local _, ns = ...
local S, W, C = {}, ns.Widgets, ns.PortraitConfig
ns.StageLightUI = S

local colors = {
    {"White",1,1,1}, {"Amber",1,.55,.22}, {"Rose",1,.48,.63},
    {"Mint",.50,1,.74}, {"Sky",.45,.70,1}, {"Violet",.73,.52,1},
}
local rigs = {{"neutral","Neutral"}, {"soft","Softbox"}, {"ember","Firelight"}, {"moon","Moon rim"}}

local function heading(parent, label, y)
    W.Text(parent,label,0,y,145,14)
    local value=W.Text(parent,"",145,y-1,165,12,W.colors.muted)
    value:SetJustifyH("RIGHT")
    return value
end

-- One wrap around the stage: front at the center, back at either end.
local function directionPad(runtime, env, parent, ui, change)
    local caption=heading(parent,"Drag to aim",0)
    local pad=W.Button(env,parent,"Aim the light",0,-22,310,nil,"Drag sideways around the cast. Drag up to raise the light.")
    pad:SetHeight(82); pad.label:Hide()
    local margin, width, height = 8, 294, 66
    W.Rule(pad,margin,-41,width,W.colors.border)
    for i=0,4 do W.Rule(pad,margin+i*width/4,-margin,1,W.colors.border,height) end
    for i,label in ipairs({"Back","Left","Front","Right","Back"}) do
        local x=math.max(0,math.min(266,margin+(i-1)*width/4-22))
        local text=W.Text(parent,label,x,-108,44,11,W.colors.muted)
        text:SetJustifyH(i==1 and "LEFT" or i==5 and "RIGHT" or "CENTER")
    end
    local halo=W.Art(pad,"photo-glow-5",0,0,42,34,.75)
    local marker=W.Art(pad,"switch-knob",0,0,13,13,1,"OVERLAY")
    local function draw(light)
        local x=margin+(light.azimuth+180)*width/360
        local y=-margin-(80-light.elevation)*height/160
        marker:ClearAllPoints(); marker:SetPoint("CENTER",pad,"TOPLEFT",x,y)
        halo:ClearAllPoints(); halo:SetPoint("CENTER",marker,"CENTER")
        halo:SetVertexColor(light.red,light.green,light.blue)
        local az,el=light.azimuth,light.elevation
        local side=az==0 and "Front" or math.abs(az)==180 and "Back" or math.abs(az).."° "..(az<0 and "left" or "right")
        local heightLabel=el==0 and "level" or math.abs(el).."° "..(el>0 and "up" or "down")
        caption:SetText(side.." · "..heightLabel)
    end
    local function sample()
        local pos=ns.ReadOnly.Call(runtime.reader,env.GetCursorPosition)
        local left,top,scale=pad:GetLeft(),pad:GetTop(),pad:GetEffectiveScale()
        if not pos or not ns.Value.Finite(pos[1]) or not ns.Value.Finite(pos[2]) or not left or not top or not scale or scale<=0 then return false end
        local across=math.max(0,math.min(1,(pos[1]/scale-left-margin)/width))
        local down=math.max(0,math.min(1,(top-pos[2]/scale-margin)/height))
        return change({azimuth=math.floor(across*360-180+.5),elevation=math.floor(80-down*160+.5)})
    end
    local gesture
    local function stop()
        gesture=nil
        if ui.dragging==pad then ui.dragging=nil end
    end
    W.Script(pad,"OnMouseDown",function(_,which)
        if which~="LeftButton" then return end
        local id={}
        gesture,ui.dragging=id,pad
        if sample()==false then stop(); return end
        local function tick()
            if gesture~=id then return end
            if ui.dragging~=pad or not pad:IsVisible() or not runtime.portrait.active then stop(); return end
            local held=ns.ReadOnly.Call(runtime.reader,env.IsMouseButtonDown,"LeftButton")
            if sample()==false or (held and held[1]==false) then stop(); return end
            if not ns.ReadOnly.Call(runtime.reader,env.C_Timer and env.C_Timer.After,1/30,tick) then stop() end
        end
        if not ns.ReadOnly.Call(runtime.reader,env.C_Timer and env.C_Timer.After,1/30,tick) then stop() end
    end)
    W.Script(pad,"OnMouseUp",function(_,which)
        if which=="LeftButton" and ui.dragging==pad then sample(); stop() end
    end)
    W.Script(pad,"OnHide",stop)
    return draw
end

local function palette(env,parent,y,change)
    local caption=heading(parent,"Key color",y)
    local buttons={}
    for i,color in ipairs(colors) do
        local b=ns.PhotoStyle.Tab(env,parent,color[1],(i-1)*52,y-25,50,function()
            change({red=color[2],green=color[3],blue=color[4]})
        end)
        b:SetHeight(31); b.label:ClearAllPoints(); b.label:SetPoint("TOP",b,"TOP",0,-10)
        W.Rule(b,5,-1,40,{color[2],color[3],color[4],1},6)
        buttons[i]=b
    end
    return function(light)
        local match
        for i,color in ipairs(colors) do
            local selected=light.red==color[2] and light.green==color[3] and light.blue==color[4]
            buttons[i].SetSelected(selected)
            if selected then match=color[1] end
        end
        caption:SetText(match or string.format("#%02X%02X%02X",math.floor(light.red*255+.5),
            math.floor(light.green*255+.5),math.floor(light.blue*255+.5)))
    end
end

function S.Build(runtime,env,parent,ui)
    local stage=runtime.portrait
    if not stage.backend.CanLight() then
        W.Text(parent,"This renderer cannot adjust model lighting. You can still pose and photograph the cast.",0,0,310,13,W.colors.muted)
        return -56
    end
    local function read() return runtime.db.camera.portrait.scene.light end
    local function change(fields)
        local light=read()
        local changed=false
        for key,v in pairs(fields) do if light[key]~=v then changed=true; break end end
        if not changed then return true end
        local nextLight=ns.Value.Copy(light)
        for key,v in pairs(fields) do nextLight[key]=v end
        return stage.SetLight(nextLight)==true
    end
    local function slider(key,label,y,percent,spectrum)
        local scale=percent and 100 or 1
        local limits=C.LightRanges[key]
        ns.StageLayout.Slider(env,parent,ui,y,"light_"..key,label,{limits[1]*scale,limits[2]*scale},1,percent and "%" or "°",
            function() return read()[key]*scale end,function(v) return change({[key]=v/scale}) end,spectrum)
    end
    local page=ui.lightPage
    if page=="Rig" then
        local aim=directionPad(runtime,env,parent,ui,change)
        local color=palette(env,parent,-138,change)
        slider("diffuse","Key intensity",-213,true)
        slider("ambient","Shadow fill",-251,true)
        ui.RefreshStageLight=function() local light=read(); aim(light); color(light) end
        return -282
    elseif page=="Color" then
        local color=palette(env,parent,0,change)
        local chip=env.CreateFrame("Frame",nil,parent)
        local sample=W.Fill(chip)
        chip:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-72); chip:SetSize(310,44)
        ui.RefreshStageLight=function()
            local light=read()
            color(light); sample:SetColorTexture(light.red,light.green,light.blue,1)
        end
        for i,key in ipairs({"red","green","blue"}) do
            local channel={0,0,0}; channel[i]=1
            slider(key,key:sub(1,1):upper()..key:sub(2),-138-(i-1)*41,true,{{0,0,0},channel})
        end
        return -254
    elseif page=="Direction" then
        W.Text(parent,"Aim from",0,0,310,14)
        local buttons={}
        for i,point in ipairs({{"Front",0},{"Right",90},{"Back",180},{"Left",-90}}) do
            buttons[point[2]]=ns.PhotoStyle.Tab(env,parent,point[1],(i-1)*78,-24,76,function() change({azimuth=point[2]}) end)
        end
        ui.RefreshStageLight=function()
            local azimuth=read().azimuth
            for angle,b in pairs(buttons) do b.SetSelected(angle==azimuth or (angle==180 and azimuth==-180)) end
        end
        slider("azimuth","Around cast",-73,false)
        slider("elevation","Elevation",-119,false)
        W.Text(parent,"Angles follow the stage. At 0° the light comes from the front. Positive elevation raises it above the cast.",0,-167,310,12,W.colors.muted)
        return -215
    end
    for i,rig in ipairs(rigs) do
        local light=C.LightPreset(rig[1])
        local b=W.Button(env,parent,rig[2],(i-1)%2*158,-math.floor((i-1)/2)*83,152,function() stage.SetLight(light) end)
        b:SetHeight(75); b.label:ClearAllPoints(); b.label:SetPoint("BOTTOM",b,"BOTTOM",0,6)
        b.label:SetJustifyH("CENTER")
        b.picture=W.Texture(b,"ARTWORK"); b.picture:SetPoint("TOP",b,"TOP",0,-5); b.picture:SetSize(140,43)
        ns.StageSavedUI.InitLightCard(b); ns.StageSavedUI.DrawLightCard(b,light)
        local selected=true
        for k,v in pairs(light) do if read()[k]~=v then selected=false; break end end
        b.SetSelected(selected)
    end
    W.Text(parent,"Choose a preset to replace the current direction, color, key and fill together.",0,-176,310,12,W.colors.muted)
    return -220
end
