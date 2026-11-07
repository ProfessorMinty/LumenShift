local _, ns = ...
local T, V = {}, ns.Value
ns.QualityTrial = T
-- Source-confirmed UI choices in the 70862 Graphics.lua (docs/29), not a
-- claim of complete native dependency mapping. These are round-trip trials.
T.Order = { "graphicsShadowQuality", "graphicsLightMode", "graphicsLiquidDetail", "graphicsPBRLiquidDetail" }
local definitions = {
    graphicsShadowQuality = { label = "Shadows", choices = { "Low", "Fair", "Medium", "High", "Ultra", "Ultra high" } },
    graphicsLightMode = { label = "Lighting", choices = { "Fair", "Medium", "High", "Ultra" }, capability = "IsSecondaryLightingSupported" },
    graphicsLiquidDetail = { label = "Water and reflections", choices = { "Low", "Fair", "Medium", "High" } },
    graphicsPBRLiquidDetail = { label = "PBR water", choices = { "Low", "High", "Ultra" }, capability = "IsPBRWaterSupported" },
}
function T.Definition(key) return V.Copy(definitions[key]) end
function T.Known(key) return definitions[key] ~= nil end
function T.Context(signature)
    return { signature = signature, testOnly = true, experiment = "QUALITY_TIER_TRIAL" }
end
function T.Descriptor(key, signature)
    local definition = definitions[key]
    if not definition or not ns.Compatibility.Experimental(signature) then return nil end
    return { name = key, layer = "quality", kind = "number", version = 3, testOnly = true, admitted = false,
        evidence = "SOURCE_UI_TIER_TRIAL", signature = signature, scope = "watched_tier_roundtrip", min = 0,
        max = #definition.choices - 1, settle = "scheduled_readback_test", numericEquivalent = true, dependencies = {}, conflicts = {} }
end
function T.Support(reader, key, target)
    local definition = definitions[key]
    if not definition or not V.Finite(target) or target % 1 ~= 0 or target < 0 or target >= #definition.choices then
        return nil, "INVALID_TIER_CHOICE"
    end
    if definition.capability then
        local video = reader.env.C_VideoOptions
        local result = ns.ReadOnly.Call(reader, type(video) == "table" and video[definition.capability])
        if not result or result.n ~= 1 or result[1] ~= true then return nil, "HARDWARE_CAPABILITY_UNAVAILABLE" end
    end
    local result, why = ns.ReadOnly.Call(reader, reader.env.IsGraphicsSettingValueSupported, key, target, false)
    if not result or result.n ~= 1 or result[1] ~= 0 then return nil, why or "NATIVE_TIER_CHOICE_UNSUPPORTED" end
    return true
end
function T.Snapshot(reader)
    local snapshot = {}
    for _, key in ipairs(ns.Catalog.WatchKeys()) do
        local item = ns.ReadOnly.Read(reader, key)
        if item.code == "OK" and V.Number(item.raw) then snapshot[key] = { before = item.raw, after = item.raw } end
    end
    return snapshot
end
function T.Matches(reader, snapshot, field)
    local differences = {}
    for _, key in ipairs(V.Keys(snapshot)) do
        local item = ns.ReadOnly.Read(reader, key)
        if item.code ~= "OK" or item.raw ~= snapshot[key][field] then differences[#differences + 1] = key end
    end
    return #differences == 0, differences
end
function T.HasRecord(data)
    for key, entry in pairs(data and data.journal.entries or {}) do
        if T.Known(key) and entry.descriptorVersion == 3 then return key, entry end
    end
end
