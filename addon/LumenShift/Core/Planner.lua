local _, ns = ...
local P, V = {}, ns.Value
ns.Planner = P

local function safeObservation(item)
    return type(item) == "table" and item.code == "OK" and V.Number(item.raw) ~= nil
        and item.flagsCode == "OK" and type(item.flags) == "table"
        and item.flags.secure == false and item.flags.readOnly == false
        and item.flags.locked == false
        and item.flags.serverAccount == false and item.flags.serverCharacter == false
end
P.SafeObservation = safeObservation

function P.Build(catalog, context, observed, journal, layer, targets)
    local input = V.Copy({ catalog = catalog, context = context, observed = observed,
        journal = journal, targets = targets })
    if not input or type(input.catalog) ~= "table" or type(input.context) ~= "table"
        or type(input.observed) ~= "table" or type(input.targets) ~= "table"
        or not ns.Store.ValidateJournal(input.journal)
        or (layer ~= "visual" and layer ~= "quality") then return nil, "INVALID_INPUT" end
    catalog, context, observed, journal, targets = input.catalog, input.context,
        input.observed, input.journal, input.targets
    if context.verified ~= true or context.rendererVerified ~= true then return nil, "UNVERIFIED_CLIENT" end
    local affected, count = {}, 0
    for key in pairs(targets) do
        if type(key) ~= "string" then return nil, "INVALID_KEY" end
        affected[key] = true
        count = count + 1
    end
    if count > 64 then return nil, "TOO_MANY_KEYS" end
    for key, record in pairs(journal.entries) do
        if record.layer == layer then affected[key] = true end
    end
    local participating = {}
    for key in pairs(affected) do participating[key] = true end
    for key in pairs(journal.entries) do participating[key] = true end
    -- Check both directions, including another layer's already-owned tier/child.
    for key in pairs(participating) do
        local descriptor = catalog[key]
        if not ns.Catalog.Admitted(descriptor, context) then return nil, "UNADMITTED_KEY:" .. key end
        for _, conflict in ipairs(descriptor.conflicts) do
            if participating[conflict] then return nil, "DEPENDENCY_CONFLICT:" .. key end
        end
    end
    local ops, byKey, nextEpoch = {}, {}, journal.nextEpoch
    for _, key in ipairs(V.Keys(affected)) do
        local descriptor, current, record = catalog[key], observed[key], journal.entries[key]
        if not ns.Catalog.Admitted(descriptor, context) then return nil, "UNADMITTED_KEY:" .. key end
        if descriptor.layer ~= layer or (record and record.layer ~= layer) then return nil, "LAYER_CONFLICT:" .. key end
        if not safeObservation(current) then return nil, "UNSAFE_OBSERVATION:" .. key end
        if record and (record.state ~= "owned" or record.signature ~= context.signature
            or record.descriptorVersion ~= descriptor.version
            or current.raw ~= record.lastVerifiedRaw) then return nil, "OWNERSHIP_CONFLICT:" .. key end
        -- A new capture or retained original must be restorable in the admitted domain.
        local originalRaw = record and record.originalRaw or current.raw
        local originalNumber = V.Number(originalRaw)
        if not originalNumber or originalNumber < descriptor.min or originalNumber > descriptor.max then
            return nil, "UNSAFE_BASELINE:" .. key
        end
        local release = targets[key] == nil
        local targetRaw
        if release then
            targetRaw = originalRaw
        else
            local target = targets[key]
            if not V.Finite(target) or target < descriptor.min or target > descriptor.max then
                return nil, "INVALID_TARGET:" .. key
            end
            targetRaw = tostring(target)
        end
        -- Even historical baselines require the current measured domain to allow restoration.
        local number = V.Number(targetRaw)
        if not number or number < descriptor.min or number > descriptor.max then return nil, "UNSAFE_BASELINE:" .. key end
        for _, conflict in ipairs(descriptor.conflicts) do
            if affected[conflict] or journal.entries[conflict] then return nil, "DEPENDENCY_CONFLICT:" .. key end
        end
        local equal = ns.Catalog.Equal(descriptor, current.raw, targetRaw)
        -- Exact raw restoration is stricter than numeric target equivalence.
        if release then equal = current.raw == targetRaw end
        if release or not equal then
            local epoch = record and record.epoch or nextEpoch
            if not record then nextEpoch = nextEpoch + 1 end
            byKey[key] = { key = key, beforeRaw = current.raw, targetRaw = targetRaw,
                originalRaw = originalRaw,
                epoch = epoch, layer = layer, descriptorVersion = descriptor.version,
                signature = context.signature, release = release, write = not equal,
                numericEquivalent = descriptor.numericEquivalent }
        end
    end
    -- Stable topological ordering; a missing dependency is a refusal, never an implicit target.
    local visiting, visited = {}, {}
    local function visit(key)
        if visited[key] then return true end
        if visiting[key] then return false end
        visiting[key] = true
        for _, dependency in ipairs(catalog[key].dependencies) do
            if not affected[dependency] or not catalog[dependency] or not visit(dependency) then return false end
        end
        visiting[key], visited[key] = nil, true
        if byKey[key] then ops[#ops + 1] = byKey[key] end
        return true
    end
    for _, key in ipairs(V.Keys(affected)) do
        if not visit(key) then return nil, "DEPENDENCY_CLOSURE_OR_CYCLE" end
    end
    -- Releasing a dependency graph must undo it in reverse order.
    local releaseCount = 0
    for _, op in ipairs(ops) do if op.release then releaseCount = releaseCount + 1 end end
    if releaseCount == #ops then
        local reverse = {}
        for i = #ops, 1, -1 do reverse[#reverse + 1] = ops[i] end
        ops = reverse
    elseif releaseCount > 0 then
        for key in pairs(affected) do
            if #catalog[key].dependencies > 0 then return nil, "MIXED_DEPENDENT_TRANSITION" end
        end
    end
    return { operations = ops, layer = layer, nextEpoch = nextEpoch, signature = context.signature }
end
