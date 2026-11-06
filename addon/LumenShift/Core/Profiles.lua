local _, ns = ...
local P = {}
ns.Profiles = P
local definitions = {
    visual = {
        natural = "Natural", nightVision = "Night Vision", cinematic = "Cinematic",
        lantern = "Lantern", clarity = "Clarity", moonlight = "Moonlight",
    },
    quality = {
        currentBaseline = "Current Baseline", balanced = "Balanced",
        vista = "Vista", performance = "Performance",
    },
}
function P.Definitions()
    local result = { visual = {}, quality = {} }
    for layer, presets in pairs(definitions) do
        for id, label in pairs(presets) do
            result[layer][id] = { id = id, label = label, layer = layer,
                targets = {}, status = "METADATA_ONLY", enabled = false }
        end
    end
    return result
end
function P.ValidSelection(layer, id)
    return definitions[layer] ~= nil and definitions[layer][id] ~= nil
end
function P.Defaults()
    return { selected = { visual = "natural", quality = "currentBaseline" },
        custom = { visual = {}, quality = {} },
        preferences = { sound = false, animation = true, reducedMotion = false },
        studio = ns.StudioConfig.Defaults() }
end
function P.ValidateLegacy(config)
    local V = ns.Value
    if not V.Fields(config, { selected = true, custom = true, preferences = true })
        or not V.Fields(config.selected, { visual = true, quality = true })
        or not P.ValidSelection("visual", config.selected.visual)
        or not P.ValidSelection("quality", config.selected.quality)
        or not V.Fields(config.custom, { visual = true, quality = true }) then return false end
    -- No user targets/imports are admitted in 01A, even under a known preset name.
    for _, layer in ipairs({ "visual", "quality" }) do
        if type(config.custom[layer]) ~= "table" or next(config.custom[layer]) then return false end
    end
    if not V.Fields(config.preferences, { sound = true, animation = true, reducedMotion = true }) then return false end
    for _, key in ipairs({ "sound", "animation", "reducedMotion" }) do
        if type(config.preferences[key]) ~= "boolean" then return false end
    end
    return true
end
function P.Validate(config)
    if not ns.Value.Fields(config, { selected = true, custom = true, preferences = true, studio = true }) then return false end
    return P.ValidateLegacy({ selected = config.selected, custom = config.custom, preferences = config.preferences })
        and ns.StudioConfig.Validate(config.studio)
end
