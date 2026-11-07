local _, ns = ...
local S, W = {}, ns.Widgets
ns.Studio = S
local pages = {
    { "Visual Modes", "Choose a look, tune it, then apply when you're ready." },
    { "Graphics Quality", "Independent quality profiles. Your visual mode stays as it is." },
    { "Colors & Effects", "Optional screen tint, soft edges and screenshot framing." },
    { "Audio", "Small cues for switching modes. Your game volume stays as it is." },
    { "Personal Presets", "Save your favorite variations and make them your own." },
    { "Accessibility", "Make LumenShift comfortable to read and use." },
    { "Diagnostic Center", "Check addon health, export a report or recover captured settings." },
    { "Advanced Graphics", "Explore individual settings with a temporary Test & Restore." },
    { "Camera", "A clear view for screenshots, with optional floating-name controls." },
}
local modeNotes = { natural = "Your original settings", nightVision = "See more in low light", cinematic = "A dramatic, softer look",
    lantern = "Warm and welcoming", clarity = "Clean, readable detail", moonlight = "Cool and atmospheric" }
local pageIcons = { "ui-modes", "ui-quality", "ui-effects", "ui-audio", "ui-presets", "ui-accessibility", "ui-diagnostics", "ui-advanced", "ui-camera" }
function S.New(runtime)
    local env, db, product = runtime.reader.env, runtime.db, runtime.product
    local ui = { page = 1, edited = "nightVision", pageFrames = {}, nav = {} }
    if not db or not env.UIParent then return ui end
    local function cfg() return db.config.studio end
    local function update(fn) return product.Update(fn) end
    local function emit(code) if code then ns.Diagnostics.Emit(runtime, "LumenShift: " .. ns.Product.Message(code)) end end
    local window = env.CreateFrame("Frame", "LumenShiftStudio", env.UIParent)
    ui.window = window
    window:SetSize(1120, 740); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true); window:SetMovable(true); window:EnableMouse(true); window:RegisterForDrag("LeftButton")
    W.Script(window, "OnDragStart", function(self) if not product.IsCombat() then self:StartMoving() end end)
    W.Script(window, "OnDragStop", function(self) self:StopMovingOrSizing() end)
    W.Script(window, "OnHide", function(self) if self.lumenFade then self.lumenFade:Stop() end end)
    ui.background = W.Fill(window, W.colors.bg)
    ui.panelArt = W.Art(window, "panel-steel", 1, -1, 1118, 738, 0.48, "BACKGROUND")
    ui.headerArt = W.Art(window, "light-sweep", 588, -8, 500, 102, 0.48, "BACKGROUND")
    ui.headerArt:SetTexCoord(0, 1, 0.32, 0.73); W.Border(window)
    local sidebar = env.CreateFrame("Frame", nil, window); sidebar:SetSize(220, 738); sidebar:SetPoint("TOPLEFT", 1, -1)
    ui.sidebar = W.Fill(sidebar, W.colors.sidebar)
    ui.sidebarArt = W.Art(sidebar, "panel-midnight", 0, 0, 220, 738, 0.17, "BACKGROUND")
    local logo = W.Texture(sidebar, "ARTWORK"); logo:SetSize(42, 42); logo:SetPoint("TOPLEFT", 18, -29)
    W.Asset(logo, "Interface/AddOns/LumenShift/Media/logo.tga")
    W.Text(sidebar, "LumenShift", 68, -31, 143, 20)
    W.Text(sidebar, "NORTHERN LIGHTS LABS", 69, -59, 140, 9, W.colors.muted)
    W.Rule(sidebar, 18, -94, 184)
    ui.title = W.Text(window, "", 252, -30, 735, 28)
    ui.subtitle = W.Text(window, "", 253, -75, 805, 14, W.colors.muted)
    W.ButtonIcon(W.Button(env, window, "Close", 996, -24, 100, function() window:Hide() end, nil, "quiet"), "ui-close", 14)
    W.Rule(window, 252, -111, 836)
    ui.status = W.Text(window, "", 253, -132, 830, 12, W.colors.muted)
    W.Rule(window, 252, -678, 836)
    ui.footer = W.Text(window, "", 253, -698, 520, 12, W.colors.muted)
    ui.primary = W.Button(env, window, "", 798, -695, 290, function() end, nil, "primary")
    ui.primary:SetHeight(32)
    W.ButtonIcon(ui.primary, "ui-modes", 16)
    function ui.Primary(label, fn, hint)
        ui.hint = hint or "Preferences save as you edit. Apply changes your current view."
        if label then
            ui.primary.label:SetText(label); W.Script(ui.primary, "OnClick", fn); ui.primary:Show()
            W.Asset(ui.primary.icon, "Interface/AddOns/LumenShift/Media/" .. (ui.page == 7 and "ui-export" or pageIcons[ui.page]) .. ".tga")
        else ui.primary:Hide(); W.Script(ui.primary, "OnClick", nil) end
    end
    local scroll = env.CreateFrame("ScrollFrame", nil, window); ui.scroll = scroll
    scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 252, -184); scroll:SetSize(836, 474); scroll:EnableMouseWheel(true)
    local scrollBar = env.CreateFrame("Slider", nil, window)
    ui.scrollBar = scrollBar
    scrollBar:SetPoint("TOPLEFT", window, "TOPLEFT", 1098, -184); scrollBar:SetSize(5, 474)
    scrollBar:SetOrientation("VERTICAL"); scrollBar:SetMinMaxValues(0, 1); scrollBar:SetValueStep(24)
    W.Fill(scrollBar, W.colors.sidebar)
    local thumb = W.Texture(scrollBar, "OVERLAY"); thumb:SetSize(5, 38); thumb:SetColorTexture(unpack(W.colors.muted)); scrollBar:SetThumbTexture(thumb)
    W.Script(scrollBar, "OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
    W.Script(scroll, "OnMouseWheel", function(_, delta)
        scrollBar:SetValue(math.max(0, math.min(ui.scrollMaximum or 0, scroll:GetVerticalScroll() - delta * 36)))
    end)
    function ui.Refresh()
        local status, current = runtime.engine.Status(), ns.ReadOnly.Read(runtime.reader, "Brightness")
        local states = { BASELINE = "Ready", ACTIVE = "Applied", RECOVERY = "Recovery available",
            CONFLICT = "External change preserved", AWAITING_VERIFICATION = "Checking change..." }
        local state = product.busy and "Checking change..." or states[status.state] or status.state
        ui.status:SetText("ACTIVE  " .. ns.StudioConfig.Labels[product.active] .. "     /     QUALITY  "
            .. (ns.Quality.Profiles[db.config.selected.quality] or "Current Baseline") .. "     /     BRIGHTNESS  "
            .. (current.raw or "unavailable") .. "     /     " .. state)
        local lab = runtime.lab and runtime.lab.Status()
        ui.footer:SetText(product.lastMessage or ns.Product.Message(lab and lab.error) or ns.Product.Message(status.error) or ui.hint or "")
        if ui.labStateText and lab then
            local states = { BASELINE = "Original settings restored.", ACTIVE = "Settings applied.", APPLYING = "Applying...",
                AWAITING_VERIFICATION = "Checking the change...", RECOVERY = "Recovery is available below.", CONFLICT = "An external change was kept. Review recovery below." }
            ui.labStateText:SetText(ns.Product.Message(lab.error) or (lab.operation == "PREVIEW" and "Preview ready. No change yet.") or states[lab.state] or lab.state)
        end
        if ui.trialStateText and runtime.tierTrial then
            local trial = runtime.tierTrial.Status()
            ui.trialStateText:SetText("Trial: " .. trial.state .. (trial.error and " — " .. ns.Product.Message(trial.error) or ""))
        end
        if ui.cameraStateText then
            local player, pet = ns.ReadOnly.Read(runtime.reader, "UnitNameFriendlyPlayerName"), ns.ReadOnly.Read(runtime.reader, "UnitNameFriendlyPetName")
            ui.cameraStateText:SetText("PLAYER NAMES  " .. (player.raw or "unavailable") .. "     /     PET NAMES  " .. (pet.raw or "unavailable")
                .. "\n" .. (runtime.camera.error and ns.Product.Message(runtime.camera.error) or runtime.names.Status().state))
        end
        if ui.page == 9 then ui.primary.label:SetText(runtime.camera.active and "Exit Camera Mode" or "Enter Camera Mode — hide interface") end
        if ui.radial then ui.radial.Refresh() end
    end
    function ui.BuildPage()
        ns.Log.Record(runtime.reader, "studio", "page", "DEBUG", "OPEN", { count = ui.page })
        for _, frame in pairs(ui.pageFrames) do frame:Hide() end
        ui.labStateText, ui.trialStateText, ui.cameraStateText = nil, nil, nil
        ui.title:SetText(pages[ui.page][1]); ui.subtitle:SetText(pages[ui.page][2])
        for id, button in pairs(ui.nav) do button.SetSelected(id == ui.page) end
        local key = ui.page .. ":" .. ((ui.page == 1 or ui.page == 3) and ui.edited or "shared")
        ui.cache = ui.cache or {}
        local parent = ui.cache[key] or env.CreateFrame("Frame", nil, scroll)
        parent.pool = parent.pool or W.CreatePool(env, parent); parent.pool.Reset()
        local env = parent.pool.env
        parent:SetSize(836, 474); scroll:SetScrollChild(parent)
        parent:ClearAllPoints(); parent:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
        ui.pageFrames[ui.page], ui.cache[key] = parent, parent
        local height = 474
        local function text(label, x, y, width, size, color) return W.Text(parent, label, x, y, width, size or 13, color) end
        local function button(label, x, y, width, fn, style) return W.Button(env, parent, label, x, y, width, fn, nil, style) end
        local function toggle(label, x, y, width, get, set) return W.Toggle(env, parent, label, x, y, width, get, set) end
        local function section(label, y) W.Section(parent, label, 0, y, 836) end
        local function editMode(field, value) return update(function(copy) copy.studio.modes[ui.edited][field] = value end) end
        ui.Primary(nil, nil, "Preferences save as you edit.")
        if ui.page == 1 then
            for i, id in ipairs(ns.StudioConfig.Order) do
                local selected = id
                W.Card(env, parent, ns.StudioConfig.Labels[id], modeNotes[id], ((i - 1) % 3) * 284,
                    -math.floor((i - 1) / 3) * 94, 268, 82, ui.edited == id,
                    function() ui.edited = selected; ui.BuildPage() end, "Interface/AddOns/LumenShift/Media/" .. id .. ".tga")
            end
            section("LIGHT & CONTRAST", -210)
            if ui.edited ~= "natural" then
                W.Slider(env, parent, "Brightness", 0, -252, 0, 100, 1, function() return cfg().modes[ui.edited].brightness end,
                    function(value) return editMode("brightness", value) end, nil, 398)
                W.Slider(env, parent, "Contrast", 438, -252, 0, 100, 1, function() return cfg().modes[ui.edited].contrast end,
                    function(value) return editMode("contrast", value) end, nil, 398)
                toggle("Adjust Contrast with this mode", 438, -319, 398, function() return cfg().modes[ui.edited].useContrast end,
                    function(value) return editMode("useContrast", value) end)
                text("Adjustments apply when you click Apply.", 0, -325, 398, 12, W.colors.muted)
            else
                text("Return to your original light and contrast.", 0, -254, 800, 18)
                text("Natural restores the exact settings captured before LumenShift took control. Your quality profile stays independent.", 0, -292, 800, 14, W.colors.muted)
            end
            button("Reset this mode's saved settings", 0, -389, 284, function()
                local selected = ui.edited
                update(function(copy) copy.studio.modes[selected] = ns.StudioConfig.Defaults().modes[selected] end)
                ui.Invalidate(1); ui.Invalidate(3); ui.BuildPage()
            end, "quiet")
            ui.Primary("Apply " .. ns.StudioConfig.Labels[ui.edited], function() product.Select(ui.edited) end)
        elseif ui.page == 2 then
            ui.qualityID = ui.qualityID or db.config.selected.quality
            local descriptions = { currentBaseline = "Restore your captured quality settings.", balanced = "Sharpen the image. Preserve scene detail.",
                vista = "Favor landscape detail and viewing distance.", performance = "Reduce detail and distance for a lighter view." }
            for i, id in ipairs({ "currentBaseline", "balanced", "vista", "performance" }) do
                local selected = id
                W.Card(env, parent, ns.Quality.Profiles[id], descriptions[id], ((i - 1) % 2) * 430,
                    -math.floor((i - 1) / 2) * 110, 406, 96, ui.qualityID == id, function() ui.qualityID = selected; ui.BuildPage() end)
            end
            section("PROFILE DETAILS", -242)
            local targets, omitted, source = ns.Quality.Resolve(runtime, ui.qualityID)
            local labels = {}; for _, candidate in ipairs(ns.Quality.Candidates) do labels[candidate.key] = candidate.label end
            local details = {}
            for _, keyName in ipairs(ns.Value.Keys(targets or {})) do details[#details + 1] = (labels[keyName] or keyName) .. ": " .. targets[keyName] end
            text(ui.qualityID == "currentBaseline" and "Restore only the quality settings owned by LumenShift."
                or (#details > 0 and table.concat(details, "   /   ") or "No usable targets available on this client."), 0, -286, 836, 13)
            text(source == "custom" and "Using your saved custom values." or "Built-in targets are based on your captured originals.", 0, -358, 836, 12, W.colors.muted)
            if type(omitted) == "table" and #omitted > 0 then
                text("Unavailable settings are omitted (" .. #omitted .. "). Details are in the diagnostic report.", 0, -383, 836, 12, W.colors.muted)
            elseif not targets then text(ns.Product.Message(omitted), 0, -383, 836, 12, W.colors.warning) end
            button("Edit individual quality settings", 0, -424, 280, function() ui.labKey = "ResampleSharpness"; ui.Open(8) end, "quiet")
            ui.Primary(ui.qualityID == "currentBaseline" and "Restore quality baseline" or "Apply " .. ns.Quality.Profiles[ui.qualityID], function()
                local ok, code = runtime.lab.SelectProfile(ui.qualityID); if not ok then emit(code) end; ui.Refresh()
            end, "Selecting a card previews it. Apply changes quality only.")
        elseif ui.page == 3 then
            toggle("Enable screen effects", 0, 0, 406, function() return cfg().effects end,
                function(value) update(function(copy) copy.studio.effects = value end); product.RefreshPresentation() end)
            for i, id in ipairs(ns.StudioConfig.Order) do
                local selected = id
                local b = button(ns.StudioConfig.Labels[id], (i - 1) * 141, -58, 131, function() ui.edited = selected; ui.BuildPage() end)
                b.SetSelected(id == ui.edited)
            end
            section("TINT & SOFT EDGES", -116)
            toggle("Tint for " .. ns.StudioConfig.Labels[ui.edited], 0, -155, 398, function() return cfg().modes[ui.edited].tintEnabled end,
                function(value) editMode("tintEnabled", value) end)
            for i, item in ipairs({ { "Tint opacity", "opacity", 0.12 }, { "Vignette", "vignette", 0.15 } }) do
                local field = item[2]
                W.Slider(env, parent, item[1], 0, -201 - (i - 1) * 70, 0, item[3], 0.01,
                    function() return cfg().modes[ui.edited][field] end, function(value) return editMode(field, value) end, nil, 398)
            end
            for i, channel in ipairs({ "r", "g", "b" }) do
                local c = channel
                W.Slider(env, parent, ({ "Red", "Green", "Blue" })[i], 438, -155 - (i - 1) * 70, 0, 1, 0.01,
                    function() return cfg().modes[ui.edited].tint[c] end,
                    function(value) return update(function(copy) copy.studio.modes[ui.edited].tint[c] = value end) end, nil, 398)
            end
            section("SCREENSHOT FRAMING", -365)
            toggle("Screenshot letterbox", 0, -407, 398, function() return cfg().screenshot end,
                function(value) update(function(copy) copy.studio.screenshot = value end); product.RefreshPresentation() end)
            W.Slider(env, parent, "Letterbox height", 438, -407, 0, 0.12, 0.01, function() return cfg().modes[ui.edited].letterbox end,
                function(value) return editMode("letterbox", value) end, nil, 398)
            ui.Primary("Apply effects to active mode", product.RefreshPresentation, "Screen overlays; letterbox hides automatically in combat.")
        elseif ui.page == 4 then
            section("PLAYBACK", 0)
            toggle("Activation / deactivation sounds", 0, -43, 406, function() return db.config.preferences.sound end,
                function(value) update(function(copy) copy.preferences.sound = value end); if not value then runtime.audio.Stop() end end)
            text("Plays after a successful mode switch, through the game's SFX channel.", 0, -91, 790, 14, W.colors.muted)
            section("CUE LEVEL", -155)
            for i, id in ipairs({ "soft", "normal" }) do
                local level = id
                W.Card(env, parent, id == "soft" and "Soft" or "Normal", id == "soft" and "A quieter cue." or "The original cue level.",
                    (i - 1) * 430, -199, 406, 88, cfg().audioLevel == id, function()
                        update(function(copy) copy.studio.audioLevel = level end); ui.BuildPage()
                    end)
            end
            button("Preview deactivation cue", 0, -331, 250, function() local _, code = runtime.audio.Play("off", db.config); emit(code) end)
            button("Stop current cue", 270, -331, 186, function() runtime.audio.Stop() end, "quiet")
            ui.Primary("Preview activation cue", function() local _, code = runtime.audio.Play("on", db.config); emit(code) end,
                "Enable sounds to hear a preview. Global volume is unchanged.")
        elseif ui.page == 5 then
            section("SAVE A VARIATION", 0)
            text("Based on " .. ns.StudioConfig.Labels[ui.edited], 0, -44, 800, 14, W.colors.muted)
            local name = W.Edit(env, parent, "My " .. ns.StudioConfig.Labels[ui.edited], 0, -77, 406, function() end)
            button("Edit source mode", 430, -77, 180, function() ui.Open(1) end, "quiet")
            ui.Primary("Save variation", function() product.SavePreset(name:GetText(), ui.edited); ui.BuildPage() end,
                "Presets save mode settings. Quality profiles stay separate.")
            section("YOUR PRESETS", -143)
            local ids = ns.Value.Keys(cfg().presets)
            if #ids == 0 then text("Your saved looks will appear here.", 0, -190, 800, 16, W.colors.muted) end
            for i, id in ipairs(ids) do
                local presetID, preset = id, cfg().presets[id]
                local x, y = ((i - 1) % 2) * 430, -187 - math.floor((i - 1) / 2) * 118
                text(ns.StudioConfig.Labels[preset.mode], x, y, 406, 12, W.colors.muted)
                W.Edit(env, parent, preset.name, x, y - 24, 406, function(value)
                    if ns.StudioConfig.Name(value) then update(function(copy) copy.studio.presets[presetID].name = value end) end
                end)
                button("Apply", x, y - 64, 100, function() product.LoadPreset(presetID); ui.Invalidate(1); ui.Invalidate(3) end)
                button("Delete", x + 118, y - 64, 100, function() update(function(copy) copy.studio.presets[presetID] = nil end); ui.BuildPage() end, "quiet")
            end
            height = math.max(474, 200 + math.ceil(#ids / 2) * 118)
        elseif ui.page == 6 then
            section("COMFORT & READABILITY", 0)
            toggle("Reduced motion", 0, -44, 398, function() return db.config.preferences.reducedMotion end,
                function(value) update(function(copy) copy.preferences.reducedMotion = value end) end)
            toggle("Menu fade animation", 438, -44, 398, function() return db.config.preferences.animation end,
                function(value) update(function(copy) copy.preferences.animation = value end) end)
            toggle("High-contrast panel", 0, -90, 398, function() return cfg().highContrast end,
                function(value) update(function(copy) copy.studio.highContrast = value end); ui.Size() end)
            toggle("Show draggable launcher", 438, -90, 398, function() return cfg().launcher.visible end,
                function(value) update(function(copy) copy.studio.launcher.visible = value end) end)
            W.Slider(env, parent, "Studio scale", 0, -148, 0.75, 1.5, 0.05, function() return cfg().scale end,
                function(value) local ok = update(function(copy) copy.studio.scale = value end); ui.Size(); return ok end, nil, 398)
            button("Reset launcher position", 438, -157, 260, function() update(function(copy) copy.studio.launcher.x = 80; copy.studio.launcher.y = -160 end) end)
            section("SHORTCUTS & SETUP", -237)
            text("Assign shortcuts in Key Bindings > LumenShift.\nMode wheel: 1–6, arrows or Tab to choose; Enter to apply; Escape to close.", 0, -278, 820, 14, W.colors.muted)
            button("Setup wizard", 0, -350, 184, function() if runtime.setup then runtime.setup.Open() end end)
            button("Disable controls (restore Natural first)", 206, -350, 360, function() product.Disable() end, "quiet")
            section("ART & CREDITS", -414)
            text("Core UI icons by Streamline · CC BY 4.0 · streamlinehq.com\nMesh Gradients by Craftwork Studio · Lumen Loops by Jon Lehman\nCraftwork Commercial License · craftwork.design/license\nLumenShift logo and original mode artwork · Northern Lights Labs", 0, -455, 820, 12, W.colors.muted)
            height = 550
        elseif ui.page == 7 then
            section("ADDON HEALTH", 0)
            local counts = {}; for _, check in ipairs(runtime.checks or {}) do counts[check.status] = (counts[check.status] or 0) + 1 end
            local results = {}; for _, keyName in ipairs(ns.Value.Keys(counts)) do results[#results + 1] = counts[keyName] .. " " .. keyName end
            text(#results > 0 and table.concat(results, "     /     ") or "Run diagnostics to check current capabilities.", 0, -45, 820, 16)
            button("Run Diagnostics", 0, -86, 200, function() ns.Report.Run(runtime, "user"); ui.BuildPage() end)
            button("Advanced Graphics", 220, -86, 200, function() ui.Open(8) end, "quiet")
            section("BRIGHTNESS RECOVERY", -151)
            local status = runtime.engine.Status()
            local observed = ns.ReadOnly.Read(runtime.reader, "Brightness")
            text("CURRENT  " .. ns.Report.Number(observed.raw) .. "     /     CAPTURED ORIGINAL  " .. ns.Report.Number(status.original)
                .. "     /     " .. status.state, 0, -192, 830, 14)
            button("Natural — restore current-session visual baseline", 0, -235, 430, function() product.Select("natural") end)
            button("Restore My Brightness — preview only", 446, -235, 390, function() runtime.engine.Prepare("restore"); ui.BuildPage() end)
            local y = -285
            if status.token then
                local token = status.token
                text("Review recovery: original " .. ns.Report.Number(status.preview and status.preview.original)
                    .. "   /   current " .. ns.Report.Number(observed.raw) .. "   /   restore to " .. ns.Report.Number(status.preview and status.preview.target), 0, y, 830, 14, W.colors.warning)
                button("Confirm displayed recovery card " .. token, 0, y - 40, 405, function() runtime.engine.Confirm(token); product.Observe(); ui.BuildPage() end)
                y = y - 90
            end
            button("Verify pending recovery (read only)", 0, y, 405, function() runtime.engine.Verify(); product.Observe(); ui.BuildPage() end)
            button("Cancel preview (does not restore graphics)", 430, y, 406, function() runtime.engine.Cancel(); product.Observe(); ui.BuildPage() end, "quiet")
            button(ui.showChecks and "Hide individual checks" or "Show individual checks", 0, y - 55, 240, function() ui.showChecks = not ui.showChecks; ui.BuildPage() end, "quiet")
            y = y - 108
            if ui.showChecks then
                for _, check in ipairs(runtime.checks or {}) do
                    text(check.status .. "  /  " .. check.id .. "\n" .. check.detail, 0, y, 830, 12, W.colors.muted); y = y - 60
                end
            end
            height = math.max(474, -y + 12)
            ui.Primary("Export Complete Diagnostic Report", function() ns.DiagnosticWindow.Open(runtime) end, "Checks and exports do not change graphics settings.")
        elseif ui.page == 8 then
            height = ns.CalibrationUI.Build(runtime, ui, parent, env)
        elseif ui.page == 9 then
            section("A CLEAR VIEW", 0)
            text("Hide the interface. Keep the scene.", 0, -46, 820, 22)
            text("Camera Mode uses the game's Alt+Z behavior. Your visual mode and quality profile stay active.", 0, -86, 820, 14, W.colors.muted)
            toggle("Hide friendly player and pet names in Camera Mode", 0, -138, 620, function() return db.camera.hideWithUI end,
                function(value) db.camera.hideWithUI = value end)
            text("To return: use your Camera Mode keybinding, or press Alt+Z and click Exit Camera Mode. Alt+Z itself only shows the interface; it does not restore names.", 0, -191, 820, 14, W.colors.muted)
            section("FLOATING NAMES", -272)
            ui.cameraStateText = text("", 0, -313, 820, 13, W.colors.muted)
            button("Toggle friendly player and pet names", 0, -378, 406, function() runtime.camera.ToggleNames(); ui.Refresh() end)
            button("Restore original name settings", 430, -378, 406, function() runtime.camera.RestoreNames(); ui.Refresh() end, "quiet")
            ui.Primary("Enter Camera Mode — hide interface", function() runtime.camera.Toggle(); ui.BuildPage() end,
                "Optional shortcut: Key Bindings > LumenShift > Camera Mode.")
        end
        parent:SetHeight(height)
        ui.scrollMaximum = math.max(0, height - 474)
        scrollBar:SetMinMaxValues(0, ui.scrollMaximum); scrollBar:SetValue(0); scroll:SetVerticalScroll(0)
        if ui.scrollMaximum > 0 then scrollBar:Show() else scrollBar:Hide() end
        parent:Show(); ui.Refresh()
    end
    function ui.Invalidate(page)
        if ui.cache then for key, frame in pairs(ui.cache) do if key:match("^" .. page .. ":") then frame.lumenInvalid = true end end end
    end
    function ui.Size()
        local effective = env.UIParent:GetEffectiveScale()
        if not ns.Value.Finite(effective) or effective <= 0 then effective = 1 end
        window:SetScale(math.min(cfg().scale / effective, env.UIParent:GetWidth() / 1168, env.UIParent:GetHeight() / 788))
        ui.background:SetColorTexture(unpack(cfg().highContrast and { 0, 0, 0, 1 } or W.colors.bg))
        ui.sidebar:SetColorTexture(unpack(cfg().highContrast and { 0, 0, 0, 1 } or W.colors.sidebar))
        W.Decoration(ui.panelArt); W.Decoration(ui.sidebarArt); W.Decoration(ui.headerArt)
    end
    function ui.Open(page)
        if product.IsCombat() then emit("Studio is unavailable during combat. Nothing queued."); return end
        product.Observe(); if page then ui.page = page end
        ui.Size(); ui.BuildPage(); window:Show(); W.Fade(window, db.config.preferences)
        ns.Log.Record(runtime.reader, "studio", "open", "INFO", "PASS", { count = ui.page })
    end
    local y = -118
    for _, group in ipairs({ { "WORKSPACE", 1, 2, 9 }, { "PERSONALIZE", 3, 4, 5 }, { "TOOLS", 8, 6, 7 } }) do
        W.Text(sidebar, group[1], 24, y, 184, 10, W.colors.muted); y = y - 26
        for index = 2, #group do
            local page = group[index]
            ui.nav[page] = W.Button(env, sidebar, pages[page][1], 12, y, 196, function() ui.Open(page) end, nil, "nav")
            ui.nav[page]:SetHeight(34); W.ButtonIcon(ui.nav[page], pageIcons[page], 17); y = y - 38
        end
        y = y - 22
    end
    W.Rule(sidebar, 18, -654, 184)
    W.Button(env, sidebar, "Open mode wheel", 12, -671, 196, function() window:Hide(); ui.Wheel() end, nil, "quiet")
    W.Text(sidebar, "VISUAL STUDIO", 24, -716, 184, 9, W.colors.muted)
    if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftStudio") end
    ui.radial = ns.Radial.New(runtime, function() ui.Open() end)
    function ui.CloseWheel() if ui.radial.Close then ui.radial.Close() end; window:Hide() end
    function ui.Wheel() if ui.radial.Toggle then ui.radial.Toggle() end end
    product.Refresh = ui.Refresh
    ns.Log.Record(runtime.reader, "studio", "initialize", "INFO", "PASS")
    window:Hide(); return ui
end
