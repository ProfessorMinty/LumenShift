local _, ns = ...
local V = {}
ns.Value = V

function V.Finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

function V.Raw(value)
    return type(value) == "string" and #value > 0 and #value <= 64
        and not value:find("[%c|]")
end

function V.Number(raw)
    if not V.Raw(raw) or not raw:match("^[+-]?%d*%.?%d+$") then return nil end
    local value = tonumber(raw)
    if V.Finite(value) then return value end
end

function V.Keys(value)
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

-- Copy only bounded, acyclic, data-only tables. Never execute imports/metatables.
function V.Copy(value)
    local seen, count = {}, 0
    local function copy(item, depth)
        count = count + 1
        if depth > 12 or count > 4096 then error("DATA_LIMIT") end
        local kind = type(item)
        if kind == "nil" or kind == "boolean" then return item end
        if kind == "number" and V.Finite(item) then return item end
        if kind == "string" and #item <= 256 then return item end
        if kind ~= "table" or getmetatable(item) ~= nil or seen[item] then error("INVALID_DATA") end
        seen[item] = true
        local result = {}
        for key, child in pairs(item) do
            if type(key) ~= "string" and type(key) ~= "number" then error("INVALID_KEY") end
            result[copy(key, depth + 1)] = copy(child, depth + 1)
        end
        seen[item] = nil
        return result
    end
    local ok, result = pcall(copy, value, 0)
    if ok then return result end
    return nil, "INVALID_OR_OVERSIZED_DATA"
end

function V.Fields(value, allowed)
    if type(value) ~= "table" then return false end
    for key in pairs(value) do if not allowed[key] then return false end end
    return true
end
