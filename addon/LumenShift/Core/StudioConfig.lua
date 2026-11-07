local _, ns = ...
local C, V = {}, ns.Value
ns.StudioConfig = C
C.Order = { "natural", "nightVision", "cinematic", "lantern", "clarity", "moonlight" }
C.Labels = { natural = "Natural", nightVision = "Night Vision", cinematic = "Cinematic",
    lantern = "Lantern", clarity = "Clarity", moonlight = "Moonlight" }
C.Descriptions = {
    natural = "Your captured visual baseline. No presentation effects.",
    nightVision = "Visibility boost with optional phosphor-green tint.",
    cinematic = "Quiet amber atmosphere; optional screenshot letterbox.",
    lantern = "Warm light and a gentle visibility lift for interiors.",
    clarity = "Neutral, unobstructed visibility for regular gameplay.",
    moonlight = "Cool blue atmosphere with configurable visibility.",
}
local function mode(brightness, r, g, b, opacity, vignette)
    return { brightness = brightness, tint = { r = r, g = g, b = b },
        tintEnabled = opacity > 0, opacity = opacity, vignette = vignette,
        letterbox = 0, contrast = 60, useContrast = false }
end
function C.Defaults()
    return { enabled = false, experimentalBrightness = false,
        modes = { natural = mode(50, 1, 1, 1, 0, 0), nightVision = mode(75, 0.25, 1, 0.48, 0.04, 0.04),
            cinematic = mode(42, 1, 0.72, 0.46, 0.025, 0.06), lantern = mode(65, 1, 0.61, 0.20, 0.045, 0.035),
            clarity = mode(70, 1, 1, 1, 0, 0), moonlight = mode(55, 0.35, 0.55, 1, 0.045, 0.04) },
        effects = true, screenshot = false, highContrast = false, scale = 1,
        launcher = { visible = true, x = 80, y = -160 }, audioLevel = "soft",
        presets = {}, nextPreset = 1 }
end
local function number(n, low, high) return V.Finite(n) and n >= low and n <= high end
C.Number = number
function C.ValidateMode(m)
    return V.Fields(m, { brightness = true, tint = true, tintEnabled = true, opacity = true,
        vignette = true, letterbox = true, contrast = true, useContrast = true })
        and number(m.brightness, 0, 100) and number(m.contrast, 0, 100)
        and type(m.useContrast) == "boolean" -- a session-calibrated target is still required before writing
        and V.Fields(m.tint, { r = true, g = true, b = true })
        and number(m.tint.r, 0, 1) and number(m.tint.g, 0, 1) and number(m.tint.b, 0, 1)
        and type(m.tintEnabled) == "boolean" and number(m.opacity, 0, 0.12)
        and number(m.vignette, 0, 0.15) and number(m.letterbox, 0, 0.12)
end
function C.Name(value)
    return type(value) == "string" and #value >= 1 and #value <= 40
        and value:match("%S") ~= nil and not value:find("[%c|]")
end
function C.Validate(data)
    if not V.Fields(data, { enabled = true, experimentalBrightness = true, modes = true, effects = true,
        screenshot = true, highContrast = true, scale = true, launcher = true, audioLevel = true,
        presets = true, nextPreset = true }) or type(data.modes) ~= "table" then return false end
    for _, key in ipairs({ "enabled", "experimentalBrightness", "effects", "screenshot", "highContrast" }) do
        if type(data[key]) ~= "boolean" then return false end
    end
    if not number(data.scale, 0.75, 1.5) or not V.Fields(data.launcher, { visible = true, x = true, y = true })
        or type(data.launcher.visible) ~= "boolean" or not number(data.launcher.x, -10000, 10000)
        or not number(data.launcher.y, -10000, 10000) or (data.audioLevel ~= "soft" and data.audioLevel ~= "normal")
        or type(data.presets) ~= "table" or not number(data.nextPreset, 1, 1000000)
        or data.nextPreset % 1 ~= 0 then return false end
    for _, id in ipairs(C.Order) do if not C.ValidateMode(data.modes[id]) then return false end end
    for id in pairs(data.modes) do if not C.Labels[id] then return false end end
    local count = 0
    for id, preset in pairs(data.presets) do
        count = count + 1
        if count > 24 or type(id) ~= "string" or not id:match("^p%d+$")
            or not V.Fields(preset, { name = true, mode = true, settings = true })
            or not C.Name(preset.name) or not C.Labels[preset.mode] or preset.mode == "natural"
            or not C.ValidateMode(preset.settings) then return false end
    end
    return true
end
function C.SavePreset(data, name, modeID)
    local copy = V.Copy(data)
    if not copy or not C.Validate(copy) or not C.Name(name) or not C.Labels[modeID] or modeID == "natural" then
        return nil, "INVALID_PRESET"
    end
    local count = 0
    for _ in pairs(copy.presets) do count = count + 1 end
    if count >= 24 or copy.nextPreset >= 1000000 then return nil, "PRESET_LIMIT" end
    local id = "p" .. copy.nextPreset
    if copy.presets[id] then return nil, "PRESET_ID_CONFLICT" end
    copy.nextPreset = copy.nextPreset + 1
    copy.presets[id] = { name = name, mode = modeID, settings = V.Copy(copy.modes[modeID]) }
    return copy, id
end
function C.LoadPreset(data, id)
    local copy = V.Copy(data)
    if not copy or not C.Validate(copy) or not copy.presets[id] then return nil, "UNKNOWN_PRESET" end
    local preset = copy.presets[id]
    copy.modes[preset.mode] = V.Copy(preset.settings)
    return copy, preset.mode
end
