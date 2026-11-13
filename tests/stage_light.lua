return function(make,eq,test)
    local function click(f,label) f.mock.Click(label); assert(not f.ui.building,label) end
    local function button(f,label)
        for _,b in ipairs(f.mock.nodes) do
            if b.kind=="Button" and b:IsVisible() and b.label and b.label:GetText()==label then return b end
        end
    end
    local function start(fallback)
        local f=make(fallback); click(f,"Portrait Stage"); f.flush(); click(f,"Light")
        f.sceneData=f.r.db.camera.portrait.scene
        return f
    end
    local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a).." differs from "..tostring(b)) end
    local function aim(f)
        local pad=assert(button(f,"Aim the light"))
        pad.GetLeft=function() return 30 end
        pad.GetTop=function() return 150 end
        pad.GetEffectiveScale=function() return 1.5 end
        local function point(across,high)
            f.env.GetCursorPosition=function() return (30+8+294*across)*1.5,(150-8-66*(1-high))*1.5 end
        end
        return pad,point
    end
    local function native(f)
        local l=f.sceneData.light
        local az,el=math.rad(l.azimuth),math.rad(l.elevation)
        local x,y,z=-math.cos(az)*math.cos(el),-math.sin(az)*math.cos(el),-math.sin(el)
        if f.scene then
            near(f.scene.direction[1],x); near(f.scene.direction[2],y); near(f.scene.direction[3],z)
            near(f.scene.diffuse[1],l.red*l.diffuse); near(f.scene.diffuse[2],l.green*l.diffuse)
            near(f.scene.diffuse[3],l.blue*l.diffuse); near(f.scene.ambient[1],l.ambient)
        else
            for _,model in ipairs(f.p.backend.models) do
                local v=model.light
                near(v.point.x,x); near(v.point.y,y); near(v.point.z,z)
                near(v.diffuseColor.r,l.red); near(v.diffuseColor.g,l.green); near(v.diffuseColor.b,l.blue)
                near(v.diffuseIntensity,l.diffuse); near(v.ambientIntensity,l.ambient)
            end
        end
        eq(#f.calls,0)
    end
    test("PLT01 all lighting pages fit both sizes; browsing makes no stage or graphics edits",function()
        local f=start(); local edits=0
        local apply=f.p.backend.Light
        f.p.backend.Light=function(...) edits=edits+1; return apply(...) end
        for _,size in ipairs({{1280,800},{600,400}}) do
            f.env.UIParent:SetSize(unpack(size)); f.c.Show()
            for _,label in ipairs({"Direction","Color","Presets","Rig"}) do
                click(f,label); eq(f.ui.scrollbar.maximum,0,label); eq(f.ui.scrollbar:IsShown(),false,label)
            end
            assert(button(f,"Aim the light") and button(f,"Amber") and f.ui.sliders.light_diffuse and f.ui.sliders.light_ambient)
        end
        eq(edits,0); eq(f.env.Narci,nil); eq(#f.calls,0)
    end)
    test("PLT02 held map gestures reach both renderers before release, clamp edges and skip duplicate positions",function()
        for _,fallback in ipairs({false,true}) do
            local f=start(fallback); local pad,point=aim(f); local edits=0
            local apply=f.p.backend.Light
            f.p.backend.Light=function(...) edits=edits+1; return apply(...) end
            point(.5,.5); pad.scripts.OnMouseDown(pad,"LeftButton"); eq(f.sceneData.light.azimuth,0); native(f)
            point(.75,.75); eq(edits,1); near(f.mock.timers[1][1],1/30)
            f.tick(); eq(edits,2); eq(f.sceneData.light.azimuth,90); eq(f.sceneData.light.elevation,40); native(f)
            f.tick(); eq(edits,2); eq(button(f,"Aim the light"),pad)
            point(-3,5); pad.scripts.OnMouseUp(pad,"LeftButton"); eq(edits,3); eq(f.sceneData.light.azimuth,-180)
            eq(f.sceneData.light.elevation,80); native(f); f.flush(); eq(edits,3); eq(f.ui.dragging,nil)
        end
    end)
    test("PLT03 key, fill and custom RGB reach the staged cast while held and keep pose and framing",function()
        for _,fallback in ipairs({false,true}) do
            local f=start(fallback); local front=f.front()
            click(f,"Amber"); eq(f.sceneData.light.green,.55); eq(f.sceneData.light.azimuth,-35); native(f)
            local function drag(key,values,scale)
                local slider=f.ui.sliders["light_"..key]; slider.scripts.OnMouseDown(slider)
                for _,v in ipairs(values) do slider:SetValue(v); near(f.sceneData.light[key],v/scale); native(f)
                    eq(f.ui.sliders["light_"..key],slider); eq(f.front(),front)
                end
                slider.scripts.OnMouseUp(slider)
            end
            drag("diffuse",{0,48,200},100); drag("ambient",{0,25,100},100)
            click(f,"Color"); drag("red",{10,60,97},100); drag("blue",{7,23,64},100)
            drag("green",{5,70,83},100)
            eq(f.sceneData.light.diffuse,2); eq(f.sceneData.light.ambient,1)
            eq(f.sceneData.actors[1].animation,0); eq(f.sceneData.yaw,0); eq(#f.calls,0)
        end
    end)
    test("PLT04 colors change only RGB; presets recall complete rigs and custom settings survive save and apply",function()
        local f=start()
        for _,pair in ipairs({{"Neutral","neutral"},{"Softbox","soft"},{"Firelight","ember"},{"Moon rim","moon"}}) do
            click(f,"Presets"); click(f,pair[1]); assert(button(f,pair[1]).selected)
            for k,v in pairs(f.ns.PortraitConfig.LightPreset(pair[2])) do near(f.sceneData.light[k],v) end
            native(f)
        end
        click(f,"Rig"); click(f,"Violet"); click(f,"Direction"); click(f,"Back")
        eq(f.sceneData.light.azimuth,180); eq(f.sceneData.light.elevation,40)
        eq(f.sceneData.light.diffuse,1.2); eq(f.sceneData.light.red,.73)
        local edit=f.ui.sliders.light_elevation.edit; edit:SetText("-32"); edit.scripts.OnEnterPressed(edit)
        eq(f.sceneData.light.elevation,-32); assert(f.p.Save("Moon gel",true))
        click(f,"Presets"); click(f,"Neutral"); assert(f.p.Load("Moon gel",true)); click(f,"Rig")
        eq(f.sceneData.light.elevation,-32); eq(button(f,"Violet").selected,true); native(f)
    end)
    test("PLT05 failed live edit retains last accepted light, stops sampling, and leaves the next gesture usable",function()
        local f=start(); local pad,point=aim(f)
        local previous=f.scene.SetLightDirection
        f.scene.SetLightDirection=function(scene,x,y,z)
            if y<-.90 then error("rejected direction") end; previous(scene,x,y,z)
        end
        point(.5,.5); pad.scripts.OnMouseDown(pad,"LeftButton")
        point(.75,.5); f.tick()
        eq(#f.mock.timers,0); eq(f.ui.dragging,nil); eq(f.sceneData.light.azimuth,0); native(f)
        assert(f.ui.status:GetText():find("lighting unavailable",1,true))
        point(.25,.5); pad.scripts.OnMouseDown(pad,"LeftButton"); pad.scripts.OnMouseUp(pad,"LeftButton")
        eq(f.sceneData.light.azimuth,-90); native(f)
    end)
    test("PLT06 hiding, navigating or switching to World Photo stops map input and leaves other lighting untouched",function()
        local f=start(); local pad,point=aim(f); point(.25,.5); pad.scripts.OnMouseDown(pad,"LeftButton")
        point(.75,1)
        click(f,"Color"); f.flush(); eq(f.sceneData.light.azimuth,-90)
        click(f,"Rig"); pad,point=aim(f); point(.5,.5); pad.scripts.OnMouseDown(pad,"LeftButton")
        pad:Hide(); f.flush(); eq(f.ui.dragging,nil)
        click(f,"World Photo"); f.flush(); click(f,"Light"); assert(button(f,"Tone")); eq(button(f,"Amber"),nil)
        eq(f.sceneData.light.azimuth,0); eq(#f.calls,0)
    end)
    test("PLT08 release outside the pad commits the last point and stops the gesture timer",function()
        local f=start(); local pad,point=aim(f); local held=true
        f.env.IsMouseButtonDown=function(which) eq(which,"LeftButton"); return held end
        point(.5,.5); pad.scripts.OnMouseDown(pad,"LeftButton")
        point(2,.75); held=false; f.tick()
        eq(f.sceneData.light.azimuth,180); eq(f.sceneData.light.elevation,40); native(f)
        eq(#f.mock.timers,0); eq(f.ui.dragging,nil)
    end)
    test("PLT07 unavailable renderer and invalid pointer reads stay local to the light tool",function()
        local f=start(); local pad,point=aim(f); f.env.GetCursorPosition=function() return "SECRET",0 end
        pad.scripts.OnMouseDown(pad,"LeftButton"); pad.scripts.OnMouseUp(pad,"LeftButton"); eq(f.sceneData.light.azimuth,-35)
        f.scene.SetLightDirection=nil; click(f,"Rig"); eq(button(f,"Aim the light"),nil); eq(f.ui.sliders.light_ambient,nil)
        click(f,"Capture"); assert(button(f,"Pair")); eq(#f.calls,0)
    end)
end
