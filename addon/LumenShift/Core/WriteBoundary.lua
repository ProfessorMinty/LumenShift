local _, ns = ...
local B, V, R = {}, ns.Value, ns.Recovery
ns.WriteBoundary = B

-- No ambient enable switch or public raw setter. A preview token is consumed once.
function B.Request() return nil, "TEST_NOT_ENABLED" end

function B.New(reader, db, emit)
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

    local function setterAvailable()
        local api = reader.env.C_CVar
        return type(api) == "table" and type(api.SetCVar) == "function"
    end

    local function eligible()
        if not db then return nil, "SAVED_DATA_QUARANTINED" end
        if not ns.Store.ValidateJournal(db.journal) then return nil, "INVALID_JOURNAL" end
        for key in pairs(db.journal.entries) do
            if key ~= "Brightness" then return nil, "OTHER_RECOVERY_RECORDS_PRESENT" end
        end
        local identity = ns.Compatibility.Inspect(reader)
        local catalog, context = ns.Catalog.BrightnessExperiment(identity.signature)
        if not catalog then return nil, "UNSUPPORTED_TEST_BUILD" end
        if not setterAvailable() then return nil, "SETTER_UNAVAILABLE" end
        if combat() then return nil, "COMBAT_OR_RESTRICTION" end
        return catalog, context
    end

    local function mark(reason, conflict)
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
        local result, code = ns.ReadOnly.Call(reader, reader.env.C_CVar.SetCVar, "Brightness", target)
        local after = read() -- even an errored setter might have changed the value
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
            transaction = { compensation = true, expected = expected, finalJournal = rollback.journal,
                failure = lastError, held = V.Copy(db.journal) }
            state = "AWAITING_VERIFICATION"
        end
        say("Operation failed: " .. lastError .. "; compensation state " .. state .. ". Inspect /ls.")
    end

    local function prepare(action)
        proposal = nil -- a new explicit request always expires the previous preview
        if action ~= "on" and action ~= "off" and action ~= "restore" then return nil, "UNKNOWN_ACTION" end
        local catalog, context = eligible()
        if not catalog then return nil, context end
        local current = read()
        if not ns.Planner.SafeObservation(current) then return nil, "UNSAFE_OBSERVATION" end
        local journal = V.Copy(db.journal)
        local record = journal.entries.Brightness
        local recoveryAction = action == "restore" and (not sessionOwned or transaction ~= nil or state ~= "ACTIVE"
            or record and (record.state ~= "owned" or record.lastVerifiedRaw ~= current.raw))
        if action == "on" and (state ~= "BASELINE" and state ~= "ACTIVE") then return nil, "RECOVERY_REQUIRED" end
        if action == "off" and (not sessionOwned or state ~= "ACTIVE") then return nil, "USE_EXPLICIT_RESTORE" end
        if action ~= "on" and not record then return nil, "NO_CAPTURED_ORIGINAL" end
        if record then
            if record.signature ~= context.signature or record.descriptorVersion ~= 1 or record.layer ~= "visual" then
                return nil, "RECOVERY_SIGNATURE_MISMATCH"
            end
            if action == "restore" then
                -- Explicit restore previews a reconciliation. Never silently replace originalRaw.
                record.lastVerifiedRaw, record.state, record.failure = current.raw, "owned", nil
            elseif record.state ~= "owned" or record.lastVerifiedRaw ~= current.raw then
                mark("EXTERNAL_CONFLICT", true); return nil, "EXTERNAL_CONFLICT"
            end
        end
        local targets = action == "on" and { Brightness = 75 } or {}
        local plan, code = ns.Planner.Build(catalog, context, { Brightness = current }, journal, "visual", targets)
        if not plan then return nil, code end
        if #plan.operations == 0 then return nil, "ALREADY_AT_TARGET_NO_OWNERSHIP_CHANGE" end
        if #plan.operations ~= 1 or plan.operations[1].key ~= "Brightness" then return nil, "TEST_PLAN_EXCLUDED" end
        serial = serial + 1
        local op = plan.operations[1]
        local shown = say("RECOVERY CARD " .. serial .. " | " .. context.signature
            .. " | Brightness original=" .. op.originalRaw .. " current=" .. op.beforeRaw .. " target=" .. op.targetRaw)
        shown = say("No write yet. Save this card outside the game; SavedVariables is not immediately durable.") and shown
        if recoveryAction then
            shown = say("Explicit recovery will replace the CURRENT value with the saved original. No automatic compensation on recovery failure.") and shown
        end
        shown = say("Only after live-test approval and saving the card: /ls confirm " .. serial
            .. ". This authorizes the displayed operation and bounded compensation for normal on/off failures.") and shown
        if not shown then return nil, "RECOVERY_CARD_NOT_DISPLAYED" end
        proposal = { token = tostring(serial), plan = plan, journal = journal, sourceJournal = V.Copy(db.journal),
            action = action, recoveryAction = recoveryAction, priorState = sessionOwned and "ACTIVE" or "BASELINE" }
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
        local targets = pending.action == "on" and { Brightness = 75 } or {}
        local _, context = ns.Catalog.BrightnessExperiment(op.signature)
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
        transaction = { model = tx, action = pending.action, recoveryAction = pending.recoveryAction,
            held = V.Copy(db.journal) }
        state = "AWAITING_VERIFICATION"
        say("Immediate readback matched. Inspect the scene, then /ls verify for a separate fresh read. Original=" .. op.originalRaw)
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
        local checked, code = R.Verify(transaction.model, transaction.model.id, { Brightness = read() })
        if not checked then mark(code, false); return nil, code end
        if checked.state ~= "VERIFIED" then
            -- A delayed mismatch could be an external change. Never automatically fight it.
            mark("LATE_DRIFT_OR_RESTRICTION", true); return nil, "LATE_DRIFT_OR_RESTRICTION"
        end
        db.journal = V.Copy(checked.journal)
        sessionOwned = db.journal.entries.Brightness ~= nil
        state, lastError = sessionOwned and "ACTIVE" or "BASELINE", nil
        transaction, dirty = nil, false
        say(sessionOwned and "Night Vision verified by readback. /ls off previews exact restoration."
            or "Original Brightness verified by exact readback; ownership released.")
        return true
    end

    local function guarded(fn, ...)
        if busy then return nil, "BUSY" end
        busy = true
        local ok, result, code = pcall(fn, ...)
        busy = false
        if not ok then
            mark("ENGINE_ERROR", false)
            say("Engine error; writes locked. Preserve the recovery card and inspect /ls.")
            return nil, "ENGINE_ERROR"
        end
        if not result then lastError = code; say("Refused/failed: " .. (code or "UNKNOWN") .. ". No automatic retry.") end
        return result, code
    end

    function engine.Prepare(action) return guarded(prepare, action) end
    function engine.Confirm(token) return guarded(confirm, token) end
    function engine.Verify() return guarded(verify) end
    function engine.Cancel()
        if busy then return nil, "BUSY" end
        proposal = nil
        -- Cancel revokes permission; it is not a hidden restore or loss of a pending journal.
        if transaction then mark("CANCELLED_WITH_RECOVERY", false) end
        operation = "none"
        return true
    end
    function engine.Notify() dirty = true end -- synchronous notifications never recurse into writes
    function engine.Status()
        if not busy and sessionOwned and state == "ACTIVE" and not (proposal and proposal.recoveryAction) then
            local current = read()
            if not ns.Planner.SafeObservation(current) or current.raw ~= db.journal.entries.Brightness.lastVerifiedRaw then
                mark("EXTERNAL_CONFLICT", true)
            end
        end
        local record = db and db.journal.entries.Brightness
        return { state = state, operation = operation, original = record and record.originalRaw,
            lastVerified = record and record.lastVerifiedRaw, token = proposal and proposal.token,
            error = lastError, notificationsPending = dirty, writeEnabled = false, setterAvailable = setterAvailable() }
    end
    return engine
end
