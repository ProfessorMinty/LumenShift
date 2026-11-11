local _, ns = ...
local S, W, C = {}, ns.Widgets, ns.PortraitConfig
ns.StageLayout = S

function S.Choices(env, parent, y, labels, current, choose)
    local width = 310 / #labels
    for i, label in ipairs(labels) do
        local choice = label
        local button = ns.PhotoStyle.Tab(env, parent, label, (i-1)*width, y, width,
            function() choose(choice) end)
        button.SetSelected(choice == current)
    end
    return y - 36
end

function S.Slider(env, parent, ui, y, key, label, limits, step, unit, get, set, spectrum)
    local slider = W.Slider(env, parent, label, 0, y, limits[1], limits[2], step, get, set, nil, 310, unit, spectrum)
    ui.sliders[key] = slider
    W.Script(slider, "OnMouseDown", function() ui.dragging = slider end)
    W.Script(slider, "OnMouseUp", function()
        ui.dragging = nil
        ui.Build() -- Scrubbing a playing pose also changes the play/pause button.
    end)
    return y - 35
end

-- The crosshair shows stage coordinates. A click commits both axes in one controller call.
local function plane(runtime, env, parent, ui, y, label, horizontal, vertical, get, apply, presets)
    W.Text(parent, label, 0, y, 310, 12, W.colors.muted)
    y = y - 22
    local width, height = 184, 86
    local pad = W.Button(env, parent, label, 0, y, width, function(b)
        local pos = ns.ReadOnly.Call(runtime.reader, env.GetCursorPosition)
        local left, top, scale = b:GetLeft(), b:GetTop(), b:GetEffectiveScale()
        if not pos or pos.n~=2 or not ns.Value.Finite(pos[1]) or not ns.Value.Finite(pos[2])
            or not left or not top or not scale or scale<=0 then return end
        local function value(fraction, bounds)
            fraction = math.max(0,math.min(1,fraction))
            return math.floor(100*(bounds[1]+fraction*(bounds[2]-bounds[1]))+.5)/100
        end
        apply(value((pos[1]/scale-left)/width,horizontal), value(1-(top-pos[2]/scale)/height,vertical))
    end, label, "quiet")
    pad:SetHeight(height); pad.label:Hide()
    W.Art(pad,"look-neutral",0,0,width,height,.50,"BORDER")
    local function line(x, top, w, h)
        local t=W.Texture(pad,"ARTWORK")
        t:SetPoint("TOPLEFT",pad,"TOPLEFT",x,-top);t:SetSize(w,h);t:SetColorTexture(.85,1,1,.32)
    end
    for i=1,3 do line(width*i/4,0,1,height) end
    line(0,height/2,width,1)
    local cross={}
    for i, size in ipairs({{15,3},{3,15},{13,1},{1,13}}) do
        local t=W.Texture(pad,"OVERLAY");t:SetSize(size[1],size[2])
        local v=i<=2 and .05 or 1;t:SetColorTexture(v,v,v,1);cross[i]=t
    end
    ui.RefreshStageMap=function()
        local x,v=get()
        for _,t in ipairs(cross) do
            t:ClearAllPoints();t:SetPoint("CENTER",pad,"TOPLEFT",
                (x-horizontal[1])/(horizontal[2]-horizontal[1])*width,
                -(vertical[2]-v)/(vertical[2]-vertical[1])*height)
        end
    end
    ui.RefreshStageMap()
    for i, preset in ipairs(presets) do
        local choice=preset
        local b=W.Button(env,parent,choice[1],194,y-(i-1)*30,116,function() apply(choice[2],choice[3]) end)
        b:SetHeight(26)
    end
    return y-height-8
end

function S.Lens(runtime,env,parent,ui,y)
    local stage=runtime.portrait
    if stage.backend.kind~="ModelScene" then
        W.Text(parent,"Use Actors → Transform to position individual models on this renderer.",0,y,310,13,W.colors.muted)
        return y-52
    end
    local function scene() return runtime.db.camera.portrait.scene end
    local function slider(key,label,step,unit)
        y=S.Slider(env,parent,ui,y,"stage_"..key,label,C.CameraRanges[key],step,unit,
            function() return scene()[key] end,function(v) return stage.SetScene(key,v) end)
    end
    if ui.cameraPage=="Lens" then
        W.Text(parent,"STAGE LENS",0,y,310,11,W.colors.muted);y=y-26
        slider("distance","Distance",.1,"");slider("height","Aim height",.1,"");slider("fov","Field of view",.1,"°")
    else
        y=plane(runtime,env,parent,ui,y,"Click to orbit the cast",C.CameraRanges.yaw,C.CameraRanges.pitch,
            function() return scene().yaw,scene().pitch end,stage.SetOrbit,
            {{"Front",0,0},{"Three-quarter",45,12},{"Profile",90,0}})
        slider("yaw","Orbit",1,"°");slider("pitch","Elevation",1,"°");slider("roll","Horizon roll",1,"°")
        W.Button(env,parent,"Level horizon",0,y,148,function() stage.SetScene("roll",0) end)
    end
    W.Button(env,parent,"Reset stage camera",ui.cameraPage=="Lens" and 0 or 157,y,153,stage.ResetCamera,nil,"quiet")
    return y-38
end

function S.Cast(runtime,env,parent,ui,y)
    local stage=runtime.portrait
    W.Text(parent,"ADD TO THE STAGE",0,y,310,11,W.colors.muted);y=y-25
    for i,item in ipairs({{"player","Add me"},{"target","Add target"},{"pet","Add pet"}}) do
        local unit=item[1]
        W.Button(env,parent,item[2],(i-1)*104,y,102,function() stage.Add(unit) end)
    end
    y=y-49
    for id=1,3 do
        local slot=stage.slots[id]
        if slot and slot.front then
            local index=id
            local b=W.Button(env,parent,id.."  "..slot.spec.unit,0,y,156,function()
                stage.selected=index;ui.actorTab="Poses";ui.Build(true)
            end,"Pose this actor")
            b.SetSelected(id==stage.selected)
            W.Button(env,parent,"Remove",180,y,126,function()
                if stage.Remove(index) and stage.selected==index then
                    for other=1,3 do
                        if stage.slots[other] and stage.slots[other].front then stage.selected=other;break end
                    end
                    ui.Build()
                end
            end,nil,"quiet")
            y=y-38
        end
    end
    return y
end

local favorites = { {0,"stand"},{97,"sit"},{115,"kneel"},{67,"wave"},{32,"cast"},{5,"run"} }
function S.Poses(runtime,env,parent,ui,y,selected)
    local stage,library=runtime.portrait,ns.PortraitLibrary
    y=S.Choices(env,parent,y,{"Quick picks","Browse","Playback"},ui.poseTool,function(tool)
        ui.poseTool=tool;ui.Build(true)
    end)
    local spec=selected.spec
    W.Text(parent,library.Pose(spec.animation)[2],0,y-4,178,16)
    W.Button(env,parent,spec.paused and "Play pose" or "Pause pose",186,y,122,function()
        stage.SetActor("paused",not selected.spec.paused)
    end)
    y=y-37
    if ui.poseTool=="Quick picks" then
        for i,item in ipairs(favorites) do
            local id=item[1];local name=library.Pose(id)[2]
            local b=ns.PhotoStyle.Swatch(env,parent,name,(i-1)%3*105,y-math.floor((i-1)/3)*66,100,41,
                "pose-"..item[2],function() stage.SetActor("animation",id) end,"Preview "..name)
            b.SetSelected(id==spec.animation)
        end
        return y-132
    elseif ui.poseTool=="Playback" then
        for _,item in ipairs({{"variation","Variation",0,5,1,""},{"time","Pose offset",0,10,.01,"s"},{"speed","Speed",.1,2,.05,"x"}}) do
            local key=item[1]
            if stage.backend.Supports(stage.backend.models[selected.front],key) then
                y=S.Slider(env,parent,ui,y,key,item[2],{item[3],item[4]},item[5],item[6],
                    function() return selected.spec[key] end,function(value) return stage.SetActor(key,value) end)
            end
        end
        return y
    end
    local field=W.Edit(env,parent,ui.poseQuery or "",0,y,110,function(value)
        ui.poseQuery=value;ui.posePage=1;ui.Build()
    end,40)
    W.Button(env,parent,"Search",114,y,68,function()
        ui.poseQuery=field:GetText();ui.posePage=1;ui.Build()
    end)
    W.Button(env,parent,ui.poseGroup or "All poses",187,y,123,function()
        ui.poseCategories=not ui.poseCategories;ui.Build()
    end,"Choose a pose category")
    y=y-36
    if ui.poseCategories then
        local groups={"All"};for _,group in ipairs(library.Groups) do groups[#groups+1]=group end
        for i,group in ipairs(groups) do
            local choice=group
            local b=W.Button(env,parent,group,(i-1)%2*156,y-math.floor((i-1)/2)*33,151,function()
                ui.poseGroup=choice;ui.posePage=1;ui.poseCategories=false;ui.Build()
            end)
            b.SetSelected((ui.poseGroup or "All")==group)
        end
        return y-100
    end
    local items=library.FindPoses(ui.poseGroup,ui.poseQuery)
    local pages=math.max(1,math.ceil(#items/6))
    local page=math.max(1,math.min(pages,ui.posePage or 1));ui.posePage=page
    for i=(page-1)*6+1,math.min(#items,page*6) do
        local id=items[i][1];local index=(i-1)%6
        local b=W.Button(env,parent,items[i][2],index%2*156,y-math.floor(index/2)*33,152,function()
            stage.SetActor("animation",id)
        end)
        b.SetSelected(id==spec.animation)
    end
    if #items==0 then W.Text(parent,"No matching poses.",0,y,310,12,W.colors.muted) end
    y=y-102
    local prev=W.Button(env,parent,"Previous",0,y,90,function() ui.posePage=page-1;ui.Build() end,nil,"quiet")
    local nextPage=W.Button(env,parent,"Next",216,y,90,function() ui.posePage=page+1;ui.Build() end,nil,"quiet")
    if page==1 then prev:Disable() end
    if page==pages then nextPage:Disable() end
    local label=W.Text(parent,page.." / "..pages,98,y-7,110,12,W.colors.muted);label:SetJustifyH("CENTER")
    return y-35
end

function S.SelectActor(stage,env,parent,ui,y)
    local slots={}
    for id=1,3 do if stage.slots[id] and stage.slots[id].front then slots[#slots+1]=id end end
    if #slots==0 then
        W.Text(parent,"Open Cast to add an actor.",0,y,310,13,W.colors.muted)
        return nil,y-40
    end
    if not stage.slots[stage.selected] or not stage.slots[stage.selected].front then stage.selected=slots[1] end
    W.Text(parent,"ACTOR",0,y-7,45,11,W.colors.muted)
    for i,id in ipairs(slots) do
        local index=id
        local b=ns.PhotoStyle.Tab(env,parent,id.."  "..stage.slots[id].spec.unit,48+(i-1)*87,y,85,function()
            stage.selected=index;ui.Build(true)
        end)
        b.SetSelected(id==stage.selected)
    end
    return stage.slots[stage.selected],y-32
end

function S.Transform(runtime,env,parent,ui,y,selected)
    local stage=runtime.portrait
    local model=stage.backend.models[selected.front]
    y=S.Choices(env,parent,y,{"Place","Turn","Gear"},ui.transformPage,function(page)
        ui.transformPage=page;ui.Build(true)
    end)
    local function slider(key,label,step,unit)
        if stage.backend.Supports(model,key) then
            y=S.Slider(env,parent,ui,y,key,label,C.ActorRanges[key],step,unit,
                function() return selected.spec[key] end,function(v) return stage.SetActor(key,v) end)
        else
            W.Text(parent,label.." unavailable on this model.",0,y,310,12,W.colors.muted);y=y-28
        end
    end
    if ui.transformPage=="Place" then
        y=plane(runtime,env,parent,ui,y,"Click to place the actor · front view",C.ActorRanges.x,C.ActorRanges.y,
            function() return selected.spec.x,selected.spec.y end, stage.PlaceActor,
            {{"Left",-1,0},{"Center",0,0},{"Right",1,0}})
        -- X and Y can also be typed exactly. The pad uses the same coordinates.
        for i,item in ipairs({{"x","X"},{"y","Y"}}) do
            local key=item[1];local x=(i-1)*153
            W.Text(parent,item[2],x,y-6,24,12,W.colors.muted)
            W.Edit(env,parent,selected.spec[key],x+28,y,100,function(s)
                local n=tonumber(s)
                if ns.Value.Finite(n) then stage.SetActor(key,n) end
                ui.Build()
            end)
        end
        y=y-34
        slider("depth","Depth",.01,"");slider("scale","Scale",.01,"x")
    elseif ui.transformPage=="Turn" then
        slider("yaw","Facing",1,"°");slider("pitch","Tilt",.1,"°");slider("roll","Roll",.1,"°")
    else
        for _,item in ipairs({{"sheathed","Sheathe weapons"},{"hideWeapons","Hide weapons"},{"transmog","Use transmog appearance"},
            {"hideHead","Hide helmet"},{"hideCloak","Hide cloak"}}) do
            local key=item[1]
            if stage.backend.Supports(model,key) then
                W.Toggle(env,parent,item[2],0,y,310,function() return selected.spec[key] end,function(v) stage.SetActor(key,v) end)
                y=y-35
            end
        end
    end
    return y
end
