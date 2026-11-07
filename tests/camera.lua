return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local player, pet = "UnitNameFriendlyPlayerName", "UnitNameFriendlyPetName"
    local function setup(saved, values)
        local f = fixture(saved); f.mock = widgets(f.env); f.calls, f.visibility = {}, {}
        f.values[player], f.values[pet] = "1", "1"
        for key, value in pairs(values or {}) do f.values[key] = value end
        f.env.SetUIVisibility = function(shown)
            f.visibility[#f.visibility + 1] = shown
            if f.uiSetter then return f.uiSetter(shown) end
            if shown then f.env.UIParent:Show() else f.env.UIParent:Hide() end
        end
        f.env.C_CVar.SetCVar = function(key, target)
            local db = f.env.LumenShiftDB
            local original = db.camera.journal.entries[key] or db.journal.entries[key] or db.experiments.journal.entries[key]
            assert(original and original.originalRaw, "name originals captured before write")
            f.calls[#f.calls + 1] = { key, target }
            if f.setter then return f.setter(key, target, #f.calls) end
            f.values[key] = target; return true
        end
        f.load(); f.r, f.c = f.ns.runtime, f.ns.runtime.camera
        return f
    end
    test("C01 camera startup and diagnostics never hide UI or change name CVars", function()
        local f = setup(); f.r.ui.Open(9); f.ns.Report.Export(f.r)
        eq(#f.calls, 0); eq(#f.visibility, 0); eq(f.env.UIParent:IsShown(), true)
        eq(f.r.db.schemaVersion, 7); eq(f.c.active, false)
    end)
    test("C02 names toggle restores independent mixed originals instead of forcing both on", function()
        local f = setup(nil, { [player] = "1", [pet] = "0" })
        assert(f.c.ToggleNames()); f.mock.Flush(); eq(f.values[player], "0"); eq(f.values[pet], "0")
        assert(f.c.ToggleNames()); f.mock.Flush(); eq(f.values[player], "1"); eq(f.values[pet], "0")
        eq(#f.calls, 2); eq(#f.visibility, 0); eq(next(f.r.db.camera.journal.entries), nil)
    end)
    test("C03 initially hidden names can be shown and then restored to hidden", function()
        local f = setup(nil, { [player] = "0", [pet] = "0" })
        assert(f.c.ToggleNames()); f.mock.Flush(); eq(f.values[player], "1"); eq(f.values[pet], "1")
        assert(f.c.ToggleNames()); f.mock.Flush(); eq(f.values[player], "0"); eq(f.values[pet], "0")
    end)
    test("C04 Camera Mode hides HUD only after name verification and its keybinding restores both", function()
        local f = setup(); assert(f.r.product.Select("nightVision")); f.mock.Flush()
        f.env.LumenShift_ToggleCamera(); eq(#f.visibility, 0); f.mock.Flush()
        eq(f.c.active, true); eq(f.env.UIParent:IsShown(), false); eq(f.values.Brightness, "75")
        f.env.LumenShift_ToggleCamera(); eq(f.env.UIParent:IsShown(), true); f.mock.Flush()
        eq(f.values[player], "1"); eq(f.values[pet], "1"); eq(f.c.active, false); eq(f.values.Brightness, "75")
        for _, call in ipairs(f.calls) do assert(call[1] == player or call[1] == pet or call[1] == "Brightness") end
    end)
    test("C05 opting out of name hiding performs only the native UI visibility call", function()
        local f = setup(); f.r.db.camera.hideWithUI = false
        assert(f.c.Toggle()); eq(f.env.UIParent:IsShown(), false); eq(#f.calls, 0)
        assert(f.c.Toggle()); eq(f.env.UIParent:IsShown(), true); eq(#f.calls, 0)
    end)
    test("C06 a failed second name setter compensates and never hides the interface", function()
        local f = setup()
        f.setter = function(key, target, count) if count == 2 then return false end; f.values[key] = target; return true end
        assert(f.c.Toggle()); f.mock.Flush()
        eq(f.env.UIParent:IsShown(), true); eq(#f.visibility, 0)
        eq(f.values[player], "1"); eq(f.values[pet], "1"); eq(#f.calls, 3)
        eq(f.c.active, false)
    end)
    test("C07 external name edits are preserved until explicit Restore original names", function()
        local f = setup(); assert(f.c.Toggle()); f.mock.Flush()
        f.values[player] = "1"; f.r.names.Observe()
        local count = #f.calls; eq(f.c.Toggle(), nil); f.mock.Flush()
        eq(f.env.UIParent:IsShown(), true); eq(#f.calls, count); eq(f.values[player], "1")
        assert(f.c.RestoreNames()); f.mock.Flush(); eq(f.values[pet], "1"); eq(next(f.r.db.camera.journal.entries), nil)
    end)
    test("C08 interrupted names survive reload with no startup hide or automatic restore", function()
        local f = setup(); assert(f.c.Toggle()); f.mock.Flush()
        local g = setup(f.r.db, { [player] = "0", [pet] = "0" })
        eq(#g.calls, 0); eq(#g.visibility, 0); eq(g.r.names.state, "RECOVERY")
        assert(g.c.RestoreNames()); g.mock.Flush(); eq(g.values[player], "1"); eq(g.values[pet], "1")
    end)
    test("C09 unavailable, invalid and protected names never hide the UI", function()
        for _, value in ipairs({ "2", "SECRET", "not-a-number" }) do
            local f = setup(nil, { [player] = value }); eq(f.c.Toggle(), nil)
            eq(#f.calls, 0); eq(#f.visibility, 0)
        end
        local f = setup(); f.values[pet] = nil; eq(f.c.Toggle(), nil); eq(#f.calls, 0)
        local g = setup(); g.env.C_CVar.GetCVarInfo = function(key) return g.values[key], "50", false, false, false, true, false end
        eq(g.c.Toggle(), nil); eq(#g.calls, 0); eq(#g.visibility, 0)
    end)
    test("C10 absent or failed native visibility keeps name recovery accessible", function()
        local f = setup(); f.env.SetUIVisibility = nil
        eq(f.c.Toggle(), nil); eq(#f.calls, 0)
        local g = setup(); g.uiSetter = function() error("PRIVATE_UI_ERROR") end
        assert(g.c.Toggle()); g.mock.Flush(); eq(g.c.active, false); eq(g.env.UIParent:IsShown(), true)
        eq(g.r.db.camera.journal.entries[player].originalRaw, "1")
        eq(g.ns.Report.Export(g.r):find("PRIVATE_UI_ERROR", 1, true), nil)
    end)
    test("C11 combat during verification leaves HUD visible and names available for recovery", function()
        local f = setup(); f.env.InCombatLockdown = function() return true end
        eq(f.c.Toggle(), nil); eq(#f.calls, 0)
        f.env.InCombatLockdown = function() return false end
        assert(f.c.Toggle()); f.env.InCombatLockdown = function() return true end; f.mock.Flush()
        eq(#f.visibility, 0); eq(f.r.names.state, "RECOVERY")
    end)
    test("C12 native Alt-Z showing the HUD does not silently restore name preferences", function()
        local f = setup(); assert(f.c.Toggle()); f.mock.Flush(); local count = #f.calls
        f.env.UIParent:Show(); eq(#f.calls, count); eq(f.values[player], "0")
        assert(f.c.Toggle()); f.mock.Flush(); eq(f.values[player], "1"); eq(f.c.active, false)
    end)
    test("C13 schema-4 upgrade preserves preferences, completion and active recovery", function()
        local f = setup(); local old = f.ns.Value.Copy(f.r.db)
        old.schemaVersion, old.camera, old.addonVersion, old.baseline = 4, nil, "0.2.0-dev.6", nil; old.graphics = nil
        old.onboarding.completed = true; old.config.studio.modes.lantern.brightness = 67
        local copy, why = f.ns.Store.Open(old)
        eq(why, "MIGRATED_4_TO_7"); eq(copy.schemaVersion, 7); eq(copy.onboarding.completed, true)
        eq(copy.config.studio.modes.lantern.brightness, 67); eq(old.camera, nil); eq(old.schemaVersion, 4)
        copy.camera.journal.entries.Unknown = {}; eq(f.ns.Store.Open(copy), nil)
    end)
    test("C14 camera buttons and binding are wired without commands or key reassignment", function()
        local f = setup(); f.r.ui.Open(9); f.mock.Click("Toggle friendly player and pet names"); f.mock.Flush()
        eq(f.values[player], "0"); f.mock.Click("Restore original name settings"); f.mock.Flush(); eq(f.values[player], "1")
        f.mock.Click("Enter Camera Mode — hide interface"); f.mock.Flush(); eq(f.c.active, true)
        f.env.LumenShift_ToggleCamera(); f.mock.Flush(); eq(f.c.active, false)
    end)
    test("C15 camera names reject arbitrary keys and serialize native callback reentry", function()
        local f = setup(); eq(f.r.names.Apply("camera", { Brightness = 75 }), nil); eq(#f.calls, 0)
        f.setter = function(key, target)
            eq(f.r.engine.Prepare("on"), nil); eq(f.r.lab.Apply("quality", {}), nil)
            eq(f.c.Toggle(), nil); eq(f.r.tierTrial.Test("graphicsShadowQuality", 2), nil)
            f.frame.OnEvent(f.frame, "CVAR_UPDATE", key, target)
            f.values[key] = target; return true
        end
        assert(f.c.ToggleNames()); f.mock.Flush(); eq(#f.calls, 2)
        assert(f.c.ToggleNames()); f.mock.Flush(); eq(#f.calls, 4); eq(f.values[player], "1")
    end)
end
