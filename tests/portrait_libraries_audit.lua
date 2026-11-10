-- Audit scenarios use isolated native mocks; no Narcissus or rendered-game pass.
return function(make, eq, test)
    local function modeAndCamera()
        local f=make(); assert(f.r.camera.Exit()); f.flush(); assert(f.r.product.Enable(true))
        assert(f.r.product.Select("nightVision")); f.flush(); assert(f.r.camera.Toggle()); f.flush(); f.start()
        eq(f.r.presentation.frame:IsShown(),true)
        return f
    end
    test("PXA01 all curated poses and kits use the selected owned actor only",function()
        local f=make(); f.start(); assert(f.p.Add("target")); f.flush()
        local other=f.front(1); local seen={}
        for _,pose in ipairs(f.ns.PortraitLibrary.Poses) do
            assert(not seen[pose[1]]); seen[pose[1]]=true
            assert(f.p.SetActor("animation",pose[1])); eq(f.front().anim,pose[1]); eq(other.anim,0)
        end
        for _,kit in ipairs(f.ns.PortraitLibrary.Kits) do
            assert(f.p.SetActor("spellKit",kit[1])); eq(f.front().kit,kit[1]); eq(other.kit,0)
        end
        eq(f.env.Narci,nil); eq(#f.calls,0)
    end)
    test("PXA02 unsupported poses and errors after a kit mutation retain the previous selection",function()
        local f=make(); f.start(); assert(f.p.SetActor("animation",69)); assert(f.p.SetActor("spellKit",10650))
        local m=f.front(); m.HasAnimation=function(_,id) return id~=125 end
        eq(f.p.SetActor("animation",125),nil); eq(m.anim,69); eq(f.p.slots[1].spec.animation,69)
        m.SetSpellVisualKit=function(s,id) s.kit=id; if id==16556 then error("after mutation") end end
        eq(f.p.SetActor("spellKit",16556),nil); eq(m.kit,10650); eq(f.p.slots[1].spec.spellKit,10650)
        assert(f.p.SetActor("spellKit",0)); eq(m.kit,0); eq(#f.calls,0)
    end)
    test("PXA03 saved outfit copies preserve explicit empty slots and survive reload",function()
        local f=make(); f.start(); assert(f.p.TryItem(1,0)); f.flush(); assert(f.p.SaveOutfit("Bare head"))
        local bank=f.r.db.camera.portrait.outfits; eq(bank["Bare head"][1],0)
        assert(f.p.TryItem(1,1001)); f.flush(); eq(bank["Bare head"][1],0)
        assert(f.p.SetOutfit(bank["Bare head"])); f.flush(); eq(f.front().items[1],nil)
        local g=make(false,f.r.db); g.start(); eq(g.front().items[1],nil); eq(g.p.slots[1].spec.outfit[1],0)
        eq(g.r.db.camera.portrait.outfits["Bare head"][1],0); eq(#g.calls,0)
    end)
    test("PXA04 missing inventory sources are labelled rather than looking like empty bags",function()
        local f=make(); f.env.C_Container=nil; f.env.C_EquipmentSet=nil; f.env.GetInventoryItemID=nil
        assert(f.p.wardrobe.Refresh()); eq(#f.p.wardrobe.items,0)
        assert(f.p.wardrobe.status:find("unavailable",1,true),"missing native readers need a local status")
        f.start(); assert(f.p.SetActor("yaw",30)); eq(#f.calls,0)
    end)
    test("PXA05 turning combat filters off clears an inherited visual-mode treatment immediately",function()
        local f=modeAndCamera(); f.env.InCombatLockdown=function() return true end
        f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED"); eq(f.r.presentation.frame:IsShown(),true)
        f.r.db.camera.effectsInCombat=false; f.r.product.RefreshPresentation(true); f.r.photoEditor.Render()
        eq(f.r.presentation.frame:IsShown(),false)
        f.r.db.camera.effectsInCombat=true; f.r.product.RefreshPresentation(true); f.r.photoEditor.Render()
        eq(f.r.presentation.frame:IsShown(),true); eq(f.p.active,true)
    end)
    test("PXA06 compositing pair omits inherited mode effects through combat and resize",function()
        local f=modeAndCamera(); local count=#f.calls
        assert(f.p.CaptureLayers()); eq(f.r.presentation.frame:IsShown(),false)
        f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED")
        eq(f.r.presentation.frame:IsShown(),false); f.r.photoEditor.Render(); eq(f.r.presentation.frame:IsShown(),false)
        f.tick(); eq(f.captures,1); f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_SUCCEEDED")
        f.env.InCombatLockdown=function() return false end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_ENABLED")
        eq(f.r.presentation.frame:IsShown(),false); f.tick(); f.tick(); eq(f.captures,2)
        f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_SUCCEEDED"); eq(f.r.presentation.frame:IsShown(),true)
        eq(f.p.layerCapture,nil); eq(#f.calls,count)
    end)
    test("PXA07 all four combat choices preserve data and never queue native writes",function()
        for _,stay in ipairs({false,true}) do for _,effects in ipairs({false,true}) do
            local f=make(); f.start(); assert(f.r.photoEditor.Recipe("ember"))
            f.r.db.camera.keepInCombat=stay; f.r.db.camera.effectsInCombat=effects
            local look=f.ns.PhotoConfig.Export(f.r.db.camera.editor.look)
            f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED")
            eq(f.p.active,stay); eq(f.r.photoEffects.root:IsShown(),effects); eq(f.env.UIParent:IsShown(),not stay)
            f.env.InCombatLockdown=function() return false end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_ENABLED"); f.flush()
            eq(f.p.active,stay); eq(f.r.photoEffects.root:IsShown(),true); eq(f.ns.PhotoConfig.Export(f.r.db.camera.editor.look),look)
            eq(f.env.UIParent:IsShown(),not stay); eq(#f.calls,0)
        end end
    end)
    test("PXA08 combat during a clean capture preserves hidden controls until its completion",function()
        local f=make(); f.start(); assert(f.r.photoEditor.Recipe("ember")); assert(f.c.ToggleControls())
        assert(f.c.Capture()); f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED")
        f.tick(); eq(f.captures,1); eq(f.c.root:IsShown(),false); eq(f.r.photoEffects.root:IsShown(),true)
        f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_SUCCEEDED"); eq(f.c.root:IsShown(),false)
        f.c.input.scripts.OnKeyDown(f.c.input,"H"); eq(f.c.root:IsShown(),true)
        f.c.input.scripts.OnKeyDown(f.c.input,"ESCAPE"); f.flush(); eq(f.p.active,false); eq(f.env.UIParent:IsShown(),true)
    end)
    test("PXA09 inventory reader failures keep accessible items and report local source loss",function()
        local f=make(); f.env.C_Container.GetContainerNumSlots=function() return .5 end
        f.env.C_EquipmentSet.GetItemIDs=function() error("native set read failed") end
        assert(f.p.wardrobe.Refresh()); eq(#f.p.wardrobe.items,3); eq(#f.p.wardrobe.sets,0)
        assert(f.p.wardrobe.status:find("inventory sources are unavailable",1,true)); eq(#f.itemRequests,0)
        f.start(); assert(f.p.TryItem(5,1002)); f.flush(); eq(f.front().items[5],1002)
    end)
    test("PXA10 accessible empty inventories are not labelled unavailable",function()
        local f=make(); f.env.GetInventoryItemID=function() return nil end
        f.env.C_Container.GetContainerNumSlots=function() return 3 end
        f.env.C_Container.GetContainerItemID=function() end -- documented MayReturnNothing for empty slots
        f.env.C_EquipmentSet.GetEquipmentSetIDs=function() return {} end
        assert(f.p.wardrobe.Refresh()); eq(#f.p.wardrobe.items,0); eq(#f.p.wardrobe.sets,0)
        assert(not f.p.wardrobe.status:find("unavailable",1,true))
    end)
    test("PXA11 full actor pose kit outfit and light selection survive a standalone scene reload",function()
        local f=make(); f.start(); assert(f.p.TryItem(17,1004)); f.flush()
        assert(f.p.SetActor("animation",124)); assert(f.p.SetActor("variation",2)); assert(f.p.SetActor("time",.8))
        assert(f.p.SetActor("spellKit",57874)); assert(f.p.SetLight(f.ns.PortraitConfig.LightPreset("ember")))
        assert(f.p.Save("Complete")); assert(f.p.SetActor("spellKit",0)); assert(f.p.SetOutfit({})); f.flush()
        local g=make(false,f.r.db); g.start(); assert(g.p.Load("Complete")); g.flush()
        local m=g.front(); eq(m.anim,124); eq(m.variation,2); eq(m.offset,.8); eq(m.kit,57874); eq(m.items[17],1004)
        eq(g.r.db.camera.portrait.scene.light.green,.55); eq(g.env.Narci,nil); eq(#g.calls,0)
    end)
    test("PXA12 a cancelled or failed compositing pair returns the inherited treatment once",function()
        for _,cancel in ipairs({false,true}) do
            local f=modeAndCamera(); assert(f.p.CaptureLayers()); eq(f.r.presentation.frame:IsShown(),false)
            if cancel then f.p.CancelLayers()
            else f.tick(); f.c.root.scripts.OnEvent(f.c.root,"SCREENSHOT_FAILED") end
            eq(f.p.layerCapture,nil); eq(f.r.presentation.frame:IsShown(),true)
            local count=f.captures; f.flush(); eq(f.captures,count); eq(f.front().shown,true)
        end
    end)
end
