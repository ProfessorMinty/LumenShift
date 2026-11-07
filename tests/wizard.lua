return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function make(saved, configure)
        local f = fixture(saved); f.mock = widgets(f.env); f.writes, f.reloads = {}, 0
        f.env.ReloadUI = function()
            f.reloads = f.reloads + 1
            f.atReload = f.ns.Value.Copy(f.env.LumenShiftDB)
        end
        f.env.C_CVar.SetCVar = function(key, value)
            assert(key == "Brightness"); assert(f.env.LumenShiftDB.journal.entries[key].originalRaw)
            f.writes[#f.writes + 1] = { key, value }; f.values[key] = value; return true
        end
        if configure then configure(f) end
        f.load(); f.runtime = f.ns.runtime; f.setup = f.runtime.setup
        function f.enter() f.frame.OnEvent(f.frame, "PLAYER_ENTERING_WORLD") end
        function f.next() f.setup.next.scripts.OnClick(f.setup.next) end
        function f.review()
            f.next(); f.next()
            f.mock.Click("I know how to restore my settings")
        end
        return f
    end
    test("W01 first world entry opens the wizard once without graphics, sounds or reload", function()
        local f = make(); eq(f.setup.window, nil); f.enter(); assert(f.setup.window:IsShown())
        eq(f.setup.page, 1); eq(#f.writes, 0); eq(#f.mock.soundCalls, 0); eq(f.reloads, 0)
        f.mock.Click("Set up later"); eq(f.setup.window:IsShown(), false); f.enter(); eq(f.setup.window:IsShown(), false)
        eq(f.env.LumenShiftDB.onboarding.completed, false); f.zero()
    end)
    test("W02 Finish saves selected preferences before one explicit reload and never reapplies after login", function()
        local f = make(); f.enter(); f.next()
        f.mock.Click("Activation sounds"); f.mock.Click("Reduced motion")
        f.mock.Click("Screen effects")
        eq(f.env.LumenShiftDB.config.preferences.sound, false)
        f.next(); f.mock.Click("Finish & Reload UI"); eq(f.reloads, 0)
        f.mock.Click("I know how to restore my settings")
        f.mock.Click("Finish & Reload UI"); eq(f.reloads, 1); eq(#f.writes, 0); eq(#f.mock.soundCalls, 0)
        eq(f.atReload.onboarding.completed, true); eq(f.atReload.config.preferences.sound, true)
        eq(f.atReload.config.preferences.reducedMotion, true); eq(f.atReload.config.studio.effects, false)
        eq(f.atReload.config.studio.enabled, true); eq(f.setup.Finish(), nil); eq(f.reloads, 1)
        local nextLogin = make(f.atReload); nextLogin.enter(); eq(nextLogin.setup.window, nil)
        eq(nextLogin.runtime.product.active, "natural"); eq(#nextLogin.writes, 0); eq(nextLogin.reloads, 0)
    end)
    test("W03 closing setup discards drafts and resumes on the next login", function()
        local f = make(); f.enter(); f.next(); f.mock.Click("Activation sounds")
        f.setup.window:Hide(); eq(f.env.LumenShiftDB.config.preferences.sound, false)
        f.runtime.entry.Open("LeftButton"); eq(f.setup.page, 1); eq(f.setup.draft.sound, false)
        local again = make(f.env.LumenShiftDB); again.enter(); assert(again.setup.window:IsShown()); eq(again.reloads, 0)
    end)
    test("W04 combat defers initial setup and cannot trigger Finish or queued reload", function()
        local f = make(); local combat = true; f.env.InCombatLockdown = function() return combat end
        f.enter(); eq(f.setup.window, nil); combat = false; f.frame.OnEvent(f.frame, "PLAYER_REGEN_ENABLED")
        assert(f.setup.window:IsShown()); f.review(); combat = true
        eq(f.setup.Finish(), nil); eq(f.reloads, 0); eq(f.env.LumenShiftDB.onboarding.completed, false)
        combat = false; f.frame.OnEvent(f.frame, "PLAYER_REGEN_ENABLED"); eq(f.reloads, 0); eq(#f.writes, 0)
    end)
    test("W05 missing or failed reload is reported without a graphics change or automatic retry", function()
        local f = make(); f.enter(); f.review(); local reload = f.env.ReloadUI; f.env.ReloadUI = nil
        eq(f.setup.Finish(), nil); eq(f.env.LumenShiftDB.onboarding.completed, false)
        eq(f.env.LumenShiftDB.config.studio.enabled, false)
        f.env.ReloadUI = function() error("PRIVATE_RELOAD_DETAIL") end
        eq(f.setup.Finish(), nil); eq(f.env.LumenShiftDB.onboarding.completed, true)
        eq(f.ns.Report.Export(f.runtime):find("PRIVATE_RELOAD_DETAIL", 1, true), nil)
        assert(f.setup.window:IsShown()); eq(f.reloads, 0); eq(#f.writes, 0)
        f.env.ReloadUI = reload; assert(f.setup.Finish()); eq(f.reloads, 1)
    end)
    test("W06 recovery precedes wizard and full recovery uses only buttons", function()
        local original = make(); local db = original.env.LumenShiftDB
        db.journal = { nextEpoch = 2, entries = { Brightness = { originalRaw = "52", lastVerifiedRaw = "75",
            intendedRaw = "75", layer = "visual", epoch = 1, state = "owned", descriptorVersion = 1, signature = "1.60.1:70790:16001" } } }
        local f = make(db); f.enter(); eq(f.setup.window, nil); eq(f.runtime.ui.page, 7)
        f.mock.Click("Restore My Brightness — preview only"); local token = assert(f.runtime.engine.Status().token)
        f.mock.Click("Confirm displayed recovery card " .. token); f.mock.Click("Verify pending recovery (read only)")
        eq(f.runtime.engine.Status().state, "BASELINE"); eq(#f.writes, 0); eq(f.reloads, 0)
        assert(f.setup.Open()); f.review(); f.mock.Click("Finish & Reload UI"); eq(f.reloads, 1)
    end)
    test("W07 complete setup, mode on/off, diagnostics and report need no slash commands", function()
        local f = make(); f.enter(); f.review(); f.mock.Click("Finish & Reload UI")
        f = make(f.atReload); f.enter()
        f.runtime.entry.button.scripts.OnClick(f.runtime.entry.button, "LeftButton")
        assert(f.runtime.ui.radial.frame:IsShown()); f.mock.Click("2 Night Vision"); f.mock.Flush()
        eq(f.values.Brightness, "75")
        f.runtime.entry.Open("LeftButton"); f.mock.Click("1 Natural"); f.mock.Flush(); eq(f.values.Brightness, "52")
        f.runtime.entry.Open("RightButton"); f.mock.Click("Diagnostic Center")
        f.mock.Click("Run Diagnostics (read only, no audio or graphics changes)")
        f.mock.Click("Export Complete Diagnostic Report"); f.mock.Click("Select All")
        eq(f.runtime.exportUI.box.focus, true); assert(f.runtime.exportUI.text:find("END LUMENSHIFT REPORT", 1, true))
        eq(#f.writes, 2); eq(f.reloads, 0)
    end)
    test("W08 minimap and visible fallback remain accessible with hidden launcher or missing Settings", function()
        local first = make(); local db = first.env.LumenShiftDB
        db.onboarding.completed = true; db.config.studio.launcher.visible = false
        for _, withMap in ipairs({ true, false }) do
            local f = make(db, function(f)
                f.env.Settings = nil
                if withMap then f.env.Minimap = f.env.CreateFrame("Frame", "Minimap", f.env.UIParent) end
            end)
            eq(f.runtime.ui.radial.launcher:IsShown(), false); assert(f.runtime.entry.button:IsShown())
            f.runtime.entry.Open("RightButton"); assert(f.runtime.ui.window:IsShown()); eq(#f.writes, 0)
        end
    end)
    test("W09 Studio initialization failure retains a clickable diagnostic export", function()
        local f = make(nil, function(f) f.ns.Studio.New = function() error("PRIVATE_STUDIO_ERROR") end end)
        eq(f.runtime.ui, nil); assert(f.runtime.entry.button:IsShown())
        f.runtime.entry.Open("RightButton"); assert(f.runtime.exportUI.window:IsShown())
        assert(f.runtime.exportUI.text:find("UI_INITIALIZATION_FAILED", 1, true))
        eq(f.runtime.exportUI.text:find("PRIVATE_STUDIO_ERROR", 1, true), nil); eq(#f.writes, 0)
    end)
    test("W10 schema-3 upgrade preserves configuration and originals; invalid completion is quarantined", function()
        local f = make(); local old = f.ns.Value.Copy(f.env.LumenShiftDB)
        old.schemaVersion = 3; old.onboarding = nil; old.config.studio.modes.lantern.brightness = 67
        local migrated, code = f.ns.Store.Open(old); eq(code, "MIGRATED_3_TO_4")
        eq(migrated.onboarding.completed, false); eq(migrated.config.studio.modes.lantern.brightness, 67)
        eq(old.schemaVersion, 3); eq(old.onboarding, nil)
        migrated.onboarding.completed = "yes"; eq(f.ns.Store.Open(migrated), nil)
    end)
    test("W11 invalid build can complete read-only preferences without enabling future writes", function()
        local f = make(nil, function(f) f.env.GetBuildInfo = function() return "1.60.2", "99999", "unknown", 16002 end end)
        f.enter(); eq(f.setup.draft.enabled, false); f.review()
        f.setup.draft.enabled = true; eq(f.setup.Finish(), nil); eq(f.reloads, 0)
        assert(f.setup.message:find("has not been reviewed", 1, true))
        eq(f.env.LumenShiftDB.config.studio.enabled, false)
        f.mock.Click("Enable visual switching"); assert(f.setup.Finish())
        eq(f.atReload.config.studio.enabled, false); eq(#f.writes, 0)
    end)
    test("W12 Settings buttons reopen setup and preserve a previously disabled control preference", function()
        local first = make(); first.env.LumenShiftDB.onboarding.completed = true
        first.env.LumenShiftDB.config.studio.enabled = false
        local f = make(first.env.LumenShiftDB); f.enter(); assert(f.mock.category)
        f.mock.Click("Setup wizard"); assert(f.setup.window:IsShown()); eq(f.setup.draft.enabled, false)
        f.mock.Click("Open Visual Studio"); eq(f.setup.window:IsShown(), false); assert(f.runtime.ui.window:IsShown())
        f.mock.Click("Run Diagnostics"); eq(f.runtime.ui.page, 7)
        f.mock.Click("Export Complete Diagnostic Report"); assert(f.runtime.exportUI.window:IsShown())
        eq(f.reloads, 0); eq(#f.writes, 0)
    end)
    test("W13 displayed/exported Brightness card uses the actual pending target and cannot mutate it", function()
        local f = make(); assert(f.runtime.engine.Prepare("on"))
        local status = f.runtime.engine.Status(); eq(status.preview.original, "52"); eq(status.preview.target, "75")
        status.preview.target = "52"
        assert(f.ns.Report.Export(f.runtime):find("PREVIEW Brightness original=52 snapshot=52 target=75", 1, true))
        f.runtime.entry.Studio(7); f.mock.Click("Confirm displayed recovery card " .. status.token)
        eq(f.values.Brightness, "75"); eq(#f.writes, 1)
    end)
end
