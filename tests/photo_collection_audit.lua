-- Off-client regressions only. No test certifies native labels, actors or captures.
return function(make, eq, test)
    local function fixture()
        local f=make(); f.start()
        for _,key in ipairs(f.ns.NamePolicy.AllKeys) do f.values[key]="1" end
        return f
    end
    local function button(f,label)
        for _,node in ipairs(f.mock.nodes) do
            if node.kind=="Button" and node.label and node.label.text==label and node:IsVisible() then return node end
        end
        error("Missing button "..label)
    end
    test("NA01 explicit NPC switch applies immediately including special quest-giver keys",function()
        local f=fixture(); assert(f.p.World()); f.ui.tab="Frame"; f.ui.Build(); f.mock.Click("Visibility")
        f.mock.Click("Hide NPC / quest-giver names"); f.flush()
        for _,key in ipairs({"UnitNameNPC","UnitNameFriendlySpecialNPCName","UnitNameInteractiveNPC","UnitNameHostleNPC","UnitNameNonCombatCreatureName"}) do
            eq(f.values[key],"0"); eq(f.r.db.camera.journal.entries[key].originalRaw,"1")
        end
        eq(f.r.camera.nameResult.ok,true); eq(f.values.UnitNameFocused,"1")
        f.mock.Click("Hide NPC / quest-giver names"); f.flush(); eq(f.values.UnitNameFriendlySpecialNPCName,"1")
        eq(next(f.r.db.camera.journal.entries),nil)
    end)
    test("NA02 Hide all includes focused and minion names without touching chat or graphics",function()
        local f=fixture(); f.ui.tab="Frame"; f.ui.Build(); f.mock.Click("Visibility"); f.values.UnitNameFocused="01"
        f.mock.Click("Hide all names"); f.flush()
        for _,g in ipairs(f.ns.NamePolicy.Groups) do for _,key in ipairs(g.keys) do eq(f.values[key],g.id=="bubbles" and "1" or "0") end end
        eq(button(f,"Hide focused-unit names").value,true,"focused switch"); eq(button(f,"Hide NPC / quest-giver names").value,true,"npc switch")
        eq(button(f,"Hide all names").disabled,false)
        for _,call in ipairs(f.calls) do assert(f.ns.NamePolicy.Known(call[1])) end
        f.mock.Click("Restore names"); f.flush(); eq(f.values.UnitNameFocused,"01")
        eq(next(f.r.db.camera.journal.entries),nil); eq(button(f,"Hide focused-unit names").value,false)
    end)
    test("NA03 missing focused API setting is disclosed while available NPC keys still apply",function()
        local f=fixture(); f.values.UnitNameFocused=nil
        assert(f.r.camera.EditNames("all",true)); f.flush(); eq(f.values.UnitNameNPC,"0"); eq(f.values.UnitNameFocused,nil)
        eq(#f.r.camera.unavailableNames,1); eq(f.r.camera.unavailableNames[1],"UnitNameFocused")
        eq(f.r.db.camera.journal.entries.UnitNameFocused,nil); eq(f.r.camera.nameResult.ok,true)
        assert(f.ns.Report.Export(f.r):find("UnitNameFocused",1,true))
    end)
    test("NA04 restricted focused names are skipped without bypassing their security flags",function()
        local f=fixture(); f.restricted="UnitNameFocused"
        assert(f.r.camera.EditNames("all",true)); f.flush(); eq(f.values.UnitNameFocused,"1"); eq(f.values.UnitNameNPC,"0")
        eq(f.r.db.camera.journal.entries.UnitNameFocused,nil); assert(#f.r.camera.unavailableNames>0)
    end)
    test("NA05 combat name clicks do not edit preferences queue writes or disturb filters",function()
        local f=fixture(); assert(f.r.photoEditor.Recipe("ember")); f.env.InCombatLockdown=function() return true end
        eq(f.r.camera.EditNames("all",true),nil); eq(f.r.camera.nameResult.code,"COMBAT_OR_RESTRICTION")
        eq(f.r.db.camera.nameGroups.focused,false); eq(f.r.db.camera.nameGroups.npcs,false)
        f.env.InCombatLockdown=function() return false end; f.flush(); eq(#f.calls,0)
        eq(f.r.db.camera.editor.look.warmth,.55); eq(f.p.active,true)
    end)
    test("NA06 pending name edits reject a second operation without losing its preference",function()
        local f=fixture(); assert(f.r.camera.EditNames("npcs",true)); eq(f.r.camera.EditNames("focused",true),nil)
        eq(f.r.db.camera.nameGroups.focused,false); f.flush(); eq(f.r.camera.nameResult.ok,true)
        assert(f.r.camera.EditNames("focused",true)); f.flush(); eq(f.values.UnitNameFocused,"0")
    end)
    test("NA07 failed names retain the original and visible failure without retrying",function()
        local f=fixture(); f.setter=function(key) f.values[key]="0"; return false end
        f.r.camera.EditNames("focused",true); f.flush(); eq(f.r.camera.nameResult.ok,false)
        assert(f.r.camera.nameResult.code); assert(f.r.db.camera.journal.entries.UnitNameFocused)
        eq(f.r.db.camera.journal.entries.UnitNameFocused.originalRaw,"1")
        local calls=#f.calls; f.ui.tab="Frame"; f.ui.Build(); f.mock.Click("Visibility"); f.flush(); eq(#f.calls,calls)
    end)
    test("NA08 an external focused-name change survives Restore with recovery retained",function()
        local f=fixture(); assert(f.r.camera.EditNames("focused",true)); f.flush()
        f.values.UnitNameFocused="00"; f.r.names.Observe(); local calls=#f.calls
        eq(f.r.camera.EditNames("all",false),nil); f.flush(); eq(#f.calls,calls); eq(f.values.UnitNameFocused,"00")
        assert(f.r.db.camera.journal.entries.UnitNameFocused); eq(f.r.camera.nameResult.ok,false)
    end)
    test("NA09 Exit restores exact originals after hide choices without a Narcissus dependency",function()
        local f=fixture(); f.values.UnitNameFocused="01"; f.values.UnitNameFriendlySpecialNPCName="00"
        assert(f.r.camera.EditNames("all",true)); f.flush(); assert(f.r.camera.Exit()); f.flush()
        eq(f.values.UnitNameFocused,"01"); eq(f.values.UnitNameFriendlySpecialNPCName,"00")
        eq(f.r.db.camera.nameReturn,nil); eq(next(f.r.db.camera.journal.entries),nil); eq(f.env.Narci,nil)
    end)
    test("NA10 schema 18 migration preserves source outfits names and recovery without writes",function()
        local f=fixture(); assert(f.r.camera.EditNames("npcs",true)); f.flush(); assert(f.p.TrySource(1,502)); f.flush()
        assert(f.p.SaveOutfit("Exact source")); local old=f.ns.Value.Copy(f.r.db)
        old.schemaVersion=18; old.camera.nameGroups.focused=nil; old.onboarding.completed=true
        local db,why=f.ns.Store.Open(old); eq(why,"MIGRATED_18_TO_22"); eq(db.camera.nameGroups.focused,false)
        eq(db.camera.nameGroups.npcs,true); eq(db.onboarding.completed,true)
        eq(db.camera.portrait.outfits["Exact source"][1].sourceID,502)
        eq(db.camera.journal.entries.UnitNameFriendlySpecialNPCName.originalRaw,"1"); eq(old.camera.nameGroups.focused,nil)
        local writes=#f.calls; assert(f.ns.Store.Open(db)); eq(#f.calls,writes)
        db.camera.nameGroups.focused="yes"; eq(f.ns.Store.Open(db),nil)
    end)
    test("NA11 name controls work in staged Scene and Retry receives no button as callback",function()
        local f=fixture(); f.ui.tab="Frame"; f.ui.Build(); f.mock.Click("Visibility"); f.mock.Click("Hide focused-unit names"); f.flush()
        f.mock.Click("Retry name choices"); f.flush(); eq(f.r.camera.nameResult.ok,true); eq(f.p.active,true)
        f.ui.tab="Pose"; f.ui.Build(); eq(f.ui.RefreshNames,nil)
    end)
    test("NA12 rejected initial collection scheduling cannot resurrect a cancelled load",function()
        local f=fixture(); f.collection.Discover()
        local after=f.env.C_Timer.After
        f.env.C_Timer.After=function(delay,fn) after(delay,fn); error("queued then failed") end
        eq(f.collection.Load(1),nil); local status=f.collection.status; f.env.C_Timer.After=after; f.flush()
        eq(f.collection.loaded,false); eq(#f.collection.rows,0); eq(f.collection.status,status)
    end)
    test("NA13 rejected subsequent collection scheduling invalidates late callbacks",function()
        local f=fixture(); f.collection.Discover()
        for i=3,25 do f.appearances[1][i]={visualID=1000+i,isCollected=false,isHideVisual=false} end
        assert(f.collection.Load(1)); local after=f.env.C_Timer.After
        f.env.C_Timer.After=function(delay,fn) after(delay,fn); error("queued then failed") end
        f.tick(); local count,status=#f.collection.rows,f.collection.status; eq(count,24)
        f.env.C_Timer.After=after; f.flush(); eq(#f.collection.rows,count); eq(f.collection.loaded,false); eq(f.collection.status,status)
    end)
    test("NA14 partial source metadata and browser size limits are disclosed",function()
        for _,size in ipairs({2,1025}) do
            local f=fixture(); local data={}; for i=1,size do data[i]=f.ns.Value.Copy(f.sources[501]); data[i].sourceID=2000+i end
            if size==2 then data[2].categoryID=99 end
            f.env.C_TransmogCollection.GetAppearanceSources=function() return data end; f.load()
            assert(f.collection.status:find("incomplete",1,true)); eq(f.collection.loaded,true)
            local row; for _,v in ipairs(f.collection.rows) do if v.visualID==101 then row=v end end
            eq(#row.sources,size==2 and 1 or 1024)
        end
    end)
    test("NA15 returning to a cancelled browser resumes reads but redraws never retry native errors",function()
        local f=fixture(); f.ui.tab="Pose"; f.ui.actorTab="Outfits"; f.ui.wardrobeTab="Collection"; f.ui.Build()
        assert(f.collection.busy); f.ui.tab="Frame"; f.ui.Build(); f.mock.Click("Visibility"); eq(f.collection.busy,false)
        f.ui.tab="Pose"; f.ui.Build(); f.flush(); eq(f.collection.loaded,true); eq(#f.collection.rows,2)
        f.env.C_TransmogCollection.GetCategoryAppearances=function() f.reads=f.reads+1; return nil end
        f.collection.Load(1); local count=f.reads; f.ui.Build(); f.ui.Build(); eq(f.reads,count)
    end)
    test("NA16 source preview changes only the selected actor while another actor is preserved",function()
        local f=fixture(); assert(f.p.TrySource(1,502)); f.flush(); local first=f.front(1)
        assert(f.p.Add("target")); f.flush(); assert(f.p.TrySource(1,503)); f.flush()
        eq(f.front(1),first); eq(f.front(1).sources[1],502); eq(f.front().sources[1],503); eq(#f.calls,0)
    end)
    test("NA17 restoring names preserves pre-photo manual intent and separate bubble choices",function()
        local f=fixture(); assert(f.r.camera.Exit()); f.flush(); assert(f.r.camera.ToggleNames()); f.flush()
        eq(f.values.UnitNameFriendlyPlayerName,"0"); assert(f.r.camera.Toggle()); f.flush()
        assert(f.r.camera.EditNames("bubbles",true)); f.flush(); assert(f.r.camera.EditNames("all",true)); f.flush()
        assert(f.r.camera.EditNames("all",false)); f.flush()
        eq(f.values.UnitNameNPC,"1"); eq(f.values.UnitNameFriendlyPlayerName,"0"); eq(f.values.chatBubbles,"0")
        assert(f.r.camera.Exit()); f.flush(); eq(f.values.chatBubbles,"1"); eq(f.values.UnitNameFriendlyPlayerName,"0")
        assert(f.r.camera.RestoreNames()); f.flush(); eq(f.values.UnitNameFriendlyPlayerName,"1")
    end)
    test("NA18 capture and invalid name requests do not change saved choices or run a writer",function()
        local f=fixture(); eq(f.r.camera.EditNames("arbitrary",true),nil); eq(f.r.camera.EditNames("npcs",1),nil)
        f.r.composition.capturing=true; eq(f.r.camera.EditNames("all",true),nil); f.r.composition.capturing=false
        f.flush(); eq(#f.calls,0); eq(f.r.db.camera.nameGroups.npcs,false)
    end)
    test("NA19 name controls refresh on bulk actions without stale callbacks on pooled buttons",function()
        local f=fixture(); f.ui.tab="Frame"; f.ui.Build(); f.mock.Click("Visibility"); f.mock.Click("Hide all names"); f.flush()
        eq(button(f,"Hide focused-unit names").value,true)
        local W=f.ns.Widgets; local parent=f.env.CreateFrame("Frame",nil,f.env.UIParent); local pool=W.CreatePool(f.env,parent)
        local toggle=W.Toggle(pool.env,parent,"Toggle",0,0,200,function() return true end,function() end)
        assert(toggle.RefreshValue); pool.Reset()
        local normal=W.Button(pool.env,parent,"Normal",0,0,200,function() end); eq(normal,toggle); eq(normal.RefreshValue,nil)
    end)
end
