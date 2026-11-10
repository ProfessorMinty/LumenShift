local _,ns=...
local U,W={},ns.Widgets; ns.TransmogCollectionUI=U
function U.Build(runtime,env,parent,ui,y)
    local stage=runtime.portrait; local c=stage.collection
    local function text(s,h) W.Text(parent,s,0,y,310,12,W.colors.muted); y=y-(h or math.max(40,math.ceil(#s/43)*16+12)) end
    local function button(label,fn,tip) W.Button(env,parent,label,0,y,310,function() fn(); ui.Build() end,tip); y=y-40 end
    local function pages(rows,key,draw,height)
        local count=math.max(1,math.ceil(#rows/8)); ui[key]=math.max(1,math.min(count,ui[key] or 1)); local page=ui[key]
        W.Button(env,parent,"Previous",0,y,98,function() ui[key]=math.max(1,page-1); ui.Build() end)
        W.Text(parent,page.." / "..count,112,y-8,92,12,W.colors.muted)
        W.Button(env,parent,"Next",212,y,98,function() ui[key]=math.min(count,page+1); ui.Build() end); y=y-40
        for i=(page-1)*8+1,math.min(#rows,page*8) do draw(rows[i]); y=y-(height or 62) end
        if #rows==0 then text(c.busy and "Reading the collection..." or "No matches. Try All, another category, or Refresh.") end
    end
    local function icon(b,value)
        if value then local t=W.Texture(b,"ARTWORK"); t:SetSize(24,24); t:SetPoint("LEFT",b,"LEFT",4,0); t:SetTexture(value)
            b.label:ClearAllPoints(); b.label:SetPoint("LEFT",b,"LEFT",34,0); b.label:SetWidth(b:GetWidth()-42) end
    end
    W.Button(env,parent,"Outfits / back to outfit tools",0,y,310,function() ui.scrollbar:SetValue(-ui.libraryY) end); y=y-40
    if not c.discovered then c.Discover(); c.discovered=true end
    if #c.categories==0 then
        text(c.status); button("Check collection APIs again",function() c.discovered=false end); return y
    end
    for i,label in ipairs({"Appearances","Collection sets"}) do local selected=label
        local b=W.Button(env,parent,label,(i-1)*160,y,150,function()
            ui.collectionTab=selected; ui.collectionSources=nil; ui.collectionPage=1; c.Cancel()
            if selected=="Collection sets" then c.LoadSets() else c.Load(ui.collectionCategory or c.categories[1].id) end; ui.Build()
        end); b.SetSelected((ui.collectionTab or "Appearances")==label)
    end; y=y-44
    local sets=ui.collectionTab=="Collection sets"
    local refreshY=y
    if not sets then
        ui.collectionCategory=ui.collectionCategory or c.categories[1].id
        local category=c.Category(ui.collectionCategory) or c.categories[1]; ui.collectionCategory=category.id
        local categoryButton=W.Button(env,parent,category.name.." - category",0,y,224,function() ui.collectionCategories=not ui.collectionCategories; ui.Build() end)
        categoryButton.label:SetWordWrap(false); W.Tip(env,categoryButton,category.name); y=y-40
        if ui.collectionCategories then
            for i,entry in ipairs(c.categories) do local item=entry
                local b=W.Button(env,parent,item.name,(i-1)%2*160,y-math.floor((i-1)/2)*38,150,function()
                    ui.collectionCategory=item.id; ui.collectionCategories=false; ui.collectionSources=nil; ui.collectionPage=1
                    ui.collectionSlot=item.slots[1]; c.Load(item.id); ui.Build()
                end); b.SetSelected(item.id==category.id); b.label:SetWordWrap(false); W.Tip(env,b,item.name)
            end; y=y-math.ceil(#c.categories/2)*38-8
        end
        local found=false; for _,slot in ipairs(category.slots) do if slot==ui.collectionSlot then found=true end end
        if not found then ui.collectionSlot=category.slots[1] end
        if #category.slots>1 then
            for i,slot in ipairs(category.slots) do local target=slot
                local b=W.Button(env,parent,ns.PortraitLibrary.Slot(slot),(i-1)*106,y,98,function() ui.collectionSlot=target; ui.Build() end)
                b.SetSelected(ui.collectionSlot==slot)
            end; y=y-40
        end
        if c.category~=category.id or not c.loaded and not c.busy and not c.attempted then c.attempted=true; c.Load(category.id) end
    elseif not c.setsLoaded and not c.setsAttempted then c.setsAttempted=true; c.LoadSets() end
    W.Button(env,parent,"Refresh",232,refreshY,78,function()
        ui.collectionSources=nil; if sets then c.LoadSets() else c.Load(ui.collectionCategory) end; ui.Build()
    end)
    if sets then y=y-40 end
    if ui.collectionSources and not sets then
        local sources=ui.collectionSources.sources
        button("Back to appearances",function() ui.collectionSources=nil end)
        text(ui.collectionSources.name.." - choose an exact appearance source")
        pages(sources,"collectionSourcePage",function(source)
            local s=source
            local b=W.Button(env,parent,s.name,0,y,310,function() stage.TrySource(ui.collectionSlot,s.sourceID); ui.Build() end)
            b.label:SetWordWrap(false); b.label:SetNonSpaceWrap(false); icon(b,s.icon)
            W.Tip(env,b,s.name.." | Source "..s.sourceID.." | "..(s.itemID and "Item "..s.itemID or "Item unknown"))
            W.Text(parent,(s.collected and "Collected" or "Uncollected").." | "..(ns.TransmogCollection.SourceTypes[s.sourceType] or "Source unknown"),4,y-34,302,11,W.colors.muted)
        end)
        text("Preview only. Collection ownership and your real gear do not change. An appearance may be unavailable on a particular model.")
        return y
    end
    local query=W.Edit(env,parent,ui.collectionQuery or "",0,y,224,function(v) ui.collectionQuery=v; ui.collectionPage=1; ui.Build() end,80)
    W.Tip(env,query,"Search this category by appearance/source name, appearance ID, source ID or item ID.")
    W.Button(env,parent,"Search",232,y,78,function() ui.collectionQuery=query:GetText(); ui.collectionPage=1; ui.Build() end); y=y-42
    button("Filters: "..(ui.collectionOwned or "All")..(ui.collectionFavorites and " / favorites" or ""),function() ui.collectionFilters=not ui.collectionFilters end)
    if ui.collectionFilters then
        for i,label in ipairs({"All","Collected","Uncollected"}) do local choice=label
            local b=W.Button(env,parent,label,(i-1)*106,y,98,function() ui.collectionOwned=choice; ui.collectionPage=1; ui.Build() end)
            b.SetSelected((ui.collectionOwned or "All")==label)
        end; y=y-42
        W.Toggle(env,parent,"WoW favorites only",0,y,310,function() return ui.collectionFavorites==true end,
            function(v) ui.collectionFavorites=v; ui.collectionPage=1; ui.Build() end); y=y-46
        if not sets then
            button("Source: "..(ns.TransmogCollection.SourceTypes[ui.collectionSourceType] or "All"),function() ui.collectionSourceFilters=not ui.collectionSourceFilters end)
            if ui.collectionSourceFilters then
                button("All sources",function() ui.collectionSourceType=nil; ui.collectionSourceFilters=false; ui.collectionPage=1 end)
                for i,label in ipairs(ns.TransmogCollection.SourceTypes) do local index=i
                    local b=W.Button(env,parent,label,(i-1)%2*160,y-math.floor((i-1)/2)*38,150,function()
                        ui.collectionSourceType=index; ui.collectionSourceFilters=false; ui.collectionPage=1; ui.Build()
                    end); b.label:SetWordWrap(false); W.Tip(env,b,label)
                end; y=y-math.ceil(#ns.TransmogCollection.SourceTypes/2)*38-8
            end
        end
        if not sets and #c.classes>0 then
            local name="Current"; for _,entry in ipairs(c.classes) do if entry.id==c.classID then name=entry.name end end
            button("WoW collection class: "..name,function() ui.collectionClasses=not ui.collectionClasses end,
                "Changes WoW's shared wardrobe class filter. Does not change your character or equipment.")
            if ui.collectionClasses then
                for i,entry in ipairs(c.classes) do local class=entry
                    W.Button(env,parent,class.name,(i-1)%2*160,y-math.floor((i-1)/2)*38,150,function()
                        ui.collectionClasses=false; ui.collectionSources=nil; ui.collectionPage=1; c.SelectClass(class.id); ui.Build()
                    end)
                end; y=y-math.ceil(#c.classes/2)*38-8
            end
        end
        if not sets then
            button("Reset WoW wardrobe filters",function() c.Cancel(); c.ResetFilters() end,
                "Clears WoW's appearance search and resets its shared wardrobe display filters. Your real gear stays unchanged.")
            text("WoW's wardrobe filters can limit this list. Uncollected appearances are shown only when the client supplies them.")
        end
    end
    local rows=c.Filter(sets and c.sets or c.rows,ui.collectionQuery,ui.collectionOwned,ui.collectionFavorites,not sets and ui.collectionSourceType or nil)
    if c.busy or not (sets and c.setsLoaded or not sets and c.loaded) then text(c.status) end
    text(#rows.." matches"..(sets and " across native sets and variants." or ". Click an appearance to preview it."),34)
    pages(rows,"collectionPage",function(row)
        local item=row
        if sets then
            local b=W.Button(env,parent,item.name,0,y,310,function() stage.TryCollectionSet(item.setID); ui.Build() end)
            b.label:SetWordWrap(false); b.label:SetNonSpaceWrap(false); W.Tip(env,b,item.name.." | Set "..item.setID)
        else
            local s=item.sources[1]
            if ui.collectionSourceType then for _,source in ipairs(item.sources) do if source.sourceType==ui.collectionSourceType then s=source; break end end end
            local b=W.Button(env,parent,item.name,0,y,224,function()
                if s then stage.TrySource(ui.collectionSlot,s.sourceID) else stage.status="Source details unavailable. Refresh the collection." end; ui.Build()
            end); b.label:SetWordWrap(false); b.label:SetNonSpaceWrap(false); icon(b,item.icon); W.Tip(env,b,item.name.." | Appearance "..item.visualID)
            W.Button(env,parent,"Sources",232,y,78,function() ui.collectionSources=item; ui.collectionSourcePage=1; ui.Build() end)
        end
        W.Text(parent,(item.collected and "Collected" or "Uncollected")..(item.favorite and " | Favorite" or ""),4,y-34,302,11,W.colors.muted)
    end)
    text(c.status)
    return y
end
