local _, ns = ...
local U, W = {}, ns.Widgets; ns.PhotoToolsUI = U
function U.Capture(runtime, env, parent, ui)
    local prefs, sequence = runtime.db.camera.tools, runtime.captureSequence
    local y = 0
    local function text(label, height) W.Text(parent, label, 0, y, 310, 12, W.colors.muted); y = y - height end
    if ui.capturePage == "Combat" then
        W.Section(parent,"COMBAT BEHAVIOR",0,y,310); y=y-40
        W.Toggle(env,parent,"Stay in Photo Studio in combat",0,y,310,function() return runtime.db.camera.keepInCombat end,
            function(v) runtime.db.camera.keepInCombat=v; if not v and runtime.product.IsCombat() then runtime.camera.Combat() end end); y=y-46
        W.Toggle(env,parent,"Keep filters during combat",0,y,310,function() return runtime.db.camera.effectsInCombat end,
            function(v) runtime.db.camera.effectsInCombat=v; runtime.product.RefreshPresentation(true); runtime.photoEditor.Render() end); y=y-46
        text("Both on by default. Off: return to the game UI, or temporarily hide filters. Native graphics/name edits and orbit pause in combat; they are never queued.",90)
    else
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
    local db, camera, controls = runtime.db.camera, runtime.camera, {}
    W.Section(parent, "NAMES & BUBBLES", 0, y, 310); y = y - 40
    W.Text(parent, "On means hidden. Changes apply immediately; Exit returns your previous name settings.", 0, y, 310, 12, W.colors.muted); y = y - 54
    controls[#controls + 1] = W.Button(env, parent, "Hide all names", 0, y, 150, function() camera.EditNames("all", true) end)
    controls[#controls + 1] = W.Button(env, parent, "Restore names", 160, y, 150, function() camera.EditNames("all", false) end,
        "Return name groups to their pre-photo settings. Chat bubbles are separate."); y = y - 44
    local status = W.Text(parent, "", 0, y, 310, 12, W.colors.muted); y = y - 62
    controls[#controls + 1] = W.Toggle(env, parent, "Hide friendly players & pets", 0, y, 310, function() return db.hideWithUI end,
        function(v) camera.EditNames("friendly", v) end); y = y - 44
    for _, group in ipairs(ns.NamePolicy.Groups) do
        local id = group.id
        controls[#controls + 1] = W.Toggle(env, parent, group.label, 0, y, 310, function() return db.nameGroups[id] end,
            function(v) camera.EditNames(id, v) end, id == "focused" and "Uses UnitNameFocused where available. This client's target / interaction label behavior still needs visual verification." or nil); y = y - 44
    end
    controls[#controls + 1] = W.Button(env, parent, "Retry name choices", 0, y, 310, function() camera.ApplyNames() end); y = y - 44
    local values = W.Text(parent, "", 0, y, 310, 12, W.colors.muted); y = y - 76
    ui.RefreshNames = function()
        local result = camera.nameResult
        local _, unavailable = ns.NamePolicy.Targets(runtime.reader, db)
        local message = result and (result.pending and "Applying name choices..." or result.ok and "Name settings read back correctly." or ns.Product.Message(result.code))
            or "Choose the names to hide."
        if #unavailable > 0 then message = message .. " " .. #unavailable .. " settings unavailable; see Diagnostics." end
        status:SetText(message)
        local seen = {}
        for _, item in ipairs({ { "NPC", "UnitNameNPC" }, { "Special", "UnitNameFriendlySpecialNPCName" },
            { "Interactive", "UnitNameInteractiveNPC" }, { "Focused", "UnitNameFocused" } }) do
            local raw = ns.ReadOnly.Read(runtime.reader, item[2])
            local value = ns.Planner.SafeObservation(raw, item[2]) and ns.Value.Number(raw.raw)
            seen[#seen + 1] = item[1] .. ": " .. (value and tostring(value) or "unavailable")
        end
        values:SetText(table.concat(seen, " / ") .. "\n0 = off. A remaining label may be forced by the client or another addon.")
        for _, button in ipairs(controls) do
            if button.RefreshValue then button.RefreshValue() end
            if runtime.names.busy or result and result.pending then button:Disable() else button:Enable() end
        end
    end
    ui.RefreshNames()
    return y
end
