-- Simulated WoW CVar and frame APIs; no installed-client writes.
return function(make,eq,test)
    local centered,reduce="CameraKeepCharacterCentered","CameraReduceUnexpectedMovement"
    local shoulder,pitch,foot="test_cameraOverShoulder","test_cameraDynamicPitch","test_cameraDynamicPitchBaseFovPad"
    local function open(a,b,saved)
        local f=make(saved,{[centered]=a,[reduce]=b,[shoulder]="0.00",[pitch]="0",[foot]="0.35"})
        local getInfo=f.env.C_CVar.GetCVarInfo
        f.env.C_CVar.GetCVarInfo=function(key)
            if key==centered or key==reduce then
                return f.values[key],key==centered and "1" or "0",true,false,false,false,f.restricted==key
            end
            return getInfo(key)
        end
        assert(f.r.camera.Toggle()); f.flush()
        local ui=f.r.composition.editor
        f.mock.Click("Framing"); f.mock.Click("Offset"); assert(not ui.building)
        return f,ui
    end
    local function button(f,label)
        for _,v in ipairs(f.mock.nodes) do if v.kind=="Button" and v:IsVisible() and v.label and v.label:GetText()==label then return v end end
    end
    local function visibleText(f,label)
        for _,v in ipairs(f.mock.nodes) do if v.kind=="FontString" and v:IsVisible() and v:GetText()==label then return true end end
    end
    test("CF01 Offset identifies each live preference without writes, with readable rail labels and no stale orbit status",function()
        for _,pair in ipairs({{"1","0"},{"0","1"},{"1","1"},{"0","0"}}) do
            local f,ui=open(unpack(pair)); f.r.cameraActions.status="Motion stopped."; ui.Build()
            eq(visibleText(f,"Keep character centered") or false,pair[1]=="1")
            eq(visibleText(f,"Reduce unexpected camera movement") or false,pair[2]=="1")
            eq(button(f,"Enable photo framing")~=nil,pair[1]=="1" or pair[2]=="1")
            eq(button(f,"Restore all framing"):IsEnabled(),false); eq(ui.status:GetText(),"")
            assert(button(f,"Camera").label:GetWidth()>=60 and button(f,"Capture").label:GetWidth()>=60)
            f.env.UIParent:SetSize(600,400); f.r.composition.Show(); eq(ui.scrollbar.maximum,0)
            eq(#f.calls,0)
        end
    end)
    test("CF02 explicit enable restores exact preference and framing originals using the UI or camera exit",function()
        for i,pair in ipairs({{"01","0"},{"0","1"},{"1","1"}}) do
            local f,ui=open(unpack(pair)); f.mock.Click("Enable photo framing"); f.flush()
            eq(f.values[centered],"0"); eq(f.values[reduce],"0"); eq(button(f,"Enable photo framing"),nil)
            assert(ui.sliders[shoulder] and ui.sliders[foot]); assert(button(f,"Dynamic framing"))
            local j=f.r.db.camera.framing.journal.entries
            for index,key in ipairs({centered,reduce}) do
                if pair[index]~="0" then eq(j[key].originalRaw,pair[index]) else eq(j[key],nil) end
            end
            assert(f.r.camera.ApplyFraming({[shoulder]=1.5,[pitch]=1,[foot]=.6})); f.flush()
            if i%2==1 then f.mock.Click("Restore all framing") else assert(f.r.camera.Exit()) end
            f.flush()
            eq(f.values[centered],pair[1]); eq(f.values[reduce],pair[2])
            eq(f.values[shoulder],"0.00"); eq(f.values[foot],"0.35"); eq(f.values[pitch],"0")
            eq(next(f.r.db.camera.framing.journal.entries),nil)
        end
    end)
    test("CF03 later native checkbox choices survive exit and ordinary framing requests",function()
        for _,observe in ipairs({false,true}) do
            local f=open("1","0"); assert(f.r.camera.UsePhotoFraming()); f.flush()
            assert(f.r.camera.ApplyFraming({[shoulder]=1})); f.flush()
            f.values[reduce]="1"; if observe then f.r.framing.Observe() end
            local count=#f.calls; assert(f.r.camera.ApplyFOV(78)); f.flush(); eq(#f.calls,count+1)
            assert(f.r.camera.Exit()); f.flush()
            eq(f.values[centered],"0"); eq(f.values[reduce],"1"); eq(f.values[shoulder],"0.00")
            eq(next(f.r.db.camera.framing.journal.entries),nil)
        end
    end)
    test("CF04 no preset, slider queue or camera entry can opt into changing comfort preferences",function()
        local f=open("1","0")
        eq(f.r.camera.ApplyFraming({[centered]=0}),nil)
        eq(f.r.photoPreview.Queue(centered,0),nil)
        assert(f.r.photoComposition.Save("Native")); local preset=f.r.db.camera.composition.saved.Native
        eq(preset.framing[centered],nil); eq(preset.framing[reduce],nil)
        preset.framing[reduce]=0; eq(f.ns.PhotoComposition.ValidPreset(preset),false)
        eq(f.r.photoComposition.Apply("Native"),nil); eq(#f.calls,0)
        assert(f.r.camera.Exit()); f.flush(); eq(f.r.camera.UsePhotoFraming(),nil); eq(#f.calls,0)
    end)
    test("CF05 inaccessible or nonbinary preferences and combat do not authorize custom framing",function()
        local f,ui=open("1","0"); f.restricted=centered; ui.Build()
        eq(button(f,"Enable photo framing"):IsEnabled(),false); eq(f.r.camera.UsePhotoFraming(),nil)
        f.restricted=nil; f.values[reduce]="2"; eq(f.r.camera.UsePhotoFraming(),nil)
        f.values[reduce]="0"; f.env.InCombatLockdown=function() return true end
        eq(f.r.camera.UsePhotoFraming(),nil); eq(#f.calls,0)
    end)
    test("CF06 failing second flag compensates the first and preserves originals",function()
        local f=open("1","1")
        f.setter=function(k,v) if k==reduce and v=="0" then return false end; return f.native(k,v) end
        local done; f.r.camera.UsePhotoFraming(function(ok) done=ok end); f.flush()
        eq(done,false); eq(f.values[centered],"1"); eq(f.values[reduce],"1")
        eq(next(f.r.db.camera.framing.journal.entries),nil)
    end)
    test("CF07 verified flags survive reload as recovery data and restore only on an explicit action",function()
        local f=open("1","0"); assert(f.r.camera.UsePhotoFraming()); f.flush()
        local saved=f.ns.Value.Copy(f.r.db); local g=open("0","0",saved)
        eq(#g.calls,0); eq(g.r.db.camera.framing.journal.entries[centered].originalRaw,"1")
        g.mock.Click("Restore all framing"); g.flush(); eq(g.values[centered],"1")
        eq(next(g.r.db.camera.framing.journal.entries),nil)
    end)
    test("CF08 interrupted enable waits for manual recovery and refuses ambiguous external combinations",function()
        local f=open("1","0"); assert(f.r.camera.UsePhotoFraming())
        local saved=f.ns.Value.Copy(f.r.db); eq(saved.camera.framing.journal.entries[centered].state,"pending"); f.flush()
        local g=open("0","0",saved); eq(#g.calls,0)
        eq(g.r.camera.RestoreFraming(),nil); eq(#g.calls,0)
        g.mock.Click("Restore all framing"); g.flush(); eq(g.values[centered],"1"); eq(#g.calls,1)
        local h=open("0","1",saved); h.mock.Click("Restore all framing"); h.flush()
        eq(#h.calls,0); assert(h.r.db.camera.framing.journal.entries[centered])
    end)
    test("CF09 exiting during enable verification waits and returns the captured pair",function()
        local f=open("0","1"); assert(f.r.camera.UsePhotoFraming()); eq(f.r.camera.Exit(),nil); f.flush()
        eq(f.r.camera.active,false); eq(f.values[reduce],"1"); eq(f.values[centered],"0")
        eq(next(f.r.db.camera.framing.journal.entries),nil)
    end)
end
