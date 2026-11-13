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
        function f.check(id)
            for _, item in ipairs(f.r.checks) do if item.id == id then return item end end
            error("missing check " .. id)
        end
        return f
    end
    test("K01 reported 70840 client completes setup and one reload without any graphics writes", function()
        local f = make(); f.enter(); eq(f.r.setup.next.label:GetText(), "Next: Graphics")
        f.mock.Click("Next: Graphics"); f.mock.Click("Finish & Reload UI"); eq(f.reloads, 1); eq(#f.calls, 0)
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
        eq(#f.calls, 0); eq(f.reloads, 0); eq(f.r.setup.draft.effects, true); f.zero()
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
    test("K06 version and interface differences warn but do not disable normal controls", function()
        for _, tuple in ipairs({ { "70789", 16001 }, { "70862", 16002 }, { "70862", 16001, "1.60.2" }, { "70862", 16001, "12.0.0" } }) do
            local f = make(tuple[1], function(f) identity(f, unpack(tuple)) end); f.enter()
            eq(f.check("client-identity").status, "WARN"); assert(f.r.product.CanEnable())
            eq(#f.calls, 0); assert(f.r.setup.Finish()); eq(#f.calls, 0)
            assert(f.r.product.Select("nightVision")); f.mock.Flush(); eq(f.values.Brightness, "75")
            assert(f.r.product.Select("natural")); f.mock.Flush(); eq(f.values.Brightness, "45")
            assert(f.r.lab.Test("Contrast", 65)); f.mock.Flush(); eq(f.values.Contrast, "60")
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
    test("K09 explicit recovery after a build update preserves provenance until verified restoration", function()
        for _, leaf in ipairs({ false, true }) do
            local old = make("70790"); local engine = leaf and old.r.lab or old.r.engine
            if leaf then assert(engine.Preview("Contrast", 65)) else assert(engine.Prepare("on")) end
            assert(engine.Confirm(engine.Status().token))
            local key = leaf and "Contrast" or "Brightness"
            local f = make("70840", function(g) g.values[key] = leaf and "65" or "75" end, old.r.db); f.enter()
            eq(#f.calls, 0)
            local current = leaf and f.r.lab or f.r.engine
            if leaf then assert(current.PreviewRestore("visual")) else assert(current.Prepare("restore")) end
            eq(#f.calls, 0); assert(current.Confirm(current.Status().token))
            local journal = leaf and f.r.db.experiments.journal or f.r.db.journal
            eq(journal.entries[key].signature, "1.60.1:70790:16001")
            if leaf then f.mock.Flush() else assert(current.Verify()) end
            eq(f.values[key], leaf and "60" or "45")
            eq(next((leaf and f.r.db.experiments.journal or f.r.db.journal).entries), nil)
            eq(#f.calls, 1); eq(f.reloads, 0)
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
        eq(e.Descriptor("Contrast", bounds), nil); eq(e.Descriptor("Contrast", bounds, "invalid-identity"), nil)
        local descriptor = assert(e.Descriptor("Contrast", bounds, "1.60.1:70840:16001"))
        eq(c.Admitted(descriptor, e.Context("1.60.1:70790:16001")), false)
        eq(c.Get("Brightness").admitted, false); eq(c.Get("Contrast").admitted, false)
        eq(f.ns.Compatibility.Inspect(f.r.reader).futureWrites, false)
        local signatures = f.ns.Compatibility.ObservedSignatures(); signatures[1] = "forged"
        eq(f.ns.Compatibility.Experimental("forged"), false)
    end)
    test("K12 compact setup has readable scale and bounded frame reuse without saving drafts early", function()
        local f = make(nil, function(f) f.env.UIParent:SetSize(1920, 1080); f.env.UIParent:SetScale(0.71111112833023) end)
        f.enter(); eq(f.r.setup.window:GetWidth(), 640)
        assert(math.abs(f.r.setup.window:GetEffectiveScale() - 1) < 0.001)
        f.mock.Click("Night Vision sounds"); eq(f.r.setup.draft.sound, true); eq(f.r.db.config.preferences.sound, false)
        local count = #f.mock.nodes
        for _ = 1, 20 do f.r.setup.Build() end
        eq(#f.mock.nodes, count); eq(f.r.setup.draft.sound, true); eq(#f.calls, 0); eq(f.reloads, 0)
        local small = make(nil, function(g) g.env.UIParent:SetSize(800, 600) end); small.enter()
        assert(small.r.setup.window:GetWidth() * small.r.setup.window.scale < 800)
        assert(small.r.setup.window:GetHeight() * small.r.setup.window.scale < 600)
    end)
    test("K13 owner dev.5 70862 report reproduces setup refresh and button-only usable modes", function()
        local old = make(); local saved = old.ns.Value.Copy(old.r.db)
        saved.addonVersion = "0.2.0-dev.5"; saved.onboarding.completed = true
        saved.config.studio.enabled = false; saved.config.preferences.sound = true
        local f = make("70862", nil, saved); f.enter()
        eq(f.r.identity.status, "OBSERVED_CLIENT_IDENTITY"); eq(f.r.storeStatus, "SETUP_REFRESH_REQUIRED")
        assert(f.r.setup.window:IsShown()); eq(f.r.setup.draft.sound, true); eq(#f.calls, 0)
        eq(saved.onboarding.completed, true); eq(saved.addonVersion, "0.2.0-dev.5") -- copy-only upgrade
        f.mock.Click("Next: Graphics"); f.mock.Click("Finish & Reload UI"); eq(f.reloads, 1); eq(#f.calls, 0)
        local again = make("70862", nil, f.saved); again.enter(); eq(again.r.setup.window, nil)
        again.r.entry.Open("LeftButton"); again.mock.Click("Night Vision"); again.mock.Flush()
        eq(again.values.Brightness, "75"); eq(again.r.db.journal.entries.Brightness.originalRaw, "45")
        again.r.entry.Open("LeftButton"); again.mock.Click("Original"); again.mock.Flush()
        eq(again.values.Brightness, "45"); eq(#again.calls, 2)
        assert(again.ns.Report.Export(again.r):find("Mode controls: AVAILABLE", 1, true))
    end)
    test("K14 hotfix numbers do not individually lock the supported client family", function()
        for _, build in ipairs({ "70790", "70791", "70840", "70862", "70999" }) do
            local f = make(build); f.enter(); eq(#f.calls, 0)
            assert(f.r.product.Select("lantern")); f.mock.Flush(); eq(f.values.Brightness, "65")
            assert(f.r.product.Select("natural")); f.mock.Flush(); eq(f.values.Brightness, "45")
            assert(f.r.lab.Test("Contrast", 65)); f.mock.Flush(); eq(f.values.Contrast, "60")
            eq(#f.calls, 4)
        end
    end)
    test("K15 malformed identities stay invalid and reference-policy copies cannot change warning behavior", function()
        local f = make("70862"); local c = f.ns.Compatibility
        for _, signature in ipairs({ "1.60.1:foo:16001", "1.60.1:070862:16001", "1.60.1:70862x:16001",
            "1.60.1:70862:016001", "1.60.1:0:16001", "1.60.1:70862:0" }) do
            eq(c.Experimental(signature), false)
        end
        eq(c.Experimental(nil), false); eq(c.Experimental({}), false)
        local policy = c.Policy(); policy.interface = 16002; policy.version = "1.60.2"; policy.minimumBuild = 1
        eq(c.Policy().version, "1.60.1"); eq(c.Policy().mismatchAction, "warn"); assert(c.Experimental("1.60.2:1:16002"))
        eq(#f.calls, 0)
    end)
    test("K16 current hotfix still rejects unavailable and restricted native controls without a write", function()
        for _, configure in ipairs({
            function(f) f.env.C_CVar.SetCVar = nil end,
            function(f) f.env.C_CVar.GetCVar = nil end,
            function(f) f.env.C_CVar.GetCVarInfo = function(k) return f.values[k], "50", false, false, false, true, false end end,
        }) do
            local f = make("70862", configure); eq(f.r.product.Select("nightVision"), nil)
            eq(f.r.lab.Test("Contrast", 65), nil); eq(#f.calls, 0)
            local text = f.ns.Report.Export(f.r); eq(text:find("Mode controls: AVAILABLE", 1, true), nil)
            eq(text:find("production write admission unavailable", 1, true), nil)
        end
    end)
    test("K17 setup refresh retains ownership and preferences and stops repeating after Save", function()
        local old = make("70862"); assert(old.r.product.Select("nightVision")); old.mock.Flush()
        local saved = old.ns.Value.Copy(old.r.db)
        saved.addonVersion = "0.2.0-dev.4"; saved.onboarding.completed = true
        saved.config.studio.modes.lantern.brightness = 67; saved.config.preferences.sound = true
        local f = make("70862", function(g) g.values.Brightness = "75" end, saved); f.enter()
        assert(f.r.setup.window:IsShown()); eq(f.r.db.journal.entries.Brightness.originalRaw, "45")
        eq(f.r.db.config.studio.modes.lantern.brightness, 67); eq(f.r.setup.draft.sound, true)
        assert(f.r.setup.Finish()); eq(f.reloads, 1); eq(#f.calls, 0)
        eq(f.r.db.onboarding.completed, true)
        local nextLogin = make("70862", nil, f.r.db); nextLogin.enter()
        eq(nextLogin.r.setup.window, nil); eq(#nextLogin.calls, 0)
        eq(nextLogin.r.db.journal.entries.Brightness.originalRaw, "45")
    end)
    test("K25 owner dev10 70862 Cinematic reload report resumes on click and restores actual 45", function()
        local first = make("70862"); first.enter(); assert(first.r.setup.SaveAndClose())
        assert(first.r.product.Select("cinematic")); first.mock.Flush(); eq(first.values.Brightness, "42")
        local f = make("70862", function(g) g.values.Brightness = "42" end, first.r.db)
        f.enter(); f.ns.Report.Export(f.r); eq(#f.calls, 0); eq(f.r.engine.Status().state, "RECOVERY")
        assert(f.r.product.Availability()); eq(f.r.engine.Status().state, "RECOVERY")
        assert(f.r.product.Select("nightVision")); f.mock.Flush(); eq(f.values.Brightness, "75")
        eq(f.r.engine.Status().original, "45"); eq(f.r.product.active, "nightVision")
        assert(f.r.product.Select("natural")); f.mock.Flush(); eq(f.values.Brightness, "45")
        eq(f.r.engine.Status().state, "BASELINE"); eq(#f.calls, 2)
    end)
    test("K18 a hotfix cannot retag an interrupted operation or historical recovery", function()
        for _, leaf in ipairs({ false, true }) do
            local f = make("70862"); local engine = leaf and f.r.lab or f.r.engine
            if leaf then assert(engine.Preview("Contrast", 65)) else assert(engine.Prepare("on")) end
            local token = engine.Status().token; identity(f, "70999")
            local ok, why = engine.Confirm(token); eq(ok, nil); eq(why, "SESSION_BUILD_CHANGED"); eq(#f.calls, 0)
        end
    end)
    test("K19 mismatch warning is nonblocking, shown once, and exported as WARN instead of BLOCKED", function()
        local f = make("71000", function(g) identity(g, "71000", 16002, "1.60.2") end)
        f.enter(); f.enter(); f.frame.OnEvent(f.frame, "PLAYER_REGEN_ENABLED")
        local notices = 0
        for _, line in ipairs(f.output) do if line:find("has not been reviewed", 1, true) then notices = notices + 1 end end
        eq(notices, 1); eq(#f.calls, 0)
        local text = f.ns.Report.Export(f.r)
        assert(text:find("WARN | client-identity | UNREVIEWED_CLIENT_WARNING", 1, true))
        assert(text:find("Mode controls: AVAILABLE", 1, true)); eq(text:find("BLOCKED | client-identity", 1, true), nil)
        assert(f.r.product.Select("nightVision")); f.mock.Flush(); eq(f.values.Brightness, "75")
        f.enter(); local after = 0
        for _, line in ipairs(f.output) do if line:find("has not been reviewed", 1, true) then after = after + 1 end end
        eq(after, 1); assert(f.r.product.Select("natural")); f.mock.Flush(); eq(f.values.Brightness, "45")
    end)
    test("K20 failed warning display never becomes an approval gate; API failures still refuse", function()
        local f = make("71000", function(g)
            identity(g, "71000", 16002, "1.60.2"); g.env.DEFAULT_CHAT_FRAME.AddMessage = function() error("unavailable") end
        end)
        f.enter(); assert(f.r.product.Select("lantern")); f.mock.Flush(); eq(f.values.Brightness, "65")
        local unavailable = make("71000", function(g)
            identity(g, "71000", 16002, "1.60.2"); g.env.C_CVar.SetCVar = nil
        end)
        unavailable.enter(); eq(unavailable.r.product.Select("nightVision"), nil); eq(#unavailable.calls, 0)
        eq(unavailable.check("client-identity").status, "WARN"); eq(unavailable.check("native-setter").status, "BLOCKED")
    end)
    test("K21 failed cross-version recovery keeps exact originals and their source identity", function()
        for _, leaf in ipairs({ false, true }) do
            local old = make("70862"); local engine = leaf and old.r.lab or old.r.engine
            if leaf then assert(engine.Preview("Contrast", 65)) else assert(engine.Prepare("on")) end
            assert(engine.Confirm(engine.Status().token))
            local key = leaf and "Contrast" or "Brightness"
            local f = make("71000", function(g)
                identity(g, "71000", 16002, "1.60.2"); g.values[key] = leaf and "65" or "75"
                g.env.C_CVar.SetCVar = function() g.calls[#g.calls + 1] = "failed"; return false end
            end, old.r.db)
            local recovery = leaf and f.r.lab or f.r.engine
            if leaf then assert(recovery.PreviewRestore("visual")) else assert(recovery.Prepare("restore")) end
            eq(recovery.Confirm(recovery.Status().token), nil); eq(#f.calls, 1)
            local journal = leaf and f.r.db.experiments.journal or f.r.db.journal
            eq(journal.entries[key].originalRaw, leaf and "60" or "45")
            eq(journal.entries[key].signature, "1.60.1:70862:16001"); eq(recovery.Status().state, "RECOVERY")
        end
    end)
    test("K22 mixed historical visual and quality originals restore independently on a newer version", function()
        local old = make("70790")
        assert(old.r.lab.Apply("visual", { Contrast = 65 })); old.mock.Flush()
        assert(old.r.lab.Apply("quality", { ResampleSharpness = 1.1 })); old.mock.Flush()
        old.r.db.experiments.journal.entries.ResampleSharpness.signature = "1.60.1:70840:16001"
        local f = make("71000", function(g)
            identity(g, "71000", 16002, "1.60.2"); g.values.Contrast = "65"; g.values.ResampleSharpness = "1.1"
        end, old.r.db)
        eq(#f.calls, 0); assert(f.r.lab.PreviewRestore("visual")); assert(f.r.lab.Confirm(f.r.lab.Status().token)); f.mock.Flush()
        eq(f.values.Contrast, "60"); eq(f.values.ResampleSharpness, "1.1")
        eq(f.r.db.experiments.journal.entries.ResampleSharpness.signature, "1.60.1:70840:16001")
        assert(f.r.lab.PreviewRestore("quality")); assert(f.r.lab.Confirm(f.r.lab.Status().token)); f.mock.Flush()
        eq(f.values.ResampleSharpness, "1"); eq(next(f.r.db.experiments.journal.entries), nil); eq(#f.calls, 2)
    end)
    test("K23 version-warning recovery already at the original releases without a native setter call", function()
        for _, leaf in ipairs({ false, true }) do
            local old = make("70862"); local engine = leaf and old.r.lab or old.r.engine
            if leaf then assert(engine.Preview("Contrast", 65)) else assert(engine.Prepare("on")) end
            assert(engine.Confirm(engine.Status().token))
            local f = make("71000", function(g) identity(g, "71000", 16002, "1.60.2") end, old.r.db)
            local recovery = leaf and f.r.lab or f.r.engine
            if leaf then assert(recovery.PreviewRestore("visual")) else assert(recovery.Prepare("restore")) end
            assert(recovery.Confirm(recovery.Status().token))
            if leaf then f.mock.Flush() else assert(recovery.Verify()) end
            eq(#f.calls, 0); eq(recovery.Status().state, "BASELINE")
        end
    end)
    test("K24 reconciliation cannot become a new-target shortcut around ownership checks", function()
        local f = make("70862"); local ns = f.ns
        local catalog, context = ns.Catalog.BrightnessExperiment("1.60.1:70862:16001")
        context.explicitRecovery = true
        local seen = { Brightness = ns.ReadOnly.Read(f.r.reader, "Brightness") }
        local plan, why = ns.Planner.Build(catalog, context, seen, ns.Store.EmptyJournal(), "visual", { Brightness = 75 })
        eq(plan, nil); eq(why, "INVALID_RECOVERY_REQUEST"); eq(#f.calls, 0)
    end)
    local path = os.getenv("LUMENSHIFT_SETUP_MODEL_PATH")
    if path then
        local f = make(); f.enter()
        f.mock.Export(path .. "-compact.tsv")
    end
end
