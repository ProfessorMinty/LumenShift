local _, ns = ...
local S, W = {}, ns.Widgets
ns.Setup = S
function S.New(runtime)
    local env, db, product = runtime.reader.env, runtime.db, runtime.product
    local ui = { page = 1, attempted = false, finishing = false }
    local function recovery()
        return not db or product.busy or runtime.lab.busy or next(db.journal.entries)
            or next(db.experiments.journal.entries) or runtime.engine.Status().state ~= "BASELINE"
    end
    local function tell(text)
        ui.message = text
        if ui.notice then ui.notice:SetText(text) end
        return nil, text
    end
    function ui.Finish()
        if ui.finishing then return nil, "SETUP_BUSY" end
        if not db or not ui.draft then return tell("Setup data is unavailable. Open the diagnostic report.") end
        if product.IsCombat() then return tell("Finish setup after combat. No reload was requested.") end
        if recovery() then return tell("Restore owned settings in Diagnostic Center before reloading.") end
        if not ui.draft.acknowledged then return tell("Check the restore reminder below before finishing.") end
        if type(env.ReloadUI) ~= "function" then return tell("Reload UI is unavailable. Your choices have not been committed.") end
        ui.finishing = true
        local prior = ns.Value.Copy(db.config)
        if ui.draft.enabled then
            local enabled, why, explanation = product.Enable(true)
            if not enabled then ui.finishing = false; return tell(explanation or why or "Visual controls are unavailable.") end
        end
        local saved, reason = product.Update(function(copy)
            copy.studio.enabled = ui.draft.enabled
            copy.studio.effects = ui.draft.effects
            copy.studio.highContrast = ui.draft.highContrast
            copy.studio.launcher.visible = ui.draft.launcher
            copy.preferences.sound = ui.draft.sound
            copy.preferences.animation = ui.draft.animation
            copy.preferences.reducedMotion = ui.draft.reducedMotion
        end)
        if not saved then db.config = prior; ui.finishing = false; return tell(reason) end
        db.onboarding.completed = true
        ns.Log.Record(runtime.reader, "setup", "finish", "INFO", "SAVED_USER_REQUESTED_RELOAD_NO_GRAPHICS_WRITE")
        -- Only the explicit final button reaches this call. Never a startup/event action.
        local result, code = ns.ReadOnly.Call(runtime.reader, env.ReloadUI)
        if not result or result.n ~= 0 then
            ui.finishing = false
            ns.Log.Record(runtime.reader, "setup", "reload", "WARN", code or "UNEXPECTED_RELOAD_RESULT")
            return tell("Preferences saved, but reload did not complete. You can retry Finish or restart normally.")
        end
        if ui.window then ui.window:Hide() end
        return true
    end
    function ui.Build()
        ui.pool.Reset()
        local parent, widgetEnv = ui.body, ui.pool.env
        local titles = { "Welcome", "Make it comfortable", "Review and finish" }
        W.Text(parent, titles[ui.page], 0, 0, 696, 26)
        local ready, unavailable = product.CanEnable()
        local identity = ns.Compatibility.Inspect(runtime.reader)
        local y = -56
        local function toggle(label, description, key)
            local button, state
            local function update()
                state:SetText(key == "acknowledged" and (ui.draft[key] and "YES" or "NO") or (ui.draft[key] and "ON" or "OFF"))
                state:SetTextColor(unpack(ui.draft[key] and W.colors.accent or W.colors.muted))
            end
            button = W.Button(widgetEnv, parent, label, 0, y, 696, function()
                if key == "enabled" and not ui.draft.enabled then
                    local allowed, reason = product.CanEnable()
                    if not allowed then tell(reason); return end
                end
                ui.draft[key] = not ui.draft[key]; update()
            end)
            button:SetHeight(56); button.label:SetWidth(570)
            local font = button.label:GetFont(); button.label:SetFont(font, 17, "")
            W.Text(button, description, 10, -32, 650, 14, W.colors.muted)
            state = W.Text(button, "", 630, -10, 55, 16, W.colors.accent)
            update(); y = y - 62
        end
        if ui.page == 1 then
            W.Text(parent, "Choose how LumenShift looks and feels. Setup only saves preferences; your graphics stay as they are.", 0, -56, 696, 18)
            W.Text(parent, "YOUR GAME", 0, -124, 696, 14, W.colors.accent)
            W.Text(parent, ready and ns.Compatibility.Explain(identity) or unavailable, 0, -150, 696, 16)
            W.Text(parent, "WHAT THIS BUILD INCLUDES", 0, -222, 696, 14, W.colors.accent)
            W.Text(parent, "Six visual modes, a mode wheel, Studio, optional screen effects and sounds, personal presets, and diagnostics.", 0, -248, 696, 17)
            W.Text(parent, "Still in development: Contrast and advanced graphics need explicit calibration. Quality profiles start empty; this is not the finished product.", 0, -312, 696, 16, W.colors.muted)
            W.Button(widgetEnv, parent, "View diagnostic report", 0, -386, 260, function() ns.DiagnosticWindow.Open(runtime) end)
        elseif ui.page == 2 then
            toggle("Screen effects", "Allow each mode's optional tint, vignette and cinematic bars.", "effects")
            toggle("Activation sounds", "Play the Night Vision cue when switching on or off.", "sound")
            toggle("Menu animations", "Use short fades when opening menus.", "animation")
            toggle("Reduced motion", "Suppress animation even when menu animations are on.", "reducedMotion")
            toggle("High-contrast Studio", "Use a stronger background for the settings window.", "highContrast")
            toggle("Show on-screen launcher", "Keep a movable mode button on screen. The minimap entry remains available.", "launcher")
        else
            toggle("Enable visual switching", "Let the mode wheel change your visuals when you choose a mode.", "enabled")
            W.Text(parent, ready and "Ready. Nothing activates during setup or login. Extra brightness targets and graphics experiments have separate opt-ins in Studio."
                or unavailable, 0, -128, 696, 16, ready and W.colors.muted or W.colors.text)
            local function choice(label, key) return label .. ": " .. (ui.draft[key] and "On" or "Off") end
            W.Text(parent, choice("Screen effects", "effects") .. "   /   " .. choice("Sounds", "sound")
                .. "\n" .. choice("Menu animations", "animation") .. "   /   " .. choice("Reduced motion", "reducedMotion")
                .. "\n" .. choice("High contrast", "highContrast") .. "   /   " .. choice("Launcher", "launcher"), 0, -208, 696, 16)
            local current = ns.ReadOnly.Read(runtime.reader, "Brightness")
            W.Text(parent, "Brightness now: " .. ns.Report.Number(current.raw)
                .. ". Before changing it, LumenShift records the actual original. Save recovery reports outside the game in case of a crash.", 0, -282, 696, 16)
            y = -358; toggle("I know how to restore my settings", "Choose Natural, or use Diagnostic Center > Restore. Restore before uninstalling.", "acknowledged")
        end
        ui.progress:SetText("1  Welcome     /     2  Preferences     /     3  Review     -     Step " .. ui.page .. " of 3")
        ui.back.label:SetText(ui.page == 1 and "Set up later" or "Back")
        ui.next.label:SetText(ui.page == 3 and "Finish & Reload UI" or ui.page == 1 and "Choose preferences" or "Review choices")
        ui.notice:SetText(ui.message or (ui.page == 3 and "Finish saves your choices and briefly reloads the interface. Use the launcher afterward."
            or "Your choices are saved only when you finish. Close to leave them unchanged."))
    end
    function ui.Open()
        if not db then return ns.DiagnosticWindow.Open(runtime) end
        if product.IsCombat() then return nil, "COMBAT" end
        if recovery() then
            if runtime.ui and runtime.ui.Open then runtime.ui.Open(7) else ns.DiagnosticWindow.Open(runtime) end
            return nil, "RECOVERY_BEFORE_SETUP"
        end
        if not env.UIParent then return nil, "NATIVE_UI_UNAVAILABLE" end
        ui.page, ui.message, ui.finishing = 1, nil, false
        ui.draft = { effects = db.config.studio.effects, sound = db.config.preferences.sound,
            animation = db.config.preferences.animation, reducedMotion = db.config.preferences.reducedMotion,
            highContrast = db.config.studio.highContrast, launcher = db.config.studio.launcher.visible,
            enabled = product.CanEnable() == true and (db.config.studio.enabled or not db.onboarding.completed), acknowledged = false }
        if not ui.window then
            local window = env.CreateFrame("Frame", "LumenShiftSetup", env.UIParent); ui.window = window
            window:SetSize(760, 670); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
            window:SetClampedToScreen(true); window:EnableMouse(true); W.Fill(window, W.colors.bg)
            W.Text(window, "LUMENSHIFT", 32, -24, 570, 20, W.colors.accent)
            ui.progress = W.Text(window, "", 32, -62, 696, 14, W.colors.muted)
            ui.body = env.CreateFrame("Frame", nil, window); ui.body:SetPoint("TOPLEFT", window, "TOPLEFT", 32, -110); ui.body:SetSize(696, 430)
            ui.pool = W.CreatePool(env, ui.body)
            ui.notice = W.Text(window, "", 32, -554, 696, 16)
            W.Button(env, window, "Close", 648, -20, 80, function() window:Hide() end)
            ui.back = W.Button(env, window, "Set up later", 32, -616, 160, function()
                if ui.page == 1 then window:Hide() else ui.page = ui.page - 1; ui.message = nil; ui.Build() end
            end)
            ui.next = W.Button(env, window, "Choose preferences", 468, -616, 260, function()
                if ui.page < 3 then ui.page = ui.page + 1; ui.message = nil; ui.Build() else ui.Finish() end
            end)
            for _, button in ipairs({ ui.back, ui.next }) do
                button:SetHeight(38)
                local font = button.label:GetFont(); button.label:SetFont(font, 16, "")
            end
            if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftSetup") end
        end
        if runtime.ui and runtime.ui.CloseWheel then runtime.ui.CloseWheel() end
        local scale = env.UIParent:GetEffectiveScale()
        if not ns.Value.Finite(scale) or scale <= 0 then scale = 1 end
        ui.window:SetScale(math.min(1 / scale, env.UIParent:GetWidth() / 800, env.UIParent:GetHeight() / 710))
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
