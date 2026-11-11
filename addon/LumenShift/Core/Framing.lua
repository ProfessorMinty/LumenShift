local _, ns = ...
local F, V = {}, ns.Value
ns.Framing = F
F.Keys, F.Version = { "cameraFov", "test_cameraOverShoulder", "test_cameraDynamicPitch", "test_cameraDynamicPitchBaseFovPad" }, 1
local limits = { test_cameraOverShoulder = { -3, 3, .1 }, test_cameraDynamicPitch = { 0, 1, 1 }, test_cameraDynamicPitchBaseFovPad = { 0, 1, .01 } }
F.ComfortKeys = { "CameraKeepCharacterCentered", "CameraReduceUnexpectedMovement" }
F.AllKeys = V.Copy(F.Keys)
for _,key in ipairs(F.ComfortKeys) do
    F.AllKeys[#F.AllKeys+1]=key
    limits[key]={0,1,1}
end
function F.IsComfort(key) return key==F.ComfortKeys[1] or key==F.ComfortKeys[2] end
function F.Known(key) return key == "cameraFov" or limits[key] ~= nil end

function F.ReadComfort(reader)
    local state={targets={}, enabled={}}
    for _,key in ipairs(F.ComfortKeys) do
        local item=ns.ReadOnly.Read(reader,key)
        local value=item.code=="OK" and V.Number(item.raw)
        if value~=0 and value~=1 then state.error="CAMERA_COMFORT_UNAVAILABLE"
        elseif value==1 then
            state.targets[key]=0
            state.enabled[#state.enabled+1]=key
            state.error=ns.Planner.ObservationError(item,key) or state.error
        end
    end
    return state
end
function F.ValidBounds(key, low, high)
    if key == "cameraFov" then return V.Finite(low) and V.Finite(high) and low > 0 and high < 180 and low < high end
    return limits[key] and low == limits[key][1] and high == limits[key][2] or false
end
function F.Layer() return "camera" end
function F.Range(reader, key)
    if key and limits[key] then
        local r = limits[key]
        return { min = r[1], max = r[2], step = r[3], basis = "lumenshift-bounded-camera-control" }
    end
    local result = ns.ReadOnly.Call(reader, reader.env.GetCameraFOVDefaults)
    if not result or result.n ~= 3 then return nil, "FOV_UNAVAILABLE" end
    local default, low, high = result[1], result[2], result[3]
    if not V.Finite(default) or not V.Finite(low) or not V.Finite(high)
        or low <= 0 or high >= 180 or low >= high or default < low or default > high then return nil, "FOV_UNAVAILABLE" end
    return { min = low, max = high, step = 0.1, basis = "native-camera-fov-bounds" }
end
function F.Bounds(key, original, reader)
    if not F.Known(key) then return nil, "FOV_UNAVAILABLE" end
    local bounds, why = F.Range(reader, key)
    local value = V.Number(original)
    if F.IsComfort(key) and value~=0 and value~=1 then return nil,"CAMERA_COMFORT_UNAVAILABLE" end
    if not bounds or not value or value < bounds.min or value > bounds.max then return nil, why or "FOV_OUTSIDE_NATIVE_BOUNDS" end
    return bounds
end
function F.Capability(reader, key, returning)
    if key and key ~= "cameraFov" then
        local item = ns.ReadOnly.Read(reader, key)
        if not ns.Planner.SafeObservation(item, key) then return nil, "FRAMING_UNAVAILABLE" end
        -- Returning a captured original does not request a new photo composition.
        if not F.IsComfort(key) and not returning and next(F.ReadComfort(reader).targets) then
            return nil, "CAMERA_COMFORT_SETTING_ENABLED"
        end
    end
    local bounds, why = F.Range(reader, key); return bounds ~= nil, why
end
function F.Context(signature) return { signature = signature, testOnly = true, experiment = "CAMERA_FRAMING" } end
function F.Descriptor(key, bounds, signature)
    if not F.Known(key) or not F.ValidBounds(key, bounds.min, bounds.max) then return nil end
    return { name = key, layer = "camera", kind = "number", version = F.Version, testOnly = true, admitted = false,
        evidence = key == "cameraFov" and "FOREVER_70862_NATIVE_FOV_API" or "FOREVER_BOUNDED_CAMERA_CVAR", signature = signature, scope = "camera_framing",
        min = bounds.min, max = bounds.max, settle = "scheduled_readback_test", numericEquivalent = true, dependencies = {}, conflicts = {} }
end
function F.ValidateTargets(targets, layer)
    if type(targets) ~= "table" or layer ~= "camera" then return false end
    for key, value in pairs(targets) do if not F.Known(key) or not V.Finite(value) or F.IsComfort(key) and value~=0 then return false end end
    return true
end
-- After an interrupted preference-only transaction, a manual Restore can
-- reconcile either complete endpoint. A different checkbox choice is preserved.
function F.CanRecoverComfort(reader,data)
    local entries=data.journal.entries
    if not next(entries) or next(data.sideEffects) then return false end
    local signature=ns.Compatibility.Inspect(reader).signature
    for key,e in pairs(entries) do
        if not F.IsComfort(key) or e.signature~=signature or e.descriptorVersion~=F.Version or V.Number(e.originalRaw)~=1 then return false end
    end
    local original,paused=true,true
    for _,key in ipairs(F.ComfortKeys) do
        local item=ns.ReadOnly.Read(reader,key)
        if not ns.Planner.SafeObservation(item,key) then return false end
        local value=V.Number(item.raw)
        original=original and (entries[key] and item.raw==entries[key].originalRaw or not entries[key] and value==0)
        paused=paused and value==0
    end
    return original or paused
end
function F.Defaults() return { journal = ns.Store.EmptyJournal(), sideEffects = {} } end
function F.Validate(data)
    if not V.Fields(data, { journal = true, sideEffects = true }) or not ns.Store.ValidateJournal(data.journal)
        or type(data.sideEffects) ~= "table" then return false end
    for key, record in pairs(data.journal.entries) do
        if not F.Known(key) or record.layer ~= "camera" or record.descriptorVersion ~= F.Version then return false end
    end
    for key, pair in pairs(data.sideEffects) do
        if not F.Known(key) or not V.Fields(pair, { before = true, after = true }) or not V.Number(pair.before) or not V.Number(pair.after) then return false end
    end
    return true
end
