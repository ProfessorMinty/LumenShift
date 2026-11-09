-- Simulated client only: all settings below are in-memory strings.
return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function make(saved, configure)
        local f = fixture(saved); f.mock = widgets(f.env); f.calls, f.defaults = {}, { Brightness = "48", Contrast = "53" }
        f.env.C_CVar.GetCVarDefault = function(key) return f.defaults[key] end
        f.env.C_CVar.GetCVarInfo = function(key) return f.values[key], f.defaults[key] or "0", false, false, false, false, false end
        f.env.C_CVar.SetCVar = function(key, value)
            local db = f.env.LumenShiftDB
            local entry = db.journal.entries[key] or db.experiments.journal.entries[key]
            assert(entry and entry.originalRaw, "capture must precede every setter")
            f.calls[#f.calls + 1] = { key, value }
            if f.setter then return f.setter(key, value) end
            f.values[key] = value; return true
        end
        if configure then configure(f) end
        f.load(); f.r = f.ns.runtime
        function f.choose(source)
            assert(f.r.setup.Open()); f.mock.Click(source == "gameDefaults" and "Game Defaults" or "Original")
            assert(f.r.setup.SaveAndClose())
        end
        function f.select(id) local ok, why = f.r.product.Select(id); assert(ok, why); f.mock.Flush() end
        return f
    end
    test("H01 setup captures exact Original values without graphics changes", function()
        local f = make(nil, function(f) f.values.Brightness = "052.00" end)
        f.choose("current"); eq(f.r.db.baseline.values.Brightness, "052.00"); eq(f.r.db.baseline.values.Contrast, "60")
        eq(f.ns.StudioConfig.Label("natural"), "Original"); eq(f.r.db.baseline.chosen, true)
        eq(#f.calls, 0); eq(#f.mock.soundCalls, 0); eq(next(f.r.db.journal.entries), nil); f.zero()
    end)
    test("H02 native defaults are displayed and applied without overwriting recovery originals", function()
        local f = make(); f.choose("gameDefaults")
        eq(f.r.db.baseline.values.Brightness, "48"); eq(f.r.db.baseline.values.Contrast, "53")
        eq(f.ns.StudioConfig.Label("natural"), "Game Defaults"); eq(#f.calls, 0)
        f.select("natural"); eq(f.values.Brightness, "48"); eq(f.values.Contrast, "53")
        eq(f.r.db.journal.entries.Brightness.originalRaw, "52")
        eq(f.r.db.experiments.journal.entries.Contrast.originalRaw, "60"); eq(f.r.product.baselineVerified, true)
        assert(f.r.engine.Switch(nil)); assert(f.r.engine.Verify())
        assert(f.r.lab.Apply("visual", {})); f.mock.Flush()
        eq(f.values.Brightness, "52"); eq(f.values.Contrast, "60"); eq(#f.calls, 4)
        f.r.product.Observe(); eq(f.r.product.baselineVerified, false); f.zero()
    end)
    test("H03 Original uses exact raw restoration and never assumes brightness 45", function()
        local f = make(nil, function(f) f.values.Brightness = "052.00" end)
        f.choose("current"); f.select("nightVision"); f.select("natural")
        eq(f.values.Brightness, "052.00"); eq(#f.calls, 2); eq(next(f.r.db.journal.entries), nil)
        eq(next(f.r.db.experiments.journal.entries), nil); eq(f.values.Contrast, "60"); f.zero()
    end)
    test("H04 current capture while Night Vision is active retains pre-mode originals", function()
        local f = make(); f.select("nightVision"); eq(f.values.Brightness, "75")
        f.choose("current"); eq(f.r.db.baseline.values.Brightness, "52")
        eq(f.r.db.journal.entries.Brightness.originalRaw, "52"); eq(#f.calls, 1)
        f.select("natural"); eq(f.values.Brightness, "52"); f.zero()
    end)
    test("H05 saving preferences does not recapture and canceled choices have no effect", function()
        local f = make(); f.choose("current"); f.values.Brightness = "57"
        assert(f.r.setup.Open()); f.mock.Click("Reduced motion"); assert(f.r.setup.SaveAndClose())
        eq(f.r.db.baseline.values.Brightness, "52")
        assert(f.r.setup.Open()); f.mock.Click("Game Defaults"); f.r.setup.window:Hide()
        eq(f.r.db.baseline.source, "current")
        assert(f.r.setup.Open()); f.mock.Click("Capture again"); assert(f.r.setup.SaveAndClose())
        eq(f.r.db.baseline.values.Brightness, "57"); eq(#f.calls, 0); f.zero()
    end)
    test("H06 schema 5 migration keeps completion preferences and recovery with one new setup choice", function()
        local f = make(); f.select("nightVision")
        local old = f.ns.Value.Copy(f.r.db); old.schemaVersion, old.baseline = 5, nil; old.graphics = nil; old.optics = nil
        old.addonVersion = "0.2.0-dev.9"; old.onboarding.completed = true; old.config.preferences.sound = true
        local migrated, code = f.ns.Store.Open(old); eq(code, "MIGRATED_5_TO_14")
        eq(migrated.onboarding.completed, true); eq(migrated.baseline.chosen, false)
        eq(migrated.config.preferences.sound, true); eq(migrated.journal.entries.Brightness.originalRaw, "52")
        eq(old.schemaVersion, 5); eq(old.baseline, nil)
        local nextLogin = make(old); nextLogin.frame.OnEvent(nextLogin.frame, "PLAYER_ENTERING_WORLD")
        assert(nextLogin.r.setup.window:IsShown()); eq(#nextLogin.calls, 0); nextLogin.zero()
    end)
    test("H07 invalid baseline numbers and unknown keys quarantine without mutation", function()
        local f = make(); f.choose("current")
        for _, raw in ipairs({ "NaN", "inf", "101", "-1", "", "1e2", 52 }) do
            local db = f.ns.Value.Copy(f.r.db); db.baseline.values.Brightness = raw
            eq(f.ns.Store.Open(db), nil); eq(db.baseline.values.Brightness, raw)
        end
        local db = f.ns.Value.Copy(f.r.db); db.baseline.values.Gamma = "1"
        eq(f.ns.Store.Open(db), nil); eq(#f.calls, 0); f.zero()
    end)
    test("H08 missing secret invalid and drifted defaults never become guessed targets", function()
        for _, kind in ipairs({ "missing", "secret", "invalid", "error", "drift" }) do
            local f = make(nil, function(f)
                if kind == "missing" then f.env.C_CVar.GetCVarDefault = nil
                elseif kind == "error" then f.env.C_CVar.GetCVarDefault = function() error("PRIVATE") end
                elseif kind == "drift" then f.env.C_CVar.GetCVarDefault = function() return "49" end
                else f.defaults.Brightness = kind == "secret" and "SECRET" or "bad" end
            end)
            f.choose("gameDefaults"); eq(f.r.db.baseline.values.Brightness, nil)
            eq(f.r.product.Select("natural"), nil); eq(#f.calls, 0)
            -- A missing default does not turn otherwise working controls read-only.
            if kind ~= "secret" then f.select("nightVision"); eq(f.values.Brightness, "75") end
            f.zero()
        end
    end)
    test("H09 delayed capture fills only missing keys before an explicit mode action", function()
        local f = make(); f.env.C_CVar.AreCVarsLoaded = function() return false end
        f.choose("current"); eq(next(f.r.db.baseline.values), nil); eq(#f.calls, 0)
        f.env.C_CVar.AreCVarsLoaded = function() return true end
        f.select("nightVision"); eq(f.r.db.baseline.values.Brightness, "52"); eq(f.r.db.baseline.values.Contrast, "60")
        f.defaults.Brightness = "41"; f.ns.Baseline.CompleteMissing(f.r)
        eq(f.r.db.baseline.values.Brightness, "52"); f.zero()
    end)
    test("H10 missing Contrast stays disclosed and does not invent a default", function()
        local f = make(); f.defaults.Contrast = nil; f.choose("gameDefaults")
        eq(f.r.db.baseline.values.Contrast, nil); f.select("natural")
        eq(f.values.Brightness, "48"); eq(f.values.Contrast, "60"); eq(#f.calls, 1)
        assert(f.ns.Baseline.Summary(f.r.db.baseline):find("Contrast unavailable", 1, true)); f.zero()
    end)
    test("H11 a captured but restricted Contrast prevents any preceding Brightness write", function()
        local f = make(); f.choose("gameDefaults")
        f.env.C_CVar.GetCVarInfo = function(key) return f.values[key], f.defaults[key], false, false, false, false, key == "Contrast" end
        eq(f.r.product.Select("natural"), nil); eq(#f.calls, 0); eq(f.values.Brightness, "52"); f.zero()
    end)
    test("H12 external edits are preserved when returning to selected baseline", function()
        local f = make(); f.choose("current"); f.select("nightVision"); f.values.Brightness = "67"
        eq(f.r.product.Select("natural"), nil); eq(f.values.Brightness, "67"); eq(#f.calls, 1)
        eq(f.r.db.journal.entries.Brightness.originalRaw, "52"); eq(f.r.product.baselineVerified, false); f.zero()
    end)
    test("H13 default Contrast failure keeps both recovery originals and no false completion", function()
        local f = make(); f.choose("gameDefaults")
        f.setter = function(key, value) f.values[key] = key == "Contrast" and "55" or value; return true end
        eq(f.r.product.Select("natural"), nil); f.mock.Flush(); eq(f.r.product.baselineVerified, false); assert(f.r.product.lastError)
        eq(f.r.db.journal.entries.Brightness.originalRaw, "52")
        eq(f.r.db.experiments.journal.entries.Contrast.originalRaw, "60")
        eq(f.values.Contrast, "55"); f.zero()
    end)
    test("H14 restart never applies chosen defaults or reports them as active", function()
        local f = make(); f.choose("gameDefaults")
        local again = make(f.r.db); again.frame.OnEvent(again.frame, "PLAYER_ENTERING_WORLD")
        eq(again.r.setup.window, nil); eq(again.r.product.baselineVerified, nil)
        eq(again.values.Brightness, "52"); eq(#again.calls, 0); again.zero()
    end)
    test("H15 no-setter baseline release and external drift clear the active marker", function()
        local f = make(); f.choose("current"); f.select("nightVision")
        f.values.Brightness = "52"
        -- The existing writer treats external drift as a conflict, including a
        -- return to the original. Explicit recovery may release it without a setter.
        assert(f.r.engine.Prepare("restore")); assert(f.r.engine.Confirm(f.r.engine.Status().token))
        assert(f.r.engine.Verify()); f.select("natural")
        eq(#f.calls, 1); eq(next(f.r.db.journal.entries), nil); eq(f.r.product.baselineVerified, true)
        f.values.Contrast = "61"; f.r.product.Observe(); eq(f.r.product.baselineVerified, false)
        eq(f.values.Contrast, "61"); eq(#f.calls, 1); f.zero()
    end)
    test("H16 mode and quality selections remain independent with defaults selected", function()
        local f = make(); f.choose("gameDefaults")
        f.r.db.config.selected.quality = "vista"; f.r.db.experiments.profiles.vista.ResampleSharpness = 0.2
        f.select("nightVision"); f.select("natural")
        eq(f.r.db.config.selected.quality, "vista"); eq(f.r.db.experiments.profiles.vista.ResampleSharpness, 0.2)
        for _, call in ipairs(f.calls) do assert(call[1] == "Brightness" or call[1] == "Contrast") end; f.zero()
    end)
    test("H18 unchanged fractional current values do not need a new target or ownership", function()
        local f = make(nil, function(f) f.values.Brightness, f.values.Contrast = "052.25", "060.25" end)
        f.choose("current"); f.select("nightVision"); f.select("natural")
        eq(f.values.Brightness, "052.25"); eq(f.values.Contrast, "060.25"); eq(#f.calls, 2)
        eq(next(f.r.db.journal.entries), nil); eq(next(f.r.db.experiments.journal.entries), nil); f.zero()
    end)
    test("H17 research observations and dependency watchers never grant write admission or dump console scripts", function()
        local f = make(); f.env.ConsoleGetAllCommands = function() error("MUST_NOT_DUMP") end
        local watch = {}; for _, key in ipairs(f.ns.Catalog.WatchKeys()) do watch[key] = true end
        for _, key in ipairs(f.ns.Catalog.ResearchKeys()) do
            eq(f.ns.Catalog.Get(key).admitted, false); eq(f.ns.ExperimentPolicy.Known(key), false)
            -- Some research fields are now read-only dependency watchers for the isolated AO trial.
            eq(f.ns.Catalog.Admitted(f.ns.Catalog.Get(key), f.ns.ExperimentPolicy.Context("1.60.1:70790:16001")), false)
            f.values[key] = "1"; f.defaults[key] = "0"
        end
        local report = f.ns.Report.Export(f.r)
        assert(report:find("EXTRA GRAPHICS OBSERVATIONS", 1, true)); assert(report:find("assaoSharpness", 1, true))
        eq(report:find("MUST_NOT_DUMP", 1, true), nil); eq(#f.calls, 0); f.zero()
    end)
end
