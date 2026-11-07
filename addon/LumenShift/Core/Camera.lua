local _, ns = ...
local C = {}
ns.Camera = C
function C.New(runtime)
    local camera = { active = false, changedNames = false }
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
    function camera.Exit()
        -- Showing the HUD is always the first attempt, even if name restoration fails.
        local shown, why = visibility(true)
        if not shown then return report(nil, why) end
        if camera.changedNames then
            return camera.RestoreNames(function(ok)
                if ok then camera.active, camera.changedNames = false, false end
                if runtime.product then runtime.product.Refresh() end
            end, false)
        end
        camera.active = false; return report(true)
    end
    function camera.Toggle()
        if names.busy then return report(nil, "BUSY") end
        local shown, why = camera.Visible()
        if shown == nil then return report(nil, why) end
        if camera.active or not shown then return camera.Exit() end
        if not db then return report(nil, "SAVED_DATA_QUARANTINED") end
        if runtime.product.IsCombat() then return report(nil, "COMBAT_OR_RESTRICTION") end
        if type(reader.env.SetUIVisibility) ~= "function" then return report(nil, "UI_VISIBILITY_UNAVAILABLE") end
        local function hide()
            -- Combat or an external UI change during name verification is not a new hide request.
            if runtime.product.IsCombat() or camera.Visible() ~= true then return report(nil, "CAMERA_ENTRY_INTERRUPTED") end
            local ok, reason = visibility(false)
            camera.active = ok == true
            return report(ok, reason)
        end
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
    return camera
end
