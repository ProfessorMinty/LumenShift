local _, ns = ...
local R = {}
ns.ReadOnly = R
local apiNames = { "AreCVarsLoaded", "GetCVar", "GetCVarDefault", "GetCVarInfo" }
local flagNames = { "serverAccount", "serverCharacter", "locked", "secure", "readOnly" }
local function pack(...) return { n = select("#", ...), ... } end

function R.New(env)
    return { env = env }
end

-- Do not stringify, compare or save a native result until its accessibility is checked.
function R.Accessible(reader, value)
    local found = false
    for _, check in ipairs({ "canaccessvalue", "issecretvalue" }) do
        local fn = reader.env[check]
        if type(fn) == "function" then
            found = true
            local ok, result = pcall(fn, value)
            if not ok or type(result) ~= "boolean" then return false end
            if (check == "canaccessvalue" and not result)
                or (check == "issecretvalue" and result) then return false end
        end
    end
    return found
end

function R.Call(reader, fn, ...)
    if type(fn) ~= "function" then return nil, "API_UNAVAILABLE" end
    local result = pack(pcall(fn, ...))
    if not result[1] then return nil, "API_ERROR" end
    for i = 2, result.n do
        if not R.Accessible(reader, result[i]) then return nil, "ACCESS_UNVERIFIED" end
    end
    local values = { n = result.n - 1 }
    for i = 2, result.n do values[i - 1] = result[i] end
    return values
end

function R.Capabilities(reader)
    local api, result = reader.env.C_CVar, {}
    for _, name in ipairs(apiNames) do
        result[name] = type(api) == "table" and type(api[name]) == "function"
    end
    result.canaccessvalue = type(reader.env.canaccessvalue) == "function"
    result.issecretvalue = type(reader.env.issecretvalue) == "function"
    return result
end

function R.Ready(reader)
    local api = reader.env.C_CVar
    if type(api) ~= "table" then return false, "API_UNAVAILABLE" end
    local values, code = R.Call(reader, api.AreCVarsLoaded)
    if not values then return false, code end
    if values.n ~= 1 or type(values[1]) ~= "boolean" then return false, "UNEXPECTED_READINESS" end
    if not values[1] then return false, "CVARS_NOT_LOADED" end
    return true
end

function R.Read(reader, key)
    -- Only the diagnostic catalog can supply names; no arbitrary console interface.
    if not ns.Catalog.Get(key) then return { code = "UNKNOWN_KEY" } end
    local ready, code = R.Ready(reader)
    if not ready then return { code = code } end
    local api, result = reader.env.C_CVar, { code = "OK" }
    local values, readCode = R.Call(reader, api.GetCVar, key)
    if not values then result.code = readCode
    elseif values.n ~= 1 or not ns.Value.Raw(values[1]) then result.code = "UNAVAILABLE_OR_INVALID_VALUE"
    else
        result.raw = values[1]
        if ns.Catalog.Get(key).kind ~= "string" and not ns.Value.Number(result.raw) then result.code = "UNEXPECTED_NUMERIC_VALUE" end
    end

    local defaults, defaultCode = R.Call(reader, api.GetCVarDefault, key)
    if defaults and defaults.n == 1 and ns.Value.Raw(defaults[1]) then
        result.defaultRaw, result.defaultCode = defaults[1], "OK"
        if ns.Catalog.Get(key).kind ~= "string" and not ns.Value.Number(result.defaultRaw) then result.defaultCode = "UNEXPECTED_NUMERIC_DEFAULT" end
    else result.defaultCode = defaultCode or "UNAVAILABLE_OR_INVALID_DEFAULT" end

    local info, infoCode = R.Call(reader, api.GetCVarInfo, key)
    result.flagsCode = infoCode or "UNEXPECTED_INFO"
    if info and info.n == 7 and ns.Value.Raw(info[1]) and ns.Value.Raw(info[2]) then
        local valid = true
        for i = 3, 7 do if type(info[i]) ~= "boolean" then valid = false end end
        if valid then
            result.flags, result.flagsCode = {}, "OK"
            for i, name in ipairs(flagNames) do result.flags[name] = info[i + 2] end
            -- Multiple getters are observations, not an atomic snapshot.
            if result.raw and result.raw ~= info[1] then result.code = "READ_DRIFT" end
            if result.defaultRaw and result.defaultRaw ~= info[2] then result.defaultCode = "READ_DRIFT" end
        end
    end
    return result
end
