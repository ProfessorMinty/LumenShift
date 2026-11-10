local _, ns = ...
local T, V = {}, ns.Value; ns.TransmogCollection = T
local armorSlots = { [1]=1,[2]=3,[3]=15,[4]=5,[5]=4,[6]=19,[7]=9,[8]=10,[9]=6,[10]=7,[11]=8 }
T.SourceTypes = { "Encounter", "Quest", "Vendor", "World drop", "Hidden until collected", "Cannot collect", "Achievement", "Profession", "Not for transmog", "Trading Post" }
function T.New(runtime)
    local reader, env = runtime.reader, runtime.reader.env
    local self = { rows={}, sets={}, categories={}, classes={}, generation=0, status="Choose a collection category." }
    local function call(name, ...) return ns.ReadOnly.Call(reader, env.C_TransmogCollection and env.C_TransmogCollection[name], ...) end
    local function access(v) return ns.ReadOnly.Accessible(reader,v) end
    local function id(v) return access(v) and V.Finite(v) and v>0 and v%1==0 and v<=9999999 end
    local function clean(v, max)
        if not access(v) or type(v)~="string" then return nil end
        return v:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("[%c|]"," "):sub(1,max or 96)
    end
    local function tableResult(r) return r and r.n==1 and type(r[1])=="table" and r[1] end
    local function changed() if self.RefreshUI then self.RefreshUI() end end
    function self.Cancel()
        self.generation=self.generation+1
        if self.busy then self.loaded=false; self.attempted=false; self.status="Collection loading stopped. Reopen or Refresh to continue." end
        self.busy=false
    end
    function self.Discover()
        self.categories, self.classes = {}, {}
        for category=1,29 do
            local r=call("GetCategoryInfo",category)
            if r and r.n==6 and clean(r[1]) and type(r[2])=="boolean" then
                local slots={}
                if armorSlots[category] then slots={armorSlots[category]}
                else for i,slot in ipairs({16,17,18}) do if r[i+3]==true then slots[#slots+1]=slot end end end
                if #slots>0 then self.categories[#self.categories+1]={ id=category,name=clean(r[1]),slots=slots } end
            end
        end
        local r=ns.ReadOnly.Call(reader,env.C_SpecializationInfo and env.C_SpecializationInfo.GetAllClassIDs)
        local ids=tableResult(r)
        if ids then local n=0; for _,classID in ipairs(ids) do
            n=n+1; if n>64 then break end
            if id(classID) then
                local info=tableResult(ns.ReadOnly.Call(reader,env.C_CreatureInfo and env.C_CreatureInfo.GetClassInfo,classID))
                local name=info and clean(info.className,40)
                if name then self.classes[#self.classes+1]={id=classID,name=name} end
            end
        end end
        local current=call("GetClassFilter"); self.classID=current and id(current[1]) and current[1] or nil
        if #self.categories==0 then self.status="Transmog collection categories are unavailable on this client. Items and saved outfits still work." end
        return #self.categories>0
    end
    function self.Category(category)
        for _,c in ipairs(self.categories) do if c.id==category then return c end end
    end
    function self.Source(sourceID, supplied)
        if not id(sourceID) then return nil end
        local raw=supplied or tableResult(call("GetSourceInfo",sourceID))
        if not access(raw) or type(raw)~="table" then return nil end
        for _,key in ipairs({"sourceID","visualID","itemID","categoryID","isCollected","sourceType","canDisplayOnPlayer","isValidSourceForPlayer"}) do
            if not access(raw[key]) then return nil end
        end
        if raw.sourceID~=sourceID or not id(raw.visualID) or not id(raw.categoryID) or type(raw.isCollected)~="boolean" then return nil end
        local category=self.Category(raw.categoryID)
        if not category then return nil end
        local name=clean(raw.name)
        if not name and id(raw.itemID) then local item=runtime.portrait.wardrobe.Info(raw.itemID); name=item and item.name end
        local icon=call("GetSourceIcon",sourceID)
        return {sourceID=sourceID,visualID=raw.visualID,itemID=id(raw.itemID) and raw.itemID or nil,
            categoryID=raw.categoryID,slots=category.slots,name=name or "Appearance source "..sourceID,
            collected=raw.isCollected,sourceType=id(raw.sourceType) and raw.sourceType or nil,
            usable=raw.isValidSourceForPlayer==true,displayable=raw.canDisplayOnPlayer==true,
            icon=icon and id(icon[1]) and icon[1] or nil}
    end
    function self.Load(category)
        self.Cancel(); self.rows={}; self.category=category; self.loaded=false; self.attempted=true
        if not self.Category(category) then self.status="Choose an available collection category."; changed(); return nil end
        local raw=tableResult(call("GetCategoryAppearances",category))
        if not raw then self.status="Collection data is unavailable or still loading. Refresh to try again."; changed(); return nil end
        local total=#raw
        if total>25000 then self.status="This category exceeds the supported browser size. Choose another category."; changed(); return nil end
        local token,index,skipped,seen=self.generation,1,0,{}
        self.busy=true; self.status="Reading "..total.." appearances..."
        local function step()
            if token~=self.generation then return end
            for _=1,24 do
                local a=raw[index]; if index>total then break end; index=index+1
                if access(a) and type(a)=="table" and id(a.visualID) and access(a.isCollected) and type(a.isCollected)=="boolean"
                    and access(a.isHideVisual) and not a.isHideVisual and not seen[a.visualID] then
                    seen[a.visualID]=true
                    local sources=tableResult(call("GetAppearanceSources",a.visualID,category)); local valid={}
                    if sources then
                        local n=0; for _,s in ipairs(sources) do
                            n=n+1; if n>1024 then skipped=skipped+1; break end
                            if access(s) and type(s)=="table" and id(s.sourceID) then
                                local entry=self.Source(s.sourceID,s)
                                if entry and entry.visualID==a.visualID and entry.categoryID==category then valid[#valid+1]=entry
                                else skipped=skipped+1 end
                            else skipped=skipped+1
                            end
                        end
                    end
                    table.sort(valid,function(a,b) if a.collected~=b.collected then return a.collected end; return a.sourceID<b.sourceID end)
                    local first=valid[1]
                    self.rows[#self.rows+1]={visualID=a.visualID,collected=a.isCollected,
                        favorite=access(a.isFavorite) and a.isFavorite==true,name=first and first.name or "Appearance "..a.visualID,
                        icon=first and first.icon,sources=valid}
                    if not first then skipped=skipped+1 end
                elseif not (access(a) and type(a)=="table" and
                    (access(a.isHideVisual) and a.isHideVisual or id(a.visualID) and seen[a.visualID])) then skipped=skipped+1 end
            end
            if index<=total then
                if not ns.ReadOnly.Call(reader,env.C_Timer and env.C_Timer.After,.01,step) then
                    self.generation=self.generation+1; self.busy=false; self.status="Collection loading paused: timer unavailable. Refresh to retry."; changed()
                end
            else
                self.busy=false; self.loaded=true
                table.sort(self.rows,function(a,b) return a.name==b.name and a.visualID<b.visualID or a.name<b.name end)
                self.status=#self.rows.." appearances returned by WoW."..(skipped>0 and " Source details incomplete (unavailable, invalid or over the browser limit)." or "")
                changed()
            end
        end
        if not ns.ReadOnly.Call(reader,env.C_Timer and env.C_Timer.After,0,step) then self.generation=self.generation+1; self.busy=false; self.status="Collection timer unavailable."; changed(); return nil end
        return true
    end
    function self.Filter(rows, query, owned, favorites, sourceType)
        local result={}; query=type(query)=="string" and query:lower():sub(1,80) or ""
        for _,row in ipairs(rows) do
            local match=query=="" or row.name:lower():find(query,1,true) or tostring(row.visualID or row.setID)==query
            local sourceMatch=not sourceType
            for _,s in ipairs(row.sources or {}) do
                if not match and (s.name:lower():find(query,1,true) or tostring(s.itemID)==query or tostring(s.sourceID)==query) then match=true end
                if s.sourceType==sourceType then sourceMatch=true end
            end
            if match and sourceMatch and (owned=="All" or owned==nil or owned=="Collected" and row.collected or owned=="Uncollected" and not row.collected)
                and (not favorites or row.favorite) then result[#result+1]=row end
        end
        return result
    end
    function self.LoadSets()
        self.Cancel(); self.sets={}; self.setsLoaded=false
        local api=env.C_TransmogSets or {}; local data=tableResult(ns.ReadOnly.Call(reader,api.GetAllSets))
        if not data or #data>20000 then self.status="Native transmog sets are unavailable. Appearance browsing still works."; return nil end
        for _,s in ipairs(data) do
            if access(s) and type(s)=="table" and id(s.setID) and clean(s.name) and access(s.collected) and type(s.collected)=="boolean"
                and access(s.hiddenUntilCollected) and (not s.hiddenUntilCollected or s.collected) then
                local label=clean(s.label,64)
                self.sets[#self.sets+1]={setID=s.setID,name=clean(s.name)..(label and " - "..label or ""),
                    collected=s.collected,favorite=access(s.favorite) and s.favorite==true}
            end
        end
        table.sort(self.sets,function(a,b) return a.name==b.name and a.setID<b.setID or a.name<b.name end)
        self.setsLoaded=true; self.status=#self.sets.." native sets and variants."; return true
    end
    function self.SetOutfit(setID)
        if not id(setID) then return nil end
        local api=env.C_TransmogSets or {}; local data=tableResult(ns.ReadOnly.Call(reader,api.GetSetPrimaryAppearances,setID))
        if not data or #data>64 then return nil,"Set appearance data is unavailable." end
        local outfit={}
        for _,a in ipairs(data) do
            -- Blizzard's set field is named appearanceID but contains a source ID.
            local s=access(a) and type(a)=="table" and self.Source(a.appearanceID)
            if not s then return nil,"A set source is unavailable; previous outfit kept." end
            local slot=s.slots[1]
            if outfit[slot] then return nil,"This set has ambiguous preview slots; choose its appearances separately." end
            outfit[slot]={sourceID=s.sourceID}
        end
        if not next(outfit) then return nil,"This set has no previewable appearances." end
        return outfit
    end
    function self.SelectClass(classID)
        local found=false; for _,c in ipairs(self.classes) do if c.id==classID then found=true end end
        if not found then return nil end
        local r=call("SetClassFilter",classID); local read=call("GetClassFilter")
        if not r or r.n~=0 or not read or read[1]~=classID then self.status="WoW could not change its collection class filter."; return nil end
        self.classID=classID; return self.Load(self.category)
    end
    function self.ResetFilters()
        self.Cancel(); self.loaded=false
        -- Explicit browser action only. These are shared wardrobe display filters,
        -- never equipment/transmog application, graphics CVars or automatic setup.
        local api=env.C_TransmogCollection or {}
        for _,name in ipairs({"SetDefaultFilters","SetCollectedShown","SetUncollectedShown","ClearSearch"}) do
            if type(api[name])~="function" then self.status="WoW collection filter reset is unavailable."; return nil end
        end
        for _,op in ipairs({{"SetDefaultFilters"},{"SetCollectedShown",true},{"SetUncollectedShown",true}}) do
            local r=call(op[1],unpack(op,2,#op)); if not r or r.n~=0 then self.status="WoW rejected a collection filter change; Refresh to inspect its results."; return nil end
        end
        local r=call("ClearSearch",1)
        if not r or r.n~=1 or type(r[1])~="boolean" then self.status="WoW could not clear its collection search."; return nil end
        self.status=r[1] and "WoW collection filters reset. Refresh the collection." or "WoW is updating its collection search. Refresh when ready."
        local current=call("GetClassFilter"); self.classID=current and id(current[1]) and current[1] or nil
        if r[1] then return self.Load(self.category) end
        return true
    end
    return self
end
