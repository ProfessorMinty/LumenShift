local _, ns = ...
local B, V = {}, ns.Value
ns.Baseline = B
local keys = { "Brightness", "Contrast" }
function B.Defaults()
    return { source = "current", chosen = false, values = {}, signature = "unavailable", includeOptics = false }
end
function B.Validate(data)
    if not V.Fields(data, { source = true, chosen = true, values = true, signature = true, includeOptics = true })
        or (data.source ~= "current" and data.source ~= "gameDefaults") or type(data.chosen) ~= "boolean"
        or type(data.includeOptics) ~= "boolean" or not V.Raw(data.signature)
        or not ns.Optics.RawMap(data.values) then return false end
    for key, raw in pairs(data.values) do
        local value = V.Number(raw)
        if not value or value < 0 or value > 100 then return false end
        if ns.Optics.Known(key) and not data.includeOptics then return false end
    end
    return true
end
function B.Capture(runtime, source, includeOptics)
    if source ~= "current" and source ~= "gameDefaults" then return nil, "INVALID_BASELINE_SOURCE" end
    local data = B.Defaults(); data.source, data.chosen = source, true
    data.includeOptics = includeOptics == true
    data.signature = ns.Compatibility.Inspect(runtime.reader).signature or "unavailable"
    local missing = {}
    local captureKeys = V.Copy(keys)
    if data.includeOptics then for _, key in ipairs(ns.Optics.Keys) do captureKeys[#captureKeys + 1] = key end end
    for _, key in ipairs(captureKeys) do
        local item = ns.ReadOnly.Read(runtime.reader, key)
        local raw
        if source == "gameDefaults" then
            if item.defaultCode == "OK" then raw = item.defaultRaw end
        else
            -- Reopening setup while a mode is active must not capture its target.
            -- Historical recovery originals take precedence over temporary values.
            local journal = key == "Brightness" and runtime.db.journal or runtime.db.experiments.journal
            local entry = journal.entries[key]
            if entry then raw = entry.originalRaw
            elseif item.code == "OK" then raw = item.raw end
        end
        local number = V.Number(raw)
        if number and ns.Optics.RawMap({ [key] = raw }) then data.values[key] = raw
        else missing[#missing + 1] = key end
    end
    return data, missing
end
function B.Label(data)
    return data and data.source == "gameDefaults" and "Game Defaults" or "Original"
end
function B.CompleteMissing(runtime)
    local data = runtime.db.baseline
    if not data.chosen or (data.values.Brightness and data.values.Contrast) then return end
    local fresh = B.Capture(runtime, data.source, data.includeOptics)
    for _, key in ipairs(keys) do
        if not data.values[key] and fresh.values[key] then
            data.values[key] = fresh.values[key]
            if data.signature ~= fresh.signature then data.signature = "mixed-capture-sessions" end
        end
    end
end
function B.Summary(data)
    return B.Label(data) .. " — Brightness " .. (data.values.Brightness or "unavailable")
        .. " / Contrast " .. (data.values.Contrast or "unavailable")
end
-- A selected home look is a preference, never a replacement recovery journal.
-- Omit a target matching the recovery original to take the exact release path.
function B.Target(runtime, key)
    local data = runtime.db.baseline
    if not data.chosen then return nil end -- compatibility before the user chooses
    local raw = data.values[key]
    if not raw then return nil, "BASELINE_VALUE_UNAVAILABLE:" .. key end
    local journal = key == "Brightness" and runtime.db.journal or runtime.db.experiments.journal
    local entry = journal.entries[key]
    if entry and V.Number(entry.originalRaw) == V.Number(raw) then return nil end
    if not entry then
        local current = ns.ReadOnly.Read(runtime.reader, key)
        if ns.Planner.SafeObservation(current) and V.Number(current.raw) == V.Number(raw) then return nil end
    end
    return V.Number(raw)
end
