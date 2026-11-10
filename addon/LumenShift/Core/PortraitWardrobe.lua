local _, ns = ...
local U, V, L = {}, ns.Value, ns.PortraitLibrary; ns.PortraitWardrobe = U
function U.New(runtime)
    local reader, env = runtime.reader, runtime.reader.env
    local self = { items = {}, sets = {}, status = "Browse your equipped items, bags and saved sets." }
    local function call(fn, ...) return ns.ReadOnly.Call(reader, fn, ...) end
    local function id(value) return ns.ReadOnly.Accessible(reader,value) and V.Finite(value) and value%1==0 and value>0 and value<=9999999 end
    local function api(name) return env.C_Item and env.C_Item[name] or env[name] end
    function self.Info(itemID)
        if not id(itemID) then return nil end
        local r,why=call(api("GetItemInfo"),itemID)
        if not r then return nil,why end
        if r.n==0 or r[1]==nil then return nil,"ITEM_DATA_PENDING" end
        if r.n<10 or type(r[1])~="string" or type(r[2])~="string" or type(r[9])~="string" then return nil,"UNEXPECTED_ITEM_DATA" end
        local slots=L.EquipSlots[r[9]]; if not slots then return nil,"NOT_WEARABLE" end
        return { id=itemID, name=r[1]:gsub("|"," "):sub(1,80), link=r[2], slots=slots, icon=r[10] }
    end
    function self.Request(itemID)
        if id(itemID) then call(env.C_Item and env.C_Item.RequestLoadItemDataByID,itemID) end
    end
    function self.Capture(unit)
        local result={}
        for _,slot in ipairs(L.Slots) do
            local r=call(env.GetInventoryItemID,unit,slot[1])
            if not r or r.n~=1 or r[1]~=nil and r[1]~=0 and not id(r[1]) then return nil,"Equipment details unavailable; previous outfit kept." end
            result[slot[1]]=r[1] or 0
        end
        return result
    end
    function self.Refresh()
        local seen,items,sets,pending={}, {}, {}, 0
        local unavailable=false
        local function add(value)
            if not id(value) or seen[value] or #items>=256 then return end
            seen[value]=true
            local item,why=self.Info(value)
            if item then items[#items+1]=item
            elseif why=="ITEM_DATA_PENDING" then pending=pending+1; if pending<=64 then self.Request(value) end
            elseif why~="NOT_WEARABLE" then unavailable=true end
        end
        for _,slot in ipairs(L.Slots) do local r=call(env.GetInventoryItemID,"player",slot[1]); if r then add(r[1]) end end
        local container=env.C_Container or {}
        for bag=0,4 do
            local n=call(container.GetContainerNumSlots,bag)
            if n and n.n==1 and V.Finite(n[1]) and n[1]>=0 and n[1]<=100 then
                for index=1,n[1] do local r=call(container.GetContainerItemID,bag,index); if r then add(r[1]) end end
            end
        end
        local equipment=env.C_EquipmentSet or {}; local ids=call(equipment.GetEquipmentSetIDs)
        if ids and ids.n==1 and type(ids[1])=="table" then
            local count=0
            for _,setID in pairs(ids[1]) do
                count=count+1; if count>32 then break end
                if ns.ReadOnly.Accessible(reader,setID) and (id(setID) or setID==0) then
                    local info=call(equipment.GetEquipmentSetInfo,setID); local contents=call(equipment.GetItemIDs,setID)
                    if info and type(info[1])=="string" and contents and type(contents[1])=="table" then
                        local outfit={}
                        for _,slot in ipairs(L.Slots) do local item=contents[1][slot[1]]; if id(item) then outfit[slot[1]]=item; add(item) end end
                        if next(outfit) then sets[#sets+1]={ name=info[1]:gsub("|"," "):sub(1,64), outfit=outfit } end
                    end
                end
            end
        end
        table.sort(items,function(a,b) return a.name==b.name and a.id<b.id or a.name<b.name end)
        table.sort(sets,function(a,b) return a.name<b.name end)
        self.items,self.sets=items,sets
        self.status=#items.." wearable items; "..#sets.." equipment sets."..(pending>0 and " Some items are uncached; Refresh to check again." or "")
        if unavailable then self.status=self.status.." Some item information is unavailable." end
        return true
    end
    function self.Items(slot, query)
        local result={}; query=type(query)=="string" and query:lower():sub(1,40) or ""
        for _,item in ipairs(self.items) do
            local matches=false; for _,s in ipairs(item.slots) do if s==slot then matches=true end end
            if matches and (query=="" or item.name:lower():find(query,1,true) or tostring(item.id)==query) then result[#result+1]=item end
        end
        return result
    end
    function self.Parse(value)
        if type(value)~="string" or #value>256 then return nil end
        local raw=value:match("^%s*(%d+)%s*$") or value:match("|Hitem:(%d+):") or value:match("^item:(%d+)")
        local item=raw and tonumber(raw); return id(item) and item or nil
    end
    return self
end
