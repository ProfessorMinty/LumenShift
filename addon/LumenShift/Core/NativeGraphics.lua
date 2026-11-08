local _, ns = ...
local G, V = {}, ns.Value
ns.NativeGraphics = G
G.Version = 1
G.Banks = { "normal", "raid" }
-- Mirrored Forever 70862 UI, docs/35 and docs/37. Native mappings and
-- support checks choose targets; these limits do not assert measured performance.
local definitions = {
    { "ShadowQuality", "Shadows", 5 }, { "LiquidDetail", "Water", 3 },
    { "PBRLiquidDetail", "PBR water", 2, "IsPBRWaterSupported" },
    { "ParticleDensity", "Particles", 5 }, { "SSAO", "Ambient occlusion", 4 },
    { "DepthEffects", "Depth effects", 3 }, { "ComputeEffects", "Compute effects", 4 },
    { "OutlineMode", "Outlines", 2, "IsOutlineModeSupported" },
    { "TextureResolution", "Textures", 2 },
    { "SpellDensity", "Spell density", 2, "IsSpellVisualDensitySystemSupported" },
    { "ProjectedTextures", "Projected textures", 1 },
    { "LightMode", "Lighting", 3, "IsSecondaryLightingSupported" },
    { "ViewDistance", "View distance", 9 }, { "EnvironmentDetail", "Environment detail", 9 },
    { "GroundClutter", "Ground clutter", 9 },
}
-- Exact names from the 70532 console capture, not inferred RAID + arbitrary key.
-- Leaf values are observable captures; the only direct leaf writes here are
-- exact restoration of captured values, never invented quality targets.
local leaves = {
    { "clusteredShading", "RAIDclusteredShading" }, { "componentTextureLevel", "RAIDcomponentTextureLevel" },
    { "DepthBasedOpacity", "RAIDDepthBasedOpacity" }, { "doodadLodScale", "RAIDdoodadLodScale" },
    { "entityLodDist", "RAIDentityLodDist" }, { "entityShadowFadeScale", "RAIDentityShadowFadeScale" },
    { "farclip", "RAIDfarclip" }, { "giQuality", "RAIDgiQuality" },
    { "groundEffectDensity", "RAIDgroundEffectDensity" }, { "groundEffectDist", "RAIDgroundEffectDist" },
    { "groundEffectFade", "RAIDgroundEffectFade" }, { "horizonClip", "RAIDhorizonClip" },
    { "horizonStart", "RAIDhorizonStart" }, { "lodObjectCullDist", "RAIDlodObjectCullDist" },
    { "lodObjectCullSize", "RAIDlodObjectCullSize" }, { "lodObjectFadeScale", "RAIDlodObjectFadeScale" },
    { "lodObjectMinSize", "RAIDlodObjectMinSize" }, { "OutlineEngineMode", "RAIDOutlineEngineMode" },
    { "particleDensity", "RAIDparticleDensity" }, { "particleMTDensity", "RAIDparticleMTDensity" },
    { "ParticulatesEnabled", "RAIDParticulatesEnabled" }, { "pbrLiquidDetail", "RAIDpbrLiquidDetail" },
    { "projectedTextures", "RAIDprojectedTextures" }, { "reflectionMode", "RAIDreflectionMode" },
    { "refraction", "RAIDrefraction" }, { "rippleDetail", "RAIDrippleDetail" },
    { "shadowBlendCascades", "RAIDshadowBlendCascades" }, { "shadowMode", "RAIDshadowMode" },
    { "shadowNumCascades", "RAIDshadowNumCascades" }, { "shadowRt", "RAIDshadowRt" },
    { "shadowSoft", "RAIDshadowSoft" }, { "shadowTextureSize", "RAIDshadowTextureSize" },
    { "spellClutter", "RAIDspellClutter" }, { "SSAO", "RAIDSSAO" }, { "sunShafts", "RAIDsunShafts" },
    { "terrainLodDist", "RAIDterrainLodDist" }, { "TerrainLodDiv", "RAIDTerrainLodDiv" },
    { "terrainMipLevel", "RAIDterrainMipLevel" }, { "volumeFog", "RAIDVolumeFog" },
    { "volumeFogLevel", "RAIDVolumeFogLevel" }, { "waterDetail", "RAIDWaterDetail" },
    { "weatherDensity", "RAIDweatherDensity" }, { "wmoLodDist", "RAIDwmoLodDist" },
    { "worldBaseMip", "RAIDworldBaseMip" },
}
local byKey, bankKeys = {}, { normal = {}, raid = {} }
for _, bank in ipairs(G.Banks) do
    local prefix = bank == "raid" and "raidGraphics" or "graphics"
    for _, def in ipairs(definitions) do
        local key = prefix .. def[1]
        byKey[key] = { bank = bank, label = def[2], max = def[3], capability = def[4], suffix = def[1] }
        bankKeys[bank][#bankKeys[bank] + 1] = key
    end
    local overall = prefix .. "Quality"
    byKey[overall] = { bank = bank, label = "Overall quality", max = 9, overall = true }
    bankKeys[bank][#bankKeys[bank] + 1] = overall
    for _, pair in ipairs(leaves) do
        local key = pair[bank == "raid" and 2 or 1]
        byKey[key] = { bank = bank, leaf = true }
        bankKeys[bank][#bankKeys[bank] + 1] = key
    end
end
byKey.RAIDsettingsEnabled = { bank = "raid", max = 1, flag = true, label = "Separate raid settings" }
bankKeys.raid[#bankKeys.raid + 1] = "RAIDsettingsEnabled"
function G.Known(key) return byKey[key] ~= nil end
function G.Definition(key) return V.Copy(byKey[key]) end
function G.Keys(bank) return V.Copy(bank and bankKeys[bank] or V.Keys(byKey)) end
function G.Overall(bank) return bank == "raid" and "raidGraphicsQuality" or "graphicsQuality" end
function G.Defaults()
    return { choices = { normal = { source = "keep", level = 5 }, raid = { source = "keep", level = 5 },
        raidEnabled = "keep" }, records = {}, sideEffects = {} }
end
function G.Choice(choice)
    return V.Fields(choice, { source = true, level = true })
        and (choice.source == "keep" or choice.source == "recommended" or choice.source == "level")
        and V.Finite(choice.level) and choice.level % 1 == 0 and choice.level >= 1 and choice.level <= 10
end
function G.Choices(choices)
    return V.Fields(choices, { normal = true, raid = true, raidEnabled = true })
        and G.Choice(choices.normal) and G.Choice(choices.raid)
        and (choices.raidEnabled == "keep" or choices.raidEnabled == "on" or choices.raidEnabled == "off")
end
function G.Validate(data)
    if not V.Fields(data, { choices = true, records = true, sideEffects = true }) or not G.Choices(data.choices)
        or type(data.sideEffects) ~= "table"
        or not V.Fields(data.records, { normal = true, raid = true }) then return false end
    for key, pair in pairs(data.sideEffects) do
        if not (byKey[key] or key == "Brightness" or key == "Contrast" or key == "Gamma" or key == "RenderScale" or ns.Optics.Known(key))
            or not V.Fields(pair, { before = true, after = true }) or not V.Number(pair.before) or not V.Number(pair.after) then return false end
    end
    for bank, record in pairs(data.records) do
        if not V.Fields(record, { signature = true, state = true, original = true, expected = true, error = true })
            or not V.Raw(record.signature) or not ({ pending = true, owned = true, failed = true, conflict = true })[record.state]
            or record.error ~= nil and not V.Raw(record.error)
            or type(record.original) ~= "table" or type(record.expected) ~= "table" or not next(record.original) then return false end
        for key, raw in pairs(record.original) do
            if not byKey[key] or byKey[key].bank ~= bank or not V.Number(raw) or not V.Number(record.expected[key]) then return false end
        end
        for key in pairs(record.expected) do if record.original[key] == nil then return false end end
    end
    return true
end
function G.Snapshot(reader, bank)
    local values, unavailable = {}, {}
    for _, key in ipairs(bankKeys[bank] or {}) do
        local item = ns.ReadOnly.Read(reader, key)
        if ns.Planner.SafeObservation(item) then values[key] = item.raw
        else unavailable[#unavailable + 1] = key end
    end
    return values, unavailable
end
function G.Matches(reader, expected)
    for _, key in ipairs(V.Keys(expected)) do
        local item = ns.ReadOnly.Read(reader, key)
        if not ns.Planner.SafeObservation(item) or item.raw ~= expected[key] then return nil, key end
    end
    return true
end
function G.Capability(reader, name)
    local api = reader.env.C_VideoOptions
    local result, why = ns.ReadOnly.Call(reader, type(api) == "table" and api[name])
    if not result or result.n ~= 1 or type(result[1]) ~= "boolean" then return nil, why or "UNEXPECTED_CAPABILITY" end
    return result[1]
end
function G.Support(reader, key, value)
    local def = byKey[key]
    if not def or def.leaf or not V.Finite(value) or value % 1 ~= 0 or value < 0 or value > def.max then return nil, "INVALID_NATIVE_LEVEL" end
    -- Native sliders have bounded numeric ranges, not dropdown support enums.
    if def.flag or def.overall or def.suffix == "ViewDistance" or def.suffix == "EnvironmentDetail" or def.suffix == "GroundClutter" then return true end
    if def.capability then
        local supported, why = G.Capability(reader, def.capability)
        if not supported then return nil, why or "HARDWARE_UNSUPPORTED" end
    end
    if def.suffix == "ParticleDensity" then
        local lighting, why = G.Capability(reader, "IsSecondaryLightingSupported")
        if lighting == nil then return nil, why end
        if lighting and value > 4 then return nil, "INVALID_PARTICLE_LEVEL" end
        if def.bank == "normal" and value < 1 then return nil, "INVALID_PARTICLE_LEVEL" end
        -- Avoid the native disabled-combat-cues choice in both banks.
        if not lighting and value == 0 then return nil, "COMBAT_CUES_DISABLED" end
    end
    local result, why = ns.ReadOnly.Call(reader, reader.env.IsGraphicsSettingValueSupported, key, value, def.bank == "raid")
    if not result or result.n ~= 1 or result[1] ~= 0 then return nil, why or "UNSUPPORTED_GRAPHICS_OPTION" end
    return true
end
function G.Recipe(reader, bank, choice, inspectNative)
    if not bankKeys[bank] or not G.Choice(choice) then return nil, "INVALID_GRAPHICS_CHOICE" end
    local targets, omitted = {}, {}
    if choice.source == "keep" then return targets, omitted end
    for _, key in ipairs(bankKeys[bank]) do
        local def = byKey[key]
        if not def.leaf and not def.flag then
            local enabled, why = true
            if def.capability then enabled, why = G.Capability(reader, def.capability) end
            if enabled == nil then return nil, (why or "CAPABILITY_UNAVAILABLE") .. ":" .. key end
            if not enabled then omitted[#omitted + 1] = key
            else
                local item = ns.ReadOnly.Read(reader, key)
                if not ns.Planner.SafeObservation(item) then return nil, "GRAPHICS_VALUE_UNAVAILABLE:" .. key end
                local value
                if choice.source == "recommended" then
                    value = item.defaultCode == "OK" and V.Number(item.defaultRaw)
                elseif def.overall then value = choice.level - 1
                else
                    local result = ns.ReadOnly.Call(reader, reader.env.GetGraphicsCVarValueForQualityLevel, key, choice.level - 1, bank == "raid")
                    value = result and result.n == 1 and V.Finite(result[1]) and result[1] or nil
                    if value and def.suffix == "ParticleDensity" and bank == "normal" then value = math.max(1, value) end
                end
                if not V.Finite(value) or value % 1 ~= 0 then return nil, "NATIVE_RECIPE_UNAVAILABLE:" .. key end
                -- Preserve projected combat cues even at the lowest level.
                if not inspectNative and def.suffix == "ProjectedTextures" then value = 1 end
                if not inspectNative and def.suffix == "ParticleDensity" then
                    local lighting = G.Capability(reader, "IsSecondaryLightingSupported")
                    if lighting == false or bank == "normal" then value = math.max(1, value) end
                end
                if inspectNative then
                    if value < 0 or value > def.max then return nil, "INVALID_NATIVE_LEVEL:" .. key end
                else
                    local ok, errorCode = G.Support(reader, key, value)
                    if not ok then return nil, errorCode .. ":" .. key end
                end
                targets[key] = value
            end
        end
    end
    return targets, omitted
end
function G.Current(reader, bank)
    local item = ns.ReadOnly.Read(reader, G.Overall(bank))
    local raw = item.code == "OK" and V.Number(item.raw)
    if not raw or raw % 1 ~= 0 or raw < 0 or raw > 9 then return "Custom / unavailable", nil end
    local recipe = G.Recipe(reader, bank, { source = "level", level = raw + 1 }, true)
    if not recipe then return "Current level " .. (raw + 1) .. " (recipe unavailable)", raw + 1 end
    for key, target in pairs(recipe) do
        if V.Number(ns.ReadOnly.Read(reader, key).raw) ~= target then return "Custom (level " .. (raw + 1) .. " modified)", raw + 1 end
    end
    return "Level " .. (raw + 1), raw + 1
end
function G.Draft(runtime)
    local choices = V.Copy(runtime.db.graphics.choices)
    for _, bank in ipairs(G.Banks) do
        if choices[bank].source == "keep" then
            local raw = V.Number(ns.ReadOnly.Read(runtime.reader, G.Overall(bank)).raw)
            if raw and raw >= 0 and raw <= 9 and raw % 1 == 0 then choices[bank].level = raw + 1 end
        end
    end
    return choices
end
function G.Context(signature) return { signature = signature, testOnly = true, experiment = "NATIVE_GRAPHICS_BANK" } end
function G.Descriptor(key, signature, restoreRaw)
    local def = byKey[key]
    if not def or not ns.Compatibility.Experimental(signature) then return nil end
    if def.leaf and not V.Number(restoreRaw) then return nil end
    local original = restoreRaw and V.Number(restoreRaw)
    return { name = key, layer = "quality", kind = "number", version = 5, testOnly = true, admitted = false,
        evidence = "SOURCE_NATIVE_RECIPE_EXPERIMENT", signature = signature, scope = "native_bank_capture",
        min = original or -1, max = original or def.max, restoreRaw = restoreRaw,
        settle = "scheduled_readback_test", numericEquivalent = true, dependencies = {}, conflicts = {} }
end
-- Exact captured-value restoration uses an equality-only descriptor. No caller
-- can use a leaf descriptor to request a new numeric tuning value.
function G.Step(reader, key, targetRaw, restoring, signature)
    local current = ns.ReadOnly.Read(reader, key)
    if not ns.Planner.SafeObservation(current) or not V.Number(targetRaw) then return nil, "UNSAFE_GRAPHICS_OBSERVATION:" .. key end
    local desc = G.Descriptor(key, signature, restoring and targetRaw or nil)
    if not desc then return nil, "UNKNOWN_GRAPHICS_WRITE:" .. key end
    local journal = { nextEpoch = 2, entries = { [key] = {
        originalRaw = restoring and targetRaw or current.raw, lastVerifiedRaw = current.raw, intendedRaw = targetRaw,
        layer = "quality", epoch = 1, state = "owned", descriptorVersion = 5, signature = signature } } }
    local plan, why = ns.Planner.Build({ [key] = desc }, G.Context(signature), { [key] = current }, journal,
        "quality", restoring and {} or { [key] = V.Number(targetRaw) })
    return plan, journal, current, why
end
function G.Order(bank, targets, restoring)
    local result = {}
    -- Restore parents before their captured custom leaf overrides. Apply overall
    -- quality last, matching the native Settings commit order.
    local overall = G.Overall(bank)
    if restoring and targets[overall] ~= nil then result[#result + 1] = overall end
    for _, key in ipairs(bankKeys[bank]) do
        local def = byKey[key]
        if targets[key] ~= nil and not def.overall and not def.flag and not def.leaf then result[#result + 1] = key end
    end
    if not restoring and targets[overall] ~= nil then result[#result + 1] = overall end
    if restoring then
        for _, key in ipairs(bankKeys[bank]) do if byKey[key].leaf and targets[key] ~= nil then result[#result + 1] = key end end
    end
    if targets.RAIDsettingsEnabled ~= nil then result[#result + 1] = "RAIDsettingsEnabled" end
    return result
end
