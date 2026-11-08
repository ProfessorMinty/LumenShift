local _, ns = ...
local O, V = {}, ns.Value
ns.Optics = O
O.Keys = { "ResampleAlwaysSharpen", "ResampleSharpness", "bloomUserMult" }
local limits = { ResampleAlwaysSharpen = 1, ResampleSharpness = 2, bloomUserMult = 1 }
function O.Known(key) return limits[key] ~= nil end
function O.ValidRequest(data)
    if type(data) ~= "table" then return false end
    for key, value in pairs(data) do
        if not limits[key] or not V.Finite(value) or value < 0 or value > limits[key]
            or key == "ResampleAlwaysSharpen" and value % 1 ~= 0 then return false end
    end
    return true
end
function O.Extract(targets)
    local result = {}
    for key, value in pairs(targets) do if O.Known(key) then result[key] = value end end
    return result
end
-- One effective value; quality remains underneath an explicit mode override.
-- Numeric values express intent. Exact pre-change strings live only in journals.
function O.Resolve(visual, quality)
    if not O.ValidRequest(visual) or not O.ValidRequest(quality) then return nil, "INVALID_OPTICAL_REQUEST" end
    local result, sources = V.Copy(quality), {}
    for key in pairs(result) do sources[key] = "quality" end
    for key, value in pairs(visual) do result[key], sources[key] = value, "visual" end
    return result, sources
end
function O.Defaults() return { visual = {}, quality = {} } end
function O.ModeTargets(mode)
    local result = {}
    if mode.sharpening == "custom" then
        result.ResampleAlwaysSharpen = 1
        result.ResampleSharpness = (100 - mode.detail) / 50
    elseif mode.sharpening == "off" then result.ResampleAlwaysSharpen = 0 end
    if mode.useBloom then result.bloomUserMult = mode.bloom end
    return result
end
function O.RawMap(data)
    if type(data) ~= "table" then return false end
    for key, raw in pairs(data) do
        local maximum = (key == "Brightness" or key == "Contrast") and 100 or limits[key]
        local n = V.Number(raw)
        if not maximum or not n or n < 0 or n > maximum
            or key == "ResampleAlwaysSharpen" and n % 1 ~= 0 then return false end
    end
    return true
end
function O.Validate(data)
    if not V.Fields(data, { visual = true, quality = true, comparison = true })
        or not O.ValidRequest(data.visual) or not O.ValidRequest(data.quality) then return false end
    local c = data.comparison
    if c ~= nil then
        if not V.Fields(c, { before = true, after = true, expected = true, state = true })
            or not O.RawMap(c.before) or not O.RawMap(c.after) or not O.RawMap(c.expected)
            or not ({ pending = true, before = true, after = true, recovery = true })[c.state] then return false end
        for key in pairs(c.before) do if not c.after[key] or not c.expected[key] then return false end end
        for key in pairs(c.after) do if not c.before[key] then return false end end
        for key in pairs(c.expected) do if not c.before[key] then return false end end
    end
    return true
end
-- Pre-mode optical records already have a single physical home in experiments.
-- Preserve that record and its original; migrate only the separate quality intent.
function O.Migrate(journal)
    local data = O.Defaults()
    for key, entry in pairs(journal.entries) do
        if O.Known(key) then
            local value = V.Number(entry.lastVerifiedRaw)
            if value and O.ValidRequest({ [key] = value }) then data.quality[key] = value end
        end
    end
    return data
end
