local _, ns = ...
local C = {}
ns.Catalog = C
-- SRC-02/10/11 in docs/07. UI bounds are NOT measured write admission.
local candidates = {
    Brightness = { layer = "visual", kind = "number", uiMin = 0, uiMax = 100,
        evidence = "SOURCE_DECLARED_70790", admitted = false, version = 1 },
    Contrast = { layer = "visual", kind = "number", uiMin = 0, uiMax = 100,
        evidence = "SOURCE_DECLARED_70790", admitted = false, version = 1 },
}
function C.Get(key) return ns.Value.Copy(candidates[key]) end
function C.Keys() return ns.Value.Keys(candidates) end
function C.Snapshot() return ns.Value.Copy(candidates) end

local function names(list)
    if type(list) ~= "table" then return false end
    local count = 0
    for index, key in pairs(list) do
        count = count + 1
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #list
            or not ns.Value.Raw(key) then return false end
    end
    return count == #list and count <= 16
end

-- Pure predicate for a FUTURE reviewed catalog. No runtime admission/update API.
function C.Admitted(descriptor, context)
    return type(descriptor) == "table" and type(context) == "table"
        and context.verified == true and context.rendererVerified == true
        and ns.Value.Raw(context.signature) and ns.Value.Raw(context.renderer)
        and descriptor.admitted == true and descriptor.evidence == "VERIFIED_CLIENT"
        and descriptor.signature == context.signature and descriptor.renderer == context.renderer
        and descriptor.scope == "client" and descriptor.kind == "number"
        and ns.Value.Finite(descriptor.min) and ns.Value.Finite(descriptor.max)
        and descriptor.min <= descriptor.max and descriptor.settle == "immediate_verified"
        and names(descriptor.dependencies) and names(descriptor.conflicts)
        and (descriptor.layer == "visual" or descriptor.layer == "quality")
        and type(descriptor.numericEquivalent) == "boolean"
        and ns.Value.Finite(descriptor.version) and descriptor.version >= 1 and descriptor.version % 1 == 0
end

function C.Equal(descriptor, left, right)
    if left == right then return true end
    if descriptor.numericEquivalent == true then
        local a, b = ns.Value.Number(left), ns.Value.Number(right)
        return a ~= nil and b ~= nil and a == b
    end
    return false
end
