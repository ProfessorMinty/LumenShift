-- Simulated native collection/model APIs; these are not live rendering results.
return function(make,eq,test)
    local function fixture(fallback,saved)
        local f=make(fallback,saved); f.reads,f.filterWrites=0,0
        f.sources={
            [501]={sourceID=501,visualID=101,itemID=1001,categoryID=1,name="Silver Hat",isCollected=true,sourceType=1,canDisplayOnPlayer=true,isValidSourceForPlayer=true},
            [502]={sourceID=502,visualID=101,itemID=1001,categoryID=1,name="Quest Silver Hat",isCollected=false,sourceType=2,canDisplayOnPlayer=true,isValidSourceForPlayer=true},
            [503]={sourceID=503,visualID=102,itemID=1001,categoryID=1,name="Golden Hat",isCollected=false,sourceType=3,canDisplayOnPlayer=true,isValidSourceForPlayer=true},
            [504]={sourceID=504,visualID=103,itemID=1002,categoryID=4,name="Amber Robe",isCollected=true,sourceType=1,canDisplayOnPlayer=true,isValidSourceForPlayer=true},
            [505]={sourceID=505,visualID=104,itemID=1003,categoryID=14,name="Glass Sword",isCollected=true,sourceType=3,canDisplayOnPlayer=true,isValidSourceForPlayer=true},
        }
        f.appearances={
            [1]={{visualID=101,isCollected=true,isFavorite=true,isHideVisual=false},{visualID=102,isCollected=false,isHideVisual=false}},
            [4]={{visualID=103,isCollected=true,isHideVisual=false}}, [14]={{visualID=104,isCollected=true,isHideVisual=false}}
        }
        local class=1
        f.env.C_TransmogCollection={
            GetCategoryInfo=function(id)
                f.reads=f.reads+1
                local name=({[1]="Head",[4]="Chest",[14]="One-Hand Swords"})[id]
                if name then return name,id==14,false,id==14,id==14,false end
                return nil,false,false,false,false,false
            end,
            GetCategoryAppearances=function(id) f.reads=f.reads+1; return f.appearances[id] end,
            GetAppearanceSources=function(visual,category)
                f.reads=f.reads+1; local result={}
                for _,s in pairs(f.sources) do if s.visualID==visual and s.categoryID==category then result[#result+1]=s end end
                return result
            end,
            GetSourceInfo=function(id) f.reads=f.reads+1; return f.sources[id] end,
            GetSourceIcon=function() return 123 end,
            GetClassFilter=function() return class end,
            SetClassFilter=function(id) f.filterWrites=f.filterWrites+1; class=id end,
            SetDefaultFilters=function(...) eq(select('#',...),0); f.filterWrites=f.filterWrites+1 end,
            SetCollectedShown=function(v) eq(v,true); f.filterWrites=f.filterWrites+1 end,
            SetUncollectedShown=function(v) eq(v,true); f.filterWrites=f.filterWrites+1 end,
            ClearSearch=function(id) eq(id,1); f.filterWrites=f.filterWrites+1; return true end,
        }
        f.env.C_SpecializationInfo={GetAllClassIDs=function() return {1,2} end}
        f.env.C_CreatureInfo={GetClassInfo=function(id) return {className=id==1 and "Warrior" or "Paladin"} end}
        f.env.C_TransmogSets={GetAllSets=function() return {
            {setID=10,name="Silver Guard",label="Normal",collected=true,favorite=true,hiddenUntilCollected=false},
            {setID=11,name="Silver Guard",label="Heroic",collected=false,favorite=false,hiddenUntilCollected=false},
            {setID=12,name="Secret",collected=false,hiddenUntilCollected=true}}
            end, GetSetPrimaryAppearances=function() return {{appearanceID=501,collected=true},{appearanceID=504,collected=true}} end}
        local function forbidden() error("Real equipment/transmog mutation is forbidden") end
        f.env.EquipItemByName=forbidden; f.env.C_Transmog={ApplyAllPending=forbidden}; f.env.Narci=nil; f.env.Narcissus=nil
        f.collection=f.p.collection
        function f.browse()
            f.start(); f.ui.tab="Pose"; f.ui.actorTab="Outfits"; f.ui.wardrobeTab="Collection"; f.ui.Build(); f.flush()
        end
        function f.load(category) assert(f.collection.Discover()); assert(f.collection.Load(category or 1)); f.flush() end
        return f
    end
    test("TC01 native collection is lazy and browsing never changes wardrobe filters or equipment",function()
        local f=fixture(); eq(f.reads,0); f.start(); eq(f.reads,0); f.load(); eq(#f.collection.rows,2)
        eq(f.filterWrites,0); eq(#f.calls,0); eq(f.env.Narci,nil)
    end)
    test("TC02 all source variants and ownership survive deduplicated category loading",function()
        local f=fixture(); f.appearances[1][3]=f.appearances[1][1]
        f.appearances[1][4]={visualID=999,isCollected=true,isHideVisual=true}; f.load()
        eq(#f.collection.rows,2); local row=f.collection.Filter(f.collection.rows,"101","All")[1]
        eq(#row.sources,2); eq(row.sources[1].sourceID,501); eq(row.sources[2].collected,false)
        assert(not f.collection.status:find("unavailable",1,true))
    end)
    test("TC03 local search status favorite and source filters do not change native filters",function()
        local f=fixture(); f.load(); local c=f.collection
        eq(#c.Filter(c.rows,"Quest","All"),1); eq(#c.Filter(c.rows,"502","All"),1)
        eq(#c.Filter(c.rows,"1001","All"),2); eq(#c.Filter(c.rows,"","Uncollected"),1)
        eq(#c.Filter(c.rows,"","Collected",true,2),1); eq(#c.Filter(c.rows,"","All",false,10),0)
        eq(f.filterWrites,0); eq(#f.calls,0)
    end)
    test("TC04 exact native source IDs reach the model without base item substitution",function()
        local f=fixture(); f.start(); assert(f.p.TrySource(1,502)); f.flush()
        eq(f.front().sources[1],502); eq(f.front().items[1],1001); eq(f.equipped[1],1001)
        eq(f.r.db.camera.portrait.scene.actors[1].outfit[1].sourceID,502); eq(#f.calls,0)
    end)
    test("TC05 weapon sources can target either native hand while incompatible slots are rejected",function()
        local f=fixture(); f.start(); assert(f.p.TrySource(17,505)); f.flush(); eq(f.front().sources[17],505)
        eq(f.front().hand,"SECONDARYHANDSLOT"); local old=f.front(); eq(f.p.TrySource(5,505),nil); eq(f.front(),old)
    end)
    test("TC06 rejected or missing source previews keep the previous displayed actor",function()
        local f=fixture(); f.start(); assert(f.p.TrySource(1,501)); f.flush(); local old=f.front()
        eq(f.p.TrySource(1,999),nil); eq(f.front(),old); f.tryOnError=3; assert(f.p.TrySource(1,502)); f.flush()
        eq(f.front(),old); eq(f.r.db.camera.portrait.scene.actors[1].outfit[1].sourceID,501)
    end)
    test("TC07 native collection sets and variants preview exact sources atomically",function()
        local f=fixture(); f.start(); f.collection.Discover(); assert(f.collection.LoadSets()); eq(#f.collection.sets,2)
        assert(f.collection.sets[1].name:find("Heroic",1,true)); assert(f.p.TryCollectionSet(10)); f.flush()
        eq(f.front().sources[1],501); eq(f.front().sources[5],504); eq(f.equipped[5],1002); eq(#f.calls,0)
    end)
    test("TC08 incomplete or ambiguous native sets never partly replace an outfit",function()
        local f=fixture(); f.start(); f.collection.Discover(); local old=f.front()
        f.env.C_TransmogSets.GetSetPrimaryAppearances=function() return {{appearanceID=501},{appearanceID=999}} end
        eq(f.p.TryCollectionSet(10),nil); eq(f.front(),old)
        f.env.C_TransmogSets.GetSetPrimaryAppearances=function() return {{appearanceID=501},{appearanceID=502}} end
        eq(f.p.TryCollectionSet(10),nil); eq(f.front(),old)
    end)
    test("TC09 saved outfits and scenes preserve source variants across reload",function()
        local f=fixture(); f.start(); assert(f.p.TrySource(1,502)); f.flush(); assert(f.p.SaveOutfit("Exact")); assert(f.p.Save("Scene"))
        local copy=assert(f.ns.Store.Open(f.r.db)); eq(copy.camera.portrait.outfits.Exact[1].sourceID,502)
        local g=fixture(false,copy); g.start(); eq(g.front().sources[1],502)
        assert(g.p.SetOutfit({})); g.flush(); assert(g.p.SetOutfit(copy.camera.portrait.outfits.Exact)); g.flush()
        eq(g.front().sources[1],502); eq(#g.calls,0)
    end)
    test("TC10 schema 17 migrations preserve numeric outfits preferences originals and input",function()
        local f=fixture(); local old=f.ns.Value.Copy(f.r.db); old.schemaVersion=17
        local p=old.camera.portrait; p.version=2; p.scene.version=2; p.scene.actors[1].outfit={[5]=1002,[1]=0}
        p.saved.Old=f.ns.Value.Copy(p.scene); p.outfits.Old={[5]=1002}; old.camera.effectsInCombat=false
        local updated,code=f.ns.Store.Open(old); assert(updated); eq(code,"MIGRATED_17_TO_20")
        eq(updated.camera.portrait.version,4); eq(updated.camera.portrait.saved.Old.actors[1].outfit[1],0)
        eq(updated.camera.portrait.outfits.Old[5],1002); eq(updated.camera.effectsInCombat,false); eq(old.camera.portrait.version,2)
    end)
    test("TC11 malformed source descriptors are rejected without executing or resetting data",function()
        local f=fixture(); f.start()
        for _,bad in ipairs({{sourceID=0},{sourceID=-1},{sourceID=.5},{sourceID=math.huge},{sourceID="501"},{sourceID=501,itemID=1001},{itemID=1001}}) do
            eq(f.p.SetOutfit({[1]=bad}),nil)
            local raw=f.ns.Value.Copy(f.r.db); raw.camera.portrait.outfits.Bad={[1]=bad}; eq(f.ns.Store.Open(raw),nil)
        end
        eq(#f.calls,0)
    end)
    test("TC12 collection failures stay local and preserve item pose filter and model controls",function()
        local f=fixture(); f.env.C_TransmogCollection=nil; f.browse(); eq(#f.collection.categories,0)
        assert(f.collection.status:find("unavailable",1,true)); assert(f.p.TryItem(5,1002)); f.flush()
        assert(f.p.SetActor("animation",69)); assert(f.r.photoEditor.Set("vignette",.5)); eq(f.front().items[5],1002)
        eq(#f.calls,0)
    end)
    test("TC13 nested inaccessible and malformed native values are skipped locally",function()
        local f=fixture(); f.env.canaccessvalue=function(v) return v~="SECRET" end
        f.sources[501].name="SECRET"; f.sources[502].sourceID="SECRET"; f.sources[503].isCollected="SECRET"
        f.appearances[1][3]={visualID="SECRET",isCollected=true,isHideVisual=false}
        f.load(); eq(#f.collection.rows,2); eq(#f.collection.rows[2].sources,1); eq(f.collection.rows[2].sources[1].name,"Silver Hat")
        eq(f.filterWrites,0)
    end)
    test("TC14 async category changes discard old work and complete the latest category only",function()
        local f=fixture(); f.collection.Discover(); assert(f.collection.Load(1)); assert(f.collection.Load(4)); f.flush()
        eq(#f.collection.rows,1); eq(f.collection.rows[1].visualID,103); eq(f.collection.busy,false)
    end)
    test("TC15 large categories load in finite batches and expose the full result",function()
        local f=fixture(); local rows={}
        for i=1,600 do rows[i]={visualID=i+1000,isCollected=false,isHideVisual=false} end
        f.appearances[1]=rows; f.collection.Discover(); assert(f.collection.Load(1)); eq(#f.collection.rows,0)
        f.tick(); eq(#f.collection.rows,24); eq(f.collection.busy,true); f.flush(); eq(#f.collection.rows,600); eq(f.collection.loaded,true)
    end)
    test("TC16 unavailable timers and readers report recoverable browser failures",function()
        local f=fixture(); f.collection.Discover(); f.env.C_Timer=nil
        eq(f.collection.Load(1),nil); eq(f.collection.busy,false); assert(f.collection.status:find("unavailable",1,true))
        f.env.C_TransmogCollection.GetCategoryAppearances=function() error("native error") end
        eq(f.collection.Load(1),nil); eq(f.collection.loaded,false)
    end)
    test("TC17 closing camera or leaving the browser cancels stale scans",function()
        local f=fixture(); f.browse(); assert(f.collection.Load(1)); f.ui.wardrobeTab="Items"; f.ui.Build(); f.flush()
        eq(f.collection.busy,false); eq(f.collection.loaded,false); eq(#f.collection.rows,0)
        f.ui.wardrobeTab="Collection"; f.ui.Build(); assert(f.collection.Load(1)); f.p.Exit(); f.flush(); eq(#f.collection.rows,0)
    end)
    test("TC18 class and reset actions only change native wardrobe display filters explicitly",function()
        local f=fixture(); f.load(); eq(f.filterWrites,0); assert(f.collection.SelectClass(2)); f.flush(); eq(f.collection.classID,2)
        eq(f.filterWrites,1); assert(f.collection.ResetFilters()); eq(f.filterWrites,5); eq(#f.calls,0)
        eq(f.collection.SelectClass(99),nil); eq(f.filterWrites,5)
    end)
    test("TC19 partial native filter failures and delayed searches are accurately reported",function()
        local f=fixture(); f.load(); f.env.C_TransmogCollection.SetUncollectedShown=function() error("native filter error") end
        eq(f.collection.ResetFilters(),nil); assert(f.collection.status:find("rejected",1,true)); eq(f.filterWrites,2)
        f.env.C_TransmogCollection.SetUncollectedShown=function() end
        f.env.C_TransmogCollection.ClearSearch=function() return false end
        assert(f.collection.ResetFilters()); assert(f.collection.status:find("updating",1,true)); eq(#f.calls,0)
    end)
    test("TC20 collection UI connects category sources local search sets and saved preview",function()
        local f=fixture(); f.browse(); f.mock.Click("Silver Hat"); f.flush(); eq(f.front().sources[1],501)
        f.mock.Click("Head"); f.mock.Click("Collection sets"); f.mock.Click("Silver Guard - Normal"); f.flush(); eq(f.front().sources[5],504)
        f.mock.Click("Saved outfits"); f.mock.Click("Save current outfit"); f.mock.Click("Save / replace outfit"); eq(f.r.db.camera.portrait.outfits["My outfit"][1].sourceID,501)
        eq(f.filterWrites,0); eq(#f.calls,0)
    end)
    test("TC21 standalone fallback renderer supports exact collection-source previews",function()
        local f=fixture(true); f.start(); assert(f.p.TrySource(1,502)); f.flush(); eq(f.front().sources[1],502)
        eq(f.env.Narci,nil); eq(#f.calls,0)
    end)
    test("TC22 default combat preserves filters and permits native model collection previews",function()
        local f=fixture(); f.browse(); assert(f.r.photoEditor.Recipe("ember"))
        f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED")
        assert(f.p.TrySource(1,503)); f.flush(); eq(f.front().sources[1],503); eq(f.r.photoEffects.root:IsShown(),true)
        eq(f.r.db.camera.editor.look.warmth,.55); eq(#f.calls,0)
    end)
    test("TC23 maximum saved banks with source descriptors round trip within the data budget",function()
        local f=fixture(); local db=f.r.db; local p=db.camera.portrait
        local outfit={}; for _,entry in ipairs(f.ns.PortraitLibrary.Slots) do outfit[entry[1]]={sourceID=501} end
        for i=1,3 do p.scene.actors[i]=f.ns.PortraitConfig.Actor(); p.scene.actors[i].outfit=f.ns.Value.Copy(outfit) end
        for i=1,8 do p.saved["Scene"..i]=f.ns.Value.Copy(p.scene); p.outfits["Outfit"..i]=f.ns.Value.Copy(outfit); p.lights["Light"..i]=f.ns.PortraitConfig.Light() end
        for i=1,12 do assert(f.r.photoEditor.Save("Look"..i)) end
        for i=1,24 do db.config.studio=assert(f.ns.StudioConfig.SavePreset(db.config.studio,"Preset"..i,"nightVision")) end
        local copy=assert(f.ns.Store.Open(db)); eq(copy.camera.portrait.saved.Scene8.actors[3].outfit[1].sourceID,501)
    end)
    test("TC24 collection controls select exact sources and native off-hand previews",function()
        local f=fixture(); f.browse(); f.ns.OutfitPicker.State(f.ui,"appearances").query="Silver"; f.ui.Build(); f.mock.Click("Sources")
        f.mock.Click("Quest Silver Hat"); f.flush(); eq(f.front().sources[1],502)
        f.mock.Click("Back"); f.ns.OutfitPicker.State(f.ui,"appearances").query=""; f.ui.Build()
        f.mock.Click("Head"); f.mock.Click("One-Hand Swords"); f.flush(); f.mock.Click("Main hand"); f.mock.Click("Off hand")
        f.mock.Click("Glass Sword"); f.flush(); eq(f.front().sources[17],505); eq(f.filterWrites,0)
    end)
    test("TC25 missing set APIs do not break appearance browsing or imply an empty collection",function()
        local f=fixture(); f.start(); f.collection.Discover(); f.env.C_TransmogSets=nil
        eq(f.collection.LoadSets(),nil); assert(f.collection.status:find("unavailable",1,true))
        assert(f.collection.Load(1)); f.flush(); eq(#f.collection.rows,2); assert(f.p.TrySource(1,501)); f.flush()
        eq(f.front().sources[1],501); eq(#f.calls,0)
    end)
    test("TC26 async completion keeps a focused search draft until the user submits it",function()
        local f=fixture(); f.browse(); f.mock.Click("Filters"); f.mock.Click("All"); f.mock.Click("Back")
        assert(f.collection.Load(1)); f.ui.Build()
        local field
        for _,node in ipairs(f.mock.nodes) do if node.kind=="EditBox" and node:IsVisible() then field=node; break end end
        assert(field); field:SetFocus(); field:SetText("Golden"); f.flush()
        eq(f.mock.focus,field); eq(field:GetText(),"Golden")
        eq(f.ns.OutfitPicker.State(f.ui,"appearances").query,"Golden"); f.mock.Click("Golden Hat"); f.flush(); eq(f.front().sources[1],503)
    end)
    test("TC27 diagnostic export includes collection counts without names or source enumeration",function()
        local f=fixture(); f.load(); local reads=f.reads; local report=f.ns.Report.Export(f.r)
        assert(report:find("Transmog browser: categories=3 appearances=2",1,true))
        assert(not report:find("Silver Hat",1,true)); assert(not report:find("Quest Silver",1,true)); eq(f.reads,reads)
    end)
    test("TC28 switching back from sets refreshes appearances and their status",function()
        local f=fixture(); f.browse(); f.mock.Click("Head"); f.mock.Click("Collection sets"); assert(f.collection.status:find("native sets",1,true))
        f.mock.Click("Collection sets"); f.mock.Click("Head"); f.flush(); assert(f.collection.status:find("appearances returned",1,true))
        eq(#f.collection.rows,2); f.mock.Click("Silver Hat"); f.flush(); eq(f.front().sources[1],501)
    end)
    test("TC29 pooled collection labels do not leave other controls with wrapping disabled",function()
        local f=fixture(); local W=f.ns.Widgets; local parent=f.env.CreateFrame("Frame",nil,f.env.UIParent)
        local pool=W.CreatePool(f.env,parent)
        local a=W.Button(pool.env,parent,"Long collection item",0,0,200,function() end)
        a.label:SetWordWrap(false); pool.Reset()
        local b=W.Button(pool.env,parent,"A different control",0,0,200,function() end)
        eq(a,b); eq(b.label.SetWordWrapArgs[1],true); eq(b.label.SetNonSpaceWrapArgs[1],false)
    end)
    return fixture
end
