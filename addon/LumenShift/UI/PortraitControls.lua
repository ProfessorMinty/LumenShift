local _, ns = ...
local U, W, C, V = {}, ns.Widgets, ns.PortraitConfig, ns.Value; ns.PortraitControls = U
function U.Build(runtime, env, parent, tab, ui, startY)
    local stage, data, y = runtime.portrait, runtime.db.camera.portrait, startY or 0
    local function text(value, height) W.Text(parent, value, 0, y, 310, 12, W.colors.muted); y = y - (height or 48) end
    local function section(value) W.Section(parent, value, 0, y, 310); y = y - 40 end
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
        y = ns.StageLightUI.Build(runtime, env, parent, ui)
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
    end
    if tab == "Pose" and ui.actorTab == "Cast" then
        for _, id in ipairs(V.Keys(stage.failures)) do text("Actor " .. id .. ": " .. stage.failures[id], 48) end
        if stage.notice then text(stage.notice, 48) end
    end
    return y
end
