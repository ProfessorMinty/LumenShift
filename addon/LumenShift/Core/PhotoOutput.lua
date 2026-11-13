local _, ns = ...
local P, V = {}, ns.Value; ns.PhotoOutput = P
P.Groups = { aa = { "ffxAntiAliasingMode", "MSAAQuality", "MSAAAlphaTest" }, jpeg = { "screenshotQuality" } }
function P.Known(key)
    for group, keys in pairs(P.Groups) do for _, name in ipairs(keys) do if name == key then return group end end end
end
function P.Sample(raw)
    if not V.Raw(raw) then return nil end
    local index, coverage = raw:match("^(%d+),(%d+)$")
    if not index then index, coverage = raw:match("^(%d+)$"), "0" end
    index, coverage = tonumber(index), tonumber(coverage)
    if not index or index > 64 or not coverage or coverage > 64 then return nil end
    return index, coverage
end
function P.ValidRaw(key, raw)
    if key == "MSAAQuality" then return P.Sample(raw) ~= nil end
    local n = V.Number(raw)
    if not n or n % 1 ~= 0 then return false end
    return key == "ffxAntiAliasingMode" and n >= 0 and n <= 4
        or key == "MSAAAlphaTest" and (n == 0 or n == 1)
        or key == "screenshotQuality" and n >= 1 and n <= 10 or false
end
function P.Equal(key, a, b)
    if key == "MSAAQuality" then
        local x, y = P.Sample(a); local u, v = P.Sample(b)
        return x ~= nil and u ~= nil and x == u and y == v
    end
    return V.Number(a) ~= nil and V.Number(a) == V.Number(b)
end
function P.Safe(item, key)
    if not item or not P.ValidRaw(key, item.raw) then return false end
    -- The ordinary security policy still applies. Only this named compound
    -- setting uses a validated tuple instead of the general numeric planner.
    local copy = V.Copy(item); if key == "MSAAQuality" then copy.raw = "0" end
    return ns.Planner.SafeObservation(copy, key)
end
function P.Defaults() return { records = {} } end
function P.Validate(data)
    if not V.Fields(data, { records = true }) or not V.Fields(data.records, P.Groups) then return false end
    for group, r in pairs(data.records) do
        if not V.Fields(r, { original = true, expected = true, signature = true, state = true, error = true })
            or not V.Raw(r.signature) or not ({ pending = true, owned = true, failed = true, conflict = true })[r.state]
            or r.error ~= nil and not V.Raw(r.error) or type(r.original) ~= "table" or type(r.expected) ~= "table" then return false end
        local count = 0
        for key, raw in pairs(r.original) do
            count = count + 1
            if P.Known(key) ~= group or not P.ValidRaw(key, raw) or not P.ValidRaw(key, r.expected[key]) then return false end
        end
        if count ~= #P.Groups[group] then return false end
        for key in pairs(r.expected) do if not r.original[key] then return false end end
    end
    return true
end
function P.Read(reader, group)
    local seen = {}
    for _, key in ipairs(P.Groups[group] or {}) do seen[key] = ns.ReadOnly.Read(reader, key) end
    return seen
end
-- Pure, closed-group plan: every dependent AA member is captured/verified,
-- including unchanged ones. Restores preserve the exact original strings.
function P.Plan(group, observed, record, requested, signature, restoring)
    if not P.Groups[group] or not ns.Compatibility.Experimental(signature) or type(requested) ~= "table" then return nil, "INVALID_OUTPUT_REQUEST" end
    if record and (not P.Validate({ records = { [group] = record } }) or record.signature ~= signature
        or not restoring and (record.state ~= "owned" or record.error)) then return nil, "OUTPUT_RECOVERY_RETAINED" end
    local original, expected, ops, changed = {}, {}, {}, false
    for key in pairs(requested) do if P.Known(key) ~= group then return nil, "INVALID_OUTPUT_KEY" end end
    for _, key in ipairs(P.Groups[group]) do
        local item = observed[key]
        if not P.Safe(item, key) then return nil, "OUTPUT_UNAVAILABLE:" .. key end
        if record and item.raw ~= record.expected[key] then return nil, "OUTPUT_EXTERNAL_CONFLICT:" .. key end
        original[key], expected[key] = record and record.original[key] or item.raw, item.raw
        local target = restoring and original[key] or requested[key]
        if not P.ValidRaw(key, target) then return nil, "INVALID_OUTPUT_TARGET:" .. key end
        local equal = restoring and item.raw == target or not restoring and P.Equal(key, item.raw, target)
        if not equal then changed = true; ops[#ops + 1] = { key = key, before = item.raw, target = target } end
    end
    return { original = original, expected = expected, operations = ops, changed = changed, targets = V.Copy(requested) }
end
function P.Options(reader)
    local image, samples = { { value = 0, label = "Off" } }, { { value = "0", label = "Off" } }
    local aa = ns.ReadOnly.Call(reader, reader.env.AntiAliasingSupported)
    if aa and aa.n == 3 then
        if aa[1] == true then image[#image + 1] = { value = 1, label = "FXAA Low" }; image[#image + 1] = { value = 2, label = "FXAA High" } end
        if aa[2] == true then image[#image + 1] = { value = 3, label = "CMAA" } end
        if aa[3] == true then image[#image + 1] = { value = 4, label = "CMAA2" } end
    end
    local ms = ns.ReadOnly.Call(reader, reader.env.MultiSampleAntiAliasingSupported)
    if ms and ms.n > 0 and ms.n % 3 == 0 and ms.n <= 48 then
        for i = 1, ms.n, 3 do
            local raw = type(ms[i]) == "number" and tostring(ms[i]) or ms[i]
            local index, coverage = P.Sample(raw)
            if index and index > 0 and V.Finite(ms[i + 1]) and V.Finite(ms[i + 2])
                and ms[i + 1] >= 1 and ms[i + 1] <= 64 and ms[i + 2] >= 0 and ms[i + 2] <= 64 then
                samples[#samples + 1] = { value = raw, label = "MSAA " .. ms[i + 1] .. "x / " .. ms[i + 2] .. " coverage" }
            end
        end
    end
    return image, samples
end
function P.Admit(reader, group, targets)
    if group == "jpeg" then
        local format = ns.ReadOnly.Read(reader, "screenshotFormat")
        return format.code == "OK" and format.raw == "jpeg" and P.ValidRaw("screenshotQuality", targets.screenshotQuality) or nil, "JPEG_OUTPUT_UNAVAILABLE"
    end
    if group ~= "aa" then return nil, "INVALID_OUTPUT_REQUEST" end
    local image, samples = P.Options(reader); local hasImage, hasSamples = false, false
    for _, option in ipairs(image) do if V.Number(targets.ffxAntiAliasingMode) == option.value then hasImage = true end end
    for _, option in ipairs(samples) do if P.Equal("MSAAQuality", option.value, targets.MSAAQuality) then hasSamples = true end end
    if not hasImage or not hasSamples or not P.ValidRaw("MSAAAlphaTest", targets.MSAAAlphaTest) then return nil, "AA_OPTION_UNSUPPORTED" end
    local supported = ns.ReadOnly.Call(reader, reader.env.IsGraphicsSettingValueSupported, "msaaAlphaTest", V.Number(targets.MSAAAlphaTest), false)
    if not supported or supported.n ~= 1 or supported[1] ~= 0 then return nil, "AA_ALPHA_UNSUPPORTED" end
    return true
end
