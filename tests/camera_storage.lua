-- Server-stored friendly-name preferences are not secure/read-only CVars.
-- All native values, flags, setters and visibility here are simulated.
return function(make, eq, test)
    local player, pet = "UnitNameFriendlyPlayerName", "UnitNameFriendlyPetName"
    local function setup(saved, values)
        local f = make(saved, values or { [player] = "1", [pet] = "1", Brightness = "45", Contrast = "60" })
        f.r.db.camera.hideWithUI = true
        f.flags = { [player] = { false, true, false, false, false }, [pet] = { false, true, false, false, false } }
        local info = f.env.C_CVar.GetCVarInfo
        f.env.C_CVar.GetCVarInfo = function(key)
            if f.flags[key] then
                local flags = f.flags[key]
                return f.values[key], "1", flags[1], flags[2], flags[3], flags[4], flags[5]
            end
            return info(key)
        end
        return f
    end
    test("CS01 beta7-style Camera refusal with server-stored pet names now enters and exits", function()
        local f = setup(); f.flags[player][2] = false
        f.r.ui.Wheel(); f.mock.Click("Camera"); f.flush()
        eq(f.r.camera.active, true); eq(f.env.UIParent:IsShown(), false)
        eq(f.values[player], "0"); eq(f.values[pet], "0")
        f.mock.Click("Exit Camera Mode"); f.flush()
        eq(f.env.UIParent:IsShown(), true); eq(f.values[player], "1"); eq(f.values[pet], "1")
        eq(next(f.r.db.camera.journal.entries), nil); eq(f.r.db.camera.nameReturn, nil); eq(#f.calls, 4)
    end)
    test("CS02 account character and combined storage flags keep exact independent originals", function()
        for _, storage in ipairs({ { true, false }, { false, true }, { true, true } }) do
            local f = setup(nil, { [player] = "01.00", [pet] = "0.00" })
            for _, key in ipairs({ player, pet }) do f.flags[key][1], f.flags[key][2] = storage[1], storage[2] end
            assert(f.r.camera.Toggle()); f.flush(); eq(f.values[player], "0"); eq(f.values[pet], "0.00")
            f.r.names.Observe(); eq(f.r.names.Status().state, "ACTIVE")
            assert(f.r.camera.Exit()); f.flush()
            eq(f.values[player], "01.00"); eq(f.values[pet], "0.00"); eq(#f.calls, 2)
        end
    end)
    test("CS03 server-stored name recovery survives reload without automatic writes or HUD hiding", function()
        local f = setup(); assert(f.r.camera.Toggle()); f.flush()
        local g = setup(f.r.db, f.values); eq(#g.calls, 0); eq(g.env.UIParent:IsShown(), true)
        g.frame.OnEvent(g.frame, "PLAYER_ENTERING_WORLD"); g.flush(); eq(#g.calls, 0)
        assert(g.r.camera.RestoreNames()); g.flush()
        eq(g.values[player], "1"); eq(g.values[pet], "1"); eq(g.r.db.camera.nameReturn, nil)
        eq(next(g.r.db.camera.journal.entries), nil)
    end)
    test("CS04 external name changes remain preserved on exit with server storage", function()
        local f = setup(); assert(f.r.camera.Toggle()); f.flush()
        f.values[player] = "1"; f.r.names.Observe(); local calls = #f.calls
        eq(f.r.camera.Exit(), nil); f.flush(); eq(f.env.UIParent:IsShown(), true)
        eq(#f.calls, calls); eq(f.values[player], "1"); eq(f.values[pet], "0")
        assert(f.r.db.camera.journal.entries[pet]); assert(f.r.db.camera.nameReturn)
    end)
    test("CS05 second setter failure compensates server-stored names without hiding HUD", function()
        local f = setup()
        f.setter = function(key, target, count)
            if count == 2 then return false end
            f.values[key] = target; return true
        end
        assert(f.r.camera.Toggle()); f.flush()
        eq(f.env.UIParent:IsShown(), true); eq(f.r.camera.active, false)
        eq(f.values[player], "1"); eq(f.values[pet], "1"); eq(#f.calls, 3)
        eq(next(f.r.db.camera.journal.entries), nil)
        assert(f.r.camera.RestoreNames()); eq(f.r.db.camera.nameReturn, nil)
    end)
    test("CS06 real restrictions unknown flags unavailable reads and invalid values still refuse", function()
        for _, fault in ipairs({ "secure", "locked", "readOnly", "unknownStorage", "unavailable", "invalid" }) do
            local f = setup()
            if fault == "secure" then f.flags[pet][4] = true
            elseif fault == "locked" then f.flags[pet][3] = true
            elseif fault == "readOnly" then f.flags[pet][5] = true
            elseif fault == "unknownStorage" then f.flags[pet][2] = nil
            elseif fault == "unavailable" then f.values[pet] = nil
            else f.values[pet] = "2" end
            eq(f.r.camera.Toggle(), nil); f.flush()
            eq(#f.calls, 0); eq(f.env.UIParent:IsShown(), true); eq(f.r.db.camera.nameReturn, nil)
        end
    end)
    test("CS07 new restrictions after a setter retain recovery instead of unsafe compensation", function()
        local f = setup()
        f.setter = function(key, target)
            f.values[key] = target; f.flags[key][4] = true; return true
        end
        local ok, code = f.r.camera.Toggle(); eq(ok, nil); eq(code, "COMPENSATION_FAILED"); f.flush()
        eq(f.env.UIParent:IsShown(), true); eq(f.r.camera.active, false); eq(#f.calls, 1)
        assert(next(f.r.db.camera.journal.entries)); assert(f.r.db.camera.nameReturn)
    end)
    test("CS08 report distinguishes name storage flags from restrictions and includes Camera error", function()
        local f = setup(); local report = f.ns.Report.Export(f.r)
        assert(report:find("serverAccount=no serverCharacter=yes flags=OK nameCheck=OK", 1, true))
        assert(report:find("name-preflight-" .. pet, 1, true)); eq(#f.calls, 0)
        f.flags[pet][4] = true; eq(f.r.camera.Toggle(), nil)
        report = f.ns.Report.Export(f.r)
        assert(report:find("nameCheck=SECURE_CVAR", 1, true)); assert(report:find("lastError=UNSAFE_OBSERVATION:" .. pet, 1, true))
        eq(#f.calls, 0)
    end)
    test("CS09 allowing name storage does not admit server-stored graphics or unknown metadata", function()
        local f = setup(); local item = f.ns.ReadOnly.Read(f.r.reader, pet)
        eq(f.ns.Planner.SafeObservation(item, pet), true)
        eq(f.ns.Planner.SafeObservation(item), false)
        for _, key in ipairs({ "Brightness", "Contrast", "farclip", "cameraFov", "unknown" }) do
            eq(f.ns.Planner.SafeObservation(item, key), false)
        end
        item.flags.serverCharacter = nil; eq(f.ns.Planner.SafeObservation(item, pet), false)
        eq(#f.calls, 0)
    end)
    test("CS10 Camera works over active Cinematic without touching its brightness or original", function()
        local f = setup(); assert(f.r.product.Select("cinematic")); f.flush()
        eq(f.values.Brightness, "42"); local original = f.r.db.journal.entries.Brightness.originalRaw
        f.r.ui.Wheel(); f.r.ui.radial.frame.scripts.OnKeyDown(f.r.ui.radial.frame, "7"); f.flush()
        eq(f.r.camera.active, true); assert(f.r.camera.Exit()); f.flush()
        eq(f.values.Brightness, "42"); eq(f.r.product.active, "cinematic")
        eq(f.r.db.journal.entries.Brightness.originalRaw, original); eq(#f.calls, 5)
    end)
    test("CS11 manual names preference stays independent across Camera entry and exit", function()
        local f = setup(); assert(f.r.camera.ToggleNames()); f.flush()
        eq(f.values[player], "0"); eq(f.values[pet], "0"); eq(f.env.UIParent:IsShown(), true)
        assert(f.r.camera.Toggle()); f.flush(); eq(f.r.camera.active, true)
        assert(f.r.camera.Exit()); f.flush()
        eq(f.values[player], "0"); eq(f.values[pet], "0"); eq(#f.calls, 2)
        eq(f.r.db.camera.nameReturn, nil); assert(next(f.r.db.camera.journal.entries))
        assert(f.r.camera.ToggleNames()); f.flush()
        eq(f.values[player], "1"); eq(f.values[pet], "1"); eq(#f.calls, 4)
        eq(next(f.r.db.camera.journal.entries), nil)
    end)
end
