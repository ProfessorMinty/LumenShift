local _, ns = ...
local F, V = {}, ns.Value
ns.Framing = F
F.Keys, F.Version = { "cameraFov" }, 1
function F.Known(key) return key == "cameraFov" end
function F.Layer() return "camera" end
function F.Range(reader)
    local result = ns.ReadOnly.Call(reader, reader.env.GetCameraFOVDefaults)
    if not result or result.n ~= 3 then return nil, "FOV_UNAVAILABLE" end
    local default, low, high = result[1], result[2], result[3]
    if not V.Finite(default) or not V.Finite(low) or not V.Finite(high)
        or low <= 0 or high >= 180 or low >= high or default < low or default > high then return nil, "FOV_UNAVAILABLE" end
    return { min = low, max = high, step = 0.1, basis = "native-camera-fov-bounds" }
end
function F.Bounds(key, original, reader)
    if not F.Known(key) then return nil, "FOV_UNAVAILABLE" end
    local bounds, why = F.Range(reader)
    local value = V.Number(original)
    if not bounds or not value or value < bounds.min or value > bounds.max then return nil, why or "FOV_OUTSIDE_NATIVE_BOUNDS" end
    return bounds
end
function F.Capability(reader) local bounds, why = F.Range(reader); return bounds ~= nil, why end
function F.Context(signature) return { signature = signature, testOnly = true, experiment = "CAMERA_FRAMING" } end
function F.Descriptor(key, bounds, signature)
    if not F.Known(key) then return nil end
    return { name = key, layer = "camera", kind = "number", version = F.Version, testOnly = true, admitted = false,
        evidence = "FOREVER_70862_NATIVE_FOV_API", signature = signature, scope = "camera_framing",
        min = bounds.min, max = bounds.max, settle = "scheduled_readback_test", numericEquivalent = true, dependencies = {}, conflicts = {} }
end
function F.ValidateTargets(targets, layer)
    if type(targets) ~= "table" or layer ~= "camera" then return false end
    for key, value in pairs(targets) do if not F.Known(key) or not V.Finite(value) then return false end end
    return true
end
function F.Defaults() return { journal = ns.Store.EmptyJournal(), sideEffects = {} } end
function F.Validate(data)
    if not V.Fields(data, { journal = true, sideEffects = true }) or not ns.Store.ValidateJournal(data.journal)
        or not V.Fields(data.sideEffects, { cameraFov = true }) then return false end
    for key, record in pairs(data.journal.entries) do
        if not F.Known(key) or record.layer ~= "camera" or record.descriptorVersion ~= F.Version then return false end
    end
    for _, pair in pairs(data.sideEffects) do
        if not V.Fields(pair, { before = true, after = true }) or not V.Number(pair.before) or not V.Number(pair.after) then return false end
    end
    return true
end
