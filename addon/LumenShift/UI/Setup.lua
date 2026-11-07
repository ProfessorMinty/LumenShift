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
    function ui.Finish()
        if ui.finishing then return nil, "SETUP_BUSY" end
        local saved, why = save(); if not saved then return nil, why end
        -- Preference persistence is independent of momentary graphics readiness.
        -- Only the explicit final button requests reload, never a later event.
        if product.IsCombat() then return tell("Preferences saved. Finish reloading after combat, or choose Save & Close.") end
        if product.busy or runtime.lab.busy or next(db.journal.entries) or next(db.experiments.journal.entries) then
            return tell("Preferences saved. Return visuals and quality to Natural / Current Baseline before reloading. You can Save & Close now.")
        end
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
    function ui.Build()
        ui.pool.Reset()
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
                -math.floor((index - 1) / 2) * 66, 280, function() return ui.draft[key] end,
                function(value) ui.draft[key] = value end)
        end
        ui.notice:SetText(ui.message or "Click the LumenShift button for modes. Right-click it for Studio.")
    end
    function ui.Open()
        if not db then return ns.DiagnosticWindow.Open(runtime) end
        if product.IsCombat() then return nil, "COMBAT" end
        if not env.UIParent then return nil, "NATIVE_UI_UNAVAILABLE" end
        ui.message, ui.finishing = nil, false
        ui.draft = { effects = db.config.studio.effects, sound = db.config.preferences.sound,
            animation = db.config.preferences.animation, reducedMotion = db.config.preferences.reducedMotion,
            highContrast = db.config.studio.highContrast, launcher = db.config.studio.launcher.visible }
        if not ui.window then
            local window = env.CreateFrame("Frame", "LumenShiftSetup", env.UIParent); ui.window = window
            window:SetSize(640, 440); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
            window:SetClampedToScreen(true); window:EnableMouse(true); W.Fill(window, W.colors.bg)
            local logo = window:CreateTexture(nil, "ARTWORK"); logo:SetSize(48, 48); logo:SetPoint("TOPLEFT", 28, -26)
            W.Asset(logo, "Interface/AddOns/LumenShift/Media/logo.tga")
            W.Text(window, runtime.storeStatus == "SETUP_REFRESH_REQUIRED" and "LumenShift setup updated" or "Welcome to LumenShift", 94, -28, 470, 22, W.colors.accent)
            W.Text(window, runtime.storeStatus == "SETUP_REFRESH_REQUIRED" and "Your choices are kept. Save once to finish the new setup." or "Choose your defaults. You can change them anytime.", 94, -62, 490, 14)
            ui.body = env.CreateFrame("Frame", nil, window)
            ui.body:SetPoint("TOPLEFT", window, "TOPLEFT", 30, -114); ui.body:SetSize(580, 195)
            ui.pool = W.CreatePool(env, ui.body)
            ui.notice = W.Text(window, "", 30, -318, 580, 14, W.colors.muted)
            W.Button(env, window, "X", 592, -12, 30, function() window:Hide() end)
            W.Button(env, window, "Later", 30, -382, 92, function() window:Hide() end)
            W.Button(env, window, "Save & Close", 138, -382, 178, ui.SaveAndClose)
            ui.next = W.Button(env, window, "Finish & Reload UI", 332, -382, 278, ui.Finish)
            ui.next:SetHeight(36)
            local font = ui.next.label:GetFont(); ui.next.label:SetFont(font, 16, "")
            if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftSetup") end
        end
        if runtime.ui and runtime.ui.CloseWheel then runtime.ui.CloseWheel() end
        local scale = env.UIParent:GetEffectiveScale()
        if not ns.Value.Finite(scale) or scale <= 0 then scale = 1 end
        ui.window:SetScale(math.min(1 / scale, env.UIParent:GetWidth() / 680, env.UIParent:GetHeight() / 480))
        ui.Build(); ui.window:Show()
        ns.Log.Record(runtime.reader, "setup", "open", "INFO", "NO_GRAPHICS_WRITE")
        return true
    end
    function ui.MaybeOpen()
        if ui.attempted or not db or db.onboarding.completed or product.IsCombat() then return end
        ui.attempted = true; ui.Open()
    end
    return ui
end
