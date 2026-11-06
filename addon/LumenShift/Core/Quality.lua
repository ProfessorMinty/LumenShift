local _, ns = ...
local Q = {}
ns.Quality = Q
-- Observation catalog only. Never a write whitelist or a target-value guess.
Q.Candidates = {
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
Q.Descriptions = { currentBaseline = "Keep your existing graphics quality unchanged.",
    balanced = "Balanced detail and cost. Blocked until a complete target set passes native validation.",
    vista = "Scenic distance, foliage and water. Blocked pending native ranges, side-effect mapping and restoration.",
    performance = "Reduced measured rendering cost. Blocked pending native validation and benchmarks." }
function Q.Scan(reader)
    local rows = {}
    for _, candidate in ipairs(Q.Candidates) do
        local row = ns.Value.Copy(candidate)
        row.observation = ns.ReadOnly.Read(reader, row.key)
        row.operational = false
        row.reason = "Not admitted: native domain, dependency closure and restoration are unverified."
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
