local _, ns = ...
local S, V = {}, ns.Value
ns.Store = S
local states = { pending = true, owned = true, conflict = true, failed = true }
local recordFields = { originalRaw = true, lastVerifiedRaw = true, intendedRaw = true,
    layer = true, epoch = true, state = true, descriptorVersion = true, signature = true,
    failure = true }

function S.EmptyJournal() return { entries = {}, nextEpoch = 1 } end
function S.ValidateJournal(journal)
    if not V.Fields(journal, { entries = true, nextEpoch = true })
        or type(journal.entries) ~= "table" or not V.Finite(journal.nextEpoch)
        or journal.nextEpoch < 1 or journal.nextEpoch % 1 ~= 0 then return false end
    local count = 0
    for key, record in pairs(journal.entries) do
        count = count + 1
        -- Unknown historical keys are preserved as inert recovery data, never admitted.
        if count > 64 or not V.Raw(key) or not key:match("^[%w_]+$")
            or not V.Fields(record, recordFields) or not V.Raw(record.originalRaw)
            or not V.Raw(record.lastVerifiedRaw) or not V.Raw(record.intendedRaw)
            or (record.layer ~= "visual" and record.layer ~= "quality")
            or not states[record.state] or not V.Finite(record.epoch) or record.epoch < 1
            or record.epoch % 1 ~= 0 or record.epoch >= journal.nextEpoch
            or not V.Finite(record.descriptorVersion) or record.descriptorVersion < 1
            or not V.Raw(record.signature)
            or (record.failure ~= nil and not V.Raw(record.failure)) then return false end
    end
    return true
end

function S.Open(raw)
    if raw == nil then
        return { schemaVersion = ns.schemaVersion, addonVersion = ns.version,
            config = ns.Profiles.Defaults(), journal = S.EmptyJournal() }, "NEW"
    end
    local data = V.Copy(raw)
    if not data or type(data) ~= "table" then return nil, "QUARANTINED_DATA" end
    if data.schemaVersion ~= ns.schemaVersion then
        -- No released predecessor schema exists. Refuse a speculative migration.
        return nil, "UNSUPPORTED_SCHEMA"
    end
    if not V.Fields(data, { schemaVersion = true, addonVersion = true, config = true, journal = true })
        or not V.Raw(data.addonVersion) or not ns.Profiles.Validate(data.config)
        or not S.ValidateJournal(data.journal) then return nil, "QUARANTINED_SCHEMA" end
    data.addonVersion = ns.version
    return data, "VALIDATED_COPY"
end
