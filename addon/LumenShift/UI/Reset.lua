local _, ns = ...
local R, W = {}, ns.Widgets
ns.Reset = R

-- A deliberate factory reset of our SavedVariables only. Controllers retain
-- references to the old database until ReloadUI replaces this entire runtime.
function R.New(runtime, replaceSaved)
    local reader, ui = runtime.reader, { armed = false }
    local env = reader.env
    local function tell(message, code)
        if ui.notice then ui.notice:SetText(message) end
        return nil, code
    end
    local function ready()
        local combat = ns.ReadOnly.Call(reader, env.InCombatLockdown)
        if not combat or combat.n ~= 1 or combat[1] ~= false then
            return tell("Reset after combat. Nothing has been cleared.", "COMBAT_OR_RESTRICTION")
        end
        -- Wait only for operations actually running now, never for historical
        -- recovery/conflict records: intentionally clearing those is this action.
        for _, name in ipairs({ "brightnessExecuting", "visualBusy", "experimentBusy", "nameBusy", "graphicsBusy" }) do
            if reader[name] and reader[name]() then
                return tell("A change is still finishing. Try Reset again in a moment.", "OPERATION_ACTIVE")
            end
        end
        for _, name in ipairs({ "product", "camera", "tierTrial", "cameraActions", "photoComposition" }) do
            if runtime[name] and runtime[name].busy then
                return tell("A change is still finishing. Try Reset again in a moment.", "OPERATION_ACTIVE")
            end
        end
        if runtime.setup and runtime.setup.finishing then
            return tell("Setup is still finishing. Nothing has been cleared.", "SETUP_BUSY")
        end
        if type(env.ReloadUI) ~= "function" then
            return tell("UI reload is unavailable. Nothing has been cleared.", "RELOAD_UNAVAILABLE")
        end
        return true
    end
    function ui.Confirm()
        if not ui.armed or reader.resetPending then return nil, "RESET_NOT_CONFIRMED" end
        local ok, why = ready(); if not ok then return nil, why end
        if runtime.cameraActions then
            local stopped = runtime.cameraActions.StopOrbit()
            if not stopped then return tell("Camera motion could not stop. Release the camera control and retry.", "CAMERA_STOP_FAILED") end
        end
        if runtime.portrait then runtime.portrait.Exit() end
        if runtime.captureSequence then runtime.captureSequence.Cancel() end
        if runtime.composition then runtime.composition.CancelCapture() end
        local fresh = ns.Store.Open(nil)
        -- Change the global save target, not the live controllers' database.
        -- This fence stops owned input/events and the one native write boundary
        -- if ReloadUI reenters code or returns before the runtime is destroyed.
        reader.resetPending = true
        local previous = replaceSaved(fresh)
        local result, code = ns.ReadOnly.Call(reader, env.ReloadUI)
        if not result or result.n ~= 0 then
            replaceSaved(previous)
            reader.resetPending = false
            ns.Log.Record(reader, "reset", "reload", "WARN", code or "UNEXPECTED_RELOAD_RESULT")
            return tell("Reload did not complete. Your LumenShift settings were kept. You can retry or cancel.", "RELOAD_FAILED")
        end
        ui.armed = false
        ui.confirm:Disable(); ui.cancel:Disable()
        if ui.notice then ui.notice:SetText("Restarting setup...") end
        return true
    end
    function ui.Open()
        if reader.resetPending then return nil, "RESET_PENDING" end
        if not env.UIParent or type(env.CreateFrame) ~= "function" then return nil, "NATIVE_UI_UNAVAILABLE" end
        if not ui.window then
            local window = env.CreateFrame("Frame", "LumenShiftReset", env.UIParent); ui.window = window
            window:SetSize(560, 338); window:SetPoint("CENTER")
            W.Window(env, window, 48, 20); W.Fill(window, W.colors.bg); W.Border(window)
            ns.Keyboard.Attach(env, window)
            W.Text(window, "Reset LumenShift?", 24, -24, 512, 24)
            W.Text(window, "Start fresh with the setup wizard.", 24, -65, 512, 14, W.colors.muted)
            W.Text(window, "Deletes LumenShift preferences, personal presets, setup choices and saved recovery history for this WoW account.", 24, -105, 512, 14)
            W.Text(window, "Your current WoW settings and other addons' saved data stay unchanged. Old captured originals will be forgotten, not restored.", 24, -158, 512, 14, W.colors.muted)
            ui.notice = W.Text(window, "The interface will reload, then setup will open.", 24, -218, 512, 13, W.colors.accent)
            W.Rule(window, 24, -268, 512)
            -- Cancel is first in keyboard navigation; opening never confirms.
            ui.cancel = W.Button(env, window, "Cancel", 24, -284, 144, function() window:Hide() end)
            ui.confirm = W.Button(env, window, "Reset & Restart Setup", 184, -284, 352, ui.Confirm, nil, "primary")
            local onHide = window:GetScript("OnHide")
            W.Script(window, "OnHide", function(self, ...)
                ui.armed = false
                if onHide then onHide(self, ...) end
            end)
            if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftReset") end
        end
        if runtime.ui and runtime.ui.CloseWheel then runtime.ui.CloseWheel() end
        ui.window:SetScale(math.min(1 / env.UIParent:GetEffectiveScale(), env.UIParent:GetWidth() / 600, env.UIParent:GetHeight() / 378))
        ui.notice:SetText("The interface will reload, then setup will open.")
        ui.armed = true; ui.window:Show()
        return true
    end
    return ui
end
