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
        if not ui.draft.acknowledged then return tell("Please acknowledge the recovery note before finishing.") end
        if type(env.ReloadUI) ~= "function" then return tell("Reload UI is unavailable. Your choices have not been committed.") end
        ui.finishing = true
        local prior = ns.Value.Copy(db.config)
        if ui.draft.enabled then
            local enabled, why = product.Enable(true)
            if not enabled then ui.finishing = false; return tell(why or "Visual controls are unavailable.") end
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
        W.Text(parent, "Step " .. ui.page .. " of 3", 0, 0, 520, 13, W.colors.accent)
        local y = -44
        local function toggle(label, key)
            W.Toggle(widgetEnv, parent, label, 0, y, 520, function() return ui.draft[key] end,
                function(value) ui.draft[key] = value end); y = y - 42
        end
        if ui.page == 1 then
            W.Text(parent, "Welcome to LumenShift", 0, -40, 520, 22)
            W.Text(parent, "Choose your preferences, then finish and reload the interface. Setup does not change graphics or apply a mode.", 0, -88, 520, 15)
            W.Text(parent, "After setup: click the LumenShift launcher for the mode wheel. Right-click it for Studio. Settings > AddOns > LumenShift also opens every control.", 0, -160, 520, 15)
            W.Text(parent, "Natural restores your captured visual settings. Diagnostic Center provides recovery and one report to copy if something goes wrong.", 0, -245, 520, 14, W.colors.muted)
        elseif ui.page == 2 then
            toggle("Optional tint and vignette effects", "effects")
            toggle("Activation sounds", "sound")
            toggle("Menu animations", "animation")
            toggle("Reduced motion", "reducedMotion")
            toggle("High-contrast Studio", "highContrast")
            toggle("Show movable on-screen launcher", "launcher")
        else
            toggle("Enable user-controlled visual switching", "enabled")
            W.Text(parent, "No mode is applied at login. Other brightness targets and Contrast/quality experiments keep their separate opt-ins in Studio.", 0, -95, 520, 14)
            local current = ns.ReadOnly.Read(runtime.reader, "Brightness")
            W.Text(parent, "Current Brightness: " .. ns.Report.Number(current.raw)
                .. ". Each later operation captures its actual original. Save recovery reports externally; saved addon data is not immediately durable.", 0, -160, 520, 14)
            y = -250; toggle("I understand: restore owned settings before removal", "acknowledged")
            W.Button(widgetEnv, parent, "Export recovery / diagnostic report", 0, -300, 520, function() ns.DiagnosticWindow.Open(runtime) end)
        end
        ui.back.label:SetText(ui.page == 1 and "Later" or "Back")
        ui.next.label:SetText(ui.page == 3 and "Finish & Reload UI" or "Next")
        ui.notice:SetText(ui.message or "Changes stay in this wizard until Finish. No commands are required.")
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
            enabled = db.config.studio.enabled or not db.onboarding.completed, acknowledged = false }
        if not ui.window then
            local window = env.CreateFrame("Frame", "LumenShiftSetup", env.UIParent); ui.window = window
            window:SetSize(580, 500); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
            window:SetClampedToScreen(true); window:EnableMouse(true); W.Fill(window)
            W.Text(window, "LUMENSHIFT  /  SETUP", 25, -18, 470, 17, W.colors.accent)
            ui.body = env.CreateFrame("Frame", nil, window); ui.body:SetPoint("TOPLEFT", window, "TOPLEFT", 25, -58); ui.body:SetSize(530, 345)
            ui.pool = W.CreatePool(env, ui.body)
            ui.notice = W.Text(window, "", 25, -415, 530, 12)
            W.Button(env, window, "Close", 475, -14, 80, function() window:Hide() end)
            ui.back = W.Button(env, window, "Later", 25, -456, 120, function()
                if ui.page == 1 then window:Hide() else ui.page = ui.page - 1; ui.message = nil; ui.Build() end
            end)
            ui.next = W.Button(env, window, "Next", 305, -456, 250, function()
                if ui.page < 3 then ui.page = ui.page + 1; ui.message = nil; ui.Build() else ui.Finish() end
            end)
            if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftSetup") end
        end
        if runtime.ui and runtime.ui.CloseWheel then runtime.ui.CloseWheel() end
        ui.window:SetScale(math.min(1, env.UIParent:GetWidth() / 610, env.UIParent:GetHeight() / 530))
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
