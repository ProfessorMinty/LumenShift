local _, ns = ...
local U, W = {}, ns.Widgets
ns.OpticsUI = U
function U.Build(runtime, ui, parent, env)
    local db, product = runtime.db, runtime.product
    local function mode() return db.config.studio.modes[ui.edited] end
    local function edit(key, value)
        product.Update(function(copy) copy.studio.modes[ui.edited][key] = value end)
        ui.RebuildInPlace()
    end
    local function text(label, y, color) return W.Text(parent, label, 0, y, 830, 12, color or W.colors.muted) end
    local y = -375
    if ui.edited ~= "natural" then
        W.Section(parent, "STARTING LOOK", 0, y, 836)
        for i, variant in ipairs(ns.Modes.Variants[ui.edited]) do
            local index = i
            local button = W.Button(env, parent, variant.name, (i - 1) * 284, y - 40, 268, function()
                product.Update(function(copy) copy.studio.modes[ui.edited] = ns.Modes.Variant(ui.edited, index) end)
                ui.Invalidate(3); ui.RebuildInPlace()
            end)
            W.Tip(env, button, variant.note)
        end
        text("Choosing a starting look replaces this mode's saved edits. Apply changes the scene; save a personal variation to keep your edits.", y - 89)
        W.Slider(env, parent, "Light & style intensity", 0, y - 137, 0, 100, 5, function() return mode().intensity end,
            function(value) return product.Update(function(copy) copy.studio.modes[ui.edited].intensity = value end) end, nil, 398)
        text("0 uses return-look light and no tint/edges. Detail, bloom and deliberate framing stay independent.", y - 208)
        y = y - 258
        W.Section(parent, "DETAIL", 0, y, 836)
        for i, choice in ipairs({ { "inherit", "Inherit quality" }, { "off", "Off (extra)" }, { "custom", "Custom" } }) do
            local value = choice[1]
            local b = W.Button(env, parent, choice[2], (i - 1) * 136, y - 40, 124, function() edit("sharpening", value) end)
            b.SetSelected(mode().sharpening == value)
        end
        W.Slider(env, parent, "Detail: weak to strong", 438, y - 38, 0, 100, 5, function() return mode().detail end,
            function(value) return product.Update(function(copy) copy.studio.modes[ui.edited].detail = value end) end, nil, 398)
        text("Custom adjusts native sharpening. Off disables extra always-on sharpening; your chosen upscaler may still sharpen.", y - 108)
        local bloom = W.Toggle(env, parent, "Custom bloom / glare", 0, y - 159, 398, function() return mode().useBloom end,
            function(value) edit("useBloom", value) end)
        local supported, reason = ns.ExperimentPolicy.Capability(runtime.reader, "bloomUserMult")
        if not supported and not mode().useBloom then bloom:Disable() end -- an existing override can always be turned off
        W.Slider(env, parent, "Bloom amount: lower is less", 438, y - 160, 0, 1, 0.2, function() return mode().bloom end,
            function(value) return product.Update(function(copy) copy.studio.modes[ui.edited].bloom = value end) end, nil, 398)
        text(supported and "Bloom depends on the scene and renderer. Use Before / After to judge the actual effect."
            or ns.Product.Message(reason), y - 225)
        y = y - 276
        W.Section(parent, "STYLE", 0, y, 836)
        for i, choice in ipairs({ { "clear", "Clear" }, { "goggles", ui.edited == "nightVision" and "Goggles" or "Styled" } }) do
            local value = choice[1]
            local b = W.Button(env, parent, choice[2], (i - 1) * 190, y - 40, 174, function() edit("styling", value) end)
            b.SetSelected(mode().styling == value)
        end
        text("Clear keeps the native visual changes and removes tint, screen edges and bars. Screen effects remain optional.", y - 86)
        y = y - 137
    end
    if ui.edited == "natural" then
        W.Section(parent, "OPTICAL REFERENCE", 0, y, 836)
        local reference = ns.Optics.Reference(db.baseline)
        local labels = {}
        for _, key in ipairs(ns.Value.Keys(reference)) do labels[#labels + 1] = key .. " " .. ns.Report.Number(reference[key]) end
        text(#labels > 0 and table.concat(labels, " / ") or "Return optics are not captured. Include sharpening and bloom in Setup to opt in.", y - 35)
        text("Priority: mode detail, then quality preference, then this return reference. Recovery keeps separate exact originals.", y - 74)
        y = y - 125
    end
    W.Section(parent, "BEFORE / AFTER", 0, y, 836)
    text("Apply a look first. Before shows your return look and underlying quality; After shows the applied look. Finish returns to After.", y - 35)
    for i, choice in ipairs({ { "before", "Before" }, { "after", "After" }, { "done", "Finish comparison" } }) do
        local side = choice[1]
        local button = W.Button(env, parent, choice[2], (i - 1) * 230, y - 88, 214,
            function() product.Compare(side, ui.RebuildInPlace); ui.RebuildInPlace() end)
        local current = db.optics.comparison
        button.SetSelected(current and current.state == side)
        if side ~= "before" and not current then button:Disable() end
    end
    if db.optics.comparison then text("Comparison: " .. db.optics.comparison.state .. ". External changes are preserved; no automatic replay after reload.", y - 135) end
    y = y - 181
    if ui.edited ~= "natural" then
        W.Button(env, parent, "Reset this mode's saved settings", 0, y, 284, function()
            local selected = ui.edited
            product.Update(function(copy) copy.studio.modes[selected] = ns.StudioConfig.Defaults().modes[selected] end)
            ui.Invalidate(1); ui.Invalidate(3); ui.RebuildInPlace()
        end, nil, "quiet")
    end
    if ui.edited ~= "natural" then
        y = y - 66
        W.Button(env, parent, "Explore contact depth (experimental)", 0, y, 340, function()
            ui.labKey, ui.qualityTrials = "assaoDetailShadowStrength", false; ui.Open(8)
        end, nil, "quiet")
        text("A separate, temporary AO detail trial. Effect and motion stability need visual comparison.", y - 47)
        y = y - 60
    end
    return -y + 54
end
