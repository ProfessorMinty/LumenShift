-- Whole-addon adversarial audit. All native APIs, input and scenes are simulated.
return function(make, eq, test)
    test("F01 supported full library and graphics recovery survive Store.Open", function()
        local f = make()
        for i = 1, 24 do assert(f.r.product.SavePreset("Look " .. i, "nightVision")) end
        f.values.RAIDsettingsEnabled = "1"
        f.apply("normal", 7); f.apply("raid", 4)
        f.r.db.camera.photoEnabled, f.r.db.camera.photoLevel = true, 8
        assert(f.r.camera.Toggle()); f.flush()
        local reopened, why = f.ns.Store.Open(f.r.db)
        assert(reopened, why)
        eq(reopened.config.studio.presets.p24.name, "Look 24")
        eq(reopened.graphics.records.normal.original.farclip, "05432.00")
        eq(reopened.camera.photo.records.normal.original.farclip, f.r.db.camera.photo.records.normal.original.farclip)
    end)
    test("F02 Apply effects button applies edited cosmetics without graphics writes", function()
        local f = make(); assert(f.r.product.Select("nightVision")); f.flush()
        local writes = #f.calls
        assert(f.r.product.Update(function(c) c.studio.modes.nightVision.opacity = 0.11 end))
        f.r.ui.Open(3); f.mock.Click("Apply effects to active mode")
        eq(f.r.presentation.tint.color[4], 0.11); eq(#f.calls, writes)
    end)
    test("F03 wheel preserves chat focus and unrelated held-key releases", function()
        local f = make(); local wheel = f.r.ui.radial; wheel.Toggle()
        local frame = wheel.frame
        eq(frame.SetPropagateKeyboardInputArgs[1], true)
        frame.scripts.OnKeyDown(frame, "TAB")
        eq(frame.SetPropagateKeyboardInputArgs[1], false)
        assert(frame.scripts.OnKeyUp, "wheel needs paired key-up propagation")
        frame.scripts.OnKeyUp(frame, "W")
        eq(frame.SetPropagateKeyboardInputArgs[1], true)
        local chat = f.env.CreateFrame("EditBox", nil, f.env.UIParent); chat:SetFocus()
        frame.scripts.OnKeyDown(frame, "2")
        eq(#f.calls, 0); assert(frame:IsShown())
        eq(frame.SetPropagateKeyboardInputArgs[1], true)
    end)
    test("F04 synchronous Brightness setter cannot reenter the names writer", function()
        local f = make(); f.r.db.config.studio.enabled = true
        local attempted, result, code
        f.setter = function(key, target)
            if not attempted then
                attempted = true
                result, code = f.r.names.Apply("camera", { UnitNameFriendlyPlayerName = 0 })
            end
            return f.native(key, target)
        end
        assert(f.r.engine.Switch(75)); assert(f.r.engine.Verify())
        eq(result, nil); eq(code, "OTHER_OPERATION_ACTIVE")
        eq(#f.calls, 1); eq(f.values.UnitNameFriendlyPlayerName, "1")
    end)
    test("F05 native tier trial cannot reenter a visual preflight", function()
        local f = make(); local get = f.env.C_CVar.GetCVar
        local attempted, result, code
        f.env.C_CVar.GetCVar = function(key)
            if not attempted then
                attempted = true
                result, code = f.r.tierTrial.Test("graphicsShadowQuality", 2)
            end
            return get(key)
        end
        assert(f.r.visual.Apply({ Brightness = 75, Contrast = 65 })); f.flush()
        eq(result, nil); eq(code, "OTHER_OPERATION_ACTIVE")
        for _, call in ipairs(f.calls) do assert(call[1] == "Brightness" or call[1] == "Contrast") end
    end)
    test("F06 every controller rejects cross-controller preflight and setter reentry", function()
        local actions = {
            brightness = function(f) return f.r.engine.Switch(75) end,
            visual = function(f) return f.r.visual.Apply({ Brightness = 75, Contrast = 65 }) end,
            detail = function(f) return f.r.lab.Apply("quality", { ResampleAlwaysSharpen = 1 }) end,
            names = function(f) return f.r.names.Apply("camera", { UnitNameFriendlyPlayerName = 0 }) end,
            framing = function(f) return f.r.framing.Apply("camera", { cameraFov = 80 }) end,
            graphics = function(f) return f.r.graphics.Apply(f.choice("normal", 7)) end,
            photo = function(f) return f.r.photo.Apply(f.choice("normal", 7)) end,
            tier = function(f) return f.r.tierTrial.Test("graphicsShadowQuality", 2) end,
        }
        for outer, apply in pairs(actions) do
            for inner, nested in pairs(actions) do
                if outer ~= inner then
                    for _, stage in ipairs({ "read", "setter" }) do
                        local f = make(); f.values.ResampleAlwaysSharpen = "0"; f.r.db.config.studio.enabled = true
                        local attempted, result, code
                        local function enter()
                            if not attempted then
                                attempted = true
                                local count = #f.calls
                                result, code = nested(f)
                                eq(#f.calls, count)
                            end
                        end
                        if stage == "read" then
                            local get = f.env.C_CVar.GetCVar
                            f.env.C_CVar.GetCVar = function(key) enter(); return get(key) end
                        else f.setter = function(key, target) enter(); return f.native(key, target) end end
                        local ok, reason = apply(f)
                        local label = outer .. " -> " .. inner .. " during " .. stage
                        assert(attempted, label .. " hook not reached: " .. tostring(reason))
                        assert(not result, label .. " nested operation accepted")
                        assert(type(code) == "string" and #code > 0, label .. " needs an explicit refusal")
                        assert(ok, label .. " outer operation failed: " .. tostring(reason))
                        if outer == "brightness" then assert(f.r.engine.Verify()) else f.flush() end
                    end
                end
            end
        end
    end)
    test("F07 already matching native recipes neither write nor acquire recovery ownership", function()
        for _, controller in ipairs({ "graphics", "photo" }) do
            local f = make(); local choice = f.choice("normal", 7)
            local recipe = assert(f.ns.NativeGraphics.Recipe(f.r.reader, "normal", choice.normal))
            for key, value in pairs(recipe) do f.values[key] = tostring(value) end
            local completed = 0
            assert(f.r[controller].Apply(choice, function(ok) assert(ok); completed = completed + 1 end))
            f.flush(); eq(completed, 1); eq(#f.calls, 0)
            local data = controller == "photo" and f.r.db.camera.photo or f.r.db.graphics
            eq(next(data.records), nil); eq(f.r[controller].Status().state, "IDLE")
        end
    end)
    test("F08 no-change recipes preserve existing originals and complete multi-bank callbacks", function()
        local f = make(); f.apply("normal", 7)
        local record, count = f.r.db.graphics.records.normal, #f.calls
        f.apply("normal", 7); eq(f.r.db.graphics.records.normal, record); eq(#f.calls, count)
        eq(record.original.farclip, "05432.00")
        assert(f.r.graphics.Restore("normal")); f.flush(); eq(f.values.farclip, "05432.00")
        local g = make(); local choice = g.choice("normal", 7)
        for key, value in pairs(assert(g.ns.NativeGraphics.Recipe(g.r.reader, "normal", choice.normal))) do
            g.values[key] = tostring(value)
        end
        choice.raid = { source = "level", level = 4 }
        local completed = 0
        assert(g.r.graphics.Apply(choice, function(ok) assert(ok); completed = completed + 1 end)); g.flush()
        eq(completed, 1); eq(g.r.db.graphics.records.normal, nil); assert(g.r.db.graphics.records.raid)
        for _, call in ipairs(g.calls) do eq(g.ns.NativeGraphics.Definition(call[1]).bank, "raid") end
    end)
    test("F09 camera recovery exports survive reload without relying on session history", function()
        local f = make()
        f.setter = function(key, target) f.values[key] = target; return false end
        eq(f.r.camera.ApplyFOV(80), nil); f.flush()
        local g = make(f.r.db, f.values)
        local report = g.ns.Report.Export(g.r)
        assert(report:find("Framing: state=RECOVERY", 1, true))
        assert(report:find("recovery cameraFov original=090.00", 1, true))
        eq(#g.calls, 0)
        local h = make(); h.r.db.camera.photoEnabled = true
        h.setter = function(key, target) h.values.Brightness = "58"; return h.native(key, target) end
        h.r.camera.Toggle(); h.flush(); assert(h.r.db.camera.photo.sideEffects.Brightness)
        local j = make(h.r.db, h.values); report = j.ns.Report.Export(j.r)
        assert(report:find("PhotoGraphics: state=RECOVERY", 1, true))
        assert(report:find("photo graphics normal state=failed", 1, true))
        assert(report:find("error=OTHER_BANK_OR_VISUAL_CHANGED", 1, true))
        assert(report:find("photo-graphics watched change Brightness before=52 after=58", 1, true))
        eq(#j.calls, 0)
    end)
    test("F10 wheel shortcut failures preserve mouse access and close consumes no game action", function()
        local f = make(); local wheel = f.r.ui.radial
        wheel.Toggle(); wheel.frame.scripts.OnKeyDown(wheel.frame, "ESCAPE")
        eq(wheel.frame:IsShown(), false); eq(#f.calls, 0)
        wheel.Toggle(); wheel.frame.scripts.OnKeyDown(wheel.frame, "2"); f.flush()
        eq(f.r.product.active, "nightVision"); eq(wheel.frame:IsShown(), false)
        local g = make(); g.env.GetCurrentKeyBoardFocus = nil
        g.r.ui.radial.Toggle(); local frame = g.r.ui.radial.frame
        frame.scripts.OnKeyDown(frame, "W")
        eq(frame:IsShown(), true); eq(frame.EnableKeyboardArgs[1], false)
        eq(frame.scripts.OnKeyDown, nil); eq(#g.calls, 0)
    end)
end
