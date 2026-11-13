-- Lens coordinates and controls on the standalone simulated client.
return function(make, eq, test)
    local function near(value, want) assert(math.abs(value-want)<.000001, tostring(value).." expected "..tostring(want)) end
    local function enter(f)
        f.mock.Click("Portrait Stage"); f.flush(); f.mock.Click("Track")
    end
    local function edit(f, key, value)
        local slider=assert(f.ui.sliders["stage_"..key])
        slider.scripts.OnMouseDown(slider); slider:SetValue(value); slider.scripts.OnMouseUp(slider)
    end
    test("TR01 track translates the lens on straight rails with a fixed aim direction and fixed cast",function()
        local f=make(); enter(f)
        local actor=f.front(); local pos=f.ns.Value.Copy(actor.position)
        assert(f.p.SetOrbit(90,30)); assert(f.p.SetScene("roll",20))
        local origin=f.ns.Value.Copy(f.scene.cameraPosition); local angles=f.ns.Value.Copy(f.scene.cameraAngles)
        edit(f,"trackSide",2); edit(f,"trackLift",-1.5)
        near(f.scene.cameraPosition[1],origin[1]-2); near(f.scene.cameraPosition[2],origin[2]); near(f.scene.cameraPosition[3],origin[3]-1.5)
        for i=1,3 do near(f.scene.cameraAngles[i],angles[i]); near(actor.position[i],pos[i]) end
        eq(f.r.db.camera.portrait.scene.distance,6); near(f.scene.fov,math.rad(35))
        f.mock.Click("Center track"); for i=1,3 do near(f.scene.cameraPosition[i],origin[i]) end
        eq(#f.calls,0); eq(f.env.Narci,nil)
    end)
    test("TR02 aim compensation turns from the translated lens toward the same aim point",function()
        local f=make(); enter(f); assert(f.p.SetOrbit(-35,21))
        assert(f.p.SetTrack(1.5,2)); local position=f.ns.Value.Copy(f.scene.cameraPosition)
        f.mock.Click("Keep aim on stage center")
        local x,y,z=unpack(f.scene.cameraPosition)
        local yaw,pitch=unpack(f.scene.cameraAngles); local h=f.r.db.camera.portrait.scene.height
        local d=math.sqrt(x*x+y*y+(z-h)^2)
        near(x+d*math.cos(pitch)*math.cos(yaw),0); near(y+d*math.cos(pitch)*math.sin(yaw),0)
        near(z-d*math.sin(pitch),h)
        for i=1,3 do near(f.scene.cameraPosition[i],position[i]) end
        f.mock.Click("Keep aim on stage center"); near(f.scene.cameraAngles[2],math.rad(21)); eq(#f.calls,0)
    end)
    test("TR03 overhead and underside are vertical viewpoints with defined headings at either pole",function()
        local f=make(); enter(f); assert(f.p.SetOrbit(43,18)); assert(f.p.SetScene("roll",10))
        for _,v in ipairs({{"Overhead",1},{"From below",-1}}) do
            assert(f.p.SetTrack(1,1)); f.mock.Click(v[1])
            local s=f.r.db.camera.portrait.scene; eq(s.trackSide,0); eq(s.trackLift,0)
            near(f.scene.cameraPosition[1],0); near(f.scene.cameraPosition[2],0)
            near(f.scene.cameraPosition[3],1.1+6*v[2]); near(f.scene.cameraAngles[2],math.pi*.5*v[2])
            near(f.scene.cameraAngles[1],math.pi+math.rad(43)); near(f.scene.cameraAngles[3],math.rad(10))
        end
        f.mock.Click("Keep aim on stage center"); assert(f.p.SetTrack(0,1))
        local ok=f.p.SetTrack(0,6); eq(ok,nil); eq(f.r.db.camera.portrait.scene.trackLift,1)
    end)
    test("TR04 lens errors and invalid track input preserve the previous view and saved position",function()
        local f=make(); enter(f); assert(f.p.SetTrack(1,2))
        local native=f.scene.SetCameraOrientationByYawPitchRoll
        f.scene.SetCameraOrientationByYawPitchRoll=function(self,...)
            if self.cameraPosition[3]>4 then error("renderer refused") end
            native(self,...)
        end
        eq(f.p.SetTrack(3,4),nil); local s=f.r.db.camera.portrait.scene
        eq(s.trackSide,1); eq(s.trackLift,2); near(f.scene.cameraPosition[2],1); near(f.scene.cameraPosition[3],3.1)
        eq(f.p.SetTrack(1,math.huge),nil); eq(f.p.SetTrack("3",2),nil); eq(f.p.SetScene("trackAim",0),nil)
        assert(f.p.ResetCamera()); eq(s.trackSide,0); eq(s.trackLift,0); eq(s.trackAim,false)
    end)
    test("TR05 saved scenes round trip through reload and both renderers; old scenes keep their angles",function()
        local f=make(); enter(f); assert(f.p.SetOrbit(20,-12)); assert(f.p.SetTrack(2,.75))
        assert(f.p.SetScene("trackAim",true)); assert(f.p.Save("Truck")); assert(f.p.ResetCamera())
        for _,fallback in ipairs({false,true}) do
            local g=make(fallback,f.r.db); enter(g); assert(g.p.Load("Truck")); g.flush()
            local s=g.r.db.camera.portrait.scene; eq(s.trackSide,2); eq(s.trackLift,.75); eq(s.trackAim,true)
            eq(g.ui.sliders.stage_trackSide~=nil,not fallback); eq(#g.calls,0)
        end
        local old=f.ns.Value.Copy(f.r.db); old.schemaVersion=22; local p=old.camera.portrait; p.version=4
        for _,s in ipairs({p.scene,p.saved.Truck}) do s.version=4; s.trackLift,s.trackSide,s.trackAim=nil,nil,nil end
        local d,code=f.ns.Store.Open(old); eq(code,"MIGRATED_22_TO_23"); local scene=d.camera.portrait.saved.Truck
        eq(scene.yaw,20); eq(scene.pitch,-12); eq(scene.trackSide,0); eq(scene.trackLift,0); eq(scene.trackAim,false)
        eq(old.camera.portrait.saved.Truck.trackSide,nil)
    end)
    test("TR06 world track uses bounded native controls, restores its offsets and honors a quarter-step zoom",function()
        local f=make(); local shoulder="test_cameraOverShoulder"; local zoom=6
        f.values[shoulder]="0.00"; f.values.CameraKeepCharacterCentered="0"; f.values.CameraReduceUnexpectedMovement="0"
        f.env.GetCameraZoom=function() return zoom end
        f.env.CameraZoomIn=function(d) zoom=zoom-d end; f.env.CameraZoomOut=function(d) zoom=zoom+d end
        f.mock.Click("Track"); eq(#f.calls,0); local s=f.ui.sliders[shoulder]; assert(s)
        s.scripts.OnMouseDown(s); s:SetValue(-1.5); s.scripts.OnMouseUp(s); f.flush(); eq(f.values[shoulder],"-1.5")
        f.mock.Click("Precision movement"); f.mock.Click("Closer"); f.flush(); near(zoom,5.75)
        f.mock.Click("Farther"); f.flush(); near(zoom,6); f.mock.Click("Closer"); f.flush()
        assert(f.r.camera.Exit()); f.flush(); eq(f.values[shoulder],"0.00"); near(zoom,6)
        eq(f.scene,nil)
    end)
    test("TR07 both track pages fit the compact inspector, and a named stage view never moves the world camera",function()
        local f=make(); f.env.UIParent:SetSize(600,400); f.c.Show()
        f.mock.Click("Track"); eq(f.ui.scrollbar.maximum,0); enter(f); eq(f.ui.scrollbar.maximum,0)
        f.mock.Click("From below"); eq(#f.calls,0); f.mock.Click("World Photo")
        eq(f.p.active,false); eq(f.ui.sliders.stage_trackSide,nil)
    end)
end
