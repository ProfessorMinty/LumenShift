local _, ns = ...
local M, V = {}, ns.Value
ns.Modes = M
-- Authored starting looks, not native defaults or measured optimal values.
M.Variants = {
    nightVision = {
        { name = "Clear vision", note = "Readable darkness and detail, without a colored overlay.", brightness = 75, detail = 70, clear = true },
        { name = "Goggles", note = "The same native visibility with restrained green styling.", brightness = 75, detail = 70, opacity = 0.025, vignette = 0.025 },
    },
    clarity = {
        { name = "Clean detail", note = "Neutral light, crisp detail and an unobstructed view.", inherit = true, detail = 65, clear = true },
        { name = "Low glare", note = "Neutral detail with optional native bloom reduction.", inherit = true, detail = 65, clear = true, bloom = 0 },
    },
    cinematic = {
        { name = "Atmosphere", note = "Deeper light, gentle amber styling and modest detail.", brightness = 42, detail = 55, opacity = 0.015, vignette = 0.025 },
        { name = "Soft film", note = "Softer contrast and optional bloom; framing remains separately enabled.", brightness = 48, contrast = 58, detail = 60, bloom = 0.6, opacity = 0.015, vignette = 0.02, letterbox = 0.06 },
    },
    lantern = {
        { name = "Warm interior", note = "Comfortable exposure and a subtle warm tint; no new world light.", brightness = 65, detail = 55, opacity = 0.025, vignette = 0.02 },
        { name = "Clear interior", note = "Interior visibility without tint or screen edges.", brightness = 65, detail = 60, clear = true },
    },
    moonlight = {
        { name = "Cool night", note = "A modest visibility lift with restrained cool styling.", brightness = 55, detail = 60, opacity = 0.02, vignette = 0.025 },
        { name = "Quiet night", note = "Keep more night atmosphere with less tint and gentler detail.", brightness = 50, detail = 55, opacity = 0.01, vignette = 0.015 },
    },
}
function M.Variant(id, index)
    local item = M.Variants[id] and M.Variants[id][index]
    if not item then return nil, "UNKNOWN_STARTING_LOOK" end
    local mode = ns.StudioConfig.Defaults().modes[id]
    mode.brightnessMode = item.inherit and "inherit" or "custom"
    mode.brightness = item.brightness or mode.brightness
    mode.sharpening, mode.detail = "custom", item.detail
    mode.useContrast, mode.contrast = item.contrast ~= nil, item.contrast or mode.contrast
    mode.useBloom, mode.bloom = item.bloom ~= nil, item.bloom or 0
    mode.styling = item.clear and "clear" or "goggles"
    mode.opacity, mode.vignette, mode.letterbox = item.opacity or 0, item.vignette or 0, item.letterbox or 0
    return mode
end
-- Pure interpolation of LIGHT and cosmetic intensity. Detail/bloom stay independent.
function M.Evaluate(mode, home)
    if not ns.StudioConfig.ValidateMode(mode) then return nil, "INVALID_MODE_CONFIG" end
    local result, fraction = V.Copy(mode), mode.intensity / 100
    for _, key in ipairs({ "brightness", "contrast" }) do
        local used = key == "brightness" and mode.brightnessMode == "custom" or key == "contrast" and mode.useContrast
        if used and fraction < 1 then
            local anchor = home[key]
            if not V.Finite(anchor) or anchor < 0 or anchor > 100 then return nil, "BASELINE_VALUE_UNAVAILABLE:" .. key end
            result[key] = fraction == 0 and anchor or math.floor(anchor + (mode[key] - anchor) * fraction + 0.5)
        end
    end
    if fraction == 0 then result.brightnessMode, result.useContrast = "inherit", false end
    result.opacity, result.vignette = mode.opacity * fraction, mode.vignette * fraction
    return result
end
function M.Home(runtime)
    local home, db = {}, runtime.db
    for _, key in ipairs({ "Brightness", "Contrast" }) do
        local entry = key == "Brightness" and db.journal.entries[key] or db.experiments.journal.entries[key]
        local raw = db.baseline.chosen and db.baseline.values[key] or entry and entry.originalRaw
        if not raw then raw = ns.ReadOnly.Read(runtime.reader, key).raw end
        home[key:lower()] = V.Number(raw)
    end
    return home
end
-- Optional omissions are reported before Apply and again after success. Existing
-- ownership is never discarded: an unavailable owned key still needs recovery.
function M.Optional(runtime, targets)
    local result, omitted = V.Copy(targets), {}
    local function unavailable(key)
        local item = ns.ReadOnly.Read(runtime.reader, key)
        local capable, reason = ns.ExperimentPolicy.Capability(runtime.reader, key)
        local entry = runtime.db.experiments.journal.entries[key]
        local bounds, boundsReason = ns.ExperimentPolicy.Bounds(key, entry and entry.originalRaw or item.raw)
        return not capable and reason or not ns.Planner.SafeObservation(item) and item.code ~= "OK" and item.code
            or not ns.Planner.SafeObservation(item) and "RESTRICTED" or not bounds and boundsReason
    end
    local sharpReason
    for _, key in ipairs(ns.Optics.Keys) do
        if result[key] ~= nil then
            local reason = unavailable(key)
            if reason then
                omitted[#omitted + 1] = { key = key, reason = reason }
                if not runtime.db.experiments.journal.entries[key] then
                    result[key] = nil
                    if key ~= "bloomUserMult" then sharpReason = reason end
                end
            end
        end
    end
    if sharpReason then -- never half-enable a custom sharpening pair
        for _, key in ipairs({ "ResampleAlwaysSharpen", "ResampleSharpness" }) do
            if result[key] ~= nil and not runtime.db.experiments.journal.entries[key] then result[key] = nil end
        end
    end
    return result, omitted
end
function M.OmissionText(omitted)
    local labels, seen = {}, {}
    for _, item in ipairs(omitted) do
        local label = item.key == "bloomUserMult" and "bloom" or "sharpening"
        if not seen[label] then labels[#labels + 1], seen[label] = label, true end
    end
    return #labels > 0 and "Unavailable: " .. table.concat(labels, ", ") .. ". Other controls can apply; owned changes need Recovery." or nil
end
function M.Reference(runtime)
    return M.Optional(runtime, ns.Optics.Reference(runtime.db.baseline))
end
