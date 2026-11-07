-- Regression fixtures from the owner's dev.3 report. These are simulations, not native results.
return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function identity(f, build, interface, version)
        f.env.GetBuildInfo = function() return version or "1.60.1", build, "Nov 5 2026", interface or 16001 end
    end
    local function make(build, configure, saved)
        local f = fixture(saved); f.mock = widgets(f.env); f.calls, f.reloads = {}, 0
        identity(f, build or "70840")
        for _, key in ipairs(f.ns.Catalog.WatchKeys()) do if not f.values[key] then f.values[key] = "100" end end
        f.values.Brightness, f.values.Contrast, f.values.gxapi = "45", "60", "d3d12"
        f.values.ResampleSharpness, f.values.ResampleAlwaysSharpen, f.values.bloomUserMult = "1", "0", "0.2"
        f.env.C_CVar.SetCVar = function(key, value)
            local db = f.env.LumenShiftDB
            local entry = key == "Brightness" and db.journal.entries[key] or db.experiments.journal.entries[key]
            assert(entry and entry.originalRaw, "capture before write")
            f.calls[#f.calls + 1] = { key, value }; f.values[key] = value; return true
        end
        f.env.ReloadUI = function() f.reloads = f.reloads + 1; f.saved = f.ns.Value.Copy(f.env.LumenShiftDB) end
        if configure then configure(f) end
        f.load(); f.r = f.ns.runtime
        function f.enter() f.frame.OnEvent(f.frame, "PLAYER_ENTERING_WORLD") end
        function f.next() f.r.setup.next.scripts.OnClick(f.r.setup.next) end
        function f.check(id)
            for _, item in ipairs(f.r.checks) do if item.id == id then return item end end
            error("missing check " .. id)
        end
        return f
    end
    test("K01 reported 70840 client completes setup and one reload without any graphics writes", function()
        local f = make(); f.enter(); assert(f.r.setup.draft.enabled)
        eq(f.r.setup.next.label:GetText(), "Choose preferences"); f.mock.Click("Choose preferences")
        f.mock.Click("Review choices"); f.mock.Click("I know how to restore my settings")
        f.mock.Click("Finish & Reload UI"); eq(f.reloads, 1); eq(#f.calls, 0)
        eq(f.saved.onboarding.completed, true); eq(f.saved.config.studio.enabled, true)
        local again = make("70840", nil, f.saved); again.enter(); eq(again.r.setup.window, nil)
        eq(#again.calls, 0); eq(again.r.product.active, "natural"); f.zero(); again.zero()
    end)
    test("K02 both exact experimental builds restore raw Brightness originals through user mode selection", function()
        for _, build in ipairs({ "70790", "70840" }) do
            local f = make(build, function(f) f.values.Brightness = "045.00" end)
            assert(f.r.product.Enable(true)); assert(f.r.product.Select("nightVision")); f.mock.Flush()
            eq(f.values.Brightness, "75"); eq(f.r.db.journal.entries.Brightness.signature, "1.60.1:" .. build .. ":16001")
            assert(f.r.product.Select("natural")); f.mock.Flush(); eq(f.values.Brightness, "045.00")
            eq(#f.calls, 2); eq(next(f.r.db.journal.entries), nil)
        end
    end)
    test("K03 70840 leaf calibration, Contrast and independent quality profiles carry the actual signature", function()
        local f = make(); local lab = f.r.lab
        for _, pair in ipairs({ { "Contrast", 65 }, { "ResampleSharpness", 1.1 } }) do
            assert(lab.Preview(pair[1], pair[2])); assert(lab.Confirm(lab.Status().token)); f.mock.Flush()
            assert(lab.certificates[pair[1]][tostring(pair[2])])
        end
        eq(f.values.Contrast, "60"); eq(f.values.ResampleSharpness, "1")
        assert(lab.SaveProfile("balanced", "ResampleSharpness", 1.1)); assert(lab.SelectProfile("balanced")); f.mock.Flush()
        eq(f.r.db.experiments.journal.entries.ResampleSharpness.signature, "1.60.1:70840:16001")
        assert(f.r.product.Enable(true))
        assert(f.r.product.Update(function(c) c.studio.modes.nightVision.useContrast = true; c.studio.modes.nightVision.contrast = 65 end))
        assert(f.r.product.Select("nightVision")); f.mock.Flush()
        eq(f.values.Contrast, "65"); eq(f.values.ResampleSharpness, "1.1")
        assert(f.r.product.Select("natural")); f.mock.Flush()
        eq(f.values.Brightness, "45"); eq(f.values.Contrast, "60"); eq(f.values.ResampleSharpness, "1.1")
        assert(lab.SelectProfile("currentBaseline")); f.mock.Flush(); eq(f.values.ResampleSharpness, "1")
    end)
    test("K04 readiness at world entry replaces transient startup checks without writes or reload", function()
        local loaded = false
        local f = make(nil, function(f) f.env.C_CVar.AreCVarsLoaded = function() return loaded end end)
        eq(f.check("read-Brightness").detail, "CVARS_NOT_LOADED")
        eq(f.check("calibration-preflight-Contrast").detail, "CVARS_NOT_LOADED")
        loaded = true; f.enter()
        eq(f.check("read-Brightness").status, "PASS"); eq(f.check("client-identity").status, "PASS")
        eq(f.check("calibration-preflight-Contrast").status, "PASS")
        eq(#f.calls, 0); eq(f.reloads, 0); assert(f.r.setup.draft.enabled); f.zero()
    end)
    test("K05 export refreshes stale checks in either direction and never completes a pending calibration", function()
        local f = make(); f.env.C_CVar.AreCVarsLoaded = function() return false end
        local text = f.ns.Report.Export(f.r); eq(f.check("read-Brightness").status, "BLOCKED")
        f.env.C_CVar.AreCVarsLoaded = function() return true end
        text = f.ns.Report.Export(f.r); eq(f.check("read-Brightness").status, "PASS")
        assert(text:find("build 70840", 1, true)); assert(text:find("NOT TESTED | native-writes", 1, true))
        assert(f.r.lab.Preview("Contrast", 65)); assert(f.r.lab.Confirm(f.r.lab.Status().token))
        local calls = #f.calls; f.ns.Report.Export(f.r); eq(#f.calls, calls)
        eq(f.r.lab.Status().state, "AWAITING_VERIFICATION"); eq(f.r.lab.certificates.Contrast, nil)
    end)
    test("K06 unreviewed identities remain read-only and are explained before finishing", function()
        for _, tuple in ipairs({ { "70841", 16001 }, { "70791", 16001 }, { "70840", 16002 }, { "70840", 16001, "1.60.2" } }) do
            local f = make(tuple[1], function(f) identity(f, unpack(tuple)) end); f.enter()
            eq(f.r.setup.draft.enabled, false); eq(f.r.product.CanEnable(), nil)
            local enabled, code, explanation = f.r.product.Enable(true)
            eq(enabled, nil); eq(code, "UNSUPPORTED_BUILD"); assert(explanation:find("has not been reviewed", 1, true))
            eq(f.r.log.issues[#f.r.log.issues].result, "UNSUPPORTED_BUILD")
            eq(f.r.engine.Prepare("on"), nil); eq(f.r.lab.Preview("Contrast", 65), nil)
            f.next(); f.next(); f.mock.Click("Enable visual switching")
            eq(f.r.setup.draft.enabled, false); assert(f.r.setup.message:find("has not been reviewed", 1, true))
            f.mock.Click("I know how to restore my settings"); assert(f.r.setup.Finish())
            eq(f.saved.config.studio.enabled, false); eq(#f.calls, 0)
        end
    end)
    test("K07 changing between reviewed builds invalidates both pending preview types", function()
        for _, build in ipairs({ "70790", "70840" }) do
            for _, leaf in ipairs({ false, true }) do
                local f = make(build); local engine = leaf and f.r.lab or f.r.engine
                if leaf then assert(engine.Preview("Contrast", 65)) else assert(engine.Prepare("on")) end
                local token = engine.Status().token; identity(f, build == "70790" and "70840" or "70790")
                local ok, why = engine.Confirm(token); eq(ok, nil); eq(why, "SESSION_BUILD_CHANGED"); eq(#f.calls, 0)
            end
        end
    end)
    test("K08 a build change during verification retains originals without automatic compensation", function()
        for _, leaf in ipairs({ false, true }) do
            local f = make(); local engine = leaf and f.r.lab or f.r.engine
            if leaf then assert(engine.Preview("Contrast", 65)) else assert(engine.Prepare("on")) end
            assert(engine.Confirm(engine.Status().token)); identity(f, "70790")
            if leaf then f.mock.Flush() else eq(engine.Verify(), nil) end
            eq(#f.calls, 1); eq(engine.Status().state, "RECOVERY")
            local journal = leaf and f.r.db.experiments.journal or f.r.db.journal
            local entry = journal.entries[leaf and "Contrast" or "Brightness"]
            eq(entry.originalRaw, leaf and "60" or "45"); eq(entry.signature, "1.60.1:70840:16001")
        end
    end)
    test("K09 reload on another reviewed build cannot retag or restore historical recovery records", function()
        for _, leaf in ipairs({ false, true }) do
            local old = make("70790"); local engine = leaf and old.r.lab or old.r.engine
            if leaf then assert(engine.Preview("Contrast", 65)) else assert(engine.Prepare("on")) end
            assert(engine.Confirm(engine.Status().token))
            local f = make("70840", nil, old.r.db); f.enter()
            local ok, why
            if leaf then ok, why = f.r.lab.PreviewRestore("visual") else ok, why = f.r.engine.Prepare("restore") end
            eq(ok, nil); eq(why, "RECOVERY_SIGNATURE_MISMATCH"); eq(#f.calls, 0); eq(f.reloads, 0)
            local journal = leaf and f.r.db.experiments.journal or f.r.db.journal
            eq(journal.entries[leaf and "Contrast" or "Brightness"].signature, "1.60.1:70790:16001")
        end
    end)
    test("K10 native API and restriction gates still apply on 70840", function()
        for _, configure in ipairs({
            function(f) f.env.C_CVar.SetCVar = nil end,
            function(f) f.env.C_CVar.GetCVar = nil end,
            function(f) f.env.C_CVar.GetCVarInfo = function(k) return f.values[k], "50", false, false, false, true, false end end,
        }) do
            local f = make(nil, configure); eq(f.r.product.Enable(true), nil)
            eq(f.r.engine.Prepare("on"), nil); eq(f.r.lab.Preview("Contrast", 65), nil); eq(#f.calls, 0)
        end
    end)
    test("K11 experimental descriptor signatures cannot be forged, omitted or promoted to production", function()
        local f = make(); local c, e = f.ns.Catalog, f.ns.ExperimentPolicy
        local bounds = assert(e.Bounds("Contrast", "60"))
        eq(e.Descriptor("Contrast", bounds), nil); eq(e.Descriptor("Contrast", bounds, "1.60.1:70841:16001"), nil)
        local descriptor = assert(e.Descriptor("Contrast", bounds, "1.60.1:70840:16001"))
        eq(c.Admitted(descriptor, e.Context("1.60.1:70790:16001")), false)
        eq(c.Get("Brightness").admitted, false); eq(c.Get("Contrast").admitted, false)
        eq(f.ns.Compatibility.Inspect(f.r.reader).futureWrites, false)
        local signatures = f.ns.Compatibility.ExperimentalSignatures(); signatures[1] = "forged"
        eq(f.ns.Compatibility.Experimental("forged"), false)
    end)
    test("K12 wizard draft review, back navigation and readable scale leave live preferences untouched", function()
        local f = make(nil, function(f) f.env.UIParent:SetSize(1920, 1080); f.env.UIParent:SetScale(0.71111112833023) end)
        f.enter(); eq(f.r.setup.window:GetWidth(), 760)
        assert(math.abs(f.r.setup.window:GetEffectiveScale() - 1) < 0.001)
        f.mock.Click("Choose preferences"); f.mock.Click("Activation sounds"); f.mock.Click("Review choices")
        eq(f.r.setup.draft.sound, true); eq(f.r.db.config.preferences.sound, false)
        f.mock.Click("Back"); eq(f.r.setup.draft.sound, true)
        local count = #f.mock.nodes
        for _ = 1, 20 do f.mock.Click("Review choices"); f.mock.Click("Back") end
        eq(#f.mock.nodes, count); eq(#f.calls, 0); eq(f.reloads, 0)
        local small = make(nil, function(g) g.env.UIParent:SetSize(800, 600) end); small.enter()
        assert(small.r.setup.window:GetWidth() * small.r.setup.window.scale < 800)
        assert(small.r.setup.window:GetHeight() * small.r.setup.window.scale < 600)
    end)
    local path = os.getenv("LUMENSHIFT_SETUP_MODEL_PATH")
    if path then
        local f = make(); f.enter()
        for page = 1, 3 do f.r.setup.page = page; f.r.setup.Build(); f.mock.Export(path .. "-" .. page .. ".tsv") end
    end
end
