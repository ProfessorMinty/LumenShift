local _,ns=...
local P,W={},ns.Widgets
ns.OutfitPicker=P

function P.Preview(stage,ui,name,fn)
    local feedback={name=name,actor=stage.selected,generation=stage.generation}
    ui.outfitFeedback=feedback
    local ok,why=fn()
    feedback.error=not ok and (why or "Preview unavailable.") or nil
    ui.Refresh()
end

function P.State(ui,key)
    ui.outfitPages=ui.outfitPages or {}
    local state=ui.outfitPages[key] or {page=1,query=""}
    ui.outfitPages[key]=state
    return state
end

function P.Header(env,parent,y,title,back)
    W.Button(env,parent,"Back",0,y,66,back,nil,"quiet")
    local t=W.Text(parent,title,77,y-6,231,14); t:SetWordWrap(false); t:SetNonSpaceWrap(false)
    return y-35
end

-- Finite pages for slot, class and source-type lists, including client-localized names.
function P.Grid(env,parent,ui,y,entries,state,choose)
    local size=8
    local pages=math.max(1,math.ceil(#entries/size))
    state.page=math.max(1,math.min(pages,state.page))
    for i=1,size do
        local e=entries[(state.page-1)*size+i]
        if e then
            local b=W.Button(env,parent,e[2],(i-1)%2*156,y-math.floor((i-1)/2)*33,153,function() choose(e[1]) end,e[2])
            b.label:SetWordWrap(false); b.label:SetNonSpaceWrap(false); b.SetSelected(e[3]==true)
        end
    end
    if pages>1 then
        local show=ns.PhotoStyle.Pager(env,parent,y-134,function(delta)
            state.page=math.max(1,math.min(pages,state.page+delta)); ui.Build(true)
        end)
        show(state.page,size,#entries)
        return y-165
    end
    return y-math.ceil(#entries/2)*33
end

-- Repaint the three visible rows in place, including when a native collection read finishes mid-search.
function P.List(stage,env,parent,ui,y,state,options)
    local refresh
    local field=W.Edit(env,parent,state.query,0,y,225,function()
        if options.submit then options.submit(state.query) end
        refresh(); ui.Refresh()
    end,80)
    local placeholder=W.Text(field,options.hint,7,-6,210,12,W.colors.muted)
    W.Button(env,parent,options.submit and "Search" or "Clear",231,y,79,function()
        if options.submit then options.submit(field:GetText()) else field:SetText(""); field:SetFocus() end
        refresh(); ui.Refresh()
    end,nil,"quiet")
    y=y-35
    local cards={}
    local empty=W.Text(parent,"",4,y-27,302,13,W.colors.muted); empty:SetJustifyH("CENTER")
    for i=1,3 do
        local card={}; cards[i]=card
        local width=options.more and 235 or 310
        local b=W.Button(env,parent,"",0,y-(i-1)*39,width,function()
            field:ClearFocus()
            local row=card.row
            if row then P.Preview(stage,ui,card.button.label:GetText(),function() return options.preview(row) end) end
        end)
        card.button=b; b:SetHeight(36)
        card.icon=W.Texture(b,"ARTWORK"); card.icon:SetSize(28,28); card.icon:SetPoint("LEFT",b,"LEFT",5,0)
        card.detail=W.Text(b,"",40,-20,width-45,11,W.colors.muted)
        card.detail:SetWordWrap(false); card.detail:SetNonSpaceWrap(false)
        b.label:ClearAllPoints(); b.label:SetPoint("TOPLEFT",b,"TOPLEFT",40,-3); b.label:SetWidth(width-45)
        b.label:SetWordWrap(false); b.label:SetNonSpaceWrap(false)
        local enter=b:GetScript("OnEnter")
        W.Script(b,"OnEnter",function(self)
            enter(self)
            if card.row and env.GameTooltip then
                env.GameTooltip:SetOwner(b,"ANCHOR_RIGHT"); env.GameTooltip:SetText(card.tip); env.GameTooltip:Show()
            end
        end)
        if options.more then
            card.more=W.Button(env,parent,options.moreLabel,240,y-(i-1)*39,70,function()
                field:ClearFocus(); if card.row then options.more(card.row) end
            end,nil,"quiet")
            card.more:SetHeight(36)
        end
    end
    local count=ns.PhotoStyle.Pager(env,parent,y-118,function(delta) state.page=state.page+delta; refresh() end)
    refresh=function()
        local rows,reason=options.rows(state.query)
        local n=#rows
        state.page=math.max(1,math.min(math.max(1,math.ceil(n/3)),state.page))
        for i,card in ipairs(cards) do
            local row=rows[(state.page-1)*3+i]; card.row=row
            local b=card.button
            if row then
                local name,detail,icon,selected,tip,available=options.describe(row)
                b.label:SetText(name); card.detail:SetText(detail); card.tip=tip or (name.."\n"..detail)
                card.icon:SetTexture((type(icon)=="number" or type(icon)=="string") and icon or "Interface/AddOns/LumenShift/Media/ui-presets.tga")
                b.SetSelected(selected==true); ns.PhotoStyle.Enable(b,available~=false); b:Show()
                if card.more then card.more:Show() end
            else b:Hide(); if card.more then card.more:Hide() end end
        end
        if n==0 then empty:SetText(reason or "No matches. Try another name or slot."); empty:Show() else empty:Hide() end
        if state.query=="" then placeholder:Show() else placeholder:Hide() end
        count(state.page,3,n)
    end
    W.Script(field,"OnTextChanged",function()
        local q=field:GetText()
        if state.query~=q then
            state.query,state.page,ui.outfitFeedback=q,1,nil
            if options.edited then options.edited(q) end
            refresh(); ui.Refresh()
        end
    end)
    ui.RefreshOutfitResults=refresh
    refresh()
    return y-150
end
