return function(fixture, native, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function studio(saved, original)
        local f = native(saved, original)
        f.uiMock = widgets(f.env)
        f.product = f.ns.runtime.product
        f.ui = f.ns.Studio.New(f.ns.runtime); f.ns.runtime.ui = f.ui
        function f.enable(experimental)
            assert(f.product.Enable(true))
            f.env.LumenShiftDB.config.studio.experimentalBrightness = experimental == true
        end
        function f.select(id) local ok, code = f.product.Select(id); assert(ok, code); f.uiMock.Flush() end
        return f
    end
    test("P01 schema-1 migration preserves journal, selections and source input without enabling controls", function()
        local f = native(); f.activate()
        local old = f.ns.Value.Copy(f.env.LumenShiftDB)
        old.schemaVersion = 1; old.baseline = nil; old.camera = nil; old.config.studio = nil; old.experiments = nil; old.onboarding = nil; old.graphics = nil; old.optics = nil
        local copy, code = f.ns.Store.Open(old)
        eq(code, "MIGRATED_1_TO_22"); eq(copy.schemaVersion, 22); eq(old.schemaVersion, 1); eq(old.config.studio, nil)
        eq(copy.journal.entries.Brightness.originalRaw, "52"); eq(copy.journal.entries.Brightness.state, "owned")
        eq(copy.config.studio.enabled, false)
        local reload = studio(old, "75"); eq(#reload.calls, 0); eq(reload.engine.Status().state, "RECOVERY")
        assert(reload.product.Enable(true)); eq(#reload.calls, 0)
        reload.select("nightVision"); eq(#reload.calls, 0); eq(reload.engine.Status().original, "52"); reload.zero()
    end)
    test("P02 setup and every Studio page load without any native write or sound", function()
        local f = studio()
        eq(f.env.LumenShiftDB.config.studio.enabled, false)
        for page = 1, 9 do f.ui.Open(page) end
        f.enable(); eq(#f.calls, 0); eq(#f.uiMock.soundCalls, 0)
        eq(f.product.active, "natural"); eq(f.engine.Status().state, "BASELINE"); f.zero()
    end)
    test("P03 all six modes retain the first raw original and preserve quality/Contrast", function()
        local f = studio(nil, "052.00"); f.enable(true)
        f.ns.runtime.db.config.studio.modes.clarity.brightnessMode = "custom"
        for _, id in ipairs({ "nightVision", "cinematic", "lantern", "clarity", "moonlight" }) do
            assert(f.product.Select(id)); eq(f.product.busy, true)
            f.uiMock.Flush(); eq(f.product.active, id); eq(f.engine.Status().original, "052.00")
            eq(f.env.LumenShiftDB.config.selected.quality, "currentBaseline"); eq(f.values.Contrast, "60")
        end
        f.select("natural"); eq(f.values.Brightness, "052.00"); eq(f.engine.Status().state, "BASELINE")
        eq(f.ns.runtime.presentation.frame:IsShown(), false); eq(#f.calls, 6); f.zero()
    end)
    test("P04 source-range targets work without extra unlocks while invalid preferences remain rejected", function()
        local f = studio(); f.enable()
        f.select("cinematic"); eq(f.values.Brightness, "42"); eq(#f.calls, 1)
        f.select("nightVision"); eq(f.values.Brightness, "75")
        local old = f.env.LumenShiftDB.config.studio.modes.nightVision.contrast
        eq(f.product.Update(function(copy) copy.studio.modes.nightVision.useContrast = "yes" end), nil)
        eq(f.env.LumenShiftDB.config.studio.modes.nightVision.useContrast, false)
        eq(f.env.LumenShiftDB.config.studio.modes.nightVision.contrast, old)
        eq(f.product.Update(function(copy) copy.studio.modes.nightVision.brightness = 0/0 end), nil)
        eq(#f.calls, 2); f.zero()
    end)
    test("P05 quality scans are read-only and empty profiles cannot pretend to apply", function()
        local f = studio(); f.enable(); f.select("nightVision")
        for _, candidate in ipairs(f.ns.Quality.Candidates) do f.values[candidate.key] = "1" end
        local rows = f.ns.Quality.Scan(f.ns.runtime.reader); eq(#rows, 15)
        for _, row in ipairs(rows) do
            if row.key == "assaoDetailShadowStrength" then eq(not not row.operational, false) -- 1 exceeds the isolated trial limit
            else eq(row.operational, f.ns.ExperimentPolicy.Known(row.key)) end
            eq(row.observation.raw, "1")
        end
        for _, id in ipairs({ "balanced", "vista", "performance" }) do
            eq(f.ns.Quality.Select(f.env.LumenShiftDB, id), nil)
        end
        assert(f.ns.Quality.Select(f.env.LumenShiftDB, "currentBaseline"))
        eq(f.product.active, "nightVision"); eq(f.values.Brightness, "75"); eq(#f.calls, 1); f.zero()
    end)
    test("P06 preset validation, copy isolation, rename and bounded storage reject injected keys", function()
        local f = studio()
        for i = 1, 24 do assert(f.product.SavePreset("Variation " .. i, "nightVision")) end
        eq(f.product.SavePreset("Overflow", "nightVision"), nil)
        eq(f.product.SavePreset("bad|name", "nightVision"), nil)
        local copy = f.ns.Value.Copy(f.env.LumenShiftDB.config.studio)
        copy.presets.p1.settings.targets = { Contrast = 80 }
        eq(f.ns.StudioConfig.Validate(copy), false)
        eq(f.env.LumenShiftDB.config.studio.presets.p1.settings.targets, nil)
        assert(f.product.Update(function(config) config.studio.presets.p1.name = "My eyes" end))
        f.enable(); assert(f.product.LoadPreset("p1")); f.uiMock.Flush()
        eq(f.product.active, "nightVision"); eq(f.env.LumenShiftDB.config.selected.quality, "currentBaseline"); f.zero()
    end)
    test("P07 Studio pages reuse native frames across repeated edits and diagnostics", function()
        local f = studio()
        for page = 1, 9 do f.ui.Open(page) end
        local count = #f.uiMock.nodes
        for _ = 1, 20 do for page = 1, 9 do f.ui.Open(page) end end
        eq(#f.uiMock.nodes, count); eq(#f.calls, 0); f.zero()
    end)
    test("P08 wheel clamps, cancels, selects by keyboard and respects combat without rebinding", function()
        local f = studio(); f.enable(true)
        local x, y = f.ns.Radial.Clamp(9999, -50, 1280, 800, 180)
        eq(x, 1100); eq(y, 180)
        f.ui.Wheel(); local wheel = f.ui.radial.frame
        assert(wheel:IsShown()); wheel.scripts.OnKeyDown(wheel, "ESCAPE"); eq(wheel:IsShown(), false); eq(#f.calls, 0)
        f.ui.Wheel(); wheel.scripts.OnKeyDown(wheel, "6"); f.uiMock.Flush()
        eq(f.product.active, "moonlight"); eq(wheel:IsShown(), false)
        f.env.InCombatLockdown = function() return true end
        f.ui.Wheel(); eq(wheel:IsShown(), false); eq(f.product.Toggle(), nil); eq(#f.calls, 1); f.zero()
    end)
    test("P09 active external changes suspend effects and preserve external graphics without fights", function()
        local f = studio(); f.enable(); f.select("nightVision")
        f.values.Brightness = "63"
        f.frame.OnEvent(f.frame, "CVAR_UPDATE", "Brightness", "63")
        eq(f.values.Brightness, "63"); eq(#f.calls, 1); eq(f.engine.Status().state, "CONFLICT")
        eq(f.product.active, "natural"); eq(f.ns.runtime.presentation.frame:IsShown(), false)
        eq(f.product.Select("nightVision"), nil); eq(#f.calls, 1); f.zero()
    end)
    test("P10 delayed verification refuses drift and combat without automatic compensation", function()
        for _, scenario in ipairs({ "drift", "combat" }) do
            local f = studio(); f.enable(); assert(f.product.Select("nightVision"))
            if scenario == "drift" then f.values.Brightness = "63"
            else f.env.InCombatLockdown = function() return true end end
            f.uiMock.Flush(); eq(f.product.busy, false); eq(f.product.active, "natural")
            eq(#f.calls, 1); eq(f.engine.Status().original, "52"); f.zero()
        end
    end)
    test("P11 absent/failed timers refuse or retain recovery and never claim a committed mode", function()
        local f = studio(); f.env.C_Timer = nil
        eq(f.product.Enable(true), nil); eq(#f.calls, 0)
        f = studio(); f.enable(); f.env.C_Timer.After = function() error("scheduler unavailable") end
        eq(f.product.Select("nightVision"), nil); eq(#f.calls, 1)
        eq(f.engine.Status().original, "52"); eq(f.engine.Status().state, "RECOVERY"); eq(f.product.active, "natural"); f.zero()
    end)
    test("P12 a manual recovery cannot be committed as a stale scheduled visual selection", function()
        local f = studio(); f.enable(); assert(f.product.Select("nightVision"))
        assert(f.engine.Prepare("restore")); assert(f.engine.Confirm(f.engine.Status().token))
        f.uiMock.Flush(); eq(f.product.active, "natural"); eq(f.values.Brightness, "52")
        eq(f.engine.Status().state, "AWAITING_VERIFICATION"); eq(f.engine.Status().original, "52")
        assert(f.engine.Verify()); eq(f.engine.Status().state, "BASELINE"); eq(#f.calls, 2); f.zero()
    end)
    test("P13 saved setup and selected modes never cause a startup reapply", function()
        local first = studio(); first.enable(); first.select("nightVision")
        local f = studio(first.env.LumenShiftDB, "75")
        eq(f.product.active, "natural"); eq(f.engine.Status().state, "RECOVERY"); eq(#f.calls, 0)
        f.select("nightVision"); eq(#f.calls, 0); eq(f.product.active, "nightVision")
        eq(f.engine.Status().original, "52"); f.zero()
    end)
    test("P14 cues follow verified transitions, stop previous handles and stay optional", function()
        local f = studio(); f.enable(); f.select("nightVision"); eq(#f.uiMock.soundCalls, 0)
        f.select("natural"); assert(f.product.Update(function(copy) copy.preferences.sound = true end))
        assert(f.product.Select("nightVision")); eq(#f.uiMock.soundCalls, 0)
        f.uiMock.Flush(); eq(#f.uiMock.soundCalls, 1)
        assert(f.uiMock.soundCalls[1][1]:find("night-on-soft.wav", 1, true)); eq(f.uiMock.soundCalls[1][2], "SFX")
        f.select("natural"); eq(#f.uiMock.soundCalls, 2); assert(#f.uiMock.stops >= 1); f.zero()
    end)
    test("P15 audio errors do not falsify graphics success; combat hides all presentation", function()
        local f = studio(); f.enable(); f.env.LumenShiftDB.camera.effectsInCombat=false; f.env.LumenShiftDB.config.preferences.sound = true
        f.env.PlaySoundFile = function() error("audio private error") end
        f.select("nightVision"); eq(f.engine.Status().state, "ACTIVE")
        eq(f.ns.runtime.audio.lastError, "API_ERROR")
        f.frame.OnEvent(f.frame, "PLAYER_REGEN_DISABLED")
        eq(f.ns.runtime.presentation.frame:IsShown(), false); eq(#f.calls, 1)
        f.frame.OnEvent(f.frame, "PLAYER_REGEN_ENABLED"); eq(f.ns.runtime.presentation.frame:IsShown(), true); eq(#f.calls, 1); f.zero()
    end)
    test("P16 already-matching unowned mode retains effects until current value actually changes", function()
        local f = studio(nil, "75"); f.enable(); f.select("nightVision")
        eq(#f.calls, 0); eq(f.engine.Status().original, nil)
        f.product.Observe(); eq(f.product.active, "nightVision")
        f.product.Update(function(copy) copy.studio.modes.nightVision.brightness = 70 end)
        f.product.Observe(); eq(f.product.active, "nightVision")
        f.values.Brightness = "63"; f.product.Observe(); eq(f.product.active, "natural"); eq(#f.calls, 0); f.zero()
    end)
    test("P17 disabling requires restoration and revokes a pending preview", function()
        local f = studio(); f.enable(); f.select("nightVision")
        eq(f.product.Disable(), nil); eq(f.env.LumenShiftDB.config.studio.enabled, true)
        f.select("natural"); local token = f.preview("on")
        assert(f.product.Disable()); eq(f.engine.Confirm(token), nil); eq(#f.calls, 2); f.zero()
    end)
    test("P18 slider edits change only validated saved settings; reset does not write", function()
        local f = studio(); f.ui.Open(1)
        for _, node in ipairs(f.uiMock.nodes) do
            if node.kind == "Slider" and node.maximum == 100 and node:IsVisible() then node:SetValue(80) end
        end
        eq(f.env.LumenShiftDB.config.studio.modes.nightVision.brightness, 80); eq(#f.calls, 0)
        f.uiMock.Click("Reset this mode's saved settings")
        eq(f.env.LumenShiftDB.config.studio.modes.nightVision.brightness, 75); eq(#f.calls, 0); f.zero()
    end)
    test("P19 malformed studio data and unknown schema retain original SavedVariables untouched", function()
        local first = studio()
        for _, change in ipairs({ function(data) data.config.studio.modes.nightVision.tint.r = 9 end,
            function(data) data.schemaVersion = 999 end,
            function(data) data.config.studio.presets.p1 = { name = "Bad", mode = "nightVision", settings = function() end } end }) do
            local data = first.ns.Value.Copy(first.env.LumenShiftDB); change(data)
            local f = fixture(data); f.load(); eq(f.ns.runtime.db, nil); eq(f.env.LumenShiftDB, data); f.zero()
        end
    end)
    test("P20 original mode metadata stays independent across all personal-preset operations", function()
        local f = studio(); f.enable(true)
        f.product.Update(function(copy) copy.studio.modes.lantern.brightness = 66 end)
        local id = assert(f.product.SavePreset("Warm study", "lantern"))
        f.product.Update(function(copy) copy.studio.modes.lantern.brightness = 67 end)
        eq(f.env.LumenShiftDB.config.studio.presets[id].settings.brightness, 66)
        assert(f.product.LoadPreset(id)); f.uiMock.Flush(); eq(f.values.Brightness, "66")
        eq(f.env.LumenShiftDB.config.selected.quality, "currentBaseline")
        eq(f.values.Contrast, "60"); f.select("natural"); eq(f.values.Brightness, "52"); f.zero()
    end)
    test("P21 full bootstrap builds UI and bindings once with no startup action, including enabled saved setup", function()
        local first = studio(); first.enable()
        local f = fixture(first.env.LumenShiftDB)
        local uiModel = widgets(f.env); f.load()
        assert(f.ns.runtime.ui); eq(f.ns.runtime.lastError, nil)
        eq(f.env.BINDING_NAME_LUMENSHIFT_TOGGLE, "Toggle Night Vision")
        f.env.LumenShift_OpenStudio(); assert(f.ns.runtime.ui.window:IsShown())
        f.env.LumenShift_OpenWheel(); assert(f.ns.runtime.ui.radial.frame:IsShown())
        local count = #uiModel.nodes; f.load(); eq(#uiModel.nodes, count)
        eq(f.ns.runtime.product.active, "natural"); eq(#uiModel.soundCalls, 0); f.zero()
        local broken = fixture(); widgets(broken.env)
        broken.env.CreateFrame = function() error("missing UI support") end; broken.load()
        eq(broken.ns.runtime.lastError, "UI_INITIALIZATION_FAILED")
        broken.env.SlashCmdList.LUMENSHIFT(); broken.zero()
    end)
    test("P22 restricted input and unknown cursors fall back without capturing keys or writing", function()
        for _, change in ipairs({ function(f) f.env.GetCursorPosition = nil end,
            function(f) f.env.GetCursorPosition = function() return "SECRET", 1 end end,
            function(f) f.ui.radial.frame.SetPropagateKeyboardInput = false end,
            function(f) f.ui.radial.frame.SetPropagateKeyboardInput = function() error("restricted") end end }) do
            local f = studio(); change(f); f.ui.Wheel()
            eq(f.ui.radial.frame:IsShown(), false); eq(f.ui.window:IsShown(), true); eq(#f.calls, 0); f.zero()
        end
    end)
    test("P23 effects honor opt-outs and corner anchors without hiding or resizing the HUD", function()
        local f = studio(); f.enable(); f.select("nightVision")
        local p = f.ns.runtime.presentation
        eq(p.frame.EnableMouseArgs[1], false); eq(p.frame.SetFrameStrataArgs[1], "BACKGROUND")
        eq(p.edges[1].points[1][1], "TOPLEFT"); eq(p.edges[1].points[2][1], "TOPRIGHT")
        eq(p.edges[3].points[1][1], "TOPLEFT"); eq(p.edges[3].points[2][1], "BOTTOMLEFT")
        f.product.Update(function(copy) copy.studio.screenshot = true; copy.studio.modes.nightVision.letterbox = 0.1 end)
        assert(f.product.RefreshPresentation()); eq(p.bars[1]:GetHeight(), 80)
        eq(p.bars[1].points[1][1], "TOPLEFT"); eq(p.bars[1].points[2][1], "TOPRIGHT")
        eq(f.env.UIParent:GetWidth(), 1280); eq(f.env.UIParent:GetHeight(), 800); eq(f.env.UIParent:IsShown(), true)
        f.product.Update(function(copy) copy.studio.effects = false end)
        assert(f.product.RefreshPresentation()); eq(p.frame:IsShown(), false)
        f.product.Update(function(copy) copy.studio.effects = true end)
        f.env.InCombatLockdown = function() error("inaccessible") end
        assert(f.product.RefreshPresentation()); eq(p.frame:IsShown(), false); eq(#f.calls, 1); f.zero()
    end)
    test("P24 enabling controls refuses unreadable identity or missing native writer", function()
        for _, change in ipairs({ function(f) f.env.C_CVar.SetCVar = nil end,
            function(f) f.env.GetBuildInfo = function() return nil end end }) do
            local f = studio(); change(f); eq(f.product.Enable(true), nil)
            eq(f.env.LumenShiftDB.config.studio.enabled, false); eq(#f.calls, 0); f.zero()
        end
    end)
    test("P25 diagnostic quality export distinguishes absent and restricted values without admission", function()
        local f = studio(); f.values.farclip = "5000"
        local getInfo = f.env.C_CVar.GetCVarInfo
        f.env.C_CVar.GetCVarInfo = function(key)
            if key == "farclip" then return "5000", "50", false, false, false, false, true end
            return getInfo(key)
        end
        local report = table.concat(f.ns.Diagnostics.QualityLines(f.ns.runtime), "\n")
        assert(report:find("farclip=5000", 1, true)); assert(report:find("readOnly=yes", 1, true))
        assert(report:find("unavailable", 1, true)); assert(report:find("Currently unavailable", 1, true))
        eq(#f.calls, 0); f.zero()
    end)
    test("P26 ordinary selection verifies quietly and reduced motion suppresses fades", function()
        local f = studio(); f.enable()
        f.product.Update(function(copy) copy.preferences.reducedMotion = true end)
        f.ui.Open(); eq(f.ui.window.lumenFade, nil); f.ui.Wheel(); eq(f.ui.radial.frame.lumenFade, nil)
        assert(f.product.Select("nightVision"))
        local report = table.concat(f.output, "\n")
        eq(report:find("RECOVERY CARD", 1, true), nil)
        eq(f.engine.Status().original, "52"); eq(f.engine.Status().state, "AWAITING_VERIFICATION")
        eq(report:find("then /ls verify", 1, true), nil)
        f.uiMock.Flush(); eq(f.product.active, "nightVision"); f.zero()
    end)
    test("P27 legacy slash recovery clears Studio effects without waiting for another event", function()
        local f = studio(); f.enable(); f.select("nightVision")
        f.env.SlashCmdList.LUMENSHIFT("restore")
        f.env.SlashCmdList.LUMENSHIFT("confirm " .. f.engine.Status().token)
        eq(f.ns.runtime.presentation.frame:IsShown(), false)
        f.env.SlashCmdList.LUMENSHIFT("verify")
        eq(f.product.active, "natural"); eq(f.engine.Status().state, "BASELINE")
        eq(f.values.Brightness, "52"); eq(#f.calls, 2); f.zero()
    end)
    test("U01 card selection is read-only; the fixed Apply action uses the selected mode", function()
        local f = studio(); f.enable(); f.ui.Open(1)
        f.uiMock.Click("Moonlight"); eq(f.ui.edited, "moonlight"); eq(f.product.active, "natural")
        eq(#f.calls, 0); eq(f.ui.primary.label.text, "Apply Moonlight")
        f.uiMock.Click("Apply Moonlight"); f.uiMock.Flush()
        eq(f.product.active, "moonlight"); eq(#f.calls, 1)
        f.uiMock.Click("Original"); eq(#f.calls, 1)
        f.uiMock.Click("Apply Original"); f.uiMock.Flush(); eq(f.values.Brightness, "52"); eq(#f.calls, 2)
        f.zero()
    end)
    test("U02 quality cards preview without applying; fixed action keeps layers separate", function()
        local f = studio(); f.enable(); f.select("nightVision"); f.ui.Open(2)
        local applied
        f.ns.runtime.lab.SelectProfile = function(id) applied = id; return true end
        f.uiMock.Click("Detail profiles"); f.uiMock.Click("Vista"); eq(applied, nil); eq(f.ui.qualityID, "vista")
        eq(f.product.active, "nightVision"); eq(#f.calls, 1)
        f.uiMock.Click("Apply Vista"); eq(applied, "vista"); eq(#f.calls, 1)
        f.ui.Open(1); eq(f.ui.primary.label.text, "Apply Night Vision")
        f.zero()
    end)
    test("U03 switches persist preferences across navigation without changing the scene", function()
        local f = studio(); f.ui.Open(6)
        local config = f.env.LumenShiftDB.config
        local before = config.preferences.reducedMotion
        f.uiMock.Click("Reduced motion"); eq(f.env.LumenShiftDB.config.preferences.reducedMotion, not before)
        f.ui.Open(1); f.ui.Open(6)
        for _, n in ipairs(f.uiMock.nodes) do
            if n:IsVisible() and n.label and n.label.text == "Reduced motion" then eq(n.value, not before) end
        end
        eq(f.ui.primary:IsShown(), false); eq(#f.calls, 0); eq(#f.uiMock.soundCalls, 0); f.zero()
    end)
    test("U04 Studio respects effective scale and stays inside a small viewport", function()
        local f = studio()
        f.env.UIParent:SetScale(0.711); f.env.UIParent:SetSize(1920 / 0.711, 1080 / 0.711)
        f.ui.Open(1); eq(f.ui.window:GetEffectiveScale(), 1)
        f.env.UIParent:SetSize(800, 600)
        f.env.LumenShiftDB.config.studio.scale = 1.5; f.ui.Open(6)
        assert(f.ui.window:GetWidth() * f.ui.window.scale <= 800)
        assert(f.ui.window:GetHeight() * f.ui.window.scale <= 600)
        eq(#f.calls, 0); f.zero()
    end)
    test("U05 pooled disabled controls are reenabled before reuse and callbacks are replaced", function()
        local f = studio(); local W = f.ns.Widgets
        local parent = f.env.CreateFrame("Frame", nil, f.env.UIParent)
        local pool = W.CreatePool(f.env, parent); local old, fresh = 0, 0
        local a = W.Button(pool.env, parent, "Old", 0, 0, 120, function() old = old + 1 end)
        a:Disable(); f.uiMock.Click("Old"); eq(old, 0)
        pool.Reset()
        local b = W.Button(pool.env, parent, "Fresh", 0, 0, 120, function() fresh = fresh + 1 end)
        eq(a, b); assert(b:IsEnabled()); f.uiMock.Click("Fresh"); eq(old, 0); eq(fresh, 1); f.zero()
    end)
    test("U06 page changes keep one selected navigation item and separate fixed action from scroll", function()
        local f = studio()
        for page = 1, 9 do
            f.ui.Open(page)
            local selected = 0; for id, b in pairs(f.ui.nav) do
                if b.selected then selected = selected + 1; eq(id, page) end
            end
            eq(selected, 1); eq(f.ui.primary:GetParent(), f.ui.window)
            f.ui.scrollBar:SetValue(f.ui.scrollMaximum)
            eq(f.ui.primary.points[1][5], -695)
        end
        eq(#f.calls, 0); eq(#f.uiMock.soundCalls, 0); f.zero()
    end)
    test("U07 textured navigation preserves action labels and high contrast removes decoration", function()
        local f = studio(); f.ui.Open(1)
        for _, button in pairs(f.ui.nav) do assert(button.icon and button.icon.texture); assert(#button.label.text > 0) end
        f.ui.Open(6); f.uiMock.Click("High-contrast panel")
        eq(f.ui.panelArt:IsShown(), false); eq(f.ui.headerArt:IsShown(), false); eq(f.ui.sidebarArt:IsShown(), false)
        f.ui.Open(1); eq(f.ui.nav[1].selected, true); eq(f.ui.primary.label.text, "Apply Night Vision")
        f.ui.Wheel(); eq(f.ui.radial.halo:IsShown(), false)
        f.ui.radial.Close(); f.ui.Open(6); f.uiMock.Click("High-contrast panel")
        eq(f.ui.panelArt:IsShown(), true); eq(#f.calls, 0); eq(#f.uiMock.soundCalls, 0); f.zero()
    end)
    test("U08 pooled texture opacity tint crop and edit focus reset without scene writes", function()
        local f = studio(); local W = f.ns.Widgets
        local parent = f.env.CreateFrame("Frame", nil, f.env.UIParent); local pool = W.CreatePool(f.env, parent)
        local art = W.Art(parent, "light-sweep", 0, 0, 100, 30, .2)
        art:SetVertexColor(.2, .3, .4, 1); art:SetTexCoord(.2, .8, .3, .7)
        pool.Reset(); local fresh = W.Fill(parent)
        eq(art, fresh); eq(fresh.alpha, 1); eq(fresh.vertexColor[1], 1); eq(fresh.SetTexCoordArgs[1], 0); eq(fresh.texture, nil)
        local edit = W.Edit(pool.env, parent, "52", 0, 0, 100, function() end)
        edit:SetFocus(); local focusBorder = edit.lumenRegions.texture[2]
        eq(focusBorder.color[2], W.colors.accent[2]); edit:ClearFocus(); eq(focusBorder.color[2], W.colors.border[2])
        eq(#f.calls, 0); f.zero()
    end)
    test("U09 radial sector follows keyboard selection with no write until activation", function()
        local f = studio(); f.ui.Wheel()
        local wheel = f.ui.radial
        assert(wheel.sector.texture:match('wheel%-sector%-1'))
        local count = #f.uiMock.nodes
        for _ = 1, 24 do wheel.frame.scripts.OnKeyDown(wheel.frame, "RIGHT") end
        eq(#f.uiMock.nodes, count); eq(#f.calls, 0)
        wheel.frame.scripts.OnKeyDown(wheel.frame, "RIGHT")
        assert(wheel.sector.texture:match('wheel%-sector%-2'))
        wheel.frame.scripts.OnKeyDown(wheel.frame, "ESCAPE"); eq(wheel.frame:IsShown(), false); f.zero()
    end)
    test("U10 visible wheel sectors accept clicks while center gaps and outside do not", function()
        local f = studio(); local R = f.ns.Radial
        for i = 1, 6 do
            local angle = math.rad(90 - (i - 1) * 60)
            eq(R.Hit(math.cos(angle) * 150, math.sin(angle) * 150), i)
        end
        eq(R.Hit(0, 0), nil); eq(R.Hit(0, 180), nil); eq(R.Hit(0/0, 100), nil)
        eq(R.Hit(math.cos(math.rad(60)) * 150, math.sin(math.rad(60)) * 150), nil)
        f.enable(); f.ui.Wheel(); local wheel = f.ui.radial.frame
        local cx, cy = wheel:GetCenter()
        f.env.GetCursorPosition = function() return cx + 130, cy + 75 end
        wheel.scripts.OnMouseDown(wheel, "LeftButton"); f.uiMock.Flush()
        eq(f.product.active, "nightVision"); eq(#f.calls, 1); eq(wheel:IsShown(), false); f.zero()
    end)
    test("U11 window title bars raise drag and stop without moving foreign frames or losing hide behavior", function()
        local f = studio(); f.ui.Open(1)
        local setup = f.ns.Setup.New(f.ns.runtime); assert(setup.Open())
        f.ns.DiagnosticWindow.Open(f.ns.runtime)
        local foreign = f.env.CreateFrame("Frame", nil, f.env.UIParent)
        for _, window in ipairs({ f.ui.window, setup.window, f.ns.runtime.exportUI.window }) do
            eq(window.SetFrameStrataArgs[1], "FULLSCREEN_DIALOG"); eq(window.SetToplevelArgs[1], true)
            eq(window.SetClampedToScreenArgs[1], true); eq(window.SetMovableArgs[1], true)
            local header = assert(window.lumenDragHandle); eq(header.RegisterForDragArgs[1], "LeftButton")
            header.scripts.OnDragStart(header); assert(window.StartMovingArgs); assert(window.RaiseArgs)
            header.scripts.OnDragStop(header); assert(window.StopMovingOrSizingArgs)
            window.StopMovingOrSizingArgs = nil; window:Hide(); assert(window.StopMovingOrSizingArgs)
            window.RaiseArgs = nil; window:Show(); assert(window.RaiseArgs)
        end
        eq(f.ns.runtime.exportUI.box.focus, false); eq(foreign.SetFrameStrataArgs, nil)
        eq(foreign.StartMovingArgs, nil); eq(#f.calls, 0); f.zero()
    end)
    test("U12 wheel labels have stable single-line geometry and a separate active indicator", function()
        local f = studio(); f.ns.runtime.db.baseline.source = "gameDefaults"
        f.ui.Wheel()
        for i, button in ipairs(f.ui.radial.buttons) do
            eq(button.label.SetWordWrapArgs[1], false); eq(button.label.SetNonSpaceWrapArgs[1], false)
            eq(button.label.width, 128); eq(button.label.fontSize, 13)
            eq(button.label.text:find("*", 1, true), nil); assert(button.activeMark)
            eq(button.shortcut.text, tostring(i))
            local point = button.points[1]
            assert(point[4] >= 0 and point[4] + button.width <= 420)
            assert(-point[5] >= 0 and -point[5] + button.height <= 420)
        end
        eq(f.ui.radial.buttons[1].label.text, "Game Defaults"); eq(#f.calls, 0); f.zero()
    end)
    test("P24 reload failures pending records and external drift cannot be mistaken for completed ownership", function()
        local first = studio(nil, "045.00"); first.enable(); first.select("cinematic")
        for _, fault in ipairs({ "pending", "failed", "conflict", "external", "flags", "original", "descriptor", "version" }) do
            local saved = first.ns.Value.Copy(first.env.LumenShiftDB); local entry = saved.journal.entries.Brightness
            if fault == "pending" or fault == "failed" or fault == "conflict" then entry.state = fault end
            if fault == "original" then entry.originalRaw = "not-a-number" end
            if fault == "descriptor" then entry.descriptorVersion = 999 end
            if fault == "version" then entry.signature = "1.60.1:70862:16001" end
            local f = studio(saved, fault == "external" and "63" or "42")
            if fault == "flags" then f.env.C_CVar.GetCVarInfo = function() return "42", "50", false, false, false, true, false, false end end
            eq(f.product.Select("nightVision"), nil); eq(#f.calls, 0)
            eq(f.env.LumenShiftDB.journal.entries.Brightness.originalRaw, entry.originalRaw); f.zero()
        end
    end)
    test("P27 Original can be the first post-reload click and restores the exact saved raw value", function()
        local first = studio(nil, "045.00"); first.enable(); first.select("cinematic")
        local f = studio(first.env.LumenShiftDB, "42")
        eq(#f.calls, 0); f.select("natural"); eq(#f.calls, 1)
        eq(f.calls[1], "045.00"); eq(f.values.Brightness, "045.00")
        eq(f.engine.Status().state, "BASELINE"); eq(next(f.env.LumenShiftDB.journal.entries), nil); f.zero()
    end)
    test("P25 a resumed no-op remains conflict monitored and retains the exact original", function()
        local first = studio(nil, "045.00"); first.enable(); first.select("nightVision")
        local f = studio(first.env.LumenShiftDB, "75"); f.select("nightVision")
        eq(#f.calls, 0); eq(f.engine.Status().original, "045.00")
        f.values.Brightness = "63"; eq(f.product.Select("natural"), nil); eq(#f.calls, 0)
        eq(f.engine.Status().state, "CONFLICT"); eq(f.engine.Status().original, "045.00"); f.zero()
    end)
    test("P26 resumed change still detects pre-write drift and retains originals after setter failure", function()
        local first = studio(nil, "045.00"); first.enable(); first.select("cinematic")
        local f = studio(first.env.LumenShiftDB, "42")
        f.setter = function() return false end
        eq(f.product.Select("nightVision"), nil); f.uiMock.Flush()
        eq(f.values.Brightness, "42"); eq(f.engine.Status().original, "045.00"); eq(#f.calls, 1)
        f = studio(first.env.LumenShiftDB, "42")
        local read, reads = f.env.C_CVar.GetCVar, 0
        f.env.C_CVar.GetCVar = function(key)
            if key == "Brightness" then reads = reads + 1; if reads == 2 then f.values.Brightness = "63" end end
            return read(key)
        end
        eq(f.product.Select("nightVision"), nil); eq(#f.calls, 0)
        eq(f.values.Brightness, "63"); eq(f.engine.Status().original, "045.00"); f.zero()
    end)
    if os.getenv("LUMENSHIFT_UI_MODEL_PATH") then
        local f = studio()
        for page = 1, 9 do
            f.ui.Open(page); f.ui.radial.launcher:Hide()
            f.uiMock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-" .. page .. ".tsv")
        end
        f.ui.Open(6); f.uiMock.Click("High-contrast panel"); f.ui.Open(1); f.ui.radial.launcher:Hide()
        f.uiMock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-contrast.tsv")
        f.ui.Open(6); f.uiMock.Click("High-contrast panel")
        f.ui.Open(8); f.uiMock.Click("Shadows, lighting & water"); f.ui.radial.launcher:Hide()
        f.uiMock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-tiers.tsv")
        f.ui.window:Hide(); f.ui.Wheel(); f.uiMock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-wheel.tsv")
        local setup = f.ns.Setup.New(f.ns.runtime); setup.Open(); f.ui.radial.Close()
        f.uiMock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-setup.tsv")
        f.uiMock.Click("Game Defaults")
        f.uiMock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-setup-defaults.tsv")
        setup.SaveAndClose(); f.ui.Open(1); f.ui.edited = "natural"; f.ui.BuildPage()
        f.uiMock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-baseline.tsv")
        f.ui.window:Hide(); f.ui.Wheel(); f.uiMock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-wheel-defaults.tsv"); f.ui.radial.Close()
        f.ui.window:Hide()
        setup.window:Hide(); f.ns.DiagnosticWindow.Open(f.ns.runtime)
        f.uiMock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-report.tsv")
    end
end
