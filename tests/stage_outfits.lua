return function(make,eq,test)
    local function click(f,s) f.mock.Click(s); assert(not f.ui.building,s) end
    local function visible(f,kind,label)
        for _,n in ipairs(f.mock.nodes) do
            if n.kind==kind and n:IsVisible() and (not label or n.label and n.label:GetText()==label) then return n end
        end
    end
    local function search(f,q)
        local field=assert(visible(f,"EditBox")); field:SetFocus(); field:SetText(q); return field
    end
    local function fits(f)
        eq(f.ui.scrollbar.maximum,0); eq(f.ui.scrollbar:IsShown(),false); eq(f.ui.scroll:GetVerticalScroll(),0)
    end
    local function open(f)
        click(f,"Portrait Stage"); f.flush(); click(f,"Actors"); click(f,"Outfits"); f.flush()
        eq(f.ui.wardrobeTab,"Collection")
    end
    local function add(f,n)
        for i=1,n do
            local visual,source=2000+i,4000+i
            f.appearances[1][#f.appearances[1]+1]={visualID=visual,isCollected=true,isHideVisual=false}
            f.sources[source]={visualID=visual,sourceID=source,itemID=1001,categoryID=1,
                name=string.format("Silk cap %02d",i),isCollected=true,sourceType=2}
        end
    end
    test("OW01 Outfits opens the collection and pages every appearance three at a time at both panel sizes",function()
        for _,size in ipairs({{1280,800},{600,400}}) do
            local f=make(); add(f,10); f.env.UIParent:SetSize(unpack(size)); f.c.Show(); open(f)
            local front=f.front(); search(f,"Silk cap")
            for i=1,10 do
                if i>1 and (i-1)%3==0 then click(f,"Next") end
                local name=string.format("Silk cap %02d",i)
                assert(visible(f,"Button",name)); fits(f)
            end
            eq(f.front(),front); eq(f.filterWrites,0); eq(#f.calls,0)
            click(f,"Silk cap 10"); f.flush(); eq(f.front().sources[1],4010); eq(f.equipped[1],1001)
            eq(visible(f,"Button","Next"):IsEnabled(),false)
        end
    end)
    test("OW02 source queries preview precisely the matching variant on both renderers",function()
        for _,fallback in ipairs({false,true}) do
            local f=make(fallback); open(f); local old=f.front()
            search(f,"502"); eq(f.front(),old); click(f,"Quest Silver Hat"); f.flush()
            eq(f.front().sources[1],502); assert(f.ui.status:GetText():find("Quest Silver Hat",1,true))
            search(f,"1001"); click(f,"Silver Hat"); f.flush(); eq(f.front().sources[1],501)
            search(f,"["); eq(visible(f,"Button","Silver Hat"),nil); eq(f.env.Narci,nil); eq(#f.calls,0)
        end
    end)
    test("OW03 all-slot search finds a different category, supports exact off-hand variants, and preserves other actors",function()
        local f=make(); open(f)
        assert(f.p.Add("target")); f.flush(); eq(f.p.selected,2)
        local original=f.front(1); search(f,"Glass"); click(f,"All slots"); f.flush(); fits(f)
        click(f,"Sources"); fits(f); click(f,"Main hand"); click(f,"Off hand"); fits(f)
        click(f,"Glass Sword"); f.flush(); eq(f.front(2).sources[17],505); eq(f.front(1),original)
        click(f,"Back"); assert(visible(f,"Button","Glass Sword")); eq(f.equipped[17],nil); eq(f.filterWrites,0)
    end)
    test("OW04 changing a global query or leaving Outfits cancels obsolete batches and keeps focus during completion",function()
        local f=make(); add(f,70); open(f); click(f,"All slots"); local reads=f.reads
        local field=search(f,"Silk"); eq(f.reads,reads); click(f,"Search"); eq(f.collection.busy,true)
        f.tick(); field:SetText("Amber"); eq(f.collection.busy,false)
        click(f,"Search"); f.flush(); eq(f.mock.focus,field); eq(field:GetText(),"Amber")
        assert(visible(f,"Button","Amber Robe")); eq(visible(f,"Button","Silk cap 01"),nil)
        field:SetText("Glass"); click(f,"Search"); click(f,"Items"); f.flush(); eq(f.collection.busy,false)
        eq(visible(f,"Button","Glass Sword"),nil); eq(f.filterWrites,0); eq(#f.calls,0)
    end)
    test("OW05 local filters combine source and query on one variant; category, filter and hand choices fit",function()
        local f=make(); f.env.UIParent:SetSize(600,400); open(f)
        click(f,"Filters"); fits(f); click(f,"Source · All"); fits(f); click(f,"Next"); fits(f)
        click(f,"Previous"); click(f,"Quest"); fits(f); search(f,"501"); eq(visible(f,"Button","Silver Hat"),nil)
        search(f,"502"); assert(visible(f,"Button","Quest Silver Hat")); eq(f.filterWrites,0)
        click(f,"Filters"); click(f,"WoW class · Warrior"); fits(f); click(f,"Back"); fits(f)
        click(f,"Back"); click(f,"Head"); fits(f); click(f,"One-Hand Swords"); f.flush(); click(f,"Main hand"); fits(f)
    end)
    test("OW06 global partial and capped results are reported, with later categories reachable after a narrower search",function()
        local f=make(); local many={}
        for i=1,1002 do many[i]={visualID=9000+i,isCollected=true,isHideVisual=false} end
        f.appearances[1]=many
        open(f); click(f,"All slots"); search(f,"Appearance"); click(f,"Search"); f.flush()
        eq(#f.collection.rows,1000); assert(f.collection.status:find("1,000",1,true)); fits(f)
        f.appearances[4]=nil; search(f,"505"); click(f,"Search"); f.flush()
        eq(#f.collection.rows,1); assert(f.collection.status:find("Unavailable categories",1,true))
        click(f,"Glass Sword"); f.flush(); eq(f.front().sources[16],505); eq(#f.calls,0)
    end)
    test("OW07 a failed source preview retains the prior model and gives local feedback; a retry clears the error",function()
        local f=make(); open(f); click(f,"Silver Hat"); f.flush(); local front=f.front()
        click(f,"Filters"); click(f,"All"); click(f,"Back")
        f.tryOnError=3; click(f,"Golden Hat"); f.flush()
        eq(f.front(),front); eq(f.front().sources[1],501); assert(f.p.failures[1]); eq(f.ui.status:GetText(),f.p.failures[1])
        f.tryOnError=nil; click(f,"Golden Hat"); f.flush(); eq(f.front().sources[1],503)
        eq(f.ui.status:GetText(),"Previewing Golden Hat"); eq(#f.calls,0)
    end)
    test("OW08 compact inventory, gear sets, saved outfits and collection sets remain usable",function()
        local f=make(); f.env.UIParent:SetSize(600,400); open(f)
        click(f,"Items"); fits(f); click(f,"Chest"); fits(f); click(f,"Next"); fits(f); click(f,"Off hand")
        click(f,"Item ID / link"); search(f,"1003"); click(f,"Try on"); f.flush(); eq(f.front().items[17],1003)
        click(f,"Back"); click(f,"Tools"); fits(f); click(f,"Back")
        click(f,"Gear sets"); fits(f); click(f,"Preview equipped"); f.flush(); eq(f.front().items[1],1001)
        click(f,"Saved outfits"); click(f,"Save current outfit"); search(f,"Studio set"); click(f,"Save / replace outfit")
        fits(f); click(f,"Studio set"); f.flush(); click(f,"Delete"); eq(f.r.db.camera.portrait.outfits["Studio set"],nil)
        click(f,"Collection"); click(f,"Head"); click(f,"Collection sets"); fits(f)
        click(f,"Filters"); click(f,"All"); click(f,"Back"); click(f,"Silver Guard - Heroic"); f.flush(); eq(f.front().sources[5],504); eq(f.filterWrites,0); eq(#f.calls,0)
    end)
    test("OW09 hiding the controls stops outstanding reads and restores a usable picker on return",function()
        local f=make(); add(f,60); open(f)
        assert(f.collection.Load(1)); f.tick()
        assert(f.c.ToggleControls()); eq(f.collection.busy,false); f.flush()
        assert(f.c.ToggleControls()); f.flush(); eq(f.collection.loaded,true); fits(f)
        click(f,"All slots"); search(f,"Silk"); click(f,"Search"); f.tick()
        assert(f.c.ToggleControls()); f.flush(); assert(f.c.ToggleControls()); f.flush()
        eq(f.collection.busy,false); eq(visible(f,"Button","Silk cap 01"),nil)
        click(f,"Search"); f.flush(); assert(visible(f,"Button","Silk cap 01")); eq(#f.calls,0)
    end)
    test("OW10 a rejected native class filter is reported without retry or losing the currently staged gear",function()
        local f=make(); open(f); click(f,"Silver Hat"); f.flush(); local model=f.front()
        f.env.C_TransmogCollection.SetClassFilter=function() error("unavailable") end
        click(f,"Filters"); click(f,"WoW class · Warrior"); click(f,"Paladin"); f.flush()
        assert(f.ui.status:GetText():find("could not change",1,true)); eq(f.collection.loaded,false)
        local n=f.reads; f.ui.Build(); f.flush(); eq(f.reads,n); eq(f.front(),model); eq(model.sources[1],501)
    end)
end
