local _, ns = ...
local R, V = {}, ns.Value
ns.Recovery = R

-- All methods return new data. Nothing here reads a client or executes a plan.
function R.Inspect(journal, observed, signature)
    local result = { state = "BASELINE", entries = {} }
    for key, record in pairs(journal.entries) do
        result.state = "RECOVERY"
        local current = observed[key]
        local status = "UNAVAILABLE"
        if record.signature ~= signature then status = "BUILD_CHANGED"
        elseif current and current.code == "OK" and V.Raw(current.raw) then
            status = current.raw == record.lastVerifiedRaw and "MATCHING_UNVERIFIED_OWNERSHIP" or "EXTERNAL_CONFLICT"
        end
        result.entries[key] = status
    end
    return result
end

function R.Begin(journal, plan, id, previousState)
    if not ns.Store.ValidateJournal(journal) or type(plan) ~= "table"
        or not V.Finite(id) or id < 1 or id % 1 ~= 0 then return nil, "INVALID_TRANSACTION" end
    local tx = V.Copy({ journal = journal, prior = journal, plan = plan, id = id,
        previousState = previousState, state = "APPLYING", nextIndex = 1, attempts = {}, releases = {} })
    if not tx or type(tx.plan.operations) ~= "table"
        or (previousState ~= "BASELINE" and previousState ~= "ACTIVE") then return nil, "INVALID_TRANSACTION" end
    -- Plans are internal data from Planner.Build, never deserialized user imports.
    for _, op in ipairs(tx.plan.operations) do
        if not V.Raw(op.beforeRaw) or not V.Raw(op.originalRaw) or not V.Raw(op.targetRaw)
            or tx.journal.entries[op.key] and tx.journal.entries[op.key].originalRaw ~= op.originalRaw then
            return nil, "INVALID_CAPTURE"
        end
        tx.journal.entries[op.key] = { originalRaw = op.originalRaw, lastVerifiedRaw = op.beforeRaw,
            intendedRaw = op.targetRaw, layer = op.layer, epoch = op.epoch, state = "pending",
            descriptorVersion = op.descriptorVersion, signature = op.signature }
    end
    tx.journal.nextEpoch = plan.nextEpoch
    if not ns.Store.ValidateJournal(tx.journal) then return nil, "INVALID_CAPTURE" end
    if #tx.plan.operations == 0 then tx.state = "AWAITING_VERIFICATION" end
    return tx
end

local function prepare(tx, id, index, current, combat)
    if id ~= tx.id or tx.state ~= "APPLYING" or index ~= tx.nextIndex or tx.pendingIndex then
        return nil, "STALE_OR_BUSY"
    end
    local nextTx, op = V.Copy(tx), tx.plan.operations[index]
    if not nextTx then return nil, "TRANSACTION_LIMIT" end
    if not op then return nil, "NO_OPERATION" end
    if combat ~= false then
        nextTx.state = #tx.attempts == 0 and "DEFERRED" or "ROLLING_BACK"
        nextTx.reason = "COMBAT_OR_RESTRICTION"
    elseif not ns.Planner.SafeObservation(current) or current.raw ~= op.beforeRaw then
        nextTx.state, nextTx.reason = "ROLLING_BACK", "EXTERNAL_CONFLICT"
        nextTx.journal.entries[op.key].state = "conflict"
    else nextTx.pendingIndex = index end
    return nextTx
end

function R.Before(tx, id, index, current, combat)
    local nextTx, code = prepare(tx, id, index, current, combat)
    if not nextTx then return nil, code end
    if tx.plan.operations[index].write ~= true then return nil, "OBSERVATION_RELEASE_REQUIRED" end
    return nextTx
end

-- Release bookkeeping from a fresh observation; no setter result is requested or fabricated.
function R.ReleaseObserved(tx, id, index, current, combat)
    local nextTx, code = prepare(tx, id, index, current, combat)
    if not nextTx then return nil, code end
    local op = tx.plan.operations[index]
    if op.release ~= true or op.write ~= false or op.beforeRaw ~= op.originalRaw
        or op.targetRaw ~= op.originalRaw then return nil, "INVALID_OBSERVATION_RELEASE" end
    if nextTx.pendingIndex ~= index then return nextTx end -- drift/restriction retains the record
    nextTx.releases[#nextTx.releases + 1] = { index = index, raw = current.raw }
    nextTx.journal.entries[op.key], nextTx.pendingIndex = nil, nil
    nextTx.nextIndex = index + 1
    if nextTx.nextIndex > #tx.plan.operations then nextTx.state = "AWAITING_VERIFICATION" end
    return nextTx
end

-- setterOK/readback are synthetic facts supplied by tests, not native setter calls.
function R.Observe(tx, id, index, setterOK, raw)
    if id ~= tx.id or tx.state ~= "APPLYING" or tx.pendingIndex ~= index then return nil, "STALE_OR_BUSY" end
    local nextTx, op = V.Copy(tx), tx.plan.operations[index]
    if not nextTx then return nil, "TRANSACTION_LIMIT" end
    if op.write ~= true then return nil, "OBSERVATION_RELEASE_REQUIRED" end
    local readable = V.Raw(raw)
    nextTx.attempts[#nextTx.attempts + 1] = { index = index, raw = readable and raw or nil }
    nextTx.pendingIndex = nil
    local matches = readable and (raw == op.targetRaw
        or (not op.release and ns.Catalog.Equal(op, raw, op.targetRaw)))
    if setterOK == true and matches then
        if op.release then nextTx.journal.entries[op.key] = nil
        else
            local record = nextTx.journal.entries[op.key]
            record.state, record.lastVerifiedRaw = "owned", raw
        end
        nextTx.nextIndex = index + 1
        if nextTx.nextIndex > #tx.plan.operations then nextTx.state = "AWAITING_VERIFICATION" end
    else
        nextTx.state, nextTx.reason = "ROLLING_BACK", "RESULT_NOT_VERIFIED"
        nextTx.journal.entries[op.key].state = "failed"
        nextTx.journal.entries[op.key].failure = nextTx.reason
    end
    return nextTx
end

function R.Verify(tx, id, observed)
    if id ~= tx.id or tx.state ~= "AWAITING_VERIFICATION" then return nil, "STALE_OR_INVALID_VERIFY" end
    local nextTx = V.Copy(tx)
    if not nextTx then return nil, "TRANSACTION_LIMIT" end
    for _, observations in ipairs({ tx.attempts, tx.releases }) do
        for _, item in ipairs(observations) do
            local op = tx.plan.operations[item.index]
            local current = observed[op.key]
            if not ns.Planner.SafeObservation(current) or current.raw ~= item.raw then
                nextTx.state, nextTx.reason = "ROLLING_BACK", "LATE_DRIFT_OR_RESTRICTION"
                if op.write == false then nextTx.journal.entries[op.key] = V.Copy(tx.prior.entries[op.key]) end
                if nextTx.journal.entries[op.key] then nextTx.journal.entries[op.key].state = "conflict" end
                return nextTx
            end
        end
    end
    nextTx.state = "VERIFIED"
    return nextTx
end

function R.RollbackPlan(tx, observed)
    if tx.state ~= "ROLLING_BACK" and tx.state ~= "DEFERRED" then return nil, "INVALID_STATE" end
    local nextTx = V.Copy(tx)
    if not nextTx then return nil, "TRANSACTION_LIMIT" end
    nextTx.rollback, nextTx.unresolved = {}, {}
    local processed = {}
    for i = #tx.attempts, 1, -1 do
        local attempt = tx.attempts[i]
        local op, current = tx.plan.operations[attempt.index], observed[tx.plan.operations[attempt.index].key]
        processed[op.key] = true
        if ns.Planner.SafeObservation(current) and current.raw == op.beforeRaw then
            nextTx.journal.entries[op.key] = V.Copy(tx.prior.entries[op.key])
        elseif ns.Planner.SafeObservation(current) and attempt.raw and current.raw == attempt.raw then
            nextTx.rollback[#nextTx.rollback + 1] = { key = op.key, targetRaw = op.beforeRaw, expectedRaw = current.raw }
            nextTx.unresolved[op.key] = "PENDING_COMPENSATION"
        else nextTx.unresolved[op.key] = "CONFLICT_OR_UNREADABLE" end
        if nextTx.unresolved[op.key] then
            -- A completed release may have removed the record; reconstruct its original.
            nextTx.journal.entries[op.key] = nextTx.journal.entries[op.key] or {
                originalRaw = op.originalRaw, lastVerifiedRaw = attempt.raw or op.beforeRaw,
                intendedRaw = op.targetRaw, layer = op.layer, epoch = op.epoch,
                descriptorVersion = op.descriptorVersion, signature = op.signature }
            local record = nextTx.journal.entries[op.key]
            record.state, record.failure = "failed", nextTx.unresolved[op.key]
        end
    end
    -- Observation-only releases undo bookkeeping, never schedule a compensating write.
    for _, release in ipairs(tx.releases) do
        local op = tx.plan.operations[release.index]
        local current = observed[op.key]
        processed[op.key] = true
        nextTx.journal.entries[op.key] = V.Copy(tx.prior.entries[op.key])
        if not ns.Planner.SafeObservation(current) or current.raw ~= op.beforeRaw then
            nextTx.unresolved[op.key] = "RELEASE_CONFLICT_OR_UNREADABLE"
            nextTx.journal.entries[op.key].state = "conflict"
            nextTx.journal.entries[op.key].failure = nextTx.unresolved[op.key]
        end
    end
    for _, op in ipairs(tx.plan.operations) do
        if not processed[op.key] then
            if tx.journal.entries[op.key] and tx.journal.entries[op.key].state == "conflict" then
                nextTx.unresolved[op.key] = "CONFLICT_BEFORE_OPERATION"
                nextTx.journal.entries[op.key].failure = nextTx.unresolved[op.key]
            else nextTx.journal.entries[op.key] = V.Copy(tx.prior.entries[op.key]) end
        end
    end
    nextTx.state = "ROLLING_BACK"
    return nextTx
end

function R.BeforeRollback(tx, id, key, current, combat)
    if id ~= tx.id or tx.state ~= "ROLLING_BACK" or not tx.unresolved
        or tx.unresolved[key] ~= "PENDING_COMPENSATION" or tx.pendingRollback then
        return nil, "STALE_OR_INVALID_ROLLBACK"
    end
    local nextTx, expected = V.Copy(tx)
    if not nextTx then return nil, "TRANSACTION_LIMIT" end
    for _, op in ipairs(tx.rollback) do
        if tx.unresolved[op.key] == "PENDING_COMPENSATION" then
            if op.key ~= key then return nil, "ROLLBACK_ORDER" end
            expected = op.expectedRaw
            break
        end
    end
    if combat ~= false or not ns.Planner.SafeObservation(current) or current.raw ~= expected then
        nextTx.unresolved[key] = "CONFLICT_OR_RESTRICTED"
        nextTx.journal.entries[key].state = "conflict"
        nextTx.journal.entries[key].failure = nextTx.unresolved[key]
    else nextTx.pendingRollback = key end
    return nextTx
end

function R.ResolveRollback(tx, id, key, setterOK, currentRaw)
    if id ~= tx.id or tx.state ~= "ROLLING_BACK" or not tx.unresolved
        or tx.unresolved[key] ~= "PENDING_COMPENSATION" or tx.pendingRollback ~= key then return nil, "STALE_OR_INVALID_ROLLBACK" end
    local nextTx, target = V.Copy(tx)
    if not nextTx then return nil, "TRANSACTION_LIMIT" end
    nextTx.pendingRollback = nil
    for _, op in ipairs(tx.rollback) do if op.key == key then target = op.targetRaw end end
    if setterOK == true and currentRaw == target then
        nextTx.journal.entries[key], nextTx.unresolved[key] = V.Copy(tx.prior.entries[key]), nil
    else
        nextTx.unresolved[key] = "COMPENSATION_FAILED"
        nextTx.journal.entries[key].failure = "COMPENSATION_FAILED"
    end
    return nextTx
end

function R.FinishRollback(tx)
    if tx.state ~= "ROLLING_BACK" or not tx.unresolved then return nil, "INVALID_STATE" end
    local nextTx = V.Copy(tx)
    if not nextTx then return nil, "TRANSACTION_LIMIT" end
    nextTx.state = next(tx.unresolved) and "PARTIAL_ERROR" or tx.previousState
    return nextTx
end
