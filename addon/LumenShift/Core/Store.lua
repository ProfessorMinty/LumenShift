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
            or (record.layer ~= "visual" and record.layer ~= "quality" and record.layer ~= "camera")
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
            config = ns.Profiles.Defaults(), journal = S.EmptyJournal(), experiments = ns.ExperimentPolicy.Defaults(),
            onboarding = { completed = false }, camera = ns.NamePolicy.Defaults(), baseline = ns.Baseline.Defaults(),
            graphics = ns.NativeGraphics.Defaults(), optics = ns.Optics.Defaults() }, "NEW"
    end
    local data = V.Copy(raw)
    if not data or type(data) ~= "table" then return nil, "QUARANTINED_DATA" end
    if type(data.schemaVersion) == "number" and data.schemaVersion >= 1 and data.schemaVersion <= 8 then
        local studio = type(data.config) == "table" and data.config.studio
        if type(studio) == "table" then
            for _, m in pairs(type(studio.modes) == "table" and studio.modes or {}) do ns.StudioConfig.UpgradeMode(m) end
            for _, p in pairs(type(studio.presets) == "table" and studio.presets or {}) do
                if type(p) == "table" then ns.StudioConfig.UpgradeMode(p.settings) end
            end
        end
    end
    if type(data.schemaVersion) == "number" and data.schemaVersion >= 5 and data.schemaVersion <= 7
        and type(data.camera) == "table" and data.camera.keepEffects == nil then data.camera.keepEffects = true end
    local migrated = false
    if data.schemaVersion == 1 then
        if not V.Fields(data, { schemaVersion = true, addonVersion = true, config = true, journal = true })
            or not V.Raw(data.addonVersion) or not ns.Profiles.ValidateLegacy(data.config)
            or not S.ValidateJournal(data.journal) then return nil, "QUARANTINED_SCHEMA" end
        data.config.studio = ns.StudioConfig.Defaults()
        data.schemaVersion, migrated = 2, "MIGRATED_1_TO_6"
    end
    if data.schemaVersion == 2 then
        if not V.Fields(data, { schemaVersion = true, addonVersion = true, config = true, journal = true })
            or not V.Raw(data.addonVersion) or not ns.Profiles.Validate(data.config)
            or not S.ValidateJournal(data.journal) then return nil, "QUARANTINED_SCHEMA" end
        data.experiments = ns.ExperimentPolicy.Defaults()
        data.schemaVersion, migrated = 3, migrated or "MIGRATED_2_TO_6"
    end
    if data.schemaVersion == 3 then
        if not V.Fields(data, { schemaVersion = true, addonVersion = true, config = true, journal = true, experiments = true })
            or not V.Raw(data.addonVersion) or not ns.Profiles.Validate(data.config)
            or not S.ValidateJournal(data.journal) or not ns.ExperimentPolicy.Validate(data.experiments) then return nil, "QUARANTINED_SCHEMA" end
        data.onboarding = { completed = false }
        data.schemaVersion, migrated = 4, migrated or "MIGRATED_3_TO_6"
    end
    if data.schemaVersion == 4 then
        if not V.Fields(data, { schemaVersion = true, addonVersion = true, config = true, journal = true, experiments = true, onboarding = true })
            or not V.Raw(data.addonVersion) or not ns.Profiles.Validate(data.config)
            or not S.ValidateJournal(data.journal) or not ns.ExperimentPolicy.Validate(data.experiments)
            or not V.Fields(data.onboarding, { completed = true }) or type(data.onboarding.completed) ~= "boolean" then return nil, "QUARANTINED_SCHEMA" end
        data.camera = ns.NamePolicy.Defaults()
        data.schemaVersion, migrated = 5, migrated or "MIGRATED_4_TO_6"
    end
    if data.schemaVersion == 5 then
        if not V.Fields(data, { schemaVersion = true, addonVersion = true, config = true, journal = true, experiments = true, onboarding = true, camera = true })
            or not V.Raw(data.addonVersion) or not ns.Profiles.Validate(data.config)
            or not S.ValidateJournal(data.journal) or not ns.ExperimentPolicy.Validate(data.experiments) or not ns.NamePolicy.Validate(data.camera)
            or not V.Fields(data.onboarding, { completed = true }) or type(data.onboarding.completed) ~= "boolean" then return nil, "QUARANTINED_SCHEMA" end
        data.baseline = ns.Baseline.Defaults()
        data.schemaVersion, migrated = 6, migrated or "MIGRATED_5_TO_6"
    end
    if data.schemaVersion == 6 then
        if not V.Fields(data, { schemaVersion = true, addonVersion = true, config = true, journal = true, experiments = true, onboarding = true, camera = true, baseline = true })
            or not V.Raw(data.addonVersion) or not ns.Profiles.Validate(data.config)
            or not S.ValidateJournal(data.journal) or not ns.ExperimentPolicy.Validate(data.experiments) or not ns.NamePolicy.Validate(data.camera) or not ns.Baseline.Validate(data.baseline)
            or not V.Fields(data.onboarding, { completed = true }) or type(data.onboarding.completed) ~= "boolean" then return nil, "QUARANTINED_SCHEMA" end
        data.graphics = ns.NativeGraphics.Defaults()
        data.schemaVersion, migrated = 7, migrated and migrated:gsub("_TO_6$", "_TO_7") or "MIGRATED_6_TO_7"
    end
    if data.schemaVersion == 7 then
        data.schemaVersion, migrated = 8, migrated and migrated:gsub("_TO_7$", "_TO_8") or "MIGRATED_7_TO_8"
    end
    if data.schemaVersion == 8 then
        if not ns.ExperimentPolicy.Validate(data.experiments) then return nil, "QUARANTINED_SCHEMA" end
        data.optics = data.optics or ns.Optics.Migrate(data.experiments.journal)
        data.schemaVersion, migrated = 9, migrated and migrated:gsub("_TO_8$", "_TO_9") or "MIGRATED_8_TO_9"
    end
    if data.schemaVersion ~= ns.schemaVersion then
        -- Only the explicitly supported schema-1/2/3/4/5/6/7/8 migrations above are permitted.
        return nil, "UNSUPPORTED_SCHEMA"
    end
    if not V.Fields(data, { schemaVersion = true, addonVersion = true, config = true, journal = true, experiments = true, onboarding = true, camera = true, baseline = true, graphics = true, optics = true })
        or not V.Raw(data.addonVersion) or not ns.Profiles.Validate(data.config)
        or not S.ValidateJournal(data.journal) or not ns.ExperimentPolicy.Validate(data.experiments) or not ns.NamePolicy.Validate(data.camera) or not ns.Baseline.Validate(data.baseline)
        or not ns.NativeGraphics.Validate(data.graphics) or not ns.Optics.Validate(data.optics)
        or not V.Fields(data.onboarding, { completed = true }) or type(data.onboarding.completed) ~= "boolean" then return nil, "QUARANTINED_SCHEMA" end
    -- One-time setup refresh for the old completed-wizard generations. Keep every
    -- preference and journal; only the old completion marker is superseded.
    if data.onboarding.completed and (data.addonVersion:match("^0%.2%.0%-dev%.[1-5]$")
        or data.addonVersion == "0.2.0-beta.1") then
        data.onboarding.completed = false
        migrated = migrated or "SETUP_REFRESH_REQUIRED"
    end
    data.addonVersion = ns.version
    return data, migrated or "VALIDATED_COPY"
end
