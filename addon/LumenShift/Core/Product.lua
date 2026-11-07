local _, ns = ...
local P = {}
ns.Product = P

function P.New(runtime)
    local product = { active = "natural", busy = false, generation = 0, lastError = nil }
    local env, db, engine = runtime.reader.env, runtime.db, runtime.engine
    local function report(code)
        product.lastError = code
        ns.Log.Record(runtime.reader, "product", "operation", "WARN", code or "UNKNOWN")
        ns.Diagnostics.Emit(runtime, "LumenShift: " .. code)
        if product.Refresh then product.Refresh() end
        return nil, code
    end
    local function combat()
        local result = ns.ReadOnly.Call(runtime.reader, env.InCombatLockdown)
        return not result or result.n ~= 1 or result[1] ~= false
    end
    local function config() return db and db.config.studio end
    local function clear()
        if runtime.presentation then runtime.presentation.Clear() end
    end
    local function commit(id, settings)
        local previous = product.active
        product.active, product.lastError = id, nil
        product.appliedBrightness = settings.brightness
        db.config.selected.visual = id
        ns.Log.Record(runtime.reader, "product", "mode-commit", "INFO", "PASS", { mode = id, requested = settings.brightness })
        if runtime.presentation then
            local ok, code = runtime.presentation.Apply(id, settings, db.config)
            if not ok then
                product.lastError = code; ns.Diagnostics.Emit(runtime, "LumenShift: " .. code)
                ns.Log.Record(runtime.reader, "presentation", "apply", "ERROR", code)
            end
        end
        if runtime.audio then runtime.audio.Transition(previous, id, db.config) end
        if product.Refresh then product.Refresh() end
    end
    function product.Enable(acknowledged)
        if not db or not ns.Profiles.Validate(db.config) then return report("SAVED_DATA_QUARANTINED") end
        if acknowledged ~= true then return report("Read and acknowledge the recovery notice first.") end
        if combat() then return report("Outside combat only. Retry after combat.") end
        if engine.Status().state ~= "BASELINE" then return report("Resolve existing recovery before setup.") end
        if not engine.Status().setterAvailable then return report("SETTER_UNAVAILABLE") end
        if type(env.C_Timer) ~= "table" or type(env.C_Timer.After) ~= "function" then return report("FOLLOWUP_TIMER_UNAVAILABLE") end
        local item = ns.ReadOnly.Read(runtime.reader, "Brightness")
        if not ns.Planner.SafeObservation(item) then return report("BRIGHTNESS_UNAVAILABLE_OR_RESTRICTED") end
        if ns.Compatibility.Inspect(runtime.reader).signature ~= "1.60.1:70790:16001" then return report("UNSUPPORTED_BUILD") end
        if not ns.Diagnostics.Emit(runtime, "LumenShift recovery note: current Brightness=" .. item.raw
            .. ". Save this outside the game. Each new ownership captures the actual then-current value; SavedVariables can lag or be lost.") then
            return report("RECOVERY_CARD_NOT_DISPLAYED")
        end
        config().enabled = true
        ns.Log.Record(runtime.reader, "configuration", "enable-controls", "INFO", "PASS_NO_WRITE")
        ns.Diagnostics.Emit(runtime, "LumenShift: visual switching enabled. Nothing applied yet; login never reapplies a mode.")
        if product.Refresh then product.Refresh() end
        return true
    end
    function product.Disable()
        if not db then return report("SAVED_DATA_QUARANTINED") end
        if product.busy or next(db.journal.entries) or next(db.experiments.journal.entries) then return report("Restore visuals and quality before disabling controls.") end
        config().enabled = false
        engine.Cancel()
        product.active = "natural"; clear()
        if runtime.audio then runtime.audio.Stop() end
        if product.Refresh then product.Refresh() end
        return true
    end
    function product.Select(id)
        if not db or not config().enabled then return report("Click LumenShift and complete setup to enable visual switching.") end
        if product.busy then return report("An operation is still being verified.") end
        if not ns.StudioConfig.Labels[id] or not ns.StudioConfig.Validate(config()) then return report("INVALID_MODE_CONFIG") end
        if combat() then return report("Outside combat only. No change queued.") end
        if type(env.C_Timer) ~= "table" or type(env.C_Timer.After) ~= "function" then return report("FOLLOWUP_TIMER_UNAVAILABLE") end
        local settings = ns.Value.Copy(config().modes[id])
        local contrast = id ~= "natural" and settings.useContrast and { Contrast = settings.contrast } or {}
        local needsContrast = next(contrast) ~= nil or db.experiments.journal.entries.Contrast ~= nil
        if runtime.lab and runtime.lab.busy then return report("OTHER_OPERATION_ACTIVE") end
        if needsContrast then
            local planned, reason = runtime.lab.CanApply("visual", contrast)
            if not planned then return report(reason) end -- before ANY Brightness write
        end
        ns.Log.Record(runtime.reader, "product", "mode-select", "INFO", "USER_REQUEST", { mode = id })
        local function finishMode()
            if not needsContrast then commit(id, settings); return true end
            product.busy = true
            local started, why = runtime.lab.Apply("visual", contrast, function(verified, reason)
                product.busy = false
                if verified then commit(id, settings)
                else clear(); product.active = "natural"; report("MODE_PARTIAL: " .. (reason or "CONTRAST_FAILED")) end
            end)
            if not started then
                product.busy = false; clear(); product.active = "natural"
                return report("MODE_PARTIAL: " .. (why or "CONTRAST_FAILED"))
            end
            return true
        end
        local previous = product.active
        product.busy, product.generation = true, product.generation + 1
        local generation = product.generation
        local ok, code = engine.Switch(id ~= "natural" and settings.brightness or nil)
        local status = engine.Status()
        if status.state ~= "AWAITING_VERIFICATION" then
            product.busy = false
            if ok then return finishMode() end
            if status.state ~= "ACTIVE" then clear(); product.active = "natural" end
            return report(code or "SWITCH_FAILED")
        end
        -- A second read on a later timer turn, NOT a claim of measured settling.
        -- Brightness verification is read-only; a requested Contrast leg follows only on success.
        -- Failure locks recovery and removes presentation.
        local followup = function()
            if generation ~= product.generation then return end
            product.busy = false
            if engine.Status().transactionID ~= status.transactionID then
                clear(); product.active = "natural"; report("OPERATION_SUPERSEDED: use Recovery to inspect the current transaction."); return
            end
            local verified, reason = engine.Verify()
            if not verified then clear(); product.active = "natural"; report(reason or "VERIFY_FAILED"); return end
            if ok then finishMode()
            else
                product.active = previous
                report(code or "OPERATION_COMPENSATED")
            end
        end
        local handler = runtime.log and runtime.log.Guard("product", "followup", followup, function()
            product.busy = false; engine.Cancel(); clear(); product.active = "natural"
        end) or followup
        local scheduled = pcall(env.C_Timer.After, 0.15, handler)
        if not scheduled then
            product.busy = false; engine.Cancel(); clear(); product.active = "natural"
            return report("FOLLOWUP_TIMER_FAILED: original retained; use Diagnostics and Recovery.")
        end
        if product.Refresh then product.Refresh() end
        return ok, code
    end
    function product.Toggle()
        return product.Select(product.active == "nightVision" and "natural" or "nightVision")
    end
    function product.Observe()
        if product.busy then return end
        if runtime.lab then
            runtime.lab.Observe()
            if db and db.experiments.journal.entries.Contrast and (runtime.lab.state == "RECOVERY" or runtime.lab.state == "CONFLICT") then
                clear(); product.active = "natural"
            end
        end
        local status = engine.Status()
        if status.state ~= "ACTIVE" and product.active ~= "natural" then
            if status.state == "BASELINE" and db and not next(db.journal.entries) then
                local item = ns.ReadOnly.Read(runtime.reader, "Brightness")
                if ns.Planner.SafeObservation(item) and ns.Value.Number(item.raw) == product.appliedBrightness then
                    if product.Refresh then product.Refresh() end
                    return -- presentation may be active at an already-matching, unowned value
                end
            end
            clear(); product.active = "natural"
            if status.state ~= "BASELINE" then report("Graphics ownership is uncertain; effects suspended. Open Recovery.") end
        end
        if product.Refresh then product.Refresh() end
    end
    function product.Combat()
        ns.Log.Record(runtime.reader, "product", "combat", "INFO", "PRESENTATION_SUSPENDED_NO_WRITE")
        if runtime.presentation then runtime.presentation.Combat() end
        if runtime.audio then runtime.audio.Stop() end
        if runtime.ui then runtime.ui.CloseWheel() end
        if runtime.exportUI then runtime.exportUI.window:Hide() end
        if runtime.setup and runtime.setup.window then runtime.setup.window:Hide() end
    end
    function product.RefreshPresentation()
        if runtime.presentation and db then
            return runtime.presentation.Apply(product.active, config().modes[product.active], db.config)
        end
    end
    function product.Update(mutator)
        if not db then return report("SAVED_DATA_QUARANTINED") end
        local copy = ns.Value.Copy(db.config)
        local ok = pcall(mutator, copy)
        if not ok or not ns.Profiles.Validate(copy) then return report("INVALID_CONFIGURATION") end
        db.config = copy
        ns.Log.Record(runtime.reader, "configuration", "edit", "DEBUG", "VALIDATED_NO_WRITE")
        if product.Refresh then product.Refresh() end
        return true
    end
    function product.SavePreset(name, id)
        if not db then return report("SAVED_DATA_QUARANTINED") end
        local copy, code = ns.StudioConfig.SavePreset(config(), name, id)
        if not copy then return report(code) end
        db.config.studio = copy
        ns.Log.Record(runtime.reader, "presets", "save", "INFO", "PASS", { mode = id })
        if product.Refresh then product.Refresh() end
        return code
    end
    function product.LoadPreset(id)
        if not db then return report("SAVED_DATA_QUARANTINED") end
        local copy, mode = ns.StudioConfig.LoadPreset(config(), id)
        if not copy then return report(mode) end
        db.config.studio = copy
        ns.Log.Record(runtime.reader, "presets", "load", "INFO", "USER_REQUEST", { mode = mode })
        return product.Select(mode)
    end
    product.IsCombat = combat
    return product
end
