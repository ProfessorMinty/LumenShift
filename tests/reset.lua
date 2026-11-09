-- Simulated account SavedVariables replacement and native reload, not disk/game evidence.
return function(make, fixture, eq, test)
    local label = "Reset LumenShift & Restart Setup"
    local function same(a, b)
        eq(type(a), type(b))
        if type(a) ~= "table" then return eq(a, b) end
        for k, v in pairs(a) do same(v, b[k]) end
        for k in pairs(b) do assert(a[k] ~= nil, "unexpected field " .. tostring(k)) end
    end
    local function configured()
        local f = make(nil, { Brightness = "45", Contrast = "60", farclip = "5000" })
        assert(f.r.setup.Open()); assert(f.r.setup.SaveAndClose())
        f.r.db.config.preferences.sound = false
        f.r.db.config.studio.launcher.x = 333
        f.r.db.config.studio.modes.nightVision.brightness = 70
        f.env.OtherAddonDB = { profiles = { main = { scale = 0.8 } } }
        return f
    end
    test("RST01 visible Studio reset opens a confirmation; cancel and Escape preserve all data", function()
        local f = configured(); local old = f.env.LumenShiftDB; local copy = f.ns.Value.Copy(old)
        f.r.entry.Studio(6); f.mock.Click(label)
        eq(f.r.reset.window:IsShown(), true); eq(#f.calls, 0); eq(f.reloads, 0)
        f.mock.Click("Cancel"); eq(f.r.reset.window:IsShown(), false); eq(f.r.reset.Confirm(), nil)
        eq(f.env.LumenShiftDB, old); same(old, copy)
        f.mock.Click(label); f.r.reset.window:Hide() -- native Escape closes its UISpecialFrame
        eq(f.r.reset.Confirm(), nil); eq(#f.calls, 0); eq(f.reloads, 0); same(old, copy)
    end)
    test("RST02 confirmed reset replaces only our save target and requests one reload", function()
        local f = configured(); local old = f.env.LumenShiftDB; local other = f.env.OtherAddonDB
        local values = f.ns.Value.Copy(f.values); local expected = f.ns.Store.Open(nil)
        f.r.entry.Studio(6); f.mock.Click(label); assert(f.mock.Click("Reset & Restart Setup"))
        eq(f.reloads, 1); eq(#f.calls, 0); same(f.values, values)
        same(f.env.LumenShiftDB, expected); assert(f.env.LumenShiftDB ~= old)
        eq(f.env.OtherAddonDB, other); same(other, { profiles = { main = { scale = 0.8 } } })
        eq(f.r.db, old) -- closed-over controllers are not rebound mid-session
        eq(old.onboarding.completed, true); eq(old.config.studio.launcher.x, 333)
        eq(f.r.reset.Confirm(), nil); eq(f.r.reset.Open(), nil); eq(f.reloads, 1)
    end)
    test("RST03 next load opens fresh setup and captures current values without graphics writes", function()
        local f = configured(); assert(f.r.reset.Open()); assert(f.r.reset.Confirm())
        local g = make(f.env.LumenShiftDB, f.values)
        g.frame.OnEvent(g.frame, "PLAYER_ENTERING_WORLD"); g.flush()
        eq(g.r.setup.window:IsShown(), true); eq(g.r.db.onboarding.completed, false)
        eq(g.r.setup.draft.graphics.normal.source, "keep"); eq(g.r.setup.draft.graphics.raid.source, "keep")
        assert(g.r.setup.SaveAndClose()); eq(g.r.db.baseline.values.Brightness, "45")
        eq(g.r.db.baseline.values.Contrast, "60"); eq(#g.calls, 0)
        local h = make(g.env.LumenShiftDB, g.values)
        h.frame.OnEvent(h.frame, "PLAYER_ENTERING_WORLD"); h.flush()
        assert(not h.r.setup.window or not h.r.setup.window:IsShown()); eq(#h.calls, 0)
    end)
    test("RST04 active and uncertain historical recovery records can be intentionally cleared without restoring", function()
        local f = configured(); assert(f.r.product.Select("nightVision")); f.flush()
        for _, state in ipairs({ "owned", "pending", "failed", "conflict" }) do
            local saved = f.ns.Value.Copy(f.r.db); saved.journal.entries.Brightness.state = state
            if state == "failed" or state == "conflict" then saved.journal.entries.Brightness.failure = "EXTERNAL_CONFLICT" end
            local g = make(saved, f.values); local values = g.ns.Value.Copy(g.values)
            assert(g.r.reset.Open()); assert(g.r.reset.Confirm())
            eq(next(g.env.LumenShiftDB.journal.entries), nil); eq(next(g.env.LumenShiftDB.experiments.journal.entries), nil)
            eq(next(g.env.LumenShiftDB.graphics.records), nil); eq(next(g.env.LumenShiftDB.camera.photo.records), nil)
            eq(g.reloads, 1); eq(#g.calls, 0); same(g.values, values)
        end
    end)
    test("RST05 combat and an actually running operation defer reset without losing settings", function()
        local f = configured(); local old = f.env.LumenShiftDB
        assert(f.r.reset.Open()); f.env.InCombatLockdown = function() return true end
        eq(f.r.reset.Confirm(), nil); eq(f.env.LumenShiftDB, old); eq(f.reloads, 0)
        f.env.InCombatLockdown = function() return false end
        assert(f.r.product.Select("nightVision"))
        eq(f.r.reset.Confirm(), nil); eq(f.env.LumenShiftDB, old); eq(f.reloads, 0)
        f.flush(); local calls = #f.calls
        assert(f.r.reset.Confirm()); eq(f.reloads, 1); eq(#f.calls, calls)
    end)
    test("RST06 missing throwing and unexpected reload outcomes preserve settings and allow retry", function()
        for _, failure in ipairs({ "absent", "throw", "unexpected" }) do
            local f = configured(); local old = f.env.LumenShiftDB; local copy = f.ns.Value.Copy(old)
            local reload = f.env.ReloadUI
            if failure == "absent" then f.env.ReloadUI = nil
            elseif failure == "throw" then f.env.ReloadUI = function() error("private native failure") end
            else f.env.ReloadUI = function() return false end end
            assert(f.r.reset.Open()); eq(f.r.reset.Confirm(), nil)
            eq(f.env.LumenShiftDB, old); same(old, copy); assert(not f.r.reader.resetPending)
            eq(f.reloads, 0); eq(#f.calls, 0)
            f.env.ReloadUI = reload; assert(f.r.reset.Confirm()); eq(f.reloads, 1)
        end
    end)
    test("RST07 reload reentry and late handlers cannot write or repopulate the cleared database", function()
        local f = configured(); local old = f.env.LumenShiftDB; local calls = 0
        local guarded = f.r.log.Guard("test", "late", function() calls = calls + 1; old.onboarding.completed = false end)
        f.env.ReloadUI = function()
            f.reloads = f.reloads + 1
            eq(guarded(), nil)
            eq(f.env.LumenShift_ToggleNightVision(), nil)
            eq(f.r.product.Select("nightVision"), nil) -- bypass input guard, exercise native boundary fence
        end
        assert(f.r.reset.Open()); assert(f.r.reset.Confirm()); f.flush()
        guarded(); f.frame.OnEvent(f.frame, "CVAR_UPDATE", "Brightness")
        eq(calls, 0); eq(#f.calls, 0); eq(f.reloads, 1)
        same(f.env.LumenShiftDB, f.ns.Store.Open(nil)); eq(old.onboarding.completed, true)
    end)
    test("RST08 native Settings and export offer reset even with quarantined SavedVariables", function()
        local f = fixture({ schemaVersion = 999, unknown = { preserved = true } })
        f.mock = assert(loadfile("tests/ui_mock.lua"))()(f.env)
        f.reloads = 0; f.env.ReloadUI = function() f.reloads = f.reloads + 1 end
        f.load(); local r = f.ns.runtime; eq(r.db, nil)
        f.mock.category.frame:Show(); f.mock.Click(label); eq(r.reset.window:IsShown(), true)
        f.mock.Click("Cancel"); assert(f.ns.DiagnosticWindow.Open(r)); f.mock.Click("Reset LumenShift...")
        eq(r.reset.window:IsShown(), true); assert(f.mock.Click("Reset & Restart Setup"))
        same(f.env.LumenShiftDB, f.ns.Store.Open(nil)); eq(f.reloads, 1); f.zero()
    end)
    test("RST09 reset never needs available graphics setters getters or a matching game build", function()
        local f = configured(); f.env.C_CVar = nil
        f.env.GetBuildInfo = function() return "1.60.2", "99999", "unknown", 16002 end
        assert(f.r.reset.Open()); assert(f.r.reset.Confirm())
        eq(f.reloads, 1); eq(#f.calls, 0); same(f.env.LumenShiftDB, f.ns.Store.Open(nil))
    end)
    test("RST10 full preset library and all owned setting layers reset without native restoration", function()
        local f = configured()
        for i = 1, 24 do assert(f.r.product.SavePreset("Look " .. i, "nightVision")) end
        assert(f.r.product.Select("nightVision")); f.flush()
        f.values.RAIDsettingsEnabled = "1"; f.apply("normal", 7); f.apply("raid", 4)
        assert(f.r.camera.ApplyFOV(80)); f.flush()
        assert(f.r.camera.ToggleNames()); f.flush()
        f.r.db.camera.photoEnabled, f.r.db.camera.photoLevel = true, 8
        assert(f.r.camera.Toggle()); f.flush()
        local saved = assert(f.ns.Store.Open(f.r.db)); local g = make(saved, f.values)
        assert(g.r.db.config.studio.presets.p24)
        assert(next(g.r.db.journal.entries)); assert(next(g.r.db.camera.journal.entries))
        assert(next(g.r.db.camera.framing.journal.entries)); assert(next(g.r.db.camera.photo.records))
        assert(next(g.r.db.graphics.records)); local values = g.ns.Value.Copy(g.values)
        assert(g.r.reset.Open()); assert(g.r.reset.Confirm())
        same(g.env.LumenShiftDB, g.ns.Store.Open(nil)); same(g.values, values); eq(#g.calls, 0)
    end)
end
