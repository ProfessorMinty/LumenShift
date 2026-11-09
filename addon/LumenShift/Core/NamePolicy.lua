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
function N.Upgrade(data)
    local defaults = { thirds = false, aspect = "none", photoEnabled = false, photoLevel = 7,
        framing = ns.Framing.Defaults(), photo = ns.NativeGraphics.Defaults(), editor = ns.PhotoConfig.Defaults() }
    for key, value in pairs(defaults) do if data[key] == nil then data[key] = value end end
end
function N.Defaults()
    local data = { journal = ns.Store.EmptyJournal(), sideEffects = {}, hideWithUI = true, keepEffects = true }
    N.Upgrade(data); return data
end
function N.Validate(data)
    if not V.Fields(data, { journal = true, sideEffects = true, hideWithUI = true, keepEffects = true, thirds = true, aspect = true, photoEnabled = true, photoLevel = true, framing = true, photo = true, nameReturn = true, editor = true })
        or not ns.Store.ValidateJournal(data.journal) or type(data.sideEffects) ~= "table"
        or type(data.hideWithUI) ~= "boolean" or type(data.keepEffects) ~= "boolean" then return false end
    if type(data.thirds) ~= "boolean" or not ({ none = true, wide = true, cinema = true, square = true })[data.aspect]
        or type(data.photoEnabled) ~= "boolean" or not V.Finite(data.photoLevel) or data.photoLevel % 1 ~= 0
        or data.photoLevel < 1 or data.photoLevel > 10 or not ns.Framing.Validate(data.framing)
        or not ns.NativeGraphics.Validate(data.photo) or not ns.PhotoConfig.Validate(data.editor) then return false end
    if data.nameReturn ~= nil and (not V.Fields(data.nameReturn, { targets = true })
        or not N.ValidateTargets(data.nameReturn.targets, "camera")) then return false end
    for key, record in pairs(data.journal.entries) do
        if not N.Known(key) or record.layer ~= "camera" or record.descriptorVersion ~= N.Version then return false end
    end
    for key, item in pairs(data.sideEffects) do
        if not N.Known(key) or not V.Fields(item, { before = true, after = true })
            or not V.Number(item.before) or not V.Number(item.after) then return false end
    end
    return true
end
