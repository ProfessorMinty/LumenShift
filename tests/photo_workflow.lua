-- Standalone simulated photo workflow. No installed addon or game is loaded.
return function(cameraFixture, eq, test)
    local function make()
        local f = cameraFixture()
        f.emotes, f.stops = {}, 0
        f.env.C_ChatInfo = { PerformEmote = function(token, target)
            eq(target, "none"); f.emotes[#f.emotes + 1] = token; return true
        end, CancelEmote = function() f.stops = f.stops + 1 end }
        eq(f.env.NarciScreenshotToolbar, nil); eq(f.env.Narci, nil)
        assert(f.r.camera.Toggle()); f.flush()
        f.seq, f.pose, f.c, f.editor = f.r.captureSequence, f.r.photoTools, f.r.composition, f.r.photoEditor
        return f
    end
    local function request(f)
        local before, guard = f.captures, 0
        repeat f.tick(); guard = guard + 1; assert(guard < 35) until f.captures > before
        eq(f.c.root:IsShown(), false); eq(f.c.input:IsShown(), true)
    end
    local function completed(f, success)
        f.c.root.scripts.OnEvent(f.c.root, success == false and "SCREENSHOT_FAILED" or "SCREENSHOT_SUCCEEDED")
    end
    test("WF01 standalone poses use native API once, favorites and all six tabs need no Narcissus", function()
        local f = make(); eq(f.r.photoCompatibility.state, "STANDALONE"); eq(#f.calls, 0)
        assert(f.pose.Perform("WAVE")); eq(#f.emotes, 1); eq(f.emotes[1], "WAVE"); eq(#f.calls, 0)
        assert(f.pose.Favorite("READ")); eq(f.r.db.camera.tools.favorites.READ, true)
        assert(f.pose.Stop()); eq(f.stops, 1)
        for _, tab in ipairs({ "Look", "Light", "Frame", "Pose", "Capture", "Saved" }) do f.c.editor.tab = tab; f.c.editor.Build(true) end
        eq(f.r.lastError, nil); assert(f.r.camera.Exit()); f.flush(); eq(#f.calls, 0)
    end)
    test("WF02 missing and rejected modern emotes never guess or fall back after a rejection", function()
        local f = make(); local legacy = 0; f.env.DoEmote = function() legacy = legacy + 1 end
        for _, fn in ipairs({ function() return false end, function() error("private detail") end, function() return "yes" end, function() end }) do
            f.env.C_ChatInfo.PerformEmote = fn; eq(f.pose.Perform("DANCE"), nil); eq(legacy, 0); eq(f.captures, 0)
        end
        f.env.C_ChatInfo.PerformEmote = nil; assert(f.pose.Perform("DANCE")); eq(legacy, 1)
        f.env.DoEmote = nil; eq(f.pose.Perform("DANCE"), nil); eq(f.pose.Available(), false)
        eq(f.pose.Perform("arbitrary script"), nil)
    end)
    test("WF03 three-shot burst advances only on results and remains finite", function()
        local f = make(); local prefs = f.r.db.camera.tools; prefs.delay, prefs.shots, prefs.interval = 2, 3, 1
        assert(f.seq.Start()); eq(f.seq.remaining, 2); eq(f.captures, 0)
        for i = 1, 3 do request(f); completed(f); eq(f.seq.completed, i) end
        f.flush(); eq(f.captures, 3); eq(f.seq.active, false); eq(f.seq.state, "COMPLETE"); eq(f.c.root:IsShown(), true)
    end)
    test("WF04 cancellation during countdown or between shots invalidates every remaining timer", function()
        local f = make(); assert(f.seq.Start()); f.seq.Cancel(); f.flush(); eq(f.captures, 0)
        f.r.db.camera.tools.shots = 3; assert(f.seq.Start()); request(f); completed(f); f.seq.Cancel(); f.flush()
        eq(f.captures, 1); eq(f.seq.state, "CANCELLED"); eq(f.c.root:IsShown(), true)
    end)
    test("WF05 cancellation after native request drains one result without issuing another shot", function()
        local f = make(); f.r.db.camera.tools.shots = 3; assert(f.seq.Start()); request(f)
        f.seq.Cancel(); eq(f.c.capturing, true); completed(f); f.flush(); eq(f.captures, 1); eq(f.seq.completed, 0)
        eq(f.seq.state, "CANCELLED")
    end)
    test("WF06 timeout and native screenshot failure stop the burst without false success", function()
        for _, failure in ipairs({ "event", "timeout" }) do
            local f = make(); f.r.db.camera.tools.shots = 3; assert(f.seq.Start()); request(f)
            if failure == "event" then completed(f, false) end
            f.flush(); eq(f.seq.active, false); eq(f.seq.completed, 0); eq(f.captures, 1)
            eq(f.seq.state, failure == "event" and "SCREENSHOT_FAILED" or "CAPTURE_RESULT_UNOBSERVED")
        end
    end)
    test("WF07 Escape combat and world leave cancel pending sequences across re-entry", function()
        for _, event in ipairs({ "exit", "combat", "leave" }) do
            local f = make(); assert(f.seq.Start())
            if event == "exit" then f.r.camera.Exit()
            elseif event == "combat" then f.env.InCombatLockdown = function() return true end; f.frame.OnEvent(f.frame, "PLAYER_REGEN_DISABLED")
            else f.frame.OnEvent(f.frame, "PLAYER_LEAVING_WORLD") end
            f.flush(); eq(f.seq.active, false); eq(f.captures, 0)
        end
    end)
    test("WF08 pose capture is one requested shot and Stop cancels its pending timer", function()
        local f = make(); f.r.db.camera.tools.autoPose, f.r.db.camera.tools.shots = true, 5
        assert(f.pose.Perform("KNEEL")); request(f); completed(f); f.flush(); eq(f.captures, 1); eq(#f.emotes, 1)
        assert(f.pose.Perform("WAVE")); assert(f.pose.Stop()); f.flush(); eq(f.captures, 1); eq(f.stops, 1)
    end)
    test("WF09 preview drains before timed capture and cancellation cannot resurrect it", function()
        local f = make(); assert(f.r.photoPreview.Queue("Brightness", 70)); assert(f.seq.Start())
        eq(f.seq.state, "WAITING_FOR_PREVIEW"); eq(f.captures, 0); request(f); eq(f.values.Brightness, "70")
        completed(f); f.flush(); f.r.camera.Exit(); f.flush(); eq(f.values.Brightness, "52")
        local g = make(); assert(g.r.photoPreview.Queue("Brightness", 72)); assert(g.seq.Start()); g.seq.Cancel(); g.flush()
        eq(g.captures, 0); eq(g.seq.active, false)
    end)
    test("WF10 preview rejection cancels waiting capture and does not leave an active phantom timer", function()
        local f = make(); f.setter = function() return false end
        assert(f.r.photoPreview.Queue("Brightness", 72)); assert(f.seq.Start()); f.flush()
        eq(f.seq.active, false); eq(f.captures, 0)
    end)
    test("WF11 capture preserves clean view and treats missing timer or screenshot as local failure", function()
        local f = make(); assert(f.c.ToggleControls()); assert(f.seq.Start()); request(f); completed(f); f.flush()
        eq(f.c.controlsHidden, true); eq(f.c.root:IsShown(), false)
        local g = make(); g.env.Screenshot = nil; eq(g.seq.Start(), nil); eq(g.seq.active, false); assert(g.pose.Perform("WAVE"))
        g.env.Screenshot = function() end; g.env.C_Timer.After = function() error("timer") end
        g.seq.Start(); eq(g.seq.active, false); eq(g.seq.state, "CAPTURE_TIMER_FAILED")
    end)
    test("WF12 grouped look undo redo covers drags recipes imports and leaves native journals unchanged", function()
        local f = make(); local e = f.editor; local original = f.ns.PhotoConfig.Export(f.r.db.camera.editor.look)
        e.BeginLookEdit(); for i = 1, 100 do e.Set("warmth", i / 100) end; e.EndLookEdit(); eq(#e.undo, 1)
        assert(e.Undo()); eq(f.ns.PhotoConfig.Export(f.r.db.camera.editor.look), original)
        assert(e.Undo(true)); eq(f.r.db.camera.editor.look.warmth, 1)
        assert(e.Recipe("ember")); assert(e.Undo()); eq(f.r.db.camera.editor.look.warmth, 1)
        assert(e.SetMany({ glowR = .2, glowG = .3, glowB = .4 })); eq(#e.redo, 0)
        assert(e.Import(original)); assert(e.Undo()); eq(f.r.db.camera.editor.look.glowR, .2)
        eq(#f.calls, 0); eq(next(f.r.db.journal.entries), nil)
    end)
    test("WF13 history is bounded and look mutation is refused during capture or combat", function()
        local f = make(); for i = 1, 70 do f.editor.Set("warmth", i / 100) end; eq(#f.editor.undo, 32)
        assert(f.seq.Start()); eq(f.editor.Set("warmth", -1), nil); eq(f.editor.Undo(), nil)
        f.seq.Cancel(); f.env.InCombatLockdown = function() return true end; eq(f.editor.Recipe("ember"), nil)
    end)
    test("WF14 name groups omit absent optional keys and restore exact originals through the sole writer", function()
        local f = make(); f.values.UnitNameOwn, f.values.UnitNameEnemyPlayerName = "01", "1"
        f.r.db.camera.nameGroups.players = true; assert(f.r.camera.ApplyNames()); f.flush()
        eq(f.values.UnitNameOwn, "0"); eq(f.values.UnitNameEnemyPlayerName, "0")
        eq(f.r.db.camera.journal.entries.UnitNameOwn.originalRaw, "01")
        f.r.db.camera.nameGroups.npcs = true; assert(f.r.camera.ApplyNames()); f.flush(); assert(#f.r.camera.unavailableNames > 0)
        assert(f.r.camera.Exit()); f.flush(); eq(f.values.UnitNameOwn, "01"); eq(f.values.UnitNameEnemyPlayerName, "1")
        eq(f.r.db.camera.nameReturn, nil)
    end)
    test("WF15 names preserve manual intent while camera toggles additional groups", function()
        local f = make(); f.r.camera.Exit(); f.flush(); assert(f.r.camera.ToggleNames()); f.flush()
        local player = "UnitNameFriendlyPlayerName"; eq(f.values[player], "0")
        assert(f.r.camera.Toggle()); f.r.db.camera.nameGroups.bubbles = true; f.values.chatBubbles, f.values.chatBubblesParty = "1", "0"
        assert(f.r.camera.ApplyNames()); f.flush(); eq(f.values.chatBubbles, "0")
        f.r.camera.Exit(); f.flush(); eq(f.values.chatBubbles, "1"); eq(f.values[player], "0")
        assert(f.r.camera.ToggleNames()); f.flush(); eq(f.values[player], "1")
    end)
    test("WF16 external name change survives exit with original recovery retained", function()
        local f = make(); f.values.chatBubbles = "1"; f.r.db.camera.nameGroups.bubbles = true
        assert(f.r.camera.ApplyNames()); f.flush(); f.values.chatBubbles = "01"; f.r.names.Observe()
        local count = #f.calls; f.r.camera.Exit(); f.flush(); eq(f.values.chatBubbles, "01"); eq(#f.calls, count)
        assert(f.r.db.camera.journal.entries.chatBubbles); eq(f.env.UIParent:IsShown(), true)
    end)
    test("WF17 schema 13 migration preserves looks originals completion and settings without writes", function()
        local f = make(); local old = f.ns.Value.Copy(f.r.db); old.schemaVersion = 13
        old.camera.tools, old.camera.nameGroups = nil, nil; old.onboarding.completed = true
        old.camera.editor.look.warmth = .42
        local copy, why = f.ns.Store.Open(old); eq(why, "MIGRATED_13_TO_15"); eq(copy.camera.editor.look.warmth, .42)
        eq(copy.onboarding.completed, true); eq(copy.camera.nameGroups.players, false); eq(old.camera.tools, nil)
        copy.camera.tools.shots = 100; eq(f.ns.Store.Open(copy), nil); eq(#f.calls, 0)
    end)
    test("WF18 passive Narcissus toolbar is optional and native cleanup can run without foreign API calls", function()
        local f = make(); f.r.camera.Exit(); f.flush()
        local bar = f.env.CreateFrame("Frame"); bar.layout = "Blizzard"; bar:Hide(); f.env.NarciScreenshotToolbar = bar
        local forbidden = 0; bar.HideUI = function() forbidden = forbidden + 1; error("do not restore foreign settings") end
        local native = f.env.SetUIVisibility
        f.env.SetUIVisibility = function(shown)
            native(shown)
            if shown then bar:Hide() else bar:Show() end
        end
        assert(f.r.camera.Toggle()); eq(bar:IsShown(), false); eq(f.r.photoCompatibility.state, "PASSIVE_TOOLBAR_HIDDEN")
        bar:Show(); eq(bar:IsShown(), false); assert(f.c.Capture()); request(f); completed(f); f.flush()
        assert(f.r.camera.Exit()); f.flush(); eq(bar:IsShown(), false); eq(forbidden, 0); eq(#f.calls, 0)
    end)
    test("WF19 an active foreign studio requests handoff without writing or breaking standalone modes", function()
        local f = make(); f.r.camera.Exit(); f.flush()
        local bar = f.env.CreateFrame("Frame"); bar.layout = "PhotoMode"; bar:Show(); f.env.NarciScreenshotToolbar = bar
        local ok, why = f.r.camera.Toggle(); eq(ok, nil); eq(why, "OTHER_PHOTO_STUDIO_ACTIVE"); eq(#f.calls, 0); eq(bar:IsShown(), true)
        f.env.NarciScreenshotToolbar = nil; assert(f.r.camera.Toggle()); assert(f.pose.Perform("WAVE"))
    end)
    test("WF20 late addon loading is optional and capture detects an unhideable foreign toolbar", function()
        local f = make(); local bar = f.env.CreateFrame("Frame"); bar.layout = "Blizzard"; bar:Show()
        f.env.NarciScreenshotToolbar = bar; assert(f.c.ToggleControls()); eq(bar:IsShown(), false)
        bar.Hide = function() error("restricted") end; bar:Show()
        local ok, why = f.c.Capture(); eq(ok, nil); eq(why, "OTHER_TOOLBAR_VISIBLE"); eq(f.captures, 0)
    end)
    test("WF21 capture option and favorite validation reject invalid or arbitrary data", function()
        local f = make(); local prefs = f.ns.Value.Copy(f.r.db.camera.tools)
        for _, value in ipairs({ -1, 20, .5, math.huge }) do prefs.shots = value; eq(f.seq.Start(prefs), nil) end
        eq(f.pose.Favorite("SCRIPT"), nil); prefs = f.ns.PhotoTools.Defaults(); prefs.favorites.SCRIPT = true
        eq(f.ns.PhotoTools.Validate(prefs), false); eq(f.captures, 0)
    end)
    test("WF22 reports expose numeric state without favorite labels or foreign saved data", function()
        local f = make(); local report = f.ns.Report.Export(f.r)
        assert(report:find("Photo tools:", 1, true)); assert(report:find("coexistence=STANDALONE", 1, true))
        assert(not report:find("NarcissusDB", 1, true)); eq(#f.calls, 0)
    end)
    test("WF23 optional foreign auto-hide names on or off keeps exact session return and preferences", function()
        for _, autoHide in ipairs({ false, true }) do
            local f = make(); f.r.camera.Exit(); f.flush()
            local player, backup = "UnitNameFriendlyPlayerName", nil
            f.values[player] = "01"; f.r.db.camera.hideWithUI = true
            local bar = f.env.CreateFrame("Frame"); bar.layout = "Blizzard"; bar:Hide(); f.env.NarciScreenshotToolbar = bar
            f.env.NarcissusDB = { HideTextsWithUI = autoHide, KeepActionCam = false }
            local native = f.env.SetUIVisibility
            f.env.SetUIVisibility = function(shown)
                native(shown)
                if not shown then
                    if autoHide then backup = f.values[player]; f.values[player] = "0" end
                    bar:Show()
                elseif bar:IsShown() then
                    if backup then f.values[player] = backup end
                    bar:Hide()
                end
            end
            assert(f.r.camera.Toggle()); f.flush(); eq(bar:IsShown(), false)
            eq(f.r.db.camera.journal.entries[player].originalRaw, "01")
            assert(f.r.camera.Exit()); f.flush(); eq(f.values[player], "01")
            eq(f.env.NarcissusDB.HideTextsWithUI, autoHide); eq(f.env.NarcissusDB.KeepActionCam, false)
            eq(next(f.r.db.camera.journal.entries), nil)
        end
    end)
    test("WF24 foreign late changes are observed without fighting or rebasing retained originals", function()
        local f = make(); assert(f.r.camera.ApplyFOV(80)); f.flush()
        local bar = f.env.CreateFrame("Frame"); bar.layout = "Blizzard"; bar:Hide(); f.env.NarciScreenshotToolbar = bar
        -- Model an independent addon's delayed change, not a LumenShift setter.
        f.values.cameraFov = "85"; f.r.photoCompatibility.AfterShow(); f.flush()
        eq(f.r.framing.state, "CONFLICT"); eq(f.r.db.camera.framing.journal.entries.cameraFov.originalRaw, "090.00")
        local count = #f.calls; f.r.camera.Exit(); f.flush(); eq(f.values.cameraFov, "85"); eq(#f.calls, count)
        f.values.cameraFov = "86"; f.r.photoCompatibility.AfterShow(); f.flush(); eq(f.values.cameraFov, "86"); eq(#f.calls, count)
    end)
    test("WF25 capture excludes in-flight native operations and countdown freezes native editing", function()
        local f = make(); local original = f.values.Brightness
        assert(f.editor.Native({ Brightness = 72 })); eq(f.c.Capture(), nil); eq(f.captures, 0); f.flush()
        assert(f.seq.Start()); eq(f.editor.Native({ Brightness = 73 }), nil); eq(f.editor.Compare(), nil)
        eq(f.editor.Restore(), nil); eq(f.r.camera.ApplyFOV(80), nil); eq(f.r.camera.RestoreFOV(), nil)
        f.seq.Cancel(); assert(f.c.Capture()); request(f)
        -- Escape must still return the values even while an issued screenshot drains.
        assert(f.r.camera.Exit()); completed(f); f.flush(); eq(f.values.Brightness, original); eq(f.env.UIParent:IsShown(), true)
    end)
    test("WF26 source-listed special NPC and raid bubble toggles restore exact values", function()
        local f = make(); f.values.UnitNameFriendlySpecialNPCName, f.values.chatBubblesRaid = "01", "1"
        f.r.db.camera.nameGroups.npcs, f.r.db.camera.nameGroups.bubbles = true, true
        assert(f.r.camera.ApplyNames()); f.flush(); eq(f.values.UnitNameFriendlySpecialNPCName, "0"); eq(f.values.chatBubblesRaid, "0")
        assert(f.r.camera.Exit()); f.flush(); eq(f.values.UnitNameFriendlySpecialNPCName, "01"); eq(f.values.chatBubblesRaid, "1")
    end)
end
