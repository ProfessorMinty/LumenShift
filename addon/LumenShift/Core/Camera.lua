local _, ns = ...
local C = {}
ns.Camera = C
function C.New(runtime)
    local camera = { active = false, changedNames = false, busy = false }
    local reader, db, names = runtime.reader, runtime.db, runtime.names
    local pendingEntryFraming
    function camera.CancelEntryFraming() pendingEntryFraming=nil end
    local function report(ok, why)
        camera.error = why
        ns.Log.Record(reader, "camera", "operation", ok and "INFO" or "WARN", why or "PASS")
        if why then ns.Diagnostics.Emit(runtime, "LumenShift: " .. ns.Product.Message(why)) end
        if runtime.product and runtime.product.Refresh then runtime.product.Refresh() end
        return ok, why
    end
    function camera.CanCompose()
        return not runtime.product.IsCombat() or db and db.camera.keepInCombat == true
    end
    function camera.Visible()
        local parent = reader.env.UIParent
        local result = ns.ReadOnly.Call(reader, parent and parent.IsShown, parent)
        if not result or result.n ~= 1 or type(result[1]) ~= "boolean" then return nil, "UI_VISIBILITY_UNAVAILABLE" end
        return result[1]
    end
    local function visibility(shown)
        if shown and runtime.photoCompatibility then runtime.photoCompatibility.BeforeShow() end
        local result, why = ns.ReadOnly.Call(reader, reader.env.SetUIVisibility, shown)
        if not result then return nil, why or "UI_VISIBILITY_UNAVAILABLE" end
        local current = camera.Visible()
        if current ~= shown then return nil, "UI_VISIBILITY_NOT_CHANGED" end
        if runtime.photoCompatibility then
            if shown then runtime.photoCompatibility.AfterShow() else runtime.photoCompatibility.AfterHide() end
        end
        return true
    end
    function camera.RestoreNames(callback, reconcile)
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if not next(db.camera.journal.entries) then db.camera.nameReturn = nil; if callback then callback(true) end; return true end
        local function completed(restored, reason)
            if restored then db.camera.sideEffects = {}; db.camera.nameReturn = nil end
            report(restored, reason); if callback then callback(restored, reason) end
        end
        local ok, why
        if reconcile == false then ok, why = names.Apply("camera", {}, completed)
        else ok, why = names.RestoreLayer("camera", completed) end
        if not ok then return report(ok, why) end
        return true
    end
    function camera.ToggleNames()
        if camera.active or db and db.camera.nameReturn then return report(nil, "EXIT_CAMERA_BEFORE_NAMES") end
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if next(db.camera.journal.entries) then return camera.RestoreNames(nil, false) end
        local target = 1
        for _, key in ipairs(ns.NamePolicy.Keys) do
            local item = ns.ReadOnly.Read(reader, key)
            if not ns.Planner.SafeObservation(item, key) then return report(nil, "NAME_CONTROLS_UNAVAILABLE") end
            if ns.Value.Number(item.raw) == 1 then target = 0 end
        end
        local targets = {}; for _, key in ipairs(ns.NamePolicy.Keys) do targets[key] = target end
        local ok, why = names.Apply("camera", targets, function(done, reason) report(done, reason) end)
        if not ok then return report(ok, why) end
        return true
    end
    local function namesResult(ok, code, pending)
        camera.nameResult = { ok = ok == true, code = code, pending = pending == true }
        if camera.NamesChanged then camera.NamesChanged() end
        if not pending then return report(ok, code) end
    end
    local function namesReady(entering)
        if not db or camera.busy or reader.resetPending or not camera.active and not entering then return nil, "CAMERA_NOT_READY" end
        if runtime.product.IsCombat() then return nil, "COMBAT_OR_RESTRICTION" end
        if names.busy or runtime.composition and runtime.composition.capturing
            or runtime.captureSequence and runtime.captureSequence.active or runtime.photoPreview and runtime.photoPreview.Pending() then return nil, "BUSY" end
        return true
    end
    function camera.EditNames(id, hidden)
        local ready, why = namesReady(false)
        if not ready then return namesResult(nil, why) end
        local known = id == "friendly" or id == "all"
        for _, group in ipairs(ns.NamePolicy.Groups) do if id == group.id then known = true end end
        if not known or type(hidden) ~= "boolean" then return namesResult(nil, "INVALID_NAME_CHOICE") end
        if id == "all" then
            db.camera.hideWithUI = hidden
            for _, group in ipairs(ns.NamePolicy.Groups) do
                if group.id ~= "bubbles" then db.camera.nameGroups[group.id] = hidden end
            end
        elseif id == "friendly" then db.camera.hideWithUI = hidden
        else db.camera.nameGroups[id] = hidden end
        return camera.ApplyNames()
    end
    function camera.ApplyNames(onComplete)
        local ready, why = namesReady(type(onComplete) == "function")
        if not ready then return namesResult(nil, why) end
        local targets, unavailable = ns.NamePolicy.Targets(reader, db.camera)
        camera.unavailableNames = unavailable
        -- Keep pre-session manual intent until the whole Camera session returns.
        local prior = db.camera.nameReturn and db.camera.nameReturn.targets or {}
        if not db.camera.nameReturn then
            for key, entry in pairs(db.camera.journal.entries) do prior[key] = ns.Value.Number(entry.lastVerifiedRaw) end
        end
        for key, value in pairs(prior) do if targets[key] == nil then targets[key] = value end end
        local proposal, code = names.CanApply("camera", targets)
        if not proposal then return namesResult(nil, code) end
        db.camera.nameReturn = db.camera.nameReturn or { targets = ns.Value.Copy(prior) }
        namesResult(nil, nil, true)
        local ok, why = names.Apply("camera", targets, function(done, reason)
            if done then camera.changedNames = next(db.camera.journal.entries) ~= nil end
            namesResult(done, reason)
            if done and onComplete then onComplete() end
            if camera.interrupted and camera.active and not runtime.product.IsCombat() then
                ns.ReadOnly.Call(reader, reader.env.C_Timer and reader.env.C_Timer.After, 0, camera.Exit)
            end
        end)
        if not ok then return namesResult(nil, why) end
        return true
    end
    local function retainedFraming(omit)
        local kept,why=runtime.framing.RespectComfortChoice()
        if not kept then return nil,why end
        local targets={}
        for key,entry in pairs(db.camera.framing.journal.entries) do
            if key~=omit then
                if ns.Framing.IsComfort(key) then
                    local item=ns.ReadOnly.Read(reader,key)
                    if item.code~="OK" then return nil,"CAMERA_COMFORT_UNAVAILABLE" end
                    if item.raw==entry.lastVerifiedRaw then targets[key]=ns.Value.Number(entry.lastVerifiedRaw)
                    elseif item.raw~=entry.originalRaw then return nil,"CAMERA_COMFORT_CHANGED" end
                    -- An outside return to the exact original is released, never disabled again in passing.
                else targets[key]=ns.Value.Number(entry.lastVerifiedRaw) end
            end
        end
        return targets
    end
    local function applyFraming(values, onComplete)
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if camera.busy then return report(nil, "BUSY") end
        if runtime.captureSequence and runtime.captureSequence.active and runtime.captureSequence.state ~= "WAITING_FOR_PREVIEW"
            or runtime.composition and runtime.composition.capturing then return report(nil, "BUSY") end
        local targets,reason = retainedFraming()
        if not targets then return report(nil,reason) end
        for key, value in pairs(values) do targets[key] = value end
        local ok, why = runtime.framing.Apply("camera", targets, function(done, code)
            report(done, code); if onComplete then onComplete(done, code) end
            if camera.interrupted and camera.active and not runtime.product.IsCombat() then
                ns.ReadOnly.Call(reader, reader.env.C_Timer and reader.env.C_Timer.After, 0, camera.Exit)
            end
        end)
        if not ok then return report(nil, why) end
        return true
    end
    function camera.ApplyFraming(values, onComplete)
        for key in pairs(values) do
            if ns.Framing.IsComfort(key) then return report(nil,"INVALID_EXPERIMENT_TARGETS") end
        end
        return applyFraming(values,onComplete)
    end
    function camera.UsePhotoFraming(onComplete)
        camera.CancelEntryFraming()
        if not camera.active or camera.interrupted or runtime.product.IsCombat() or runtime.portrait.active
            or runtime.composition.suspended or runtime.composition.controlsHidden or runtime.photoPreview.Pending() then
            return report(nil,"CAMERA_NOT_READY")
        end
        local state=ns.Framing.ReadComfort(reader)
        if state.error then return report(nil,state.error) end
        if not next(state.targets) then if onComplete then onComplete(true) end; return true end
        return applyFraming(state.targets,onComplete)
    end
    local function usePreferredFraming()
        if not db.camera.photoFramingOnEntry or not camera.active or camera.interrupted or reader.resetPending
            or runtime.product.IsCombat() or runtime.portrait.active or runtime.composition.suspended
            or runtime.composition.controlsHidden or camera.Visible()~=false then return end
        -- A preference may start a new session, but must not adopt an interrupted one's originals.
        local entries=db.camera.framing.journal.entries
        if (entries.CameraKeepCharacterCentered or entries.CameraReduceUnexpectedMovement)
            and (runtime.framing.state=="RECOVERY" or runtime.framing.state=="CONFLICT") then
            return report(nil,"RESTORE_FRAMING_FIRST")
        end
        return camera.UsePhotoFraming(camera.FramingPreferenceResult)
    end
    function camera.SetFramingOnEntry(enabled)
        if not db then return report(nil,"SAVED_DATA_QUARANTINED") end
        if type(enabled)~="boolean" then return nil,"INVALID_FRAMING_PREFERENCE" end
        if db.camera.photoFramingOnEntry==enabled then return true end
        camera.CancelEntryFraming()
        db.camera.photoFramingOnEntry=enabled
        if enabled and camera.active and not runtime.framing.busy then usePreferredFraming() end
        return true
    end
    local function enableFramingAfterEntry(afterNames)
        if not db.camera.photoFramingOnEntry then return end
        if not afterNames then usePreferredFraming(); return end
        -- Leave the names writer's verification callback before starting the framing writer.
        local ticket={}
        pendingEntryFraming=ticket
        local scheduled=ns.ReadOnly.Call(reader,reader.env.C_Timer and reader.env.C_Timer.After,0,function()
            if pendingEntryFraming~=ticket then return end
            pendingEntryFraming=nil
            usePreferredFraming()
        end)
        if not scheduled then pendingEntryFraming=nil; report(nil,"FOLLOWUP_TIMER_FAILED") end
    end
    function camera.ApplyFOV(value, callback) return camera.ApplyFraming({ cameraFov = value }, callback) end
    function camera.RestoreFOV(callback)
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        local targets,reason = retainedFraming("cameraFov")
        if not targets then return report(nil,reason) end
        if runtime.captureSequence.active or runtime.composition.capturing then return report(nil, "BUSY") end
        return runtime.framing.Apply("camera", targets, callback)
    end
    function camera.RestoreFraming(callback, manual)
        camera.CancelEntryFraming()
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if camera.active and (runtime.captureSequence and runtime.captureSequence.active or runtime.composition and runtime.composition.capturing) then return report(nil, "BUSY") end
        local kept,reason=runtime.framing.RespectComfortChoice()
        if not kept then return report(nil,reason) end
        if not next(db.camera.framing.journal.entries) then if callback then callback(true) end; return true end
        -- An exit never authorizes overwriting another camera addon's adjustment.
        local function finished(done,code)
            report(done,code); if callback then callback(done,code) end
        end
        local ok,why=runtime.framing.Apply("camera",{},finished)
        if not ok and manual==true and why=="EXPLICIT_RECOVERY_REQUIRED" and ns.Framing.CanRecoverComfort(reader,db.camera.framing) then
            ok,why=runtime.framing.RestoreLayer("camera",finished)
        end
        if not ok then return report(nil, why) end
        return true
    end
    function camera.Exit()
        camera.CancelEntryFraming()
        if runtime.portrait then runtime.portrait.Exit() end
        if runtime.photoComposition then runtime.photoComposition.Cancel() end
        local motionError
        if runtime.cameraActions then
            local stopped, why = runtime.cameraActions.StopOrbit()
            if not stopped then motionError = why end
        end
        if runtime.captureSequence then runtime.captureSequence.Cancel() end
        if runtime.photoPreview then runtime.photoPreview.Cancel("EXIT") end
        -- Showing the HUD is always the first attempt, even if name restoration fails.
        local shown, why = visibility(true)
        if not shown then return report(nil, why) end
        if runtime.composition then runtime.composition.CancelCapture() end
        if runtime.photoEditor then runtime.photoEditor.Hide() end
        if camera.busy or names.busy or runtime.framing.busy or runtime.photo.busy or runtime.output and runtime.output.busy or runtime.photoEditor and runtime.photoEditor.busy then
            camera.interrupted = true; return report(nil, "BUSY")
        end
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        camera.active, camera.busy = false, true
        local tasks, firstError = {}, nil
        if next(db.camera.output.records) then tasks[#tasks + 1] = runtime.output.RestoreAll end
        if db.camera.composition.zoom then tasks[#tasks + 1] = runtime.cameraActions.Restore end
        if db.camera.editor.session then tasks[#tasks + 1] = runtime.photoEditor.Restore end
        if db.camera.nameReturn then tasks[#tasks + 1] = function(done)
            return names.Apply("camera", ns.Value.Copy(db.camera.nameReturn.targets), function(ok, code)
                if ok then db.camera.nameReturn = nil; db.camera.sideEffects = {} end
                done(ok, code)
            end)
        end end
        if next(db.camera.framing.journal.entries) then tasks[#tasks + 1] = camera.RestoreFraming end
        if next(db.camera.photo.records) then tasks[#tasks + 1] = runtime.photo.RestorePhoto end
        local index = 0
        local function advance(ok, code)
            if not ok then firstError = firstError or code end
            index = index + 1
            if not tasks[index] then
                camera.busy = false
                if not firstError then camera.changedNames = false end
                if motionError and runtime.cameraActions.orbit then firstError = firstError or motionError end
                runtime.product.RefreshPresentation(true)
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
        camera.CancelEntryFraming()
        -- Cancel native movement/writes, not the user's screen treatment or staged art.
        if runtime.photoComposition then runtime.photoComposition.Cancel() end
        if runtime.cameraActions then runtime.cameraActions.Cancel() end
        if runtime.photoPreview then runtime.photoPreview.Cancel("COMBAT") end
        if runtime.captureSequence and runtime.captureSequence.state=="WAITING_FOR_PREVIEW" then runtime.captureSequence.Cancel() end
        if db and db.camera.keepInCombat and camera.active and not camera.interrupted then
            if runtime.photoEditor then runtime.photoEditor.Render() end
            return
        end
        if runtime.portrait then runtime.portrait.Exit() end
        if runtime.captureSequence then runtime.captureSequence.Cancel() end
        camera.interrupted = true
        if runtime.composition then runtime.composition.CancelCapture() end
        if runtime.photoEditor then runtime.photoEditor.Render() end
        if camera.active or camera.busy then visibility(true) end
    end
    function camera.Toggle()
        if camera.busy or names.busy or runtime.photo.busy or runtime.framing.busy and not camera.active then return report(nil, "BUSY") end
        local shown, why = camera.Visible()
        if shown == nil then return report(nil, why) end
        if camera.active or not shown then return camera.Exit() end
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if runtime.product.IsCombat() then
            if not camera.CanCompose() then return report(nil,"COMBAT_OR_RESTRICTION") end
            -- Start a cosmetic/model session at current native settings. Never queue deferred writes.
            if runtime.photoCompatibility then local ok,why=runtime.photoCompatibility.Prepare(); if not ok then return report(nil,why) end end
            camera.interrupted=false
            local ok,why=visibility(false); camera.active=ok==true
            if ok then runtime.photoEditor.Enter(); runtime.composition.Show() end
            return report(ok,why)
        end
        if type(reader.env.SetUIVisibility) ~= "function" then return report(nil, "UI_VISIBILITY_UNAVAILABLE") end
        if db.camera.nameReturn then return report(nil, "RESTORE_CAMERA_NAMES_FIRST") end
        if runtime.photoCompatibility then
            local ready, reason = runtime.photoCompatibility.Prepare(); if not ready then return report(nil, reason) end
        end
        camera.interrupted = false
        local function hide(afterNames)
            -- Combat or an external UI change during name verification is not a new hide request.
            if camera.interrupted or runtime.product.IsCombat() or camera.Visible() ~= true then return report(nil, "CAMERA_ENTRY_INTERRUPTED") end
            local ok, reason = visibility(false)
            camera.active = ok == true
            if ok and runtime.photoEditor then runtime.photoEditor.Enter() end
            if ok and runtime.composition then runtime.composition.Show() end
            report(ok, reason)
            if ok then enableFramingAfterEntry(afterNames) end
            return ok, reason
        end
        local function enter()
            if camera.interrupted or runtime.product.IsCombat() then return report(nil, "CAMERA_ENTRY_INTERRUPTED") end
            local targets, unavailable = ns.NamePolicy.Targets(reader, db.camera)
            camera.unavailableNames = unavailable
            if next(targets) then return camera.ApplyNames(function() hide(true) end) end
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
