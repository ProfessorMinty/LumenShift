-- Saved consent and per-visit originals are exercised through simulated Camera entry and exit.
return function(make,eq,test)
    local centered,reduce="CameraKeepCharacterCentered","CameraReduceUnexpectedMovement"
    local label="Enable photo framing on entry"
    local function enter(f) assert(f.r.camera.Toggle()); f.flush(); eq(f.r.camera.active,true) end
    local function leave(f) assert(f.r.camera.Exit()); f.flush(); eq(f.r.camera.active,false) end
    local function offset(f) f.mock.Click("Framing"); f.mock.Click("Offset") end
    local function writes(f)
        local n=0
        for _,call in ipairs(f.calls) do if call[1]==centered or call[1]==reduce then n=n+1 end end
        return n
    end
    test("PF01 new and migrated preferences default off, preserving existing choices and recovery data",function()
        local f=make("1","0"); eq(f.r.db.camera.photoFramingOnEntry,false); enter(f)
        assert(f.r.camera.UsePhotoFraming()); f.flush()
        local old=f.ns.Value.Copy(f.r.db); old.schemaVersion=20; old.camera.photoFramingOnEntry=nil
        old.onboarding.completed=true
        local copy,code=f.ns.Store.Open(old); eq(code,"MIGRATED_20_TO_22"); eq(copy.schemaVersion,22)
        eq(copy.camera.photoFramingOnEntry,false); eq(copy.camera.framing.journal.entries[centered].originalRaw,"1")
        eq(copy.onboarding.completed,true); eq(old.camera.photoFramingOnEntry,nil)
        copy.camera.photoFramingOnEntry="on"; eq(f.ns.Store.Open(copy),nil)
    end)
    test("PF02 saving in Studio is write-free; each entry captures its own native values and restores them on exit",function()
        local f=make("01","0"); f.r.ui.Open(9); f.mock.Click(label)
        eq(f.r.db.camera.photoFramingOnEntry,true); eq(writes(f),0)
        local g=make("01","0",f.r.db); eq(g.r.db.camera.photoFramingOnEntry,true); eq(#g.calls,0)
        enter(g); eq(g.values[centered],"0"); eq(g.r.db.camera.framing.journal.entries[centered].originalRaw,"01")
        assert(g.r.camera.ApplyFraming({test_cameraOverShoulder=1.4,test_cameraDynamicPitch=1,test_cameraDynamicPitchBaseFovPad=.58})); g.flush()
        leave(g); eq(g.values[centered],"01"); eq(g.values[reduce],"0"); eq(g.values.test_cameraOverShoulder,"0.00")
        eq(g.values.test_cameraDynamicPitch,"0"); eq(g.values.test_cameraDynamicPitchBaseFovPad,"0.35")
        g.values[centered],g.values[reduce],g.values.test_cameraOverShoulder="0","1.0","0.8"
        enter(g); eq(g.values[reduce],"0"); eq(g.r.db.camera.framing.journal.entries[reduce].originalRaw,"1.0")
        eq(g.values.test_cameraOverShoulder,"0.8"); leave(g); eq(g.values[reduce],"1.0")
        eq(next(g.r.db.camera.framing.journal.entries),nil); eq(g.r.db.camera.photoFramingOnEntry,true)
    end)
    test("PF03 Offset saves and enables in one click; Restore applies for the visit and opting out changes future entries",function()
        local f=make("0","1"); enter(f); offset(f); f.mock.Click(label); f.flush()
        eq(f.r.db.camera.photoFramingOnEntry,true); eq(f.values[reduce],"0")
        f.mock.Click("Restore all framing"); f.flush(); eq(f.values[reduce],"1"); eq(f.r.db.camera.photoFramingOnEntry,true)
        f.mock.Click("Guides"); f.mock.Click("Offset"); eq(f.values[reduce],"1"); leave(f)
        enter(f); eq(f.values[reduce],"0"); f.mock.Click(label); f.flush()
        eq(f.r.db.camera.photoFramingOnEntry,false); eq(f.values[reduce],"0")
        leave(f); eq(f.values[reduce],"1"); local n=writes(f); enter(f); eq(writes(f),n)
        f.mock.Click("Enable photo framing"); f.flush(); eq(f.values[reduce],"0"); eq(f.r.db.camera.photoFramingOnEntry,false)
        leave(f); eq(f.values[reduce],"1")
    end)
    test("PF04 saved framing composes with verified name hiding and temporary quality without overlapping writers",function()
        local f=make("1","0")
        local db=f.r.db.camera; db.hideWithUI=true; db.photoEnabled=true; db.photoLevel=6
        f.values.RAIDsettingsEnabled="0"; local quality=f.values.graphicsQuality
        assert(f.r.camera.SetFramingOnEntry(true)); enter(f)
        eq(f.values.UnitNameFriendlyPlayerName,"0"); eq(f.values[centered],"0")
        assert(db.photo.records.normal); eq(f.r.camera.error,nil)
        leave(f); eq(f.values.UnitNameFriendlyPlayerName,"1"); eq(f.values[centered],"1"); eq(f.values.graphicsQuality,quality)
        eq(db.photo.records.normal,nil); eq(next(db.framing.journal.entries),nil)
    end)
    test("PF05 exit, opting out, restore, combat and world leave invalidate queued entry framing",function()
        for _,stop in ipairs({"exit","off","restore","combat","world"}) do
            local f=make("1","0"); local c=f.r.camera; f.r.db.camera.hideWithUI=true; c.SetFramingOnEntry(true)
            assert(c.Toggle()); assert(not c.active); f.tick(); assert(c.active); eq(writes(f),0)
            if stop=="exit" then assert(c.Exit())
            elseif stop=="off" then c.SetFramingOnEntry(false)
            elseif stop=="restore" then assert(c.RestoreFraming())
            elseif stop=="combat" then c.Combat()
            else f.frame.OnEvent(f.frame,"PLAYER_LEAVING_WORLD"); f.r.composition.Show() end
            f.flush(); eq(writes(f),0); eq(f.values[centered],"1")
        end
    end)
    test("PF06 combat entry stays at current native settings, with no queued reapply after combat",function()
        local f=make("1","1"); f.r.camera.SetFramingOnEntry(true); f.env.InCombatLockdown=function() return true end
        enter(f); eq(#f.calls,0); f.env.InCombatLockdown=function() return false end
        f.frame.OnEvent(f.frame,"PLAYER_REGEN_ENABLED"); f.flush(); eq(#f.calls,0)
        leave(f); enter(f); eq(f.values[centered],"0"); eq(f.values[reduce],"0"); leave(f)
        eq(f.values[centered],"1"); eq(f.values[reduce],"1")
    end)
    test("PF07 an external checkbox change survives the exit while the saved opt-in remains available",function()
        local f=make("1","0"); f.r.camera.SetFramingOnEntry(true); enter(f)
        f.values[reduce]="1"; f.r.framing.Observe(); leave(f)
        eq(f.values[centered],"0"); eq(f.values[reduce],"1"); enter(f); eq(f.values[reduce],"0")
        leave(f); eq(f.values[centered],"0"); eq(f.values[reduce],"1")
    end)
    test("PF08 restricted and interrupted preferences leave Camera usable without losing an earlier original",function()
        local f=make("1","0"); f.r.camera.SetFramingOnEntry(true); f.restricted=centered
        enter(f); eq(writes(f),0); assert(f.r.camera.error); leave(f); f.restricted=nil
        assert(f.r.camera.Toggle()); local saved=f.ns.Value.Copy(f.r.db); assert(saved.camera.framing.journal.entries[centered])
        local g=make("0","0",saved); eq(#g.calls,0); enter(g); eq(writes(g),0)
        eq(g.r.camera.error,"RESTORE_FRAMING_FIRST"); offset(g); g.mock.Click("Restore all framing"); g.flush()
        eq(g.values[centered],"1"); leave(g); enter(g); eq(g.values[centered],"0")
        leave(g); eq(g.values[centered],"1")
    end)
    test("PF09 immediate toggle exit during framing verification restores both originals",function()
        local f=make("01","1"); f.r.camera.SetFramingOnEntry(true); assert(f.r.camera.Toggle())
        eq(f.r.framing.busy,true); f.r.camera.Toggle(); f.flush()
        eq(f.r.camera.active,false); eq(f.values[centered],"01"); eq(f.values[reduce],"1")
        eq(next(f.r.db.camera.framing.journal.entries),nil)
    end)
    test("PF10 enabled preference leaves native free framing alone, keeps external changes, and fits both panel sizes",function()
        local f=make("0","0"); f.r.camera.SetFramingOnEntry(true); enter(f); offset(f)
        eq(writes(f),0); eq(next(f.r.db.camera.framing.journal.entries),nil)
        f.values[reduce]="1"; f.r.framing.Observe(); leave(f)
        eq(f.values[reduce],"1"); eq(writes(f),0)
        f.env.UIParent:SetSize(600,400); enter(f)
        local ui=f.r.composition.editor
        eq(ui.scrollbar.maximum,0); eq(ui.scrollbar:IsShown(),false); eq(f.values[reduce],"0")
        leave(f); eq(f.values[reduce],"1")
    end)
end
