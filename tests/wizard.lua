return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function make(saved, configure)
        local f = fixture(saved); f.mock = widgets(f.env); f.writes, f.reloads = {}, 0
        f.env.ReloadUI = function()
            f.reloads = f.reloads + 1; f.atReload = f.ns.Value.Copy(f.env.LumenShiftDB)
        end
        f.env.C_CVar.SetCVar = function(key, value)
            assert(key == "Brightness"); assert(f.env.LumenShiftDB.journal.entries[key].originalRaw)
            f.writes[#f.writes + 1] = { key, value }; f.values[key] = value; return true
        end
        if configure then configure(f) end
        f.load(); f.runtime = f.ns.runtime; f.setup = f.runtime.setup
        function f.enter() f.frame.OnEvent(f.frame, "PLAYER_ENTERING_WORLD") end
        return f
    end
    test("W01 first world entry opens compact setup once without writes, sounds or reload", function()
        local f = make(); eq(f.setup.window, nil); f.enter(); assert(f.setup.window:IsShown())
        eq(#f.writes, 0); eq(#f.mock.soundCalls, 0); eq(f.reloads, 0)
        f.mock.Click("Later"); eq(f.setup.window:IsShown(), false); f.enter(); eq(f.setup.window:IsShown(), false)
        eq(f.env.LumenShiftDB.onboarding.completed, false); f.zero()
    end)
    test("W02 one Finish saves choices and usable controls before explicit reload without reapplying at login", function()
        local f = make(); f.enter(); f.mock.Click("Night Vision sounds"); f.mock.Click("Reduced motion")
        f.mock.Click("Screen effects"); eq(f.env.LumenShiftDB.config.preferences.sound, false)
        f.mock.Click("Next: Graphics"); f.mock.Click("Finish & Reload UI"); eq(f.reloads, 1); eq(#f.writes, 0); eq(#f.mock.soundCalls, 0)
        eq(f.atReload.onboarding.completed, true); eq(f.atReload.config.preferences.sound, true)
        eq(f.atReload.config.preferences.reducedMotion, true); eq(f.atReload.config.studio.effects, false)
        eq(f.atReload.config.studio.enabled, true); eq(f.setup.Finish(), nil); eq(f.reloads, 1)
        local again = make(f.atReload); again.enter(); eq(again.setup.window, nil)
        eq(again.runtime.product.active, "natural"); eq(#again.writes, 0); eq(again.reloads, 0)
    end)
    test("W03 closing without saving discards drafts and resumes on the next login", function()
        local f = make(); f.enter(); f.mock.Click("Night Vision sounds"); f.setup.window:Hide()
        eq(f.env.LumenShiftDB.config.preferences.sound, false)
        f.runtime.entry.Open("LeftButton"); eq(f.setup.draft.sound, false)
        local again = make(f.env.LumenShiftDB); again.enter(); assert(again.setup.window:IsShown()); eq(again.reloads, 0)
    end)
    test("W04 combat defers initial display but does not discard explicit preference saves or queue reload", function()
        local f = make(); local combat = true; f.env.InCombatLockdown = function() return combat end
        f.enter(); eq(f.setup.window, nil); combat = false; f.frame.OnEvent(f.frame, "PLAYER_REGEN_ENABLED")
        assert(f.setup.window:IsShown()); f.mock.Click("Night Vision sounds"); combat = true
        eq(f.setup.Finish(), nil); eq(f.reloads, 0); eq(f.env.LumenShiftDB.onboarding.completed, true)
        eq(f.env.LumenShiftDB.config.preferences.sound, true)
        combat = false; f.frame.OnEvent(f.frame, "PLAYER_REGEN_ENABLED"); eq(f.reloads, 0); eq(#f.writes, 0)
    end)
    test("W05 unavailable or failed reload retains saved choices and never automatically retries", function()
        local f = make(); f.enter(); f.mock.Click("Night Vision sounds")
        local reload = f.env.ReloadUI; f.env.ReloadUI = nil
        eq(f.setup.Finish(), nil); eq(f.env.LumenShiftDB.onboarding.completed, true)
        eq(f.env.LumenShiftDB.config.preferences.sound, true); eq(f.env.LumenShiftDB.config.studio.enabled, true)
        f.env.ReloadUI = function() error("PRIVATE_RELOAD_DETAIL") end
        eq(f.setup.Finish(), nil); eq(f.ns.Report.Export(f.runtime):find("PRIVATE_RELOAD_DETAIL", 1, true), nil)
        assert(f.setup.window:IsShown()); eq(f.reloads, 0); eq(#f.writes, 0)
        f.env.ReloadUI = reload; assert(f.setup.Finish()); eq(f.reloads, 1)
    end)
    test("W06 existing recovery permits preference saves but cannot be discarded by reload", function()
        local original = make(); local db = original.env.LumenShiftDB
        db.journal = { nextEpoch = 2, entries = { Brightness = { originalRaw = "52", lastVerifiedRaw = "75",
            intendedRaw = "75", layer = "visual", epoch = 1, state = "owned", descriptorVersion = 1, signature = "1.60.1:70790:16001" } } }
        local f = make(db); f.enter(); assert(f.setup.window:IsShown()); f.mock.Click("Night Vision sounds")
        assert(f.setup.Finish()); eq(f.reloads, 1); eq(f.runtime.db.config.preferences.sound, true)
        eq(f.atReload.journal.entries.Brightness.originalRaw, "52"); eq(#f.writes, 0)
        f = make(f.atReload)
        eq(f.runtime.engine.Status().state, "RECOVERY"); eq(#f.writes, 0)
        f.runtime.entry.Studio(7); f.mock.Click("Restore captured visuals"); f.mock.Flush()
        eq(f.runtime.engine.Status().state, "BASELINE"); eq(#f.writes, 0)
        assert(f.setup.Open()); f.mock.Click("Next: Graphics"); f.mock.Click("Finish & Reload UI"); eq(f.reloads, 1)
    end)
    test("W17 explicit Finish retains interrupted records and never restores or finishes pending graphics", function()
        local f = make(); f.enter(); assert(f.runtime.product.Select("nightVision"))
        eq(f.runtime.product.busy, true); eq(f.runtime.db.journal.entries.Brightness.state, "pending")
        assert(f.setup.Finish()); eq(f.reloads, 1); eq(#f.writes, 1)
        eq(f.atReload.journal.entries.Brightness.originalRaw, "52")
        eq(f.atReload.journal.entries.Brightness.state, "pending")
        local nextLogin = make(f.atReload, function(g) g.values.Brightness = "75" end)
        nextLogin.enter(); eq(#nextLogin.writes, 0); eq(nextLogin.runtime.engine.Status().state, "RECOVERY")
        eq(nextLogin.runtime.product.Select("nightVision"), nil); eq(#nextLogin.writes, 0)
    end)
    test("W07 complete setup, mode on/off, diagnostics and export use only normal buttons", function()
        local f = make(); f.enter(); f.mock.Click("Next: Graphics"); f.mock.Click("Finish & Reload UI")
        f = make(f.atReload); f.enter()
        f.runtime.entry.button.scripts.OnClick(f.runtime.entry.button, "LeftButton")
        assert(f.runtime.ui.radial.frame:IsShown()); f.mock.Click("Night Vision"); f.mock.Flush(); eq(f.values.Brightness, "75")
        f.runtime.entry.Open("LeftButton"); f.mock.Click("Original"); f.mock.Flush(); eq(f.values.Brightness, "52")
        f.runtime.entry.Open("RightButton"); f.mock.Click("Diagnostic Center")
        f.mock.Click("Run Diagnostics")
        f.mock.Click("Export Complete Diagnostic Report"); f.mock.Click("Select All")
        eq(f.runtime.exportUI.box.focus, true); assert(f.runtime.exportUI.text:find("END LUMENSHIFT REPORT", 1, true))
        eq(#f.writes, 2); eq(f.reloads, 0)
    end)
    test("W08 minimap and fallback remain accessible when the launcher or Settings are absent", function()
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
        eq(f.runtime.ui, nil); assert(f.runtime.entry.button:IsShown()); f.runtime.entry.Open("RightButton")
        assert(f.runtime.exportUI.window:IsShown()); assert(f.runtime.exportUI.text:find("UI_INITIALIZATION_FAILED", 1, true))
        eq(f.runtime.exportUI.text:find("PRIVATE_STUDIO_ERROR", 1, true), nil); eq(#f.writes, 0)
    end)
    test("W10 schema-3 upgrade preserves preferences and originals; corrupt completion is quarantined", function()
        local f = make(); local old = f.ns.Value.Copy(f.env.LumenShiftDB)
        old.schemaVersion = 3; old.baseline = nil; old.camera = nil; old.onboarding = nil; old.config.studio.modes.lantern.brightness = 67; old.graphics = nil; old.optics = nil
        local migrated, code = f.ns.Store.Open(old); eq(code, "MIGRATED_3_TO_18")
        eq(migrated.onboarding.completed, false); eq(migrated.config.studio.modes.lantern.brightness, 67)
        eq(old.schemaVersion, 3); eq(old.onboarding, nil)
        migrated.onboarding.completed = "yes"; eq(f.ns.Store.Open(migrated), nil)
    end)
    test("W11 unreviewed clients can save preferences and select modes without acknowledgement", function()
        local f = make(nil, function(f) f.env.GetBuildInfo = function() return "1.60.2", "99999", "unknown", 16002 end end)
        f.enter(); f.mock.Click("Night Vision sounds"); assert(f.setup.Finish()); eq(f.reloads, 1)
        eq(f.atReload.config.preferences.sound, true); eq(f.atReload.config.studio.enabled, true)
        assert(f.runtime.product.Select("nightVision")); f.mock.Flush(); eq(f.values.Brightness, "75"); eq(#f.writes, 1)
    end)
    test("W12 reopening setup displays saved preferences without changing them until Save", function()
        local first = make(); first.env.LumenShiftDB.onboarding.completed = true
        first.env.LumenShiftDB.config.studio.enabled = false; first.env.LumenShiftDB.config.preferences.sound = true
        local f = make(first.env.LumenShiftDB); f.enter(); assert(f.mock.category)
        f.mock.Click("Setup wizard"); assert(f.setup.window:IsShown()); eq(f.setup.draft.sound, true)
        eq(f.runtime.db.config.studio.enabled, false); f.mock.Click("Save & Close")
        eq(f.runtime.db.config.studio.enabled, true); eq(f.reloads, 0)
        f.mock.Click("Open Visual Studio"); assert(f.runtime.ui.window:IsShown())
        f.mock.Click("Run Diagnostics"); eq(f.runtime.ui.page, 7)
        f.mock.Click("Export Complete Diagnostic Report"); assert(f.runtime.exportUI.window:IsShown()); eq(#f.writes, 0)
    end)
    test("W13 exported recovery preview is immutable and uses the actual pending values", function()
        local f = make(); assert(f.runtime.engine.Prepare("on"))
        local status = f.runtime.engine.Status(); eq(status.preview.original, "52"); eq(status.preview.target, "75")
        status.preview.target = "52"
        assert(f.ns.Report.Export(f.runtime):find("PREVIEW Brightness original=52 snapshot=52 target=75", 1, true))
        f.runtime.entry.Studio(7); f.mock.Click("Confirm displayed recovery card " .. status.token)
        eq(f.values.Brightness, "75"); eq(#f.writes, 1)
    end)
    test("W14 temporary unavailable reads cannot silently save visual controls as disabled", function()
        local f = make(nil, function(f) f.env.C_CVar.AreCVarsLoaded = function() return false end end)
        f.enter(); f.mock.Click("Night Vision sounds"); assert(f.setup.Finish())
        eq(f.atReload.config.studio.enabled, true); eq(f.atReload.config.preferences.sound, true); eq(#f.writes, 0)
        local again = make(f.atReload); again.enter()
        assert(again.runtime.product.Select("lantern")); again.mock.Flush(); eq(again.values.Brightness, "65")
        assert(again.runtime.product.Select("natural")); again.mock.Flush(); eq(again.values.Brightness, "52")
    end)
    test("W15 serialized SavedVariables round trip preserves choices and completion in a fresh fixture", function()
        local f = make(); f.enter(); f.mock.Click("Night Vision sounds"); f.mock.Click("High contrast")
        f.mock.Click("Floating launcher"); f.mock.Click("Menu animations"); assert(f.setup.Finish())
        local function serialize(value)
            if type(value) == "string" then return string.format("%q", value) end
            if type(value) ~= "table" then return tostring(value) end
            local fields = {}; for key, item in pairs(value) do fields[#fields + 1] = "[" .. serialize(key) .. "]=" .. serialize(item) end
            return "{" .. table.concat(fields, ",") .. "}"
        end
        local chunk = assert(loadstring("return " .. serialize(f.atReload))); setfenv(chunk, {})
        local again = make(chunk()); again.enter(); eq(again.setup.window, nil); assert(again.setup.Open())
        eq(again.setup.draft.sound, true); eq(again.setup.draft.highContrast, true)
        eq(again.setup.draft.launcher, true); eq(again.setup.draft.animation, false)
        eq(again.runtime.db.onboarding.completed, true); eq(#again.writes, 0)
    end)
    test("W16 an explicit mode click works after dev.4 saved completion with disabled controls", function()
        local first = make(); local db = first.runtime.db
        db.onboarding.completed = true; db.config.studio.enabled = false; db.config.studio.experimentalBrightness = false
        local f = make(db); f.enter(); eq(#f.writes, 0); eq(f.runtime.db.config.studio.enabled, false)
        f.runtime.entry.Open("LeftButton"); f.mock.Click("Lantern"); f.mock.Flush()
        eq(f.runtime.product.active, "lantern"); eq(f.values.Brightness, "65")
        eq(f.runtime.db.config.studio.enabled, true); eq(#f.writes, 1)
    end)
end
