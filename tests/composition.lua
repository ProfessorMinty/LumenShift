-- Simulated camera/FPS behavior; no game, GPU, screenshot or scene was measured.
return function(nativeFixture, eq, test)
    local player, pet = "UnitNameFriendlyPlayerName", "UnitNameFriendlyPetName"
    local function make(saved, values)
        local f = nativeFixture(saved, values)
        f.values.cameraFov = values and values.cameraFov or "090.00"
        f.values[player], f.values[pet] = values and values[player] or "1", values and values[pet] or "0"
        f.env.GetCameraFOVDefaults = function() return 90, 60, 100 end
        f.env.SetUIVisibility = function(shown) if shown then f.env.UIParent:Show() else f.env.UIParent:Hide() end end
        f.r.db.camera.hideWithUI = false
        f.clock, f.fps, f.captures = 100, 60, 0
        f.env.GetTime = function() return f.clock end
        f.env.GetFramerate = function() return f.fps end
        f.env.Screenshot = function()
            eq(f.r.composition.root:IsShown(), false)
            f.captures = f.captures + 1
        end
        function f.tick()
            local nextTimer = table.remove(f.mock.timers, 1); assert(nextTimer, "timer expected")
            f.clock = f.clock + nextTimer[1]; nextTimer[2]()
        end
        function f.flush() local guard = 0; while #f.mock.timers > 0 do guard = guard + 1; assert(guard < 40); f.tick() end end
        return f
    end
    test("CAM01 camera preferences migrate without writes, losing completion or old originals", function()
        local f = make(); local old = f.ns.Value.Copy(f.r.db)
        old.schemaVersion, old.camera.thirds, old.camera.aspect, old.camera.photoEnabled, old.camera.photoLevel = 10, nil, nil, nil, nil
        old.camera.framing, old.camera.photo = nil, nil; old.onboarding.completed = true
        local copy, code = f.ns.Store.Open(old); eq(code, "MIGRATED_10_TO_11"); eq(copy.onboarding.completed, true)
        eq(copy.camera.photoEnabled, false); eq(copy.camera.aspect, "none"); eq(old.camera.photo, nil)
        f.r.ui.Open(9); f.ns.Report.Export(f.r); eq(#f.calls, 0); eq(f.captures, 0)
        copy.camera.photo.records.unknown = {}; eq(f.ns.Store.Open(copy), nil)
    end)
    test("CAM02 FOV uses dynamic native bounds, captures exact originals and restores on exit", function()
        local f = make(); assert(f.r.camera.ApplyFOV(76.5)); f.flush(); eq(f.values.cameraFov, "76.5")
        eq(f.r.db.camera.framing.journal.entries.cameraFov.originalRaw, "090.00")
        assert(f.r.camera.Toggle()); eq(f.r.camera.active, true); assert(f.r.camera.Exit()); f.flush()
        eq(f.values.cameraFov, "090.00"); eq(next(f.r.db.camera.framing.journal.entries), nil)
        eq(#f.calls, 2); eq(f.env.UIParent:IsShown(), true)
    end)
    test("CAM03 absent invalid restricted and changing FOV bounds refuse only framing", function()
        for _, getter in ipairs({ function() return 90, 0, 180 end, function() return "90", 60, 100 end, function() error("private") end }) do
            local f = make(); f.env.GetCameraFOVDefaults = getter
            eq(f.r.camera.ApplyFOV(80), nil); eq(#f.calls, 0); assert(f.r.camera.Toggle()); assert(f.r.camera.Exit())
        end
        local f = make(); f.env.GetCameraFOVDefaults = nil; eq(f.r.camera.ApplyFOV(80), nil); eq(#f.calls, 0)
        local g = make(); g.restricted = "cameraFov"; eq(g.r.camera.ApplyFOV(80), nil); eq(#g.calls, 0)
        local h = make(); eq(h.r.camera.ApplyFOV(101), nil); eq(h.r.camera.ApplyFOV(75.55), nil)
        assert(h.r.camera.ApplyFOV(80)); h.flush(); h.env.GetCameraFOVDefaults = function() return 70, 60, 75 end
        eq(h.r.camera.RestoreFOV(), nil); eq(h.values.cameraFov, "80"); assert(h.r.db.camera.framing.journal.entries.cameraFov)
    end)
    test("CAM04 another camera addon wins an external FOV change, without retry or name coupling", function()
        local f = make(); assert(f.r.camera.ApplyFOV(80)); f.flush()
        f.values.cameraFov = "85"; f.r.framing.Observe(); local calls = #f.calls
        eq(f.r.camera.RestoreFOV(), nil); eq(#f.calls, calls); eq(f.values.cameraFov, "85")
        assert(f.r.camera.ToggleNames()); f.flush(); eq(f.values[player], "0"); eq(f.values.cameraFov, "85")
        assert(f.r.camera.ToggleNames()); f.flush(); eq(f.values[player], "1")
    end)
    test("CAM05 FOV failures and reload retain exact originals with no automatic restoration", function()
        local f = make(); f.setter = function(key, target) f.values[key] = target; return false end
        eq(f.r.camera.ApplyFOV(80), nil); f.flush()
        local record = f.r.db.camera.framing.journal.entries.cameraFov
        assert(record); eq(record.originalRaw, "090.00")
        local g = make(); assert(g.r.camera.ApplyFOV(80)); g.flush()
        local h = make(g.r.db, g.values); eq(#h.calls, 0); eq(h.r.framing.state, "RECOVERY")
        assert(h.r.camera.RestoreFOV()); h.flush(); eq(h.values.cameraFov, "090.00")
    end)
    test("CAM06 guides survive hidden HUD and capture hides guides until native completion", function()
        local f = make(); f.r.db.camera.thirds, f.r.db.camera.aspect = true, "square"
        assert(f.r.camera.Toggle()); local c = f.r.composition
        eq(c.root:IsShown(), true); eq(c.root.parent, nil); eq(c.lines[1].alpha, 0.55)
        eq(c.lines[1]:GetHeight(), 800); assert(c.Capture()); eq(c.root:IsShown(), false)
        f.tick(); eq(f.captures, 1); eq(c.root:IsShown(), false)
        c.root.scripts.OnEvent(c.root, "SCREENSHOT_SUCCEEDED"); eq(c.status, "SCREENSHOT_SUCCEEDED"); eq(c.root:IsShown(), true)
        f.flush(); assert(f.r.camera.Exit()); eq(c.root:IsShown(), false); eq(#f.calls, 0)
    end)
    test("CAM07 screenshot missing failed timed out or cancelled restores controls without false success", function()
        local f = make(); assert(f.r.camera.Toggle()); f.env.Screenshot = nil
        eq(f.r.composition.Capture(), nil); eq(f.r.composition.root:IsShown(), true)
        local g = make(); assert(g.r.camera.Toggle()); assert(g.r.composition.Capture()); g.flush()
        eq(g.r.composition.status, "CAPTURE_RESULT_UNOBSERVED"); eq(g.r.composition.root:IsShown(), true)
        local h = make(); assert(h.r.camera.Toggle()); assert(h.r.composition.Capture()); h.r.camera.Exit(); h.flush()
        eq(h.captures, 0); eq(h.r.composition.root:IsShown(), false)
        local j = make(); assert(j.r.camera.Toggle()); assert(j.r.composition.Capture()); j.tick()
        j.r.composition.root.scripts.OnEvent(j.r.composition.root, "SCREENSHOT_FAILED")
        eq(j.r.composition.status, "SCREENSHOT_FAILED"); eq(j.r.composition.root:IsShown(), true)
    end)
    test("CAM08 combat exposes HUD and hides composition without restoring graphics", function()
        local f = make(); assert(f.r.camera.ApplyFOV(80)); f.flush(); assert(f.r.camera.Toggle())
        local count = #f.calls; f.env.InCombatLockdown = function() return true end
        f.frame.OnEvent(f.frame, "PLAYER_REGEN_DISABLED")
        eq(f.env.UIParent:IsShown(), true); eq(f.r.composition.root:IsShown(), false); eq(#f.calls, count)
        eq(f.values.cameraFov, "80"); eq(f.r.composition.Capture(), nil)
    end)
    test("CAM09 temporary photo quality restores exact bank leaves and leaves saved preferences intact", function()
        local f = make(); f.apply("normal", 4); f.apply("raid", 3)
        f.values.RAIDsettingsEnabled = "1"
        -- The raid toggle is external to its earlier ownership: explicitly restore and reapply it.
        assert(f.r.graphics.Restore("raid")); f.flush()
        f.values.RAIDsettingsEnabled = "1"; f.apply("raid", 3)
        local before = f.ns.Value.Copy(f.values); local choices = f.ns.Value.Copy(f.r.db.graphics.choices)
        local normalOriginal = f.r.db.graphics.records.normal.original.farclip
        f.r.db.camera.photoEnabled, f.r.db.camera.photoLevel = true, 7
        assert(f.r.camera.Toggle()); f.flush(); eq(f.r.camera.active, true); eq(f.values.graphicsQuality, "6"); eq(f.values.raidGraphicsQuality, "6")
        eq(f.r.db.graphics.choices.raid.level, choices.raid.level); eq(f.r.db.graphics.records.normal.original.farclip, normalOriginal)
        assert(f.ns.Store.Open(f.r.db), "combined normal/raid/photo journals must remain within storage limits")
        eq(f.r.graphics.Apply(f.choice("normal", 5)), nil)
        assert(f.r.camera.Exit()); f.flush(); eq(f.r.camera.active, false)
        for _, key in ipairs(f.ns.NativeGraphics.Keys()) do assert(f.values[key] == before[key], key .. " expected " .. tostring(before[key]) .. " got " .. tostring(f.values[key])) end
        eq(next(f.r.db.camera.photo.records), nil); eq(f.r.db.graphics.records.normal.state, "owned")
    end)
    test("CAM10 photo conflicts keep HUD accessible and preserve external values and recovery", function()
        local f = make(); f.r.db.camera.photoEnabled = true; assert(f.r.camera.Toggle()); f.flush()
        f.values.farclip = "9999"; f.r.photo.Observe(); local count = #f.calls
        eq(f.r.camera.Exit(), nil); f.flush(); eq(f.env.UIParent:IsShown(), true)
        eq(f.values.farclip, "9999"); eq(#f.calls, count); assert(f.r.db.camera.photo.records.normal)
        assert(f.ns.Report.Export(f.r):find("photo farclip original=", 1, true))
    end)
    test("CAM11 partial photo failure never hides HUD and rollback or recovery stays local", function()
        local f = make(); f.r.db.camera.photoEnabled = true
        f.setter = function(key, target, count) if count == 2 then return false end; return f.native(key, target) end
        assert(f.r.camera.Toggle()); f.flush(); eq(f.r.camera.active, false); eq(f.env.UIParent:IsShown(), true)
        eq(f.values.farclip, "05432.00"); eq(next(f.r.db.graphics.records), nil)
        local g = make(); g.r.db.camera.photoEnabled = true
        g.setter = function(key, target, count) if count >= 2 then return false end; return g.native(key, target) end
        g.r.camera.Toggle(); g.flush(); eq(g.env.UIParent:IsShown(), true); assert(g.r.db.camera.photo.records.normal)
    end)
    test("CAM12 photo reload is read-only and explicit Camera restore recovers matching values", function()
        local f = make(); f.r.db.camera.photoEnabled = true; assert(f.r.camera.Toggle()); f.flush()
        local g = make(f.r.db, f.values); eq(#g.calls, 0); eq(g.r.camera.active, false); eq(g.r.photo.state, "RECOVERY")
        assert(g.r.camera.Exit()); g.flush(); eq(g.values.farclip, "05432.00"); eq(next(g.r.db.camera.photo.records), nil)
    end)
    test("CAM13 exit during photo verification cancels pending hide without losing originals", function()
        local f = make(); f.r.db.camera.photoEnabled = true; assert(f.r.camera.Toggle())
        eq(f.r.camera.Exit(), nil); f.flush(); eq(f.env.UIParent:IsShown(), true); eq(f.r.camera.active, false)
        assert(f.r.db.camera.photo.records.normal); assert(f.r.camera.Exit()); f.flush(); eq(f.values.farclip, "05432.00")
    end)
    test("CAM14 FPS observation is user-started read-only bounded and reports actual elapsed readings", function()
        local f = make(); local p = f.r.performance
        eq(#p.results, 0); eq(p.active, false); assert(p.Start()); f.flush()
        eq(p.active, false); eq(p.status, "COMPLETE"); eq(#p.results, 1); eq(#f.calls, 0)
        local result = p.results[1]; eq(result.count, 10); eq(result.elapsed, 10); eq(result.mean, 60); eq(result.low, 60)
        eq(result.effective.farclip, "05432.00"); eq(result.requested.normal.source, "keep")
        f.fps = 45; assert(p.Start()); f.flush(); eq(#p.results, 2); eq(p.results[2].mean, 45)
        f.fps = 80; assert(p.Start()); f.flush(); eq(#p.results, 2); eq(p.results[1].mean, 45)
        assert(f.ns.Report.Export(f.r):find("FPS sample 2", 1, true))
    end)
    test("CAM15 missing restricted invalid FPS or clock observations fail without fabricated results", function()
        local f = make(); f.env.GetFramerate = nil; eq(f.r.performance.Start(), nil); eq(#f.calls, 0)
        for _, value in ipairs({ 0, -10, "60", "SECRET", math.huge }) do
            local g = make(); g.fps = value; eq(g.r.performance.Start(), nil); eq(#g.r.performance.results, 0)
        end
        local h = make(); assert(h.r.performance.Start()); h.env.GetTime = function() return 100 end; h.flush()
        eq(h.r.performance.status, "FPS_OBSERVATION_INVALID"); eq(#h.r.performance.results, 0)
    end)
    test("CAM16 FPS cancels on changed settings scene change and user cancellation", function()
        local f = make(); assert(f.r.performance.Start()); f.values.RenderScale = "0.8"; f.flush()
        eq(f.r.performance.status, "SAMPLE_SETTINGS_CHANGED"); eq(#f.r.performance.results, 0)
        for _, event in ipairs({ "PLAYER_LEAVING_WORLD" }) do
            local g = make(); assert(g.r.performance.Start()); g.frame.OnEvent(g.frame, event); g.flush()
            eq(g.r.performance.active, false); eq(#g.r.performance.results, 0); eq(#g.calls, 0)
        end
        local h = make(); assert(h.r.performance.Start()); h.r.performance.Cancel(); assert(h.r.performance.Start()); h.flush()
        eq(#h.r.performance.results, 1)
    end)
    test("CAM17 Camera and FPS controls are reachable without commands or automatic application", function()
        local f = make(); f.r.ui.Open(9); f.mock.Click("Square"); eq(f.r.db.camera.aspect, "square"); eq(#f.calls, 0)
        f.mock.Click("Apply field of view"); f.flush(); eq(#f.calls, 0)
        f.r.ui.Open(2); f.r.ui.scroll:SetVerticalScroll(400)
        f.mock.Click("Quieter operation"); eq(f.r.performance.priority, "quiet"); eq(f.r.ui.scroll:GetVerticalScroll(), 400)
        f.mock.Click("Busy town"); eq(f.r.performance.scene, "town"); eq(f.r.ui.scroll:GetVerticalScroll(), 400)
        f.mock.Click("Observe FPS for 10 seconds"); f.flush(); eq(#f.r.performance.results, 1); eq(#f.calls, 0)
    end)
    test("CAM18 combined names framing and two-bank photo exit serializes every restoration", function()
        local f = make(); f.r.db.camera.hideWithUI, f.r.db.camera.photoEnabled = true, true
        f.values.RAIDsettingsEnabled = "1"
        assert(f.r.camera.ApplyFOV(80)); f.flush()
        assert(f.r.camera.Toggle()); f.flush(); eq(f.r.camera.active, true); eq(f.values[player], "0")
        assert(f.r.camera.Exit()); f.flush(); eq(f.r.camera.busy, false); eq(f.r.camera.error, nil)
        eq(f.values.cameraFov, "090.00"); eq(f.values[player], "1"); eq(f.values[pet], "0")
        eq(f.values.farclip, "05432.00"); eq(f.values.RAIDfarclip, "03210.00")
        eq(next(f.r.db.camera.photo.records), nil); eq(next(f.r.db.camera.framing.journal.entries), nil)
    end)
    test("CAM19 photo restore failure retains one bank while independent matching bank restores", function()
        local f = make(); f.r.db.camera.photoEnabled = true; f.values.RAIDsettingsEnabled = "1"
        assert(f.r.camera.Toggle()); f.flush(); f.values.farclip = "9999"
        f.r.camera.Exit(); f.flush(); eq(f.values.farclip, "9999"); eq(f.values.RAIDfarclip, "03210.00")
        assert(f.r.db.camera.photo.records.normal); eq(f.r.db.camera.photo.records.raid, nil)
        eq(f.env.UIParent:IsShown(), true); eq(f.r.camera.busy, false)
        eq(f.r.photo.Status().state, "RECOVERY"); eq(f.r.photo.Status().error, "PHOTO_EXTERNAL_CONFLICT")
    end)
    test("CAM20 photo native failure and callback reentry preserve canonical optical ownership", function()
        local f = make(); f.values.ResampleAlwaysSharpen, f.values.ResampleSharpness, f.values.bloomUserMult = "1", "1", "1"
        assert(f.r.product.Select("nightVision")); f.flush()
        local before = f.ns.Value.Copy(f.r.db.experiments.journal.entries)
        f.r.db.camera.photoEnabled = true
        f.setter = function(key, target)
            eq(f.r.graphics.Apply(f.choice("normal", 4)), nil)
            eq(f.r.camera.ApplyFOV(80), nil)
            eq(f.r.lab.Apply("quality", { ResampleSharpness = 0.5 }), nil)
            f.frame.OnEvent(f.frame, "CVAR_UPDATE", key, target)
            return f.native(key, target)
        end
        assert(f.r.camera.Toggle()); f.flush(); f.setter = nil
        eq(f.values.Brightness, "75"); assert(f.r.camera.Exit()); f.flush()
        for key, record in pairs(before) do eq(f.r.db.experiments.journal.entries[key].originalRaw, record.originalRaw) end
        eq(f.values.Brightness, "75"); eq(f.r.product.active, "nightVision")
        assert(f.r.camera.Toggle()); f.flush(); f.env.C_CVar.SetCVar = nil
        f.r.camera.Exit(); f.flush(); assert(f.r.db.camera.photo.records.normal); eq(f.env.UIParent:IsShown(), true)
    end)
    test("CAM21 FPS timer failure and observation changes never schedule indefinite work", function()
        local f = make(); f.env.C_Timer.After = function() error("private") end
        eq(f.r.performance.Start(), nil); eq(f.r.performance.status, "SAMPLE_TIMER_FAILED"); eq(#f.calls, 0)
        local g = make(); assert(g.r.performance.Start()); g.tick(); g.fps = "SECRET"; g.flush()
        eq(g.r.performance.status, "FPS_OBSERVATION_INVALID"); eq(#g.r.performance.results, 0)
        local h = make(); h.r.performance.scene = "arbitrary private text"; eq(h.r.performance.Start(), nil)
        eq(h.ns.Report.Export(h.r):find("arbitrary private text", 1, true), nil)
    end)
    test("CAM22 framing admission cannot expand to zoom arbitrary names or forged bounds", function()
        local f = make(); local F, C = f.ns.Framing, f.ns.Catalog
        local context = F.Context(f.r.identity.signature)
        local descriptor = F.Descriptor("cameraFov", { min = 60, max = 100 }, f.r.identity.signature)
        assert(C.Admitted(descriptor, context)); descriptor.name = "cameraDistanceMaxZoomFactor"; eq(C.Admitted(descriptor, context), false)
        descriptor.name, descriptor.max = "cameraFov", 200; eq(C.Admitted(descriptor, context), false)
        eq(f.r.framing.Apply("camera", { cameraDistanceMaxZoomFactor = 3 }), nil); eq(#f.calls, 0)
    end)
    test("CAM23 explicit restore after reload includes matching names framing and photo originals", function()
        local f = make(); f.r.db.camera.hideWithUI, f.r.db.camera.photoEnabled = true, true
        assert(f.r.camera.ApplyFOV(80)); f.flush(); assert(f.r.camera.Toggle()); f.flush()
        local g = make(f.r.db, f.values); eq(#g.calls, 0); eq(g.r.camera.active, false)
        assert(g.r.camera.Exit()); g.flush(); eq(g.values[player], "1"); eq(g.values[pet], "0")
        eq(g.values.cameraFov, "090.00"); eq(g.values.farclip, "05432.00"); eq(g.r.camera.error, nil)
    end)
    test("CAM24 deliberate combat sampling remains read-only and labels combat observations", function()
        local f = make(); f.env.InCombatLockdown = function() return true end
        f.r.performance.scene = "raid"; assert(f.r.performance.Start()); f.flush()
        eq(f.r.performance.results[1].combatSamples, 10); eq(f.r.performance.results[1].scene, "raid"); eq(#f.calls, 0)
        eq(f.r.camera.ApplyFOV(80), nil); eq(#f.calls, 0)
    end)
    test("CAM25 read callbacks cannot cross between normal/photo or names/framing writers", function()
        local f = make(); local getter, probing = f.env.C_CVar.GetCVar, false
        local phase = "photo"
        f.env.C_CVar.GetCVar = function(key)
            if not probing then
                probing = true
                if phase == "photo" then eq(f.r.graphics.Apply(f.choice("normal", 4)), nil)
                elseif phase == "normal" then eq(f.r.photo.Apply(f.choice("normal", 4)), nil)
                elseif phase == "framing" then eq(f.r.names.Apply("camera", { [player] = 0 }), nil)
                elseif phase == "names" then eq(f.r.framing.Apply("camera", { cameraFov = 80 }), nil) end
                probing = false
            end
            return getter(key)
        end
        assert(f.r.photo.Apply(f.choice("normal", 6))); f.flush()
        phase = nil; assert(f.r.photo.RestorePhoto()); f.flush()
        phase = "normal"; assert(f.r.graphics.Apply(f.choice("normal", 4))); f.flush()
        phase = "framing"; assert(f.r.camera.ApplyFOV(80)); f.flush()
        phase = "names"; assert(f.r.names.Apply("camera", { [player] = 0 })); f.flush()
        eq(f.values.cameraFov, "80"); eq(f.values.graphicsQuality, "3")
    end)
    test("CAM26 unknown combat state is labelled separately and delayed captures start their own timeout", function()
        local f = make(); f.env.InCombatLockdown = nil; assert(f.r.performance.Start()); f.flush()
        eq(f.r.performance.results[1].combatSamples, 0); eq(f.r.performance.results[1].combatUnknown, 10)
        local g = make(); assert(g.r.camera.Toggle()); assert(g.r.composition.Capture())
        eq(#g.mock.timers, 1); g.clock = g.clock + 10; g.tick()
        eq(g.captures, 1); eq(g.r.composition.capturing, true); eq(#g.mock.timers, 1); eq(g.mock.timers[1][1], 5)
        g.flush(); eq(g.r.composition.status, "CAPTURE_RESULT_UNOBSERVED")
    end)
    if os.getenv("LUMENSHIFT_UI_MODEL_PATH") then
        local f = make(); f.r.ui.Open(9); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-camera.tsv")
        f.r.ui.scroll:SetVerticalScroll(450); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-camera-photo.tsv")
        f.r.ui.Open(2); f.r.ui.scroll:SetVerticalScroll(400); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-performance-goals.tsv")
        f.r.ui.scroll:SetVerticalScroll(650); f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-performance.tsv")
        f.r.ui.window:Hide(); f.r.db.camera.thirds = true; f.r.db.camera.aspect = "cinema"; f.r.camera.Toggle()
        f.mock.Export(os.getenv("LUMENSHIFT_UI_MODEL_PATH") .. "-composition.tsv")
    end
end
