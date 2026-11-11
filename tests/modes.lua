return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function make(saved, actual)
        local f = fixture(saved); f.mock = widgets(f.env); f.calls = {}
        f.values.Brightness, f.values.Contrast = "052.00", "060.00"
        f.values.ResampleAlwaysSharpen, f.values.ResampleSharpness, f.values.bloomUserMult = "0", "1.7700", "0.8"
        f.values.SSAO, f.values.RAIDSSAO, f.values.RAIDsettingsEnabled = "4", "4", "0"
        f.values.assaoDetailShadowStrength, f.values.assaoRadius, f.values.assaoShadowMult = "0.00", "1.85", "1.1"
        f.values.assaoShadowPower, f.values.assaoBlurPassCount, f.values.assaoSharpness = "1.34", "2", ".98"
        for key, raw in pairs(actual or {}) do f.values[key] = raw end
        f.env.C_CVar.SetCVar = function(key, raw)
            local db = f.env.LumenShiftDB
            assert(db.journal.entries[key] or db.experiments.journal.entries[key], "capture before any writer")
            f.calls[#f.calls + 1] = { key, raw }
            if f.setter then return f.setter(key, raw) end
            f.values[key] = raw; return true
        end
        f.load(); f.r, f.p = f.ns.runtime, f.ns.runtime.product
        function f.select(id) local ok, why = f.p.Select(id); assert(ok, why); f.mock.Flush(); eq(f.p.state, "ACTIVE") end
        function f.variant(id, index) f.r.db.config.studio.modes[id] = assert(f.ns.Modes.Variant(id, index)) end
        function f.quality(targets) local ok, why = f.r.lab.Apply("quality", targets); assert(ok, why); f.mock.Flush() end
        function f.compare(side) local ok, why = f.p.Compare(side); assert(ok, why); f.mock.Flush() end
        function f.restore() local ok, why = f.p.RestoreVisuals(); assert(ok, why); f.mock.Flush() end
        return f
    end
    test("T01 every authored look validates and changes no live state until Apply", function()
        local f = make()
        for id, variants in pairs(f.ns.Modes.Variants) do
            for i in ipairs(variants) do assert(f.ns.StudioConfig.ValidateMode(f.ns.Modes.Variant(id, i))) end
        end
        eq(f.ns.Modes.Variant("natural", 1), nil); eq(#f.calls, 0)
        f.r.ui.Open(1); f.mock.Click("Clear vision"); eq(#f.calls, 0)
        eq(f.r.db.config.studio.modes.nightVision.detail, 70); eq(f.r.db.config.studio.modes.nightVision.styling, "clear")
        f.mock.Click("Apply Night Vision"); f.mock.Flush(); eq(f.values.ResampleSharpness, "0.6")
    end)
    test("T02 authored modes preserve independent quality and full exact restoration", function()
        for id, variants in pairs(make().ns.Modes.Variants) do
            for i in ipairs(variants) do
                local f = make(); f.quality({ ResampleSharpness = 0.9 }); f.variant(id, i); f.select(id)
                eq(f.r.db.optics.quality.ResampleSharpness, 0.9); f.select("natural"); eq(f.values.ResampleSharpness, "0.9")
                f.restore(); eq(f.values.ResampleSharpness, "1.7700"); eq(f.values.Brightness, "052.00")
                eq(f.values.Contrast, "060.00"); eq(f.values.bloomUserMult, "0.8")
            end
        end
    end)
    test("T03 intensity interpolates light and styling while detail and framing stay independent", function()
        local f = make(); f.variant("cinematic", 2); local m = f.r.db.config.studio.modes.cinematic
        m.intensity = 50; f.select("cinematic")
        eq(f.values.Brightness, "50"); eq(f.values.Contrast, "59"); eq(f.values.ResampleSharpness, "0.8")
        eq(f.p.appliedSettings.opacity, m.opacity / 2); eq(f.p.appliedSettings.letterbox, 0.06)
        eq(m.brightness, 48); eq(m.opacity, 0.015)
        m.intensity = 0; f.select("cinematic"); eq(f.values.Brightness, "052.00"); eq(f.values.Contrast, "060.00")
        eq(f.p.appliedSettings.opacity, 0); eq(f.values.ResampleSharpness, "0.8")
    end)
    test("T04 intensity anchors to chosen reference not the previous mode's value", function()
        local f = make(); f.r.db.baseline = f.ns.Baseline.Capture(f.r, "current")
        f.variant("nightVision", 1); f.select("nightVision")
        f.variant("lantern", 1); f.r.db.config.studio.modes.lantern.intensity = 50; f.select("lantern")
        eq(f.values.Brightness, "59"); eq(f.r.db.journal.entries.Brightness.originalRaw, "052.00")
        f.select("natural"); eq(f.values.Brightness, "052.00")
    end)
    test("T05 intensity rejects invalid inputs and cosmetic resume does not double-scale", function()
        local f = make(); f.variant("lantern", 1)
        eq(f.p.Update(function(c) c.studio.modes.lantern.intensity = 101 end), nil)
        eq(f.p.Update(function(c) c.studio.modes.lantern.intensity = 37 end), nil)
        f.r.db.config.studio.modes.lantern.intensity = 50; f.select("lantern")
        local opacity, n = f.p.appliedSettings.opacity, #f.calls
        f.p.RefreshPresentation(true); f.p.RefreshPresentation(true)
        eq(f.r.presentation.tint.color[4], opacity); eq(#f.calls, n)
    end)
    test("T06 return optics are explicit and capture owned originals rather than targets", function()
        local f = make(); local light = f.ns.Baseline.Capture(f.r, "current")
        eq(light.includeOptics, false); eq(light.values.ResampleSharpness, nil)
        f.variant("nightVision", 1); f.select("nightVision")
        local all = f.ns.Baseline.Capture(f.r, "current", true)
        eq(all.values.ResampleSharpness, "1.7700"); eq(all.values.ResampleAlwaysSharpen, "0")
        eq(all.values.Brightness, "052.00"); assert(f.ns.Baseline.Validate(all))
    end)
    test("T07 chosen optical reference sits below quality and mode without duplicating originals", function()
        local f = make(); f.r.db.baseline = f.ns.Baseline.Capture(f.r, "current", true)
        f.r.db.baseline.values.ResampleSharpness = "1.200"
        f.select("natural"); eq(f.values.ResampleSharpness, "1.2")
        f.quality({ ResampleSharpness = 0.9 }); f.variant("nightVision", 1); f.select("nightVision")
        eq(f.values.ResampleSharpness, "0.6"); f.quality({ ResampleSharpness = 0.7 })
        f.select("natural"); eq(f.values.ResampleSharpness, "0.7"); f.p.Observe(); eq(f.p.baselineVerified, true)
        f.quality({}); eq(f.values.ResampleSharpness, "1.2")
        eq(f.r.db.experiments.journal.entries.ResampleSharpness.originalRaw, "1.7700")
        f.restore(); eq(f.values.ResampleSharpness, "1.7700"); eq(next(f.r.db.optics.reference), nil)
        eq(f.r.db.baseline.values.ResampleSharpness, "1.200")
    end)
    test("T08 disabling an applied optical reference releases its records exactly", function()
        local f = make(); f.r.db.baseline = f.ns.Baseline.Capture(f.r, "current", true)
        f.r.db.baseline.values.ResampleSharpness = "0.4"; f.select("natural")
        f.r.db.baseline = f.ns.Baseline.Capture(f.r, "current", false); f.select("natural")
        eq(f.values.ResampleSharpness, "1.7700"); eq(f.r.db.experiments.journal.entries.ResampleSharpness, nil)
    end)
    test("T09 matching off-grid optical reference uses the exact no-setter release", function()
        local f = make(); f.r.db.baseline = f.ns.Baseline.Capture(f.r, "current", true)
        f.variant("nightVision", 1); f.select("nightVision"); f.select("natural")
        eq(f.values.ResampleSharpness, "1.7700"); eq(f.r.db.experiments.journal.entries.ResampleSharpness, nil)
        local n = #f.calls; f.quality({}); eq(#f.calls, n)
    end)
    test("T10 comparison preserves unrelated reference requests and returns applied intensity", function()
        local f = make(); f.r.db.baseline = f.ns.Baseline.Capture(f.r, "current", true)
        f.r.db.baseline.values.bloomUserMult = "0.4"
        f.variant("nightVision", 1); f.r.db.config.studio.modes.nightVision.intensity = 50; f.select("nightVision")
        f.compare("before"); eq(f.values.bloomUserMult, "0.4"); eq(f.values.ResampleSharpness, "1.7700")
        f.compare("done"); eq(f.values.bloomUserMult, "0.4"); eq(f.values.Brightness, "64")
        f.restore(); eq(f.values.bloomUserMult, "0.8")
    end)
    test("T11 unavailable unowned bloom is disclosed before applying a useful mode", function()
        local f = make(); f.env.C_VideoOptions.IsLinearEnabledOnStart = function() return false end
        f.variant("clarity", 2); f.r.ui.edited = "clarity"; f.r.ui.Open(1)
        assert(f.r.ui.hint:find("bloom")); f.select("clarity")
        eq(f.values.bloomUserMult, "0.8"); eq(f.values.ResampleSharpness, "0.7"); eq(f.values.Brightness, "052.00")
        assert(f.p.lastMessage:find("bloom")); eq(f.r.db.config.studio.modes.clarity.useBloom, true)
    end)
    test("T12 unavailable optional ownership is retained and cannot be silently skipped", function()
        local f = make(); f.variant("clarity", 2); f.select("clarity")
        f.env.C_VideoOptions.IsLinearEnabledOnStart = function() return false end
        f.variant("nightVision", 1); local n = #f.calls
        eq(f.p.Select("nightVision"), nil); eq(#f.calls, n)
        eq(f.r.db.experiments.journal.entries.bloomUserMult.originalRaw, "0.8")
    end)
    test("T13 optional failure after the first write compensates instead of reporting a successful partial mode", function()
        local f = make(); f.variant("nightVision", 1)
        f.setter = function(key, raw) if key == "ResampleSharpness" then return false end; f.values[key] = raw; return true end
        f.p.Select("nightVision"); f.mock.Flush()
        assert(f.p.state ~= "ACTIVE"); eq(f.values.Brightness, "052.00"); eq(f.values.ResampleAlwaysSharpen, "0")
    end)
    test("T14 legacy preset import defaults intensity and new export retains it", function()
        local f = make(); f.variant("moonlight", 2); f.r.db.config.studio.modes.moonlight.intensity = 65
        local id = assert(f.p.SavePreset("Quiet", "moonlight")); local encoded = f.ns.StudioConfig.ExportPreset(f.r.db.config.studio, id)
        assert(encoded:match("^LSMODE3;")); local copy = assert(f.p.ImportPreset("Copy", encoded))
        eq(f.r.db.config.studio.presets[copy].settings.intensity, 65)
        local legacy = encoded:gsub("^LSMODE3;", "LSMODE2;"):gsub(";65$", "")
        local old = assert(f.p.ImportPreset("Legacy", legacy)); eq(f.r.db.config.studio.presets[old].settings.intensity, 100)
        eq(f.p.ImportPreset("Bad", encoded:gsub(";65$", ";101")), nil); eq(#f.calls, 0)
    end)
    test("T15 schema 9 upgrade preserves old appearance completion requests and originals", function()
        local f = make(); f.variant("lantern", 1); f.select("lantern"); f.r.db.onboarding.completed = true
        local old = f.ns.Value.Copy(f.r.db); old.schemaVersion, old.optics.reference, old.baseline.includeOptics = 9, nil, nil
        for _, m in pairs(old.config.studio.modes) do m.intensity = nil end
        local g = make(old, f.values); eq(#g.calls, 0); eq(g.r.storeStatus, "MIGRATED_9_TO_21")
        eq(g.r.db.config.studio.modes.lantern.intensity, 100); eq(g.r.db.onboarding.completed, true)
        eq(g.r.db.baseline.includeOptics, false); eq(g.r.db.experiments.journal.entries.ResampleSharpness.originalRaw, "1.7700")
    end)
    test("T16 setup optical choice saves and reloads without applying graphics", function()
        local f = make(); assert(f.r.setup.Open()); f.mock.Click("Include sharpening and bloom in return look")
        assert(f.r.setup.SaveAndClose()); eq(f.r.db.baseline.includeOptics, true); eq(#f.calls, 0)
        local g = make(f.r.db, f.values); eq(g.r.db.baseline.values.ResampleSharpness, "1.7700"); eq(#g.calls, 0)
        eq(g.r.db.onboarding.completed, true)
    end)
    test("T17 AO detail uses an isolated bounded trial with exact restoration", function()
        local f = make(); local ok, why = f.r.lab.Test("assaoDetailShadowStrength", 0.25); assert(ok, why)
        f.mock.Flush(); eq(f.values.assaoDetailShadowStrength, "0.00"); eq(#f.calls, 2)
        for _, call in ipairs(f.calls) do eq(call[1], "assaoDetailShadowStrength") end
        eq(f.r.lab.Apply("quality", { assaoDetailShadowStrength = 0.25 }), nil)
        eq(f.r.lab.SaveProfile("vista", "assaoDetailShadowStrength", 0.25), nil)
    end)
    test("T18 AO context absence disabled banks or out-of-policy values refuse only this trial", function()
        for _, change in ipairs({ { SSAO = "0" }, { RAIDsettingsEnabled = "1", RAIDSSAO = "0" }, { SSAO = "bad" }, { assaoDetailShadowStrength = "1.0" } }) do
            local f = make(nil, change); eq(f.r.lab.Test("assaoDetailShadowStrength", 0.25), nil); eq(#f.calls, 0)
            f.select("nightVision"); eq(f.values.Brightness, "75")
        end
        local f = make(); eq(f.r.lab.Test("assaoDetailShadowStrength", 0.55), nil)
        eq(f.r.lab.Test("assaoDetailShadowStrength", 0.23), nil); eq(#f.calls, 0)
    end)
    test("T19 AO dependency drift stops automatic restoration and preserves external state", function()
        local f = make(); assert(f.r.lab.Test("assaoDetailShadowStrength", 0.25))
        f.values.assaoRadius = "2.5"; f.mock.Flush()
        eq(f.values.assaoRadius, "2.5"); eq(f.values.assaoDetailShadowStrength, "0.25")
        eq(f.r.db.experiments.journal.entries.assaoDetailShadowStrength.originalRaw, "0.00")
        local g = make(f.r.db, f.values); eq(#g.calls, 0)
    end)
    test("T20 AO setter rejection clamps and restore failures retain recovery", function()
        local f = make(); f.setter = function(key, raw) f.values[key] = "0.3"; return true end
        f.r.lab.Test("assaoDetailShadowStrength", 0.25); f.mock.Flush()
        eq(f.r.db.experiments.journal.entries.assaoDetailShadowStrength.originalRaw, "0.00")
        local n = #f.calls; f.ns.Report.Export(f.r); eq(#f.calls, n)
    end)
    test("T21 invalid reference and intensity saved values quarantine read-only", function()
        for _, change in ipairs({ function(d) d.baseline.includeOptics = "yes" end,
            function(d) d.baseline.includeOptics = true; d.baseline.values.ResampleSharpness = "3" end,
            function(d) d.optics.reference.Gamma = 1 end,
            function(d) d.config.studio.modes.nightVision.intensity = -1 end }) do
            local f = make(); local old = f.ns.Value.Copy(f.r.db); change(old); local g = make(old)
            eq(g.r.db, nil); eq(#g.calls, 0)
        end
    end)
    test("T22 unrelated failed AO recovery does not veto or relabel a valid composite visual mode", function()
        local f = make(); f.setter = function(key, raw) f.values[key] = "0.3"; return true end
        f.r.lab.Test("assaoDetailShadowStrength", 0.25); f.mock.Flush(); f.setter = nil
        f.variant("cinematic", 2); f.select("cinematic"); f.p.Observe()
        eq(f.p.state, "ACTIVE"); eq(f.values.Contrast, "58")
        eq(f.r.db.experiments.journal.entries.assaoDetailShadowStrength.originalRaw, "0.00")
        local n = #f.calls; local choices = f.ns.NativeGraphics.Draft(f.r); choices.raidEnabled = "on"
        local ok, why = f.r.graphics.Apply(choices); eq(ok, nil); eq(why, "RESTORE_CONTACT_DEPTH_FIRST"); eq(#f.calls, n)
    end)
    test("T23 comparison external edits and owned reference drift retain both captures", function()
        local f = make(); f.r.db.baseline = f.ns.Baseline.Capture(f.r, "current", true)
        f.r.db.baseline.values.ResampleSharpness = "0.4"
        f.variant("nightVision", 1); f.select("nightVision"); f.compare("before")
        f.values.ResampleSharpness = "0.9"; local n = #f.calls
        eq(f.p.Compare("done"), nil); eq(#f.calls, n); eq(f.values.ResampleSharpness, "0.9")
        eq(f.r.db.experiments.journal.entries.ResampleSharpness.originalRaw, "1.7700")
        eq(f.r.db.baseline.values.ResampleSharpness, "0.4")
    end)
    test("T24 Game Defaults optical reference uses only valid reported values", function()
        local f = make(); local defaults = { Brightness = "50", Contrast = "50", ResampleAlwaysSharpen = "0", ResampleSharpness = "0.2", bloomUserMult = "1" }
        f.env.C_CVar.GetCVarDefault = function(key) return defaults[key] end
        -- Conflicting getters are deliberately not accepted as a default.
        eq(f.ns.Baseline.Capture(f.r, "gameDefaults", true).values.ResampleSharpness, nil)
        f.env.C_CVar.GetCVarInfo = function(key) return f.values[key], defaults[key] or "50", false, false, false, false, false end
        f.r.db.baseline = f.ns.Baseline.Capture(f.r, "gameDefaults", true)
        eq(f.r.db.baseline.values.ResampleSharpness, "0.2"); eq(#f.calls, 0)
        f.select("natural"); eq(f.values.ResampleSharpness, "0.2"); eq(f.values.Brightness, "50")
        f.restore(); eq(f.values.ResampleSharpness, "1.7700"); eq(f.values.Brightness, "052.00")
    end)
    test("T25 AO interrupted restoration is explicit and never replays on reload", function()
        local f = make(); assert(f.r.lab.Test("assaoDetailShadowStrength", 0.25))
        local g = make(f.r.db, f.values); eq(#g.calls, 0)
        assert(g.r.lab.PreviewRestore("quality")); assert(g.r.lab.Confirm(g.r.lab.Status().token)); g.mock.Flush()
        eq(g.values.assaoDetailShadowStrength, "0.00"); eq(g.r.db.experiments.journal.entries.assaoDetailShadowStrength, nil)
    end)
    if os.getenv("LUMENSHIFT_UI_MODEL_PATH") then
        local f = make(); f.r.ui.Open(1); f.r.ui.scroll:SetVerticalScroll(370)
        f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-starting-looks.tsv")
        f.r.setup.Open(); f.r.ui.window:Hide(); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-return-setup.tsv")
        f.r.setup.window:Hide(); f.r.ui.labKey = "assaoDetailShadowStrength"; f.r.ui.Open(8)
        f.r.ui.scroll:SetVerticalScroll(250); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-contact-depth.tsv")
    end
end
