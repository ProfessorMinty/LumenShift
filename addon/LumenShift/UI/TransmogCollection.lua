local _,ns=...
local U,W,P,L={},ns.Widgets,ns.OutfitPicker,ns.PortraitLibrary
ns.TransmogCollectionUI=U

function U.Build(runtime,env,parent,ui,y)
    local stage=runtime.portrait
    local c=stage.collection
    if not c.discovered then c.Discover(); c.discovered=true end
    if #c.categories==0 then
        W.Text(parent,c.status,0,y,310,12,W.colors.muted)
        W.Button(env,parent,"Check collection APIs again",0,y-54,310,function() c.discovered=false; ui.Build(true) end)
        return y-88
    end
    local sets=ui.collectionTab=="Collection sets"
    local category=c.Category(ui.collectionCategory) or c.categories[1]
    local all=not sets and ui.collectionCategory==0
    local scope=all and 0 or category.id
    local state=P.State(ui,sets and "collectionSets" or all and "acrossSlots" or "appearances")
    local function view(page)
        ui.outfitFeedback=nil; ui.outfitView=page; ui.Build(true)
    end
    local function load()
        if sets then c.setsAttempted=true; c.LoadSets()
        elseif not all or state.query:find("%S") then c.Load(scope,state.query) end
    end
    local function chooseScope(id)
        c.Cancel(); ui.collectionSources=nil; ui.outfitView=nil
        ui.outfitFeedback=nil
        ui.collectionTab=id=="sets" and "Collection sets" or "Appearances"
        if id~="sets" then ui.collectionCategory=id end
        local s=P.State(ui,id=="sets" and "collectionSets" or id==0 and "acrossSlots" or "appearances")
        if id==0 and not all and not sets and state.query:find("%S") then s.query=state.query
        elseif type(id)=="number" and id~=0 and id~=scope then s.query="" end
        s.page=1
        if id=="sets" then c.setsAttempted=true; c.LoadSets()
        elseif id~=0 or s.query:find("%S") then c.Load(id,s.query) end
        ui.Build(true)
    end
    if sets then
        if not c.setsAttempted then load() end
    elseif not all and (c.category~=scope or not c.attempted) then load() end

    ui.OutfitStatus=function()
        if all and (not c.attempted or state.query=="" or c.category~=0 or c.searchQuery~=state.query:lower()) then return "Search by appearance, source or item ID." end
        if not c.busy and (sets and c.setsLoaded or not sets and c.loaded and not c.partial) then
            if ui.outfitView=="sources" then return "Click a source to try that exact variant." end
            if not ui.outfitView then return sets and "Click a set to preview it on the selected actor." or "Click an appearance to try it on the selected actor." end
        end
        return c.status
    end
    local pane=ui.outfitView
    local function back() view(nil) end
    ui.collectionSlots=ui.collectionSlots or {}
    local function slotFor(cat) return ui.collectionSlots[cat.id] or cat.slots[1] end
    local sourceRow=ui.collectionSources
    local function match(row)
        local _,source=c.Match(row,state.query:lower(),ui.collectionSourceType)
        return source
    end
    local function sourceDetail(s)
        return (s.collected and "Collected" or "Uncollected").." · "..(ns.TransmogCollection.SourceTypes[s.sourceType] or "Source").." · "..s.sourceID
    end
    local function wearing(slot,id)
        local actor=stage.slots[stage.selected]
        local item=actor and actor.spec and actor.spec.outfit[slot]
        return type(item)=="table" and item.sourceID==id
    end
    local function tap(label,x,at,width,fn,tip)
        local b=W.Button(env,parent,label,x,at,width,fn,tip)
        b.label:SetWordWrap(false); b.label:SetNonSpaceWrap(false)
        return b
    end

    if pane=="scopes" then
        y=P.Header(env,parent,y,"Browse collection",back)
        local entries={{0,"All slots",all},{"sets","Collection sets",sets}}
        for _,cat in ipairs(c.categories) do entries[#entries+1]={cat.id,cat.name,not sets and cat.id==scope} end
        return P.Grid(env,parent,ui,y,entries,P.State(ui,"slotPages"),chooseScope)
    elseif pane=="filters" then
        y=P.Header(env,parent,y,"Collection filters",back)
        for i,label in ipairs({"All","Collected","Uncollected"}) do
            local b=ns.PhotoStyle.Tab(env,parent,label,(i-1)*104,y,102,function()
                ui.collectionOwned=label; state.page=1; ui.Build(true)
            end); b.SetSelected((ui.collectionOwned or "All")==label)
        end
        W.Toggle(env,parent,"WoW favorites only",0,y-33,310,function() return ui.collectionFavorites==true end,
            function(v) ui.collectionFavorites=v; state.page=1 end)
        if sets then
            tap("Refresh sets",0,y-78,310,function() load(); back() end)
            return y-115
        end
        tap("Source · "..(ns.TransmogCollection.SourceTypes[ui.collectionSourceType] or "All"),0,y-77,310,function() view("types") end)
        if #c.classes>0 then
            local class="Current"; for _,v in ipairs(c.classes) do if v.id==c.classID then class=v.name end end
            tap("WoW class · "..class,0,y-112,310,function() view("classes") end,"Changes WoW's shared wardrobe class filter.")
        end
        tap("Refresh",0,y-151,95,function() load(); back() end)
        tap("Reset WoW wardrobe filters",100,y-151,210,function()
            c.ResetFilters(); back()
        end,"Resets WoW's shared wardrobe filters and clears its search.")
        return y-185
    elseif pane=="classes" or pane=="types" then
        local types=pane=="types"
        y=P.Header(env,parent,y,types and "Source type" or "WoW wardrobe class",function() view("filters") end)
        local entries={}
        if types then
            entries={{0,"All sources",not ui.collectionSourceType}}
            for i,v in ipairs(ns.TransmogCollection.SourceTypes) do entries[#entries+1]={i,v,ui.collectionSourceType==i} end
        else for _,v in ipairs(c.classes) do entries[#entries+1]={v.id,v.name,c.classID==v.id} end end
        return P.Grid(env,parent,ui,y,entries,P.State(ui,pane),function(id)
            if types then ui.collectionSourceType=id~=0 and id or nil else c.SelectClass(id) end
            state.page=1; back()
        end)
    elseif pane=="hands" then
        local cat=sourceRow and c.Category(sourceRow.categoryID) or category
        local function done() view(sourceRow and "sources" or nil) end
        y=P.Header(env,parent,y,"Preview slot",done)
        local entries={}
        for _,slot in ipairs(cat.slots) do entries[#entries+1]={slot,L.Slot(slot),slotFor(cat)==slot} end
        return P.Grid(env,parent,ui,y,entries,P.State(ui,"hands"),function(slot) ui.collectionSlots[cat.id]=slot; done() end)
    elseif pane=="sources" and sourceRow then
        local cat=c.Category(sourceRow.categoryID)
        local at=y
        y=P.Header(env,parent,y,#cat.slots>1 and "Sources" or sourceRow.name,function() ui.collectionSources=nil; back() end)
        local slot=slotFor(cat)
        if #cat.slots>1 then tap(L.Slot(slot),208,at,102,function() view("hands") end) end
        local variants=P.State(ui,"variants")
        return P.List(stage,env,parent,ui,y,variants,{
            hint="Find a source or ID",
            rows=function(q)
                q=q:lower(); local result={}
                for _,s in ipairs(sourceRow.sources) do
                    if (not q:match("^%d+$") and s.name:lower():find(q,1,true)) or tostring(s.sourceID)==q or (s.itemID and tostring(s.itemID)==q) then result[#result+1]=s end
                end
                return result,"No matching source."
            end,
            describe=function(s) return s.name,sourceDetail(s),s.icon,wearing(slot,s.sourceID),s.name.."\n"..sourceDetail(s),not stage.busy end,
            preview=function(s) return stage.TrySource(slot,s.sourceID) end,
        })
    end

    local scopeName=sets and "Collection sets" or all and "All slots" or category.name
    local scopeButton=tap(scopeName,0,y,144,function() view("scopes") end,"Choose an equipment category, all slots or collection sets.")
    scopeButton.label:SetWidth(116)
    W.Text(scopeButton,"▾",124,-6,16,13,W.colors.muted)
    if not all and not sets and #category.slots>1 then
        tap(L.Slot(slotFor(category)),149,y,85,function() view("hands") end)
    elseif not all then
        tap("All slots",149,y,85,function() chooseScope(0) end,"Search appearances across all equipment slots.")
    else
        tap("Clear",149,y,85,function() c.Cancel(); state.query=""; state.page=1; ui.Build(true) end)
    end
    local filters=tap("Filters",239,y,71,function() view("filters") end)
    filters.SetSelected(ui.collectionFavorites or ui.collectionOwned and ui.collectionOwned~="All" or not sets and ui.collectionSourceType~=nil)
    local function submit(q)
        state.page=1
        if all and q:find("%S") and (c.category~=0 or c.searchQuery~=q:lower() or not c.loaded and not c.busy) then load() end
    end
    return P.List(stage,env,parent,ui,y-35,state,{
        hint=sets and "Find a collection set" or all and "Find across all slots" or ("Find in "..category.name),
        submit=all and submit or nil,
        edited=function(q) if all and c.busy and c.searchQuery~=q:lower() then c.Cancel() end end,
        rows=function(q)
            if all and (not c.attempted or not q:find("%S") or c.category~=0 or c.searchQuery~=q:lower()) then return {},"Enter a name or ID, then choose Search." end
            local rows=c.Filter(sets and c.sets or c.rows,q,ui.collectionOwned,ui.collectionFavorites,not sets and ui.collectionSourceType or nil)
            return rows,c.busy and c.status or ((sets and not c.setsLoaded or not sets and not c.loaded) and c.status or nil)
        end,
        describe=function(row)
            local source=not sets and match(row)
            local cat=not sets and c.Category(row.categoryID)
            local detail=(row.collected and "Collected" or "Uncollected")..(row.favorite and " · Favorite" or "")
            if source and source.collected~=row.collected then detail=source.collected and "Collected source" or "Uncollected source" end
            if cat then detail=detail.." · "..cat.name end
            if not sets and not source then detail="Source details unavailable" end
            return source and source.name or row.name,detail,source and source.icon or row.icon,
                source and wearing(slotFor(cat),source.sourceID),source and (source.name.."\n"..sourceDetail(source).."\nAppearance "..row.visualID..(row.collected and " · Collected" or " · Uncollected")),not stage.busy and (sets or source~=nil)
        end,
        preview=function(row)
            if sets then return stage.TryCollectionSet(row.setID)
            else local source=match(row); if source then return stage.TrySource(slotFor(c.Category(row.categoryID)),source.sourceID) end end
        end,
        moreLabel="Sources",more=not sets and function(row)
            ui.collectionSources=row; local s=P.State(ui,"variants"); s.page,s.query=1,""; view("sources")
        end or nil,
    })
end
