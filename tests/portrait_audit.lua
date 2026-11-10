-- Phase 3 audit regressions. Native rendering remains a separate owner test.
return function(make, eq, test)
    test("PCA01 appearance refresh cannot replace a staged target after retargeting", function()
        local f=make(); f.start(); assert(f.p.Add("target")); f.flush(); local old=f.front()
        f.units.target="different-target"
        eq(f.p.SetActor("hideHead",true),nil); f.flush(); eq(f.front(),old); eq(old.shown,true)
        assert(f.p.SetActor("x",1)); eq(f.p.slots[2].spec.x,1); eq(#f.calls,0)
    end)
    test("PCA02 saved ModelScene poses remain usable on the model-widget fallback", function()
        local f=make(); f.start(); assert(f.p.SetActor("time",1.25)); assert(f.p.SetActor("speed",.5)); assert(f.p.Save("Scene"))
        local g=make(true,f.r.db); g.start(); eq(g.p.backend.kind,"DressUpModel")
        assert(g.p.SetActor("x",1)); assert(g.p.SetActor("paused",false))
        eq(g.r.db.camera.portrait.saved.Scene.actors[1].time,1.25); eq(g.p.SetActor("time",2),nil); eq(#g.calls,0)
    end)
    test("PCA03 a missing optional model appearance API does not hide the actor", function()
        local f=make(); assert(f.p.backend.Build())
        for _,model in ipairs(f.models) do model.SetUseTransmogSkin=nil end
        f.start(); assert(f.p.SetActor("x",1)); eq(f.p.SetActor("transmog",false),nil)
        eq(f.front().shown,true); eq(#f.calls,0)
    end)
    test("PCA04 actor editing cannot silently change its unit source", function()
        local f=make(); f.start(); eq(f.p.SetActor("unit","target"),nil)
        eq(f.p.slots[1].spec.unit,"player"); eq(f.front().unit,"player"); eq(#f.calls,0)
    end)
    test("PCA05 missing fallback lighting does not prevent a saved layout from loading", function()
        local f=make(true); f.start(); assert(f.p.Save("Scene")); assert(f.p.SetActor("x",1))
        f.env.CreateColor=nil; assert(f.p.Load("Scene")); f.flush(); eq(f.p.slots[1].spec.x,0)
        eq(f.front().shown,true); eq(#f.calls,0)
    end)
    test("PCA06 Stage shows the same letterbox range as World Photo", function()
        local f=make(); f.start(); assert(f.r.photoEditor.Set("letterbox",.3))
        f.ui.tab="Frame"; f.ui.Build(true); eq(f.ui.sliders.letterbox:GetValue(),.3)
    end)
    test("PCA07 complete photo and visual preset banks survive Store.Open together", function()
        local f=make(); f.start(); assert(f.p.Add("target")); f.flush(); assert(f.p.Add("pet")); f.flush()
        for i=1,8 do assert(f.p.Save("Scene"..i)); assert(f.p.Save("Light"..i,true)) end
        for i=1,12 do assert(f.r.photoEditor.Save("Look"..i)) end
        for i=1,24 do
            local cfg=f.r.db.config.studio
            local updated=assert(f.ns.StudioConfig.SavePreset(cfg,"Preset"..i,"nightVision"))
            f.r.db.config.studio=updated
        end
        assert(f.ns.Store.Open(f.r.db),"Valid full banks must not quarantine on reload")
    end)
    test("PCA08 a refused layer capture reports failure and restores the paused state", function()
        local f=make(); f.start(); assert(f.p.SetActor("paused",false)); f.env.Screenshot=nil
        eq(f.p.CaptureLayers(),nil); eq(f.p.layerCapture,nil); eq(f.front().paused,false); eq(f.captures,0)
    end)
    test("PCA09 missing optional tilt clothing and weapon methods leave useful fallback controls", function()
        local f=make(true); assert(f.p.backend.Build())
        for _,model in ipairs(f.models) do model.SetPitch=nil; model.SetRoll=nil; model.UndressSlot=nil; model.SetSheathed=nil end
        f.start(); assert(f.p.SetActor("x",1)); eq(f.p.SetActor("pitch",10),nil); eq(f.p.SetActor("hideHead",true),nil)
        f.ui.tab="Pose"; f.ui.Build(); eq(f.ui.sliders.pitch,nil); eq(f.ui.sliders.roll,nil); eq(#f.calls,0)
    end)
    test("PCA10 target identity is transient and the original target can still refresh appearance", function()
        local f=make(); f.start(); assert(f.p.Add("target")); f.flush()
        local identity=f.p.slots[2].identity; assert(identity); f.units.target="different-target"
        eq(f.p.SetActor("sheathed",false),nil); f.units.target=identity
        assert(f.p.SetActor("sheathed",false)); f.flush(); eq(f.front().sheathed,false)
        assert(f.p.Save("Scene")); eq(f.r.db.camera.portrait.saved.Scene.actors[2].identity,nil)
        assert(not f.ns.Report.Export(f.r):find(identity,1,true)); eq(#f.calls,0)
    end)
    test("PCA11 missing optional scene light methods do not select a weaker rendering backend", function()
        local f=make(); local create=f.env.CreateFrame
        f.env.CreateFrame=function(kind,...)
            local node=create(kind,...); if kind=="ModelScene" then node.SetLightDirection=nil end; return node
        end
        f.start(); eq(f.p.backend.kind,"ModelScene"); eq(f.p.backend.CanLight(),false)
        assert(f.p.SetActor("time",1)); assert(f.p.SetScene("background","gray")); assert(f.p.Save("Scene"))
        assert(f.p.Load("Scene")); f.flush(); eq(f.front().shown,true); f.ui.tab="Light"; f.ui.Build(); eq(f.ui.sliders.light_red,nil)
    end)
end
