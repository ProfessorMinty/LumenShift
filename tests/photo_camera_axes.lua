-- Simulated input and scene geometry, independent of Narcissus.
return function(make, eq, test)
    local function button(f, label)
        for _, node in ipairs(f.mock.nodes) do
            if node.kind == "Button" and node.label and node.label.text == label and node:IsVisible() then return node end
        end
        error("Missing button " .. label)
    end
    local function near(actual, expected)
        assert(math.abs(actual - expected) < .000001, tostring(actual) .. " should be near " .. expected)
    end
    local function world()
        local f = make()
        f.moves = {}
        for _, direction in ipairs({ "Up", "Down", "Left", "Right" }) do
            local d = direction
            f.env["MoveView" .. d .. "Start"] = function(speed) table.insert(f.moves, {d, speed}) end
            f.env["MoveView" .. d .. "Stop"] = function() table.insert(f.moves, {d, "stop"}) end
        end
        f.ui.Build()
        return f
    end
    test("AX01 first open exposes all four world directions and separate framing and names pages", function()
        local f = world()
        eq(f.ui.tab, "Frame"); eq(f.ui.cameraPage, "Position")
        for _, label in ipairs({"Tilt up","Tilt down","Orbit left","Orbit right"}) do assert(button(f,label)) end
        f.mock.Click("Framing"); assert(button(f,"Rule of thirds")); f.mock.Click("Visibility"); assert(button(f,"Hide all names"))
        eq(#f.moves,0); eq(#f.calls,0); eq(f.env.Narci,nil)
    end)
    test("AX02 precision pitch uses the correct native pair and release doesn't start a second move", function()
        local f = world(); local b = button(f,"Tilt up")
        b.scripts.OnMouseDown(b,"LeftButton"); near(f.moves[1][2],.08); eq(f.moves[1][1],"Up")
        b.scripts.OnMouseUp(b,"LeftButton"); eq(f.moves[2][2],"stop")
        f.mock.Click("Precision movement"); b=button(f,"Tilt down")
        b.scripts.OnMouseDown(b,"LeftButton"); near(f.moves[3][2],.025); eq(f.moves[3][1],"Down")
        b.scripts.OnLeave(b); f.flush(); eq(#f.moves,4); eq(f.moves[4][2],"stop")
        eq(f.ui.notice,nil); eq(#f.calls,0)
    end)
    test("AX03 an old direction release or timer cannot stop its replacement", function()
        local f=world(); local a=f.r.cameraActions
        assert(a.Orbit("down")); assert(a.Orbit("right")); eq(#f.moves,3)
        eq(f.moves[2][1],"Down"); eq(f.moves[2][2],"stop")
        a.StopOrbit("down"); f.tick(); eq(a.orbit,"right"); eq(#f.moves,3)
        f.flush(); eq(a.orbit,nil); eq(f.moves[4][1],"Right"); eq(f.moves[4][2],"stop")
    end)
    test("AX04 a missing vertical stop disables only that direction", function()
        local f=world(); f.env.MoveViewUpStop=nil; f.ui.Build()
        eq(button(f,"Tilt up").disabled,true); eq(f.r.cameraActions.Orbit("up"),nil)
        assert(f.r.cameraActions.Orbit("down")); f.r.cameraActions.StopOrbit(); eq(#f.moves,2)
    end)
    test("AX05 pitch stops on capture, clean view, page change, combat and exit", function()
        for _, action in ipairs({"capture","clean","page","combat","exit"}) do
            local f=world(); local b=button(f,"Tilt up"); b.scripts.OnMouseDown(b,"LeftButton")
            if action=="capture" then assert(f.r.composition.Capture())
            elseif action=="clean" then assert(f.r.composition.ToggleControls())
            elseif action=="page" then f.mock.Click("Framing")
            elseif action=="combat" then f.env.InCombatLockdown=function() return true end; f.r.camera.Combat()
            else assert(f.r.camera.Exit()) end
            eq(f.r.cameraActions.orbit,nil); eq(#f.moves,2); eq(f.moves[2][2],"stop")
        end
    end)
    test("AX06 stage orbit tracks aim height across quarters above and below the cast", function()
        local f=make(); f.start(); local scene=f.r.db.camera.portrait.scene
        for _, deg in ipairs({-180,-90,0,90,180}) do
            for _, elevation in ipairs({-80,0,45,80}) do
                assert(f.p.SetScene("yaw",deg)); assert(f.p.SetScene("pitch",elevation))
                local x,y,z=unpack(f.scene.cameraPosition)
                local yaw,pitch=unpack(f.scene.cameraAngles)
                near(x+scene.distance*math.cos(pitch)*math.cos(yaw),0)
                near(y+scene.distance*math.cos(pitch)*math.sin(yaw),0)
                near(z-scene.distance*math.sin(pitch),scene.height)
                near(math.sqrt(x*x+y*y+(z-scene.height)^2),scene.distance)
            end
        end
        eq(#f.calls,0)
    end)
    test("AX07 live roll changes the staged camera while actor pose and position stay fixed", function()
        local f=make(); f.mock.Click("Portrait Stage"); f.flush(); local m=f.front()
        assert(f.p.SetActor("yaw",22)); local pos=f.ns.Value.Copy(f.scene.cameraPosition)
        local slider=f.ui.sliders.stage_roll; slider.scripts.OnMouseDown(slider)
        slider:SetValue(-18); near(f.scene.cameraAngles[3],math.rad(-18)); eq(f.ui.sliders.stage_roll,slider)
        slider:SetValue(43); near(f.scene.cameraAngles[3],math.rad(43)); eq(f.front(),m)
        for i=1,3 do near(f.scene.cameraPosition[i],pos[i]) end
        near(m.yaw,math.rad(22)); slider.scripts.OnMouseUp(slider)
        f.mock.Click("Level horizon"); near(f.scene.cameraAngles[3],0); eq(#f.calls,0)
    end)
    test("AX08 a level horizon preserves lens and orbit while reset returns the complete camera", function()
        local f=make(); f.mock.Click("Portrait Stage"); f.flush()
        for k,v in pairs({yaw=70,pitch=15,roll=-33,distance=9,height=2.5,fov=52}) do assert(f.p.SetScene(k,v)) end
        assert(f.p.SetScene("background","blue")); f.mock.Click("Level horizon")
        local scene=f.r.db.camera.portrait.scene
        eq(scene.roll,0); eq(scene.yaw,70); eq(scene.fov,52)
        f.mock.Click("Reset stage camera"); local defaults=f.ns.PortraitConfig.Scene()
        for k in pairs(f.ns.PortraitConfig.CameraRanges) do eq(scene[k],defaults[k]) end
        eq(scene.background,"blue"); eq(#f.calls,0)
    end)
    test("AX09 old active and saved scenes migrate level without losing lens or actor transforms", function()
        local f=make(); local old=f.ns.Value.Copy(f.r.db); old.schemaVersion=19
        local p=old.camera.portrait; p.version=3; p.scene.version=3
        p.scene.yaw,p.scene.pitch,p.scene.roll=nil,nil,nil
        p.scene.distance=9; p.scene.height=2; p.scene.actors[1].roll=12; p.saved.Before=f.ns.Value.Copy(p.scene)
        local db,why=f.ns.Store.Open(old); eq(why,"MIGRATED_19_TO_20")
        for _,s in ipairs({db.camera.portrait.scene,db.camera.portrait.saved.Before}) do
            eq(s.version,4); eq(s.yaw,0); eq(s.pitch,0); eq(s.roll,0); eq(s.distance,9); eq(s.height,2); eq(s.actors[1].roll,12)
        end
        eq(old.camera.portrait.saved.Before.yaw,nil); eq(#f.calls,0)
    end)
    test("AX10 saved angles survive reload, explicit scene load and the actor-only backend", function()
        local f=make(); f.start(); assert(f.p.SetScene("yaw",75)); assert(f.p.SetScene("pitch",25))
        assert(f.p.SetScene("roll",30)); assert(f.p.Save("Angled")); assert(f.p.ResetCamera())
        for _,fallback in ipairs({false,true}) do
            local g=make(fallback,f.r.db); g.start(); assert(g.p.Load("Angled")); g.flush()
            local s=g.r.db.camera.portrait.scene; eq(s.yaw,75); eq(s.pitch,25); eq(s.roll,30)
            if fallback then g.ui.tab="Frame"; g.ui.Build(); eq(g.ui.sliders.stage_roll,nil)
            else near(g.scene.cameraAngles[3],math.rad(30)) end
            eq(#g.calls,0)
        end
    end)
    test("AX11 rejected lens updates roll back a partly moved camera and retain saved angles", function()
        local f=make(); f.start(); local native=f.scene.SetCameraOrientationByYawPitchRoll
        f.scene.SetCameraOrientationByYawPitchRoll=function(self,y,p,r)
            if p>0 then error("unavailable") end
            native(self,y,p,r)
        end
        eq(f.p.SetScene("pitch",25),nil); near(f.scene.cameraPosition[3],1.1)
        eq(f.r.db.camera.portrait.scene.pitch,0); eq(f.p.SetScene("roll",91),nil)
        eq(f.p.SetScene("yaw",0/0),nil); eq(#f.calls,0)
    end)
    test("AX12 reduced motion blocks world holds and leaves deliberate stage sliders usable", function()
        local f=world(); f.r.db.config.preferences.reducedMotion=true; f.ui.Build()
        eq(button(f,"Tilt down").disabled,true); eq(f.r.cameraActions.Orbit("down"),nil)
        f.mock.Click("Portrait Stage"); f.flush(); assert(f.p.SetScene("roll",10))
        eq(#f.moves,0); eq(#f.calls,0)
    end)
    test("AX13 typed stage angles update the view and invalid entries keep the previous angle", function()
        local f=make(); f.mock.Click("Portrait Stage"); f.flush()
        local edit=f.ui.sliders.stage_roll.edit
        edit:SetText("-27"); edit.scripts.OnEnterPressed(edit); near(f.scene.cameraAngles[3],math.rad(-27))
        edit=f.ui.sliders.stage_roll.edit
        edit:SetText("150"); edit.scripts.OnEnterPressed(edit)
        eq(f.r.db.camera.portrait.scene.roll,-27); eq(edit:GetText(),"-27")
        eq(#f.calls,0)
    end)
    test("AX14 camera pages remain outside scrolling controls and open from the top", function()
        local f=world(); f.mock.Click("Framing"); f.ui.scrollbar:SetValue(150)
        eq(f.ui.scroll:GetVerticalScroll(),0); assert(button(f,"Rule of thirds"))
        eq(button(f,"Visibility").parent.parent,f.ui.panel)
        f.mock.Click("Visibility"); eq(f.ui.scroll:GetVerticalScroll(),0)
        assert(button(f,"Hide all names")); f.mock.Click("Position"); assert(button(f,"Tilt up"))
        eq(#f.moves,0); eq(#f.calls,0)
    end)
    test("AX15 rejected stage pitch restores the physical thumb, number and native view", function()
        local f=make(); f.mock.Click("Portrait Stage"); f.flush()
        local apply=f.scene.SetCameraOrientationByYawPitchRoll
        local attempts=0
        f.scene.SetCameraOrientationByYawPitchRoll=function(s,y,p,r)
            attempts=attempts+1
            if p>0 then error("angle rejected") end
            apply(s,y,p,r)
        end
        local slider=f.ui.sliders.stage_pitch
        slider.scripts.OnMouseDown(slider); slider:SetValue(24); slider.scripts.OnMouseUp(slider)
        eq(f.r.db.camera.portrait.scene.pitch,0); near(f.scene.cameraAngles[2],0)
        eq(slider.edit:GetText(),"0"); eq(attempts,2); eq(slider:GetValue(),0)
    end)
    test("AX16 rejected saved camera leaves the current scene light and cast intact", function()
        local f=make(); f.start()
        assert(f.p.SetLight(f.ns.PortraitConfig.LightPreset("ember"))); assert(f.p.SetScene("roll",30)); assert(f.p.Save("Warm angle"))
        assert(f.p.ResetCamera()); local current=f.ns.PortraitConfig.LightPreset("soft"); assert(f.p.SetLight(current))
        local front=f.front(); local apply=f.scene.SetCameraOrientationByYawPitchRoll
        f.scene.SetCameraOrientationByYawPitchRoll=function(s,y,p,r)
            if r~=0 then error("angle rejected") end
            apply(s,y,p,r)
        end
        eq(f.p.Load("Warm angle"),nil); eq(f.front(),front); eq(f.r.db.camera.portrait.scene.roll,0)
        eq(f.r.db.camera.portrait.scene.light.ambient,current.ambient)
        eq(f.r.db.camera.portrait.saved["Warm angle"].roll,30)
    end)
    test("AX17 clean view keeps controls available if native pitch cannot stop", function()
        local f=world(); local fail=true
        f.env.MoveViewUpStop=function() if fail then error("stop rejected") end end
        assert(f.r.cameraActions.Orbit("up"))
        local ok,why=f.c.ToggleControls(); eq(ok,nil); eq(why,"CAMERA_STOP_FAILED")
        eq(f.c.controlsHidden,false); assert(f.ui.panel:IsVisible())
        eq(f.ui.status:GetText(),f.ns.Product.Message(why))
        fail=false; assert(f.c.ToggleControls()); eq(f.c.controlsHidden,true); eq(f.r.cameraActions.orbit,nil)
    end)
    test("AX18 Exit returns the game HUD and reports a failed native yaw stop", function()
        local f=world(); f.env.MoveViewRightStop=function() error("stop rejected") end
        assert(f.r.cameraActions.Orbit("right")); local ok,why=f.r.camera.Exit()
        assert(f.env.UIParent:IsShown()); eq(f.r.camera.active,false)
        eq(ok,nil); eq(why,"CAMERA_STOP_FAILED"); eq(f.r.camera.error,why)
    end)
    test("AX19 rejected watchdog scheduling cannot rebuild controls from a stale callback", function()
        local f=world(); local a=f.r.cameraActions; local after=f.env.C_Timer.After
        local refreshes=0; a.Refresh=function() refreshes=refreshes+1 end
        f.env.C_Timer.After=function(delay,fn) after(delay,fn); error("scheduled then rejected") end
        eq(a.Orbit("down"),nil); eq(#f.moves,0); local before=refreshes
        f.env.C_Timer.After=after; f.flush(); eq(refreshes,before); eq(#f.moves,0)
    end)
    test("AX20 signed yaw pitch and roll match a known off-axis stage pose", function()
        local f=make(); f.mock.Click("Portrait Stage"); f.flush()
        for _, pair in ipairs({{"yaw",-90},{"pitch",60},{"roll",-90}}) do
            local slider=f.ui.sliders["stage_"..pair[1]]
            slider.scripts.OnMouseDown(slider); slider:SetValue(pair[2]); slider.scripts.OnMouseUp(slider)
        end
        local x,y,z=unpack(f.scene.cameraPosition); near(x,0); near(y,-3); near(z,6.296152423)
        local yaw,pitch,roll=unpack(f.scene.cameraAngles)
        near(yaw,math.pi/2); near(pitch,math.pi/3); near(roll,-math.pi/2)
        eq(f.env.Narci,nil); eq(#f.calls,0)
    end)
    test("AX21 all world pad buttons stop the same native axis they start", function()
        local f=world()
        for _, pair in ipairs({{"Orbit left","Left"},{"Orbit right","Right"},{"Tilt up","Up"},{"Tilt down","Down"}}) do
            local b=button(f,pair[1]); f.moves={}
            b.scripts.OnMouseDown(b,"LeftButton"); b.scripts.OnMouseUp(b,"LeftButton"); f.flush()
            eq(#f.moves,2); eq(f.moves[1][1],pair[2]); eq(f.moves[2][1],pair[2]); eq(f.moves[2][2],"stop")
        end
        eq(f.ui.sliders.stage_roll,nil); eq(#f.calls,0)
    end)
    test("AX22 an unresolved world stop still allows exact FOV restoration on exit", function()
        local f=world(); local original=f.values.cameraFov
        assert(f.r.camera.ApplyFOV(75)); f.flush()
        f.env.MoveViewUpStop=function() error("stop rejected") end
        assert(f.r.cameraActions.Orbit("up")); f.r.camera.Exit(); f.flush()
        assert(f.env.UIParent:IsShown()); eq(f.values.cameraFov,original)
        eq(next(f.r.db.camera.framing.journal.entries),nil); eq(f.r.camera.error,"CAMERA_STOP_FAILED")
    end)
    test("AX23 native start error with failed cleanup keeps the stop failure visible", function()
        local f=world(); f.env.MoveViewDownStart=function() error("start rejected") end
        f.env.MoveViewDownStop=function() error("stop rejected") end
        local ok,why=f.r.cameraActions.Orbit("down"); eq(ok,nil); eq(why,"CAMERA_STOP_FAILED")
        eq(f.r.cameraActions.orbit,"down"); eq(f.r.cameraActions.status,why)
    end)
end
