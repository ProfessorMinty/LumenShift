local _, ns = ...
local U, W, C, V = {}, ns.Widgets, ns.PortraitConfig, ns.Value; ns.PortraitControls = U
function U.Build(runtime, env, parent, tab, ui, startY)
    local stage, data, y = runtime.portrait, runtime.db.camera.portrait, startY or 0
    local function text(value, height) W.Text(parent, value, 0, y, 310, 12, W.colors.muted); y = y - (height or 48) end
    local function section(value) W.Section(parent, value, 0, y, 310); y = y - 40 end
    local function action(label, fn)
        W.Button(env, parent, label, 0, y, 310, function() fn(); ui.Build() end); y = y - 40
    end
    if tab == "Pose" then
        if ui.actorTab == "Cast" then
            y=ns.StageLayout.Cast(runtime,env,parent,ui,y)
        else
            local selected
            selected,y=ns.StageLayout.SelectActor(stage,env,parent,ui,y)
            if selected then
                if ui.actorTab=="Transform" then y=ns.StageLayout.Transform(runtime,env,parent,ui,y,selected)
                elseif ui.actorTab=="Poses" then y=ns.StageLayout.Poses(runtime,env,parent,ui,y,selected)
                else
                    ui.libraryY=y
                    y=ns.PortraitLibraryUI.Build(runtime,env,parent,ui,y,selected)
                end
            end
        end
    elseif tab == "Light" then
        section("MODEL LIGHT")
        if not stage.backend.CanLight() then
            text("Model lighting is unavailable on this client. Actors, backgrounds, filters and capture remain available; your saved lights are kept.", 80)
            return y
        end
        if ui.lightPage=="Rig" then
            for i,item in ipairs({{"neutral","Neutral"},{"soft","Softbox"},{"ember","Firelight"},{"moon","Moon rim"}}) do
                local id=item[1]
                W.Button(env,parent,item[2],(i-1)%2*156,y-math.floor((i-1)/2)*34,152,function()
                    stage.SetLight(C.LightPreset(id))
                end)
            end
            y=y-78
        end
        local controls=({Rig={{"ambient","Ambient fill"},{"diffuse","Key intensity"}},
            Direction={{"azimuth","Direction"},{"elevation","Elevation"}},
            Color={{"red","Red"},{"green","Green"},{"blue","Blue"}}})[ui.lightPage]
        for _,item in ipairs(controls) do
            local key=item[1];local degrees=ui.lightPage=="Direction"
            y=ns.StageLayout.Slider(env,parent,ui,y,"light_"..key,item[2],C.LightRanges[key],degrees and 1 or .01,degrees and "°" or "",
                function() return data.scene.light[key] end,function(value)
                    local light=V.Copy(data.scene.light);light[key]=value;return stage.SetLight(light)
                end)
        end
    elseif tab == "Frame" and (ui.cameraPage=="Position" or ui.cameraPage=="Lens") then
        y=ns.StageLayout.Lens(runtime,env,parent,ui,y)
    elseif tab == "Frame" then
        section("BACKDROP")
        for i,choice in ipairs(C.Backgrounds) do
            local id=choice[1]
            local b=W.Button(env,parent,choice[2],(i-1)%3*104,y-math.floor((i-1)/3)*34,101,function()
                stage.SetScene("background",id)
            end)
            b.SetSelected(data.scene.background==id)
            if C.Colors[id] then W.Rule(b,4,-25,92,{unpack(C.Colors[id])},3) end
        end
        y=y-74
        section("FRAMING")
        W.Toggle(env, parent, "Rule of thirds", 0, y, 310, function() return runtime.db.camera.thirds end,
            function(v) runtime.db.camera.thirds = v; runtime.composition.Show() end); y = y - 46
        local range = ns.PhotoConfig.Ranges.letterbox
        y=ns.StageLayout.Slider(env,parent,ui,y,"letterbox","Letterbox height",range,.01,"", function() return runtime.db.camera.editor.look.letterbox end,
            function(v) return runtime.photoEditor.Set("letterbox", v) end)
        text("H hides the guides. Letterbox bars stay in the shot.", 36)
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
    if tab == "Pose" and ui.actorTab == "Cast" then
        for _, id in ipairs(V.Keys(stage.failures)) do text("Actor " .. id .. ": " .. stage.failures[id], 48) end
        if stage.notice then text(stage.notice, 48) end
    end
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
