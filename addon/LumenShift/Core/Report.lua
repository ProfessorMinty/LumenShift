local _, ns = ...
local D, V = {}, ns.Value
ns.Report = D
function D.Number(value)
    if V.Finite(value) then return tostring(value) end
    if V.Number(value) then return value end
    return value == nil and "unavailable" or "REDACTED_UNEXPECTED_VALUE"
end
local function bool(v) return v == true and "yes" or v == false and "no" or "unknown" end
local function safe(value) return ns.Log.Code(value or "UNKNOWN") end
local function call(reader, fn, ...)
    local result, code = ns.ReadOnly.Call(reader, fn, ...)
    if not result then return nil, code end
    return result
end
function D.Environment(runtime)
    local reader, result = runtime.reader, {}
    local env = reader.env
    local identity = ns.Compatibility.Inspect(reader)
    result.identity = identity
    local pixels, why = call(reader, env.GetPhysicalScreenSize)
    result.resolution = pixels and pixels.n == 2 and V.Finite(pixels[1]) and V.Finite(pixels[2])
        and (D.Number(pixels[1]) .. "x" .. D.Number(pixels[2])) or "unavailable:" .. (why or "UNEXPECTED_RESOLUTION")
    for _, method in ipairs({ "GetWidth", "GetHeight", "GetEffectiveScale" }) do
        local values, code = call(reader, env.UIParent and env.UIParent[method], env.UIParent)
        result[method] = values and values.n == 1 and V.Finite(values[1]) and D.Number(values[1]) or "unavailable:" .. (code or "UNEXPECTED_UI_RESULT")
    end
    local renderer = ns.ReadOnly.Read(reader, "gxapi")
    local token = renderer.raw and string.lower(renderer.raw)
    local known = { d3d11 = true, d3d12 = true, metal = true, vulkan = true, opengl = true, d3d11legacy = true }
    result.renderer = renderer.code == "OK" and known[token] and token or "unavailable:" .. (renderer.raw and "UNRECOGNIZED_RENDERER_REDACTED" or renderer.code)
    result.apis = ns.ReadOnly.Capabilities(reader)
    for _, name in ipairs({ "GetBuildInfo", "GetTime", "GetServerTime", "GetPhysicalScreenSize", "InCombatLockdown", "PlaySoundFile", "StopSound", "CreateFrame", "ReloadUI", "SetUIVisibility" }) do
        result.apis[name] = type(env[name]) == "function"
    end
    result.apis.C_Timer_After = type(env.C_Timer) == "table" and type(env.C_Timer.After) == "function"
    result.apis.Settings_canvas = type(env.Settings) == "table" and type(env.Settings.RegisterCanvasLayoutCategory) == "function"
    result.apis.IsGraphicsSettingValueSupported = type(env.IsGraphicsSettingValueSupported) == "function"
    for _, name in ipairs({ "IsSecondaryLightingSupported", "IsPBRWaterSupported" }) do
        local video = env.C_VideoOptions
        result.apis[name] = type(video) == "table" and type(video[name]) == "function"
    end
    local combat, code = call(reader, env.InCombatLockdown)
    result.combat = combat and combat.n == 1 and type(combat[1]) == "boolean" and bool(combat[1]) or "unknown:" .. (code or "UNEXPECTED_COMBAT_RESULT")
    return result
end
function D.Run(runtime, reason)
    local results = {}
    local function add(id, status, detail) results[#results + 1] = { id = id, status = status, detail = detail } end
    local environment = D.Environment(runtime)
    add("client-identity", not environment.identity.signature and "BLOCKED" or environment.identity.warning and "WARN" or "PASS", environment.identity.status)
    add("saved-data", runtime.db and "PASS" or "BLOCKED", runtime.storeStatus)
    add("configuration", runtime.db and ns.Profiles.Validate(runtime.db.config) and "PASS" or "FAIL", "strict-data-validation-no-import-execution")
    add("recovery-data", runtime.db and ns.Store.ValidateJournal(runtime.db.journal)
        and ns.ExperimentPolicy.Validate(runtime.db.experiments) and ns.NamePolicy.Validate(runtime.db.camera) and "PASS" or "BLOCKED", "schema-and-structure-only-not-disk-durability")
    add("native-setter", runtime.engine and runtime.engine.Status().setterAvailable and "PASS" or "BLOCKED", "availability-only-no-call")
    for _, name in ipairs({ "ReadOnly", "Catalog", "Planner", "Recovery", "WriteBoundary", "StudioConfig", "ExperimentPolicy", "Product", "Diagnostics", "Report", "DiagnosticWindow", "Setup", "EntryPoints" }) do
        add("module-" .. name, type(ns[name]) == "table" and "PASS" or "FAIL", type(ns[name]) == "table" and "loaded" or "MISSING_MODULE")
    end
    add("Studio", runtime.ui and runtime.ui.window and "PASS" or "BLOCKED", runtime.ui and "initialized-not-render-certified" or "UI_UNAVAILABLE")
    add("radial", runtime.ui and runtime.ui.radial and "PASS" or "BLOCKED", "initialization-only-input-acceptance-not-tested")
    for _, name in ipairs({ "GetCVar", "GetCVarDefault", "GetCVarInfo", "C_Timer_After" }) do
        add(name, environment.apis[name] and "PASS" or "BLOCKED", environment.apis[name] and "function-present" or "API_UNAVAILABLE")
    end
    for _, key in ipairs(ns.Catalog.WatchKeys()) do
        local item = ns.ReadOnly.Read(runtime.reader, key)
        add("read-" .. key, item.code == "OK" and "PASS" or "BLOCKED", item.code)
        if ns.ExperimentPolicy.Known(key) then
            local bounds, code = ns.ExperimentPolicy.Bounds(key, item.raw)
            local ready = ns.Planner.SafeObservation(item) and bounds ~= nil
            add("calibration-preflight-" .. key, ready and "PASS" or "BLOCKED",
                ready and "observation-and-test-policy-only-no-write" or item.code ~= "OK" and item.code or code or "RESTRICTED_OR_UNVERIFIED_FLAGS")
        end
    end
    local native = runtime.log and runtime.log.native
    for _, key in ipairs(ns.NamePolicy.Keys) do
        local item = ns.ReadOnly.Read(runtime.reader, key)
        add("read-" .. key, item.code == "OK" and "PASS" or "BLOCKED", item.code)
    end
    add("native-writes", native and native.rejected > 0 and "WARN" or native and native.accepted > 0 and "PASS" or "NOT TESTED",
        native and native.attempts > 0 and ("Session setter calls=" .. native.attempts .. "; accepted=" .. native.accepted
            .. "; rejected=" .. native.rejected .. "; verified Brightness transitions=" .. native.verified .. "; restorations=" .. native.restored)
        or "No native write recorded in this login. Diagnostic scans do not write.")
    add("visible-effects", "NOT TESTED", "Readbacks do not measure the rendered scene")
    add("texture-decoding", "NOT TESTED", "No arbitrary asset filesystem inspection API used; inspect visible icons")
    add("audio-playback", "NOT TESTED", "Use explicit Audio previews; no automatic playback")
    add("input-and-custom-UI", "NOT TESTED", "Interact with Studio and wheel; no synthetic clicks or key assignment")
    add("disk-persistence", "NOT TESTED", "No immediate durable-save guarantee; no automatic reload or crash test")
    add("unobserved-dependencies", "NOT TESTED", "Named watch list is not complete engine dependency enumeration")
    runtime.checks, runtime.environment = results, environment
    ns.Log.Record(runtime.reader, "diagnostics", "read-only-checks", "INFO", "COMPLETE", { count = #results, detail = reason or "user" })
    return results
end
local function eventLine(event)
    local parts = { "#" .. event.sequence, event.time and string.format("t=%.3f", event.time) or "time=unavailable",
        event.severity, event.subsystem .. "." .. event.operation, event.result }
    for _, key in ipairs(V.Keys(event.data)) do parts[#parts + 1] = key .. "=" .. tostring(event.data[key]) end
    return table.concat(parts, " | ")
end
function D.Build(runtime)
    local env = D.Environment(runtime)
    local identity = env.identity
    local version = identity.version and identity.version:match("^%d+%.%d+%.%d+$") and identity.version or "unavailable"
    local build = identity.build and identity.build:match("^%d+$") and identity.build or "unavailable"
    local date = identity.date
    if not date or not (date:match("^%a%a%a%s+%d%d?%s+%d%d%d%d$") or date:match("^%d%d%d%d%-%d%d%-%d%d$")) then date = "unavailable:UNRECOGNIZED_DATE_FORMAT" end
    local log = runtime.log
    local lines = { "LUMENSHIFT COMPLETE DIAGNOSTIC REPORT", "Format: 1 | privacy: numeric/allowlisted data only",
        "Addon: " .. ns.version .. " | build: " .. safe(ns.build), "Session: " .. (log and log.session or "unavailable"),
        "Session observations. The report reads settings; mode and Apply buttons change them.",
        "Excluded: character/account identifiers, chat, paths, credentials, preset names and raw native error text.",
        "", "1. ENVIRONMENT", "Client: " .. version .. " build " .. build .. " date " .. date .. " interface " .. D.Number(identity.interface),
        "Compatibility: " .. safe(identity.status), ns.Compatibility.Explain(identity), ns.Diagnostics.ControlStatus(runtime),
        "Physical resolution: " .. env.resolution,
        "UI units: " .. env.GetWidth .. " x " .. env.GetHeight .. " | effective scale: " .. env.GetEffectiveScale,
        "Renderer (gxapi): " .. env.renderer .. " | combat: " .. env.combat,
        "SavedVariables: " .. safe(runtime.storeStatus) .. " | supported schema=" .. ns.schemaVersion .. " | immediately durable: no", "", "2. CAPABILITIES" }
    for _, name in ipairs(V.Keys(env.apis)) do lines[#lines + 1] = name .. "=" .. bool(env.apis[name]) end
    lines[#lines + 1] = "3. CURRENT GRAPHICS VALUES (snapshot; defaults are not captured originals)"
    for _, key in ipairs(ns.Catalog.WatchKeys()) do
        local item = ns.ReadOnly.Read(runtime.reader, key)
        local original = runtime.db and (runtime.db.journal.entries[key] or runtime.db.experiments.journal.entries[key])
        lines[#lines + 1] = key .. ": current=" .. D.Number(item.raw) .. " [" .. safe(item.code) .. "] original=" .. D.Number(original and original.originalRaw)
            .. " requested=" .. D.Number(original and original.intendedRaw) .. " default=" .. D.Number(item.defaultRaw) .. " [" .. safe(item.defaultCode or item.code) .. "]"
        if item.flags then
            lines[#lines + 1] = "  flags secure=" .. bool(item.flags.secure) .. " readOnly=" .. bool(item.flags.readOnly) .. " locked=" .. bool(item.flags.locked)
                .. " serverAccount=" .. bool(item.flags.serverAccount) .. " serverCharacter=" .. bool(item.flags.serverCharacter)
        else lines[#lines + 1] = "  flags unavailable: " .. safe(item.flagsCode or item.code) end
        if ns.ExperimentPolicy.Known(key) then
            local bounds, reason = ns.ExperimentPolicy.Bounds(key, item.raw)
            lines[#lines + 1] = bounds and ("  experimental test policy: " .. bounds.min .. ".." .. bounds.max
                .. " step=" .. bounds.step .. " basis=" .. bounds.basis)
                or ("  test policy unavailable: " .. safe(reason))
            local certificates = runtime.lab and runtime.lab.certificates[key]
            lines[#lines + 1] = "  session-tested targets: " .. (certificates and table.concat(V.Keys(certificates), ", ")
                or "none; optional test has not run") .. " | native visual effect unverified"
        end
        local latest = log and log.latest[key]
        if latest then
            local details = {}
            for _, field in ipairs(V.Keys(latest)) do details[#details + 1] = field .. "=" .. tostring(latest[field]) end
            lines[#lines + 1] = "  last-event: " .. table.concat(details, "; ")
        end
    end
    lines[#lines + 1] = "4. ACTIVE CONFIGURATION (preset names excluded)"
    local db = runtime.db
    if db then
        for _, key in ipairs(ns.NamePolicy.Keys) do
            local item, original = ns.ReadOnly.Read(runtime.reader, key), db.camera.journal.entries[key]
            lines[#lines + 1] = key .. " current=" .. D.Number(item.raw) .. " [" .. safe(item.code) .. "] original=" .. D.Number(original and original.originalRaw)
                .. " secure=" .. bool(item.flags and item.flags.secure) .. " readOnly=" .. bool(item.flags and item.flags.readOnly)
                .. " locked=" .. bool(item.flags and item.flags.locked)
        end
        lines[#lines + 1] = "Camera: active=" .. bool(runtime.camera and runtime.camera.active) .. " interfaceVisible=" .. bool(runtime.camera and runtime.camera.Visible())
            .. " hideNamesWithUI=" .. bool(db.camera.hideWithUI)
        local config = db.config
        lines[#lines + 1] = "active visual presentation=" .. safe(runtime.product and runtime.product.active)
            .. " | last verified quality selection=" .. safe(runtime.lab and runtime.lab.activeProfile)
        lines[#lines + 1] = "mode-selection=explicit-user-action; saved-enable-flag=" .. bool(config.studio.enabled)
            .. " effects=" .. bool(config.studio.effects) .. " audio=" .. bool(config.preferences.sound) .. " reducedMotion=" .. bool(config.preferences.reducedMotion)
        lines[#lines + 1] = "setup wizard completed=" .. bool(db.onboarding.completed)
        for _, id in ipairs(ns.StudioConfig.Order) do
            local mode = config.studio.modes[id]
            lines[#lines + 1] = id .. ": brightness=" .. D.Number(mode.brightness) .. " contrast=" .. D.Number(mode.contrast)
                .. " contrastEnabled=" .. bool(mode.useContrast) .. " tint=" .. bool(mode.tintEnabled) .. " opacity=" .. D.Number(mode.opacity)
                .. " vignette=" .. D.Number(mode.vignette) .. " letterbox=" .. D.Number(mode.letterbox)
        end
        lines[#lines + 1] = "personal preset count=" .. #V.Keys(config.studio.presets)
        for _, id in ipairs({ "balanced", "vista", "performance" }) do
            local targets = {}; for _, key in ipairs(V.Keys(db.experiments.profiles[id])) do targets[#targets + 1] = key .. "=" .. D.Number(db.experiments.profiles[id][key]) end
            lines[#lines + 1] = "quality " .. id .. ": " .. (#targets > 0 and table.concat(targets, ", ") or "built-in bounded recipe")
        end
    else lines[#lines + 1] = "BLOCKED: quarantined saved data preserved, not exported" end
    lines[#lines + 1] = "5. TRANSACTIONS AND RECOVERY"
    for label, engine in pairs({ Brightness = runtime.engine, Experiments = runtime.lab, QualityTrial = runtime.tierTrial, Names = runtime.names }) do
        local status = engine.Status()
        lines[#lines + 1] = label .. ": state=" .. safe(status.state) .. " operation=" .. safe(status.operation) .. " error=" .. safe(status.error or "none")
            .. " original=" .. D.Number(status.original) .. " preview=" .. safe(status.token or "none")
        if status.preview then lines[#lines + 1] = "PREVIEW Brightness original=" .. D.Number(status.preview.original)
            .. " snapshot=" .. D.Number(status.preview.current) .. " target=" .. D.Number(status.preview.target) end
    end
    if db then
        for _, journal in ipairs({ db.journal, db.experiments.journal, db.camera.journal }) do
            for _, key in ipairs(V.Keys(journal.entries)) do
                local item = journal.entries[key]
                lines[#lines + 1] = "recovery " .. (ns.Catalog.Get(key) and key or "UNKNOWN_KEY_REDACTED") .. " original=" .. D.Number(item.originalRaw)
                    .. " lastVerified=" .. D.Number(item.lastVerifiedRaw) .. " intended=" .. D.Number(item.intendedRaw) .. " state=" .. safe(item.state)
                    .. " source-client=" .. safe(item.signature) .. " failure=" .. safe(item.failure or "none")
            end
        end
        for _, key in ipairs(V.Keys(db.experiments.sideEffects)) do
            local item = db.experiments.sideEffects[key]
            lines[#lines + 1] = (item.before == item.after and "Watched original " or "UNRESOLVED watched change ") .. key .. " before=" .. D.Number(item.before) .. " after=" .. D.Number(item.after) .. " (not automatically overwritten)"
        end
    end
    if runtime.lab and runtime.lab.preview then for _, line in ipairs(runtime.lab.preview.lines) do lines[#lines + 1] = "PREVIEW: " .. line end end
    lines[#lines + 1] = "6. DIAGNOSTIC CHECKS (refreshed on export; this scan applies no settings)"
    if not runtime.checks then lines[#lines + 1] = "NOT TESTED: Run Diagnostics has not completed" end
    local counts = { PASS = 0, WARN = 0, FAIL = 0, BLOCKED = 0, ["NOT TESTED"] = 0 }
    for _, check in ipairs(runtime.checks or {}) do
        counts[check.status] = counts[check.status] + 1
        lines[#lines + 1] = check.status .. " | " .. check.id .. " | " .. check.detail
    end
    lines[#lines + 1] = "7. FEATURE AVAILABILITY"
    lines[#lines + 1] = "Six visual modes: click a mode to apply; no acknowledgement or non-75 unlock. Source-range Brightness, no startup writes."
    lines[#lines + 1] = "Contrast and named quality: direct bounded Apply or optional Test & Restore. Previous calibration is not an unlock requirement."
    lines[#lines + 1] = "Quality profiles: bounded built-in recipes or saved custom target sets, rechecked on Apply. No measured FPS promises."
    lines[#lines + 1] = "Shadow/light/water: native enum and hardware-checked round-trip trials with named-watch restoration checks; not persistent tier profiles."
    for _, key in ipairs(ns.QualityTrial.Order) do
        local supported = {}
        for index in ipairs(ns.QualityTrial.Definition(key).choices) do
            local ready = ns.QualityTrial.Support(runtime.reader, key, index - 1)
            if ready then supported[#supported + 1] = tostring(index - 1) end
        end
        lines[#lines + 1] = key .. " supported trial levels=" .. (#supported > 0 and table.concat(supported, ",") or "none or capability unavailable")
    end
    lines[#lines + 1] = "Camera: native UI hide/show and two friendly-name toggles, separate captured originals; no lens, zoom or motion CVars."
    lines[#lines + 1] = "Not controlled: HDR, renderer and overall/raid quality. Use the game's settings for restart-dependent options."
    lines[#lines + 1] = "Readback does not establish visible effect, universal safe range, or absence of unobserved dependent changes. Session test history is observational, not permission."
    lines[#lines + 1] = "Addon-owned handlers only. Pre-bootstrap syntax/load failures and unrelated game/addon errors may prevent or lie outside this report."
    lines[#lines + 1] = "8. RECENT WARNINGS / ERRORS (last 32, may overlap history)"
    for _, event in ipairs(log and log.issues or {}) do lines[#lines + 1] = eventLine(event) end
    lines[#lines + 1] = "9. CHRONOLOGICAL SESSION HISTORY (last 240; dropped=" .. (log and log.dropped or 0) .. "; slider edits coalesced=" .. (log and log.coalesced or 0) .. ")"
    for _, event in ipairs(log and log.History() or {}) do lines[#lines + 1] = eventLine(event) end
    lines[#lines + 1] = "10. SUMMARY"
    lines[#lines + 1] = "Diagnostic checks: PASS=" .. counts.PASS .. " WARN=" .. counts.WARN .. " FAIL=" .. counts.FAIL .. " BLOCKED=" .. counts.BLOCKED .. " NOT TESTED=" .. counts["NOT TESTED"]
    lines[#lines + 1] = "Session events: WARN=" .. (log and log.counts.WARN or 0) .. " ERROR=" .. (log and log.counts.ERROR or 0)
    lines[#lines + 1] = "If recovery records or watched changes remain, preserve this report and resolve them before uninstalling."
    lines[#lines + 1] = "END LUMENSHIFT REPORT"
    return table.concat(lines, "\n")
end
function D.Export(runtime)
    ns.Log.Record(runtime.reader, "diagnostics", "export", "INFO", "USER_REQUEST")
    local ok, text = pcall(function()
        D.Run(runtime, "export-read-only")
        return D.Build(runtime)
    end)
    if not ok then
        ns.Log.Record(runtime.reader, "diagnostics", "export", "ERROR", "REPORT_GENERATION_FAILED")
        text = "LUMENSHIFT REPORT GENERATION FAILED\nAddon " .. ns.version .. " build " .. safe(ns.build)
            .. "\nSaved recovery data was not cleared. No graphics write was requested.\nNative error details withheld for privacy."
    end
    if #text > 120000 then text = text:sub(1, 119800) .. "\nREPORT SIZE LIMIT REACHED; some history omitted. END REPORT" end
    return text
end
