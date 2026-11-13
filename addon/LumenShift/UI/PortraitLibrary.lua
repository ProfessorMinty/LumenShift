local _, ns = ...
local U, W, style = {}, ns.Widgets, ns.PhotoStyle
ns.PortraitLibraryUI = U

-- Family symbols identify the library entries. The staged model shows the native particles.
local families = {
    Fire    = {group="Elemental", art="lantern",     color={1,.60,.27}},
    Frost   = {group="Elemental", art="ui-effects",  color={.57,.88,1}},
    Sunlight= {group="Lighting",  art="natural",     color={1,.87,.47}},
    Shadow  = {group="Lighting",  art="moonlight",   color={.79,.63,1}},
    Arcane  = {group="Magic",     art="ui-effects",  color={.59,.72,1}},
    Fel     = {group="Magic",     art="pose-cast",   color={.62,1,.49}},
}
local pageSize = 6

local function filter(state)
    local matches = {}
    local query = state.query:lower():match("^%s*(.-)%s*$")
    for _, kit in ipairs(ns.PortraitLibrary.Kits) do
        local family = families[kit[3]]
        if family and (state.group=="All" or family.group==state.group) then
            if query=="" or tostring(kit[1])==query or kit[2]:lower():find(query,1,true)
                or kit[3]:lower():find(query,1,true) or family.group:lower():find(query,1,true) then
                matches[#matches+1]=kit
            end
        end
    end
    return matches
end

local function effects(runtime,env,parent,ui,y,slot)
    local stage=runtime.portrait
    local state=ui.effectBrowser or {query="",group="All",page=1}
    ui.effectBrowser=state
    local band=env.CreateFrame("Frame",nil,parent)
    band:SetPoint("TOPLEFT",parent,"TOPLEFT",0,y); band:SetSize(310,42)
    W.Fill(band,W.colors.sidebar)
    local caption=W.Text(band,"On actor",9,-4,183,10,W.colors.muted)
    local current=W.Text(band,"",9,-18,187,15)
    local field
    local function apply(id)
        field:ClearFocus()
        if stage.slots[stage.selected]==slot then stage.SetActor("spellKit",id) end
    end
    local clear=W.Button(env,band,"Clear effect",202,-6,100,function() apply(0) end)
    y=y-47
    field=W.Edit(env,parent,state.query,0,y,204,function() end,64)
    ui.effectSearch=field
    local hint=W.Text(field,"Find effect, family or kit ID",7,-6,192,12,W.colors.muted)
    local reset=W.Button(env,parent,"Clear search",210,y,100,function()
        field:SetText(""); field:SetFocus()
    end,nil,"quiet")
    y=y-32
    local groups={}
    for i,label in ipairs({"All","Elemental","Lighting","Magic"}) do
        groups[label]=style.Tab(env,parent,label,(i-1)*77.5,y,77.5,function()
            state.group,state.page=label,1; ui.Refresh()
        end)
    end
    y=y-32
    local empty=W.Text(parent,"No matching effects.",0,y-38,310,14,W.colors.muted)
    empty:SetJustifyH("CENTER")
    local cards={}
    for i=1,pageSize do
        local card={}
        cards[i]=card
        local b=W.Button(env,parent,"",(i-1)%2*157,y-math.floor((i-1)/2)*36,153,function()
            if card.kit then apply(card.kit[1]) end
        end)
        card.button=b; b:SetHeight(33)
        b.label:ClearAllPoints(); b.label:SetPoint("LEFT",b,"LEFT",30,0); b.label:SetWidth(119)
        b.label:SetFont(b.label:GetFont(),12,""); b.label:SetWordWrap(false); b.label:SetNonSpaceWrap(false)
        card.glyph=W.Texture(b,"ARTWORK"); card.glyph:SetSize(20,20); card.glyph:SetPoint("LEFT",b,"LEFT",6,0)
        local enter=b:GetScript("OnEnter")
        W.Script(b,"OnEnter",function(self)
            enter(self)
            if card.kit and env.GameTooltip then
                env.GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
                env.GameTooltip:SetText(card.kit[2].."\n"..card.kit[3].." · Visual kit "..card.kit[1])
                env.GameTooltip:Show()
            end
        end)
    end
    local gridTop=y
    local pager=env.CreateFrame("Frame",nil,parent)
    pager:SetSize(310,30)
    local page=style.Pager(env,pager,0,function(delta) state.page=state.page+delta; ui.Refresh() end)

    ui.RefreshStageEffects=function()
        local model=slot.front and stage.backend.models[slot.front]
        local supported=model and stage.backend.Supports(model,"spellKit")
        local editable=supported and stage.slots[stage.selected]==slot and stage.CanEdit()
        local id=slot.spec.spellKit
        local label="No effect"
        for _,kit in ipairs(ns.PortraitLibrary.Kits) do if kit[1]==id then label=kit[2]; break end end
        caption:SetText(supported and "On actor" or "Saved choice")
        current:SetText(slot.effectUncertain and "Unconfirmed" or label)
        style.Enable(clear,editable and (id~=0 or slot.effectUncertain))
        style.Enable(reset,state.query~="")
        if state.query=="" then hint:Show() else hint:Hide() end
        for key,b in pairs(groups) do b.SetSelected(key==state.group) end
        local matches=filter(state)
        state.page=math.max(1,math.min(state.page,math.ceil(#matches/pageSize)))
        for i,card in ipairs(cards) do
            local kit=matches[(state.page-1)*pageSize+i]
            if kit then
                if card.kit~=kit then
                    local family=families[kit[3]]
                    W.Asset(card.glyph,"Interface/AddOns/LumenShift/Media/"..family.art..".tga")
                    card.glyph:SetVertexColor(unpack(family.color))
                    card.button.label:SetText(kit[2])
                end
                card.button.SetSelected(supported and not slot.effectUncertain and kit[1]==id)
                style.Enable(card.button,editable); card.button:Show()
            else card.button:Hide() end
            card.kit=kit
        end
        local visible=math.min(pageSize, #matches-(state.page-1)*pageSize)
        local bottom=gridTop-36*math.ceil(visible/2)-2
        pager:ClearAllPoints(); pager:SetPoint("TOPLEFT",parent,"TOPLEFT",0,bottom)
        if visible==0 then empty:Show(); pager:Hide(); bottom=gridTop-75
        else empty:Hide(); pager:Show(); page(state.page,pageSize,#matches); bottom=bottom-32 end
        local height=-bottom+16
        if not supported then return "This renderer cannot preview model spell effects.",height end
        if slot.effectError then return slot.effectError,height end
        if not editable then return "Finish the current stage operation to change effects.",height end
        if visible==0 then return "Change the search or family to see more effects.",height end
        return id==0 and "Click an effect to preview it on this actor." or "Click another effect to swap it.",height
    end
    W.Script(field,"OnTextChanged",function()
        if state.query~=field:GetText() then state.query,state.page=field:GetText(),1; ui.Refresh() end
    end)
    return gridTop-3*36-2-32
end

function U.Build(runtime,env,parent,ui,y,selected)
    if ui.actorTab=="Effects" then return effects(runtime,env,parent,ui,y,selected) end
    return ns.StageOutfitsUI.Build(runtime,env,parent,ui,y,selected)
end
