-- Simulated native models/items and combat. No live visual acceptance is implied.
return function(make,eq,test)
    local function fixture(fallback,saved)
        local f=make(fallback,saved)
        f.items={ [1001]={name="Silver Hat",loc="INVTYPE_HEAD"}, [1002]={name="Amber Robe",loc="INVTYPE_ROBE"},
            [1003]={name="Glass Sword",loc="INVTYPE_WEAPON"}, [1004]={name="Round Shield",loc="INVTYPE_SHIELD"},
            [1005]={name="Blue Cloak",loc="INVTYPE_CLOAK"}, [1006]={name="Boots",loc="INVTYPE_FEET"} }
        f.equipped={[1]=1001,[5]=1002,[16]=1003}; f.itemRequests={}
        f.env.GetInventoryItemID=function(_,slot) return f.equipped[slot] end
        f.env.C_Item={ GetItemInfo=function(id)
            local v=f.items[id]; if not v or f.uncached==id then return end
            return v.name,"item:"..id,2,10,1,"Armor","Cloth",1,v.loc,123
        end, RequestLoadItemDataByID=function(id) f.itemRequests[#f.itemRequests+1]=id end }
        f.env.C_Container={GetContainerNumSlots=function(b) return b==0 and 3 or 0 end,
            GetContainerItemID=function(_,i) return ({1004,1005,1006})[i] end}
        f.env.C_EquipmentSet={GetEquipmentSetIDs=function() return {0,2} end,
            GetEquipmentSetInfo=function(id) return "Native set "..id end,
            GetItemIDs=function(id) return id==0 and {[1]=1001,[5]=1002,[16]=1003} or {[15]=1005,[17]=1004} end}
        return f
    end
    test("PX01 expanded grouped poses and variation operate only on staged copies",function()
        local f=fixture(); f.start(); eq(#f.ns.PortraitLibrary.Poses,56)
        eq(#f.ns.PortraitLibrary.FindPoses("Social","wave"),1)
        assert(f.p.SetActor("animation",125)); assert(f.p.SetActor("variation",3)); eq(f.front().anim,125); eq(f.front().variation,3)
        eq(f.p.SetActor("variation",6),nil); eq(f.p.slots[1].spec.variation,3); eq(#f.calls,0)
    end)
    test("PX02 spell effects replace clear save and tear down without any world spell cast",function()
        local f=fixture(); f.start(); assert(f.p.SetActor("spellKit",16556)); eq(f.front().kit,16556)
        assert(f.p.SetActor("spellKit",10650)); eq(f.front().kit,10650); assert(f.p.Save("Magic"))
        assert(f.p.SetActor("spellKit",0)); eq(f.front().kit,0); assert(f.p.Load("Magic")); f.flush(); eq(f.front().kit,10650)
        f.p.Exit(); for _,m in ipairs(f.models) do eq(m.kit,0); eq(m.unit,nil) end; eq(#f.calls,0)
    end)
    test("PX03 unavailable spell methods and invalid IDs affect only that control",function()
        local f=fixture(); assert(f.p.backend.Build()); for _,m in ipairs(f.models) do m.SetSpellVisualKit=nil end
        f.start(); eq(f.p.SetActor("spellKit",16556),nil); assert(f.p.SetActor("x",1))
        local g=fixture(); g.start(); eq(g.p.SetActor("spellKit",123456789),nil); eq(g.front().kit,0)
        g.spellError=true; eq(g.p.SetActor("spellKit",16556),nil); eq(g.p.slots[1].spec.spellKit,0)
    end)
    test("PX04 wardrobe reads native equipped bags and equipment sets without equipping",function()
        local f=fixture(); f.start(); assert(f.p.wardrobe.Refresh()); eq(#f.p.wardrobe.items,6); eq(#f.p.wardrobe.sets,2)
        eq(#f.p.wardrobe.Items(17,"sword"),1); eq(#f.p.wardrobe.Items(5,"robe"),1); eq(#f.calls,0)
    end)
    test("PX05 outfit swaps are buffered and slot edits never modify actual equipment",function()
        local f=fixture(); f.start(); local old=f.front(); assert(f.p.TryItem(17,1003)); eq(f.front(),old)
        f.flush(); eq(f.front().items[17],1003); eq(f.front().hand,"SECONDARYHANDSLOT"); eq(f.equipped[17],nil)
        eq(f.p.TryItem(5,1001),nil); eq(f.front().items[17],1003); eq(#f.calls,0)
    end)
    test("PX06 native outfit rejection preserves the whole previous visible model",function()
        local f=fixture(); f.start(); assert(f.p.TryItem(5,1002)); f.flush(); local old=f.front()
        f.tryOnError=1; assert(f.p.TryItem(1,1001)); f.flush(); eq(f.front(),old); eq(old.shown,true)
        eq(f.p.slots[1].spec.outfit[1],nil); eq(f.p.slots[1].spec.outfit[5],1002)
    end)
    test("PX07 unavailable item data requests cache loading without a queued wardrobe mutation",function()
        local f=fixture(); f.start(); local old=f.front(); f.uncached=1001
        eq(f.p.TryItem(1,1001),nil); eq(f.front(),old); eq(#f.itemRequests,1); f.flush(); eq(f.front(),old)
        f.uncached=nil; assert(f.p.TryItem(1,1001)); f.flush(); eq(f.front().items[1],1001)
    end)
    test("PX08 missing wardrobe APIs keep models and the rest of Photo Studio usable",function()
        local f=fixture(); f.start(); f.env.C_Item=nil; f.env.C_Container=nil; f.env.C_EquipmentSet=nil; f.env.GetInventoryItemID=nil
        assert(f.p.wardrobe.Refresh()); eq(#f.p.wardrobe.items,0); eq(f.p.UseEquippedOutfit(),nil)
        assert(f.p.SetActor("scale",1.2)); eq(f.front().shown,true); eq(#f.calls,0)
    end)
    test("PX09 wardrobe strings are data only and invalid inputs never reach TryOn",function()
        local f=fixture(); f.start(); local w=f.p.wardrobe
        eq(w.Parse("|cffaabbcc|Hitem:1001:0|h[Hat]|h|r"),1001); eq(w.Parse("1002"),1002)
        eq(w.Parse("/run evil()"),nil); eq(f.p.TryItem(1,nil),nil); eq(f.p.TryItem(1,math.huge),nil)
        eq(f.p.SetOutfit({[99]=1001}),nil); eq(f.p.SetOutfit({[1]=-1}),nil); eq(#f.calls,0)
    end)
    test("PX10 saved outfits capture base equipment and explicit overrides then preview without writes",function()
        local f=fixture(); f.start(); assert(f.p.TryItem(15,1005)); f.flush(); assert(f.p.SaveOutfit("Mine"))
        local outfit=f.r.db.camera.portrait.outfits.Mine; eq(outfit[1],1001); eq(outfit[15],1005); eq(outfit[17],0)
        assert(f.p.SetOutfit({})); f.flush(); assert(f.p.SetOutfit(outfit)); f.flush(); eq(f.front().items[15],1005)
        eq(f.equipped[15],nil); eq(#f.calls,0)
    end)
    test("PX11 retargeting cannot refresh or save another actor's outfit",function()
        local f=fixture(); f.start(); assert(f.p.Add("target")); f.flush(); local old=f.front(); f.units.target="new"
        eq(f.p.TryItem(1,1001),nil); eq(f.p.SaveOutfit("Wrong"),nil); eq(f.front(),old); eq(f.r.db.camera.portrait.outfits.Wrong,nil)
    end)
    test("PX12 pending outfit loads cannot resurrect an exited stage",function()
        local f=fixture(); f.start(); f.neverLoad=true; assert(f.p.TryItem(5,1002)); f.p.Exit(); f.neverLoad=false; f.flush()
        eq(f.p.active,false); for _,m in ipairs(f.models) do eq(m.shown,false); eq(m.unit,nil) end
    end)
    test("PX13 fallback keeps wardrobe and extra poses independent of spell effects",function()
        local f=fixture(true); f.start(); assert(f.p.SetActor("animation",113)); assert(f.p.SetActor("variation",1))
        assert(f.p.TryItem(1,1001)); f.flush(); eq(f.front().items[1],1001)
        eq(f.p.SetActor("spellKit",16556),nil); eq(f.front().shown,true)
    end)
    test("PX14 schema 16 migrates portrait data without resetting previous choices or mutating input",function()
        local f=fixture(); f.start(); assert(f.p.SetActor("animation",69)); assert(f.p.Save("Old"))
        local old=f.ns.Value.Copy(f.r.db); old.schemaVersion=16; old.camera.keepInCombat=nil; old.camera.effectsInCombat=nil
        local p=old.camera.portrait; p.version=1; p.outfits=nil
        for _,s in ipairs({p.scene,p.saved.Old}) do s.version=1; for _,a in pairs(s.actors) do a.variation=nil; a.outfit=nil; a.spellKit=nil end end
        local db,code=f.ns.Store.Open(old); assert(db); eq(code,"MIGRATED_16_TO_21"); eq(db.camera.portrait.saved.Old.actors[1].animation,69)
        eq(db.camera.keepInCombat,true); eq(db.camera.effectsInCombat,true); eq(old.camera.portrait.version,1); eq(old.camera.keepInCombat,nil)
    end)
    test("PX15 corrupt new saved data is preserved rather than silently reset",function()
        local f=fixture(); local bad=f.ns.Value.Copy(f.r.db); bad.camera.portrait.outfits.Bad={[99]=123}
        eq(f.ns.Store.Open(bad),nil); eq(bad.camera.portrait.outfits.Bad[99],123)
        bad=f.ns.Value.Copy(f.r.db); bad.camera.keepInCombat="yes"; eq(f.ns.Store.Open(bad),nil)
    end)
    test("PX16 full scene outfit light look and visual banks fit the saved data budget",function()
        local f=fixture(); f.start(); assert(f.p.Add("target")); f.flush(); assert(f.p.Add("pet")); f.flush()
        for i=1,3 do f.p.selected=i; assert(f.p.UseEquippedOutfit()); f.flush(); assert(f.p.SetActor("spellKit",10650)) end
        for i=1,8 do assert(f.p.Save("Scene"..i)); assert(f.p.Save("Light"..i,true)); assert(f.p.SaveOutfit("Outfit"..i)) end
        eq(f.p.SaveOutfit("Ninth"),nil)
        for i=1,12 do assert(f.r.photoEditor.Save("Look"..i)) end
        for i=1,24 do f.r.db.config.studio=assert(f.ns.StudioConfig.SavePreset(f.r.db.config.studio,"Preset"..i,"nightVision")) end
        assert(f.ns.Store.Open(f.r.db),"full supported save banks must survive reload")
    end)
    test("PX17 default combat keeps models filters and capture active without graphics writes",function()
        local f=fixture(); f.start(); assert(f.r.photoEditor.Recipe("ember")); local old=f.front()
        f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED")
        eq(f.p.active,true); eq(f.front(),old); eq(f.r.photoEffects.root:IsShown(),true); eq(f.env.UIParent:IsShown(),false)
        assert(f.r.photoEditor.Set("vignette",.6)); assert(f.p.SetActor("x",.4)); assert(f.c.Capture()); f.tick(); eq(f.captures,1)
        f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_SUCCEEDED"); f.flush(); eq(#f.calls,0)
    end)
    test("PX18 combat HUD preference keeps the selected look while returning to gameplay",function()
        local f=fixture(); f.start(); f.r.photoEditor.Recipe("ember"); f.r.db.camera.keepInCombat=false
        f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED")
        eq(f.env.UIParent:IsShown(),true); eq(f.p.active,false); eq(f.c.root:IsShown(),false); eq(f.r.photoEffects.root:IsShown(),true)
        f.env.InCombatLockdown=function() return false end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_ENABLED")
        eq(f.r.photoEffects.root:IsShown(),true); eq(f.c.root:IsShown(),false); eq(#f.calls,0)
    end)
    test("PX19 opt-out can hide combat filters temporarily without resetting the saved look",function()
        local f=fixture(); f.start(); f.r.photoEditor.Recipe("ember"); f.r.db.camera.effectsInCombat=false
        local warmth=f.r.db.camera.editor.look.warmth
        f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED")
        eq(f.r.photoEffects.root:IsShown(),false); eq(f.r.db.camera.editor.look.warmth,warmth); eq(f.p.active,true)
        f.env.InCombatLockdown=function() return false end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_ENABLED")
        eq(f.r.photoEffects.root:IsShown(),true); eq(#f.calls,0)
    end)
    test("PX20 combat entry uses current native settings and Escape exits without deferred writes",function()
        local f=fixture(); assert(f.r.camera.Exit()); f.flush(); f.r.db.camera.hideWithUI=true; f.r.db.camera.photoEnabled=true
        f.env.InCombatLockdown=function() return true end; assert(f.r.camera.Toggle()); eq(#f.calls,0)
        f.c.input.scripts.OnKeyDown(f.c.input,"H"); eq(f.c.controlsHidden,true)
        f.c.input.scripts.OnKeyDown(f.c.input,"ESCAPE"); f.flush(); eq(f.r.camera.active,false); eq(f.env.UIParent:IsShown(),true); eq(#f.calls,0)
    end)
    test("PX21 native photo edits still refuse combat while cosmetic sliders work",function()
        local f=fixture(); f.start(); f.env.InCombatLockdown=function() return true end
        assert(f.r.photoEditor.Recipe("ember")); assert(f.r.photoEditor.Set("glow",.4))
        eq(f.r.photoEditor.Native({Brightness=80}),nil); eq(f.r.camera.ApplyNames(),nil); eq(#f.calls,0)
        f.env.InCombatLockdown=function() return false end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_ENABLED"); f.flush(); eq(#f.calls,0)
    end)
    test("PX22 timed capture and pending actor loads continue under the keep-in-combat preference",function()
        local f=fixture(); f.start(); f.neverLoad=true; assert(f.p.TryItem(1,1001))
        f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED"); f.neverLoad=false; for _,m in ipairs(f.models) do if m.unit then m.loaded=true end end; f.flush()
        eq(f.front().items[1],1001); assert(f.r.captureSequence.Start()); f.tick(); f.tick(); f.tick(); f.tick()
        eq(f.captures,1); f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_SUCCEEDED"); f.flush(); eq(f.r.captureSequence.state,"COMPLETE")
    end)
    test("PX23 expanded standalone UI reaches poses outfits effects and combat preferences",function()
        local f=fixture(); f.start(); f.ui.tab="Pose"; f.ui.Build(true)
        for _,tab in ipairs({"Poses","Outfits","Effects","Transform"}) do f.mock.Click(tab); eq(f.ui.actorTab,tab) end
        f.ui.tab="Capture"; f.ui.Build(true); eq(f.env.Narci,nil); eq(#f.calls,0)
    end)
    test("PX24 expanded browser rebuilds reuse owned frames and textures",function()
        local f=fixture(); f.start(); f.ui.tab="Pose"; f.ui.actorTab="Outfits"; f.p.wardrobe.Refresh(); f.ui.Build()
        local count=#f.mock.nodes; for i=1,30 do f.ui.Build() end; eq(#f.mock.nodes,count)
    end)
    test("PX25 missing or restricted kit readback cannot claim an applied selection",function()
        local f=fixture(); f.start(); f.front().GetSpellVisualKit=function() return -1 end
        eq(f.p.SetActor("spellKit",10650),nil); eq(f.p.slots[1].spec.spellKit,0); eq(#f.calls,0)
    end)
    test("PX26 regular visual-mode cosmetics also remain constant through combat",function()
        local f=fixture(); assert(f.r.camera.Exit()); f.flush(); assert(f.r.product.Enable(true))
        assert(f.r.product.Select("nightVision")); f.flush(); local count=#f.calls; local p=f.r.presentation
        eq(p.frame:IsShown(),true); f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED")
        eq(p.frame:IsShown(),true); eq(#f.calls,count)
        f.r.db.camera.effectsInCombat=false; f.r.product.RefreshPresentation(true); eq(p.frame:IsShown(),false)
        f.env.InCombatLockdown=function() return false end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_ENABLED")
        eq(p.frame:IsShown(),true); eq(#f.calls,count)
    end)
    test("PX27 particle and wardrobe capability absence cannot blank a saved scene",function()
        local f=fixture(); f.start(); assert(f.p.TryItem(1,1001)); f.flush(); assert(f.p.SetActor("spellKit",16556)); assert(f.p.Save("Effects"))
        local g=fixture(true,f.r.db); assert(g.p.backend.Build()); for _,m in ipairs(g.models) do m.TryOn=nil end
        g.start(); eq(g.front().shown,true); eq(g.p.slots[1].spec.spellKit,16556); eq(g.p.slots[1].spec.outfit[1],1001)
        eq(g.p.TryItem(5,1002),nil); assert(g.p.SetActor("yaw",50)); eq(#g.calls,0)
    end)
    test("PX28 native item failure or secrecy does not leak names or change the model",function()
        local f=fixture(); f.start(); f.env.C_Item.GetItemInfo=function() error("private item data") end
        f.p.wardrobe.Refresh(); eq(f.p.TryItem(1,1001),nil); eq(f.front().shown,true)
        local report=f.ns.Report.Export(f.r); assert(not report:find("private item data",1,true)); assert(not report:find("Native set",1,true))
    end)

    test("PX29 outfit overrides respect hide controls and showing the slot restores its item",function()
        local f=fixture(); f.start(); assert(f.p.TryItem(1,1001)); f.flush(); eq(f.front().items[1],1001)
        assert(f.p.SetActor("hideHead",true)); f.flush(); eq(f.front().items[1],nil); eq(f.p.slots[1].spec.outfit[1],1001)
        assert(f.p.SetActor("hideHead",false)); f.flush(); eq(f.front().items[1],1001); eq(#f.calls,0)
    end)
    test("PX30 a combat keyboard restriction leaves visible mouse exit and filters usable",function()
        local f=fixture(); f.start(); f.r.photoEditor.Recipe("ember"); f.env.InCombatLockdown=function() return true end
        f.c.input.SetPropagateKeyboardInput=function() error("restricted") end
        f.c.input.scripts.OnKeyDown(f.c.input,"H"); eq(f.c.keyboard.enabled,false); eq(f.c.controlsHidden,false)
        eq(f.c.root:IsShown(),true); eq(f.r.photoEffects.root:IsShown(),true); assert(f.r.camera.Exit()); f.flush(); eq(f.env.UIParent:IsShown(),true)
    end)
    test("PX31 poses and transforms open directly from the pinned actor pages",function()
        local f=fixture(); f.start(); f.ui.tab="Pose"; f.ui.Build(true); f.mock.Click("Poses")
        eq(f.ui.scroll:GetVerticalScroll(),0); f.mock.Click("Wave"); eq(f.front().anim,67); f.mock.Click("Transform")
        eq(f.ui.scroll:GetVerticalScroll(),0)
    end)

    test("PX32 cached non-wearable bag items are skipped and unavailable item APIs are labelled",function()
        local f=fixture(); f.items[2000]={name="Food",loc=""}; f.env.C_Container.GetContainerItemID=function() return 2000 end
        f.p.wardrobe.Refresh(); eq(#f.itemRequests,0); eq(#f.p.wardrobe.items,5) -- equipped items plus native-set items
        for _,item in ipairs(f.p.wardrobe.items) do assert(item.id~=2000) end
        f.env.C_Item=nil; f.p.wardrobe.Refresh(); assert(f.p.wardrobe.status:find("unavailable",1,true)); eq(#f.itemRequests,0)
    end)

    return fixture
end
