local _, ns = ...
local E, V = {}, ns.Value
ns.ExperimentPolicy = E
E.Version = 2
function E.Layer(key) return key == "Contrast" and "visual" or "quality" end
-- Bounds are TEST POLICIES, never claims of measured native safe/effective domains.
-- No overall/tier/restart/HDR/camera CVars. Only the exact named leaf candidates below.
E.Keys = { "Contrast", "ResampleAlwaysSharpen", "ResampleSharpness", "groundEffectDensity", "groundEffectDist",
    "lodObjectCullSize", "lodObjectFadeScale", "farclip", "terrainLodDist", "bloomUserMult", "weatherDensity" }
local rules = { Contrast = { 0, 100, 1, "source-ui" }, ResampleAlwaysSharpen = { 0, 1, 1, "experimental-boolean" },
    ResampleSharpness = { 0, 2, 0.1, "source-ui-reversed" }, bloomUserMult = { 0, 1, 0.2, "source-ui-conditional" } }
local relative = { groundEffectDensity = 32, groundEffectDist = 40, lodObjectCullSize = 2,
    lodObjectFadeScale = 20, farclip = 250, terrainLodDist = 100, weatherDensity = 1 }
function E.Bounds(key, original)
    local number = V.Number(original)
    if not number then return nil, "NONNUMERIC_ORIGINAL" end
    if rules[key] then
        local rule = rules[key]
        if number < rule[1] or number > rule[2] then return nil, "ORIGINAL_OUTSIDE_TEST_POLICY" end
        return { min = rule[1], max = rule[2], step = rule[3], basis = rule[4] }
    end
    if not relative[key] then return nil, "UNMAPPED_TIER_OR_EXCLUDED_KEY" end
    if number < 0 or number > 10000 then return nil, "ORIGINAL_OUTSIDE_TEST_POLICY" end
    local delta = math.min(relative[key], math.max(1, math.abs(number) * 0.1))
    return { min = math.max(0, number - delta), max = math.min(10000, number + delta), step = 1,
        basis = "addon-relative-test-limit-not-native-range" }
end
function E.Known(key)
    return rules[key] ~= nil or relative[key] ~= nil
end
function E.ValidDescriptorBounds(key, minimum, maximum)
    if not V.Finite(minimum) or not V.Finite(maximum) or minimum > maximum then return false end
    if rules[key] then return minimum == rules[key][1] and maximum == rules[key][2] end
    return relative[key] ~= nil and minimum >= 0 and maximum <= 10000
        and maximum - minimum <= 2 * relative[key]
end
function E.ValidateTargets(targets, layer)
    if type(targets) ~= "table" then return false end
    local count = 0
    for key, value in pairs(targets) do
        count = count + 1
        if count > 8 or not E.Known(key) or not V.Finite(value) or value < 0 or value > 10000
            or (key == "Contrast" and layer ~= "visual") or (key ~= "Contrast" and layer ~= "quality") then return false end
    end
    return true
end
function E.Defaults()
    return { journal = ns.Store.EmptyJournal(), profiles = { balanced = {}, vista = {}, performance = {} },
        sideEffects = {} }
end
function E.Validate(data)
    if not V.Fields(data, { journal = true, profiles = true, sideEffects = true })
        or not ns.Store.ValidateJournal(data.journal)
        or not V.Fields(data.profiles, { balanced = true, vista = true, performance = true })
        or type(data.sideEffects) ~= "table" then return false end
    for _, id in ipairs({ "balanced", "vista", "performance" }) do
        if not E.ValidateTargets(data.profiles[id], "quality") then return false end
    end
    local count = 0
    for key, values in pairs(data.sideEffects) do
        count = count + 1
        if count > 48 or not ns.Catalog.Get(key) or not V.Fields(values, { before = true, after = true })
            or not V.Number(values.before) or not V.Number(values.after) then return false end
    end
    return true
end
function E.Context(signature)
    return { signature = signature, testOnly = true, experiment = "BOUNDED_LEAF_CALIBRATION" }
end
function E.Descriptor(key, bounds, signature)
    if not ns.Compatibility.Experimental(signature) or not E.Known(key) then return nil end
    return { name = key, layer = key == "Contrast" and "visual" or "quality", kind = "number", version = 2,
        evidence = "EXPLICIT_EXPERIMENT_NOT_NATIVE_ADMISSION", testOnly = true, admitted = false,
        signature = signature, scope = "bounded_leaf_test", min = bounds.min, max = bounds.max,
        settle = "scheduled_readback_test", numericEquivalent = true, dependencies = {}, conflicts = {} }
end
