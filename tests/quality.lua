return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function setup(saved, values)
        local f = fixture(saved); f.mock = widgets(f.env); f.calls = {}
        for _, key in ipairs(f.ns.Catalog.WatchKeys()) do if not f.values[key] then f.values[key] = "100" end end
        for _, key in ipairs(f.ns.QualityTrial.Order) do f.values[key] = "1" end
        f.values.ResampleAlwaysSharpen, f.values.ResampleSharpness, f.values.bloomUserMult = "0", "1", "0.2"
        for key, value in pairs(values or {}) do f.values[key] = value end
        f.env.IsGraphicsSettingValueSupported = function() return 0 end
        f.env.C_VideoOptions = { IsPBRWaterSupported = function() return true end, IsSecondaryLightingSupported = function() return true end }
        f.env.C_CVar.SetCVar = function(key, target)
            local record = f.env.LumenShiftDB.experiments.journal.entries[key] or f.env.LumenShiftDB.journal.entries[key]
            assert(record and record.originalRaw, "capture before native call")
            f.calls[#f.calls + 1] = { key, target }
            if f.setter then return f.setter(key, target, #f.calls) end
            f.values[key] = target; return true
        end
        f.load(); f.r = f.ns.runtime; f.t = f.r.tierTrial
        return f
    end
    test("Q01 built-in profiles are immediately usable, baseline-relative and visual-independent", function()
        local f = setup(); assert(f.r.product.Select("nightVision")); f.mock.Flush()
        assert(f.r.lab.SelectProfile("vista")); f.mock.Flush()
        eq(f.values.Brightness, "75"); eq(f.values.groundEffectDensity, "110")
        local targets = f.ns.Quality.Resolve(f.r, "vista"); eq(targets.groundEffectDensity, 110)
        assert(f.r.lab.SelectProfile("performance")); f.mock.Flush(); eq(f.values.groundEffectDensity, "90")
        assert(f.r.lab.SelectProfile("currentBaseline")); f.mock.Flush()
        eq(f.values.groundEffectDensity, "100"); eq(f.values.ResampleAlwaysSharpen, "0"); eq(f.values.Brightness, "75")
    end)
    test("Q02 saved profiles retain exact keys; missing built-in controls are disclosed", function()
        local f = setup(); f.values.farclip = nil
        local targets, omitted = f.ns.Quality.Resolve(f.r, "vista")
        eq(targets.farclip, nil); eq(#omitted, 1); eq(omitted[1], "farclip")
        assert(f.r.lab.SaveProfile("vista", "ResampleSharpness", 0.9))
        targets = f.ns.Quality.Resolve(f.r, "vista"); eq(#f.ns.Value.Keys(targets), 1)
        assert(f.r.lab.SelectProfile("vista")); f.mock.Flush(); eq(f.values.ResampleSharpness, "0.9")
    end)
    test("Q03 all tier trials capture, verify and exactly restore through one boundary", function()
        local f = setup(); eq(#f.calls, 0)
        for _, key in ipairs(f.ns.QualityTrial.Order) do
            assert(f.t.Test(key, 2)); eq(f.values[key], "2"); eq(f.t.Status().original, "1")
            f.mock.Flush(); eq(f.values[key], "1"); eq(f.t.state, "RESTORED")
            eq(next(f.r.db.experiments.journal.entries), nil); eq(next(f.r.db.experiments.sideEffects), nil)
        end
        eq(#f.calls, 8)
    end)
    test("Q04 invalid, missing and unsupported native tier choices never write", function()
        local f = setup()
        for _, value in ipairs({ -1, 6, 1.5, 0/0, math.huge }) do eq(f.t.Test("graphicsShadowQuality", value), nil) end
        eq(f.t.Test("Unknown", 2), nil); eq(f.t.Test("graphicsShadowQuality", 1), nil)
        f.env.IsGraphicsSettingValueSupported = nil; eq(f.t.Test("graphicsShadowQuality", 2), nil)
        f.env.IsGraphicsSettingValueSupported = function() return 1 end; eq(f.t.Test("graphicsShadowQuality", 2), nil)
        f.env.IsGraphicsSettingValueSupported = function() return 0 end
        f.env.C_VideoOptions.IsSecondaryLightingSupported = function() return false end
        eq(f.t.Test("graphicsLightMode", 2), nil); eq(#f.calls, 0)
    end)
    test("Q05 tier-induced watched changes must also return to originals", function()
        local f = setup()
        f.setter = function(key, target) f.values[key] = target; f.values.farclip = target == "2" and "150" or "100"; return true end
        assert(f.t.Test("graphicsShadowQuality", 2)); eq(f.r.db.experiments.sideEffects.farclip.before, "100")
        f.mock.Flush(); eq(f.t.state, "RESTORED"); eq(f.values.farclip, "100")
    end)
    test("Q06 incomplete dependent restoration retains the snapshot without child repair writes", function()
        local f = setup()
        f.setter = function(key, target) f.values[key] = target; f.values.farclip = "150"; return true end
        assert(f.t.Test("graphicsShadowQuality", 2)); f.mock.Flush()
        eq(f.t.state, "RECOVERY"); eq(f.values.graphicsShadowQuality, "1"); eq(#f.calls, 2)
        eq(f.r.db.experiments.sideEffects.farclip.before, "100"); eq(f.t.Status().original, "1")
        assert(f.t.Restore()); f.mock.Flush(); eq(f.t.state, "RECOVERY"); eq(#f.calls, 2)
        f.values.farclip = "100"; assert(f.t.Restore()); f.mock.Flush(); eq(f.t.state, "RESTORED"); eq(#f.calls, 2)
    end)
    test("Q07 external edits stop automatic tier restoration; explicit recovery is separate", function()
        local f = setup(); assert(f.t.Test("graphicsShadowQuality", 2))
        f.values.farclip = "999"; f.mock.Flush()
        eq(#f.calls, 1); eq(f.t.state, "RECOVERY"); eq(f.values.farclip, "999")
        eq(f.r.lab.SelectProfile("balanced"), nil); eq(f.r.engine.Prepare("on"), nil)
        f.values.farclip = "100"; assert(f.t.Restore()); f.mock.Flush(); eq(f.t.state, "RESTORED")
    end)
    test("Q08 reload and later build never auto-restore tiers; original provenance is retained", function()
        local f = setup(); assert(f.t.Test("graphicsShadowQuality", 2))
        local nextLogin = setup(f.r.db, { graphicsShadowQuality = "2" })
        eq(#nextLogin.calls, 0); eq(nextLogin.t.state, "RECOVERY")
        assert(nextLogin.t.Restore()); nextLogin.mock.Flush(); eq(nextLogin.values.graphicsShadowQuality, "1")
        eq(nextLogin.t.state, "RESTORED")
    end)
    test("Q09 setter rejection, clamping and restore rejection keep recovery originals", function()
        for _, behavior in ipairs({ "reject", "clamp", "restore" }) do
            local f = setup()
            f.setter = function(key, target, count)
                if behavior == "reject" or behavior == "restore" and count == 2 then return false end
                f.values[key] = behavior == "clamp" and "3" or target; return true
            end
            f.t.Test("graphicsShadowQuality", 2); f.mock.Flush()
            eq(f.t.state, "RECOVERY"); eq(f.t.Status().original, "1")
            eq(#f.calls, behavior == "restore" and 2 or 1)
        end
    end)
    test("Q10 combat, missing timer and unavailable original refuse or retain without retry", function()
        local f = setup(); f.env.InCombatLockdown = function() return true end
        eq(f.t.Test("graphicsShadowQuality", 2), nil); eq(#f.calls, 0)
        f.env.InCombatLockdown = function() return false end
        f.env.C_Timer.After = nil; eq(f.t.Test("graphicsShadowQuality", 2), nil); eq(#f.calls, 0)
        local g = setup(); assert(g.t.Test("graphicsShadowQuality", 2))
        g.env.InCombatLockdown = function() return true end; g.mock.Flush()
        eq(g.t.state, "RECOVERY"); eq(#g.calls, 1)
    end)
    test("Q11 trial buttons use capability-checked choices and bounded pooled UI", function()
        local f = setup(); f.r.ui.Open(8); f.mock.Click("Shadows, lighting & water")
        f.mock.Click("Medium (2)"); f.mock.Click("Try selected level & restore"); f.mock.Flush()
        eq(f.t.state, "RESTORED"); eq(#f.calls, 2)
        local count = #f.mock.nodes
        for _ = 1, 20 do f.r.ui.BuildPage() end
        eq(#f.mock.nodes, count)
    end)
    test("Q12 native callbacks cannot reenter or bypass tier ownership", function()
        local f = setup()
        f.setter = function(key, target)
            eq(f.t.Test(key, 3), nil); eq(f.t.Restore(), nil); eq(f.r.engine.Prepare("on"), nil)
            eq(f.r.lab.Apply("quality", { ResampleSharpness = 1.1 }), nil)
            f.frame.OnEvent(f.frame, "CVAR_UPDATE", key, target)
            f.values[key] = target; return true
        end
        assert(f.t.Test("graphicsShadowQuality", 2)); f.mock.Flush(); eq(#f.calls, 2); eq(f.t.state, "RESTORED")
    end)
    test("Q13 missing tier watch provenance refuses recovery without discarding the original", function()
        local f = setup(); assert(f.t.Test("graphicsShadowQuality", 2))
        local g = setup(f.r.db, { graphicsShadowQuality = "2" })
        g.r.db.experiments.sideEffects.graphicsShadowQuality = nil
        eq(g.t.Restore(), nil); eq(#g.calls, 0); eq(g.t.Status().original, "1")
    end)
    test("Q14 pre-write watch drift refuses without orphaning an unowned snapshot", function()
        local f = setup(); local calls = 0
        f.env.IsGraphicsSettingValueSupported = function()
            calls = calls + 1; if calls == 3 then f.values.farclip = "999" end; return 0
        end
        eq(f.t.Test("graphicsShadowQuality", 2), nil); eq(#f.calls, 0)
        eq(next(f.r.db.experiments.journal.entries), nil); eq(next(f.r.db.experiments.sideEffects), nil)
        eq(f.values.farclip, "999")
    end)
end
