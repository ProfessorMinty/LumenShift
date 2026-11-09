local _, ns = ...
local S, W = {}, ns.Widgets
ns.Setup = S
function S.New(runtime)
    local env, db, product = runtime.reader.env, runtime.db, runtime.product
    local ui = { attempted = false, finishing = false }
    local function tell(message)
        ui.message = message
        if ui.notice then ui.notice:SetText(message) end
        return nil, message
    end
    local function save()
        if not db or not ui.draft then return tell("Preferences could not be loaded. Open Diagnostics for details.") end
        local baseline = ns.Value.Copy(db.baseline)
        if ui.draft.capture or not baseline.chosen or baseline.source ~= ui.draft.baselineSource then
            baseline = ns.Baseline.Capture(runtime, ui.draft.baselineSource, ui.draft.includeOptics)
        end
        if not ns.Baseline.Validate(baseline) then return tell("The baseline choice could not be saved. Try opening setup again.") end
        local saved, why = product.Update(function(copy)
            copy.studio.enabled = true
            copy.studio.effects = ui.draft.effects
            copy.studio.highContrast = ui.draft.highContrast
            copy.studio.launcher.visible = ui.draft.launcher
            copy.preferences.sound = ui.draft.sound
            copy.preferences.animation = ui.draft.animation
            copy.preferences.reducedMotion = ui.draft.reducedMotion
        end)
        if not saved then return tell(why or "Could not save preferences.") end
        db.baseline = baseline
        if ui.draft.graphics then db.graphics.choices = ns.Value.Copy(ui.draft.graphics) end
        product.baselineVerified = false
        ui.draft.capture = false
        -- Apply saved comfort preferences to the already-applied presentation,
        -- not to unrelated mode-editor changes. This never changes CVars.
        product.RefreshPresentation(true)
        if runtime.audio and not db.config.preferences.sound then runtime.audio.Stop() end
        if not db.config.preferences.animation or db.config.preferences.reducedMotion then
            if ui.window then W.Fade(ui.window, db.config.preferences) end
            if runtime.ui and runtime.ui.window then W.Fade(runtime.ui.window, db.config.preferences) end
        end
        if runtime.ui and runtime.ui.BuildPage then runtime.ui.BuildPage(); runtime.ui.Refresh() end
        db.onboarding.completed = true
        ns.Log.Record(runtime.reader, "setup", "save", "INFO", "PREFERENCES_SAVED_NO_GRAPHICS_WRITE")
        return true
    end
    function ui.SaveAndClose()
        if ui.finishing then return nil, "SETUP_BUSY" end
        local saved, why = save(); if not saved then return nil, why end
        if ui.window then ui.window:Hide() end
        return true
    end
    local function reloadNow()
        -- Preference persistence is independent of momentary graphics readiness.
        -- Only the explicit final button requests reload, never a later event.
        if product.IsCombat() then return tell("Preferences saved. Finish reloading after combat, or choose Save & Close.") end
        -- The explicit reload keeps every original/pending journal intact.
        -- A saved recovery record must not prevent finishing preference setup.
        if type(env.ReloadUI) ~= "function" then return tell("Preferences saved. Reload is unavailable; you can close setup and keep playing.") end
        ui.finishing = true
        ns.Log.Record(runtime.reader, "setup", "finish", "INFO", "SAVED_USER_REQUESTED_RELOAD_NO_GRAPHICS_WRITE")
        local result, code = ns.ReadOnly.Call(runtime.reader, env.ReloadUI)
        if not result or result.n ~= 0 then
            ui.finishing = false
            ns.Log.Record(runtime.reader, "setup", "reload", "WARN", code or "UNEXPECTED_RELOAD_RESULT")
            return tell("Preferences saved. Reload did not complete; retry Finish or choose Save & Close.")
        end
        if ui.window then ui.window:Hide() end
        return true
    end
    function ui.Finish()
        if ui.finishing then return nil, "SETUP_BUSY" end
        local saved, why = save(); if not saved then return nil, why end
        if not ns.GraphicsUI.HasChanges(ui.draft.graphics) then return reloadNow() end
        if product.IsCombat() then return tell("Preferences saved. Apply and reload after combat.") end
        if type(env.ReloadUI) ~= "function" then return tell("Preferences saved. Reload is currently unavailable.") end
        ui.finishing = true
        if ui.window then ui.window.lumenInputBlocked = true end
        tell("Applying your graphics choices. The interface will reload when the check finishes.")
        local started, code = runtime.graphics.Apply(ui.draft.graphics, function(ok, errorCode)
            ui.finishing = false
            if ui.window then ui.window.lumenInputBlocked = false end
            if ok then reloadNow() else tell(ns.GraphicsUI.Message(errorCode)) end
        end)
        if not started then ui.finishing = false; if ui.window then ui.window.lumenInputBlocked = false end; return tell(ns.GraphicsUI.Message(code)) end
        return true
    end
    local function contentHeight(height)
        ui.body:SetHeight(math.max(424, height))
        ui.maximum = math.max(0, height - 424)
        local offset = math.min(ui.maximum, ui.scroll:GetVerticalScroll())
        ui.bar:SetMinMaxValues(0, ui.maximum); ui.bar:SetValue(offset); ui.scroll:SetVerticalScroll(offset)
        if ui.maximum > 0 then ui.bar:Show() else ui.bar:Hide() end
    end
    function ui.Build()
        if ui.finishing then return end
        ui.pool.Reset()
        for page, step in ipairs(ui.steps) do step.SetSelected(ui.page == page) end
        if ui.page == 2 then
            contentHeight(ns.GraphicsUI.Build(runtime, ui.pool.env, ui.body, ui.draft.graphics, ui.Build, 580) + 20)
            ui.next.label:SetText(ns.GraphicsUI.HasChanges(ui.draft.graphics) and "Apply & Reload UI" or "Finish & Reload UI")
            ui.notice:SetText(ui.message or "Save & Close stores your choices without applying graphics.")
            W.Script(ui.next, "OnClick", ui.Finish)
            return
        end
        ui.next.label:SetText("Next: Graphics")
        W.Script(ui.next, "OnClick", function() ui.page = 2; ui.scroll:SetVerticalScroll(0); ui.Build() end)
        W.Text(ui.body, "YOUR RETURN MODE", 0, 0, 580, 11, W.colors.muted)
        for index, item in ipairs({
            { "current", "Original", "Capture my current light and contrast." },
            { "gameDefaults", "Game Defaults", "Use the defaults reported by WoW." },
        }) do
            local source = item[1]
            W.Card(ui.pool.env, ui.body, item[2], item[3], (index - 1) * 300, -24, 280, 90,
                ui.draft.baselineSource == source, function()
                    ui.draft.baselineSource, ui.draft.capture = source, true
                    ui.Build()
                end)
        end
        local preview = db.baseline
        if ui.draft.capture or not preview.chosen or preview.source ~= ui.draft.baselineSource then
            preview = ns.Baseline.Capture(runtime, ui.draft.baselineSource, ui.draft.includeOptics)
        end
        W.Text(ui.body, ns.Baseline.Summary(preview), 0, -124, 580, 12, W.colors.accent)
        local count = 0; for key in pairs(preview.values) do if ns.Optics.Known(key) then count = count + 1 end end
        W.Text(ui.body, ui.draft.includeOptics and ("Optics captured: " .. count .. "/3 available. Quality profiles still take precedence.")
            or "Light and contrast only. Saving does not apply them.", 0, -147, 580, 12, W.colors.muted)
        W.Button(ui.pool.env, ui.body, "Capture again", 0, -176, 130, function() ui.draft.capture = true; ui.Build() end, nil, "quiet")
        W.Text(ui.body, "Active modes keep their pre-mode originals when captured.", 150, -184, 430, 11, W.colors.muted)
        W.Toggle(ui.pool.env, ui.body, "Include sharpening and bloom in return look", 0, -208, 580,
            function() return ui.draft.includeOptics end,
            function(value) ui.draft.includeOptics, ui.draft.capture = value, true; ui.Build() end)
        local choices = {
            { "Screen effects", "Tint and soft screen edges", "effects" },
            { "Night Vision sounds", "Play the on / off cue", "sound" },
            { "Menu animations", "Short menu fades", "animation" },
            { "Reduced motion", "Turn off menu animation", "reducedMotion" },
            { "High contrast", "Darker Studio background", "highContrast" },
            { "On-screen launcher", "A movable button for your modes", "launcher" },
        }
        for index, choice in ipairs(choices) do
            local key = choice[3]
            W.Checkbox(ui.pool.env, ui.body, choice[1], choice[2], ((index - 1) % 2) * 300,
                -248 - math.floor((index - 1) / 2) * 58, 280, function() return ui.draft[key] end,
                function(value) ui.draft[key] = value end)
        end
        contentHeight(424)
        ui.notice:SetText(ui.message or "Click the LumenShift button for modes. Right-click it for Studio.")
    end
    function ui.Open()
        if ui.finishing then return nil, "SETUP_BUSY" end
        if not db then return ns.DiagnosticWindow.Open(runtime) end
        if product.IsCombat() then return nil, "COMBAT" end
        if not env.UIParent then return nil, "NATIVE_UI_UNAVAILABLE" end
        ui.message, ui.finishing = nil, false
        ui.draft = { effects = db.config.studio.effects, sound = db.config.preferences.sound,
            animation = db.config.preferences.animation, reducedMotion = db.config.preferences.reducedMotion,
            highContrast = db.config.studio.highContrast, launcher = db.config.studio.launcher.visible,
            baselineSource = db.baseline.source, includeOptics = db.baseline.includeOptics, capture = not db.baseline.chosen }
        ui.draft.graphics = ns.NativeGraphics.Draft(runtime)
        -- Retain saved choices. Only the explicitly labelled Apply action writes;
        -- Save & Close and all startup paths remain read-only.
        ui.page = 1
        if not ui.window then
            local window = env.CreateFrame("Frame", "LumenShiftSetup", env.UIParent); ui.window = window
            window:SetSize(640, 692); window:SetPoint("CENTER")
            W.Window(env, window, 94, 56); W.Fill(window, W.colors.bg)
            ui.keyboard = ns.Keyboard.Attach(env, window)
            ui.panelArt = W.Art(window, "panel-steel", 1, -1, 638, 690, 0.38, "BACKGROUND")
            ui.headerArt = W.Art(window, "light-sweep", 200, -2, 410, 102, 0.50, "BACKGROUND")
            ui.headerArt:SetTexCoord(0, 1, 0.32, 0.73); W.Border(window)
            local logo = window:CreateTexture(nil, "ARTWORK"); logo:SetSize(48, 48); logo:SetPoint("TOPLEFT", 28, -26)
            W.Asset(logo, "Interface/AddOns/LumenShift/Media/logo.tga")
            W.Text(window, runtime.storeStatus == "SETUP_REFRESH_REQUIRED" and "LumenShift setup updated" or "Welcome to LumenShift", 94, -28, 470, 24)
            W.Text(window, runtime.storeStatus == "SETUP_REFRESH_REQUIRED" and "Your choices are kept. Save once to finish the new setup." or "Choose your defaults. You can change them anytime.", 94, -62, 490, 14)
            ui.scroll = env.CreateFrame("ScrollFrame", nil, window)
            ui.scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 30, -142); ui.scroll:SetSize(580, 424)
            ui.scroll:EnableMouseWheel(true)
            ui.body = env.CreateFrame("Frame", nil, ui.scroll)
            ui.scroll:SetScrollChild(ui.body)
            ui.bar = env.CreateFrame("Slider", nil, window)
            ui.bar:SetPoint("TOPLEFT", window, "TOPLEFT", 620, -142); ui.bar:SetSize(5, 424)
            ui.bar:SetOrientation("VERTICAL"); ui.bar:SetValueStep(24); ui.bar:SetMinMaxValues(0, 0)
            W.Fill(ui.bar, W.colors.sidebar)
            local thumb = W.Texture(ui.bar, "OVERLAY"); thumb:SetSize(5, 36); thumb:SetColorTexture(unpack(W.colors.accent)); ui.bar:SetThumbTexture(thumb)
            W.Script(ui.bar, "OnValueChanged", function(_, value) ui.scroll:SetVerticalScroll(value) end)
            W.Script(ui.scroll, "OnMouseWheel", function(_, delta)
                ui.bar:SetValue(math.max(0, math.min(ui.maximum or 0, ui.scroll:GetVerticalScroll() - delta * 36)))
            end)
            ui.keyboard.viewport = { body = ui.body, scroll = ui.scroll, bar = ui.bar, maximum = function() return ui.maximum or 0 end }
            ui.steps = {
                W.Button(env, window, "1  Appearance", 30, -102, 280, function() ui.page = 1; ui.scroll:SetVerticalScroll(0); ui.Build() end, nil, "quiet"),
                W.Button(env, window, "2  Graphics", 330, -102, 280, function() ui.page = 2; ui.scroll:SetVerticalScroll(0); ui.Build() end, nil, "quiet"),
            }
            ui.body:SetPoint("TOPLEFT", ui.scroll, "TOPLEFT", 0, 0); ui.body:SetSize(580, 424)
            ui.pool = W.CreatePool(env, ui.body)
            ui.notice = W.Text(window, "", 30, -574, 580, 13, W.colors.muted)
            W.ButtonIcon(W.Button(env, window, "X", 592, -12, 30, function() window:Hide() end, nil, "quiet"), "ui-close", 12).label:Hide()
            W.Button(env, window, "Later", 30, -636, 92, function() window:Hide() end)
            W.Button(env, window, "Save & Close", 138, -636, 178, ui.SaveAndClose)
            W.Rule(window, 30, -616, 580)
            ui.next = W.Button(env, window, "Next: Graphics", 332, -636, 278, ui.Finish, nil, "primary")
            ui.next:SetHeight(36)
            local font = ui.next.label:GetFont(); ui.next.label:SetFont(font, 16, "")
            window:RegisterEvent("UI_SCALE_CHANGED"); window:RegisterEvent("DISPLAY_SIZE_CHANGED")
            W.Script(window, "OnEvent", function() if window:IsShown() then ui.Size() end end)
            if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftSetup") end
        end
        if runtime.ui and runtime.ui.CloseWheel then runtime.ui.CloseWheel() end
        ui.Size()
        W.Decoration(ui.panelArt); W.Decoration(ui.headerArt)
        ui.Build(); ui.window:Show()
        ns.Log.Record(runtime.reader, "setup", "open", "INFO", "NO_GRAPHICS_WRITE")
        return true
    end
    function ui.Size()
        local scale = env.UIParent:GetEffectiveScale()
        if not ns.Value.Finite(scale) or scale <= 0 then scale = 1 end
        ui.window:SetScale(math.min(1 / scale, env.UIParent:GetWidth() / 680, env.UIParent:GetHeight() / 732))
    end
    function ui.MaybeOpen()
        if ui.attempted or not db or (db.onboarding.completed and db.baseline.chosen) or product.IsCombat() then return end
        ui.attempted = true; ui.Open()
    end
    return ui
end
