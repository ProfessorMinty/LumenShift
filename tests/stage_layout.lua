-- Exercise the visible editor in a standalone client fixture.
return function(make, eq, test)
    local function click(f, label)
        f.mock.Click(label)
        assert(not f.ui.building, "Interrupted panel build: "..label)
    end
    local function stage(f)
        click(f, "Portrait Stage"); f.flush()
        assert(f.p.active and f.p.slots[1].front)
    end
    local function button(f, label)
        for _, b in ipairs(f.mock.nodes) do
            if b.kind == "Button" and b:IsVisible() and b.label and b.label:GetText() == label then return b end
        end
    end
    local function moveOnMap(f, label, across, up)
        local b = assert(button(f, label))
        b.GetLeft = function() return 20 end
        b.GetTop = function() return 100 end
        b.GetEffectiveScale = function() return 2 end
        f.env.GetCursorPosition = function() return 2*(20 + across*b:GetWidth()), 2*(100 - (1-up)*b:GetHeight()) end
        click(f, label)
    end
    test("SW01 camera, cast, posing and lighting pages fit both inspector sizes", function()
        for _, size in ipairs({{1280,800},{600,400}}) do
            local f = make()
            f.env.UIParent:SetSize(unpack(size)); f.c.Show()
            local function fits(label)
                click(f, label)
                eq(f.ui.scrollbar.maximum, 0, label); eq(f.ui.scroll:GetVerticalScroll(), 0, label)
                eq(f.ui.scrollbar:IsShown(), false, label)
            end
            for _, label in ipairs({"Position","Framing","Guides","Offset","Quality"}) do fits(label) end
            stage(f)
            assert(f.p.Add("target")); f.flush(); assert(f.p.Add("pet")); f.flush()
            for _, label in ipairs({"Camera","Position","Lens","Framing","Actors","Cast","Poses","Browse","Playback",
                "Quick picks","Transform","Place","Turn","Gear","Light","Rig","Direction","Color"}) do fits(label) end
            eq(f.env.Narci, nil); eq(#f.calls, 0)
        end
    end)
    test("SW02 orbit map and views move the native lens in one update and preserve roll and distance", function()
        local f = make(); stage(f)
        assert(f.p.SetScene("distance", 8)); assert(f.p.SetScene("roll", 22))
        local scene, count = f.r.db.camera.portrait.scene, 0
        local apply = f.scene.SetCameraOrientationByYawPitchRoll
        f.scene.SetCameraOrientationByYawPitchRoll = function(s, ...)
            count=count+1; apply(s, ...)
        end
        moveOnMap(f, "Click to orbit the cast", .75, .25)
        eq(count, 1); eq(scene.yaw, 90); eq(scene.pitch, -40)
        for _, view in ipairs({{"Three-quarter",45,12},{"Profile",90,0},{"Front",0,0}}) do
            click(f, view[1]); eq(scene.yaw, view[2]); eq(scene.pitch, view[3])
            eq(scene.roll, 22); eq(scene.distance, 8); eq(f.scene.cameraAngles[2], math.rad(view[3]))
        end
        click(f,"Lens"); assert(f.ui.sliders.stage_fov); eq(f.ui.sliders.stage_yaw,nil)
        eq(#f.calls, 0)
    end)
    test("SW03 refusing an orbit map edit restores both angles and the native view", function()
        local f=make(); stage(f); click(f,"Three-quarter")
        local apply=f.scene.SetCameraOrientationByYawPitchRoll
        f.scene.SetCameraOrientationByYawPitchRoll=function(s,y,p,r)
            if p<0 then error("rejected") end
            apply(s,y,p,r)
        end
        moveOnMap(f,"Click to orbit the cast",.25,0)
        local scene=f.r.db.camera.portrait.scene
        eq(scene.yaw,45); eq(scene.pitch,12); eq(f.ui.sliders.stage_pitch:GetValue(),12)
        eq(f.scene.cameraAngles[1],math.pi+math.rad(45)); eq(#f.calls,0)
    end)
    test("SW04 placement moves only the selected actor and restores both coordinates on failure", function()
        local f=make(); stage(f); click(f,"Actors"); click(f,"Cast"); click(f,"Add target"); f.flush()
        click(f,"Transform"); click(f,"2  target")
        local actor, label = f.front(2), "Click to place the actor · front view"
        local apply,count=actor.SetPosition,0
        actor.SetPosition=function(s,d,x,y)
            count=count+1
            if x < -2 then error("rejected") end
            apply(s,d,x,y)
        end
        moveOnMap(f,label,.75,.8); eq(count,1)
        eq(actor.position[2],-1.5); eq(actor.position[3],2)
        eq(f.p.slots[1].spec.x,0); eq(f.p.slots[1].spec.y,0)
        moveOnMap(f,label,1,0); eq(count,3)
        eq(actor.position[2],-1.5); eq(actor.position[3],2)
        eq(f.p.slots[2].spec.x,1.5); eq(f.p.slots[2].spec.y,2)
        click(f,"Center"); eq(actor.position[2],0); eq(actor.position[3],0); eq(#f.calls,0)
    end)
    test("SW05 illustrated picks, playback and category browsing control the selected model", function()
        local f=make(); stage(f); click(f,"Actors")
        for _, pick in ipairs({{"Stand",0},{"Sit",97},{"Kneel",115},{"Wave",67},{"Cast spell",32},{"Run",5}}) do
            click(f,pick[1]); eq(f.front().anim,pick[2]); eq(button(f,pick[1]).selected,true)
        end
        click(f,"Play pose"); eq(f.front().paused,false)
        click(f,"Playback")
        local scrub=f.ui.sliders.time; scrub.scripts.OnMouseDown(scrub); scrub:SetValue(1.5)
        eq(f.ui.sliders.time,scrub); scrub.scripts.OnMouseUp(scrub)
        eq(f.front().paused,true); eq(f.front().offset,1.5); assert(button(f,"Play pose"))
        f.ui.sliders.speed:SetValue(.5); eq(f.front().speed,.5)
        click(f,"Browse"); click(f,"All poses"); click(f,"Movement"); click(f,"Next"); click(f,"Sprint")
        eq(f.front().anim,143); eq(f.front().offset,0); eq(f.ui.scroll:GetVerticalScroll(),0)
        click(f,"Movement"); click(f,"All"); click(f,"Next"); eq(f.ui.posePage,2)
        local field
        for _,b in ipairs(f.mock.nodes) do if b.kind=="EditBox" and b:IsVisible() and b:GetWidth()==110 then field=b end end
        assert(field); field:SetText("dance"); click(f,"Search"); eq(f.ui.posePage,1); click(f,"Dance")
        eq(f.front().anim,69); eq(#f.calls,0)
    end)
    test("SW06 fallback gives actor placement and poses without advertising a stage lens or timeline", function()
        local f=make(true); stage(f)
        eq(button(f,"Profile"),nil); click(f,"Actors"); click(f,"Wave"); eq(f.front().anim,67)
        click(f,"Playback"); assert(f.ui.sliders.variation); eq(f.ui.sliders.time,nil); eq(f.ui.sliders.speed,nil)
        click(f,"Transform"); click(f,"Right"); eq(f.front().position[2],-1)
        click(f,"World Photo"); eq(button(f,"Profile"),nil); assert(button(f,"Orbit left"))
        eq(f.env.Narci,nil); eq(#f.calls,0)
    end)
end
