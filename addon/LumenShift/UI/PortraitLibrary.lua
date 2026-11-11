local _, ns = ...
local U,W,L = {},ns.Widgets,ns.PortraitLibrary; ns.PortraitLibraryUI=U
function U.Build(runtime,env,parent,ui,y,selected)
    local stage=runtime.portrait
    local function text(s,h) W.Text(parent,s,0,y,310,12,W.colors.muted); y=y-(h or 50) end
    local function action(label,fn) W.Button(env,parent,label,0,y,310,function() fn(); ui.Build() end); y=y-40 end
    local function page(items,key,draw)
        local pages=math.max(1,math.ceil(#items/8)); ui[key]=math.min(pages,math.max(1,ui[key] or 1))
        local current=ui[key]
        W.Button(env,parent,"Previous",0,y,98,function() ui[key]=math.max(1,current-1); ui.Build() end)
        W.Text(parent,current.." / "..pages,112,y-8,80,12,W.colors.muted)
        W.Button(env,parent,"Next",212,y,98,function() ui[key]=math.min(pages,current+1); ui.Build() end); y=y-40
        for i=(current-1)*8+1,math.min(#items,current*8) do draw(items[i],y); y=y-40 end
        if #items==0 then text("No matching entries. Try another category or refresh.",50) end
    end
    if ui.actorTab=="Effects" then
        text("Select a model spell effect.",32)
        if not stage.backend.Supports(stage.backend.models[selected.front],"spellKit") then
            text("This renderer does not support replaceable model spell effects. Other portrait tools remain available.",66); return y
        end
        for i,entry in ipairs(L.Kits) do
            local id=entry[1]
            local b=W.Button(env,parent,entry[2],(i-1)%2*156,y-math.floor((i-1)/2)*32,153,function() stage.SetActor("spellKit",id) end)
            b.SetSelected(selected.spec.spellKit==id)
        end
        y=y-math.ceil(#L.Kits/2)*32
    elseif ui.actorTab=="Outfits" then
        local wardrobe=stage.wardrobe
        text("Preview gear and collection appearances on this actor. Your real equipment and transmog collection stay unchanged.",64)
        if not stage.backend.Supports(stage.backend.models[selected.front],"outfit") then text("Outfit preview is unavailable on this model.",50); return y end
        for i,label in ipairs({"Items","Collection","Sets","Saved"}) do local category=label
            local b=W.Button(env,parent,({Sets="Equipment sets",Saved="Saved outfits"})[label] or label,(i-1)%2*160,y-math.floor((i-1)/2)*40,150,function()
                ui.wardrobeTab=category; ui.itemPage=1; if category~="Collection" then wardrobe.Refresh() end; ui.Build()
                if category=="Collection" and ui.collectionY then ui.scrollbar:SetValue(-ui.collectionY) end
            end)
            b.SetSelected((ui.wardrobeTab or "Items")==label)
        end; y=y-84
        if ui.wardrobeTab=="Collection" then ui.collectionY=y; return ns.TransmogCollectionUI.Build(runtime,env,parent,ui,y) end
        action("Refresh equipped / bags / sets",function() wardrobe.Refresh() end)
        text(wardrobe.status,math.max(44,math.ceil(#wardrobe.status/44)*16+12))
        if (ui.wardrobeTab or "Items")=="Items" then
            ui.outfitSlot=ui.outfitSlot or 5
            action("Slot: "..L.Slot(ui.outfitSlot).." - change",function() ui.showOutfitSlots=not ui.showOutfitSlots end)
            if ui.showOutfitSlots then
                for i,slot in ipairs(L.Slots) do local slotID=slot[1]
                    local b=W.Button(env,parent,slot[2],(i-1)%3*106,y-math.floor((i-1)/3)*38,98,function()
                        ui.outfitSlot=slotID; ui.itemPage=1; ui.showOutfitSlots=false; ui.Build()
                    end)
                    b.SetSelected(ui.outfitSlot==slotID)
                end; y=y-math.ceil(#L.Slots/3)*38-8
            end
            local search=W.Edit(env,parent,ui.itemQuery or "",0,y,224,function(v) ui.itemQuery=v; ui.itemPage=1; ui.Build() end,40)
            W.Button(env,parent,"Search",232,y,78,function() ui.itemQuery=search:GetText(); ui.itemPage=1; ui.Build() end); y=y-44
            page(wardrobe.Items(ui.outfitSlot,ui.itemQuery),"itemPage",function(item,at)
                local id=item.id; local b=W.Button(env,parent,item.name:sub(1,28),0,at,310,function() stage.TryItem(ui.outfitSlot,id); ui.Build() end)
                W.Tip(env,b,item.name.." | Item "..id.." | Preview only")
                if type(item.icon)=="number" then
                    local icon=W.Texture(b,"ARTWORK"); icon:SetSize(24,24); icon:SetPoint("LEFT",b,"LEFT",5,0); icon:SetTexture(item.icon)
                    b.label:ClearAllPoints(); b.label:SetPoint("LEFT",b,"LEFT",36,0); b.label:SetWidth(268)
                end
            end)
            text("Preview another item by ID or pasted item link:",38)
            local field=W.Edit(env,parent,ui.itemInput or "",0,y,224,function(v) ui.itemInput=v end,256)
            W.Button(env,parent,"Try on",232,y,78,function() ui.itemInput=field:GetText(); stage.TryItem(ui.outfitSlot,wardrobe.Parse(ui.itemInput)); ui.Build() end); y=y-44
            action("Hide selected slot",function() stage.TryItem(ui.outfitSlot,0) end)
        elseif ui.wardrobeTab=="Sets" then
            action("Preview my equipped outfit",stage.UseEquippedOutfit)
            for _,set in ipairs(wardrobe.sets) do local outfit=set.outfit; action(set.name,function() stage.SetOutfit(outfit) end) end
            text("WoW equipment sets appear when its equipment-set API is available. Unspecified set slots keep the model's original appearance.",76)
        else
            local field=W.Edit(env,parent,ui.outfitName or "My outfit",0,y,310,function(v) ui.outfitName=v end,32); y=y-40
            action("Save / replace outfit",function() ui.outfitName=field:GetText(); stage.SaveOutfit(ui.outfitName) end)
            for _,name in ipairs(ns.Value.Keys(runtime.db.camera.portrait.outfits)) do local key=name
                W.Button(env,parent,name,0,y,224,function() stage.SetOutfit(runtime.db.camera.portrait.outfits[key]); ui.Build() end)
                W.Button(env,parent,"Delete",232,y,78,function() runtime.db.camera.portrait.outfits[key]=nil; ui.Build() end); y=y-40
            end
        end
        action("Clear item overrides",function() stage.SetOutfit({}) end)
    end
    return y
end
