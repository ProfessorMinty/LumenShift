local _, ns = ...
local P = {}
ns.Product = P
local messages = {
    COMBAT_OR_RESTRICTION = "Try again after combat.",
    SETTER_UNAVAILABLE = "The game's graphics control API is unavailable. Open Diagnostics for details.",
    FOLLOWUP_TIMER_UNAVAILABLE = "The game's follow-up timer is unavailable. Open Diagnostics for details.",
    OTHER_OPERATION_ACTIVE = "Wait for the current change to finish.",
    BUSY = "Wait for the current change to finish.",
    EXTERNAL_CONFLICT = "This setting changed outside LumenShift. Your change was kept; open Recovery to choose what to restore.",
    EXPLICIT_RECOVERY_REQUIRED = "An earlier change needs attention. Open Recovery to inspect the saved original.",
    RECOVERY_REQUIRED = "An earlier change needs attention. Open Recovery to inspect the saved original.",
    RESTORE_EXPERIMENTS_BEFORE_CALIBRATING = "Restore the active Contrast and quality changes before trying a temporary test.",
    RESTORE_BRIGHTNESS_BEFORE_CALIBRATING = "Restore pre-change Brightness in Diagnostic Center before a temporary test.",
    UNCHANGED_VALUE_IS_NOT_A_CALIBRATION = "Choose a different value to see a change.",
    CONFIGURE_PROFILE_FIRST = "This profile is empty. Add settings in Advanced Graphics first.",
    OUTSIDE_BOUNDED_TEST_POLICY = "That value is outside this control's available range.",
    INVALID_TEST_STEP = "Choose a value using the step shown for this control.",
    RESTORE_GRAPHICS_BANK_FIRST = "Restore everyday graphics on the Graphics Quality page before changing overlapping detail settings.",
    QUALITY_TRIAL_RECOVERY_REQUIRED = "Finish or restore the quality trial in Advanced Graphics first.",
    RESTORE_ACTIVE_SETTINGS_BEFORE_TIER_TRIAL = "Restore pre-change visuals in Diagnostic Center and choose Current Baseline for quality before a native tier trial.",
    INVALID_TIER_CHOICE = "Choose one of the available quality levels first.",
    UNCHANGED_TIER_CHOICE = "That level is already selected. Choose a different level for the trial.",
    NO_TIER_ORIGINAL = "There is no interrupted quality trial to restore.",
    NAME_CONTROLS_UNAVAILABLE = "Friendly-name controls are unavailable. Open Diagnostics for the API results.",
    UI_VISIBILITY_UNAVAILABLE = "The game interface visibility API is unavailable. Alt+Z remains the game's own shortcut.",
    UI_VISIBILITY_NOT_CHANGED = "The game did not change interface visibility. Your name originals are retained.",
    CAMERA_ENTRY_INTERRUPTED = "Camera entry was interrupted. The interface was left visible; restore names from the Camera page if needed.",
    TIER_OR_DEPENDENT_RESTORATION_INCOMPLETE = "Some values did not return to their originals. Export the report; originals are retained. No repair values were guessed.",
    EXTERNAL_CONFLICT_NO_AUTOMATIC_RESTORE = "A setting changed during the trial. Automatic restoration stopped; review the report before restoring the trial.",
    BLOOM_CAPABILITY_UNAVAILABLE = "Bloom support could not be checked. Other controls remain available.",
    BLOOM_LINEAR_RENDERER_UNAVAILABLE = "Bloom needs the game's linear renderer. Other controls remain available.",
    FINISH_COMPARISON = "Finish the Before / After comparison before applying another change.",
    COMPARISON_CHANGED_EXTERNALLY = "The scene changed outside LumenShift. That change was kept; use Recovery if you want the captured originals.",
    USE_SHARED_OPTICAL_RESTORE = "Use Restore captured visuals in Diagnostic Center to restore shared visual and detail originals.",
    USE_MODE_DETAIL_CONTROLS = "Use Visual Modes detail controls or finish the current comparison first.",
    MODE_PARTIAL = "The mode did not finish applying. Your original values are retained; open Recovery.",
    BASELINE_VALUE_UNAVAILABLE = "This baseline value was unavailable during setup. Open Setup and capture it again, or choose another mode.",
}
function P.Message(code)
    if not code then return nil end
    return messages[code] or messages[code:match("^([^:]+):")] or code
end

function P.New(runtime)
    local product = { active = "natural", state = "IDLE", busy = false, generation = 0, lastError = nil }
    local env, db, engine = runtime.reader.env, runtime.db, runtime.engine
    local function report(code, message)
        product.lastError, product.lastMessage = code, message or P.Message(code)
        ns.Log.Record(runtime.reader, "product", "operation", "WARN", code or "UNKNOWN")
        ns.Diagnostics.Emit(runtime, "LumenShift: " .. product.lastMessage)
        if product.Refresh then product.Refresh() end
        return nil, code, product.lastMessage
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
        product.active, product.lastError, product.lastMessage = id, nil, nil
        product.state, product.combatSuspended = "ACTIVE", false
        product.baselineVerified = id == "natural"
        product.appliedBrightness = ns.Value.Number(ns.ReadOnly.Read(runtime.reader, "Brightness").raw)
        product.appliedSettings = ns.Value.Copy(settings)
        db.config.selected.visual = id
        ns.Log.Record(runtime.reader, "product", "mode-commit", "INFO", "PASS", { mode = id,
            requested = id ~= "natural" and settings.brightness or nil,
            detail = id == "natural" and (db.baseline.chosen and "SELECTED_BASELINE_VERIFIED" or "CAPTURED_ORIGINAL_RESTORED") or nil })
        if runtime.presentation then
            local ok, code = runtime.presentation.Apply(id, settings, db.config, db.camera.keepEffects)
            if not ok then
                product.lastError, product.lastMessage = code, P.Message(code); ns.Diagnostics.Emit(runtime, "LumenShift: " .. code)
                ns.Log.Record(runtime.reader, "presentation", "apply", "ERROR", code)
            end
        end
        if runtime.audio then runtime.audio.Transition(previous, id, db.config) end
        if product.Refresh then product.Refresh() end
    end
    function product.Availability()
        if not db or not ns.Profiles.Validate(db.config) then return nil, "Saved preferences need recovery. Open Diagnostic Center.", "SAVED_DATA_QUARANTINED" end
        local identity = ns.Compatibility.Inspect(runtime.reader)
        if not ns.Compatibility.Experimental(identity.signature) then return nil, ns.Compatibility.Explain(identity), "IDENTITY_UNAVAILABLE" end
        if combat() then return nil, "Try again after combat.", "COMBAT_OR_RESTRICTION" end
        if product.busy or (runtime.lab and runtime.lab.busy) then return nil, "Wait for the current change to finish.", "BUSY" end
        local state = engine.Status().state
        if state ~= "BASELINE" and state ~= "ACTIVE" and not engine.CanContinue() then return nil, "An earlier change needs attention. Open Recovery to inspect the saved original.", "RECOVERY_REQUIRED" end
        if not engine.Status().setterAvailable then return nil, messages.SETTER_UNAVAILABLE, "SETTER_UNAVAILABLE" end
        if type(env.C_Timer) ~= "table" or type(env.C_Timer.After) ~= "function" then return nil, messages.FOLLOWUP_TIMER_UNAVAILABLE, "FOLLOWUP_TIMER_UNAVAILABLE" end
        local item = ns.ReadOnly.Read(runtime.reader, "Brightness")
        if not ns.Planner.SafeObservation(item) then return nil, "Brightness is unavailable or restricted. Try again after loading; Diagnostics has the details.", "BRIGHTNESS_UNAVAILABLE_OR_RESTRICTED" end
        return true, item
    end
    function product.CanEnable()
        local ready, detail, code = product.Availability()
        if not ready then return nil, detail, code end
        return true, detail
    end
    function product.Enable()
        local ready, item, code = product.CanEnable()
        if not ready then return report(code, item) end
        config().enabled = true
        ns.Log.Record(runtime.reader, "configuration", "enable-controls", "INFO", "PASS_NO_WRITE")
        if product.Refresh then product.Refresh() end
        return true
    end
    function product.Disable()
        if not db then return report("SAVED_DATA_QUARANTINED") end
        if product.busy or next(db.journal.entries) or next(db.experiments.journal.entries) then return report("Restore visuals and quality before disabling controls.") end
        config().enabled = false
        engine.Cancel()
        product.active, product.baselineVerified, product.state = "natural", false, "IDLE"; clear()
        if runtime.audio then runtime.audio.Stop() end
        if product.Refresh then product.Refresh() end
        return true
    end
    function product.Select(id)
        if not db then return report("SAVED_DATA_QUARANTINED", "Preferences could not be loaded. Open Diagnostics for details.") end
        if not config().enabled then
            local enabled, code, message = product.Enable()
            if not enabled then return nil, code, message end
        end
        if product.busy then return report("An operation is still being verified.") end
        if db.optics.comparison then return report("FINISH_COMPARISON") end
        if not ns.StudioConfig.Labels[id] or not ns.StudioConfig.Validate(config()) then return report("INVALID_MODE_CONFIG") end
        if not ns.Baseline.Validate(db.baseline) then return report("INVALID_BASELINE_CONFIG") end
        ns.Baseline.CompleteMissing(runtime) -- explicit click only; no startup capture/write
        if combat() then return report("Outside combat only. No change queued.") end
        if type(env.C_Timer) ~= "table" or type(env.C_Timer.After) ~= "function" then return report("FOLLOWUP_TIMER_UNAVAILABLE") end
        local settings = ns.Value.Copy(config().modes[id])
        local contrast = id ~= "natural" and settings.useContrast and { Contrast = settings.contrast } or {}
        local brightnessTarget = id ~= "natural" and settings.brightnessMode == "custom" and settings.brightness or nil
        if (id == "natural" or settings.brightnessMode == "inherit") and db.baseline.chosen then
            local why; brightnessTarget, why = ns.Baseline.Target(runtime, "Brightness")
            if why then return report(why) end
        end
        if db.baseline.chosen and not next(contrast) and db.baseline.values.Contrast then
            contrast.Contrast = ns.Baseline.Target(runtime, "Contrast")
        end
        local needsContrast = next(contrast) ~= nil or db.experiments.journal.entries.Contrast ~= nil
        if runtime.lab and runtime.lab.busy then return report("OTHER_OPERATION_ACTIVE") end
        if needsContrast then
            local planned, reason = runtime.lab.CanApply("visual", contrast)
            if not planned then return report(reason) end -- before ANY Brightness write
        end
        local optical = id == "natural" and {} or ns.Optics.ModeTargets(settings)
        local shared = needsContrast or next(optical) ~= nil or next(db.optics.visual) ~= nil
        ns.Log.Record(runtime.reader, "product", "mode-select", "INFO", "USER_REQUEST", { mode = id })
        if shared then
            local previous, previousState, previousSettings = product.active, product.state, product.appliedSettings
            local targets = ns.Value.Copy(contrast); targets.Brightness = brightnessTarget
            for key, value in pairs(optical) do targets[key] = value end
            product.busy, product.state = true, "APPLYING"
            local completed = false
            local ok, why = runtime.visual.Apply(targets, function(verified, reason, restored)
                completed = true; product.busy = false
                if verified then commit(id, settings)
                elseif restored then
                    product.active, product.state, product.appliedSettings = previous, previousState, previousSettings
                    product.RefreshPresentation(true)
                    report("MODE_COMPENSATED", "The mode could not apply; the previous values were restored. " .. P.Message(reason))
                else
                    clear(); product.state, product.baselineVerified = "PARTIAL", false
                    report("MODE_PARTIAL: " .. (reason or "APPLY_FAILED"))
                end
            end)
            if not ok and not completed then
                product.busy, product.state = false, previousState
                return report(why)
            end
            if product.Refresh then product.Refresh() end
            return ok, why
        end
        local function finishMode() commit(id, settings); return true end
        local previous = product.active
        product.busy, product.generation = true, product.generation + 1
        local generation = product.generation
        local ok, code = engine.Switch(brightnessTarget)
        local status = engine.Status()
        if status.state ~= "AWAITING_VERIFICATION" then
            product.busy = false
            if ok then return finishMode() end
            if status.state ~= "ACTIVE" then clear(); product.active, product.state = "natural", "RECOVERY" end
            return report(code or "SWITCH_FAILED")
        end
        -- A second read on a later timer turn, NOT a claim of measured settling.
        -- Brightness-only verification is read-only; composite modes use NewVisual above.
        -- Failure locks recovery and removes presentation.
        local followup = function()
            if generation ~= product.generation then return end
            product.busy = false
            if engine.Status().transactionID ~= status.transactionID then
                clear(); product.active, product.state = "natural", "RECOVERY"; report("OPERATION_SUPERSEDED: use Recovery to inspect the current transaction."); return
            end
            local verified, reason = engine.Verify()
            if not verified then clear(); product.active, product.state = "natural", "RECOVERY"; report(reason or "VERIFY_FAILED"); return end
            if ok then finishMode()
            else
                product.active = previous
                report(code or "OPERATION_COMPENSATED")
            end
        end
        local handler = runtime.log and runtime.log.Guard("product", "followup", followup, function()
            product.busy = false; engine.Cancel(); clear(); product.active, product.state = "natural", "RECOVERY"
        end) or followup
        local scheduled = pcall(env.C_Timer.After, 0.15, handler)
        if not scheduled then
            product.busy = false; engine.Cancel(); clear(); product.active, product.state = "natural", "RECOVERY"
            return report("FOLLOWUP_TIMER_FAILED: original retained; use Diagnostics and Recovery.")
        end
        if product.Refresh then product.Refresh() end
        return ok, code
    end
    function product.ActiveLabel()
        local comparison = db and db.optics.comparison
        if comparison then return "Comparison / " .. comparison.state end
        if product.state == "PARTIAL" then return "Partial / Recovery" end
        if product.state == "RECOVERY" then return "Recovery needed" end
        if product.state == "APPLYING" or product.busy then return "Applying mode..." end
        if product.state == "IDLE" or product.active == "natural" and not product.baselineVerified then return "No mode applied" end
        return ns.StudioConfig.Label(product.active)
    end
    function product.Toggle()
        return product.Select(product.active == "nightVision" and "natural" or "nightVision")
    end
    function product.Observe(resumeCosmetics)
        if product.busy then return end
        if runtime.visual.ObserveComparison() == "recovery" then clear(); product.state = "RECOVERY" end
        if db and next(db.optics.visual) and not db.optics.comparison then
            for key, target in pairs(db.optics.visual) do
                local item = ns.ReadOnly.Read(runtime.reader, key)
                if not ns.Planner.SafeObservation(item) or ns.Value.Number(item.raw) ~= target then
                    clear(); product.state, product.baselineVerified = "RECOVERY", false
                    report("EXTERNAL_CONFLICT"); break
                end
            end
        end
        if runtime.lab then
            runtime.lab.Observe()
            if db and db.experiments.journal.entries.Contrast and (runtime.lab.state == "RECOVERY" or runtime.lab.state == "CONFLICT") then
                clear(); product.active, product.baselineVerified, product.state = "natural", false, "RECOVERY"
            end
        end
        local status = engine.Status()
        if product.baselineVerified and db and db.baseline.chosen then
            for key, raw in pairs(db.baseline.values) do
                local seen = ns.ReadOnly.Read(runtime.reader, key)
                if not ns.Planner.SafeObservation(seen) or ns.Value.Number(seen.raw) ~= ns.Value.Number(raw) then
                    product.baselineVerified = false
                end
            end
            if status.state ~= "BASELINE" and status.state ~= "ACTIVE" then product.baselineVerified = false end
        end
        if status.state ~= "ACTIVE" and product.active ~= "natural" then
            if status.state == "BASELINE" and db and not next(db.journal.entries) then
                local item = ns.ReadOnly.Read(runtime.reader, "Brightness")
                if ns.Planner.SafeObservation(item) and ns.Value.Number(item.raw) == product.appliedBrightness then
                    if resumeCosmetics and product.combatSuspended then product.RefreshPresentation(true) end
                    if product.Refresh then product.Refresh() end
                    return -- presentation may be active at an already-matching, unowned value
                end
            end
            clear(); product.active, product.state = "natural", "RECOVERY"
            if status.state ~= "BASELINE" then report("Graphics ownership is uncertain; effects suspended. Open Recovery.") end
        end
        if resumeCosmetics and product.combatSuspended then product.RefreshPresentation(true) end
        if product.Refresh then product.Refresh() end
    end
    function product.Combat()
        product.combatSuspended = true
        ns.Log.Record(runtime.reader, "product", "combat", "INFO", "PRESENTATION_SUSPENDED_NO_WRITE")
        if runtime.presentation then runtime.presentation.Combat() end
        if runtime.audio then runtime.audio.Stop() end
        if runtime.ui then runtime.ui.CloseWheel() end
        if runtime.exportUI then runtime.exportUI.window:Hide() end
        if runtime.setup and runtime.setup.window then runtime.setup.window:Hide() end
    end
    function product.RefreshPresentation(resume)
        if runtime.presentation and db then
            if product.state ~= "ACTIVE" or product.IsCombat()
                or db.optics.comparison and db.optics.comparison.state ~= "after" then runtime.presentation.Clear(); return true end
            product.combatSuspended = false
            local mode = resume and product.appliedSettings or config().modes[product.active]
            if not mode then runtime.presentation.Clear(); return true end
            product.appliedSettings = ns.Value.Copy(mode)
            return runtime.presentation.Apply(product.active, mode, db.config, db.camera.keepEffects)
        end
    end
    function product.Compare(side, onComplete)
        if product.busy then return report("BUSY") end
        if side ~= "done" and not db.optics.comparison and product.state ~= "ACTIVE" then return report("Apply a mode before comparing.") end
        product.busy = true
        local completed, previousState = false, product.state
        local function done(ok, why, compensated)
            completed, product.busy = true, false
            if ok then
                if product.appliedSettings then product.state = "ACTIVE" end
                product.lastError, product.lastMessage = nil, side == "done" and "Comparison finished. Your applied look is back." or "Showing " .. side .. "."
                product.RefreshPresentation(true)
            elseif compensated then
                product.state = previousState; product.RefreshPresentation(true)
                report(why, "Comparison could not change the scene; the prior view was restored.")
            else clear(); product.state = "RECOVERY"; report(why) end
            if product.Refresh then product.Refresh() end
            if onComplete then onComplete() end
        end
        local ok, why
        if side == "done" then ok, why = runtime.visual.EndComparison(done)
        else ok, why = runtime.visual.Compare(side, done) end
        if not ok and not completed then product.busy = false; return report(why) end
        return ok, why
    end
    function product.RestoreVisuals(onComplete)
        if product.busy then return report("BUSY") end
        product.busy = true
        local ok, why = runtime.visual.Restore(function(restored, reason)
            product.busy, product.baselineVerified = false, false
            clear()
            if restored then
                product.active, product.state, product.lastError = "natural", "IDLE", nil
                product.lastMessage = "Captured visual and optical originals restored. Saved mode/profile edits are unchanged."
            else product.state = "PARTIAL"; report("MODE_PARTIAL: " .. (reason or "RESTORE_FAILED")) end
            if product.Refresh then product.Refresh() end
            if onComplete then onComplete() end
        end)
        if not ok then product.busy = false; return report(why) end
        return true
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
    function product.ImportPreset(name, text)
        if not db then return report("SAVED_DATA_QUARANTINED") end
        local copy, id = ns.StudioConfig.ImportPreset(config(), name, text)
        if not copy then return report(id) end
        db.config.studio = copy
        product.lastError, product.lastMessage = nil, "Preset imported. Click Apply on its card to use it."
        if product.Refresh then product.Refresh() end
        return id
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
