local _, ns = ...
local U, W = {}, ns.Widgets; ns.PhotoToolsUI = U
function U.Combat(runtime, env, parent)
    local y = 0
    W.Section(parent,"COMBAT BEHAVIOR",0,y,310); y=y-40
    W.Toggle(env,parent,"Stay in Photo Studio in combat",0,y,310,function() return runtime.db.camera.keepInCombat end,
        function(v) runtime.db.camera.keepInCombat=v; if not v and runtime.product.IsCombat() then runtime.camera.Combat() end end); y=y-46
    W.Toggle(env,parent,"Keep filters during combat",0,y,310,function() return runtime.db.camera.effectsInCombat end,
        function(v) runtime.db.camera.effectsInCombat=v; runtime.product.RefreshPresentation(true); runtime.photoEditor.Render() end); y=y-46
    W.Text(parent,"Native graphics and name changes, plus camera orbit, pause during combat.",0,y,310,12,W.colors.muted); y=y-56
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
