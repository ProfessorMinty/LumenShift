-- Adversarial UI integration checks. These do not certify native input/rendering.
return function(make, eq, test)
    test("A501 lost focus API releases keyboard capture after an earlier Tab", function()
        local f = make(); local ui = f.r.ui; ui.Open(5)
        ui.window.scripts.OnKeyDown(ui.window, "TAB")
        eq(ui.window.SetPropagateKeyboardInputArgs[1], false)
        f.env.GetCurrentKeyBoardFocus = function() error("private native exception") end
        ui.window.scripts.OnKeyDown(ui.window, "W")
        eq(ui.window.SetPropagateKeyboardInputArgs[1], true)
        eq(ui.window.EnableKeyboardArgs[1], false); eq(ui.keyboard.current, nil)
        assert(ui.window:IsShown()); eq(#f.calls, 0)
        assert(not f.ns.Report.Export(f.r):find("private native exception", 1, true))
    end)
    test("A502 failed propagation setup cannot leave keyboard enabled without a handler", function()
        local f = make(); local window = f.env.CreateFrame("Frame", nil, f.env.UIParent)
        window.SetPropagateKeyboardInput = function() error("restricted") end
        f.ns.Keyboard.Attach(f.env, window)
        assert(not window.EnableKeyboardArgs or window.EnableKeyboardArgs[1] == false)
        eq(window.scripts.OnKeyDown, nil); eq(#f.calls, 0)
    end)
    test("A503 native focus is respected and failing modifier reads do not swallow keys", function()
        local f = make(); local ui = f.r.ui; ui.Open(5)
        f.env.IsShiftKeyDown = function() error("restricted modifier") end
        ui.window.scripts.OnKeyDown(ui.window, "TAB")
        eq(ui.window.SetPropagateKeyboardInputArgs[1], true)
        eq(ui.window.EnableKeyboardArgs[1], false); eq(ui.keyboard.current, nil)
        f.mock.Click("Save variation"); assert(f.r.db.config.studio.presets.p1); eq(#f.calls, 0)
    end)
    test("A504 setup preferences refresh applied cosmetics without applying editor changes", function()
        local f = make(); assert(f.r.product.Select("nightVision")); f.flush()
        eq(f.r.presentation.Status(), "VISIBLE")
        local opacity, count = f.r.product.appliedSettings.opacity, #f.calls
        f.r.product.Update(function(c) c.studio.modes.nightVision.opacity = 0.11 end)
        f.r.setup.Open(); f.r.setup.draft.effects = false; f.r.setup.draft.sound = false
        assert(f.r.setup.SaveAndClose()); eq(f.r.presentation.Status(), "OFF"); eq(#f.calls, count)
        f.r.setup.Open(); f.r.setup.draft.effects = true; assert(f.r.setup.SaveAndClose())
        eq(f.r.presentation.Status(), "VISIBLE"); eq(f.r.presentation.tint.color[4], opacity)
        eq(f.r.product.appliedSettings.opacity, opacity); eq(#f.calls, count)
    end)
    test("A505 capacity-limited undo preserves the deleted preset until space is available", function()
        local f = make(); local p, ui = f.r.product, f.r.ui
        for i = 1, 24 do assert(p.SavePreset("Look " .. i, "nightVision")) end
        ui.Open(5); f.mock.Click("Delete"); local removed = ui.deletedPreset
        assert(p.SavePreset("Replacement", "moonlight")); ui.RebuildInPlace()
        f.mock.Click("Undo last deletion"); eq(ui.deletedPreset, removed)
        eq(f.r.db.config.studio.presets[removed.id], nil)
        assert(p.Update(function(c) c.studio.presets.p25 = nil end))
        f.mock.Click("Undo last deletion"); eq(ui.deletedPreset, nil)
        eq(f.r.db.config.studio.presets[removed.id].name, removed.value.name); eq(#f.calls, 0)
    end)
    test("A506 failed propagation during activation performs no action and keeps mouse controls", function()
        local f = make(); local ui = f.r.ui; ui.Open(5)
        ui.keyboard.current = ui.primary
        local propagate = ui.window.SetPropagateKeyboardInput
        ui.window.SetPropagateKeyboardInput = function(self, value)
            if value == false then error("restricted") end
            propagate(self, value)
        end
        ui.window.scripts.OnKeyDown(ui.window, "ENTER")
        eq(next(f.r.db.config.studio.presets), nil)
        eq(ui.window.EnableKeyboardArgs[1], false)
        f.mock.Click("Save variation"); assert(f.r.db.config.studio.presets.p1); eq(#f.calls, 0)
    end)
    test("A507 action exceptions release keyboard and redact native details", function()
        local f = make(); local ui = f.r.ui; ui.Open(5)
        ui.keyboard.current = ui.primary
        ui.primary:SetScript("OnClick", function() error("private button failure") end)
        ui.window.scripts.OnKeyDown(ui.window, "ENTER")
        eq(ui.window.SetPropagateKeyboardInputArgs[1], true)
        eq(ui.window.EnableKeyboardArgs[1], false); eq(ui.keyboard.error, "KEYBOARD_ACTION_FAILED")
        eq(#f.calls, 0); assert(not f.ns.Report.Export(f.r):find("private button failure", 1, true))
    end)
    test("A508 unexpected focus results disable only keyboard navigation", function()
        local f = make(); local ui = f.r.ui; ui.Open(5)
        f.env.GetCurrentKeyBoardFocus = function() return 7 end
        ui.window.scripts.OnKeyDown(ui.window, "TAB")
        eq(ui.keyboard.error, "KEYBOARD_FOCUS_UNAVAILABLE"); eq(ui.keyboard.enabled, false)
        eq(ui.window.SetPropagateKeyboardInputArgs[1], true)
        ui.Open(1); assert(ui.window:IsShown()); eq(#f.calls, 0)
    end)
    test("A509 saved mute stops the current cue and retains preferences across reload", function()
        local f = make(); local p, setup = f.r.product, f.r.setup
        p.Update(function(c) c.preferences.sound = true end)
        setup.Open(); assert(f.r.audio.Play("on", f.r.db.config))
        local played = #f.mock.soundCalls
        setup.draft.sound, setup.draft.reducedMotion = false, true
        assert(setup.SaveAndClose()); eq(f.mock.stops[#f.mock.stops], played); eq(#f.calls, 0)
        local g = make(f.r.db, f.values)
        eq(g.r.db.config.preferences.sound, false); eq(g.r.db.config.preferences.reducedMotion, true)
        eq(g.r.db.onboarding.completed, true); eq(#g.calls, 0); eq(#g.mock.soundCalls, 0)
    end)
    test("A510 consumed navigation preserves unrelated held-key releases", function()
        local f = make(); local ui = f.r.ui; ui.Open(5)
        local down, up = ui.window.scripts.OnKeyDown, ui.window.scripts.OnKeyUp
        down(ui.window, "W"); eq(ui.window.SetPropagateKeyboardInputArgs[1], true)
        down(ui.window, "TAB"); eq(ui.window.SetPropagateKeyboardInputArgs[1], false)
        up(ui.window, "W"); eq(ui.window.SetPropagateKeyboardInputArgs[1], true)
        up(ui.window, "TAB"); eq(ui.window.SetPropagateKeyboardInputArgs[1], false)
        down(ui.window, "TAB"); ui.window:Hide(); eq(next(ui.keyboard.consumed), nil)
        ui.Open(5); up(ui.window, "W"); eq(ui.window.SetPropagateKeyboardInputArgs[1], true)
        eq(#f.calls, 0)
    end)
end
