local _, ns = ...
local U, W, C, V = {}, ns.Widgets, ns.PortraitConfig, ns.Value; ns.PortraitControls = U
function U.Build(runtime, env, parent, tab, ui, startY)
    local stage, data, y = runtime.portrait, runtime.db.camera.portrait, startY or 0
    local function text(value, height) W.Text(parent, value, 0, y, 310, 12, W.colors.muted); y = y - (height or 48) end
    local function section(value) W.Section(parent, value, 0, y, 310); y = y - 40 end
    local function action(label, fn)
        W.Button(env, parent, label, 0, y, 310, function() fn(); ui.Build() end); y = y - 40
    end
    local function slider(key, label, low, high, step, get, set)
        local s = W.Slider(env, parent, label, 0, y, low, high, step, get, set, nil, 310)
        ui.sliders[key] = s
        W.Script(s, "OnMouseDown", function() ui.dragging = s end)
        W.Script(s, "OnMouseUp", function() ui.dragging = nil; ui.Refresh() end)
        y = y - 68
    end
    if tab == "Pose" then
        section("CAST")
        text("Up to three staged copies. Your character and equipment in the world stay unchanged.", 54)
        for i, choice in ipairs({ { "player", "Add me" }, { "target", "Add target" }, { "pet", "Add pet" } }) do
            local unit = choice[1]
            W.Button(env, parent, choice[2], (i - 1) * 106, y, 98, function() stage.Add(unit); ui.Build() end)
        end
        y = y - 44
        for id = 1, 3 do
            local index, slot = id, stage.slots[id]
            if slot and slot.front then
                local b = W.Button(env, parent, id .. "  " .. slot.spec.unit, 0, y, 224, function() stage.selected = index; ui.Build() end)
                b.SetSelected(stage.selected == id)
                W.Button(env, parent, "Remove", 232, y, 78, function() stage.Remove(index); ui.Build() end); y = y - 40
            end
        end
        local selected = stage.slots[stage.selected]
        if selected and selected.front then
            for i,label in ipairs({"Transform","Poses","Outfits","Effects"}) do local choice=label
                local b=W.Button(env,parent,label,(i-1)%2*160,y-math.floor((i-1)/2)*40,150,function()
                    ui.actorTab=choice; if choice=="Outfits" then stage.wardrobe.Refresh() end; ui.Build(true)
                    if choice~="Transform" and ui.libraryY then ui.scrollbar:SetValue(-ui.libraryY) end
                end)
                b.SetSelected((ui.actorTab or "Transform")==label)
            end; y=y-88
            if (ui.actorTab or "Transform")~="Transform" then
                ui.libraryY=y
                y=ns.PortraitLibraryUI.Build(runtime,env,parent,ui,y,selected)
            else
            section("POSITION")
            for _, item in ipairs({ { "x", "Horizontal" }, { "y", "Vertical" }, { "depth", "Depth" }, { "scale", "Scale" }, { "yaw", "Turn" }, { "pitch", "Tilt" }, { "roll", "Roll" } }) do
                local key, r = item[1], C.ActorRanges[item[1]]
                if stage.backend.Supports(stage.backend.models[selected.front], key) then
                    slider(key, item[2], r[1], r[2], key == "yaw" and 1 or .01, function() return selected.spec[key] end, function(v) return stage.SetActor(key, v) end)
                else text(item[2] .. " unavailable on this model. Saved value kept.", 48) end
            end
            section("APPEARANCE PREVIEW")
            for _, item in ipairs({ { "sheathed", "Sheathe weapons" }, { "hideWeapons", "Hide weapons" }, { "transmog", "Use transmog appearance" }, { "hideHead", "Hide helmet" }, { "hideCloak", "Hide cloak" } }) do
                local key = item[1]
                if stage.backend.Supports(stage.backend.models[selected.front], key) then
                    W.Toggle(env, parent, item[2], 0, y, 310, function() return selected.spec[key] end,
                        function(v) stage.SetActor(key, v); ui.Build() end); y = y - 46
                else text(item[2] .. " unavailable on this model. Saved choice kept.", 48) end
            end
            end
        else text("Add a player, target or pet, then select its row to edit it.", 54) end
    elseif tab == "Light" then
        section("MODEL LIGHT")
        if not stage.backend.CanLight() then
            text("Model lighting is unavailable on this client. Actors, backgrounds, filters and capture remain available; your saved lights are kept.", 80)
            return y
        end
        text("Relight the staged cast. This light never changes the game world.", 48)
        for i, item in ipairs({ { "neutral", "Neutral" }, { "soft", "Softbox" }, { "ember", "Firelight" }, { "moon", "Moon rim" } }) do
            local id = item[1]
            W.Button(env, parent, item[2], (i - 1) % 2 * 160, y - math.floor((i - 1) / 2) * 40, 150,
                function() stage.SetLight(C.LightPreset(id)); ui.Build() end)
        end
        y = y - 88
        for _, item in ipairs({ { "azimuth", "Light direction" }, { "elevation", "Light elevation" }, { "ambient", "Ambient fill" }, { "diffuse", "Key intensity" }, { "red", "Key red" }, { "green", "Key green" }, { "blue", "Key blue" } }) do
            local key, r = item[1], C.LightRanges[item[1]]
            slider("light_" .. key, item[2], r[1], r[2], (key == "azimuth" or key == "elevation") and 1 or .01,
                function() return data.scene.light[key] end, function(v) local l = V.Copy(data.scene.light); l[key] = v; return stage.SetLight(l) end)
        end
    elseif tab == "Frame" and ui.cameraPage == "Position" then
        if stage.backend.kind ~= "ModelScene" then
            text("This renderer supports individual actor positioning. Open Actors and choose Transform.", 66)
            return y
        end
        text("Orbit the cast or roll the shot. The game world behind the cast stays level.", 44)
        local function lens(key, label, step)
            local range = C.CameraRanges[key]
            slider("stage_" .. key, label, range[1], range[2], step,
                function() return data.scene[key] end, function(value) return stage.SetScene(key, value) end)
        end
        lens("yaw", "Orbit left / right (yaw °)", 1)
        lens("pitch", "Camera elevation (pitch °)", 1)
        lens("roll", "Horizon roll (°)", 1)
        W.Button(env, parent, "Level horizon", 0, y, 150, function() stage.SetScene("roll", 0); ui.Build() end)
        W.Button(env, parent, "Reset stage camera", 160, y, 150, function() stage.ResetCamera(); ui.Build() end)
        y = y - 44
        lens("distance", "Camera distance", .1)
        lens("height", "Aim height", .1)
        lens("fov", "Field of view (degrees)", .1)
    elseif tab == "Frame" then
        section("BACKDROP")
        for _, choice in ipairs(C.Backgrounds) do local id = choice[1]; action(choice[2], function() stage.SetScene("background", id) end) end
        section("FRAMING")
        W.Toggle(env, parent, "Rule of thirds", 0, y, 310, function() return runtime.db.camera.thirds end,
            function(v) runtime.db.camera.thirds = v; runtime.composition.Show() end); y = y - 46
        local range = ns.PhotoConfig.Ranges.letterbox
        slider("letterbox", "Letterbox height", range[1], range[2], .01, function() return runtime.db.camera.editor.look.letterbox end,
            function(v) return runtime.photoEditor.Set("letterbox", v) end)
        text("H hides all controls and guides. Look filters and the staged cast remain in the image.", 60)
    elseif tab == "Saved" and ui.stageSavePage == "Scenes" then
        text("Scenes store layout, poses, light and backdrop. Loading resolves your current player, target and pet; it does not save another player's identity.", 84)
        local sceneName = W.Edit(env, parent, ui.sceneName or "My portrait", 0, y, 310, function(v) ui.sceneName = v end, 32); y = y - 40
        action("Save / replace scene", function() ui.sceneName = sceneName:GetText(); stage.Save(ui.sceneName) end)
        for _, name in ipairs(V.Keys(data.saved)) do
            local saved = name
            W.Button(env, parent, name, 0, y, 224, function() stage.Load(saved); ui.Build() end)
            W.Button(env, parent, "Delete", 232, y, 78, function() stage.Delete(saved); ui.Build() end); y = y - 40
        end
    elseif tab == "Saved" then
        section("SAVED LIGHTS")
        local lightName = W.Edit(env, parent, ui.lightName or "My light", 0, y, 310, function(v) ui.lightName = v end, 32); y = y - 40
        action("Save / replace light", function() ui.lightName = lightName:GetText(); stage.Save(ui.lightName, true) end)
        for _, name in ipairs(V.Keys(data.lights)) do
            local saved = name
            W.Button(env, parent, name, 0, y, 224, function() stage.Load(saved, true); ui.Build() end)
            W.Button(env, parent, "Delete", 232, y, 78, function() stage.Delete(saved, true); ui.Build() end); y = y - 40
        end
    end
    for _, id in ipairs(V.Keys(stage.failures)) do text("Actor " .. id .. ": " .. stage.failures[id], 66) end
    if stage.notice then text(stage.notice, 66) end
    return y
end
function U.Capture(runtime, env, parent, y, ui)
    local W = ns.Widgets
    W.Section(parent, "COMPOSITING PAIR", 0, y, 310); y = y - 40
    W.Text(parent, "Two separate screenshots: backdrop without actors, then the cast on green. Filters are omitted from this pair. These are not transparent images or a layered file.", 0, y, 310, 12, W.colors.muted); y = y - 94
    W.Button(env, parent, "Capture background + cast", 0, y, 310, function() runtime.portrait.CaptureLayers(); ui.Refresh() end); y = y - 40
    W.Button(env, parent, "Cancel compositing pair", 0, y, 310, function() runtime.portrait.CancelLayers(); ui.Refresh() end)
    return y - 48
end
