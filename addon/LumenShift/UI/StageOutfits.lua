local _,ns=...
local U,W,P,L={},ns.Widgets,ns.OutfitPicker,ns.PortraitLibrary
ns.StageOutfitsUI=U

local tabs={{"Collection","Collection"},{"Items","Items"},{"Sets","Gear sets"},{"Saved","Saved outfits"}}
function U.Build(runtime,env,parent,ui,y,selected)
    local stage=runtime.portrait
    local wardrobe=stage.wardrobe
    if not stage.backend.Supports(stage.backend.models[selected.front],"outfit") then
        W.Text(parent,"This actor cannot preview outfits on this renderer.",0,y,310,13,W.colors.muted)
        return y-42
    end
    local tab=ui.wardrobeTab
    for i,t in ipairs(tabs) do
        local key=t[1]
        local b=ns.PhotoStyle.Tab(env,parent,t[2],(i-1)*77.5,y,77.5,function()
            ui.wardrobeTab,ui.outfitView,ui.collectionSources,ui.outfitFeedback=key,nil,nil,nil
            if key=="Items" or key=="Sets" then wardrobe.Refresh() end
            ui.Build(true)
        end)
        b.SetSelected(key==tab)
    end
    y=y-34
    if tab=="Collection" then return ns.TransmogCollectionUI.Build(runtime,env,parent,ui,y) end
    local state=P.State(ui,tab)
    local function view(page) ui.outfitView=page; ui.outfitFeedback=nil; ui.Build(true) end
    local function back() view(nil) end
    local slot=ui.outfitSlot or 5
    if ui.outfitView=="slots" then
        y=P.Header(env,parent,y,"Equipment slot",back)
        return P.Grid(env,parent,ui,y,L.Slots,P.State(ui,"itemSlots"),function(id)
            ui.outfitSlot=id; state.page=1; back()
        end)
    elseif ui.outfitView=="itemID" then
        y=P.Header(env,parent,y,"Preview by item ID or link",back)
        local field
        local function apply()
            ui.itemInput=field:GetText()
            P.Preview(stage,ui,"item",function() return stage.TryItem(slot,wardrobe.Parse(ui.itemInput)) end)
        end
        field=W.Edit(env,parent,ui.itemInput or "",0,y,310,apply,256)
        W.Script(field,"OnTextChanged",function() ui.itemInput=field:GetText() end)
        W.Button(env,parent,"Try on",0,y-37,310,apply,nil,"primary")
        return y-74
    elseif ui.outfitView=="tools" then
        y=P.Header(env,parent,y,"Item tools",back)
        W.Button(env,parent,"Refresh inventory",0,y,310,function() wardrobe.Refresh(); back() end)
        W.Button(env,parent,"Hide "..L.Slot(slot),0,y-37,310,function() stage.TryItem(slot,0) end)
        W.Button(env,parent,"Clear item overrides",0,y-74,310,function() stage.SetOutfit({}) end)
        W.Text(parent,wardrobe.status,0,y-117,310,12,W.colors.muted)
        return y-182
    elseif ui.outfitView=="saveOutfit" then
        y=P.Header(env,parent,y,"Name this outfit",back)
        local field
        local function save()
            local name=field:GetText(); ui.outfitName=name
            if stage.SaveOutfit(name) then state.query=name; state.page=1; back() end
        end
        field=W.Edit(env,parent,ui.outfitName or "My outfit",0,y,310,save,32)
        W.Script(field,"OnTextChanged",function() ui.outfitName=field:GetText() end)
        W.Button(env,parent,"Save / replace outfit",0,y-38,310,save,nil,"primary")
        return y-76
    end
    if tab=="Items" then
        W.Button(env,parent,L.Slot(slot),0,y,115,function() view("slots") end)
        W.Button(env,parent,"Item ID / link",121,y,115,function() view("itemID") end)
        W.Button(env,parent,"Tools",242,y,68,function() view("tools") end)
        return P.List(stage,env,parent,ui,y-35,state,{
            hint="Find an inventory item",rows=function(q) return wardrobe.Items(slot,q) end,
            describe=function(item) return item.name,"Item "..item.id,item.icon,selected.spec.outfit[slot]==item.id,nil,not stage.busy end,
            preview=function(item) return stage.TryItem(slot,item.id) end,
        })
    end
    local saved=tab=="Saved"
    if saved then
        W.Button(env,parent,"Save current outfit",0,y,194,function() view("saveOutfit") end,nil,"primary")
    else
        W.Button(env,parent,"Preview equipped",0,y,194,function() P.Preview(stage,ui,"equipped outfit",stage.UseEquippedOutfit) end)
    end
    W.Button(env,parent,saved and "Clear overrides" or "Refresh",200,y,110,function()
        if saved then stage.SetOutfit({}) else wardrobe.Refresh(); ui.Build() end
        ui.outfitFeedback=nil
    end)
    local bank=runtime.db.camera.portrait.outfits
    return P.List(stage,env,parent,ui,y-35,state,{
        hint=saved and "Find a saved outfit" or "Find an equipment set",
        rows=function(q)
            local rows={}; q=q:lower()
            if saved then
                for _,name in ipairs(ns.Value.Keys(bank)) do if name:lower():find(q,1,true) then rows[#rows+1]={name=name,outfit=bank[name]} end end
            else
                for _,set in ipairs(wardrobe.sets) do if set.name:lower():find(q,1,true) then rows[#rows+1]=set end end
            end
            return rows,saved and "No matching saved outfits." or "No matching equipment sets."
        end,
        describe=function(row) return row.name,saved and "Saved outfit" or "Equipment set",nil,false,nil,not stage.busy end,
        preview=function(row) return stage.SetOutfit(row.outfit) end,
        moreLabel="Delete",more=saved and function(row) bank[row.name]=nil; ui.outfitFeedback=nil; ui.Build() end or nil,
    })
end
