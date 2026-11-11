return function(make,eq,test)
    local function button(f,label)
        for _,node in ipairs(f.mock.nodes) do
            if node.kind=="Button" and node:IsVisible() and node.label and node.label:GetText()==label then return node end
        end
    end
    local function click(f,label)
        local b=assert(button(f,label),"Missing "..label); assert(b:IsEnabled(),label)
        b.scripts.OnClick(b,"LeftButton"); assert(not f.ui.building,"Interrupted stage library build")
    end
    local function field(f)
        for _,node in ipairs(f.mock.nodes) do if node.kind=="EditBox" and node:IsVisible() then return node end end
        error("Missing stage library text field")
    end
    local function open(f)
        click(f,"Portrait Stage"); f.flush(); click(f,"Saved")
    end
    local function save(f,name,kind)
        click(f,"Save current"); field(f):SetText(name); click(f,"Save "..kind)
        assert(button(f,name).selected)
    end
    local function fits(f)
        eq(f.ui.scrollbar.maximum,0); eq(f.ui.scrollbar:IsShown(),false); eq(f.ui.scroll:GetVerticalScroll(),0)
    end
    test("SS01 same-name scene and lighting saves recall their own settings through the visible controls",function()
        local f=make(); open(f); local scene=f.r.db.camera.portrait.scene
        local ember=f.ns.PortraitConfig.LightPreset("ember")
        local soft=f.ns.PortraitConfig.LightPreset("soft")
        assert(f.p.SetLight(ember)); assert(f.p.SetActor("animation",67)); assert(f.p.PlaceActor(-1,.5))
        assert(f.p.SetScene("roll",22)); assert(f.p.SetScene("background","gray"))
        save(f,"Campfire","scene"); assert(f.p.SetLight(soft)); click(f,"Lights"); save(f,"Campfire","lighting setup")
        assert(f.p.SetScene("roll",0)); assert(f.p.SetScene("background","blue")); assert(f.p.PlaceActor(1,0))
        assert(f.p.SetActor("animation",0)); assert(f.p.SetLight(ember))
        local front=f.front(); local calls=#f.modelCalls
        click(f,"Apply lighting setup"); eq(f.ui.status:GetText(),"Lighting setup applied.")
        eq(scene.light.diffuse,soft.diffuse); eq(f.scene.diffuse[1],soft.red*soft.diffuse)
        eq(front,f.front()); eq(#f.modelCalls,calls); eq(scene.background,"blue"); eq(scene.roll,0); eq(front.anim,0)
        click(f,"Scenes"); field(f):SetText("FIRE"); click(f,"Campfire"); eq(f.front().anim,0)
        click(f,"Apply scene"); eq(f.ui.status:GetText(),"Applying scene…"); eq(button(f,"Apply scene"):IsEnabled(),false)
        f.flush(); eq(f.ui.status:GetText(),"Scene applied."); eq(f.front().anim,67); eq(f.front().position[2],1)
        eq(scene.roll,22); eq(scene.background,"gray"); eq(scene.light.diffuse,ember.diffuse)
        eq(f.env.Narci,nil); eq(#f.calls,0); eq(f.captures,0)
    end)
    test("SS02 full scene and light banks survive reload and fit both panel sizes without scrolling",function()
        local seed=make(); seed.start()
        for i=1,8 do
            assert(seed.p.SetActor("x",i/4)); assert(seed.p.Save("Scene "..i))
            assert(seed.p.Save("Rig "..i,true))
        end
        local f=make(false,seed.ns.Value.Copy(seed.r.db)); open(f)
        local before=#f.modelCalls
        for _,size in ipairs({{1280,800},{600,400}}) do
            f.env.UIParent:SetSize(unpack(size)); f.c.Show()
            for _,bank in ipairs({{"Scenes","Scene "},{"Lights","Rig "}}) do
                click(f,bank[1])
                while button(f,"Previous") and button(f,"Previous"):IsEnabled() do click(f,"Previous") end
                for first=1,8,3 do
                    fits(f)
                    for i=1,8 do eq(button(f,bank[2]..i)~=nil,i>=first and i<first+3) end
                    if first<7 then click(f,"Next") end
                end
                click(f,"Save current"); fits(f); click(f,"Back")
            end
        end
        eq(before,#f.modelCalls); eq(#f.calls,0); eq(#f.mock.timers,0)
    end)
    test("SS03 literal search, paging and model callbacks preserve focus and keep library drafts independent",function()
        local f=make(); open(f); save(f,"Fire [%]","scene"); save(f,"Quiet","scene")
        click(f,"Lights"); save(f,"Sun","lighting setup"); click(f,"Scenes")
        local s=field(f); s:SetText("[%]"); eq(button(f,"Quiet"),nil); assert(button(f,"Fire [%]").selected)
        click(f,"Apply scene"); s:SetFocus(); s:SetText("qui"); f.flush()
        eq(field(f),s); eq(f.mock.focus,s); eq(s:GetText(),"qui"); assert(button(f,"Quiet").selected)
        click(f,"Lights"); field(f):SetText("sun"); click(f,"Save current"); field(f):SetText("Draft")
        click(f,"Scenes"); eq(field(f):GetText(),"qui"); field(f):SetText("missing"); eq(button(f,"Apply scene"),nil)
        click(f,"Clear search"); eq(field(f):GetText(),""); assert(button(f,"Quiet"))
        click(f,"Lights"); eq(field(f):GetText(),"Draft"); click(f,"Back"); eq(field(f):GetText(),"sun")
        eq(f.r.db.camera.portrait.lights.Draft,nil); eq(#f.calls,0)
    end)
    test("SS04 replacement at capacity, deletion and reveal operate only on the selected portrait bank",function()
        local f=make(); open(f)
        for _,spec in ipairs({{"Scenes","scene",false},{"Lights","lighting setup",true}}) do
            click(f,spec[1])
            for i=1,7 do assert(f.p.Save("Entry "..i,spec[3])) end
            field(f):SetText("Entry 1"); save(f,"Zebra",spec[2]); eq(field(f):GetText(),""); assert(button(f,"Zebra").selected)
            click(f,"Save current"); field(f):SetText("Ninth"); eq(button(f,"Save "..spec[2]):IsEnabled(),false)
            click(f,"Use selected name"); click(f,"Replace "..spec[2]); assert(button(f,"Zebra").selected)
        end
        click(f,"Delete"); eq(f.r.db.camera.portrait.lights.Zebra,nil); assert(f.r.db.camera.portrait.saved.Zebra)
        click(f,"Scenes"); field(f):SetText("zebra"); click(f,"Delete"); eq(button(f,"Apply scene"),nil)
        eq(#f.ns.Value.Keys(f.r.db.camera.portrait.saved),7); eq(#f.calls,0)
    end)
    test("SS05 a late successful player load cannot mask a missing target or overwrite its previous actor",function()
        local f=make(); open(f); assert(f.p.Add("target")); f.flush()
        save(f,"Two actors","scene"); local old=f.front(2); f.units.target=nil
        click(f,"Apply scene"); eq(f.ui.status:GetText(),"Applying scene…"); f.flush()
        assert(f.ui.status:GetText():find("Partial scene",1,true)); assert(f.ui.status:GetText():find("cast",1,true))
        eq(f.front(2),old); assert(f.p.failures[2]); eq(f.r.db.camera.portrait.saved["Two actors"].actors[2].unit,"target")
        f.units.target="replacement-target"; click(f,"Apply scene"); f.flush()
        eq(f.ui.status:GetText(),"Scene applied."); eq(f.p.slots[2].identity,"replacement-target"); eq(#f.calls,0)
    end)
    test("SS06 renderer limits affect only the lighting or lens the client cannot apply",function()
        local f=make(true); open(f); save(f,"Layout","scene"); click(f,"Lights"); save(f,"Soft","lighting setup")
        f.env.CreateColor=nil; click(f,"Apply lighting setup")
        assert(f.ui.status:GetText():find("lighting unavailable",1,true))
        assert(f.r.db.camera.portrait.lights.Soft); assert(f.p.SetActor("x",1))
        click(f,"Scenes"); click(f,"Apply scene"); f.flush()
        eq(f.p.slots[1].spec.x,0); assert(f.ui.status:GetText():find("Stage lens unavailable",1,true))
        assert(f.ui.status:GetText():find("Lighting unavailable",1,true)); eq(#f.calls,0)
    end)
    test("SS07 empty casts finish immediately and stale requests cannot report success after leaving the stage",function()
        local f=make(); open(f); save(f,"Player","scene"); assert(f.p.Remove(1)); save(f,"Empty","scene")
        click(f,"Player"); click(f,"Apply scene"); click(f,"World Photo"); f.flush(); eq(f.p.active,false)
        eq(f.p.sceneLoad,nil); click(f,"Saved"); eq(button(f,"Player"),nil); eq(button(f,"Apply scene"),nil)
        click(f,"Portrait Stage"); f.flush(); click(f,"Saved"); click(f,"Empty"); click(f,"Apply scene")
        eq(f.p.busy,false); eq(f.ui.status:GetText(),"Scene applied."); eq(next(f.r.db.camera.portrait.scene.actors),nil)
        eq(#f.calls,0)
    end)
    test("SS08 refused lens apply and invalid names preserve the library and current stage",function()
        local f=make(); open(f); assert(f.p.SetScene("roll",18)); save(f,"Angle","scene")
        assert(f.p.SetScene("roll",0)); local old=f.front(); local apply=f.scene.SetCameraOrientationByYawPitchRoll
        f.scene.SetCameraOrientationByYawPitchRoll=function(s,y,p,r) if r~=0 then error("rejected") end; apply(s,y,p,r) end
        click(f,"Apply scene"); eq(f.p.busy,false); assert(f.ui.status:GetText()~="Scene applied.")
        eq(f.r.db.camera.portrait.scene.roll,0); eq(f.r.db.camera.portrait.saved.Angle.roll,18); eq(f.front(),old)
        click(f,"Save current"); local input=field(f); input:SetText("bad|name"); eq(button(f,"Save scene"):IsEnabled(),false)
        input.scripts.OnEnterPressed(input); eq(f.r.db.camera.portrait.saved["bad|name"],nil)
        click(f,"Back"); eq(#f.calls,0)
    end)
    test("SS09 cards depict sparse cast slots and saved light direction and color without rendering live models",function()
        local f=make(); open(f); assert(f.p.Add("target")); f.flush()
        assert(f.p.Remove(1)); assert(f.p.PlaceActor(2,1)); save(f,"Target alone","scene")
        local row=button(f,"Target alone")
        assert(row.detail:GetText():find("1 actor",1,true)); eq(row.cast[1].dot:IsShown(),false)
        eq(row.cast[2].dot:IsShown(),true); assert(row.cast[2].edge.points[1][4]>30)
        assert(row.presetTip:find("2 target",1,true))
        local rig=f.ns.PortraitConfig.LightPreset("ember"); assert(f.p.SetLight(rig))
        click(f,"Lights"); save(f,"Fire","lighting setup")
        assert(f.p.SetLight(f.ns.PortraitConfig.LightPreset("moon"))); local before=#f.modelCalls
        field(f):SetText("fire"); click(f,"Fire"); row=button(f,"Fire")
        eq(row.keyLight.vertexColor[2],rig.green); assert(row.keyLight.points[1][4]<0)
        assert(row.presetTip:find("Azimuth -55°",1,true)); eq(#f.modelCalls,before)
        eq(f.r.db.camera.portrait.scene.light.green,.7); eq(#f.calls,0)
    end)
end
