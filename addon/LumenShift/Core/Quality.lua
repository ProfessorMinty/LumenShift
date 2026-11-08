local _, ns = ...
local Q = {}
ns.Quality = Q
-- Observation catalog only. Never a write whitelist or a target-value guess.
Q.Candidates = {
    { key = "assaoDetailShadowStrength", label = "Contact depth (trial)", group = "Contact depth", source = "FOREVER_70532_METADATA", dependency = "AO method/tiers; visible effect and temporal stability unverified" },
    { key = "ResampleAlwaysSharpen", label = "Always sharpen", group = "Sharpening", source = "SRC-03", dependency = "Upscaling / render scale" },
    { key = "ResampleSharpness", label = "Sharpness", group = "Sharpening", source = "SRC-11", dependency = "Reversed UI mapping; upscaling" },
    { key = "groundEffectDensity", label = "Foliage density", group = "Foliage", source = "SRC-03", dependency = "Ground clutter and fade distances" },
    { key = "groundEffectDist", label = "Foliage distance", group = "Foliage", source = "SRC-03", dependency = "Density and fade" },
    { key = "farclip", label = "View distance", group = "Distance", source = "SRC-09", dependency = "View-distance tier and terrain LOD" },
    { key = "terrainLodDist", label = "Terrain LOD", group = "Distance", source = "SRC-03", dependency = "View distance; native domain unknown" },
    { key = "lodObjectCullSize", label = "Object cull size", group = "Objects", source = "SRC-03", dependency = "Environment detail tier" },
    { key = "lodObjectFadeScale", label = "Object fade scale", group = "Objects", source = "SRC-03", dependency = "Environment detail and culling" },
    { key = "graphicsShadowQuality", label = "Shadow quality", group = "Shadows", source = "SRC-11", dependency = "Unmapped child-setting changes" },
    { key = "graphicsLightMode", label = "Secondary lighting", group = "Lighting", source = "SRC-11", dependency = "Hardware capability and shader behavior" },
    { key = "reflectionMode", label = "Reflections", group = "Water", source = "SRC-03", dependency = "Water/PBR detail; enum unverified" },
    { key = "graphicsLiquidDetail", label = "Water quality", group = "Water", source = "SRC-12", dependency = "Tier side effects and PBR support" },
    { key = "bloomUserMult", label = "Bloom", group = "Atmosphere", source = "SRC-11", dependency = "Linear pipeline support" },
    { key = "weatherDensity", label = "Weather density", group = "Atmosphere", source = "SRC-05", dependency = "Canonical spelling and real weather test" },
}
Q.Profiles = { currentBaseline = "Current Baseline", balanced = "Balanced", vista = "Vista", performance = "Performance" }
Q.Descriptions = { currentBaseline = "Restore captured quality originals. Your visual mode stays active.",
    balanced = "Preserve scene detail and enable sharpening. Uses your saved custom targets when configured.",
    vista = "Increase scene detail by a bounded amount from your original values. Experimental; may cost FPS.",
    performance = "Reduce scene detail by a bounded amount. Experimental; an FPS improvement is not guaranteed." }
-- Built-ins omit strength: preserve an unowned value or restore an owned custom
-- strength through the exact release path, including off-grid native originals.
local recipeKeys = { "ResampleAlwaysSharpen", "groundEffectDensity", "groundEffectDist",
    "farclip", "terrainLodDist", "lodObjectCullSize", "lodObjectFadeScale" }
function Q.Resolve(runtime, id)
    if not Q.Profiles[id] or not runtime.db then return nil, "INVALID_QUALITY_PROFILE" end
    if id == "currentBaseline" then return {}, {} end
    local data = runtime.db.experiments
    -- Preserve existing custom profiles exactly: built-ins never silently append keys.
    if next(data.profiles[id]) then return ns.Value.Copy(data.profiles[id]), {}, "custom" end
    local targets, omitted = {}, {}
    for _, key in ipairs(recipeKeys) do
        local observed = ns.ReadOnly.Read(runtime.reader, key)
        local entry = data.journal.entries[key]
        local original = entry and entry.originalRaw or observed.raw
        local bounds = ns.ExperimentPolicy.Bounds(key, original)
        if ns.Planner.SafeObservation(observed) and bounds then
            local value = ns.Value.Number(original)
            if key == "ResampleAlwaysSharpen" then value = 1
            elseif id ~= "balanced" then
                local increase = id == "vista"
                if key == "lodObjectCullSize" then increase = not increase end
                value = increase and math.floor(bounds.max) or math.ceil(bounds.min)
            end
            if id ~= "balanced" or key == "ResampleAlwaysSharpen" then targets[key] = value end
        else omitted[#omitted + 1] = key end
    end
    if not next(targets) then return nil, "NO_QUALITY_CONTROLS_AVAILABLE" end
    return targets, omitted, "built-in"
end
function Q.Scan(reader)
    local rows = {}
    for _, candidate in ipairs(Q.Candidates) do
        local row = ns.Value.Copy(candidate)
        row.observation = ns.ReadOnly.Read(reader, row.key)
        local bounds = ns.ExperimentPolicy.Bounds(row.key, row.observation.raw)
        local supported, capabilityReason = ns.ExperimentPolicy.Capability(reader, row.key)
        row.operational = supported and ns.ExperimentPolicy.Known(row.key) and bounds ~= nil
            and ns.Planner.SafeObservation(row.observation) and ns.Compatibility.Experimental(ns.Compatibility.Inspect(reader).signature)
        row.reason = not supported and ns.Product.Message(capabilityReason)
            or ns.QualityTrial.Known(row.key) and "Native tier trial in Advanced Graphics; checks named settings on restoration."
            or row.operational and "Experimental control available in Advanced Graphics."
            or not ns.ExperimentPolicy.Known(row.key) and "Use the native Graphics Quality controls where available; this row is a read-only observation."
            or "Currently unavailable or outside the supported test range; see Diagnostics."
        rows[#rows + 1] = row
    end
    return rows
end
function Q.Select(db, id)
    if not db or not Q.Profiles[id] then return nil, "INVALID_QUALITY_PROFILE" end
    if id ~= "currentBaseline" then return nil, "QUALITY_VALIDATION_REQUIRED" end
    for _, record in pairs(db.journal.entries) do
        if record.layer == "quality" then return nil, "QUALITY_RECOVERY_REQUIRED" end
    end
    db.config.selected.quality = id
    return true -- explicitly no native setting mutation
end
