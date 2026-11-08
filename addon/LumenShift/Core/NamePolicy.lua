local _, ns = ...
local N, V = {}, ns.Value
ns.NamePolicy = N
N.Keys = { "UnitNameFriendlyPlayerName", "UnitNameFriendlyPetName" }
N.Version = 4
function N.Known(key) return key == N.Keys[1] or key == N.Keys[2] end
function N.Layer() return "camera" end
function N.Bounds(key, original)
    local value = V.Number(original)
    if not N.Known(key) or (value ~= 0 and value ~= 1) then return nil, "INVALID_NAME_TOGGLE_VALUE" end
    return { min = 0, max = 1, step = 1, basis = "owner-macro-boolean-native-checked" }
end
function N.Context(signature) return { signature = signature, testOnly = true, experiment = "CAMERA_NAMES" } end
function N.Descriptor(key, bounds, signature)
    if not N.Known(key) or not ns.Compatibility.Experimental(signature) then return nil end
    return { name = key, layer = "camera", kind = "number", version = N.Version, testOnly = true, admitted = false,
        evidence = "OWNER_MACRO_NATIVE_CHECKED", signature = signature, scope = "friendly_names", min = 0, max = 1,
        settle = "scheduled_readback_test", numericEquivalent = true, dependencies = {}, conflicts = {} }
end
function N.ValidateTargets(targets, layer)
    if type(targets) ~= "table" or layer ~= "camera" then return false end
    for key, value in pairs(targets) do if not N.Known(key) or (value ~= 0 and value ~= 1) then return false end end
    return true
end
function N.Defaults() return { journal = ns.Store.EmptyJournal(), sideEffects = {}, hideWithUI = true, keepEffects = true } end
function N.Validate(data)
    if not V.Fields(data, { journal = true, sideEffects = true, hideWithUI = true, keepEffects = true })
        or not ns.Store.ValidateJournal(data.journal) or type(data.sideEffects) ~= "table"
        or type(data.hideWithUI) ~= "boolean" or type(data.keepEffects) ~= "boolean" then return false end
    for key, record in pairs(data.journal.entries) do
        if not N.Known(key) or record.layer ~= "camera" or record.descriptorVersion ~= N.Version then return false end
    end
    for key, item in pairs(data.sideEffects) do
        if not N.Known(key) or not V.Fields(item, { before = true, after = true })
            or not V.Number(item.before) or not V.Number(item.after) then return false end
    end
    return true
end
