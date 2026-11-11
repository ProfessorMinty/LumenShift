-- Simulated native models. No rendered pose, lighting, unit or screenshot is certified here.
return function(cameraFixture, eq, test)
    local function make(fallback, saved)
        local f = cameraFixture(saved)
        local create = f.env.CreateFrame
        f.models, f.modelCalls, f.units = {}, {}, { player = "player-identity", target = "target-identity", pet = "pet-identity" }
        f.env.UnitExists = function(unit) return f.units[unit] ~= nil end
        f.env.UnitGUID = function(unit) return f.units[unit] end
        f.env.C_Secrets = { ShouldUnitIdentityBeSecret = function(unit) return f.secret == unit end }
        f.env.CreateVector3D = function(x,y,z) return {x=x,y=y,z=z} end
        f.env.CreateColor = function(r,g,b) return {r=r,g=g,b=b} end
        local function model(frame)
            local m = frame or {}; f.models[#f.models + 1] = m
            function m.Show(s) s.shown = true end
            function m.Hide(s) s.shown = false end
            function m.ClearModel(s) s.unit, s.loaded, s.items, s.sources, s.undressed, s.kit = nil, false, {}, {}, {}, 0 end
            function m.SetModelByUnit(s, unit)
                f.modelCalls[#f.modelCalls + 1] = { "load", unit }
                if f.reject then return false end
                s.unit, s.loaded = unit, not f.neverLoad; return true
            end
            m.SetUnit = m.SetModelByUnit
            function m.IsLoaded(s) if f.readError then error("native read") end; return s.loaded end
            function m.GetModelFileID(s) return s.loaded and 123 or 0 end
            function m.SetPaused(s, value, global)
                if not fallback then eq(global, false, "never globally pause models") end
                if f.pauseError then error("pause") end
                s.paused = value; f.modelCalls[#f.modelCalls + 1] = { "pause", value }
            end
            function m.SetAnimation(s, id, variation, speed, offset)
                if f.animationError then error("animation") end
                s.anim, s.variation, s.speed, s.offset = id, variation, speed, offset
            end
            function m.SetPosition(s,x,y,z) s.position = {x,y,z} end
            function m.SetYaw(s,v) s.yaw=v end; m.SetFacing=m.SetYaw
            function m.SetScale(s,v) s.scale=v end; m.SetModelScale=m.SetScale
            function m.SetRequestedScale(s,v) s.requestedScale=v end
            function m.SetPitch(s,v) s.pitch=v end
            function m.SetRoll(s,v) s.roll=v end
            function m.SetSheathed(s,v,hidden) s.sheathed,s.hiddenWeapons=v,hidden end
            function m.SetUseTransmogSkin(s,v) s.transmog=v end
            function m.UndressSlot(s,v) s.undressed = s.undressed or {}; s.undressed[v]=true; if s.items then s.items[v]=nil end; if s.sources then s.sources[v]=nil end end
            function m.SetSpellVisualKit(s,id,oneShot)
                eq(oneShot,false); if f.spellError then error("spell kit") end; s.kit=id
            end
            function m.GetSpellVisualKit(s) return s.kit end
            function m.TryOn(s,link,hand)
                if f.tryOnError then return f.tryOnError end
                local sourceID=tonumber(link); local source=f.sources and f.sources[sourceID]
                local id=source and source.itemID or tonumber(link:match("item:(%d+)")); local item=f.items and f.items[id]
                if not item then return 3 end
                local slots=f.ns.PortraitLibrary.EquipSlots[item.loc]
                local slot=hand=="SECONDARYHANDSLOT" and 17 or slots[1]
                s.items=s.items or {}; s.sources=s.sources or {}; s.sources[slot]=sourceID; s.items[slot]=id; s.hand=hand; return 0
            end
            function m.SetLight(s,enabled,light) eq(enabled,true); s.light=light end
            return m
        end
        f.env.CreateFrame = function(kind, name, parent, template)
            local node = create(kind,name,parent,template)
            if kind == "ModelScene" and not fallback then
                f.scene = node
                function node.CreateActor(_,_,t) eq(t,"ModelSceneActorTemplate"); return model() end
                function node.SetCameraPosition(s,x,y,z) s.cameraPosition={x,y,z} end
                function node.SetCameraOrientationByYawPitchRoll(s,y,p,r) s.cameraAngles={y,p,r} end
                function node.SetCameraFieldOfView(s,v) s.fov=v end
                function node.SetLightType(s,v) eq(v,0); s.lightType=v end
                function node.SetLightVisible(s,v) s.lightVisible=v end
                function node.SetLightDirection(s,x,y,z) s.direction={x,y,z} end
                function node.SetLightAmbientColor(s,r,g,b) if f.lightError then error("lighting") end; s.ambient={r,g,b} end
                function node.SetLightDiffuseColor(s,r,g,b) s.diffuse={r,g,b} end
            elseif kind == "DressUpModel" then model(node) end
            return node
        end
        assert(f.r.camera.Toggle()); f.flush()
        f.p, f.c, f.ui = f.r.portrait, f.r.composition, f.r.composition.editor
        function f.front(id) return f.models[f.p.slots[id or f.p.selected].front] end
        function f.start() assert(f.p.Enter()); f.flush(); assert(f.p.active); assert(f.p.slots[1].front) end
        function f.flush() local n=0; while #f.mock.timers>0 do n=n+1; assert(n<150,"finite timers"); f.tick() end end
        return f
    end
    test("PC01 Phase B exit waiter completes after zoom cancellation without extra movement", function()
        local f=make(); local zoom,moves=12,0
        f.env.GetCameraZoom=function() return zoom end
        f.env.CameraZoomIn=function(n) zoom=zoom-n; moves=moves+1 end
        assert(f.r.cameraActions.Zoom(10)); assert(f.r.camera.Exit()); eq(f.r.camera.busy,true)
        f.r.camera.Combat(); eq(f.r.camera.busy,false); f.flush(); eq(moves,1)
        eq(f.r.db.camera.composition.zoom.original,12); eq(f.r.db.camera.composition.zoom.state,"failed")
    end)
    test("PC02 stage is lazy standalone and startup loads no models or CVars", function()
        local f=make(); eq(#f.models,0); eq(f.p.active,false); eq(#f.calls,0); eq(f.env.Narci,nil)
        f.start(); eq(#f.models,6); eq(f.p.backend.kind,"ModelScene"); eq(#f.calls,0)
        eq(f.front().paused,true); eq(f.front().unit,"player")
    end)
    test("PC03 live transforms and lens affect owned model copies only", function()
        local f=make(); f.start()
        for k,v in pairs({ x=1.5,y=.6,depth=-.5,scale=1.2,yaw=90,pitch=15,roll=-10 }) do assert(f.p.SetActor(k,v)) end
        local m=f.front(); eq(m.position[1],-.5); eq(m.position[2],-1.5); eq(m.position[3],.6); eq(m.yaw,math.pi/2)
        eq(m.scale,1.2); eq(m.requestedScale,1.2)
        assert(f.p.SetScene("fov",50)); eq(f.scene.fov,math.rad(50)); eq(#f.calls,0)
    end)
    test("PC04 pose scrub pause speed and failed animation preserve the saved pose", function()
        local f=make(); f.start(); assert(f.p.SetActor("animation",69)); assert(f.p.SetActor("time",1.2))
        eq(f.front().offset,1.2); eq(f.front().paused,true); assert(f.p.SetActor("paused",false)); eq(f.front().paused,false)
        assert(f.p.SetActor("speed",.5)); eq(f.front().speed,.5); f.animationError=true
        eq(f.p.SetActor("animation",67),nil); eq(f.r.db.camera.portrait.scene.actors[1].animation,69); eq(#f.calls,0)
    end)
    test("PC05 actor appearance reloads a back buffer without changing world equipment", function()
        local f=make(); f.start(); local old=f.front()
        assert(f.p.SetActor("hideHead",true)); eq(old.shown,true); f.flush()
        eq(old.shown,false); eq(f.front().undressed[1],true); eq(#f.models,6)
        assert(f.p.SetActor("hideHead",false)); f.flush(); eq(f.p.slots[1].spec.hideHead,false); eq(#f.calls,0)
    end)
    test("PC06 bounded cast selection removal and unavailable target preserve other actors", function()
        local f=make(); f.start(); assert(f.p.Add("target")); f.flush(); assert(f.p.Add("pet")); f.flush()
        eq(f.p.Add("player"),nil); eq(#f.models,6); assert(f.p.Remove(2)); eq(f.p.slots[2],nil)
        f.units.target=nil; eq(f.p.Add("target"),nil); eq(f.p.slots[1].spec.unit,"player"); eq(f.p.slots[3].spec.unit,"pet")
        eq(f.p.Remove(5),nil); eq(#f.calls,0)
    end)
    test("PC07 restricted units are rejected before model API invocation", function()
        local f=make(); f.start(); f.secret="target"; local before=#f.modelCalls
        eq(f.p.Add("target"),nil); eq(#f.modelCalls,before); eq(f.p.active,true)
        f.env.UnitGUID=function() return nil end; eq(f.p.Add("target"),nil)
    end)
    test("PC08 changed target identity and timeout retain the previous actor", function()
        local f=make(); f.start(); assert(f.p.Add("target")); f.flush(); local old=f.front()
        f.neverLoad=true; assert(f.p.SetActor("hideWeapons",true)); f.units.target="new-target"; f.flush()
        eq(f.front(),old); eq(old.shown,true); eq(f.p.busy,false)
        f.units.target=f.p.slots[f.p.selected].identity -- select the original actor again for the timeout case
        assert(f.p.SetActor("hideWeapons",true)); f.flush(); eq(f.front(),old); eq(f.p.busy,false)
        assert(f.p.status:find("timed out",1,true)); eq(#f.calls,0)
    end)
    test("PC09 native load rejection missing readiness and timer failure are local", function()
        for _,failure in ipairs({"reject","readError","timer"}) do
            local f=make(); f.start(); local old=f.front()
            if failure=="timer" then f.env.C_Timer.After=function() error("timer") end else f[failure]=true end
            f.p.SetActor("sheathed",false); f.flush(); eq(f.front(),old); eq(f.p.busy,false); eq(old.shown,true)
        end
    end)
    test("PC10 exit combat and world leave invalidate queued model loads", function()
        for _,action in ipairs({"exit","combat","world"}) do
            local f=make(); f.r.db.camera.keepInCombat=false; f.neverLoad=true; assert(f.p.Enter())
            if action=="exit" then f.r.camera.Exit() elseif action=="combat" then f.r.camera.Combat()
            else f.frame.OnEvent(f.frame,"PLAYER_LEAVING_WORLD") end
            f.neverLoad=false; f.flush(); eq(f.p.active,false); eq(f.p.busy,false); eq(f.p.backend.root:IsShown(),false)
            for _,m in ipairs(f.models) do eq(m.shown,false); eq(m.unit,nil) end
        end
    end)
    test("PC11 independent light recipes color intensity and direction are model-only", function()
        local f=make(); f.start(); local before=f.r.db.camera.editor.look.warmth
        assert(f.p.SetLight(f.ns.PortraitConfig.LightPreset("ember"))); eq(f.scene.diffuse[1],1.4)
        eq(f.r.db.camera.editor.look.warmth,before); eq(#f.calls,0)
        local original=f.r.db.camera.portrait.scene.light.ambient; f.lightError=true
        eq(f.p.SetLight(f.ns.PortraitConfig.LightPreset("soft")),nil); eq(f.r.db.camera.portrait.scene.light.ambient,original)
    end)
    test("PC12 validated scenes and independent lights roundtrip without retaining unit identities", function()
        local f=make(); f.start(); assert(f.p.Add("target")); f.flush(); assert(f.p.SetActor("x",1.8)); assert(f.p.Save("Scene")); assert(f.p.Save("Light",true))
        assert(f.p.SetActor("x",0)); assert(f.p.Load("Scene")); f.flush(); eq(f.p.slots[2].spec.x,1.8)
        local s=f.r.db.camera.portrait.saved.Scene; eq(s.actors[2].unit,"target"); eq(s.actors[2].guid,nil)
        assert(f.p.Load("Light",true)); assert(f.ns.Store.Open(f.r.db)); eq(#f.calls,0)
    end)
    test("PC13 malformed values unknown fields scripts and excessive casts are rejected", function()
        local f=make(); f.start(); local c=f.ns.PortraitConfig
        for _,v in ipairs({-4,math.huge,"1"}) do eq(f.p.SetActor("x",v),nil) end
        eq(f.p.SetActor("animation",999999),nil); eq(f.p.SetActor("script","hello"),nil)
        eq(f.p.SetScene("fov",180),nil); eq(f.p.SetScene("background","texture-path"),nil)
        local s=c.Scene(); s.actors[4]=c.Actor(); eq(c.ValidScene(s),false)
        s=c.Scene(); s.version=99; eq(c.ValidScene(s),false)
        s=c.Scene(); s.actors[1].unit="party1"; eq(c.ValidScene(s),false)
        local d=f.ns.Value.Copy(f.r.db); d.camera.portrait.saved.Bad=s; eq(f.ns.Store.Open(d),nil)
        eq(f.p.Save("|Tunsafe"),nil); eq(f.p.Save(string.rep("a",33)),nil); eq(#f.calls,0)
    end)
    test("PC14 scene banks cap at eight and preserve preferences on schema 15 migration", function()
        local f=make(); f.start()
        for i=1,8 do assert(f.p.Save("Scene"..i)); assert(f.p.Save("Light"..i,true)) end
        eq(f.p.Save("Ninth"),nil); assert(f.p.Delete("Scene8")); assert(f.p.Save("Ninth"))
        assert(f.ns.Store.Open(f.r.db)); local old=f.ns.Value.Copy(f.r.db); old.schemaVersion=15; old.camera.portrait=nil
        local updated,code=f.ns.Store.Open(old); eq(code,"MIGRATED_15_TO_20"); eq(updated.camera.portrait.version,4)
        eq(updated.config.preferences.reducedMotion,old.config.preferences.reducedMotion); eq(old.camera.portrait,nil)
    end)
    test("PC15 saved stage data never creates or starts models on reload", function()
        local f=make(); f.start(); assert(f.p.SetActor("paused",false)); assert(f.p.Save("Scene"))
        local g=make(false,f.r.db); eq(#g.models,0); eq(g.p.active,false); eq(#g.calls,0)
    end)
    test("PC16 capture pauses only staged actors and resumes after native result", function()
        local f=make(); f.start(); assert(f.p.SetActor("paused",false)); assert(f.c.Capture()); eq(f.front().paused,true)
        f.tick(); eq(f.captures,1); f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_SUCCEEDED")
        eq(f.front().paused,false); f.flush(); eq(#f.calls,0)
    end)
    test("PC17 screenshot failures timeouts and pause errors do not strand staged animation", function()
        local f=make(); f.start(); assert(f.p.SetActor("paused",false)); assert(f.c.Capture()); f.flush(); eq(f.front().paused,false)
        f.pauseError=true; eq(f.c.Capture(),nil); eq(f.c.capturing,false); eq(f.p.frozen,nil)
    end)
    test("PC18 clean external view retains artwork but Escape clears stage and restores HUD", function()
        local f=make(); f.start(); assert(f.c.ToggleControls()); eq(f.c.root:IsShown(),false)
        eq(f.p.backend.root:IsShown(),true); eq(f.front().shown,true)
        f.c.input.scripts.OnKeyDown(f.c.input,"ESCAPE"); f.flush()
        eq(f.p.active,false); eq(f.env.UIParent:IsShown(),true); eq(f.p.backend.root:IsShown(),false)
    end)
    test("PC19 layer capture takes two completion-gated clean images and restores the scene", function()
        local f=make(); f.start(); assert(f.p.SetActor("paused",false)); assert(f.r.photoEditor.Recipe("ember"))
        assert(f.p.CaptureLayers()); eq(f.front().shown,false); eq(f.r.photoEffects.root:IsShown(),false)
        f.tick(); eq(f.captures,1); eq(f.p.SetActor("x",1),nil); eq(f.r.captureSequence.Start(),nil)
        f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_SUCCEEDED"); eq(f.front().shown,true)
        -- The first request's timeout is inert; the next timer renders the green pass.
        while f.captures<2 do f.tick() end
        eq(f.front().paused,true); f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_SUCCEEDED")
        eq(f.p.layerCapture,nil); eq(f.front().paused,false); eq(f.r.photoEffects.root:IsShown(),true); f.flush()
    end)
    test("PC20 layer failure cancellation and late callbacks cannot resurrect an exited scene", function()
        for _,action in ipairs({"fail","cancel","exit"}) do
            local f=make(); f.start(); assert(f.p.CaptureLayers()); f.tick()
            if action=="fail" then f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_FAILED")
            elseif action=="cancel" then f.p.CancelLayers()
            else f.r.camera.Exit() end
            f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_SUCCEEDED"); f.flush(); eq(f.captures,1); eq(f.p.layerCapture,nil)
            if action=="exit" then eq(f.p.active,false); eq(f.p.backend.root:IsShown(),false) else eq(f.front().shown,true) end
        end
    end)
    test("PC21 model-widget fallback stays standalone and exposes its timeline limitation", function()
        local f=make(true); f.start(); eq(f.p.backend.kind,"DressUpModel"); eq(f.p.SetActor("time",1),nil)
        assert(f.p.SetActor("x",1)); assert(f.p.SetActor("animation",67)); assert(f.p.SetActor("paused",false))
        assert(f.p.SetLight(f.ns.PortraitConfig.LightPreset("soft"))); eq(f.front().light.ambientIntensity,.8)
        eq(f.p.SetScene("distance",8),nil); eq(#f.calls,0)
    end)
    test("PC22 missing model APIs refuse stage locally while World Photo stays usable", function()
        local f=cameraFixture(); assert(f.r.camera.Toggle()); f.flush(); eq(f.r.portrait.Enter(),nil)
        eq(f.r.portrait.active,false); assert(f.r.photoEditor.Recipe("ember")); assert(f.r.camera.Exit()); eq(#f.calls,0)
    end)
    test("PC23 all portrait tabs and live slider controls work with Narcissus absent", function()
        local f=make(); f.mock.Click("Portrait Stage"); f.flush(); eq(f.p.active,true)
        for _,tab in ipairs({"Pose","Light","Frame","Saved","Capture","Look"}) do f.ui.tab=tab; f.ui.Build(true) end
        f.ui.tab="Light"; f.ui.Build(); local s=f.ui.sliders.light_ambient
        s.scripts.OnMouseDown(s); s:SetValue(70); assert(math.abs(f.r.db.camera.portrait.scene.light.ambient-.7)<1e-9); s.scripts.OnMouseUp(s)
        f.mock.Click("World Photo"); eq(f.p.active,false); eq(#f.calls,0); eq(f.env.Narci,nil)
    end)
    test("PC24 repeated stage entries reuse six models and no hidden native animation survives exit", function()
        local f=make(); for i=1,8 do f.start(); assert(f.p.SetActor("paused",false)); assert(f.p.World()) end
        eq(#f.models,6); for _,m in ipairs(f.models) do eq(m.paused,true); eq(m.shown,false); eq(m.unit,nil) end
    end)
    test("PC25 missing saved target keeps the previous actor while other scene actors load", function()
        local f=make(); f.start(); assert(f.p.Add("target")); f.flush(); assert(f.p.Save("Pair"))
        local old=f.front(2); f.units.target=nil; assert(f.p.Load("Pair")); f.flush()
        eq(f.front(2),old); eq(old.shown,true); assert(f.p.failures[2]); eq(f.p.slots[1].spec.unit,"player")
    end)
    test("PC26 stale loads cannot clear actors from a new stage entry", function()
        local f=make(); f.r.db.camera.keepInCombat=false; f.neverLoad=true; assert(f.p.Enter()); assert(f.p.World()); f.neverLoad=false
        assert(f.p.Enter()); f.flush(); eq(f.p.active,true); eq(f.front().shown,true); eq(f.p.busy,false)
    end)
    test("PC27 portrait reports expose counts and backend without names or unit identities", function()
        local f=make(); f.start(); assert(f.p.Save("private scene")); assert(f.p.Save("private light",true))
        local report=f.ns.Report.Export(f.r)
        assert(report:find("Portrait stage: active=yes backend=ModelScene",1,true))
        assert(not report:find("private scene",1,true)); assert(not report:find("private light",1,true)); assert(not report:find("player-identity",1,true))
    end)
    test("PC28 reduced motion starts loaded scenes paused but explicit Play remains available", function()
        local f=make(); f.r.db.config.preferences.reducedMotion=true; f.r.db.camera.portrait.scene.actors[1].paused=false
        f.start(); eq(f.front().paused,true); assert(f.p.SetActor("paused",false)); eq(f.front().paused,false)
    end)
    test("PC29 full bounded cast scene and light banks fit the SavedVariables copy limit", function()
        local f=make(); f.start(); assert(f.p.Add("target")); f.flush(); assert(f.p.Add("pet")); f.flush()
        for i=1,8 do assert(f.p.Save("Scene"..i)); assert(f.p.Save("Light"..i,true)) end
        assert(f.ns.Store.Open(f.r.db)); local corrupt=f.ns.Value.Copy(f.r.db); corrupt.schemaVersion=15; corrupt.camera.portrait.version=99
        eq(f.ns.Store.Open(corrupt),nil); eq(corrupt.camera.portrait.version,99)
    end)
    test("PC30 capture refuses unfinished loads and clean view survives a later timeout", function()
        local f=make(); f.r.db.camera.keepInCombat=false; f.neverLoad=true; assert(f.p.Enter()); eq(f.c.Capture(),nil); eq(f.r.captureSequence.Start(),nil)
        assert(f.c.ToggleControls()); f.flush(); eq(f.p.busy,false); eq(f.c.root:IsShown(),false); eq(f.captures,0)
        assert(f.p.World()); eq(f.p.active,false)
    end)
    test("PC31 unsupported fallback poses preserve the current animation", function()
        local f=make(true); f.start(); f.front().HasAnimation=function(_,id) return id==0 end
        eq(f.p.SetActor("animation",69),nil); eq(f.p.slots[1].spec.animation,0); eq(f.front().anim,0)
    end)
    return make
end
