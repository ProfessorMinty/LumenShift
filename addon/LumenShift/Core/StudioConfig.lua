local _, ns = ...
local C, V = {}, ns.Value
ns.StudioConfig = C
C.Order = { "natural", "nightVision", "cinematic", "lantern", "clarity", "moonlight" }
C.Labels = { natural = "Original", nightVision = "Night Vision", cinematic = "Cinematic",
    lantern = "Lantern", clarity = "Clarity", moonlight = "Moonlight" }
C.Descriptions = {
    natural = "Your chosen Original or Game Defaults look. No presentation effects.",
    nightVision = "Visibility boost with optional phosphor-green tint.",
    cinematic = "Quiet amber atmosphere; optional screenshot letterbox.",
    lantern = "Warm tint and a gentle visibility lift for interiors.",
    clarity = "Neutral, unobstructed visibility for regular gameplay.",
    moonlight = "Cool blue atmosphere with configurable visibility.",
}
function C.Label(id)
    if id == "natural" and ns.runtime and ns.runtime.db then return ns.Baseline.Label(ns.runtime.db.baseline) end
    return C.Labels[id]
end
local function mode(brightness, r, g, b, opacity, vignette)
    return { brightness = brightness, tint = { r = r, g = g, b = b },
        tintEnabled = opacity > 0, opacity = opacity, vignette = vignette,
        letterbox = 0, contrast = 60, useContrast = false,
        brightnessMode = "custom", sharpening = "inherit", detail = 50,
        useBloom = false, bloom = 0, styling = "goggles" }
end
function C.Defaults()
    local defaults = { enabled = false, experimentalBrightness = false,
        modes = { natural = mode(50, 1, 1, 1, 0, 0), nightVision = mode(75, 0.25, 1, 0.48, 0.04, 0.04),
            cinematic = mode(42, 1, 0.72, 0.46, 0.025, 0.06), lantern = mode(65, 1, 0.61, 0.20, 0.045, 0.035),
            clarity = mode(70, 1, 1, 1, 0, 0), moonlight = mode(55, 0.35, 0.55, 1, 0.045, 0.04) },
        effects = true, screenshot = false, highContrast = false, scale = 1,
        launcher = { visible = true, x = 80, y = -160 }, audioLevel = "soft",
        presets = {}, nextPreset = 1 }
    defaults.modes.clarity.brightnessMode, defaults.modes.clarity.styling = "inherit", "clear"
    return defaults
end
function C.UpgradeMode(m)
    if type(m) ~= "table" then return end
    -- Preserve every existing look, including customized Clarity brightness/style.
    local additions = { brightnessMode = "custom", sharpening = "inherit", detail = 50,
        useBloom = false, bloom = 0, styling = "goggles" }
    for key, value in pairs(additions) do if m[key] == nil then m[key] = value end end
end
local function number(n, low, high) return V.Finite(n) and n >= low and n <= high end
C.Number = number
function C.ValidateMode(m)
    return V.Fields(m, { brightness = true, tint = true, tintEnabled = true, opacity = true,
        vignette = true, letterbox = true, contrast = true, useContrast = true,
        brightnessMode = true, sharpening = true, detail = true, useBloom = true, bloom = true, styling = true })
        and number(m.brightness, 0, 100) and number(m.contrast, 0, 100)
        and type(m.useContrast) == "boolean" -- validated on each explicit Apply
        and V.Fields(m.tint, { r = true, g = true, b = true })
        and number(m.tint.r, 0, 1) and number(m.tint.g, 0, 1) and number(m.tint.b, 0, 1)
        and type(m.tintEnabled) == "boolean" and number(m.opacity, 0, 0.12)
        and number(m.vignette, 0, 0.15) and number(m.letterbox, 0, 0.12)
        and (m.brightnessMode == "custom" or m.brightnessMode == "inherit")
        and (m.sharpening == "inherit" or m.sharpening == "custom" or m.sharpening == "off")
        and number(m.detail, 0, 100) and m.detail % 5 == 0
        and type(m.useBloom) == "boolean" and number(m.bloom, 0, 1)
        and math.abs(m.bloom * 5 - math.floor(m.bloom * 5 + 0.5)) < 0.000001
        and (m.styling == "clear" or m.styling == "goggles")
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

-- Fixed data-only format; no executable text, arbitrary keys or quality state.
function C.ExportPreset(data, id)
    if not C.Validate(data) or not data.presets[id] then return nil, "UNKNOWN_PRESET" end
    local p = data.presets[id]; local m = p.settings
    local fields = { "LSMODE2", p.mode, m.brightness, m.brightnessMode, m.contrast, m.useContrast and 1 or 0,
        m.sharpening, m.detail, m.useBloom and 1 or 0, m.bloom, m.styling, m.tintEnabled and 1 or 0,
        m.tint.r, m.tint.g, m.tint.b, m.opacity, m.vignette, m.letterbox }
    return table.concat(fields, ";")
end
function C.ImportPreset(data, name, text)
    if type(text) ~= "string" or #text > 2048 or text:find("[%c|]") then return nil, "INVALID_PRESET_DATA" end
    local f = {}; for field in text:gmatch("[^;]+") do f[#f + 1] = field end
    if #f ~= 18 or table.concat(f, ";") ~= text or f[1] ~= "LSMODE2" or not C.Labels[f[2]] or f[2] == "natural" then return nil, "INVALID_PRESET_DATA" end
    for _, i in ipairs({ 6, 9, 12 }) do if f[i] ~= "0" and f[i] ~= "1" then return nil, "INVALID_PRESET_DATA" end end
    local m = { brightness = V.Number(f[3]), brightnessMode = f[4], contrast = V.Number(f[5]), useContrast = f[6] == "1",
        sharpening = f[7], detail = V.Number(f[8]), useBloom = f[9] == "1", bloom = V.Number(f[10]), styling = f[11],
        tintEnabled = f[12] == "1", tint = { r = V.Number(f[13]), g = V.Number(f[14]), b = V.Number(f[15]) },
        opacity = V.Number(f[16]), vignette = V.Number(f[17]), letterbox = V.Number(f[18]) }
    if not C.ValidateMode(m) then return nil, "INVALID_PRESET_DATA" end
    local copy, id = C.SavePreset(data, name, f[2])
    if not copy then return nil, id end
    copy.presets[id].settings = m
    return copy, id
end
