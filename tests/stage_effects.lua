return function(make,eq,test)
    local function click(f,label)
        f.mock.Click(label)
        assert(not f.ui.building,label)
    end
    local function button(f,label)
        for _,b in ipairs(f.mock.nodes) do
            if b.kind=="Button" and b:IsVisible() and b.label and b.label:GetText()==label then return b end
        end
    end
    local function textVisible(f,s)
        for _,node in ipairs(f.mock.nodes) do
            if node.kind=="FontString" and node:IsVisible() and node:GetText()==s then return true end
        end
    end
    local function open(f)
        click(f,"Portrait Stage"); f.flush(); click(f,"Actors"); click(f,"Effects")
        assert(f.ui.effectSearch:IsVisible())
    end
    local function search(f,query)
        local field=f.ui.effectSearch; field:SetFocus(); field:SetText(query)
        eq(field,f.ui.effectSearch); eq(f.mock.focus,field)
    end
    local function fits(f)
        eq(f.ui.scrollbar:IsShown(),false); eq(f.ui.scrollbar.maximum,0); eq(f.ui.scroll:GetVerticalScroll(),0)
    end
    test("FX01 both pages reach every allowed effect in each panel size; browsing and mouseover never apply",function()
        for _,size in ipairs({{1280,800},{600,400}}) do
            local f=make(); f.env.UIParent:SetSize(unpack(size)); f.c.Show(); open(f)
            local model=f.front(); local calls=0
            model.SetSpellVisualKit=function(s,kit,oneShot) calls=calls+1; s.kit=kit; eq(oneShot,false) end
            local seen={}
            for page=1,2 do
                fits(f)
                for _,kit in ipairs(f.ns.PortraitLibrary.Kits) do
                    local card=button(f,kit[2])
                    if card then assert(kit[1]~=0 and not seen[kit[1]]); seen[kit[1]]=true
                        card.scripts.OnEnter(card); card.scripts.OnLeave(card)
                    end
                end
                if page==1 then click(f,"Next") end
            end
            eq(#f.ns.Value.Keys(seen),12); eq(button(f,"Next"):IsEnabled(),false)
            click(f,"Previous"); eq(button(f,"Previous"):IsEnabled(),false)
            for _,group in ipairs({"Elemental","Lighting","Magic","All"}) do click(f,group); fits(f) end
            eq(calls,0); eq(f.env.Narci,nil); eq(#f.calls,0)
        end
    end)
    test("FX02 all twelve one-click swaps reach only the selected stage model and clear without a world cast",function()
        local f=make(); open(f); assert(f.p.Add("target")); f.flush(); local target=f.front(2)
        assert(f.p.SetActor("spellKit",16343)); click(f,"1  player"); local player=f.front(1)
        local forbidden=function() error("unexpected world cast") end
        f.env.CastSpellByName=forbidden; f.env.C_Spell={CastSpell=forbidden}
        for i,kit in ipairs(f.ns.PortraitLibrary.Kits) do
            if i>1 then
                if not button(f,kit[2]) then click(f,"Next") end
                click(f,kit[2]); eq(f.front(1),player); eq(player.kit,kit[1]); eq(target.kit,16343)
                eq(f.r.db.camera.portrait.scene.actors[1].spellKit,kit[1]); eq(button(f,kit[2]).selected,true)
            end
        end
        search(f,"nothing matches"); fits(f); click(f,"Clear effect"); eq(player.kit,0); eq(target.kit,16343)
        eq(button(f,"Clear effect"):IsEnabled(),false); eq(f.r.db.camera.portrait.scene.actors[1].spellKit,0)
        click(f,"2  target"); click(f,"Clear effect"); eq(target.kit,0); eq(#f.calls,0)
    end)
    test("FX03 live literal search, exact IDs, family filters and clearing search preserve the actor's preview",function()
        local f=make(); open(f); click(f,"Fire surge")
        for _,q in ipairs({"  fRoSt  ","10650"," Cold aura "}) do
            search(f,q); assert(button(f,q==" Cold aura " and "Cold aura" or "Frost sparkle"))
        end
        search(f,"106"); assert(textVisible(f,"No matching effects.")); eq(f.front().kit,16556)
        search(f,"["); assert(textVisible(f,"No matching effects.")); click(f,"Clear search"); eq(f.front().kit,16556)
        click(f,"Magic"); search(f,"fel"); click(f,"Fel orbs"); eq(f.front().kit,25890)
        click(f,"Lighting"); assert(textVisible(f,"No matching effects.")); eq(f.front().kit,25890)
        click(f,"Clear search"); assert(button(f,"Sunlight - right")); eq(f.front().kit,25890)
        eq(#f.calls,0)
    end)
    test("FX04 rejected swaps and clears restore the last confirmed effect and its selection",function()
        local f=make(); open(f); click(f,"Frost sparkle"); local model=f.front()
        local set=model.SetSpellVisualKit
        model.SetSpellVisualKit=function(s,id,...)
            set(s,id,...); if id==16556 or id==0 then error("after mutation") end
        end
        click(f,"Fire surge"); eq(model.kit,10650); eq(button(f,"Frost sparkle").selected,true)
        click(f,"Clear effect"); eq(model.kit,10650); eq(f.r.db.camera.portrait.scene.actors[1].spellKit,10650)
        assert(f.ui.status:GetText():find("unavailable",1,true))
        model.SetSpellVisualKit=set; click(f,"Clear effect"); eq(model.kit,0); eq(f.p.slots[1].effectError,nil)
    end)
    test("FX05 unconfirmed rollback keeps Clear available even from an empty saved slot until an explicit recovery",function()
        local f=make(); open(f); local model=f.front()
        local get=model.GetSpellVisualKit; model.GetSpellVisualKit=function() return -1 end
        click(f,"Fire surge"); eq(f.p.slots[1].effectUncertain,true)
        eq(f.r.db.camera.portrait.scene.actors[1].spellKit,0); assert(textVisible(f,"Unconfirmed"))
        eq(button(f,"Fire surge").selected,false); eq(button(f,"Clear effect"):IsEnabled(),true)
        eq(f.r.db.camera.portrait.scene.actors[1].effectUncertain,nil)
        model.GetSpellVisualKit=get; click(f,"Clear effect"); eq(f.p.slots[1].effectUncertain,nil)
        eq(model.kit,0); eq(button(f,"Clear effect"):IsEnabled(),false)
    end)
    test("FX06 unsupported widget preserves saved kits and allows browsing; supported setter-only actors swap normally",function()
        local f=make(); open(f); click(f,"Frost sparkle"); assert(f.p.Save("Icy"))
        local g=make(true,f.r.db); open(g); assert(textVisible(g,"Saved choice")); assert(textVisible(g,"Frost sparkle"))
        assert(g.ui.status:GetText():find("renderer",1,true)); search(g,"Fire")
        eq(button(g,"Fire surge"):IsEnabled(),false); eq(button(g,"Clear effect"):IsEnabled(),false)
        eq(g.r.db.camera.portrait.scene.actors[1].spellKit,10650); click(g,"Poses"); assert(g.p.SetActor("animation",67))
        f.front().GetSpellVisualKit=nil; click(f,"Fire trail"); eq(f.front().kit,20503); click(f,"Clear effect")
        eq(f.front().kit,0); assert(f.p.Load("Icy")); f.flush(); eq(f.front().kit,10650); eq(#f.calls,0)
    end)
    test("FX07 capture locks edits temporarily; normal combat, look, outfit and pose are independent of swaps",function()
        local f=make(); open(f); assert(f.r.photoEditor.Recipe("ember")); assert(f.p.TryItem(1,1001)); f.flush()
        assert(f.p.SetActor("animation",67)); click(f,"Fire trail")
        f.env.InCombatLockdown=function() return true end; f.frame.OnEvent(f.frame,"PLAYER_REGEN_DISABLED")
        click(f,"Cold aura"); eq(f.front().kit,16343)
        f.r.db.camera.tools.delay=3; assert(f.r.captureSequence.Start()); f.ui.Refresh()
        eq(button(f,"Clear effect"):IsEnabled(),false); click(f,"Fire surge"); eq(f.front().kit,16343)
        f.r.captureSequence.Cancel(); f.flush(); click(f,"Clear effect"); eq(f.front().kit,0)
        eq(f.front().items[1],1001); eq(f.front().anim,67); eq(f.r.db.camera.editor.look.warmth,.55)
        eq(#f.calls,0)
    end)
    test("FX08 search focus survives model refresh; changing actors or reopening reads the current effect",function()
        local f=make(); open(f); search(f,"Frost"); assert(f.p.SetActor("spellKit",10650))
        eq(f.mock.focus,f.ui.effectSearch); eq(f.ui.effectSearch:GetText(),"Frost"); eq(button(f,"Frost sparkle").selected,true)
        assert(f.p.SetActor("yaw",14)); eq(f.mock.focus,f.ui.effectSearch); eq(f.ui.effectSearch:GetText(),"Frost")
        click(f,"Clear search"); click(f,"Actors"); click(f,"Outfits"); eq(f.ui.effectSearch,nil)
        click(f,"Effects"); eq(button(f,"Frost sparkle").selected,true); click(f,"World Photo")
        eq(f.p.active,false); eq(f.ui.RefreshStageEffects,nil); for _,m in ipairs(f.models) do eq(m.kit,0) end
        open(f); eq(f.front().kit,10650); click(f,"Clear effect"); eq(f.front().kit,0)
    end)
end
