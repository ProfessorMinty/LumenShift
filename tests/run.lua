-- Run from repository root with Lua 5.1, or tools/check.py's optional Lupa runner.
local files = {}
for line in io.lines("addon/LumenShift/LumenShift.toc") do
    if line:match("%.lua$") then files[#files + 1] = line end
end
local passed, failed = 0, 0
local function eq(actual, expected)
    assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1; print("PASS " .. name)
    else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end

local function fixture(saved)
    local writes, sounds, output, frames = 0, 0, {}, {}
    local env = setmetatable({}, { __index = _G })
    env._G, env.LumenShiftDB, env.SlashCmdList = env, saved, {}
    env.canaccessvalue = function(v) return v ~= "SECRET" end
    env.issecretvalue = function(v) return v == "SECRET" end
    env.GetBuildInfo = function() return "1.60.1", "70790", "Nov 4 2026", 16001 end
    local values = { Brightness = "52", Contrast = "60" }
    env.C_CVar = {
        AreCVarsLoaded = function() return true end,
        GetCVar = function(k) return values[k] end,
        GetCVarDefault = function() return "50" end,
        GetCVarInfo = function(k) return values[k], "50", false, false, false, false, false end,
    }
    for _, name in ipairs({ "SetCVar", "SetCVarBitfield", "SetTempCVar", "RemoveTempCVar",
        "RegisterCVar", "ResetTestCVars", "ConsoleExec", "SetDefaultVideoOptions",
        "SetVideoOptions", "SetGraphicsQuality", "ResetAllCvars" }) do
        local function forbidden() writes = writes + 1; error("FORBIDDEN_WRITER") end
        env[name], env.C_CVar[name] = forbidden, forbidden
    end
    env.PlaySound = function() sounds = sounds + 1 end
    env.PlaySoundFile = env.PlaySound
    env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) output[#output + 1] = text end }
    env.CreateFrame = function()
        local frame = { events = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:SetScript(name, fn) self[name] = fn end
        frames[#frames + 1] = frame
        return frame
    end
    local ns = {}
    for _, file in ipairs(files) do
        local chunk
        if setfenv then chunk = assert(loadfile("addon/LumenShift/" .. file)); setfenv(chunk, env)
        else chunk = assert(loadfile("addon/LumenShift/" .. file, "t", env)) end
        chunk("LumenShift", ns)
    end
    local f = { ns = ns, env = env, values = values, output = output, frame = frames[1] }
    function f.load() f.frame.OnEvent(f.frame, "ADDON_LOADED", "LumenShift") end
    function f.zero() eq(writes, 0); eq(sounds, 0) end
    return f
end

local function observation(raw)
    return { raw = raw, code = "OK", flagsCode = "OK", flags = {
        secure = false, readOnly = false, locked = false, serverAccount = false, serverCharacter = false } }
end
local context = { verified = true, rendererVerified = true, signature = "MOCK:1:1", renderer = "MOCK" }
local function catalog()
    local result = {}
    for _, key in ipairs({ "Brightness", "Contrast", "MockExposure", "MockDetail" }) do
        result[key] = { admitted = true, evidence = "VERIFIED_CLIENT", signature = "MOCK:1:1",
            renderer = "MOCK", scope = "client", kind = "number", min = 0, max = 100,
            settle = "immediate_verified", version = 1, numericEquivalent = true,
            layer = key == "MockDetail" and "quality" or "visual", dependencies = {}, conflicts = {} }
    end
    return result
end
local function observations(brightness)
    return { Brightness = observation(brightness or "52"), Contrast = observation("60"),
        MockExposure = observation("20"), MockDetail = observation("40") }
end
local function plan(ns, journal, seen, layer, targets, cat)
    local result, err = ns.Planner.Build(cat or catalog(), context, seen, journal, layer, targets)
    assert(result, err)
    return result
end
local function simulate(ns, journal, proposed, seen, priorState)
    local tx = assert(ns.Recovery.Begin(journal, proposed, 1, priorState or "BASELINE"))
    for i, op in ipairs(proposed.operations) do
        if op.write then
            tx = assert(ns.Recovery.Before(tx, 1, i, seen[op.key], false))
            eq(tx.pendingIndex, i)
            -- Only this test harness changes an in-memory fixture. No native API call.
            seen[op.key] = observation(op.targetRaw)
            tx = assert(ns.Recovery.Observe(tx, 1, i, true, seen[op.key].raw))
        else tx = assert(ns.Recovery.ReleaseObserved(tx, 1, i, seen[op.key], false)) end
    end
    return assert(ns.Recovery.Verify(tx, 1, seen))
end
local function compensate(ns, tx, seen)
    tx = assert(ns.Recovery.RollbackPlan(tx, seen))
    for _, op in ipairs(tx.rollback) do
        tx = assert(ns.Recovery.BeforeRollback(tx, tx.id, op.key, seen[op.key], false))
        if tx.pendingRollback then
            seen[op.key] = observation(op.targetRaw)
            tx = assert(ns.Recovery.ResolveRollback(tx, tx.id, op.key, true, op.targetRaw))
        end
    end
    return assert(ns.Recovery.FinishRollback(tx))
end

test("M01 startup, own ADDON_LOADED, diagnostics, reconnect have no writers/sounds", function()
    local f = fixture()
    eq(f.env.LumenShiftDB, nil)
    f.frame.OnEvent(f.frame, "ADDON_LOADED", "AnotherAddon")
    eq(f.env.LumenShiftDB, nil)
    f.load()
    eq(f.env.SLASH_LUMENSHIFT1, "/lumenshift"); eq(f.env.SLASH_LUMENSHIFT2, "/ls")
    f.env.SlashCmdList.LUMENSHIFT("set Brightness 75")
    assert(table.concat(f.output, "\n"):find("Brightness: 52", 1, true))
    local db = f.env.LumenShiftDB
    f.load(); eq(f.env.LumenShiftDB, db); f.zero()
    local reconnect = fixture(db); reconnect.load(); reconnect.env.SlashCmdList.LUMENSHIFT(); reconnect.zero()
end)

test("M02 exact originals 45, 52, and 052.00 survive mode switches and release", function()
    local ns = fixture().ns
    for _, original in ipairs({ "45", "52", "052.00" }) do
        local seen, journal = observations(original), ns.Store.EmptyJournal()
        local first = simulate(ns, journal, plan(ns, journal, seen, "visual", { Brightness = 75 }), seen)
        eq(first.journal.entries.Brightness.originalRaw, original)
        local second = simulate(ns, first.journal, plan(ns, first.journal, seen, "visual", { Brightness = 80 }), seen, "ACTIVE")
        eq(second.journal.entries.Brightness.originalRaw, original)
        local restored = simulate(ns, second.journal, plan(ns, second.journal, seen, "visual", {}), seen, "ACTIVE")
        eq(seen.Brightness.raw, original); eq(next(restored.journal.entries), nil)
        eq(next(journal.entries), nil) -- pure functions did not mutate their inputs
    end
end)

test("M03 equivalent current target grants no ownership or operation", function()
    local ns = fixture().ns
    local p = plan(ns, ns.Store.EmptyJournal(), observations("75.0"), "visual", { Brightness = 75 })
    eq(#p.operations, 0); eq(p.nextEpoch, 1)
end)

test("M04 visual and quality operations remain independent both directions", function()
    local ns, seen = fixture().ns, observations()
    local journal = ns.Store.EmptyJournal()
    local q = simulate(ns, journal, plan(ns, journal, seen, "quality", { MockDetail = 90 }), seen)
    local vp = plan(ns, q.journal, seen, "visual", { Brightness = 75 })
    eq(#vp.operations, 1); eq(vp.operations[1].key, "Brightness")
    local v = simulate(ns, q.journal, vp, seen, "ACTIVE")
    local qp = plan(ns, v.journal, seen, "quality", {})
    eq(#qp.operations, 1); eq(qp.operations[1].key, "MockDetail")
    local restored = simulate(ns, v.journal, qp, seen, "ACTIVE")
    eq(restored.journal.entries.Brightness.originalRaw, "52"); eq(seen.Brightness.raw, "75")
    local defs = ns.Profiles.Definitions()
    eq(#ns.Value.Keys(defs.visual), 6); eq(#ns.Value.Keys(defs.quality), 4)
    for _, layer in pairs(defs) do for _, preset in pairs(layer) do
        eq(preset.enabled, false); eq(next(preset.targets), nil)
    end end
end)

test("M05 missing APIs, nil/false/error/secret/unexpected results report safely", function()
    local modifications = {
        function(f) f.env.C_CVar = nil end,
        function(f) f.env.C_CVar.GetCVar = nil end,
        function(f) f.env.C_CVar.GetCVar = function() return nil end end,
        function(f) f.env.C_CVar.GetCVar = function() return false end end,
        function(f) f.env.C_CVar.GetCVar = function() error("private native detail") end end,
        function(f) f.env.C_CVar.GetCVar = function() return "SECRET" end end,
        function(f) f.env.C_CVar.GetCVar = function() return {} end end,
        function(f) f.env.C_CVar.AreCVarsLoaded = function() return false end end,
        function(f) f.env.C_CVar.AreCVarsLoaded = function() return nil end end,
        function(f) f.env.canaccessvalue = nil; f.env.issecretvalue = nil end,
    }
    for _, change in ipairs(modifications) do
        local f = fixture(); change(f); f.load()
        local result = f.ns.ReadOnly.Read(f.ns.runtime.reader, "Brightness")
        assert(result.code ~= "OK")
        f.env.SlashCmdList.LUMENSHIFT(); f.zero()
        local text = table.concat(f.output, "\n")
        assert(not text:find("SECRET", 1, true)); assert(not text:find("private native detail", 1, true))
    end
end)

test("M05 restrictions, missing flags and unstable getter values are explicit", function()
    local f = fixture(); f.load()
    f.env.C_CVar.GetCVarInfo = function() return "53", "50", false, false, false, true, true end
    local item = f.ns.ReadOnly.Read(f.ns.runtime.reader, "Brightness")
    eq(item.code, "READ_DRIFT"); eq(item.flags.secure, true); eq(item.flags.readOnly, true)
    for _, flag in ipairs({ "secure", "readOnly", "locked" }) do
        local seen = observations(); seen.Brightness.flags[flag] = true
        eq(f.ns.Planner.Build(catalog(), context, seen, f.ns.Store.EmptyJournal(), "visual", { Brightness = 75 }), nil)
    end
    f.env.C_CVar.GetCVarInfo = function() return "52" end
    eq(f.ns.ReadOnly.Read(f.ns.runtime.reader, "Brightness").flagsCode, "UNEXPECTED_INFO")
    eq(f.ns.ReadOnly.Read(f.ns.runtime.reader, "Unknown").code, "UNKNOWN_KEY"); f.zero()
end)

test("M06 invalid targets and data never enter a plan or execute code", function()
    local ns = fixture().ns
    for _, target in ipairs({ 0/0, math.huge, -math.huge, "75", "print('payload')", {}, true, -1, 101 }) do
        eq(ns.Planner.Build(catalog(), context, observations(), ns.Store.EmptyJournal(), "visual", { Brightness = target }), nil)
    end
    eq(ns.Planner.Build(catalog(), context, observations(), ns.Store.EmptyJournal(), "visual", { Unknown = 75 }), nil)
    eq(ns.Planner.Build(catalog(), context, {}, ns.Store.EmptyJournal(), "visual", { Brightness = 75 }), nil)
    local ran = false
    eq(ns.Store.Open({ schemaVersion = 1, execute = function() ran = true end }), nil); eq(ran, false)
end)

test("M07 success/no-op, clamps, and errors after change require compensation", function()
    local ns = fixture().ns
    for _, scenario in ipairs({ { true, "52" }, { true, "70" }, { false, "75" }, { false, false } }) do
        local seen, journal = observations(), ns.Store.EmptyJournal()
        local tx = assert(ns.Recovery.Begin(journal, plan(ns, journal, seen, "visual", { Brightness = 75 }), 1, "BASELINE"))
        tx = assert(ns.Recovery.Before(tx, 1, 1, seen.Brightness, false))
        tx = assert(ns.Recovery.Observe(tx, 1, 1, scenario[1], scenario[2]))
        eq(tx.state, "ROLLING_BACK")
        seen.Brightness = observation(scenario[2])
        tx = compensate(ns, tx, seen)
        if scenario[2] == false then
            eq(tx.state, "PARTIAL_ERROR"); eq(tx.journal.entries.Brightness.originalRaw, "52")
        else eq(tx.state, "BASELINE"); eq(seen.Brightness.raw, "52") end
    end
end)

test("M08 every multikey failure rolls back in reverse to previous active values", function()
    local ns = fixture().ns
    for failureIndex = 1, 3 do
        local seen, journal = observations(), ns.Store.EmptyJournal()
        local active = simulate(ns, journal, plan(ns, journal, seen, "visual", { Brightness = 75, Contrast = 65, MockExposure = 30 }), seen)
        local p = plan(ns, active.journal, seen, "visual", { Brightness = 80, Contrast = 70, MockExposure = 40 })
        local tx = assert(ns.Recovery.Begin(active.journal, p, 2, "ACTIVE"))
        for i = 1, failureIndex do
            local op = p.operations[i]
            tx = assert(ns.Recovery.Before(tx, 2, i, seen[op.key], false))
            seen[op.key] = observation(op.targetRaw)
            tx = assert(ns.Recovery.Observe(tx, 2, i, i ~= failureIndex, op.targetRaw))
        end
        local rollback = assert(ns.Recovery.RollbackPlan(tx, seen))
        eq(rollback.rollback[1].key, p.operations[failureIndex].key)
        tx = compensate(ns, tx, seen)
        eq(tx.state, "ACTIVE"); eq(seen.Brightness.raw, "75"); eq(seen.Contrast.raw, "65")
        eq(tx.journal.entries.Brightness.originalRaw, "52")
    end
end)

test("M09 failed compensation retains baseline and partial error", function()
    local ns, seen = fixture().ns, observations()
    local journal = ns.Store.EmptyJournal()
    local tx = assert(ns.Recovery.Begin(journal, plan(ns, journal, seen, "visual", { Brightness = 75 }), 1, "BASELINE"))
    tx = assert(ns.Recovery.Before(tx, 1, 1, seen.Brightness, false))
    tx = assert(ns.Recovery.Observe(tx, 1, 1, false, "75")); seen.Brightness = observation("75")
    tx = assert(ns.Recovery.RollbackPlan(tx, seen))
    tx = assert(ns.Recovery.BeforeRollback(tx, 1, "Brightness", seen.Brightness, false))
    tx = assert(ns.Recovery.ResolveRollback(tx, 1, "Brightness", false, "75"))
    tx = assert(ns.Recovery.FinishRollback(tx))
    eq(tx.state, "PARTIAL_ERROR"); eq(tx.journal.entries.Brightness.originalRaw, "52")
    assert(ns.Store.ValidateJournal(tx.journal))
end)

test("M10 external drift at preflight, before operation and restore is preserved", function()
    local ns, seen = fixture().ns, observations()
    local journal = ns.Store.EmptyJournal()
    local active = simulate(ns, journal, plan(ns, journal, seen, "visual", { Brightness = 75 }), seen)
    seen.Brightness = observation("63")
    eq(ns.Planner.Build(catalog(), context, seen, active.journal, "visual", {}), nil)
    seen.Brightness = observation("75")
    local p = plan(ns, active.journal, seen, "visual", {})
    local tx = assert(ns.Recovery.Begin(active.journal, p, 1, "ACTIVE"))
    tx = assert(ns.Recovery.Before(tx, 1, 1, observation("63"), false))
    eq(tx.pendingIndex, nil); eq(tx.reason, "EXTERNAL_CONFLICT")
    local conflicted = assert(ns.Recovery.RollbackPlan(tx, { Brightness = observation("63") }))
    eq(ns.Recovery.FinishRollback(conflicted).state, "PARTIAL_ERROR")
    eq(conflicted.journal.entries.Brightness.state, "conflict")
    eq(active.journal.entries.Brightness.originalRaw, "52")
    tx = assert(ns.Recovery.Begin(active.journal, p, 2, "ACTIVE"))
    tx = assert(ns.Recovery.Before(tx, 2, 1, observation("75"), false))
    tx = assert(ns.Recovery.Observe(tx, 2, 1, false, "52"))
    seen.Brightness = observation("63")
    tx = assert(ns.Recovery.RollbackPlan(tx, seen))
    eq(#tx.rollback, 0); eq(tx.unresolved.Brightness, "CONFLICT_OR_UNREADABLE")
    eq(ns.Recovery.FinishRollback(tx).state, "PARTIAL_ERROR"); eq(seen.Brightness.raw, "63")
end)

test("M10 fresh compensation read rejects drift, restrictions and wrong order", function()
    local ns, seen = fixture().ns, observations()
    local j = ns.Store.EmptyJournal()
    local p = plan(ns, j, seen, "visual", { Brightness = 75, Contrast = 70 })
    local tx = assert(ns.Recovery.Begin(j, p, 1, "BASELINE"))
    for i, op in ipairs(p.operations) do
        tx = assert(ns.Recovery.Before(tx, 1, i, seen[op.key], false))
        tx = assert(ns.Recovery.Observe(tx, 1, i, i == 1, op.targetRaw)); seen[op.key] = observation(op.targetRaw)
    end
    tx = assert(ns.Recovery.RollbackPlan(tx, seen))
    eq(ns.Recovery.BeforeRollback(tx, 1, "Brightness", seen.Brightness, false), nil)
    tx = assert(ns.Recovery.BeforeRollback(tx, 1, "Contrast", observation("63"), false))
    eq(tx.pendingRollback, nil); eq(tx.journal.entries.Contrast.state, "conflict")
    tx = assert(ns.Recovery.BeforeRollback(tx, 1, "Brightness", seen.Brightness, true))
    eq(tx.pendingRollback, nil); eq(ns.Recovery.FinishRollback(tx).state, "PARTIAL_ERROR")
end)

test("M11 notifications coalesce without apply or trusting payloads", function()
    local f = fixture(); f.load()
    local model = f.ns.Controller.New("APPLYING")
    for _ = 1, 1000 do
        model = assert(f.ns.Controller.Reduce(model, "observation", 0))
        f.frame.OnEvent(f.frame, "CVAR_UPDATE", "Brightness", "SECRET")
    end
    eq(model.observationsPending, true); eq(model.state, "APPLYING")
    eq(f.ns.Controller.Reduce(model, "preview", 0), nil)
    eq(f.ns.ReadOnly.Read(f.ns.runtime.reader, "Brightness").raw, "52"); f.zero()
end)

test("M12 stale callbacks, duplicate observations and busy requests are refused", function()
    local ns = fixture().ns
    local m = assert(ns.Controller.Reduce(ns.Controller.New("BASELINE"), "preview", 0))
    eq(m.token, 1)
    m = assert(ns.Controller.Reduce(m, "cancel", 1)); eq(m.token, 2)
    eq(ns.Controller.Reduce(m, "simulate", 1), nil)
    local seen, j = observations(), ns.Store.EmptyJournal()
    local tx = assert(ns.Recovery.Begin(j, plan(ns, j, seen, "visual", { Brightness = 75 }), 8, "BASELINE"))
    eq(ns.Recovery.Before(tx, 7, 1, seen.Brightness, false), nil)
    tx = assert(ns.Recovery.Before(tx, 8, 1, seen.Brightness, false))
    eq(ns.Recovery.Before(tx, 8, 1, seen.Brightness, false), nil)
    eq(ns.Recovery.Observe(tx, 7, 1, true, "75"), nil)
    tx = assert(ns.Recovery.Observe(tx, 8, 1, true, "75"))
    eq(ns.Recovery.Observe(tx, 8, 1, true, "75"), nil)
    seen.Brightness = observation("63")
    eq(ns.Recovery.Inspect(tx.journal, seen, context.signature).entries.Brightness, "EXTERNAL_CONFLICT")
end)

test("M13 combat between plan and operation defers without automatic retry", function()
    local ns, seen = fixture().ns, observations()
    local j = ns.Store.EmptyJournal()
    local tx = assert(ns.Recovery.Begin(j, plan(ns, j, seen, "visual", { Brightness = 75 }), 1, "BASELINE"))
    tx = assert(ns.Recovery.Before(tx, 1, 1, seen.Brightness, true))
    eq(tx.state, "DEFERRED"); eq(#tx.attempts, 0)
    eq(ns.Recovery.Before(tx, 1, 1, seen.Brightness, false), nil)
    eq(ns.Controller.Reduce(ns.Controller.New("DEFERRED"), "combatEnded", 0), nil)
end)

test("M14 reload/character startup retains unresolved records without recapture", function()
    local f = fixture(); f.load()
    local seen, ns = observations(), f.ns
    local tx = simulate(ns, ns.Store.EmptyJournal(), plan(ns, ns.Store.EmptyJournal(), seen, "visual", { Brightness = 75 }), seen)
    f.env.LumenShiftDB.journal = tx.journal
    for _ = 1, 2 do
        local reload = fixture(f.env.LumenShiftDB); reload.values.Brightness = "75"; reload.load()
        eq(reload.ns.runtime.controller.state, "RECOVERY")
        eq(reload.env.LumenShiftDB.journal.entries.Brightness.originalRaw, "52")
        reload.env.SlashCmdList.LUMENSHIFT(); reload.zero()
    end
    local crash = fixture(nil); crash.values.Brightness = "75"; crash.load()
    eq(next(crash.env.LumenShiftDB.journal.entries), nil); crash.zero()
end)

test("M15 corrupt, old, future, executable, cyclic, oversized schemas preserved", function()
    local cyclic = {}; cyclic.self = cyclic
    local bad = { { schemaVersion = 0, recovery = "retain" }, { schemaVersion = 2, recovery = "retain" },
        { schemaVersion = 1 }, cyclic, { payload = string.rep("x", 257) },
        setmetatable({}, { __index = function() error("must not run") end }),
        setmetatable({}, { __metatable = false }) }
    for _, raw in ipairs(bad) do
        local f = fixture(raw); f.load()
        eq(f.env.LumenShiftDB, raw); eq(f.ns.runtime.db, nil)
        f.env.SlashCmdList.LUMENSHIFT(); f.zero()
    end
    local f = fixture(); f.load()
    local raw = f.env.LumenShiftDB
    raw.config.custom.visual.unknown = { targets = { Brightness = 75 } }
    local other = fixture(raw); other.load(); eq(other.env.LumenShiftDB, raw); eq(other.ns.runtime.db, nil)
end)

test("M16 layer overlap, tier/child conflicts, dependency closure and cycles refused", function()
    local ns, cat, j, seen = fixture().ns, catalog(), fixture().ns.Store.EmptyJournal(), observations()
    eq(ns.Planner.Build(cat, context, seen, j, "visual", { MockDetail = 50 }), nil)
    cat.Brightness.conflicts = { "Contrast" }
    eq(ns.Planner.Build(cat, context, seen, j, "visual", { Brightness = 75, Contrast = 70 }), nil)
    cat = catalog(); cat.Brightness.dependencies = { "Contrast" }
    eq(ns.Planner.Build(cat, context, seen, j, "visual", { Brightness = 75 }), nil)
    local p = plan(ns, j, seen, "visual", { Brightness = 75, Contrast = 70 }, cat)
    eq(p.operations[1].key, "Contrast")
    cat.Contrast.dependencies = { "Brightness" }
    eq(ns.Planner.Build(cat, context, seen, j, "visual", { Brightness = 75, Contrast = 70 }), nil)
end)

test("M17 unknown build/interface/renderer and shipped catalog cannot admit writes", function()
    local f = fixture(); f.load()
    eq(f.ns.runtime.identity.status, "FOREVER_CANDIDATE_UNVERIFIED")
    eq(f.ns.runtime.identity.futureWrites, false)
    for _, tuple in ipairs({ { "1.60.1", "70791", 16001 }, { "1.60.1", "70790", 99999 }, { "12.0.0", "70790", 16001 } }) do
        f.env.GetBuildInfo = function() return tuple[1], tuple[2], "date", tuple[3] end
        eq(f.ns.Compatibility.Inspect(f.ns.runtime.reader).status, "UNSUPPORTED_BUILD")
        eq(f.ns.Compatibility.Inspect(f.ns.runtime.reader).futureWrites, false)
    end
    local ctx = f.ns.Value.Copy(context); ctx.renderer = "OTHER"
    eq(f.ns.Planner.Build(catalog(), ctx, observations(), f.ns.Store.EmptyJournal(), "visual", { Brightness = 75 }), nil)
    eq(f.ns.Planner.Build(f.ns.Catalog.Snapshot(), context, observations(), f.ns.Store.EmptyJournal(), "visual", { Brightness = 75 }), nil)
    local result, code = f.ns.Controller.Apply({ enable = true }); eq(result, nil); eq(code, "PHASE_01A_READ_ONLY"); f.zero()
end)

test("Generated plans preserve baseline and layer ownership for 101 starting values", function()
    local ns = fixture().ns
    for original = 0, 100 do
        local seen, j = observations(tostring(original)), ns.Store.EmptyJournal()
        local p = plan(ns, j, seen, "visual", { Brightness = 75 })
        if original == 75 then eq(#p.operations, 0)
        else
            eq(#p.operations, 1); eq(p.operations[1].beforeRaw, tostring(original))
            local active = simulate(ns, j, p, seen)
            local restored = simulate(ns, active.journal, plan(ns, active.journal, seen, "visual", {}), seen, "ACTIVE")
            eq(seen.Brightness.raw, tostring(original)); eq(seen.MockDetail.raw, "40")
            eq(next(restored.journal.entries), nil)
        end
    end
end)

test("Same-value/ABA limitation is visible, never claimed as writer attribution", function()
    local ns, seen = fixture().ns, observations()
    local j = ns.Store.EmptyJournal()
    local tx = simulate(ns, j, plan(ns, j, seen, "visual", { Brightness = 75 }), seen)
    seen.Brightness = observation("63"); seen.Brightness = observation("75")
    eq(ns.Recovery.Inspect(tx.journal, seen, context.signature).entries.Brightness, "MATCHING_UNVERIFIED_OWNERSHIP")
end)

test("M07 normalized target readback retains raw baseline and exact last observation", function()
    local ns, seen = fixture().ns, observations("052.00")
    local j = ns.Store.EmptyJournal()
    local tx = assert(ns.Recovery.Begin(j, plan(ns, j, seen, "visual", { Brightness = 75 }), 1, "BASELINE"))
    tx = assert(ns.Recovery.Before(tx, 1, 1, seen.Brightness, false))
    tx = assert(ns.Recovery.Observe(tx, 1, 1, true, "75.0"))
    eq(tx.state, "AWAITING_VERIFICATION")
    seen.Brightness = observation("75.0")
    tx = assert(ns.Recovery.Verify(tx, 1, seen))
    eq(tx.state, "VERIFIED"); eq(tx.journal.entries.Brightness.originalRaw, "052.00")
    eq(tx.journal.entries.Brightness.lastVerifiedRaw, "75.0")
    eq(plan(ns, tx.journal, seen, "visual", {}).operations[1].targetRaw, "052.00")
end)

test("M12 final verification detects earlier-key drift before success", function()
    local ns, seen = fixture().ns, observations()
    local j = ns.Store.EmptyJournal()
    local p = plan(ns, j, seen, "visual", { Brightness = 75, Contrast = 70 })
    local tx = assert(ns.Recovery.Begin(j, p, 1, "BASELINE"))
    for i, op in ipairs(p.operations) do
        tx = assert(ns.Recovery.Before(tx, 1, i, seen[op.key], false))
        tx = assert(ns.Recovery.Observe(tx, 1, i, true, op.targetRaw)); seen[op.key] = observation(op.targetRaw)
    end
    eq(tx.state, "AWAITING_VERIFICATION")
    seen.Brightness = observation("63")
    eq(ns.Recovery.Verify(tx, 0, seen), nil)
    tx = assert(ns.Recovery.Verify(tx, 1, seen)); eq(tx.state, "ROLLING_BACK")
    tx = compensate(ns, tx, seen)
    eq(tx.state, "PARTIAL_ERROR"); eq(seen.Brightness.raw, "63"); eq(seen.Contrast.raw, "60")
    eq(tx.journal.entries.Brightness.originalRaw, "52")
end)

test("M13 restriction after first operation requires rollback and fresh permission", function()
    local ns, seen = fixture().ns, observations()
    local j = ns.Store.EmptyJournal()
    local p = plan(ns, j, seen, "visual", { Brightness = 75, Contrast = 70 })
    local tx = assert(ns.Recovery.Begin(j, p, 1, "BASELINE"))
    tx = assert(ns.Recovery.Before(tx, 1, 1, seen.Brightness, false))
    tx = assert(ns.Recovery.Observe(tx, 1, 1, true, "75")); seen.Brightness = observation("75")
    tx = assert(ns.Recovery.Before(tx, 1, 2, seen.Contrast, true))
    eq(tx.state, "ROLLING_BACK")
    tx = assert(ns.Recovery.RollbackPlan(tx, seen))
    tx = assert(ns.Recovery.BeforeRollback(tx, 1, "Brightness", seen.Brightness, true))
    eq(tx.pendingRollback, nil); eq(ns.Recovery.FinishRollback(tx).state, "PARTIAL_ERROR")
    eq(seen.Brightness.raw, "75"); eq(seen.Contrast.raw, "60")
end)

test("M15 validation copies valid data and refuses invalid baselines without mutation", function()
    local f = fixture(); f.load()
    local original = f.env.LumenShiftDB
    local copy = assert(f.ns.Store.Open(original)); assert(copy ~= original)
    copy.config.selected.visual = "nightVision"; eq(original.config.selected.visual, "natural")
    local seen, j = observations(), f.ns.Store.EmptyJournal()
    local tx = simulate(f.ns, j, plan(f.ns, j, seen, "visual", { Brightness = 75 }), seen)
    original.journal = tx.journal
    original.journal.entries.Brightness.originalRaw = nil
    eq(f.ns.Store.Open(original), nil); assert(original.journal.entries.Brightness ~= nil)
end)

test("M16 one-sided conflict with an already-owned other-layer key is refused", function()
    local ns, cat, seen = fixture().ns, catalog(), observations()
    local j = ns.Store.EmptyJournal()
    local quality = simulate(ns, j, plan(ns, j, seen, "quality", { MockDetail = 90 }, cat), seen)
    cat.MockDetail.conflicts = { "Brightness" }
    eq(ns.Planner.Build(cat, context, seen, quality.journal, "visual", { Brightness = 75 }), nil)
end)

test("Controller models previous-active recovery and exposes no runtime apply", function()
    local ns = fixture().ns
    local c = assert(ns.Controller.Reduce(ns.Controller.New("ACTIVE"), "preview", 0))
    c = assert(ns.Controller.Reduce(c, "simulate", 1))
    eq(ns.Controller.Reduce(c, "cancel", 1), nil)
    c = assert(ns.Controller.Reduce(c, "failure", 1))
    c = assert(ns.Controller.Reduce(c, "recovered", 1)); eq(c.state, "ACTIVE")
    for _ = 1, 3 do local ok, reason = ns.Controller.Apply(); eq(ok, nil); eq(reason, "PHASE_01A_READ_ONLY") end
end)

test("Recovery is read-only with matching, changed-build, unknown or stale records", function()
    local f, seen = fixture(), observations()
    f.load()
    local ns, j = f.ns, f.ns.Store.EmptyJournal()
    local tx = simulate(ns, j, plan(ns, j, seen, "visual", { Brightness = 75 }), seen)
    eq(ns.Recovery.Inspect(tx.journal, seen, "OTHER").entries.Brightness, "BUILD_CHANGED")
    eq(ns.Recovery.Inspect(tx.journal, {}, context.signature).entries.Brightness, "UNAVAILABLE")
    local unknown = ns.Value.Copy(tx.journal.entries.Brightness)
    tx.journal.entries.LegacyUnknown = unknown
    f.env.LumenShiftDB.journal = tx.journal
    local reload = fixture(f.env.LumenShiftDB); reload.load(); reload.env.SlashCmdList.LUMENSHIFT(); reload.zero()
    eq(reload.env.LumenShiftDB.journal.entries.LegacyUnknown.originalRaw, "52")
    assert(table.concat(reload.output, "\n"):find("Recovery records: 2", 1, true))
end)

test("Bounded transaction refusal preserves the input recovery journal", function()
    local ns, seen = fixture().ns, observations()
    local j = ns.Store.EmptyJournal()
    local tx = assert(ns.Recovery.Begin(j, plan(ns, j, seen, "visual", { Brightness = 75 }), 1, "BASELINE"))
    tx.fixturePadding = {}
    for i = 1, 4096 do tx.fixturePadding[i] = i end
    local result, code = ns.Recovery.Before(tx, 1, 1, seen.Brightness, false)
    eq(result, nil); eq(code, "TRANSACTION_LIMIT")
    eq(tx.journal.entries.Brightness.originalRaw, "52")
end)

test("Controller restore preserves another layer's active state", function()
    local ns = fixture().ns
    local c = assert(ns.Controller.Reduce(ns.Controller.New("ACTIVE"), "release", 0))
    eq(c.state, "RESTORING"); eq(c.token, 1)
    eq(ns.Controller.Reduce(c, "verified", 0), nil)
    eq(ns.Controller.Reduce(c, "verifiedOtherLayer", 1).state, "ACTIVE")
    eq(ns.Controller.Reduce(c, "verified", 1).state, "BASELINE")
end)

test("M06 planner rejects falsely OK nonnumeric observations before capture", function()
    local ns = fixture().ns
    for _, raw in ipairs({ "not-a-number", "NaN", "inf", "1e999", "--52" }) do
        local seen, j = observations(raw), ns.Store.EmptyJournal()
        local p, code = ns.Planner.Build(catalog(), context, seen, j, "visual", { Brightness = 75 })
        eq(p, nil); eq(code, "UNSAFE_OBSERVATION:Brightness")
        eq(next(j.entries), nil); eq(j.nextEpoch, 1); eq(seen.Brightness.raw, raw)
    end
end)

local function noSetterRelease()
    local f, seen = fixture(), observations()
    local ns, j = f.ns, f.ns.Store.EmptyJournal()
    local quality = simulate(ns, j, plan(ns, j, seen, "quality", { MockDetail = 90 }), seen)
    local active = simulate(ns, quality.journal, plan(ns, quality.journal, seen, "visual", { Brightness = 75 }), seen, "ACTIVE")
    local returned = simulate(ns, active.journal, plan(ns, active.journal, seen, "visual", { Brightness = 52 }), seen, "ACTIVE")
    return f, seen, returned.journal, plan(ns, returned.journal, seen, "visual", {})
end

test("M03 owned value at exact original releases through observations only", function()
    local f, seen, j, p = noSetterRelease()
    local ns = f.ns
    eq(j.entries.Brightness.originalRaw, "52"); eq(j.entries.Brightness.lastVerifiedRaw, "52")
    eq(#p.operations, 1); eq(p.operations[1].release, true); eq(p.operations[1].write, false)
    -- This path must not even claim a synthetic setter result, let alone call a native writer.
    ns.Recovery.Observe = function() error("NO_SETTER_RESULT_ALLOWED") end
    local tx = assert(ns.Recovery.Begin(j, p, 9, "ACTIVE"))
    tx = assert(ns.Recovery.ReleaseObserved(tx, 9, 1, seen.Brightness, false))
    eq(#tx.attempts, 0); eq(#tx.releases, 1); eq(tx.pendingIndex, nil)
    eq(tx.state, "AWAITING_VERIFICATION"); eq(tx.journal.entries.Brightness, nil)
    tx = assert(ns.Recovery.Verify(tx, 9, seen))
    eq(tx.state, "VERIFIED"); eq(seen.Brightness.raw, "52")
    eq(j.entries.Brightness.originalRaw, "52")
    eq(tx.journal.entries.MockDetail.originalRaw, "40"); eq(seen.MockDetail.raw, "90")
    local throughHarness = simulate(ns, j, p, seen, "ACTIVE")
    eq(#throughHarness.attempts, 0); eq(throughHarness.state, "VERIFIED"); f.zero()
end)

test("M06 planner refuses unrestorable new and retained numeric baselines", function()
    local ns = fixture().ns
    for _, raw in ipairs({ "-1", "101", string.rep("9", 64) }) do
        local seen, j = observations(raw), ns.Store.EmptyJournal()
        local p, code = ns.Planner.Build(catalog(), context, seen, j, "visual", { Brightness = 75 })
        eq(p, nil); eq(code, "UNSAFE_BASELINE:Brightness"); eq(next(j.entries), nil)
    end
    local seen, j = observations(), ns.Store.EmptyJournal()
    local active = simulate(ns, j, plan(ns, j, seen, "visual", { Brightness = 75 }), seen)
    for _, raw in ipairs({ "not-a-number", "-1", "101" }) do
        local journal = ns.Value.Copy(active.journal)
        journal.entries.Brightness.originalRaw = raw
        for _, targets in ipairs({ { Brightness = 80 }, {} }) do
            local p, code = ns.Planner.Build(catalog(), context, seen, journal, "visual", targets)
            eq(p, nil); eq(code, "UNSAFE_BASELINE:Brightness")
            eq(journal.entries.Brightness.originalRaw, raw)
        end
    end
end)

test("M03 no-setter release rejects setter routing, stale IDs and duplicate results", function()
    local f, seen, j, p = noSetterRelease()
    local ns = f.ns
    local tx = assert(ns.Recovery.Begin(j, p, 9, "ACTIVE"))
    local result, code = ns.Recovery.Before(tx, 9, 1, seen.Brightness, false)
    eq(result, nil); eq(code, "OBSERVATION_RELEASE_REQUIRED"); eq(tx.pendingIndex, nil)
    local forgedPending = ns.Value.Copy(tx); forgedPending.pendingIndex = 1
    result, code = ns.Recovery.Observe(forgedPending, 9, 1, true, "52")
    eq(result, nil); eq(code, "OBSERVATION_RELEASE_REQUIRED")
    eq(ns.Recovery.ReleaseObserved(tx, 8, 1, seen.Brightness, false), nil)
    eq(ns.Recovery.ReleaseObserved(tx, 9, 2, seen.Brightness, false), nil)
    tx = assert(ns.Recovery.ReleaseObserved(tx, 9, 1, seen.Brightness, false))
    eq(ns.Recovery.ReleaseObserved(tx, 9, 1, seen.Brightness, false), nil)
    eq(#tx.attempts, 0); eq(#tx.releases, 1); f.zero()
end)

test("M03 no-setter release refuses fresh drift, missing reads and restricted flags", function()
    local f, seen, j, p = noSetterRelease()
    local ns = f.ns
    local restricted = observation("52"); restricted.flags.readOnly = true
    local cases = { observation("63"), observation("not-a-number"), {}, restricted }
    for _, current in ipairs(cases) do
        local tx = assert(ns.Recovery.Begin(j, p, 9, "ACTIVE"))
        tx = assert(ns.Recovery.ReleaseObserved(tx, 9, 1, current, false))
        eq(tx.state, "ROLLING_BACK"); eq(#tx.attempts, 0); eq(#tx.releases, 0)
        eq(tx.journal.entries.Brightness.state, "conflict")
        eq(tx.journal.entries.Brightness.originalRaw, "52")
    end
    local tx = assert(ns.Recovery.Begin(j, p, 9, "ACTIVE"))
    tx = assert(ns.Recovery.ReleaseObserved(tx, 9, 1, seen.Brightness, true))
    eq(tx.state, "DEFERRED"); eq(#tx.releases, 0)
    eq(ns.Recovery.ReleaseObserved(tx, 9, 1, seen.Brightness, false), nil)
    eq(j.entries.Brightness.state, "owned"); f.zero()
end)

test("M03 late drift after no-setter release retains recovery without compensation", function()
    local f, seen, j, p = noSetterRelease()
    local ns = f.ns
    for _, current in ipairs({ observation("63"), {} }) do
        local tx = assert(ns.Recovery.Begin(j, p, 9, "ACTIVE"))
        tx = assert(ns.Recovery.ReleaseObserved(tx, 9, 1, seen.Brightness, false))
        local changed = ns.Value.Copy(seen); changed.Brightness = current
        tx = assert(ns.Recovery.Verify(tx, 9, changed)); eq(tx.state, "ROLLING_BACK")
        eq(tx.journal.entries.Brightness.originalRaw, "52")
        tx = assert(ns.Recovery.RollbackPlan(tx, changed))
        eq(#tx.attempts, 0); eq(#tx.rollback, 0)
        eq(ns.Recovery.FinishRollback(tx).state, "PARTIAL_ERROR")
        eq(tx.journal.entries.Brightness.state, "conflict")
        eq(changed.Brightness.raw, current.raw)
    end
    f.zero()
end)

test("M08 mixed rollback never compensates an observation-only release", function()
    local ns = fixture().ns
    for _, drift in ipairs({ false, true }) do
        local seen, j = observations(), ns.Store.EmptyJournal()
        local active = simulate(ns, j, plan(ns, j, seen, "visual", { Brightness = 75, Contrast = 70 }), seen)
        local returned = simulate(ns, active.journal, plan(ns, active.journal, seen, "visual", { Brightness = 75, Contrast = 60 }), seen, "ACTIVE")
        local p = plan(ns, returned.journal, seen, "visual", {})
        eq(p.operations[1].key, "Contrast"); eq(p.operations[1].write, false)
        eq(p.operations[2].key, "Brightness"); eq(p.operations[2].write, true)
        local tx = assert(ns.Recovery.Begin(returned.journal, p, 9, "ACTIVE"))
        tx = assert(ns.Recovery.ReleaseObserved(tx, 9, 1, seen.Contrast, false))
        tx = assert(ns.Recovery.Before(tx, 9, 2, seen.Brightness, false))
        seen.Brightness = observation("52")
        tx = assert(ns.Recovery.Observe(tx, 9, 2, false, "52"))
        if drift then seen.Contrast = observation("63") end
        local rollback = assert(ns.Recovery.RollbackPlan(tx, seen))
        eq(#rollback.rollback, 1); eq(rollback.rollback[1].key, "Brightness")
        tx = compensate(ns, tx, seen)
        eq(tx.state, drift and "PARTIAL_ERROR" or "ACTIVE")
        eq(tx.journal.entries.Contrast.originalRaw, "60")
        eq(tx.journal.entries.Contrast.state, drift and "conflict" or "owned")
        eq(seen.Contrast.raw, drift and "63" or "60"); eq(seen.Brightness.raw, "75")
    end
end)

test("M03 numeric equivalence alone cannot take the exact-original no-setter path", function()
    local ns, seen = fixture().ns, observations("052.00")
    local j = ns.Store.EmptyJournal()
    local active = simulate(ns, j, plan(ns, j, seen, "visual", { Brightness = 75 }), seen)
    local returned = simulate(ns, active.journal, plan(ns, active.journal, seen, "visual", { Brightness = 52 }), seen, "ACTIVE")
    local p = plan(ns, returned.journal, seen, "visual", {})
    eq(p.operations[1].beforeRaw, "52"); eq(p.operations[1].targetRaw, "052.00")
    eq(p.operations[1].write, true)
    local tx = assert(ns.Recovery.Begin(returned.journal, p, 9, "ACTIVE"))
    local result, code = ns.Recovery.ReleaseObserved(tx, 9, 1, seen.Brightness, false)
    eq(result, nil); eq(code, "INVALID_OBSERVATION_RELEASE")
    eq(tx.journal.entries.Brightness.originalRaw, "052.00")
end)

print(string.format("SIMULATED: %d passed, %d failed (%s); no native game tests", passed, failed, _VERSION))
assert(failed == 0, "Mock test failures")
