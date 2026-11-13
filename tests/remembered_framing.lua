-- World Photo Offset controls exercised through the standalone mock client.
return function(make, eq, test)
    local shoulder, dynamic, foot = "test_cameraOverShoulder", "test_cameraDynamicPitch", "test_cameraDynamicPitchBaseFovPad"
    local center, reduce = "CameraKeepCharacterCentered", "CameraReduceUnexpectedMovement"
    local function enter(f)
        assert(f.r.camera.Toggle()); f.flush(); assert(f.r.camera.active)
    end
    local function leave(f)
        assert(f.r.camera.Exit()); f.flush(); eq(f.r.camera.active, false)
    end
    local function offset(f)
        f.mock.Click("Framing"); f.mock.Click("Offset")
    end
    local function drag(f, key, value)
        local slider = assert(f.r.composition.editor.sliders[key])
        slider.scripts.OnMouseDown(slider); slider:SetValue(value); slider.scripts.OnMouseUp(slider)
        f.flush()
    end
    test("MF01 verified Offset edits persist through reload; each visit restores its own exact originals", function()
        local f = make("01","0")
        enter(f); offset(f); f.mock.Click("Enable photo framing on entry"); f.flush()
        drag(f, shoulder, -1.3); f.mock.Click("Dynamic framing"); f.flush(); drag(f, foot, .62)
        local saved = f.r.db.camera.preferredFraming
        eq(saved[shoulder], -1.3); eq(saved[dynamic], 1); eq(saved[foot], .62)
        leave(f); eq(f.values[shoulder],"0.00"); eq(f.values[dynamic],"0"); eq(f.values[foot],"0.35"); eq(f.values[center],"01")
        local g = make("0","1.0",f.r.db)
        g.values[shoulder], g.values[dynamic], g.values[foot] = "0.800", "00", "0.275"
        eq(#g.calls,0); enter(g)
        eq(g.values[shoulder],"-1.3"); eq(g.values[dynamic],"1"); eq(g.values[foot],"0.62"); eq(g.values[reduce],"0")
        eq(g.calls[1][1],reduce)
        leave(g); eq(g.values[shoulder],"0.800"); eq(g.values[dynamic],"00"); eq(g.values[foot],"0.275"); eq(g.values[reduce],"1.0")
        eq(next(g.r.db.camera.framing.journal.entries),nil); eq(g.r.db.camera.preferredFraming[foot],.62)
    end)
    test("MF02 zero settings save explicitly and recall can be disabled without forgetting them", function()
        local f=make("0","0"); f.values[dynamic]="1"
        enter(f); offset(f); f.mock.Click("Dynamic framing"); f.flush()
        local n=#f.calls; f.mock.Click("Save current values"); eq(#f.calls,n)
        local saved=f.r.db.camera.preferredFraming
        eq(saved[dynamic],0); eq(saved[shoulder],0); eq(saved[foot],.35); eq(saved.cameraFov,nil)
        leave(f); eq(f.values[dynamic],"1")
        f.values[shoulder]="2"; n=#f.calls; enter(f); eq(#f.calls,n)
        assert(f.r.camera.SetFramingOnEntry(true)); f.flush()
        eq(f.values[dynamic],"0"); eq(f.values[shoulder],"0")
        assert(f.r.camera.RestoreFraming(nil,true)); f.flush()
        eq(f.values[dynamic],"1"); eq(f.values[shoulder],"2"); eq(saved[dynamic],0)
        assert(f.r.camera.SetFramingOnEntry(false)); leave(f); n=#f.calls; enter(f); eq(#f.calls,n)
    end)
    test("MF03 migration keeps consent and originals without learning values from an earlier journal", function()
        local f=make("1","0"); enter(f); assert(f.r.camera.SetFramingOnEntry(true)); f.flush()
        assert(f.r.camera.ApplyFraming({[shoulder]=1.5})); f.flush()
        local old=f.ns.Value.Copy(f.r.db); old.schemaVersion=21; old.camera.preferredFraming=nil
        local db,code=f.ns.Store.Open(old); eq(code,"MIGRATED_21_TO_23")
        eq(db.camera.photoFramingOnEntry,true); eq(next(db.camera.preferredFraming),nil)
        eq(db.camera.framing.journal.entries[shoulder].originalRaw,"0.00")
        for _,invalid in ipairs({{[center]=0},{cameraFov=75},{[dynamic]=.5},{[foot]=.275},{[shoulder]=-3.1},{[foot]="0"}}) do
            db.camera.preferredFraming=invalid; eq(f.ns.Store.Open(db),nil)
        end
    end)
    test("MF04 failed or cancelled previews and invalid snapshots leave verified choices intact", function()
        local f=make("0","0"); enter(f); offset(f); drag(f,shoulder,1.5)
        local saved=f.r.db.camera.preferredFraming
        f.setter=function(k,v) if k==shoulder and v=="2" then return false end; return f.native(k,v) end
        drag(f,shoulder,2); eq(saved[shoulder],1.5); eq(f.r.camera.SaveCurrentFraming(),nil)
        f.setter=nil; f.r.photoPreview.Begin(); assert(f.r.photoPreview.Queue(foot,.8))
        f.r.photoPreview.Cancel("TEST_CANCEL"); f.flush(); eq(saved[foot],nil)
        f.values[foot]="0.275"; eq(f.r.camera.SaveCurrentFraming(),nil)
        eq(f.r.db.camera.preferredFraming,saved); eq(saved[shoulder],1.5)
    end)
    test("MF05 unavailable controls are skipped independently and automatic recall never learns external values", function()
        local f=make("0","0"); local db=f.r.db.camera
        db.photoFramingOnEntry=true; db.preferredFraming={[shoulder]=1.1,[dynamic]=1,[foot]=.7}
        f.values[foot]=nil; enter(f); eq(f.values[foot],nil); eq(f.values[shoulder],"1.1"); eq(f.values[dynamic],"1")
        f.values[shoulder]="2.5"; f.r.framing.Observe(); eq(f.r.camera.Exit(),nil); f.flush(); eq(f.r.camera.active,false)
        eq(f.values[shoulder],"2.5"); eq(db.preferredFraming[shoulder],1.1); eq(db.preferredFraming[foot],.7)
        local n=#f.calls; enter(f); eq(#f.calls,n); eq(f.r.camera.error,"RESTORE_FRAMING_FIRST")
    end)
    test("MF06 a failed combined entry compensates the comfort flags and prior adjustments", function()
        local f=make("01","1"); local db=f.r.db.camera
        db.photoFramingOnEntry=true; db.preferredFraming={[shoulder]=1,[dynamic]=1,[foot]=.6}
        f.setter=function(k,v) if k==shoulder and v=="1" then return false end; return f.native(k,v) end
        enter(f); assert(f.r.camera.error)
        eq(f.values[center],"01"); eq(f.values[reduce],"1"); eq(f.values[foot],"0.35"); eq(f.values[dynamic],"0")
        eq(f.values[shoulder],"0.00"); eq(next(db.framing.journal.entries),nil); eq(db.preferredFraming[shoulder],1)
    end)
    test("MF07 immediate exit returns all live values; combat entry and startup leave them alone", function()
        local f=make("1","0"); local db=f.r.db.camera
        db.photoFramingOnEntry=true; db.preferredFraming={[shoulder]=1,[dynamic]=1,[foot]=.6}
        assert(f.r.camera.Toggle()); assert(f.r.framing.busy); f.r.camera.Toggle(); f.flush()
        eq(f.r.camera.active,false); eq(f.values[shoulder],"0.00"); eq(f.values[dynamic],"0"); eq(f.values[foot],"0.35")
        eq(f.values[center],"1"); eq(next(db.framing.journal.entries),nil)
        local n=#f.calls; f.env.InCombatLockdown=function() return true end; enter(f); eq(#f.calls,n)
    end)
end
