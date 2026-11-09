-- Simulated input/capture lifecycle; not native keyboard or screenshot evidence.
return function(make, eq, test)
    local function key(f, value, up)
        local input = f.r.composition.input
        local handler = input and input.scripts[up and "OnKeyUp" or "OnKeyDown"]
        assert(handler, "Camera keyboard handler expected"); handler(input, value)
    end
    test("PHOTO01 Hide controls removes all chrome and guides without changing the scene", function()
        local f = make(); f.r.db.camera.thirds = true; assert(f.r.product.Select("cinematic")); f.flush()
        assert(f.r.camera.Toggle()); local c = f.r.composition; local count = #f.calls
        local presentation = f.r.presentation.frame; eq(presentation:IsVisible(), true)
        f.env.GameTooltip:Show(); f.mock.Click("Hide controls")
        eq(c.root:IsVisible(), false); eq(c.controlsHidden, true); eq(c.input:IsVisible(), true)
        eq(c.input.EnableMouseArgs[1], false); eq(presentation:IsVisible(), true)
        eq(f.env.GameTooltip:IsShown(), false); eq(f.captures, 0); eq(#f.calls, count)
        c.Show(); eq(c.root:IsVisible(), false) -- rebuilding layout never brings chrome back
        key(f, "H"); eq(c.root:IsShown(), true); eq(c.controlsHidden, false)
        eq(f.r.product.active, "cinematic"); eq(#f.calls, count)
    end)
    test("PHOTO02 Escape exits both ordinary and clean Camera through exact name and FOV restoration", function()
        for _, hidden in ipairs({ false, true }) do
            local f = make(); f.r.db.camera.hideWithUI = true
            assert(f.r.camera.ApplyFOV(75)); f.flush(); assert(f.r.camera.Toggle()); f.flush()
            if hidden then f.mock.Click("Hide controls") end
            key(f, "ESCAPE"); f.flush()
            eq(f.env.UIParent:IsShown(), true); eq(f.r.camera.active, false)
            eq(f.values.cameraFov, "090.00"); eq(f.values.UnitNameFriendlyPlayerName, "1")
            eq(f.values.UnitNameFriendlyPetName, "0"); eq(f.r.db.camera.nameReturn, nil)
            eq(f.r.composition.root:IsShown(), false); eq(f.r.composition.input:IsShown(), false)
        end
    end)
    test("PHOTO03 Escape cancels queued native capture and cannot revive its controls later", function()
        local f = make(); assert(f.r.camera.Toggle()); assert(f.r.composition.Capture())
        eq(f.r.composition.input:IsShown(), true); key(f, "ESCAPE"); f.flush()
        eq(f.captures, 0); eq(f.r.composition.status, "CAPTURE_CANCELLED")
        eq(f.r.camera.active, false); eq(f.r.composition.root:IsShown(), false)
    end)
    test("PHOTO04 Escape exits an issued capture while late completion stays hidden", function()
        local f = make(); assert(f.r.camera.Toggle()); local c = f.r.composition
        assert(c.Capture()); f.tick(); eq(f.captures, 1); key(f, "ESCAPE")
        eq(f.r.camera.active, false); eq(f.env.UIParent:IsShown(), true)
        c.root.scripts.OnEvent(c.root, "SCREENSHOT_SUCCEEDED"); f.flush()
        eq(c.root:IsShown(), false); eq(c.input:IsShown(), false); eq(f.captures, 1)
    end)
    test("PHOTO05 clean view survives screenshot events and display changes", function()
        local f = make(); assert(f.r.camera.Toggle()); local c = f.r.composition
        assert(c.ToggleControls()); assert(c.Capture()); f.tick()
        c.root.scripts.OnEvent(c.root, "SCREENSHOT_SUCCEEDED"); f.flush()
        c.root.scripts.OnEvent(c.root, "DISPLAY_SIZE_CHANGED")
        eq(c.controlsHidden, true); eq(c.root:IsShown(), false); eq(c.input:IsShown(), true)
        key(f, "H"); eq(c.root:IsShown(), true); eq(#f.calls, 0)
    end)
    test("PHOTO06 chat focus and ordinary keys pass through without captures or writes", function()
        local f = make(); assert(f.r.camera.Toggle()); local c = f.r.composition
        for _, value in ipairs({ "W", "TAB", "PRINTSCREEN", "LALT" }) do
            key(f, value); eq(c.input.SetPropagateKeyboardInputArgs[1], true)
        end
        key(f, "H"); key(f, "W", true); eq(c.input.SetPropagateKeyboardInputArgs[1], true)
        key(f, "H", true); eq(c.input.SetPropagateKeyboardInputArgs[1], false)
        local chat = f.env.CreateFrame("EditBox", nil, f.env.UIParent); chat:SetFocus()
        key(f, "H"); key(f, "ESCAPE"); eq(c.controlsHidden, true); eq(f.r.camera.active, true)
        eq(c.input.SetPropagateKeyboardInputArgs[1], true); eq(f.captures, 0); eq(#f.calls, 0)
        chat:ClearFocus(); key(f, "ESCAPE"); eq(f.r.camera.active, false)
    end)
    test("PHOTO07 keyboard failure in clean view reveals the exit controls", function()
        local f = make(); assert(f.r.camera.Toggle()); local c = f.r.composition
        c.ToggleControls(); f.env.GetCurrentKeyBoardFocus = function() error("unavailable") end
        key(f, "H"); eq(c.keyboard.enabled, false); eq(c.controlsHidden, false)
        eq(c.root:IsShown(), true); eq(c.input:IsShown(), false); eq(c.hideButton:IsEnabled(), false)
        f.mock.Click("Exit Camera Mode"); eq(f.env.UIParent:IsShown(), true); eq(#f.calls, 0)
    end)
    test("PHOTO08 absent keyboard preserves clickable capture and exit", function()
        local f = make(); f.env.GetCurrentKeyBoardFocus = nil; assert(f.r.camera.Toggle())
        local c = f.r.composition; eq(c.keyboard.enabled, false); eq(c.root:IsShown(), true)
        eq(c.ToggleControls(), nil); eq(c.hideButton:IsEnabled(), false)
        f.mock.Click("Capture screenshot"); f.tick(); eq(f.captures, 1)
        c.root.scripts.OnEvent(c.root, "SCREENSHOT_SUCCEEDED"); f.mock.Click("Exit Camera Mode")
        eq(f.env.UIParent:IsShown(), true); f.flush(); eq(#f.calls, 0)
    end)
    test("PHOTO09 clean view does not survive exit combat or reload as hidden controls", function()
        local f = make(); assert(f.r.camera.Toggle()); local c = f.r.composition
        c.ToggleControls(); assert(f.r.camera.Exit()); assert(f.r.camera.Toggle())
        eq(c.controlsHidden, false); eq(c.root:IsShown(), true)
        c.ToggleControls(); f.env.InCombatLockdown = function() return true end
        f.frame.OnEvent(f.frame, "PLAYER_REGEN_DISABLED")
        eq(c.root:IsShown(), false); eq(c.input:IsShown(), false); eq(f.env.UIParent:IsShown(), true)
        local g = make(f.r.db, f.values); eq(g.r.composition.controlsHidden, false)
        eq(g.r.composition.input, nil); eq(#g.calls, 0)
    end)
    test("PHOTO10 clean-view state appears in diagnostics and toolbar fits small displays", function()
        local f = make(); f.env.UIParent:SetSize(600, 400); assert(f.r.camera.Toggle())
        local c = f.r.composition; assert(c.bar:GetWidth() * c.bar.scale <= 576)
        c.ToggleControls(); local report = f.ns.Report.Export(f.r)
        assert(report:find("controlsHidden=yes keyboard=yes", 1, true)); eq(#f.calls, 0); eq(f.captures, 0)
    end)
end
