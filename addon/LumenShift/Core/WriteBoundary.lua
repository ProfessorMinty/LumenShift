local _, ns = ...
local B, V, R = {}, ns.Value, ns.Recovery
ns.WriteBoundary = B
local function setterAvailable(reader)
    return type(reader.env.C_CVar) == "table" and type(reader.env.C_CVar.SetCVar) == "function"
end
-- The only native CVar call site: graphics, bounded trials and the two camera-name toggles.
-- Private callers use narrow policies, planner, fresh observations and combat checks.
local function nativeSet(reader, key, target)
    local result, code = ns.ReadOnly.Call(reader, reader.env.C_CVar.SetCVar, key, target)
    local accepted = result and result.n == 1 and result[1] == true
    ns.Log.Record(reader, "graphics", "setter", accepted and "INFO" or "ERROR", accepted and "ACCEPTED" or code or "SETTER_REJECTED",
        { key = key, requested = target, setter = accepted and "true" or code or (result and result.n == 1 and result[1] == false and "false" or "unexpected-return") })
    return result, code
end

-- No ambient enable switch or public raw setter. A preview token is consumed once.
function B.Request() return nil, "TEST_NOT_ENABLED" end

-- Composite visual/optical requests share the canonical experimental optical records.
-- Non-optical quality entries stay independent; no second copy of an original is stored.
function B.NewVisual(runtime)
    local reader, db = runtime.reader, runtime.db
    local signature = ns.Compatibility.Inspect(reader).signature
    local self = { busy = false, state = "IDLE", serial = 0 }
    local executing, comparing, cancel = false, false, nil
    reader.visualBusy = function() return self.busy or executing or comparing end
    local function combat()
        local result = ns.ReadOnly.Call(reader, reader.env.InCombatLockdown)
        return not result or result.n ~= 1 or result[1] ~= false
    end
    local function gate()
        if not db or not ns.Store.ValidateJournal(db.journal) or not ns.ExperimentPolicy.Validate(db.experiments) then return nil, "INVALID_JOURNAL" end
        if ns.Compatibility.Inspect(reader).signature ~= signature or not ns.Compatibility.Experimental(signature) then return nil, "IDENTITY_UNAVAILABLE" end
        if combat() then return nil, "COMBAT_OR_RESTRICTION" end
        if not setterAvailable(reader) then return nil, "SETTER_UNAVAILABLE" end
        if type(reader.env.C_Timer) ~= "table" or type(reader.env.C_Timer.After) ~= "function" then return nil, "FOLLOWUP_TIMER_UNAVAILABLE" end
        if runtime.engine.Status().state == "AWAITING_VERIFICATION" or runtime.lab.busy
            or reader.brightnessExecuting and reader.brightnessExecuting()
            or reader.experimentBusy and reader.experimentBusy()
            or reader.nameBusy and reader.nameBusy() or reader.graphicsBusy and reader.graphicsBusy()
            or reader.tierOccupied and reader.tierOccupied() then return nil, "OTHER_OPERATION_ACTIVE" end
        return true
    end
    local function observe()
        local seen = {}
        for _, key in ipairs(ns.Catalog.WatchKeys()) do seen[key] = ns.ReadOnly.Read(reader, key) end
        return seen
    end
    local function journal(opticalKeys)
        local result = V.Copy(db.journal)
        for key in pairs(result.entries) do if key ~= "Brightness" then return nil end end
        result.entries.Contrast = V.Copy(db.experiments.journal.entries.Contrast)
        for _, key in ipairs(ns.Optics.Keys) do
            local entry = V.Copy(db.experiments.journal.entries[key])
            if entry and (not opticalKeys or opticalKeys[key]) then entry.layer = "visual"; result.entries[key] = entry end
        end
        result.nextEpoch = math.max(result.nextEpoch, db.experiments.journal.nextEpoch)
        return result
    end
    local function persist(value, opticalKeys)
        db.journal.entries.Brightness = V.Copy(value.entries.Brightness)
        db.experiments.journal.entries.Contrast = V.Copy(value.entries.Contrast)
        for _, key in ipairs(ns.Optics.Keys) do
            local entry = V.Copy(value.entries[key])
            if entry then entry.layer = "quality" end
            if not opticalKeys or opticalKeys[key] then db.experiments.journal.entries[key] = entry end
        end
        db.journal.nextEpoch = math.max(db.journal.nextEpoch, value.nextEpoch)
        db.experiments.journal.nextEpoch = math.max(db.experiments.journal.nextEpoch, value.nextEpoch)
        runtime.engine.SyncVisual(); runtime.lab.SyncVisual()
    end
    local function matches(expected, seen, keys)
        for key in pairs(keys) do
            if not ns.Planner.SafeObservation(seen[key]) or seen[key].raw ~= expected[key].raw then return false end
        end
        return true
    end
    local function foreignChanged(before, after, keys)
        for key, item in pairs(before) do
            if not keys[key] and item.code == "OK" and (not after[key] or after[key].code ~= "OK" or item.raw ~= after[key].raw) then return true end
        end
        return false
    end
    local function apply(targets, callback, restoring, options)
        options = options or {}
        local ready, why = gate(); if not ready then return nil, why end
        if type(targets) ~= "table" then return nil, "INVALID_MODE_TARGETS" end
        for key in pairs(targets) do
            if key ~= "Brightness" and key ~= "Contrast" and not ns.Optics.Known(key) then return nil, "INVALID_MODE_TARGETS" end
        end
        if not ns.Optics.Validate(db.optics) then return nil, "INVALID_OPTICAL_STATE" end
        if db.optics.comparison and not options.comparison and not restoring then return nil, "FINISH_COMPARISON" end
        local visualIntent, opticalKeys = ns.Optics.Extract(targets), {}
        local reference = restoring and {} or ns.Modes.Reference(runtime)
        for _, key in ipairs(ns.Optics.Keys) do
            if options.comparison then opticalKeys[key] = targets[key] ~= nil or nil
            elseif restoring or targets[key] ~= nil or db.optics.visual[key] ~= nil
                or reference[key] ~= nil or db.optics.reference[key] ~= nil then opticalKeys[key] = true end
        end
        if not restoring and not options.comparison then
            local effective, reason = ns.Optics.Resolve(visualIntent, db.optics.quality, reference)
            if not effective then return nil, reason end
            targets = V.Copy(targets)
            for key, value in pairs(effective) do if opticalKeys[key] then targets[key] = value end end
            for key in pairs(opticalKeys) do
                local entry = db.experiments.journal.entries[key]
                if visualIntent[key] == nil and db.optics.quality[key] == nil and entry
                    and V.Number(entry.originalRaw) == reference[key] then targets[key] = nil end
            end
        end
        local prior, before = journal(opticalKeys), observe()
        if not prior then return nil, "OTHER_RECOVERY_RECORDS_PRESENT" end
        for key, raw in pairs(options.expected or {}) do
            if not ns.Planner.SafeObservation(before[key]) or before[key].raw ~= raw then return nil, "COMPARISON_CHANGED_EXTERNALLY" end
        end
        local descriptors = ns.Catalog.BrightnessExperiment(signature)
        local context = { signature = signature, testOnly = true, experiment = "VISUAL_MODE" }
        if restoring then
            context.explicitRecovery = true
            for key, entry in pairs(prior.entries) do
                if not ns.Planner.SafeObservation(before[key]) then return nil, "UNSAFE_RECOVERY_OBSERVATION" end
                entry.lastVerifiedRaw, entry.state, entry.failure = before[key].raw, "owned", nil
            end
        end
        local keys = { Brightness = true }
        if targets.Contrast ~= nil or prior.entries.Contrast then
            keys.Contrast = true
            local bounds, reason = ns.ExperimentPolicy.Bounds("Contrast", prior.entries.Contrast and prior.entries.Contrast.originalRaw or before.Contrast.raw)
            if not bounds then return nil, reason end
            descriptors.Contrast = ns.ExperimentPolicy.Descriptor("Contrast", bounds, signature)
            if targets.Contrast ~= nil and not options.comparison
                and (not V.Finite(targets.Contrast) or targets.Contrast % bounds.step ~= 0) then return nil, "INVALID_TEST_STEP:Contrast" end
        end
        for _, key in ipairs(ns.Optics.Keys) do
            if targets[key] ~= nil or prior.entries[key] then
                keys[key] = true
                local entry = prior.entries[key]
                local bounds, reason = ns.ExperimentPolicy.Bounds(key, entry and entry.originalRaw or before[key].raw)
                if not bounds then return nil, reason end
                local value = visualIntent[key]
                if value ~= nil and not options.comparison
                    and math.abs(value / bounds.step - math.floor(value / bounds.step + 0.5)) > 0.000001 then return nil, "INVALID_TEST_STEP:" .. key end
                descriptors[key] = ns.ExperimentPolicy.Descriptor(key, bounds, signature)
                descriptors[key].layer = "visual" -- temporary planner view; canonical record stays quality
            end
        end
        local plan, reason = ns.Planner.Build(descriptors, context, before, prior, "visual", targets)
        if not plan then return nil, reason end
        -- A no-setter release needs a safe observation, not renderer write support.
        for _, op in ipairs(plan.operations) do
            if op.write then
                local capable, code = ns.ExperimentPolicy.Capability(reader, op.key)
                if not capable then return nil, code end
            end
        end
        if options.rawTargets then
            if not ns.Optics.RawMap(options.rawTargets) then return nil, "INVALID_COMPARISON" end
            for _, op in ipairs(plan.operations) do
                local raw = options.rawTargets[op.key]
                if raw then
                    if V.Number(raw) ~= targets[op.key] then return nil, "INVALID_COMPARISON" end
                    op.targetRaw = raw
                end
            end
        end
        if not ns.Planner.SafeObservation(before.Brightness) then return nil, "BRIGHTNESS_UNAVAILABLE_OR_RESTRICTED" end
        self.serial = self.serial + 1
        local tx, code = R.Begin(prior, plan, self.serial, next(prior.entries) and "ACTIVE" or "BASELINE")
        if not tx then return nil, code end
        self.busy, self.state, self.error = true, "APPLYING", nil
        local held, expected = V.Copy(tx.journal), V.Copy(before)
        persist(held, opticalKeys) -- all originals exist before any setter
        local finished = false
        local function finish(ok, errorCode, restored)
            if finished then return end
            finished, cancel = true, nil
            self.busy, self.state, self.error = false, ok and "VERIFIED" or restored and "COMPENSATED" or "PARTIAL", errorCode
            ns.Log.Record(reader, "visual", "transaction", ok and "INFO" or "WARN", errorCode or "PASS", { state = self.state, tx = self.serial })
            if ok and not options.comparison then
                db.optics.visual = restoring and {} or V.Copy(visualIntent)
                db.optics.reference = V.Copy(reference)
                if restoring then db.optics.quality, db.optics.comparison = {}, nil end
            end
            if callback then callback(ok, errorCode, restored) end
        end
        local function fail(errorCode)
            for _, entry in pairs(held.entries) do entry.state, entry.failure = "failed", errorCode end
            persist(held, opticalKeys); finish(false, errorCode)
        end
        cancel = fail
        local function write(key, raw, current)
            local allowed, errorCode = gate(); if not allowed then return false, nil, errorCode end
            local seen = observe()
            if not matches(current, seen, keys) or foreignChanged(before, seen, keys) then return false, seen[key], "EXTERNAL_CONFLICT" end
            local capable, capabilityError = ns.ExperimentPolicy.Capability(reader, key)
            if not capable then return false, seen[key], capabilityError end
            if not ns.Catalog.Admitted(descriptors[key], context) or combat() then return false, seen[key], "COMBAT_OR_RESTRICTION" end
            local result, errorCode = nativeSet(reader, key, raw)
            local after = ns.ReadOnly.Read(reader, key)
            return result and result.n == 1 and result[1] == true and ns.Planner.SafeObservation(after), after, errorCode or "SETTER_OR_READBACK_FAILED"
        end
        local failure
        for index, op in ipairs(plan.operations) do
            local seen = observe()
            if not matches(expected, seen, keys) or foreignChanged(before, seen, keys) then
                fail("EXTERNAL_CONFLICT"); return nil, self.error
            end
            if op.write then
                tx = assert(R.Before(tx, tx.id, index, seen[op.key], combat()))
                if tx.state ~= "APPLYING" then failure = tx.reason; break end
                local ok, after, errorCode = write(op.key, op.targetRaw, expected)
                tx = assert(R.Observe(tx, tx.id, index, ok, after and after.raw))
                if after then expected[op.key] = after end
                if tx.state == "ROLLING_BACK" then failure = errorCode; break end
            else
                tx = assert(R.ReleaseObserved(tx, tx.id, index, seen[op.key], combat()))
                if tx.state ~= "APPLYING" and tx.state ~= "AWAITING_VERIFICATION" then failure = tx.reason; break end
            end
        end
        local finalJournal, immediate = nil, observe()
        if foreignChanged(before, immediate, keys) then fail("DEPENDENCY_OR_EXTERNAL_CHANGE"); return nil, self.error end
        if failure then
            if restoring then fail("RECOVERY_WRITE_FAILED"); return nil, self.error end
            local rollback = assert(R.RollbackPlan(tx, immediate))
            for _, op in ipairs(rollback.rollback) do
                local seen = observe()
                if not matches(expected, seen, keys) then fail("EXTERNAL_CONFLICT"); return nil, self.error end
                rollback = assert(R.BeforeRollback(rollback, rollback.id, op.key, seen[op.key], combat()))
                if rollback.pendingRollback then
                    local ok, after = write(op.key, op.targetRaw, expected)
                    rollback = assert(R.ResolveRollback(rollback, rollback.id, op.key, ok, after and after.raw))
                    if after then expected[op.key] = after end
                end
            end
            rollback = assert(R.FinishRollback(rollback))
            -- Even an immediately restored member keeps its original until the
            -- whole outcome gets a separate read. Partial rollback is not verified.
            if rollback.state == "PARTIAL_ERROR" then fail("COMPENSATION_FAILED"); return nil, self.error end
            finalJournal, expected = rollback.journal, before
        end
        self.state = "AWAITING_VERIFICATION"
        local function verify()
            if finished then return end
            -- Do not overwrite a journal changed by recovery or another operation.
            local currentJournal = journal(opticalKeys)
            for key in pairs(keys) do
                local a, b = held.entries[key], currentJournal and currentJournal.entries[key]
                if (a == nil) ~= (b == nil) then finish(false, "RECOVERY_DATA_CHANGED"); return end
                for field, value in pairs(a or {}) do if not b or b[field] ~= value then finish(false, "RECOVERY_DATA_CHANGED"); return end end
            end
            local allowed, reason = gate(); if not allowed then fail(reason); return end
            local seen = observe()
            if not matches(expected, seen, keys) or foreignChanged(before, seen, keys) then fail("LATE_DRIFT_OR_RESTRICTION"); return end
            if not finalJournal then
                local verified = assert(R.Verify(tx, tx.id, seen))
                if verified.state ~= "VERIFIED" then fail("LATE_DRIFT_OR_RESTRICTION"); return end
                finalJournal = verified.journal
            end
            persist(finalJournal, opticalKeys); finish(not failure, failure, failure ~= nil)
        end
        local scheduled = pcall(reader.env.C_Timer.After, 0.15, function()
            executing = true
            local ok = pcall(verify)
            executing = false
            if not ok then fail("VISUAL_HANDLER_ERROR") end
        end)
        if not scheduled then fail("FOLLOWUP_TIMER_FAILED"); return nil, self.error end
        return true
    end
    local function request(targets, callback, restoring, options)
        if self.busy or executing or comparing and not (options and options.comparison) then return nil, "BUSY" end
        executing = true
        local ok, result, why = pcall(apply, targets, callback, restoring, options)
        executing = false
        if not ok then
            self.busy, self.state, self.error = false, "PARTIAL", "VISUAL_HANDLER_ERROR"
            if callback then callback(false, self.error) end
            return nil, self.error
        end
        return result, why
    end
    function self.Apply(targets, callback) return request(targets, callback, false) end
    function self.Restore(callback) return request({}, callback, true) end
    function self.Cancel()
        if executing then return nil, "BUSY" end
        if cancel then cancel("CANCELLED_WITH_RECOVERY") end
        return true
    end
    local function comparisonMatches(c)
        for key, raw in pairs(c.expected) do
            local item = ns.ReadOnly.Read(reader, key)
            if not ns.Planner.SafeObservation(item) or item.raw ~= raw then return false end
        end
        return true
    end
    function self.ObserveComparison()
        local c = db and db.optics.comparison
        if c and not self.busy and c.state ~= "pending" and not comparisonMatches(c) then c.state = "recovery" end
        return c and c.state
    end
    local function compare(side, done, ending)
        if self.busy or executing then return nil, "BUSY" end
        if not db then return nil, "INVALID_OPTICAL_STATE" end
        local c = db.optics.comparison
        local created = false
        if not c then
            if side ~= "before" or ending then return nil, "NO_COMPARISON" end
            c = { before = {}, after = {}, expected = {}, state = "after" }
            local keys = { Brightness = true, Contrast = true }
            for key in pairs(db.optics.visual) do keys[key] = true end
            for key in pairs(keys) do
                local item = ns.ReadOnly.Read(reader, key)
                if not ns.Planner.SafeObservation(item) then
                    if key ~= "Contrast" then return nil, "COMPARISON_VALUE_UNAVAILABLE:" .. key end
                else
                    local entry = key == "Brightness" and db.journal.entries[key] or db.experiments.journal.entries[key]
                    local original = entry and entry.originalRaw or item.raw
                    local home = db.baseline.chosen and db.baseline.values[key]
                    if ns.Optics.Known(key) and db.optics.quality[key] ~= nil then home = tostring(db.optics.quality[key]) end
                    c.before[key], c.after[key], c.expected[key] = home or original, item.raw, item.raw
                end
            end
            created = true
        end
        if not ns.Optics.RawMap(c.before) or not ns.Optics.RawMap(c.after) then return nil, "INVALID_COMPARISON" end
        if c.state == "pending" or c.state == "recovery" or not comparisonMatches(c) then
            c.state = "recovery"
            if ending then db.optics.comparison = nil else db.optics.comparison = c end
            if done then done(false, "COMPARISON_CHANGED_EXTERNALLY") end
            return nil, "COMPARISON_CHANGED_EXTERNALLY"
        end
        if ending and c.state == "after" then db.optics.comparison = nil; if done then done(true) end; return true end
        local targets, priorState = {}, c.state
        for key, raw in pairs(c[side]) do targets[key] = assert(V.Number(raw)) end
        local expected = V.Copy(c.expected)
        c.state, db.optics.comparison = "pending", c -- retained before the first possible write
        local completed = false
        local ok, why = request(targets, function(success, code, compensated)
            completed = true
            if success then
                c.state = side
                for key in pairs(c.expected) do
                    local item = ns.ReadOnly.Read(reader, key)
                    if not ns.Planner.SafeObservation(item) or item.raw ~= c[side][key] then
                        c.state = "recovery"; success, code = false, "COMPARISON_CHANGED_EXTERNALLY"; break
                    end
                    c.expected[key] = item.raw
                end
                if ending and success then db.optics.comparison = nil end
            elseif compensated then c.state = priorState; if created then db.optics.comparison = nil end
            else c.state = "recovery" end
            if done then done(success, code, compensated) end
        end, false, { comparison = true, rawTargets = c[side], expected = expected })
        if not ok and not completed then
            c.state = priorState
            if created then db.optics.comparison = nil end
        end
        return ok, why
    end
    local function compareRequest(side, done, ending)
        if self.busy or executing or comparing then return nil, "BUSY" end
        comparing = true
        local ok, result, why = pcall(compare, side, done, ending)
        comparing = false
        if not ok then
            if db and db.optics.comparison then db.optics.comparison.state = "recovery" end
            return nil, "COMPARISON_HANDLER_ERROR"
        end
        return result, why
    end
    function self.Compare(side, done)
        if side ~= "before" and side ~= "after" then return nil, "INVALID_COMPARISON" end
        return compareRequest(side, done, false)
    end
    function self.EndComparison(done) return compareRequest("after", done, true) end
    return self
end

function B.New(reader, db, emit)
    local sessionSignature = ns.Compatibility.Inspect(reader).signature
    local state = db and not next(db.journal.entries) and "BASELINE" or "RECOVERY"
    local busy, proposal, transaction, sessionOwned = false, nil, nil, false
    local serial, operation, lastError, dirty = 0, "none", nil, false
    local engine = {}

    local function say(line)
        local ok, shown = pcall(emit, "LumenShift: " .. line)
        return ok and shown == true
    end

    local function read() return ns.ReadOnly.Read(reader, "Brightness") end

    local function sameJournal(left, right)
        if not ns.Store.ValidateJournal(left) or not ns.Store.ValidateJournal(right)
            or left.nextEpoch ~= right.nextEpoch then return false end
        for key, record in pairs(left.entries) do
            local other = right.entries[key]
            if not other then return false end
            for field, value in pairs(record) do if other[field] ~= value then return false end end
            for field, value in pairs(other) do if record[field] ~= value then return false end end
        end
        for key in pairs(right.entries) do if not left.entries[key] then return false end end
        return true
    end

    local function combat()
        local values = ns.ReadOnly.Call(reader, reader.env.InCombatLockdown)
        return not values or values.n ~= 1 or values[1] ~= false
    end

    local function eligible()
        if db and db.optics and db.optics.comparison then return nil, "FINISH_COMPARISON" end
        if reader.visualBusy and reader.visualBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if not db then return nil, "SAVED_DATA_QUARANTINED" end
        if not ns.Store.ValidateJournal(db.journal) then return nil, "INVALID_JOURNAL" end
        for key in pairs(db.journal.entries) do
            if key ~= "Brightness" then return nil, "OTHER_RECOVERY_RECORDS_PRESENT" end
        end
        local identity = ns.Compatibility.Inspect(reader)
        local catalog, context = ns.Catalog.BrightnessExperiment(identity.signature)
        if not catalog then return nil, "IDENTITY_UNAVAILABLE" end
        if identity.signature ~= sessionSignature then return nil, "SESSION_BUILD_CHANGED" end
        if not setterAvailable(reader) then return nil, "SETTER_UNAVAILABLE" end
        if reader.tierOccupied and reader.tierOccupied() then return nil, "QUALITY_TRIAL_RECOVERY_REQUIRED" end
        if reader.nameBusy and reader.nameBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if reader.experimentBusy and reader.experimentBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if reader.graphicsBusy and reader.graphicsBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if combat() then return nil, "COMBAT_OR_RESTRICTION" end
        return catalog, context
    end

    local function mark(reason, conflict)
        ns.Log.Record(reader, "brightness", "state", "WARN", reason or "RECOVERY", { key = "Brightness", state = conflict and "CONFLICT" or "RECOVERY" })
        local record = db and db.journal.entries.Brightness
        if record then record.state, record.failure = conflict and "conflict" or "failed", reason end
        state, lastError, sessionOwned = conflict and "CONFLICT" or "RECOVERY", reason, false
        proposal, transaction = nil, nil
    end

    -- The single native graphics-writing call site. Every path, including compensation,
    -- rechecks identity, flags, combat and the exact freshly observed expected value.
    local function write(expected, target)
        local catalog, reason = eligible()
        if not catalog then return false, nil, reason, false end
        local current = read()
        local number = V.Number(target)
        if not ns.Planner.SafeObservation(current) or current.raw ~= expected then
            return false, current, "EXTERNAL_CONFLICT", false
        end
        if not number or number < 0 or number > 100 then return false, current, "INVALID_TARGET", false end
        -- Combat can enter during getter calls. Check again at the last possible boundary.
        if combat() then return false, current, "COMBAT_OR_RESTRICTION", false end
        ns.Log.Record(reader, "brightness", "write", "INFO", "ATTEMPT", { key = "Brightness", before = expected, requested = target,
            original = db.journal.entries.Brightness and db.journal.entries.Brightness.originalRaw })
        local result, code = nativeSet(reader, "Brightness", target)
        local after = read() -- even an errored setter might have changed the value
        ns.Log.Record(reader, "brightness", "immediate", "INFO", after.code, { key = "Brightness", immediate = after.raw })
        local success = result and result.n == 1 and result[1] == true
        if not success and not code then code = "SETTER_REJECTED" end
        return success == true, after, code, true
    end

    local function keepPending(tx)
        -- Retain the recovery original until the separate final verification, even for release.
        local op = tx.plan.operations[1]
        local journal = V.Copy(tx.journal)
        if not journal.entries.Brightness then
            journal.entries.Brightness = {
                originalRaw = op.originalRaw, lastVerifiedRaw = op.beforeRaw, intendedRaw = op.targetRaw,
                layer = "visual", epoch = op.epoch, state = "pending", descriptorVersion = op.descriptorVersion,
                signature = op.signature,
            }
        else journal.entries.Brightness.state = "pending" end
        db.journal = journal
    end

    local function failTransaction(tx, observed, recoveryAction, reason)
        -- Recovery/conflict/reload requests never auto-reapply their uncertain before-value.
        if recoveryAction then mark(reason or "RECOVERY_WRITE_FAILED", false); return end
        local held = V.Copy(db.journal)
        local rollback, code = R.RollbackPlan(tx, { Brightness = observed })
        if not rollback then mark(code or "ROLLBACK_MODEL_FAILED", false); return end
        db.journal = V.Copy(rollback.journal)
        for _, op in ipairs(rollback.rollback) do
            local checked = R.BeforeRollback(rollback, rollback.id, op.key, read(), combat())
            if not checked then mark("ROLLBACK_PREFLIGHT_FAILED", false); return end
            rollback = checked
            if rollback.pendingRollback then
                local ok, after = write(op.expectedRaw, op.targetRaw)
                rollback = R.ResolveRollback(rollback, rollback.id, op.key,
                    ok and ns.Planner.SafeObservation(after), after and after.raw)
                if not rollback then mark("ROLLBACK_MODEL_FAILED", false); return end
            end
        end
        rollback = R.FinishRollback(rollback)
        if not rollback then mark("ROLLBACK_MODEL_FAILED", false); return end
        db.journal = V.Copy(rollback.journal)
        state, lastError = rollback.state, reason or "OPERATION_FAILED"
        sessionOwned = false
        transaction = nil
        if state == "BASELINE" or state == "ACTIVE" then
            -- Immediate compensation is not a measured settled result. Keep the original
            -- until a separate user-triggered read verifies the transaction before-value.
            local expected = tx.plan.operations[1].beforeRaw
            db.journal = held
            db.journal.entries.Brightness.state = "pending"
            db.journal.entries.Brightness.lastVerifiedRaw = expected
            transaction = { id = tx.id, compensation = true, expected = expected, finalJournal = rollback.journal,
                failure = lastError, held = V.Copy(db.journal) }
            state = "AWAITING_VERIFICATION"
        end
        say("Operation failed: " .. lastError .. "; compensation state " .. state .. ". Open Diagnostic Center.")
    end

    local function prepare(action, target, ordinary)
        proposal = nil -- a new explicit request always expires the previous preview
        if action ~= "on" and action ~= "off" and action ~= "restore" then return nil, "UNKNOWN_ACTION" end
        local catalog, context = eligible()
        if not catalog then return nil, context end
        local current = read()
        if not ns.Planner.SafeObservation(current) then return nil, "UNSAFE_OBSERVATION" end
        local journal = V.Copy(db.journal)
        local record = journal.entries.Brightness
        local continuing = ordinary and state == "RECOVERY" and not transaction
            and R.CanContinue(record, current, context.signature)
        local recoveryAction = action == "restore" and (not sessionOwned or transaction ~= nil or state ~= "ACTIVE"
            or record and (record.state ~= "owned" or record.lastVerifiedRaw ~= current.raw))
        if action == "on" and state ~= "BASELINE" and state ~= "ACTIVE" and not continuing then return nil, "RECOVERY_REQUIRED" end
        if action == "off" and (not sessionOwned or state ~= "ACTIVE") and not continuing then return nil, "USE_EXPLICIT_RESTORE" end
        if action ~= "on" and not record then return nil, "NO_CAPTURED_ORIGINAL" end
        if record then
            if not ns.Compatibility.Experimental(record.signature) or record.descriptorVersion ~= 1 or record.layer ~= "visual" then
                return nil, "RECOVERY_DESCRIPTOR_MISMATCH"
            end
            if record.signature ~= context.signature and action ~= "restore" then return nil, "USE_EXPLICIT_RESTORE" end
            if action == "restore" then
                -- Explicit restore previews a reconciliation. Never silently replace originalRaw.
                record.lastVerifiedRaw, record.state, record.failure = current.raw, "owned", nil
            elseif record.state ~= "owned" or record.lastVerifiedRaw ~= current.raw then
                mark("EXTERNAL_CONFLICT", true); return nil, "EXTERNAL_CONFLICT"
            end
        end
        target = target == nil and 75 or target
        local targets = action == "on" and { Brightness = target } or {}
        if action == "restore" then context.explicitRecovery = true end
        local plan, code = ns.Planner.Build(catalog, context, { Brightness = current }, journal, "visual", targets)
        if not plan then return nil, code end
        if #plan.operations == 0 then
            if continuing then
                -- Explicit selection of an already-matching target: no setter.
                state, sessionOwned, lastError = "ACTIVE", true, nil
                ns.Log.Record(reader, "brightness", "continue", "INFO", "MATCHING_SAVED_VALUE_NO_WRITE", { key = "Brightness" })
            end
            return nil, "ALREADY_AT_TARGET_NO_OWNERSHIP_CHANGE"
        end
        if #plan.operations ~= 1 or plan.operations[1].key ~= "Brightness" then return nil, "TEST_PLAN_EXCLUDED" end
        serial = serial + 1
        local op = plan.operations[1]
        local shown = true
        if ordinary then
            ns.Log.Record(reader, "brightness", "prepare", "INFO", "USER_MODE_SELECTION", { key = "Brightness",
                original = op.originalRaw, before = op.beforeRaw, requested = op.targetRaw })
        else
            shown = say("RECOVERY CARD " .. serial .. " | " .. context.signature
                .. " | Brightness original=" .. op.originalRaw .. " current=" .. op.beforeRaw .. " target=" .. op.targetRaw)
            shown = say("No write yet. You can export these values from Diagnostic Center.") and shown
            if recoveryAction then
                shown = say("Recovery replaces the current value with your saved original.") and shown
            end
            shown = say("Review the values, then use Confirm displayed recovery card " .. serial .. " in Diagnostic Center.") and shown
        end
        if not shown then return nil, "RECOVERY_CARD_NOT_DISPLAYED" end
        proposal = { token = tostring(serial), plan = plan, journal = journal, sourceJournal = V.Copy(db.journal),
            action = action, target = target, ordinary = ordinary, recoveryAction = recoveryAction,
            priorState = (sessionOwned or continuing) and "ACTIVE" or "BASELINE" }
        operation = "PREVIEW_" .. action
        return true
    end

    local function confirm(token)
        local pending = proposal
        proposal = nil -- consume even on refusal; never retry an old token
        if not pending or token ~= pending.token then return nil, "NO_MATCHING_PREVIEW" end
        local catalog, code = eligible()
        if not catalog then return nil, code end
        if not sameJournal(db.journal, pending.sourceJournal) then return nil, "RECOVERY_DATA_CHANGED" end
        -- Replan from the displayed snapshot and fresh reads; no stale plan bypass.
        local current = read()
        local op = pending.plan.operations[1]
        if not ns.Planner.SafeObservation(current) or current.raw ~= op.beforeRaw then
            if db.journal.entries.Brightness then mark("EXTERNAL_CONFLICT", true) end
            return nil, "PREVIEW_CHANGED"
        end
        local targets = pending.action == "on" and { Brightness = pending.target } or {}
        local _, context = ns.Catalog.BrightnessExperiment(pending.plan.signature)
        if pending.action == "restore" then context.explicitRecovery = true end
        local fresh, why = ns.Planner.Build(catalog, context, { Brightness = current }, pending.journal, "visual", targets)
        if not fresh or #fresh.operations ~= 1 or fresh.operations[1].targetRaw ~= op.targetRaw then
            return nil, why or "PREVIEW_CHANGED"
        end
        local tx, errorCode = R.Begin(pending.journal, fresh, serial, pending.priorState)
        if not tx then return nil, errorCode end
        operation = pending.action
        if op.write then tx, errorCode = R.Before(tx, tx.id, 1, read(), combat())
        else tx, errorCode = R.ReleaseObserved(tx, tx.id, 1, read(), combat()) end
        if not tx then return nil, errorCode end
        if tx.state == "DEFERRED" or tx.state == "ROLLING_BACK" then
            if db.journal.entries.Brightness then mark(tx.reason or "PREFLIGHT_FAILED", true) end
            return nil, tx.reason or "PREFLIGHT_FAILED"
        end
        keepPending(tx) -- original is held in memory before the first possible native mutation
        if op.write then
            local ok, after, reason, attempted = write(op.beforeRaw, op.targetRaw)
            if not attempted then
                mark(reason or "WRITE_PREFLIGHT_FAILED", true); return nil, reason
            end
            tx, errorCode = R.Observe(tx, tx.id, 1, ok and ns.Planner.SafeObservation(after), after and after.raw)
            if not tx then mark(errorCode or "RESULT_MODEL_FAILED", false); return nil, errorCode end
            if tx.state == "ROLLING_BACK" then
                failTransaction(tx, after, pending.recoveryAction, reason or "READBACK_MISMATCH")
                return nil, reason or "READBACK_MISMATCH"
            end
        end
        keepPending(tx)
        transaction = { id = tx.id, model = tx, action = pending.action, recoveryAction = pending.recoveryAction,
            held = V.Copy(db.journal), ordinary = pending.ordinary }
        state = "AWAITING_VERIFICATION"
        if not pending.ordinary then
            say("Immediate readback matched. Click Verify pending recovery in Diagnostic Center. Original=" .. op.originalRaw)
        end
        return true
    end

    local function verify()
        proposal = nil -- verification changes ownership; any older preview must expire
        if not transaction then return nil, "NO_PENDING_VERIFICATION" end
        local catalog, reason = eligible()
        if not catalog then mark(reason, false); return nil, reason end
        if not sameJournal(db.journal, transaction.held) then
            mark("RECOVERY_DATA_CHANGED", false); return nil, "RECOVERY_DATA_CHANGED"
        end
        if transaction.compensation then
            local current = read()
            ns.Log.Record(reader, "brightness", "compensation-followup", "INFO", current.code, { key = "Brightness", followup = current.raw })
            if not ns.Planner.SafeObservation(current) or current.raw ~= transaction.expected then
                mark("COMPENSATION_LATE_DRIFT", true); return nil, "COMPENSATION_LATE_DRIFT"
            end
            db.journal = V.Copy(transaction.finalJournal)
            lastError = transaction.failure
            sessionOwned = db.journal.entries.Brightness ~= nil
            state, transaction, dirty = sessionOwned and "ACTIVE" or "BASELINE", nil, false
            say("The operation failed; its before-value is now verified. Original recovery data was retained until this check.")
            return true
        end
        local observed = read()
        ns.Log.Record(reader, "brightness", "followup", "INFO", observed.code, { key = "Brightness", followup = observed.raw })
        local checked, code = R.Verify(transaction.model, transaction.model.id, { Brightness = observed })
        if not checked then mark(code, false); return nil, code end
        if checked.state ~= "VERIFIED" then
            -- A delayed mismatch could be an external change. Never automatically fight it.
            mark("LATE_DRIFT_OR_RESTRICTION", true); return nil, "LATE_DRIFT_OR_RESTRICTION"
        end
        db.journal = V.Copy(checked.journal)
        sessionOwned = db.journal.entries.Brightness ~= nil
        state, lastError = sessionOwned and "ACTIVE" or "BASELINE", nil
        ns.Log.Record(reader, "brightness", "verified", "INFO", state, { key = "Brightness", after = observed.raw, state = state })
        if not transaction.ordinary then
            say(sessionOwned and "Brightness target verified by readback. Use Diagnostic Center to restore your pre-change Brightness."
                or "Original Brightness verified by exact readback; ownership released.")
        end
        transaction, dirty = nil, false
        return true
    end

    local function guarded(fn, quiet, ...)
        if busy then return nil, "BUSY" end
        busy = true
        local ok, result, code = pcall(fn, ...)
        busy = false
        if not ok then
            mark("ENGINE_ERROR", false)
            say("Engine error; writes locked. Preserve the recovery card and open Diagnostic Center.")
            return nil, "ENGINE_ERROR"
        end
        if not result then
            lastError = code
            ns.Log.Record(reader, "brightness", "refusal", "WARN", code or "UNKNOWN", { key = "Brightness" })
            if not quiet then say("Refused/failed: " .. (code or "UNKNOWN") .. ". No automatic retry.") end
        end
        return result, code
    end

    function engine.Prepare(action) return guarded(prepare, false, action) end
    function engine.CanContinue()
        local catalog, context = eligible()
        if not catalog or state ~= "RECOVERY" or transaction then return false end
        local entry = db.journal.entries.Brightness
        return entry and entry.descriptorVersion == 1 and entry.layer == "visual"
            and R.CanContinue(entry, read(), context.signature) or false
    end
    function engine.Switch(target)
        return guarded(function()
            if not db or not ns.Profiles.Validate(db.config) or db.config.studio.enabled ~= true then return nil, "SETUP_REQUIRED" end
            if target ~= nil and (not V.Finite(target) or target < 0 or target > 100) then return nil, "INVALID_TARGET" end
            if target == nil and state == "BASELINE" and not next(db.journal.entries) then return true, "NO_CHANGE" end
            local ok, code = prepare(target == nil and "off" or "on", target, true)
            if not ok then
                if code == "ALREADY_AT_TARGET_NO_OWNERSHIP_CHANGE" then return true, "NO_CHANGE" end
                return nil, code
            end
            return confirm(proposal.token)
        end, true)
    end
    function engine.Confirm(token) return guarded(confirm, false, token) end
    function engine.Verify() return guarded(verify, transaction and transaction.ordinary == true) end
    function engine.Cancel()
        if busy then return nil, "BUSY" end
        proposal = nil
        -- Cancel revokes permission; it is not a hidden restore or loss of a pending journal.
        if transaction then mark("CANCELLED_WITH_RECOVERY", false) end
        operation = "none"
        return true
    end
    function engine.Notify() dirty = true end -- synchronous notifications never recurse into writes
    reader.brightnessBusy = function() return busy or reader.visualBusy and reader.visualBusy() end
    reader.brightnessExecuting = function() return busy end
    -- Reconcile the legacy diagnostic engine after the composite boundary updated its journal.
    function engine.SyncVisual()
        proposal, transaction = nil, nil
        local entry = db and db.journal.entries.Brightness
        sessionOwned = entry and entry.state == "owned" or false
        state = not entry and "BASELINE" or sessionOwned and "ACTIVE" or entry.state == "conflict" and "CONFLICT" or "RECOVERY"
        lastError = entry and entry.failure
    end
    function engine.Status()
        if not busy and sessionOwned and state == "ACTIVE" and not (proposal and proposal.recoveryAction) then
            local current = read()
            if not ns.Planner.SafeObservation(current) or current.raw ~= db.journal.entries.Brightness.lastVerifiedRaw then
                mark("EXTERNAL_CONFLICT", true)
            end
        end
        local record = db and db.journal.entries.Brightness
        local preview = proposal and proposal.plan.operations[1]
        return { state = state, operation = operation, original = record and record.originalRaw,
            lastVerified = record and record.lastVerifiedRaw, token = proposal and proposal.token,
            error = lastError, notificationsPending = dirty, writeEnabled = false, setterAvailable = setterAvailable(reader),
            transactionID = transaction and transaction.id,
            preview = preview and { original = preview.originalRaw, current = preview.beforeRaw, target = preview.targetRaw } }
    end
    return engine
end

-- Explicit leaf calibration and experimental profiles. Separate journal, disjoint
-- keys from the preserved Brightness engine; the native setter above is shared, never exposed.
function B.NewExperiments(runtime, cameraMode)
    local reader, db = runtime.reader, runtime.db
    local sessionSignature = ns.Compatibility.Inspect(reader).signature
    local data = db and (cameraMode == "framing" and db.camera.framing or cameraMode and db.camera or db.experiments)
    local policy = cameraMode == "framing" and ns.Framing or cameraMode and ns.NamePolicy or ns.ExperimentPolicy
    local function watchKeys() return cameraMode and policy.Keys or ns.Catalog.WatchKeys() end
    local lab = { state = data and not next(data.journal.entries) and "BASELINE" or "RECOVERY",
        busy = false, certificates = {}, preview = nil, serial = 0, lastError = nil, activeProfile = "currentBaseline" }
    local pending, pendingCompletion, executing, owned = nil, nil, false, {}
    local function record(op, level, result, fields) ns.Log.Record(reader, cameraMode and "names" or "experiments", op, level, result, fields) end
    local function refresh() if runtime.product and runtime.product.Refresh then runtime.product.Refresh() end end
    local function mark(code)
        lab.state, lab.lastError, lab.busy, pending, pendingCompletion = "RECOVERY", code, false, nil, nil
        lab.certificates = {}
        if data then for _, item in pairs(data.journal.entries) do item.state, item.failure = "failed", code end end
        owned = {}; record("state", "ERROR", code); refresh()
        return nil, code
    end
    local function combat()
        local result = ns.ReadOnly.Call(reader, reader.env.InCombatLockdown)
        return not result or result.n ~= 1 or result[1] ~= false
    end
    local function gate()
        if cameraMode == "framing" and reader.namesOnlyBusy and reader.namesOnlyBusy()
            or cameraMode ~= "framing" and reader.framingBusy and reader.framingBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if not cameraMode and db and next(db.camera.photo.records) then return nil, "RESTORE_PHOTO_FIRST" end
        if not cameraMode and db and db.optics.comparison then return nil, "FINISH_COMPARISON" end
        if reader.visualBusy and reader.visualBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if reader.graphicsBusy and reader.graphicsBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if (cameraMode and runtime.lab and runtime.lab.busy) or (not cameraMode and runtime.names and runtime.names.busy) then return nil, "OTHER_OPERATION_ACTIVE" end
        if not data or not policy.Validate(data) then return nil, "EXPERIMENT_DATA_QUARANTINED" end
        if reader.tierOccupied and reader.tierOccupied() then return nil, "QUALITY_TRIAL_RECOVERY_REQUIRED" end
        local signature = ns.Compatibility.Inspect(reader).signature
        if not ns.Compatibility.Experimental(signature) then return nil, "IDENTITY_UNAVAILABLE" end
        if signature ~= sessionSignature then return nil, "SESSION_BUILD_CHANGED" end
        if not setterAvailable(reader) then return nil, "SETTER_UNAVAILABLE" end
        if combat() then return nil, "COMBAT_OR_RESTRICTION" end
        if type(reader.env.C_Timer) ~= "table" or type(reader.env.C_Timer.After) ~= "function" then return nil, "FOLLOWUP_TIMER_UNAVAILABLE" end
        if runtime.engine and runtime.engine.Status().state == "AWAITING_VERIFICATION" then return nil, "OTHER_OPERATION_ACTIVE" end
        return true
    end
    local function observe()
        local result = {}
        for _, key in ipairs(watchKeys()) do result[key] = ns.ReadOnly.Read(reader, key) end
        return result
    end
    local function same(a, b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= "table" then return a == b end
        for key, value in pairs(a) do if not same(value, b[key]) then return false end end
        for key in pairs(b) do if a[key] == nil then return false end end
        return true
    end
    local function watch(before, after, allowed)
        local drift = false
        for key, prior in pairs(before) do
            if not allowed[key] and prior.code == "OK" and V.Number(prior.raw) then
                local current = after[key]
                if not current or current.code ~= "OK" or current.raw ~= prior.raw then
                    drift = true
                    if current and V.Number(current.raw) then data.sideEffects[key] = { before = prior.raw, after = current.raw } end
                    record("watched-change", "WARN", "DEPENDENCY_OR_EXTERNAL_CHANGE", { key = key, before = prior.raw,
                        after = current and current.raw, error = current and current.code or "READ_UNAVAILABLE" })
                end
            end
        end
        return drift
    end
    local function catalog(seen, targets, overrides)
        local descriptors = {}
        local keys = {}
        for key in pairs(targets) do keys[key] = true end
        for key in pairs(data.journal.entries) do keys[key] = true end
        for key in pairs(keys) do
            local item = data.journal.entries[key]
            if item and (not ns.Compatibility.Experimental(item.signature) or item.descriptorVersion ~= policy.Version
                or key == "Brightness" or not policy.Known(key)) then return nil, "RECOVERY_DESCRIPTOR_MISMATCH" end
            local bounds, why = policy.Bounds(key, item and item.originalRaw or seen[key] and seen[key].raw, reader)
            if overrides and overrides[key] then bounds = overrides[key] end
            if not bounds then return nil, why end
            descriptors[key] = policy.Descriptor(key, bounds, sessionSignature)
        end
        return descriptors
    end
    local function build(layer, targets, reconciliation, overrides)
        local ready, why = gate(); if not ready then return nil, why end
        local seen = observe()
        local descriptors, code = catalog(seen, targets, overrides); if not descriptors then return nil, code end
        for key in pairs(targets) do
            if policy.Capability then
                local supported, reason = policy.Capability(reader, key)
                if not supported then return nil, reason end
            end
        end
        local journal = V.Copy(data.journal)
        for key, entry in pairs(journal.entries) do
            if entry.layer == layer then
                if reconciliation then
                    if not ns.Planner.SafeObservation(seen[key]) then return nil, "UNSAFE_RECOVERY_OBSERVATION" end
                    entry.lastVerifiedRaw, entry.state, entry.failure = seen[key].raw, "owned", nil
                elseif not owned[key] and not R.CanContinue(entry, seen[key], sessionSignature) then
                    return nil, "EXPLICIT_RECOVERY_REQUIRED"
                end
            end
        end
        local context = policy.Context(sessionSignature)
        if reconciliation then context.explicitRecovery = true end
        local plan, errorCode = ns.Planner.Build(descriptors, context, seen, journal, layer, targets)
        if not plan then return nil, errorCode end
        return { plan = plan, journal = journal, source = V.Copy(data.journal), seen = seen, descriptors = descriptors,
            layer = layer, targets = V.Copy(targets), reconciliation = reconciliation, overrides = overrides }
    end
    local function write(key, expected, target, descriptor)
        local ready, why = gate(); if not ready then return false, nil, why end
        if policy.Capability then
            local supported, reason = policy.Capability(reader, key)
            if not supported then return false, nil, reason end
        end
        local current = ns.ReadOnly.Read(reader, key)
        local number = V.Number(target)
        if cameraMode == "framing" then
            local bounds = ns.Framing.Range(reader)
            if not bounds or not number or number < bounds.min or number > bounds.max then return false, current.raw, "FOV_OUTSIDE_NATIVE_BOUNDS" end
        end
        if not ns.Planner.SafeObservation(current) or current.raw ~= expected then return false, current, "EXTERNAL_CONFLICT" end
        if not ns.Catalog.Admitted(descriptor, policy.Context(sessionSignature))
            or not number or number < descriptor.min or number > descriptor.max then return false, current, "INVALID_EXPERIMENT_TARGET" end
        if combat() then return false, current, "COMBAT_OR_RESTRICTION" end
        record("write", "INFO", "ATTEMPT", { key = key, before = expected, requested = target,
            original = data.journal.entries[key] and data.journal.entries[key].originalRaw })
        local result, code = nativeSet(reader, key, target)
        local after = ns.ReadOnly.Read(reader, key)
        record("immediate", "INFO", after.code, { key = key, immediate = after.raw })
        return result and result.n == 1 and result[1] == true and ns.Planner.SafeObservation(after), after, code or "SETTER_OR_READBACK_FAILED"
    end
    local function hold(tx)
        local held = V.Copy(tx.journal)
        for _, op in ipairs(tx.plan.operations) do
            held.entries[op.key] = held.entries[op.key] or { originalRaw = op.originalRaw,
                lastVerifiedRaw = op.beforeRaw, intendedRaw = op.targetRaw, layer = op.layer, epoch = op.epoch,
                descriptorVersion = op.descriptorVersion, signature = op.signature }
            held.entries[op.key].state = "pending"
        end
        data.journal = held
    end
    local function run(proposal, callback, delay)
        if lab.busy then return nil, "BUSY" end
        if not same(data.journal, proposal.source) then return nil, "RECOVERY_DATA_CHANGED" end
        local fresh, why = build(proposal.layer, proposal.targets, proposal.reconciliation, proposal.overrides)
        if not fresh then return nil, why end
        if not same(fresh.plan, proposal.plan) then return nil, "PREVIEW_CHANGED" end
        -- A changed non-target watch value invalidates the displayed experiment too.
        for key, item in pairs(proposal.seen) do
            if item.code == "OK" and fresh.seen[key].raw ~= item.raw then return nil, "WATCH_SNAPSHOT_CHANGED" end
        end
        lab.serial = lab.serial + 1
        local id, allowed = lab.serial, {}
        local tx, code = R.Begin(fresh.journal, fresh.plan, id, next(fresh.journal.entries) and "ACTIVE" or "BASELINE")
        if not tx then return nil, code end
        for _, op in ipairs(tx.plan.operations) do allowed[op.key] = true end
        lab.busy, lab.state, lab.lastError, lab.preview = true, "APPLYING", nil, nil
        pendingCompletion = callback
        data.journal = V.Copy(tx.journal) -- all originals precede every native call
        local failure, finalJournal, expected
        for i, op in ipairs(tx.plan.operations) do
            if op.write then
                tx = assert(R.Before(tx, id, i, ns.ReadOnly.Read(reader, op.key), combat()))
                if tx.state ~= "APPLYING" then failure = tx.reason; break end
                local ok, after, errorCode = write(op.key, op.beforeRaw, op.targetRaw, fresh.descriptors[op.key])
                tx = assert(R.Observe(tx, id, i, ok, after and after.raw))
                hold(tx)
                if tx.state == "ROLLING_BACK" then failure = errorCode; break end
            else tx = assert(R.ReleaseObserved(tx, id, i, ns.ReadOnly.Read(reader, op.key), combat())); hold(tx) end
            if tx.state == "ROLLING_BACK" or tx.state == "DEFERRED" then failure = tx.reason; break end
        end
        local immediate = observe()
        if watch(fresh.seen, immediate, allowed) then
            mark("DEPENDENCY_OR_EXTERNAL_CHANGE"); if callback then callback(false, lab.lastError) end; return nil, lab.lastError
        end
        if failure then
            for key in pairs(allowed) do lab.certificates[key] = nil end
            if proposal.reconciliation then mark("RECOVERY_WRITE_FAILED"); if callback then callback(false, lab.lastError) end; return nil, lab.lastError end
            -- Bounded compensation of observed attempts, never a reset or a speculative retry.
            local rollback = assert(R.RollbackPlan(tx, immediate))
            for _, op in ipairs(rollback.rollback) do
                rollback = assert(R.BeforeRollback(rollback, id, op.key, ns.ReadOnly.Read(reader, op.key), combat()))
                if rollback.pendingRollback then
                    local ok, after = write(op.key, op.expectedRaw, op.targetRaw, fresh.descriptors[op.key])
                    rollback = assert(R.ResolveRollback(rollback, id, op.key, ok, after and after.raw))
                end
            end
            rollback = assert(R.FinishRollback(rollback))
            if rollback.state == "PARTIAL_ERROR" then
                data.journal = V.Copy(rollback.journal); mark("COMPENSATION_FAILED")
                if callback then callback(false, lab.lastError) end; return nil, lab.lastError
            end
            finalJournal, expected = rollback.journal, {}
            for _, op in ipairs(tx.plan.operations) do expected[op.key] = op.beforeRaw end
            hold(tx); record("rollback", "WARN", "AWAITING_COMPENSATION_READBACK")
        else hold(tx) end
        local held = V.Copy(data.journal)
        pending, lab.state = id, "AWAITING_VERIFICATION"
        local verify = function()
            if pending ~= id then return end
            if not same(data.journal, held) then mark("RECOVERY_DATA_CHANGED"); if callback then callback(false, lab.lastError) end; return end
            local ready, reason = gate()
            if not ready then mark(reason); if callback then callback(false, reason) end; return end
            local seen = observe()
            for key in pairs(allowed) do record("followup", "INFO", seen[key].code, { key = key, followup = seen[key].raw }) end
            if watch(fresh.seen, seen, allowed) then mark("DEPENDENCY_OR_EXTERNAL_CHANGE"); if callback then callback(false, lab.lastError) end; return end
            if finalJournal then
                for key, raw in pairs(expected) do
                    if not ns.Planner.SafeObservation(seen[key]) or seen[key].raw ~= raw then
                        mark("COMPENSATION_LATE_DRIFT"); if callback then callback(false, lab.lastError) end; return
                    end
                end
            else
                local verified = assert(R.Verify(tx, id, seen))
                if verified.state ~= "VERIFIED" then mark("LATE_DRIFT_OR_RESTRICTION"); if callback then callback(false, lab.lastError) end; return end
                finalJournal = verified.journal
            end
            data.journal = V.Copy(finalJournal)
            if not failure and proposal.qualityIntent then db.optics.quality = V.Copy(proposal.qualityIntent) end
            if not failure and proposal.referenceIntent then db.optics.reference = V.Copy(proposal.referenceIntent) end
            for key in pairs(allowed) do owned[key] = data.journal.entries[key] ~= nil end
            for key, entry in pairs(data.journal.entries) do
                if entry.layer == proposal.layer and R.CanContinue(entry, seen[key], sessionSignature) then owned[key] = true end
            end
            lab.busy, pending, pendingCompletion, lab.lastError = false, nil, nil, failure
            lab.state = next(data.journal.entries) and "ACTIVE" or "BASELINE"
            record("verification", failure and "WARN" or "INFO", failure or "PASS", { state = lab.state, tx = id })
            if callback then callback(not failure, failure) end
            refresh()
        end
        local protectedFollowup = function()
            executing = true
            local ok = pcall(verify)
            executing = false
            if not ok then error("EXPERIMENT_HANDLER_ERROR") end
        end
        local guarded = runtime.log and runtime.log.Guard("experiments", "followup", protectedFollowup, function()
            local done = pendingCompletion; mark("EXPERIMENT_HANDLER_ERROR"); if done then pcall(done, false, "EXPERIMENT_HANDLER_ERROR") end
        end) or protectedFollowup
        local scheduled = pcall(reader.env.C_Timer.After, delay or 0.15, guarded)
        if not scheduled then mark("FOLLOWUP_TIMER_FAILED"); if callback then callback(false, lab.lastError) end; return nil, lab.lastError end
        refresh(); return true
    end
    local function show(proposal, title)
        lab.serial = lab.serial + 1; proposal.token = tostring(lab.serial)
        proposal.lines = { title, "The original values below are recorded before any change.",
            "Export is optional. A saved report can help recover after an interrupted session." }
        for _, op in ipairs(proposal.plan.operations) do
            proposal.lines[#proposal.lines + 1] = op.key .. " original=" .. op.originalRaw .. " current=" .. op.beforeRaw .. " target=" .. op.targetRaw
        end
        local count = 0; for _, item in pairs(proposal.seen) do if item.code == "OK" then count = count + 1 end end
        proposal.lines[#proposal.lines + 1] = "Watch coverage: " .. count .. "/" .. #watchKeys() .. " readable named keys; no complete engine enumeration."
        lab.preview = proposal; record("preview", "INFO", "READY", { count = #proposal.plan.operations })
        return true
    end
    function lab.Preview(key, target)
        lab.preview = nil
        if lab.busy then return nil, "BUSY" end
        if not cameraMode and db and (db.optics.comparison or ns.Optics.Known(key) and next(db.optics.visual)) then return nil, "USE_MODE_DETAIL_CONTROLS" end
        if not data or next(data.journal.entries) then return nil, "RESTORE_EXPERIMENTS_BEFORE_CALIBRATING" end
        if runtime.engine and runtime.engine.Status().state ~= "BASELINE" then return nil, "RESTORE_BRIGHTNESS_BEFORE_CALIBRATING" end
        local item = ns.ReadOnly.Read(reader, key)
        local bounds, why = policy.Bounds(key, item.raw, reader)
        if not bounds then return nil, why end
        if not V.Finite(target) or target < bounds.min or target > bounds.max then return nil, "OUTSIDE_BOUNDED_TEST_POLICY" end
        if math.abs(target / bounds.step - math.floor(target / bounds.step + 0.5)) > 0.000001 then return nil, "INVALID_TEST_STEP" end
        if V.Number(item.raw) == target then return nil, "UNCHANGED_VALUE_IS_NOT_A_CALIBRATION" end
        local layer = policy.Layer(key)
        local proposal, code = build(layer, { [key] = target }, false, { [key] = bounds })
        if not proposal then return nil, code end
        proposal.calibration, proposal.key, proposal.target, proposal.bounds = true, key, target, bounds
        return show(proposal, "CALIBRATION: apply the exact target, inspect for about 2 seconds, verify, restore the captured original, verify again.")
    end
    function lab.PreviewRestore(layer)
        lab.preview = nil
        if lab.busy then return nil, "BUSY" end
        if layer ~= "visual" and layer ~= "quality" and not (cameraMode and layer == "camera") then return nil, "INVALID_LAYER" end
        if not cameraMode and (db.optics.comparison or layer == "quality" and next(db.optics.visual)) then return nil, "USE_SHARED_OPTICAL_RESTORE" end
        local proposal, code = build(layer, {}, true)
        if not proposal then return nil, code end
        if #proposal.plan.operations == 0 then return nil, "NO_CAPTURED_EXPERIMENT_ORIGINAL" end
        if not cameraMode and layer == "quality" then proposal.qualityIntent, proposal.referenceIntent = {}, {} end
        return show(proposal, "EXPLICIT RECOVERY: replace the displayed current values with the captured originals. No automatic reapply on failure.")
    end
    function lab.Confirm(token)
        local proposal = lab.preview; lab.preview = nil
        if not proposal or token ~= proposal.token then return nil, "NO_MATCHING_PREVIEW" end
        return run(proposal, function(ok, why)
            if not proposal.calibration then return end
            if not ok then record("calibration", "ERROR", why or "FAIL"); return end
            local restoration, code = build(proposal.layer, {}, false)
            if not restoration then mark(code); return end
            local started, startError = run(restoration, function(restored, reason)
                if not restored then record("calibration", "ERROR", reason or "RESTORE_FAILED"); return end
                local values = lab.certificates[proposal.key] or {}
                if #V.Keys(values) >= 8 then values = {} end -- bounded, session-only experimental certificates
                values[tostring(proposal.target)] = V.Copy(proposal.bounds)
                lab.certificates[proposal.key] = values
                record("calibration", "INFO", "ROUNDTRIP_PASS_VISUAL_EFFECT_NOT_TESTED", { key = proposal.key,
                    requested = tostring(proposal.target), after = proposal.seen[proposal.key].raw })
            end)
            if not started then mark(startError or "RESTORE_NOT_STARTED") end
        end, proposal.calibration and 2 or 0.15)
    end
    local function targetBounds(key, target)
        local entry = data and data.journal.entries[key]
        local bounds, why = policy.Bounds(key, entry and entry.originalRaw or ns.ReadOnly.Read(reader, key).raw, reader)
        if not bounds then return nil, why end
        if not V.Finite(target) or target < bounds.min or target > bounds.max then return nil, "OUTSIDE_BOUNDED_TEST_POLICY:" .. key end
        if math.abs(target / bounds.step - math.floor(target / bounds.step + 0.5)) > 0.000001 then return nil, "INVALID_TEST_STEP:" .. key end
        return bounds
    end
    local function canApply(layer, targets)
        if lab.busy then return nil, "BUSY" end
        if type(targets) == "table" and targets.assaoDetailShadowStrength ~= nil then return nil, "USE_CONTACT_DEPTH_TRIAL" end
        if layer == "quality" and db and db.graphics.records.normal then
            for key in pairs(targets) do if ns.NativeGraphics.Known(key) then return nil, "RESTORE_GRAPHICS_BANK_FIRST" end end
        end
        if lab.state == "RECOVERY" or lab.state == "CONFLICT" then
            if not data or next(data.sideEffects) then return nil, "EXPLICIT_RECOVERY_REQUIRED" end
            -- Read-only preflight; ownership is established only by the new Apply.
            for key, entry in pairs(data.journal.entries) do
                if not R.CanContinue(entry, ns.ReadOnly.Read(reader, key), sessionSignature) then
                    return nil, "EXPLICIT_RECOVERY_REQUIRED"
                end
            end
        end
        if not policy.ValidateTargets(targets, layer) then return nil, "INVALID_EXPERIMENT_TARGETS" end
        local qualityIntent, referenceIntent, sources
        if not cameraMode and layer == "quality" then
            if db.optics.comparison then return nil, "FINISH_COMPARISON" end
            qualityIntent = ns.Optics.Extract(targets)
            referenceIntent = ns.Modes.Reference(runtime)
            local effective, why = ns.Optics.Resolve(db.optics.visual, qualityIntent, referenceIntent)
            if not effective then return nil, why end
            sources = why
            targets = V.Copy(targets)
            for _, key in ipairs(ns.Optics.Keys) do targets[key] = effective[key] end
            for key in pairs(referenceIntent) do
                local entry = data.journal.entries[key]
                if sources[key] == "reference" and entry and V.Number(entry.originalRaw) == referenceIntent[key] then targets[key] = nil end
            end
        end
        local overrides = {}
        for key, target in pairs(targets) do
            local bounds, why
            if sources and sources[key] == "reference" then
                local entry = data.journal.entries[key]
                bounds, why = policy.Bounds(key, entry and entry.originalRaw or ns.ReadOnly.Read(reader, key).raw, reader)
            else bounds, why = targetBounds(key, target) end
            if not bounds then return nil, why end
            overrides[key] = bounds
        end
        local proposal, why = build(layer, targets, false, overrides)
        if proposal then proposal.qualityIntent, proposal.referenceIntent = qualityIntent, referenceIntent end
        return proposal, why
    end
    lab.CanApply = canApply
    function lab.Apply(layer, targets, callback)
        local proposal, code = canApply(layer, targets)
        if not proposal then return nil, code end
        return run(proposal, callback)
    end
    function lab.SaveProfile(id, key, target)
        if cameraMode then return nil, "INVALID_QUALITY_PROFILE" end
        if key == "assaoDetailShadowStrength" then return nil, "USE_CONTACT_DEPTH_TRIAL" end
        if not data or not data.profiles[id] or key == "Contrast" then return nil, "INVALID_QUALITY_PROFILE" end
        local copy = V.Copy(data.profiles[id]); copy[key] = target
        if not policy.ValidateTargets(copy, "quality") then return nil, "PROFILE_LIMIT" end
        local bounds, why = targetBounds(key, target)
        if not bounds then return nil, why end
        data.profiles[id] = copy; record("profile-save", "INFO", "PASS", { profile = id, key = key, requested = tostring(target) })
        return true
    end
    function lab.SelectProfile(id)
        if cameraMode then return nil, "INVALID_QUALITY_PROFILE" end
        local targets, omitted = ns.Quality.Resolve(runtime, id)
        if not targets then return nil, omitted end
        for _, key in ipairs(omitted) do record("profile-omitted", "WARN", "CONTROL_UNAVAILABLE", { profile = id, key = key }) end
        local proposal, code = canApply("quality", targets)
        if not proposal then return nil, code end
        return run(proposal, function(ok)
            if ok then lab.activeProfile = id; db.config.selected.quality = id; record("profile-select", "INFO", "PASS", { profile = id }) end
        end)
    end
    function lab.RestoreLayer(layer, callback)
        if lab.busy then return nil, "BUSY" end
        if not cameraMode or layer ~= "camera" then return nil, "INVALID_LAYER" end
        local proposal, code = build(layer, {}, true)
        if not proposal then return nil, code end
        return run(proposal, callback)
    end
    function lab.Observe()
        if lab.busy or not data then return end
        for key, item in pairs(data.journal.entries) do
            if owned[key] then
                local current = ns.ReadOnly.Read(reader, key)
                if not ns.Planner.SafeObservation(current) or current.raw ~= item.lastVerifiedRaw then
                    mark("EXTERNAL_CONFLICT"); lab.state = "CONFLICT"; return
                end
            end
        end
    end
    function lab.Cancel()
        if runtime.visual and runtime.visual.busy then return runtime.visual.Cancel() end
        lab.preview = nil
        if lab.busy then
            local done = pendingCompletion; mark("CANCELLED_WITH_RECOVERY")
            if done then pcall(done, false, "CANCELLED_WITH_RECOVERY") end
        end
        record("cancel", "INFO", "NO_GRAPHICS_RESTORE"); return true
    end
    function lab.Status()
        return { state = lab.state, busy = lab.busy, error = lab.lastError, token = lab.preview and lab.preview.token,
            activeProfile = lab.activeProfile, operation = pending and "VERIFYING" or lab.preview and "PREVIEW" or "idle" }
    end
    function lab.SyncVisual()
        for _, key in ipairs({ "Contrast", "ResampleAlwaysSharpen", "ResampleSharpness", "bloomUserMult" }) do
            local entry = data and data.journal.entries[key]
            owned[key] = entry and entry.state == "owned" or nil
        end
        lab.state, lab.lastError = data and next(data.journal.entries) and "ACTIVE" or "BASELINE", nil
        for _, item in pairs(data and data.journal.entries or {}) do
            if item.state ~= "owned" then lab.state, lab.lastError = "RECOVERY", item.failure; break end
        end
    end
    for _, name in ipairs({ "Preview", "PreviewRestore", "Confirm", "CanApply", "Apply", "RestoreLayer", "SaveProfile", "SelectProfile", "Cancel" }) do
        local fn, operation = lab[name], name
        lab[name] = function(...)
            if executing then return nil, "BUSY" end
            local outer = executing; executing = true
            local ok, result, why = pcall(fn, ...)
            executing = outer
            if not ok then return mark("EXPERIMENT_HANDLER_ERROR") end
            if not result then lab.lastError = why; record(operation, "WARN", why or "REFUSED"); refresh() end
            return result, why
        end
    end
    if cameraMode then
        local previousBusy = reader.nameBusy
        local occupied = function() return lab.busy or executing end
        if cameraMode == "framing" then reader.framingBusy = occupied else reader.namesOnlyBusy = occupied end
        reader.nameBusy = function() return occupied() or previousBusy and previousBusy() end
    else reader.experimentBusy = function() return lab.busy or executing end end
    -- The player's Test & Restore click is the action. No prior certificate or exported card is required.
    function lab.Test(key, target)
        local ready, why = lab.Preview(key, target)
        if not ready then return nil, why end
        return lab.Confirm(lab.Status().token)
    end
    return lab
end

-- Native tier trials intentionally do not promise an unmapped dependency closure.
-- Capture the named watch set before changing a tier, restore that tier, then require
-- every captured value to match. Never synthesize child-setting repair writes.
function B.NewTierTrials(runtime)
    local reader, db, T = runtime.reader, runtime.db, ns.QualityTrial
    local data = db and db.experiments
    local signature = ns.Compatibility.Inspect(reader).signature
    local trial = { state = T.HasRecord(data) and "RECOVERY" or "IDLE", busy = false, serial = 0 }
    local executing = false
    local function log(operation, level, code, fields) ns.Log.Record(reader, "quality-trial", operation, level, code, fields) end
    local function refresh() if runtime.product and runtime.product.Refresh then runtime.product.Refresh() end end
    local function fail(code)
        local _, entry = T.HasRecord(data)
        if entry then entry.state, entry.failure = "failed", code end
        trial.busy, trial.state, trial.error = false, entry and "RECOVERY" or "IDLE", code
        trial.serial = trial.serial + 1
        log("state", "WARN", code); refresh(); return nil, code
    end
    local function gate()
        if not data or not ns.ExperimentPolicy.Validate(data) then return nil, "EXPERIMENT_DATA_QUARANTINED" end
        if reader.graphicsBusy and reader.graphicsBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if db and (db.graphics.records.normal or next(db.camera.photo.records)) then return nil, "RESTORE_GRAPHICS_BANK_FIRST" end
        if ns.Compatibility.Inspect(reader).signature ~= signature then return nil, "SESSION_BUILD_CHANGED" end
        if not ns.Compatibility.Experimental(signature) then return nil, "IDENTITY_UNAVAILABLE" end
        if not setterAvailable(reader) then return nil, "SETTER_UNAVAILABLE" end
        local combat = ns.ReadOnly.Call(reader, reader.env.InCombatLockdown)
        if not combat or combat.n ~= 1 or combat[1] ~= false then return nil, "COMBAT_OR_RESTRICTION" end
        if type(reader.env.C_Timer) ~= "table" or type(reader.env.C_Timer.After) ~= "function" then return nil, "FOLLOWUP_TIMER_UNAVAILABLE" end
        if runtime.lab.busy or runtime.names and runtime.names.busy or runtime.engine.Status().state ~= "BASELINE" then return nil, "RESTORE_ACTIVE_SETTINGS_BEFORE_TIER_TRIAL" end
        for key, entry in pairs(data.journal.entries) do
            if not T.Known(key) or entry.descriptorVersion ~= 3 then return nil, "RESTORE_ACTIVE_SETTINGS_BEFORE_TIER_TRIAL" end
        end
        if #V.Keys(data.journal.entries) > 1 then return nil, "INVALID_TIER_JOURNAL" end
        local key, entry = T.HasRecord(data)
        if entry and (not data.sideEffects[key] or data.sideEffects[key].before ~= entry.originalRaw) then
            return nil, "TIER_WATCH_RECORD_MISSING"
        end
        return true
    end
    local function schedule(delay, fn)
        local serial = trial.serial
        local ok = pcall(reader.env.C_Timer.After, delay, function()
            if serial ~= trial.serial then return end
            local success = pcall(fn)
            if not success then fail("QUALITY_TRIAL_HANDLER_ERROR") end
        end)
        if not ok then return fail("FOLLOWUP_TIMER_FAILED") end
        return true
    end
    local function apply(key, target, restoring)
        local ready, why = gate(); if not ready then return nil, why end
        local supported, reason = T.Support(reader, key, target); if not supported then return nil, reason end
        local current = ns.ReadOnly.Read(reader, key)
        if not ns.Planner.SafeObservation(current) then return nil, "UNSAFE_TIER_OBSERVATION" end
        if not restoring and not T.Matches(reader, data.sideEffects, "before") then return nil, "WATCH_SNAPSHOT_CHANGED" end
        local catalog = { [key] = T.Descriptor(key, signature) }
        local context, journal = T.Context(signature), V.Copy(data.journal)
        if restoring then
            local entry = journal.entries[key]
            if not entry or entry.descriptorVersion ~= 3 then return nil, "NO_TIER_ORIGINAL" end
            context.explicitRecovery = true
            entry.state, entry.lastVerifiedRaw, entry.failure = "owned", current.raw, nil
        end
        local targets = restoring and {} or { [key] = target }
        local plan, code = ns.Planner.Build(catalog, context, { [key] = current }, journal, "quality", targets)
        if not plan then return nil, code end
        if #plan.operations ~= 1 then return nil, "UNCHANGED_TIER_CHOICE" end
        local tx = assert(R.Begin(journal, plan, trial.serial, "BASELINE"))
        local op = plan.operations[1]
        if op.write then tx = assert(R.Before(tx, tx.id, 1, ns.ReadOnly.Read(reader, key), false))
        else tx = assert(R.ReleaseObserved(tx, tx.id, 1, ns.ReadOnly.Read(reader, key), false)) end
        if tx.state == "ROLLING_BACK" or tx.state == "DEFERRED" then return nil, tx.reason end
        -- Keep the original even when the pure release model already removed it.
        data.journal = V.Copy(tx.journal)
        data.journal.entries[key] = data.journal.entries[key] or V.Copy(journal.entries[key])
        data.journal.entries[key].state = "pending"
        if op.write then
            ready, why = gate(); if not ready then return nil, why end
            local fresh = ns.ReadOnly.Read(reader, key)
            if not ns.Planner.SafeObservation(fresh) or fresh.raw ~= op.beforeRaw then return nil, "EXTERNAL_CONFLICT" end
            ready, why = gate(); if not ready then return nil, why end
            log("write", "INFO", "ATTEMPT", { key = key, original = op.originalRaw, before = op.beforeRaw, requested = op.targetRaw })
            local result = nativeSet(reader, key, op.targetRaw)
            local after = ns.ReadOnly.Read(reader, key)
            tx = assert(R.Observe(tx, tx.id, 1, result and result.n == 1 and result[1] == true
                and ns.Planner.SafeObservation(after), after.raw))
            log("immediate", "INFO", after.code, { key = key, immediate = after.raw })
            if tx.state == "ROLLING_BACK" then return nil, "TIER_WRITE_OR_READBACK_FAILED" end
            data.journal.entries[key].lastVerifiedRaw = after.raw
        end
        return tx
    end
    local restore
    local function finishRestore(key, tx)
        local ready, why = gate(); if not ready then return fail(why) end
        local seen = ns.ReadOnly.Read(reader, key)
        local verified = assert(R.Verify(tx, tx.id, { [key] = seen }))
        local matched, differences = T.Matches(reader, data.sideEffects, "before")
        if verified.state ~= "VERIFIED" or not matched then
            for _, changed in ipairs(differences) do
                log("restoration-difference", "WARN", "DEPENDENT_OR_EXTERNAL_VALUE_NOT_RESTORED", { key = changed,
                    original = data.sideEffects[changed].before, after = ns.ReadOnly.Read(reader, changed).raw })
            end
            return fail("TIER_OR_DEPENDENT_RESTORATION_INCOMPLETE")
        end
        data.journal, data.sideEffects = V.Copy(verified.journal), {}
        trial.busy, trial.state, trial.error = false, "RESTORED", nil
        runtime.lab.state, runtime.lab.lastError = "BASELINE", nil
        log("verified", "INFO", "NAMED_WATCH_ROUNDTRIP_PASS", { key = key, after = seen.raw })
        refresh(); return true
    end
    restore = function(explicit)
        local key, entry = T.HasRecord(data)
        if not entry then return nil, "NO_TIER_ORIGINAL" end
        if not explicit then
            local same = T.Matches(reader, data.sideEffects, "after")
            if not same then return fail("EXTERNAL_CONFLICT_NO_AUTOMATIC_RESTORE") end
        end
        trial.serial, trial.busy, trial.state = trial.serial + 1, true, "RESTORING"
        local tx, why = apply(key, V.Number(entry.originalRaw), true)
        if not tx then return fail(why) end
        return schedule(0.15, function() finishRestore(key, tx) end)
    end
    function trial.Test(key, target)
        if trial.busy then return nil, "BUSY" end
        local ready, why = gate(); if not ready then return nil, why end
        if next(data.journal.entries) then return nil, "QUALITY_TRIAL_RECOVERY_REQUIRED" end
        if next(data.sideEffects) then
            if not T.Matches(reader, data.sideEffects, "before") then return nil, "DEPENDENCY_RECOVERY_REQUIRED" end
            data.sideEffects = {}
        end
        local current = ns.ReadOnly.Read(reader, key)
        if not ns.Planner.SafeObservation(current) then return nil, "UNSAFE_TIER_OBSERVATION" end
        ready, why = T.Support(reader, key, V.Number(current.raw)); if not ready then return nil, why end
        ready, why = T.Support(reader, key, target); if not ready then return nil, why end
        if V.Number(current.raw) == target then return nil, "UNCHANGED_TIER_CHOICE" end
        data.sideEffects = T.Snapshot(reader) -- before the first possible mutation
        trial.serial, trial.busy, trial.state, trial.error = trial.serial + 1, true, "TRYING", nil
        local tx, code = apply(key, target, false)
        if not tx then
            if not T.HasRecord(data) then data.sideEffects = {} end -- no native attempt or ownership
            return fail(code)
        end
        for watched, item in pairs(data.sideEffects) do
            local after = ns.ReadOnly.Read(reader, watched)
            if after.code ~= "OK" or not V.Number(after.raw) then return fail("WATCH_READ_UNAVAILABLE") end
            item.after = after.raw
            if item.after ~= item.before then log("observed-change", "INFO", "TIER_OR_EXTERNAL_CHANGE", { key = watched, before = item.before, after = item.after }) end
            if (watched == "Brightness" or watched == "Contrast" or watched == "Gamma" or watched == "RenderScale")
                and item.after ~= item.before then return fail("VISUAL_OR_RENDER_CHANGE_NO_AUTOMATIC_RESTORE") end
        end
        local held = V.Copy(data.journal.entries[key])
        return schedule(2, function()
            if not data.journal.entries[key] or data.journal.entries[key].originalRaw ~= held.originalRaw
                or data.journal.entries[key].lastVerifiedRaw ~= held.lastVerifiedRaw then return fail("RECOVERY_DATA_CHANGED") end
            local verified = assert(R.Verify(tx, tx.id, { [key] = ns.ReadOnly.Read(reader, key) }))
            if verified.state ~= "VERIFIED" then return fail("TIER_LATE_DRIFT") end
            restore(false)
        end)
    end
    function trial.Restore()
        if trial.busy then return nil, "BUSY" end
        -- Explicit user action; no automatic restore after reload, error or conflict.
        return restore(true)
    end
    function trial.Status()
        local key, entry = T.HasRecord(data)
        return { state = trial.state, busy = trial.busy, error = trial.error, key = key,
            original = entry and entry.originalRaw, operation = trial.busy and "TRIAL" or "idle" }
    end
    for _, name in ipairs({ "Test", "Restore" }) do
        local fn = trial[name]
        trial[name] = function(...)
            if executing then return nil, "BUSY" end
            executing = true
            local ok, result, why = pcall(fn, ...)
            executing = false
            if not ok then return fail("QUALITY_TRIAL_HANDLER_ERROR") end
            if not result then trial.error = why; log(name, "WARN", why); refresh() end
            return result, why
        end
    end
    reader.tierOccupied = function() return trial.busy or executing or T.HasRecord(data) ~= nil end
    return trial
end

-- Native normal/raid recipes. Compact bank snapshots preserve parent selectors
-- and captured custom leaves; nativeSet above is still the only setter call.
function B.NewNativeGraphics(runtime, photo)
    local G, reader, db = ns.NativeGraphics, runtime.reader, runtime.db
    local data = db and (photo and db.camera.photo or db.graphics)
    local engine = { busy = false, state = data and next(data.records) and "RECOVERY" or "IDLE" }
    local executing, sequence = false, 0
    local function refresh()
        if runtime.ui and runtime.ui.Refresh then runtime.ui.Refresh() end
    end
    local function log(result, level, key)
        ns.Log.Record(reader, "native-graphics", "operation", level or "INFO", result, { key = key, state = engine.state })
    end
    local function combat()
        local result = ns.ReadOnly.Call(reader, reader.env.InCombatLockdown)
        return not result or result.n ~= 1 or result[1] ~= false
    end
    local function gate(bank)
        if photo and reader.normalGraphicsBusy and reader.normalGraphicsBusy()
            or not photo and reader.photoGraphicsBusy and reader.photoGraphicsBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if not photo and db and next(db.camera.photo.records) then return nil, "RESTORE_PHOTO_FIRST" end
        if photo and not next(data.records) then
            for _, record in pairs(db.graphics.records) do
                if record.state ~= "owned" or record.error or not G.Matches(reader, record.expected) then return nil, "GRAPHICS_RECOVERY_REQUIRED" end
            end
        end
        if db and db.optics.comparison then return nil, "FINISH_COMPARISON" end
        if reader.brightnessBusy and reader.brightnessBusy()
            or reader.experimentBusy and reader.experimentBusy()
            or reader.nameBusy and reader.nameBusy() then return nil, "OTHER_OPERATION_ACTIVE" end
        if db and db.experiments.journal.entries.assaoDetailShadowStrength then return nil, "RESTORE_CONTACT_DEPTH_FIRST" end
        if not data or not G.Validate(data) then return nil, "GRAPHICS_DATA_QUARANTINED" end
        if combat() then return nil, "COMBAT_OR_RESTRICTION" end
        if not setterAvailable(reader) then return nil, "SETTER_UNAVAILABLE" end
        if type(reader.env.C_Timer) ~= "table" or type(reader.env.C_Timer.After) ~= "function" then return nil, "FOLLOWUP_TIMER_UNAVAILABLE" end
        if runtime.engine and runtime.engine.Status().state == "AWAITING_VERIFICATION"
            or runtime.lab and runtime.lab.busy or runtime.names and runtime.names.busy
            or runtime.product and runtime.product.busy then return nil, "OTHER_OPERATION_ACTIVE" end
        if reader.tierOccupied and reader.tierOccupied() then return nil, "QUALITY_TRIAL_RECOVERY_REQUIRED" end
        if bank == "normal" and db.experiments then
            for key, entry in pairs(db.experiments.journal.entries) do
                if entry.layer == "quality" and G.Known(key) then return nil, "RESTORE_DETAIL_PROFILE_FIRST" end
            end
        end
        local signature = ns.Compatibility.Inspect(reader).signature
        if not signature then return nil, "IDENTITY_UNAVAILABLE" end
        if bank == "raid" and not ns.Planner.SafeObservation(ns.ReadOnly.Read(reader, "RAIDsettingsEnabled")) then
            return nil, "GRAPHICS_CAPTURE_UNAVAILABLE:RAIDsettingsEnabled"
        end
        return signature
    end
    local function snapshot(record)
        local current = {}
        for key in pairs(record.original) do
            local item = ns.ReadOnly.Read(reader, key)
            if not ns.Planner.SafeObservation(item) then return nil, "GRAPHICS_READ_FAILED:" .. key end
            current[key] = item.raw
        end
        return current
    end
    local function foreignSnapshot(bank)
        local values = G.Snapshot(reader, bank == "normal" and "raid" or "normal")
        for _, key in ipairs({ "Brightness", "Contrast", "Gamma", "RenderScale", "ResampleAlwaysSharpen", "ResampleSharpness", "bloomUserMult" }) do
            local item = ns.ReadOnly.Read(reader, key)
            if ns.Planner.SafeObservation(item) then values[key] = item.raw end
        end
        return values
    end
    local function watchForeign(values)
        local matches = true
        for key, before in pairs(values) do
            local item = ns.ReadOnly.Read(reader, key)
            if not ns.Planner.SafeObservation(item) or item.raw ~= before then
                matches = false
                if V.Number(item.raw) then data.sideEffects[key] = { before = before, after = item.raw } end
            end
        end
        return matches
    end
    local function finish(ok, code, callback)
        engine.busy, engine.error = false, code
        engine.state = next(data.records) and (ok and "ACTIVE" or "RECOVERY") or "IDLE"
        log(code or "VERIFIED", ok and "INFO" or "WARN"); refresh()
        if callback then callback(ok, code) end
        return ok, code
    end
    local function mark(record, code)
        record.state, record.error = code and code:find("CONFLICT", 1, true) and "conflict" or "failed", code
        engine.error = code
    end
    local function step(bank, record, key, raw, restoring, signature)
        local ready, why = gate(bank)
        if not ready or ready ~= signature then return nil, why or "SESSION_BUILD_CHANGED" end
        local matches, changed = G.Matches(reader, record.expected)
        if not matches then return nil, "GRAPHICS_EXTERNAL_CONFLICT:" .. changed end
        if not restoring then
            local ok, reason = G.Support(reader, key, V.Number(raw))
            if not ok then return nil, reason .. ":" .. key end
        end
        local plan, journal, _, reason = G.Step(reader, key, raw, restoring, signature)
        if not plan then return nil, reason or "GRAPHICS_PLAN_FAILED" end
        if #plan.operations == 0 then return true end
        local tx = R.Begin(journal, plan, sequence, "ACTIVE")
        if not tx then return nil, "GRAPHICS_PLAN_FAILED" end
        local op = plan.operations[1]
        if op.write then tx = R.Before(tx, sequence, 1, ns.ReadOnly.Read(reader, key), combat())
        else tx = R.ReleaseObserved(tx, sequence, 1, ns.ReadOnly.Read(reader, key), combat()) end
        if not tx or tx.state == "DEFERRED" or tx.state == "ROLLING_BACK" then return nil, "GRAPHICS_EXTERNAL_CONFLICT:" .. key end
        if op.write then
            if combat() then return nil, "COMBAT_OR_RESTRICTION" end
            local result, code = nativeSet(reader, key, op.targetRaw)
            local after = ns.ReadOnly.Read(reader, key)
            tx = R.Observe(tx, sequence, 1, result and result.n == 1 and result[1] == true and ns.Planner.SafeObservation(after), after.raw)
            local observed, readError = snapshot(record)
            if observed then record.expected = observed end
            if not observed then return nil, readError end
            if not tx or tx.state ~= "AWAITING_VERIFICATION" then return nil, code or "GRAPHICS_SETTER_OR_READBACK_FAILED:" .. key end
        end
        return true
    end
    local function run(bank, targets, restoring, callback)
        local signature, why = gate(bank)
        if not signature then return nil, why end
        local previous = data.records[bank] and V.Copy(data.records[bank])
        if not restoring and previous then
            if previous.state ~= "owned" or previous.error or previous.signature ~= signature then return nil, "GRAPHICS_RECOVERY_REQUIRED" end
            local matches, key = G.Matches(reader, previous.expected)
            if not matches then return nil, "GRAPHICS_EXTERNAL_CONFLICT:" .. key end
        end
        local before, omitted = G.Snapshot(reader, bank)
        if not next(targets) then return true, "NO_CHANGE" end
        for key in pairs(targets) do if before[key] == nil then return nil, "GRAPHICS_CAPTURE_UNAVAILABLE:" .. key end end
        local record = previous or { signature = signature, state = "pending", original = V.Copy(before), expected = V.Copy(before) }
        if not V.Copy(record) then return nil, "GRAPHICS_SNAPSHOT_LIMIT" end
        for key in pairs(targets) do if not record.original[key] then return nil, "GRAPHICS_CAPTURE_UNAVAILABLE:" .. key end end
        if restoring then
            if photo and not G.Matches(reader, record.expected) then return nil, "PHOTO_EXTERNAL_CONFLICT" end
            local seen, errorCode = snapshot(record)
            if not seen then return nil, errorCode end
            record.expected = seen -- explicit Restore replaces the currently displayed bank
        end
        local beforeOperation = V.Copy(record.expected)
        local foreign = foreignSnapshot(bank)
        sequence = sequence + 1
        local id = sequence
        engine.busy, engine.state, engine.error = true, "APPLYING", nil
        record.state, record.error = "pending", nil
        data.records[bank] = record -- every original precedes the first possible setter
        log(restoring and "USER_RESTORE_CAPTURED_BANK" or "USER_APPLY_NATIVE_RECIPE")
        local failure
        for _, key in ipairs(G.Order(bank, targets, restoring)) do
            if not watchForeign(foreign) then failure = "OTHER_BANK_OR_VISUAL_CHANGED"; break end
            local ok, code = step(bank, record, key, tostring(targets[key]), restoring, signature)
            if not ok then failure = code; break end
            if not watchForeign(foreign) then failure = "OTHER_BANK_OR_VISUAL_CHANGED"; break end
            if bank == "raid" and targets.RAIDsettingsEnabled == nil
                and record.expected.RAIDsettingsEnabled ~= beforeOperation.RAIDsettingsEnabled then
                failure = "UNREQUESTED_RAID_SWITCH_CHANGED"; break
            end
        end
        if not watchForeign(foreign) then failure = "OTHER_BANK_OR_VISUAL_CHANGED" end
        local compensated = false
        -- Bounded compensation is attempted only for this new Apply, while every
        -- captured current value still matches. Never replay after reload/conflict.
        if failure and not restoring and not failure:find("CONFLICT", 1, true)
            and failure ~= "OTHER_BANK_OR_VISUAL_CHANGED" and G.Matches(reader, record.expected) then
            compensated = true
            for _, key in ipairs(G.Order(bank, beforeOperation, true)) do
                local ok = step(bank, record, key, beforeOperation[key], true, signature)
                if not ok or not watchForeign(foreign) then compensated = false; break end
            end
        end
        if failure and not compensated then mark(record, failure); return finish(false, failure, callback) end
        engine.state = "VERIFYING"
        local followup = function()
            if sequence ~= id then return end
            local ready, gateError = gate(bank)
            if not ready or ready ~= signature then mark(record, gateError or "SESSION_BUILD_CHANGED"); finish(false, record.error, callback); return end
            local stable, key = G.Matches(reader, record.expected)
            if not stable or not watchForeign(foreign) then
                mark(record, "GRAPHICS_LATE_CONFLICT:" .. (key or "other-bank")); finish(false, record.error, callback); return
            end
            local verifyTargets = compensated and beforeOperation or targets
            for targetKey, raw in pairs(verifyTargets) do
                local current = ns.ReadOnly.Read(reader, targetKey)
                local equal = (restoring or compensated) and current.raw == raw or (not restoring and not compensated and V.Number(current.raw) == V.Number(tostring(raw)))
                if not ns.Planner.SafeObservation(current) or not equal then
                    mark(record, "GRAPHICS_FINAL_MISMATCH:" .. targetKey); finish(false, record.error, callback); return
                end
            end
            if compensated then data.records[bank] = previous
            elseif restoring then data.records[bank] = nil
            else record.state, record.error = "owned", nil end
            finish(not failure, failure, callback)
        end
        local guarded = runtime.log.Guard("native-graphics", "followup", followup, function()
            mark(record, "GRAPHICS_HANDLER_ERROR"); finish(false, record.error, callback)
        end)
        local scheduled = pcall(reader.env.C_Timer.After, 0.15, function()
            local prior = executing
            executing = true
            guarded()
            executing = prior
        end)
        if not scheduled then mark(record, "FOLLOWUP_TIMER_FAILED"); return finish(false, record.error, callback) end
        refresh()
        return true
    end
    function engine.Apply(choices, callback)
        if engine.busy then return nil, "BUSY" end
        if not data or not G.Validate(data) then return nil, "GRAPHICS_DATA_QUARANTINED" end
        if not G.Choices(choices) then return nil, "INVALID_GRAPHICS_CHOICE" end
        -- Preflight BOTH banks before any write; a bad raid recipe cannot first
        -- change everyday settings. They commit sequentially, not atomically.
        local recipes = {}
        for _, bank in ipairs(G.Banks) do
            local targets, why = G.Recipe(reader, bank, choices[bank])
            if not targets then return nil, why end
            if bank == "raid" and choices.raidEnabled ~= "keep" then targets.RAIDsettingsEnabled = choices.raidEnabled == "on" and 1 or 0 end
            if next(targets) then
                local signature, errorCode = gate(bank); if not signature then return nil, errorCode end
                local record = data.records[bank]
                if record and (record.state ~= "owned" or record.error or record.signature ~= signature or not G.Matches(reader, record.expected)) then return nil, "GRAPHICS_RECOVERY_REQUIRED" end
                for key in pairs(targets) do if not ns.Planner.SafeObservation(ns.ReadOnly.Read(reader, key)) then return nil, "GRAPHICS_CAPTURE_UNAVAILABLE:" .. key end end
            end
            recipes[bank] = targets
        end
        data.choices = V.Copy(choices)
        local index = 0
        local function nextBank(ok, code)
            if ok == false then if callback then callback(false, code) end; return end
            index = index + 1
            local bank = G.Banks[index]
            if not bank then if callback then callback(true) end; return true end
            if not next(recipes[bank]) then return nextBank(true) end
            local completed = false
            local started, why = run(bank, recipes[bank], false, function(ok, code)
                completed = true; nextBank(ok, code)
            end)
            if not started and not completed then nextBank(false, why) end
            return started, why
        end
        return nextBank(true)
    end
    function engine.Restore(bank, callback)
        if engine.busy then return nil, "BUSY" end
        if not data or not G.Validate(data) then return nil, "GRAPHICS_DATA_QUARANTINED" end
        local record = data.records[bank]
        if not record then return true, "NO_CHANGE" end
        return run(bank, V.Copy(record.original), true, callback)
    end
    function engine.RestorePhoto(callback)
        if not photo or engine.busy then return nil, "BUSY" end
        if not data or not G.Validate(data) then return nil, "GRAPHICS_DATA_QUARANTINED" end
        local index, failure = 0, nil
        local function advance(ok, code)
            if not ok then failure = failure or code end
            index = index + 1
            local bank = G.Banks[index]
            if not bank then
                if failure then engine.state, engine.error = "RECOVERY", failure; refresh() end
                if callback then callback(not failure, failure) end
                return
            end
            local record = data.records[bank]
            if not record then advance(true); return end
            local called = false
            -- Continue inside this boundary: a native completion callback still
            -- holds the public reentry guard until it returns.
            local started, why = run(bank, V.Copy(record.original), true, function(done, reason)
                called = true; advance(done, reason)
            end)
            if not started and not called then advance(false, why) end
        end
        advance(true); return true
    end
    function engine.Observe()
        if engine.busy or executing or not data then return end
        if not photo and db and next(db.camera.photo.records) then return end
        for _, record in pairs(data.records) do
            if record.state == "owned" and not G.Matches(reader, record.expected) then
                mark(record, "GRAPHICS_EXTERNAL_CONFLICT"); engine.state = "RECOVERY"
            end
        end
    end
    function engine.Status() return { busy = engine.busy, state = engine.state, error = engine.error } end
    -- Block native callback reentry during preflight, writes and verification.
    for _, name in ipairs({ "Apply", "Restore", "RestorePhoto" }) do
        local fn = engine[name]
        engine[name] = function(...)
            if executing then return nil, "BUSY" end
            executing = true
            local ok, result, why = pcall(fn, ...)
            executing = false
            if not ok then
                for _, record in pairs(data and data.records or {}) do if record.state == "pending" then mark(record, "GRAPHICS_HANDLER_ERROR") end end
                engine.busy, engine.state, engine.error = false, "RECOVERY", "GRAPHICS_HANDLER_ERROR"
                log(engine.error, "ERROR"); return nil, engine.error
            end
            if not result and why then engine.error = why; log(why, "WARN") end
            return result, why
        end
    end
    local previousBusy = reader.graphicsBusy
    local occupied = function() return engine.busy or executing end
    if photo then reader.photoGraphicsBusy = occupied else reader.normalGraphicsBusy = occupied end
    reader.graphicsBusy = function() return occupied() or previousBusy and previousBusy() end
    return engine
end
