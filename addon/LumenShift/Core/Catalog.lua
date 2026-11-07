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
local watch = { "Gamma", "RenderScale", "graphicsViewDistance", "graphicsGroundClutter", "graphicsEnvironmentDetail",
    "groundEffectFade", "graphicsPBRLiquidDetail", "graphicsQuality", "raidGraphicsQuality", "RAIDsettingsEnabled" }
function C.Get(key)
    if ns.NamePolicy and ns.NamePolicy.Known(key) then return { kind = "number", layer = "camera", admitted = false } end
    if candidates[key] then return ns.Value.Copy(candidates[key]) end
    if key == "gxapi" then return { kind = "string", diagnosticOnly = true, admitted = false } end
    for _, name in ipairs(watch) do if key == name then return { kind = "number", diagnosticOnly = true, admitted = false } end end
    for _, candidate in ipairs(ns.Quality and ns.Quality.Candidates or {}) do
        if candidate.key == key then return { layer = "quality", kind = "number", evidence = candidate.source,
            admitted = false, version = 1, diagnosticOnly = true } end
    end
end
function C.Keys() return ns.Value.Keys(candidates) end
function C.Snapshot() return ns.Value.Copy(candidates) end
function C.WatchKeys()
    local result, seen = {}, {}
    for _, list in ipairs({ C.Keys(), watch, ns.Quality and ns.Quality.Candidates or {} }) do
        for _, item in ipairs(list) do
            local key = type(item) == "table" and item.key or item
            if not seen[key] then result[#result + 1] = key; seen[key] = true end
        end
    end
    table.sort(result); return result
end

-- An explicit experiment policy, NOT a promotion to the production write catalog.
function C.TestContext(context)
    return type(context) == "table" and context.testOnly == true
        and ns.Compatibility.Experimental(context.signature)
        and (context.experiment == "BRIGHTNESS_75_ROUNDTRIP" or context.experiment == "BOUNDED_LEAF_CALIBRATION"
            or context.experiment == "QUALITY_TIER_TRIAL" or context.experiment == "CAMERA_NAMES")
end

function C.BrightnessExperiment(signature)
    local context = { signature = signature, testOnly = true, experiment = "BRIGHTNESS_75_ROUNDTRIP" }
    if not C.TestContext(context) then return nil, nil end
    return { Brightness = {
        name = "Brightness", layer = "visual", kind = "number", version = 1,
        evidence = "CONTROLLED_TEST_01B", testOnly = true, admitted = false,
        signature = signature, scope = "observed_local_test", min = 0, max = 100,
        settle = "manual_readback_test", numericEquivalent = true, dependencies = {}, conflicts = {},
    } }, context
end

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
    if C.TestContext(context) and context.experiment == "CAMERA_NAMES" then
        local expected = type(descriptor) == "table" and ns.NamePolicy.Descriptor(descriptor.name, nil, context.signature)
        if not expected then return false end
        for key, value in pairs(expected) do
            if type(value) ~= "table" and descriptor[key] ~= value then return false end
        end
        return names(descriptor.dependencies) and #descriptor.dependencies == 0
            and names(descriptor.conflicts) and #descriptor.conflicts == 0
    end
    if C.TestContext(context) and context.experiment == "QUALITY_TIER_TRIAL" then
        local expected = type(descriptor) == "table" and ns.QualityTrial.Descriptor(descriptor.name, context.signature)
        if not expected then return false end
        for key, value in pairs(expected) do
            if type(value) ~= "table" and descriptor[key] ~= value then return false end
        end
        return names(descriptor.dependencies) and #descriptor.dependencies == 0
            and names(descriptor.conflicts) and #descriptor.conflicts == 0
    end
    if C.TestContext(context) and context.experiment == "BOUNDED_LEAF_CALIBRATION" then
        return type(descriptor) == "table" and ns.ExperimentPolicy.Known(descriptor.name)
            and descriptor.testOnly == true and descriptor.admitted == false
            and descriptor.evidence == "EXPLICIT_EXPERIMENT_NOT_NATIVE_ADMISSION"
            and descriptor.signature == context.signature and descriptor.scope == "bounded_leaf_test"
            and descriptor.kind == "number" and descriptor.version == 2
            and ns.ExperimentPolicy.ValidDescriptorBounds(descriptor.name, descriptor.min, descriptor.max)
            and descriptor.layer == (descriptor.name == "Contrast" and "visual" or "quality")
            and descriptor.settle == "scheduled_readback_test" and descriptor.numericEquivalent == true
            and names(descriptor.dependencies) and #descriptor.dependencies == 0
            and names(descriptor.conflicts) and #descriptor.conflicts == 0
    end
    if C.TestContext(context) then
        return type(descriptor) == "table" and descriptor.name == "Brightness"
            and descriptor.testOnly == true and descriptor.admitted == false
            and descriptor.evidence == "CONTROLLED_TEST_01B" and descriptor.signature == context.signature
            and descriptor.scope == "observed_local_test" and descriptor.layer == "visual"
            and descriptor.kind == "number" and descriptor.version == 1
            and descriptor.min == 0 and descriptor.max == 100 and descriptor.numericEquivalent == true
            and descriptor.settle == "manual_readback_test"
            and names(descriptor.dependencies) and #descriptor.dependencies == 0
            and names(descriptor.conflicts) and #descriptor.conflicts == 0
    end
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
