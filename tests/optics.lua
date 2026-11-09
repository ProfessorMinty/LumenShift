return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function make(saved, actual)
        local f = fixture(saved); f.mock = widgets(f.env); f.calls = {}
        f.values.Brightness, f.values.Contrast = "052.00", "060.00"
        f.values.ResampleAlwaysSharpen, f.values.ResampleSharpness, f.values.bloomUserMult = "0", "1.000", "0.8"
        for key, raw in pairs(actual or {}) do f.values[key] = raw end
        f.env.C_CVar.SetCVar = function(key, raw)
            local db = f.env.LumenShiftDB
            local entry = db.journal.entries[key] or db.experiments.journal.entries[key]
            assert(entry and entry.originalRaw, "shared capture before write")
            f.calls[#f.calls + 1] = { key, raw }
            if f.setter then return f.setter(key, raw, #f.calls) end
            f.values[key] = raw; return true
        end
        f.load(); f.r, f.p = f.ns.runtime, f.ns.runtime.product
        function f.detail(id, value) local m = f.r.db.config.studio.modes[id]; m.sharpening, m.detail = "custom", value end
        function f.select(id) local ok, why = f.p.Select(id); assert(ok, why); f.mock.Flush(); assert(f.p.state == "ACTIVE", f.p.lastError) end
        function f.quality(targets) local ok, why = f.r.lab.Apply("quality", targets); assert(ok, why); f.mock.Flush(); assert(not f.r.lab.lastError, f.r.lab.lastError) end
        function f.compare(side) local ok, why = f.p.Compare(side); assert(ok, why); f.mock.Flush(); assert(not f.p.lastError, f.p.lastError) end
        function f.original(key) return f.r.db.experiments.journal.entries[key].originalRaw end
        return f
    end
    test("O01 quality mode changed-quality mode-off full-restore preserves independent intent and exact first original", function()
        local f = make(); f.quality({ ResampleSharpness = 0.4 }); f.detail("nightVision", 90); f.select("nightVision")
        eq(f.values.ResampleSharpness, "0.2"); eq(f.original("ResampleSharpness"), "1.000")
        f.quality({ ResampleSharpness = 0.7 }); eq(f.values.ResampleSharpness, "0.2"); eq(f.r.db.optics.quality.ResampleSharpness, 0.7)
        f.select("natural"); eq(f.values.ResampleSharpness, "0.7"); eq(f.values.Brightness, "052.00")
        f.quality({}); eq(f.values.ResampleSharpness, "1.000"); eq(next(f.r.db.experiments.journal.entries), nil)
    end)
    test("O02 mode-first quality selection and release never recapture a mode target", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision")
        f.quality({ ResampleSharpness = 0.4 }); eq(f.values.ResampleSharpness, "0.2")
        eq(f.original("ResampleSharpness"), "1.000"); f.quality({}); eq(f.values.ResampleSharpness, "0.2")
        f.select("natural"); eq(f.values.ResampleSharpness, "1.000"); eq(next(f.r.db.optics.visual), nil)
    end)
    test("O03 extra-sharpening off changes the enable flag rather than pretending raw strength 2 is off", function()
        local f = make(); f.quality({ ResampleAlwaysSharpen = 1, ResampleSharpness = 0.4 })
        f.r.db.config.studio.modes.nightVision.sharpening = "off"; f.select("nightVision")
        eq(f.values.ResampleAlwaysSharpen, "0"); eq(f.values.ResampleSharpness, "0.4")
        f.select("natural"); eq(f.values.ResampleAlwaysSharpen, "1"); f.quality({})
        eq(f.values.ResampleAlwaysSharpen, "0"); eq(f.values.ResampleSharpness, "1.000")
    end)
    test("O04 invalid detail is rejected and unavailable unowned optics are reported without disabling Brightness", function()
        local f = make(); eq(f.p.Update(function(c) c.studio.modes.nightVision.detail = 101 end), nil)
        eq(f.p.Update(function(c) c.studio.modes.nightVision.detail = 51 end), nil)
        f.detail("nightVision", 90); f.values.ResampleSharpness = nil
        assert(f.p.Select("nightVision")); f.mock.Flush(); eq(f.values.Brightness, "75"); assert(#f.p.omitted > 0)
        for _, call in ipairs(f.calls) do eq(call[1], "Brightness") end
        f.r.db.config.studio.modes.nightVision.sharpening = "inherit"; f.select("nightVision"); eq(f.values.Brightness, "75")
    end)
    test("O05 unrelated unavailable bloom does not block sharpening or discard its quality original", function()
        local f = make(); f.quality({ bloomUserMult = 0.4 }); f.env.C_VideoOptions.IsLinearEnabledOnStart = function() return false end
        f.detail("nightVision", 90); f.select("nightVision")
        eq(f.values.bloomUserMult, "0.4"); eq(f.original("bloomUserMult"), "0.8")
        f.select("natural"); eq(f.values.ResampleSharpness, "1.000"); eq(f.original("bloomUserMult"), "0.8")
    end)
    test("O06 delayed sharpness drift preserves the external value and all originals", function()
        local f = make(); f.detail("nightVision", 90); assert(f.p.Select("nightVision"))
        f.values.ResampleSharpness = "0.6"; f.mock.Flush()
        eq(f.values.ResampleSharpness, "0.6"); eq(f.p.state, "PARTIAL"); eq(f.original("ResampleSharpness"), "1.000")
        eq(f.r.db.journal.entries.Brightness.originalRaw, "052.00"); eq(next(f.r.db.optics.visual), nil)
    end)
    test("O07 clamping and failed optical compensation retain originals even for immediately restored members", function()
        local f = make(); f.detail("nightVision", 90)
        f.setter = function(key, raw) f.values[key] = key == "ResampleSharpness" and "0.3" or raw; return true end
        eq(f.p.Select("nightVision"), nil); f.mock.Flush(); eq(f.p.state, "PARTIAL")
        eq(f.original("ResampleSharpness"), "1.000"); eq(f.r.db.journal.entries.Brightness.originalRaw, "052.00")
        f.setter = nil; assert(f.p.RestoreVisuals()); f.mock.Flush(); eq(f.values.ResampleSharpness, "1.000")
    end)
    test("O08 before-after comparison keeps exact originals and returns to the applied look", function()
        local f = make(); f.quality({ ResampleSharpness = 0.4 }); f.detail("nightVision", 90); f.select("nightVision")
        f.compare("before"); eq(f.values.Brightness, "052.00"); eq(f.values.ResampleSharpness, "0.4")
        eq(f.original("ResampleSharpness"), "1.000"); eq(f.r.presentation.Status(), "OFF")
        f.compare("after"); eq(f.values.Brightness, "75"); eq(f.values.ResampleSharpness, "0.2")
        eq(f.r.presentation.Status(), "VISIBLE"); local n = #f.calls; f.compare("done"); eq(#f.calls, n)
        eq(f.r.db.optics.comparison, nil); f.select("natural"); eq(f.values.ResampleSharpness, "0.4")
        f.quality({}); eq(f.values.ResampleSharpness, "1.000")
    end)
    test("O09 cancelling from Before restores After through the writer and refuses external edits", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision"); f.compare("before"); f.compare("done")
        eq(f.values.Brightness, "75"); eq(f.values.ResampleSharpness, "0.2")
        f.compare("before"); f.values.ResampleSharpness = "0.8"; local n = #f.calls
        eq(f.p.Compare("done"), nil); eq(#f.calls, n); eq(f.values.ResampleSharpness, "0.8")
        eq(f.r.db.optics.comparison, nil); eq(f.original("ResampleSharpness"), "1.000")
    end)
    test("O10 external changes between comparison members are not compensated over", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision")
        f.setter = function(key, raw) f.values[key] = raw; f.values.ResampleSharpness = "0.8"; return true end
        local n = #f.calls; eq(f.p.Compare("before"), nil); eq(#f.calls, n + 1)
        eq(f.values.ResampleSharpness, "0.8"); eq(f.original("ResampleSharpness"), "1.000")
    end)
    test("O11 comparison reload is read-only and an explicit Finish can restore a matching After snapshot", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision"); f.compare("before")
        local g = make(f.r.db, f.values); eq(#g.calls, 0); eq(g.r.db.optics.comparison.state, "before")
        g.ns.Report.Export(g.r); eq(#g.calls, 0); g.compare("done")
        eq(g.values.ResampleSharpness, "0.2"); eq(g.values.Brightness, "75"); eq(g.original("ResampleSharpness"), "1.000")
    end)
    test("O12 pending comparison reload never replays an uncertain After", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision"); assert(f.p.Compare("before"))
        local g = make(f.r.db, f.values); eq(#g.calls, 0)
        eq(g.p.Compare("done"), nil); eq(#g.calls, 0); eq(g.original("ResampleSharpness"), "1.000")
    end)
    test("O13 quality native-trial and mode changes cannot interleave a comparison", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision"); f.compare("before")
        local n = #f.calls
        eq(f.r.lab.Apply("quality", { ResampleSharpness = 0.7 }), nil); eq(f.p.Select("cinematic"), nil)
        eq(f.r.engine.Switch(65), nil); eq(f.r.lab.Test("ResampleSharpness", 0.3), nil); eq(#f.calls, n)
        f.compare("done"); eq(f.values.ResampleSharpness, "0.2")
    end)
    test("O14 comparison uses the last applied cosmetics rather than intervening editor changes", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision")
        local opacity = f.p.appliedSettings.opacity; f.compare("before")
        f.r.db.config.studio.modes.nightVision.opacity = 0.11
        f.compare("after"); eq(f.r.presentation.tint.color[4], opacity); f.compare("done")
    end)
    test("O15 exact no-setter optical recovery clears requests but preserves saved mode edits", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision")
        f.values.Brightness, f.values.ResampleAlwaysSharpen, f.values.ResampleSharpness = "052.00", "0", "1.000"
        local n = #f.calls; assert(f.p.RestoreVisuals()); f.mock.Flush(); eq(#f.calls, n)
        eq(next(f.r.db.optics.visual), nil); eq(next(f.r.db.optics.quality), nil)
        eq(f.r.db.config.studio.modes.nightVision.detail, 90); eq(next(f.r.db.experiments.journal.entries), nil)
    end)
    test("O16 fresh Clarity is neutral and Clear Night Vision remains useful without styling", function()
        local f = make(); f.detail("clarity", 80); f.select("clarity")
        eq(f.values.Brightness, "052.00"); eq(f.r.presentation.Status(), "OFF"); eq(f.values.ResampleSharpness, "0.4")
        f.detail("nightVision", 90); f.r.db.config.studio.modes.nightVision.styling = "clear"; f.select("nightVision")
        eq(f.values.Brightness, "75"); eq(f.values.ResampleSharpness, "0.2"); eq(f.r.presentation.Status(), "OFF")
    end)
    test("O17 schema-8 migration preserves customized modes presets completion and single optical originals", function()
        local f = make(); f.quality({ ResampleSharpness = 0.4 }); f.r.db.onboarding.completed = true
        f.r.db.config.studio.modes.clarity.brightness = 78
        local id = assert(f.p.SavePreset("Old look", "clarity")); local old = f.ns.Value.Copy(f.r.db)
        old.schemaVersion, old.optics = 8, nil
        local function legacy(m) for _, k in ipairs({ "brightnessMode", "sharpening", "detail", "useBloom", "bloom", "styling" }) do m[k] = nil end end
        for _, m in pairs(old.config.studio.modes) do legacy(m) end; legacy(old.config.studio.presets[id].settings)
        local g = make(old, f.values); eq(#g.calls, 0); eq(g.r.storeStatus, "MIGRATED_8_TO_16")
        eq(g.r.db.optics.quality.ResampleSharpness, 0.4); eq(g.original("ResampleSharpness"), "1.000")
        eq(g.r.db.config.studio.modes.clarity.brightness, 78); eq(g.r.db.config.studio.modes.clarity.brightnessMode, "custom")
        eq(g.r.db.config.studio.presets[id].settings.sharpening, "inherit"); eq(g.r.db.onboarding.completed, true); eq(old.optics, nil)
    end)
    test("O18 invalid shared requests and comparison data quarantine without writing", function()
        for _, mutate in ipairs({ function(d) d.optics.visual.Gamma = 1 end,
            function(d) d.optics.quality.ResampleSharpness = 3 end,
            function(d) d.optics.comparison = { state = "after", before = {}, after = { Brightness = "75" }, expected = {} } end }) do
            local f = make(); local saved = f.ns.Value.Copy(f.r.db); mutate(saved)
            local g = make(saved); eq(g.r.db, nil); eq(#g.calls, 0)
        end
    end)
    test("O19 data-only preset roundtrip preserves optical fields and imports without applying", function()
        local f = make(); f.detail("nightVision", 90); f.r.db.config.studio.modes.nightVision.styling = "clear"
        local id = assert(f.p.SavePreset("Detail look", "nightVision"))
        local encoded = assert(f.ns.StudioConfig.ExportPreset(f.r.db.config.studio, id))
        local imported = assert(f.p.ImportPreset("Imported", encoded)); eq(#f.calls, 0)
        eq(f.r.db.config.studio.presets[imported].settings.detail, 90)
        for _, bad in ipairs({ encoded .. ";1", encoded:gsub(";90;", ";101;"), "return 1", encoded:gsub(";custom;90;", ";unknown;90;") }) do
            eq(f.p.ImportPreset("Bad", bad), nil)
        end
        eq(#f.calls, 0); f.quality({ ResampleSharpness = 0.4 }); assert(f.p.LoadPreset(imported)); f.mock.Flush()
        eq(f.values.ResampleSharpness, "0.2"); eq(f.r.db.optics.quality.ResampleSharpness, 0.4)
        eq(f.r.presentation.Status(), "OFF")
    end)
    test("O20 Studio optical edits and report are read-only until ordinary Apply", function()
        local f = make(); f.r.ui.Open(1); f.r.ui.scroll:SetVerticalScroll(360)
        f.mock.Click("Custom"); f.mock.Click("Clear"); eq(f.r.ui.scroll:GetVerticalScroll(), 360)
        eq(#f.calls, 0); f.ns.Report.Export(f.r); eq(#f.calls, 0)
        f.mock.Click("Apply Night Vision"); f.mock.Flush(); eq(f.values.Brightness, "75")
        f.mock.Click("Before"); f.mock.Flush(); eq(f.values.Brightness, "052.00")
        eq(f.r.ui.scroll:GetVerticalScroll(), 360)
        f.mock.Click("Finish comparison"); f.mock.Flush(); eq(f.values.Brightness, "75")
        eq(f.r.ui.scroll:GetVerticalScroll(), 360)
    end)
    test("O21 comparison preflight refuses nested graphics writers", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision")
        local getter, nested = f.env.C_CVar.GetCVar, false
        f.env.C_CVar.GetCVar = function(key)
            if not nested then
                nested = true
                eq(f.r.visual.Compare("before"), nil); eq(f.r.engine.Switch(66), nil)
                eq(f.r.lab.Apply("quality", { ResampleSharpness = 0.8 }), nil)
                nested = false
            end
            return getter(key)
        end
        assert(f.p.Compare("before")); f.mock.Flush(); eq(f.values.Brightness, "052.00")
    end)
    test("O22 compensation after a comparison setter rejection restores the known prior look", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision")
        f.setter = function(key, raw) if key == "ResampleSharpness" then return false end; f.values[key] = raw; return true end
        assert(f.p.Compare("before")); f.mock.Flush()
        eq(f.values.Brightness, "75"); eq(f.values.ResampleSharpness, "0.2")
        eq(f.r.db.optics.comparison, nil); eq(f.p.state, "ACTIVE"); eq(f.r.presentation.Status(), "VISIBLE")
    end)
    test("O23 optional off-grid originals restore exactly while new mode targets stay on source steps", function()
        local f = make(nil, { ResampleSharpness = "1.7700" }); f.detail("nightVision", 90)
        eq(f.r.visual.Apply({ Brightness = 75, ResampleSharpness = 0.17 }), nil); eq(#f.calls, 0)
        f.select("nightVision"); f.compare("before"); eq(f.values.ResampleSharpness, "1.7700")
        f.compare("done"); f.select("natural"); eq(f.values.ResampleSharpness, "1.7700")
    end)
    test("O24 missing setter and timer failure retain optical recovery without automatic retries", function()
        local f = make(); f.detail("nightVision", 90); f.env.C_CVar.SetCVar = nil
        eq(f.p.Select("nightVision"), nil); eq(#f.calls, 0)
        f = make(); f.detail("nightVision", 90); f.env.C_Timer.After = function() error("timer") end
        eq(f.p.Select("nightVision"), nil); eq(f.p.state, "PARTIAL")
        eq(f.original("ResampleSharpness"), "1.000"); local n = #f.calls; f.ns.Report.Export(f.r); eq(#f.calls, n)
    end)
    test("O25 mode detail never requests resolution antialiasing filtering or quality tiers", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision"); f.compare("before"); f.compare("done"); f.select("natural")
        for _, call in ipairs(f.calls) do
            assert(call[1] == "Brightness" or call[1] == "Contrast" or f.ns.Optics.Known(call[1]))
        end
        local _, sources = f.ns.Optics.Resolve({ ResampleSharpness = 0.2 }, { ResampleSharpness = 0.7 })
        eq(sources.ResampleSharpness, "visual")
    end)
    test("O26 comparison boolean flags reject fractional raw values without writes", function()
        local f = make(); local saved = f.ns.Value.Copy(f.r.db)
        saved.optics.comparison = { state = "after", before = { ResampleAlwaysSharpen = "0" },
            after = { ResampleAlwaysSharpen = "0.5" }, expected = { ResampleAlwaysSharpen = "0.5" } }
        local g = make(saved); eq(g.r.db, nil); eq(#g.calls, 0)
    end)
    test("O27 Studio exports a complete copyable preset and imports without applying", function()
        local f = make(); f.detail("nightVision", 90)
        local id = assert(f.p.SavePreset("Original preset", "nightVision")); f.r.ui.Open(5); f.mock.Click("Export")
        local encoded = assert(f.ns.StudioConfig.ExportPreset(f.r.db.config.studio, id)); assert(#encoded > 64)
        local input
        for _, node in ipairs(f.mock.nodes) do
            if node.kind == "EditBox" and node:IsVisible() and node:GetText() == encoded then input = node end
        end
        assert(input and input.focus and input.highlight); eq(input.SetMaxLettersArgs[1], 2048)
        f.mock.Click("Import preset"); eq(#f.ns.Value.Keys(f.r.db.config.studio.presets), 2); eq(#f.calls, 0)
    end)
    test("O28 final comparison snapshot refuses an external edit after verification", function()
        local f = make(); f.detail("nightVision", 90); f.select("nightVision")
        local getter = f.env.C_CVar.GetCVar
        f.env.C_CVar.GetCVar = function(key)
            local c = f.r.db.optics.comparison
            if key == "ResampleSharpness" and c and c.state == "before" then f.values[key] = "0.8" end
            return getter(key)
        end
        assert(f.p.Compare("before")); f.mock.Flush()
        eq(f.r.db.optics.comparison.state, "recovery"); eq(f.p.state, "RECOVERY")
        eq(f.values.ResampleSharpness, "0.8"); eq(f.original("ResampleSharpness"), "1.000")
    end)
    test("O29 already-original bloom releases without a renderer-dependent setter", function()
        local f = make(); f.r.db.config.studio.modes.nightVision.useBloom = true
        f.select("nightVision"); f.values.bloomUserMult = "0.8"
        f.values.Brightness = "052.00"; f.env.C_VideoOptions.IsLinearEnabledOnStart = function() return false end
        local n = #f.calls; assert(f.p.RestoreVisuals()); f.mock.Flush()
        eq(#f.calls, n); eq(f.r.db.experiments.journal.entries.bloomUserMult, nil)
    end)
    if os.getenv("LUMENSHIFT_UI_MODEL_PATH") then
        local f = make(); f.r.ui.Open(1); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-optics.tsv")
        f.r.ui.scroll:SetVerticalScroll(370); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-optics-detail.tsv")
        f.r.ui.scroll:SetVerticalScroll(f.r.ui.scrollMaximum); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-optics-comparison.tsv")
        assert(f.p.SavePreset("Detailed Night Vision", "nightVision")); f.r.ui.Open(5)
        f.mock.Click("Export"); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-presets-transfer.tsv")
    end
end
