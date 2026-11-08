local _, ns = ...
local C = {}
ns.Camera = C
function C.New(runtime)
    local camera = { active = false, changedNames = false, busy = false }
    local reader, db, names = runtime.reader, runtime.db, runtime.names
    local function report(ok, why)
        camera.error = why
        ns.Log.Record(reader, "camera", "operation", ok and "INFO" or "WARN", why or "PASS")
        if why then ns.Diagnostics.Emit(runtime, "LumenShift: " .. ns.Product.Message(why)) end
        if runtime.product and runtime.product.Refresh then runtime.product.Refresh() end
        return ok, why
    end
    function camera.Visible()
        local parent = reader.env.UIParent
        local result = ns.ReadOnly.Call(reader, parent and parent.IsShown, parent)
        if not result or result.n ~= 1 or type(result[1]) ~= "boolean" then return nil, "UI_VISIBILITY_UNAVAILABLE" end
        return result[1]
    end
    local function visibility(shown)
        local result, why = ns.ReadOnly.Call(reader, reader.env.SetUIVisibility, shown)
        if not result then return nil, why or "UI_VISIBILITY_UNAVAILABLE" end
        local current = camera.Visible()
        if current ~= shown then return nil, "UI_VISIBILITY_NOT_CHANGED" end
        return true
    end
    function camera.RestoreNames(callback, reconcile)
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if not next(db.camera.journal.entries) then if callback then callback(true) end; return true end
        local function completed(restored, reason)
            if restored then db.camera.sideEffects = {} end
            report(restored, reason); if callback then callback(restored, reason) end
        end
        local ok, why
        if reconcile == false then ok, why = names.Apply("camera", {}, completed)
        else ok, why = names.RestoreLayer("camera", completed) end
        if not ok then return report(ok, why) end
        return true
    end
    function camera.ToggleNames()
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if next(db.camera.journal.entries) then return camera.RestoreNames(nil, false) end
        local target = 1
        for _, key in ipairs(ns.NamePolicy.Keys) do
            local item = ns.ReadOnly.Read(reader, key)
            if not ns.Planner.SafeObservation(item) then return report(nil, "NAME_CONTROLS_UNAVAILABLE") end
            if ns.Value.Number(item.raw) == 1 then target = 0 end
        end
        local targets = {}; for _, key in ipairs(ns.NamePolicy.Keys) do targets[key] = target end
        local ok, why = names.Apply("camera", targets, function(done, reason) report(done, reason) end)
        if not ok then return report(ok, why) end
        return true
    end
    function camera.ApplyFOV(value)
        if camera.busy then return report(nil, "BUSY") end
        local ok, why = runtime.framing.Apply("camera", { cameraFov = value }, function(done, code) report(done, code) end)
        if not ok then return report(nil, why) end
        return true
    end
    function camera.RestoreFOV(callback)
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if not next(db.camera.framing.journal.entries) then if callback then callback(true) end; return true end
        -- An exit never authorizes overwriting another camera addon's adjustment.
        local ok, why = runtime.framing.Apply("camera", {}, function(done, code)
            report(done, code); if callback then callback(done, code) end
        end)
        if not ok then return report(nil, why) end
        return true
    end
    function camera.Exit()
        -- Showing the HUD is always the first attempt, even if name restoration fails.
        local shown, why = visibility(true)
        if not shown then return report(nil, why) end
        if runtime.composition then runtime.composition.Hide() end
        if camera.busy or names.busy or runtime.framing.busy or runtime.photo.busy then
            camera.interrupted = true; return report(nil, "BUSY")
        end
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        camera.active, camera.busy = false, true
        local tasks, firstError = {}, nil
        if camera.changedNames or next(db.camera.journal.entries) then tasks[#tasks + 1] = function(done) return camera.RestoreNames(done, false) end end
        if next(db.camera.framing.journal.entries) then tasks[#tasks + 1] = camera.RestoreFOV end
        if next(db.camera.photo.records) then tasks[#tasks + 1] = runtime.photo.RestorePhoto end
        local index = 0
        local function advance(ok, code)
            if not ok then firstError = firstError or code end
            index = index + 1
            if not tasks[index] then
                camera.busy = false
                if not firstError then camera.changedNames = false end
                report(not firstError, firstError); return
            end
            local called = false
            local started, why = tasks[index](function(done, reason)
                called = true
                if index < #tasks then
                    -- Leave the preceding writer's callback guard before entering
                    -- another boundary controller (names, framing, then photo).
                    local scheduled = ns.ReadOnly.Call(reader, reader.env.C_Timer and reader.env.C_Timer.After, 0, function() advance(done, reason) end)
                    if not scheduled then camera.busy = false; report(nil, reason or "FOLLOWUP_TIMER_FAILED") end
                else advance(done, reason) end
            end)
            if not started and not called then advance(false, why) end
        end
        advance(true)
        return not firstError or nil, firstError
    end
    function camera.Combat()
        camera.interrupted = true
        if runtime.composition then runtime.composition.Hide() end
        -- Restore access to combat cues only; never queue graphics restoration.
        if camera.active or camera.busy then visibility(true) end
    end
    function camera.Toggle()
        if camera.busy or names.busy or runtime.framing.busy or runtime.photo.busy then return report(nil, "BUSY") end
        local shown, why = camera.Visible()
        if shown == nil then return report(nil, why) end
        if camera.active or not shown then return camera.Exit() end
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if runtime.product.IsCombat() then return report(nil, "COMBAT_OR_RESTRICTION") end
        if type(reader.env.SetUIVisibility) ~= "function" then return report(nil, "UI_VISIBILITY_UNAVAILABLE") end
        camera.interrupted = false
        local function hide()
            -- Combat or an external UI change during name verification is not a new hide request.
            if camera.interrupted or runtime.product.IsCombat() or camera.Visible() ~= true then return report(nil, "CAMERA_ENTRY_INTERRUPTED") end
            local ok, reason = visibility(false)
            camera.active = ok == true
            if ok and runtime.composition then runtime.composition.Show() end
            return report(ok, reason)
        end
        local function enter()
            if camera.interrupted or runtime.product.IsCombat() then return report(nil, "CAMERA_ENTRY_INTERRUPTED") end
            if db.camera.hideWithUI then
                local targets = {}; for _, key in ipairs(ns.NamePolicy.Keys) do targets[key] = 0 end
                local ok, reason = names.Apply("camera", targets, function(done, errorCode)
                    if done then camera.changedNames = next(db.camera.journal.entries) ~= nil; hide()
                    else report(nil, errorCode) end
                end)
                if not ok then return report(nil, reason) end
                return true
            end
            return hide()
        end
        if db.camera.photoEnabled then
            if next(db.camera.photo.records) then return report(nil, "RESTORE_PHOTO_FIRST") end
            local choices = ns.NativeGraphics.Defaults().choices
            choices.normal = { source = "level", level = db.camera.photoLevel }
            local raid = ns.ReadOnly.Read(reader, "RAIDsettingsEnabled")
            if not ns.Planner.SafeObservation(raid) or (raid.raw ~= "0" and raid.raw ~= "1") then return report(nil, "PHOTO_BANK_UNAVAILABLE") end
            if raid.raw == "1" then choices.raid = { source = "level", level = db.camera.photoLevel } end
            camera.busy = true
            local ok, why = runtime.photo.Apply(choices, function(done, code)
                if done then
                    local scheduled = ns.ReadOnly.Call(reader, reader.env.C_Timer and reader.env.C_Timer.After, 0, function()
                        camera.busy = false; enter()
                    end)
                    if not scheduled then camera.busy = false; report(nil, "FOLLOWUP_TIMER_FAILED") end
                else camera.busy = false; report(nil, code) end
            end)
            if not ok then camera.busy = false; return report(nil, why) end
            return true
        end
        return enter()
    end
    return camera
end
