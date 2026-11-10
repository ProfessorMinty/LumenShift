local _, ns = ...
local U, W = {}, ns.Widgets; ns.PhotoToolsUI = U
function U.Status(code)
    return ({ READY = "Choose a pose. World emotes are visible to other players.", POSE_REQUESTED = "Pose requested. Animation depends on your character.",
        POSE_STOP_REQUESTED = "Stop requested.", POSE_REJECTED = "WoW could not perform that pose here.",
        POSE_UNAVAILABLE = "This client does not provide an emote API.", CAMERA_NOT_READY = "Finish or cancel the current capture first." })[code] or code
end
function U.Build(runtime, env, parent, tab, ui)
    local prefs, pose, sequence = runtime.db.camera.tools, runtime.photoTools, runtime.captureSequence
    local y = 0
    local function text(label, height) W.Text(parent, label, 0, y, 310, 12, W.colors.muted); y = y - height end
    if tab == "Pose" then
        text("Pose your character in the world. Emotes may be seen or heard by nearby players.", 54)
        W.Toggle(env, parent, "Capture after a pose", 0, y, 310, function() return prefs.autoPose end,
            function(v) prefs.autoPose = v end); y = y - 44
        text("Uses the delay on Capture and takes one shot. Pin your favorites to the top.", 50)
        W.Button(env, parent, "Stop pose / cancel capture", 0, y, 310, pose.Stop); y = y - 46
        local items = {}
        for _, pinned in ipairs({ true, false }) do
            for _, item in ipairs(ns.PhotoTools.Poses) do if (prefs.favorites[item[1]] == true) == pinned then items[#items + 1] = item end end
        end
        for _, item in ipairs(items) do
            local token = item[1]
            local button = W.Button(env, parent, item[2], 0, y, 224, function() pose.Perform(token) end)
            if not pose.Available() then button:Disable() end
            local pin = W.Button(env, parent, prefs.favorites[token] and "Pinned" or "Pin", 232, y, 78,
                function() pose.Favorite(token); ui.Build() end)
            pin.SetSelected(prefs.favorites[token] == true); y = y - 40
        end
    else
        W.Section(parent,"COMBAT BEHAVIOR",0,y,310); y=y-40
        W.Toggle(env,parent,"Stay in Photo Studio in combat",0,y,310,function() return runtime.db.camera.keepInCombat end,
            function(v) runtime.db.camera.keepInCombat=v; if not v and runtime.product.IsCombat() then runtime.camera.Combat() end end); y=y-46
        W.Toggle(env,parent,"Keep filters during combat",0,y,310,function() return runtime.db.camera.effectsInCombat end,
            function(v) runtime.db.camera.effectsInCombat=v; runtime.product.RefreshPresentation(true); runtime.photoEditor.Render() end); y=y-46
        text("Both on by default. Off: return to the game UI, or temporarily hide filters. Native graphics/name edits and orbit pause in combat; they are never queued.",90)
        text("Set up a single timed shot or a short burst. Controls disappear before every screenshot.", 56)
        for _, item in ipairs({ { "delay", "Delay before first shot", 0, 10 }, { "shots", "Number of shots", 1, 5 }, { "interval", "Seconds between shots", 1, 5 } }) do
            local key = item[1]
            W.Slider(env, parent, item[2], 0, y, item[3], item[4], 1, function() return prefs[key] end,
                function(v) if sequence.active then return nil end; prefs[key] = v; return true end, nil, 310); y = y - 72
        end
        W.Button(env, parent, "Start timed capture", 0, y, 310, function() sequence.Start() end); y = y - 40
        W.Button(env, parent, "Cancel timer / burst", 0, y, 310, sequence.Cancel); y = y - 48
        text("H hides all controls for your own screenshot program. Escape exits Camera Mode and cancels remaining shots.", 66)
        text("Screenshots are saved by WoW in its Screenshots folder. A shot already requested cannot be recalled.", 60)
    end
    return y
end
function U.Names(runtime, env, parent, y, ui)
    local db = runtime.db.camera
    W.Section(parent, "NAMES & BUBBLES", 0, y, 310); y = y - 40
    W.Toggle(env, parent, "Friendly players & pets", 0, y, 310, function() return db.hideWithUI end,
        function(v) db.hideWithUI = v end); y = y - 44
    for _, group in ipairs(ns.NamePolicy.Groups) do
        local id = group.id
        W.Toggle(env, parent, group.label, 0, y, 310, function() return db.nameGroups[id] end,
            function(v) db.nameGroups[id] = v end); y = y - 44
    end
    W.Button(env, parent, "Apply name choices now", 0, y, 310, function() runtime.camera.ApplyNames(); ui.Refresh() end); y = y - 46
    local _, unavailable = ns.NamePolicy.Targets(runtime.reader, db)
    W.Text(parent, "Checked groups are hidden. Apply now or on next entry; Exit returns prior settings."
        .. (#unavailable > 0 and " " .. #unavailable .. " unavailable options will be skipped." or ""), 0, y, 310, 12, W.colors.muted)
    return y - 84
end
