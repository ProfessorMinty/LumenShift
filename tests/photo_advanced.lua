-- Simulated standalone Delivery B. Native rendering, collision and input remain manual QA.
return function(cameraFixture, eq, test)
    local function make()
        local f = cameraFixture()
        local values = { test_cameraOverShoulder = "0.00", test_cameraDynamicPitch = "0", test_cameraDynamicPitchBaseFovPad = "0.35",
            CameraKeepCharacterCentered = "0", CameraReduceUnexpectedMovement = "0", ffxAntiAliasingMode = "0", MSAAQuality = "0,0",
            MSAAAlphaTest = "0", screenshotQuality = "08", screenshotFormat = "jpeg", shadowRt = "0" }
        for k, v in pairs(values) do f.values[k] = v end
        f.env.AntiAliasingSupported = function() return true, false, true end
        f.env.MultiSampleAntiAliasingSupported = function() return 1, 2, 0, 2, 4, 0, 3, 8, 0 end
        f.env.IsMacClient = function() return false end
        f.env.C_VideoOptions.IsSecondaryLightingSupported = function() return false end
        f.zoom, f.moves, f.starts, f.stops = 12.5, 0, 0, 0
        f.env.GetCameraZoom = function() return f.zoom end
        f.env.CameraZoomIn = function(n) f.moves = f.moves + 1; f.zoom = f.zoom - n end
        f.env.CameraZoomOut = function(n) f.moves = f.moves + 1; f.zoom = f.zoom + n end
        f.env.MoveViewLeftStart = function() f.starts = f.starts + 1 end
        f.env.MoveViewRightStart = f.env.MoveViewLeftStart
        f.env.MoveViewLeftStop = function() f.stops = f.stops + 1 end
        f.env.MoveViewRightStop = f.env.MoveViewLeftStop
        assert(f.r.camera.Toggle()); f.flush(); eq(f.env.Narci, nil); eq(f.env.NarciScreenshotToolbar, nil)
        f.a, f.o, f.c, f.ui = f.r.cameraActions, f.r.output, f.r.composition, f.r.composition.editor
        return f
    end
    local function aa() return { ffxAntiAliasingMode = "4", MSAAQuality = "2", MSAAAlphaTest = "1" } end
    test("PB01 Phase A tab change closes one look gesture and late screenshot cannot reopen departed world", function()
        local f = make(); local e = f.r.photoEditor
        e.BeginLookEdit(); e.Set("warmth", .4); f.ui.tab = "Frame"; f.ui.Build(); eq(#e.undo, 1)
        assert(e.Undo()); eq(f.r.db.camera.editor.look.warmth, 0)
        assert(f.c.Capture()); f.tick(); eq(f.captures, 1)
        f.frame.OnEvent(f.frame, "PLAYER_LEAVING_WORLD")
        f.c.root.scripts.OnEvent(f.c.root, "SCREENSHOT_SUCCEEDED"); f.flush(); eq(f.c.root:IsShown(), false)
    end)
    test("PB02 all standalone tabs and new light recipes load without startup CVar writes", function()
        local f = make()
        for _, tab in ipairs({ "Look", "Light", "Frame", "Pose", "Capture", "Saved" }) do f.ui.tab = tab; f.ui.Build(true) end
        assert(f.r.photoEditor.Recipe("sunflare")); assert(f.r.photoEditor.Recipe("bluehour"))
        eq(#f.calls, 0); eq(f.r.lastError, nil); assert(f.r.camera.Exit()); f.flush(); eq(#f.calls, 0)
    end)
    test("PB03 schema 14 photo looks migrate losslessly and legacy transfers gain neutral edge light", function()
        local f = make(); local data = f.ns.Value.Copy(f.r.db); data.schemaVersion = 14; data.camera.editor.version = 1
        data.camera.editor.look.leak, data.camera.editor.look.leakSide, data.camera.editor.look.leakWidth = nil, nil, nil
        data.camera.editor.saved.Old = f.ns.Value.Copy(data.camera.editor.look); data.camera.output, data.camera.composition = nil, nil
        local updated, code = f.ns.Store.Open(data); eq(code, "MIGRATED_14_TO_16"); eq(updated.camera.editor.saved.Old.leak, 0)
        eq(data.camera.editor.look.leak, nil); eq(updated.camera.editor.look.warmth, data.camera.editor.look.warmth)
        local exported = f.ns.PhotoConfig.Export(updated.camera.editor.look)
        local old = exported:gsub("LSPHOTO2", "LSPHOTO1"):gsub(";[^;]*;[^;]*;[^;]*$", "")
        eq(f.ns.PhotoConfig.Import(old).leak, 0); eq(f.ns.PhotoConfig.Import(exported).leakWidth, .4)
        eq(f.ns.PhotoConfig.Import(exported .. ";0"), nil)
    end)
    test("PB04 new framing preserves FOV and restores exact originals together", function()
        local f = make(); assert(f.r.camera.ApplyFOV(75)); f.flush()
        assert(f.r.camera.ApplyFraming({ test_cameraOverShoulder = 1.2, test_cameraDynamicPitch = 1, test_cameraDynamicPitchBaseFovPad = .5 })); f.flush()
        eq(f.values.cameraFov, "75"); eq(f.values.test_cameraOverShoulder, "1.2")
        assert(f.r.camera.RestoreFOV()); f.flush(); eq(f.values.cameraFov, "090.00"); eq(f.values.test_cameraOverShoulder, "1.2")
        assert(f.r.camera.Exit()); f.flush(); eq(f.values.test_cameraOverShoulder, "0.00"); eq(f.values.test_cameraDynamicPitchBaseFovPad, "0.35")
    end)
    test("PB05 comfort restrictions missing metadata and external changes stay local to framing", function()
        local f = make(); f.values.CameraKeepCharacterCentered = "1"
        eq(f.r.camera.ApplyFraming({ test_cameraOverShoulder = 1 }), nil); eq(#f.calls, 0)
        assert(f.r.camera.ApplyFOV(80)); f.flush(); f.values.CameraKeepCharacterCentered = "0"
        assert(f.r.camera.ApplyFraming({ test_cameraOverShoulder = 1 })); f.flush(); f.values.test_cameraOverShoulder = "2"
        local calls = #f.calls; eq(f.r.camera.RestoreFraming(), nil); eq(#f.calls, calls)
        assert(f.r.photoEditor.Recipe("ember")); eq(f.values.test_cameraOverShoulder, "2")
    end)
    test("PB06 zoom captures distance returns after exit and never writes CVars or view slots", function()
        local f = make(); assert(f.a.Zoom(8)); eq(f.r.db.camera.composition.zoom.original, 12.5); f.flush()
        eq(f.zoom, 8); assert(f.r.camera.Exit()); f.flush(); eq(f.zoom, 12.5)
        eq(f.r.db.camera.composition.zoom, nil); eq(#f.calls, 0); eq(f.moves, 2)
    end)
    test("PB07 native zoom clamp reports actual and external movement is kept on exit", function()
        local f = make(); f.env.CameraZoomIn = function() f.zoom = 10 end
        assert(f.a.Zoom(8)); f.flush(); eq(f.r.db.camera.composition.zoom.expected, 10); assert(f.a.status:find("limited"))
        f.zoom = 11; local moves = f.moves; f.r.camera.Exit(); f.flush(); eq(f.zoom, 11); eq(f.moves, moves)
        eq(f.r.db.camera.composition.zoom.original, 12.5)
    end)
    test("PB08 exiting during zoom waits for readback then returns once, interrupted zoom never reapplies", function()
        local f = make(); assert(f.a.Zoom(8)); assert(f.r.camera.Exit()); f.flush(); eq(f.zoom, 12.5); eq(f.r.camera.busy, false)
        local g = make(); assert(g.a.Zoom(8)); g.a.Cancel(); g.flush(); eq(g.r.db.camera.composition.zoom.state, "failed")
        eq(g.a.Restore(), nil); eq(g.moves, 1)
    end)
    test("PB09 zoom handles missing API throws read failures and original beyond UI range", function()
        local f = make(); f.env.CameraZoomIn = nil; eq(f.a.Zoom(8), nil); eq(f.r.db.camera.composition.zoom, nil)
        f.env.CameraZoomIn = function() error("native") end; eq(f.a.Zoom(8), nil); eq(f.r.db.camera.composition.zoom.state, "failed")
        local g = make(); g.zoom = 60; assert(g.a.Zoom(40)); g.flush(); assert(g.a.Restore()); eq(g.r.db.camera.composition.zoom.requested, 60); assert(g.ns.PhotoComposition.Validate(g.r.db.camera.composition)); g.flush(); eq(g.zoom, 60)
        local h = make(); assert(h.a.Zoom(8)); h.env.GetCameraZoom = function() error("private") end; h.flush()
        eq(h.a.busy, false); eq(h.r.db.camera.composition.zoom.state, "failed")
    end)
    test("PB10 held orbit stops on release hide exit combat world leave timeout and reset", function()
        for _, method in ipairs({ "release", "hide", "exit", "combat", "leave", "timeout", "reset" }) do
            local f = make(); assert(f.a.Orbit("left")); eq(f.starts, 1)
            if method == "release" then f.a.StopOrbit()
            elseif method == "hide" then f.c.ToggleControls()
            elseif method == "exit" then f.r.camera.Exit()
            elseif method == "combat" then f.env.InCombatLockdown = function() return true end; f.r.camera.Combat()
            elseif method == "leave" then f.frame.OnEvent(f.frame, "PLAYER_LEAVING_WORLD")
            elseif method == "reset" then f.r.reset.Open(); f.r.reset.Confirm() end
            f.flush(); eq(f.stops, 1); eq(f.a.orbit, nil); eq(#f.calls, 0)
        end
    end)
    test("PB11 orbit needs both functions and timer, honors reduced motion, retains failed stop", function()
        local f = make(); f.env.MoveViewLeftStop = nil; eq(f.a.Orbit("left"), nil); eq(f.starts, 0)
        f.r.db.config.preferences.reducedMotion = true; eq(f.a.Orbit("right"), nil)
        f.r.db.config.preferences.reducedMotion = false; f.env.MoveViewRightStop = function() error("stop") end
        assert(f.a.Orbit("right")); eq(f.a.StopOrbit(), nil); assert(f.a.orbitStop); f.flush(); eq(f.a.status, "CAMERA_STOP_FAILED")
    end)
    test("PB12 AA captures the entire dependency group and returns exact tuple strings", function()
        local f = make(); assert(f.o.Apply("aa", aa())); f.flush()
        local r = f.r.db.camera.output.records.aa; eq(r.original.MSAAQuality, "0,0"); eq(r.state, "owned")
        eq(f.values.MSAAQuality, "2"); assert(f.r.camera.Exit()); f.flush(); eq(f.values.MSAAQuality, "0,0"); eq(f.values.ffxAntiAliasingMode, "0")
        eq(f.r.db.camera.output.records.aa, nil)
    end)
    test("PB13 AA rejects unenumerated alpha renderer invalid tuples and restricted members before writes", function()
        for _, problem in ipairs({ "option", "alpha", "tuple", "secure" }) do
            local f = make(); local t = aa()
            if problem == "option" then t.ffxAntiAliasingMode = "3"
            elseif problem == "alpha" then f.env.IsGraphicsSettingValueSupported = function() return 12 end
            elseif problem == "tuple" then f.values.MSAAQuality = "2,NaN"
            else f.restricted = "MSAAQuality" end
            eq(f.o.Apply("aa", t), nil); eq(#f.calls, 0); eq(f.r.db.camera.output.records.aa, nil)
        end
    end)
    test("PB14 setter failure rolls back bounded changes without losing the original", function()
        local f = make(); f.setter = function(key, value, n) f.values[key] = value; return n ~= 2 end
        f.o.Apply("aa", aa()); f.flush(); eq(f.values.ffxAntiAliasingMode, "0"); eq(f.values.MSAAQuality, "0,0")
        eq(f.r.db.camera.output.records.aa, nil); eq(f.o.state, "RECOVERY")
    end)
    test("PB15 changed dependent AA members are preserved with recovery, never compensated over", function()
        local f = make(); f.setter = function(key, value) f.values[key] = value; f.values.MSAAQuality = "3"; return true end
        eq(f.o.Apply("aa", aa()), false); eq(#f.calls, 1); eq(f.values.MSAAQuality, "3")
        eq(f.r.db.camera.output.records.aa.original.MSAAQuality, "0,0"); eq(f.o.Restore("aa"), nil); eq(#f.calls, 1)
    end)
    test("PB16 AA external and delayed conflicts preserve all recovery information", function()
        local f = make(); assert(f.o.Apply("aa", aa())); f.values.MSAAQuality = "3"; f.flush()
        eq(f.o.state, "RECOVERY"); eq(f.r.db.camera.output.records.aa.state, "conflict"); local n = #f.calls
        eq(f.o.Restore("aa"), nil); eq(#f.calls, n)
        local g = make(); assert(g.o.Apply("aa", aa())); g.flush(); g.values.MSAAAlphaTest = "0"; g.o.Observe()
        eq(g.r.db.camera.output.records.aa.state, "conflict")
    end)
    test("PB17 output serializes all graphics writers and exit waits for verification", function()
        local f = make(); assert(f.o.Apply("aa", aa())); eq(f.r.camera.ApplyFOV(80), nil)
        eq(f.r.camera.Exit(), nil); f.flush(); eq(f.r.camera.active, false); eq(f.values.MSAAQuality, "0,0")
        local g = make(); assert(g.r.camera.ApplyFOV(80)); eq(g.o.Apply("aa", aa()), nil); g.flush()
    end)
    test("PB18 missing timer and callback errors retain recovery without permanent busy", function()
        local f = make(); f.env.C_Timer.After = function() error("timer") end; eq(f.o.Apply("aa", aa()), false)
        eq(f.o.busy, false); eq(f.r.db.camera.output.records.aa.original.MSAAQuality, "0,0")
        local g = make(); assert(g.o.Apply("aa", aa(), function() error("callback") end)); g.flush(); eq(g.o.busy, false)
        eq(g.o.error, "OUTPUT_HANDLER_ERROR"); assert(g.o.Restore("aa")); g.flush(); eq(g.values.MSAAQuality, "0,0")
    end)
    test("PB19 JPEG quality is explicit format aware bounded and exactly restored", function()
        local f = make(); eq(f.o.Apply("jpeg", { screenshotQuality = "11" }), nil); eq(#f.calls, 0)
        assert(f.o.Apply("jpeg", { screenshotQuality = "10" })); f.flush(); eq(f.values.screenshotQuality, "10")
        assert(f.r.camera.Exit()); f.flush(); eq(f.values.screenshotQuality, "08")
        local g = make(); g.values.screenshotFormat = "tga"; eq(g.o.Apply("jpeg", { screenshotQuality = "10" }), nil); eq(#g.calls, 0)
    end)
    test("PB20 ray shadows use photo-bank original and renderer validation", function()
        local f = make(); assert(f.r.photo.ApplyRay(3)); f.flush(); eq(f.values.shadowRt, "3")
        eq(f.r.db.camera.photo.records.normal.original.shadowRt, "0"); eq(next(f.r.db.graphics.records), nil)
        assert(f.r.photo.ApplyRay(1)); f.flush(); eq(f.r.db.camera.photo.records.normal.original.shadowRt, "0")
        assert(f.r.camera.Exit()); f.flush(); eq(f.values.shadowRt, "0")
        local g = make(); g.env.IsGraphicsSettingValueSupported = function() return 12 end
        eq(g.r.photo.ApplyRay(3), nil); eq(#g.calls, 0)
        g.env.C_VideoOptions.IsSecondaryLightingSupported = function() return true end; eq(g.r.photo.ApplyRay(0), nil)
    end)
    test("PB21 composition saves read-only separately from looks and explicit Apply uses native controllers", function()
        local f = make(); local p = f.r.photoComposition
        assert(p.Save("Campfire")); eq(#f.calls, 0)
        assert(f.r.photoEditor.Recipe("ember")); assert(f.r.photoEditor.Save("Look")); assert(f.r.photoEditor.Load("Look")); eq(#f.calls, 0)
        f.values.cameraFov = "80"; f.zoom = 16
        assert(p.Apply("Campfire")); f.flush(); eq(f.values.cameraFov, "90"); eq(f.zoom, 12.5); eq(p.busy, false)
        assert(f.r.camera.Exit()); f.flush(); eq(f.values.cameraFov, "80"); eq(f.zoom, 16)
    end)
    test("PB22 saved composition validates fields, caps storage, and exit cancels queued movement", function()
        local f = make(); local p = f.r.photoComposition
        for i = 1, 8 do assert(p.Save("View" .. i)) end
        eq(p.Save("Ninth"), nil); assert(p.Delete("View8")); assert(p.Save("Ninth"))
        f.r.db.camera.composition.saved.Bad = { thirds = true, aspect = "none", framing = { arbitrary = 1 } }
        eq(p.Apply("Bad"), nil); f.r.db.camera.composition.saved.Bad = nil
        f.values.cameraFov = "80"; assert(p.Apply("View1")); f.r.camera.Exit(); f.flush(); eq(f.moves, 0); eq(p.busy, false)
    end)
    test("PB23 reload preserves pending output originals but never automatically applies or restores", function()
        local f = make(); assert(f.o.Apply("aa", aa())); local saved = f.ns.Value.Copy(f.r.db)
        local g = cameraFixture(saved, f.values); eq(#g.calls, 0); eq(g.r.output.state, "RECOVERY")
        eq(g.r.db.camera.output.records.aa.original.MSAAQuality, "0,0")
    end)
    test("PB24 camera controls reject capture overlap and no-change output avoids ownership", function()
        local f = make(); assert(f.o.Apply("aa", { ffxAntiAliasingMode = "0", MSAAQuality = "0", MSAAAlphaTest = "0" }))
        eq(#f.calls, 0); eq(f.r.db.camera.output.records.aa, nil)
        assert(f.r.captureSequence.Start()); eq(f.a.Zoom(8), nil); eq(f.a.Orbit("left"), nil); eq(f.o.Apply("aa", aa()), nil)
        f.r.captureSequence.Cancel(); f.flush(); eq(f.captures, 0)
    end)
    test("PB25 visible framing toggle and held orbit are wired to native actions without rebuilding the hold", function()
        local f = make(); f.ui.tab = "Frame"; f.ui.Build()
        f.mock.Click("Dynamic framing"); f.flush(); eq(f.values.test_cameraDynamicPitch, "1")
        local button
        for _, b in ipairs(f.mock.nodes) do if b.kind == "Button" and b.label and b.label.text == "Hold orbit left" and b:IsVisible() then button = b end end
        assert(button); button.scripts.OnMouseDown(button, "LeftButton"); eq(f.starts, 1); eq(f.stops, 0)
        button.scripts.OnMouseUp(button, "LeftButton"); eq(f.stops, 1); f.flush()
        f.mock.Click("Restore all framing"); f.flush(); eq(f.values.test_cameraDynamicPitch, "0")
        assert(f.r.photoPreview.Queue("cameraFov", 80)); f.flush(); eq(f.ui.sliders.cameraFov:GetValue(), 80)
        f.mock.Click("Restore field of view"); f.flush(); eq(f.ui.sliders.cameraFov:GetValue(), 90)
        f.mock.Click("Look"); eq(f.ui.tab, "Look")
    end)
    test("PB26 changed renderer stops a later AA step and failed compensation keeps originals", function()
        local f = make(); f.setter = function(key, value, n)
            f.values[key] = value
            if n == 1 then f.env.IsGraphicsSettingValueSupported = function() return 12 end end
            return true
        end
        f.o.Apply("aa", aa()); f.flush(); eq(#f.calls, 1); eq(f.o.busy, false)
        eq(f.r.db.camera.output.records.aa.original.ffxAntiAliasingMode, "0"); eq(f.r.db.camera.output.records.aa.state, "failed")
        local g = make(); g.setter = function(key, value) g.values[key] = value; return false end
        g.o.Apply("aa", aa()); g.flush(); eq(g.o.busy, false); eq(g.r.db.camera.output.records.aa.original.MSAAQuality, "0,0")
    end)
    test("PB27 report includes new recovery fields but no composition names or foreign private data", function()
        local f = make(); assert(f.r.photoComposition.Save("private scene name")); assert(f.o.Apply("aa", aa())); f.flush()
        assert(f.a.Zoom(10)); f.flush(); local report = f.ns.Report.Export(f.r)
        assert(report:find("Photo movement: zoom=10", 1, true)); assert(report:find("photo output MSAAQuality current=2,0 original=0,0", 1, true))
        assert(not report:find("private scene name", 1, true)); assert(report:find("test_cameraOverShoulder", 1, true))
    end)

    test("PB28 saved composition follow-up cannot show controls or move the camera after world leave", function()
        local queued = make(); assert(queued.r.photoPreview.Queue("test_cameraOverShoulder", 1))
        queued.frame.OnEvent(queued.frame, "PLAYER_LEAVING_WORLD"); queued.flush(); eq(#queued.calls, 0)
        eq(queued.a.Zoom(8), nil)
        for _, stage in ipairs({ "duringVerify", "afterVerify" }) do
            local f = make(); assert(f.r.photoComposition.Save("View")); f.values.cameraFov, f.zoom = "80", 16
            assert(f.r.photoComposition.Apply("View"))
            if stage == "afterVerify" then f.tick() end
            f.frame.OnEvent(f.frame, "PLAYER_LEAVING_WORLD"); f.flush()
            eq(f.c.root:IsShown(), false); eq(f.c.input:IsShown(), false); eq(f.moves, 0)
            eq(f.r.photoComposition.busy, false); eq(f.r.photoComposition.status, "CANCELLED")
        end
    end)

end
