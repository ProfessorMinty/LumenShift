local _, ns = ...
local L, W = {}, ns.Widgets
ns.SavedLibraryUI = L

local pageSize = 3
local function enable(button, available)
    if available then button:Enable(); button:SetAlpha(1)
    else button:Disable(); button:SetAlpha(.55) end
end

local function matches(name, query)
    return name:lower():find(query:lower(), 1, true) ~= nil
end

local function alphabetical(a, b)
    local x, y = a:lower(), b:lower()
    if x == y then return a < b end
    return x < y
end

local function nameForm(lib, env, parent, ui, state)
    local field, commit
    local function save()
        local name = field:GetText()
        if not lib.validName(name) then return end
        local ok, why = lib.save(name)
        if not ok then
            state.note = ns.Product.Message(why) or ("Could not save this "..lib.unit..".")
            ui.Refresh(); return
        end
        if not matches(name, state.query) then state.query="" end
        state.selected, state.reveal = name, true
        state.naming, state.draft, state.note = false, nil, lib.savedMessage
        ui.Build(true)
    end
    W.Text(parent, "Save current "..lib.unit, 0, 0, 310, 17)
    W.Text(parent, lib.description,
        0, -28, 310, 12, W.colors.muted)
    W.Text(parent, "Name", 0, -64, 310, 12)
    field = W.Edit(env,parent,state.draft or "",0,-87,310,save,32)
    local help = W.Text(parent,"",0,-124,310,12,W.colors.muted)
    commit = W.Button(env,parent,"Save "..lib.unit,0,-178,193,save,nil,"primary")
    W.Button(env,parent,"Back",201,-178,109,function()
        state.naming, state.draft, state.note = false,nil,nil; ui.Build(true)
    end,nil,"quiet")
    local useName = W.Button(env,parent,"Use selected name",141,-64,169,function()
        if state.selected then field:SetText(state.selected); field:SetFocus(); field:HighlightText() end
    end,nil,"quiet")
    useName:SetHeight(23)
    if not lib.bank[state.selected] then useName:Hide() end
    ui.RefreshSavedLibrary = function()
        local name = field:GetText()
        local exists = lib.bank[name] ~= nil
        local count = #ns.Value.Keys(lib.bank)
        local full = count >= lib.limit
        local valid = lib.validName(name)
        commit.label:SetText((exists and "Replace " or "Save ")..lib.unit)
        enable(commit, valid and (exists or not full) and (not lib.worker or not lib.worker.busy))
        if name~="" and not valid then help:SetText("Use up to 32 bytes of text without formatting codes.")
        elseif exists then help:SetText("Saving replaces the entry with this name.")
        elseif full then help:SetText("Library full. Use an existing name to replace an entry.")
        else help:SetText(count.." of "..lib.limit.." saved") end
        return state.note or ""
    end
    W.Script(field,"OnTextChanged",function()
        state.draft=field:GetText(); state.note=nil; ui.Refresh()
    end)
    if state.focusName then state.focusName=nil; field:SetFocus() end
    return -216
end

function L.Build(runtime, env, parent, ui, page, lib)
    local state = ui.savedLibraries[page]
    if state.naming then return nameForm(lib,env,parent,ui,state) end
    local field = W.Edit(env,parent,state.query,0,0,182,function() end,32)
    local hint = W.Text(field,"Find "..page:lower(),7,-6,169,12,W.colors.muted)
    local newSave=W.Button(env,parent,"Save current",190,0,120,function()
        state.naming, state.focusName, state.note, state.watching = true,true,nil,nil
        ui.Build(true)
    end,"Name and save your current "..lib.unit)

    local rows = {}
    for i=1,pageSize do
        local row
        row = W.Button(env,parent,"",0,-40-(i-1)*48,310,function()
            field:ClearFocus()
            state.selected, state.note, state.watching = row.presetName,nil,nil
            ui.Refresh()
        end)
        row:SetHeight(44); row.presetName=nil; row.presetData=nil
        row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT",row,"TOPLEFT",76,-4)
        row.label:SetWidth(228); row.label:SetWordWrap(false)
        row.detail=W.Text(row,"",76,-23,228,11,W.colors.muted); row.detail:SetWordWrap(false)
        row.picture=W.Texture(row,"ARTWORK")
        row.picture:SetPoint("CENTER",row,"LEFT",38,0); row.picture:SetSize(60,34)
        if lib.initCard then lib.initCard(row) end
        local enter=row:GetScript("OnEnter")
        W.Script(row,"OnEnter",function(b)
            enter(b)
            if b.presetName and env.GameTooltip then
                env.GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
                env.GameTooltip:SetText(b.presetName.."\n"..b.presetTip); env.GameTooltip:Show()
            end
        end)
        rows[i]=row
    end
    local empty=W.Text(parent,"",0,-66,310,14,W.colors.muted); empty:SetJustifyH("CENTER")
    local clear=W.Button(env,parent,"Clear search",93,-99,124,function()
        field:SetText(""); field:SetFocus()
    end,nil,"quiet")
    local actions=env.CreateFrame("Frame",nil,parent)
    actions:SetSize(310,82)
    local function turn(delta)
        state.page=state.page+delta; state.note=nil; state.watching=nil; ui.Refresh()
    end
    local prev=W.Button(env,actions,"Previous",0,0,85,function() turn(-1) end,nil,"quiet")
    local nextPage=W.Button(env,actions,"Next",226,0,84,function() turn(1) end,nil,"quiet")
    local counter=W.Text(actions,"",85,-7,140,12,W.colors.muted); counter:SetJustifyH("CENTER")
    W.Rule(actions,0,-36,310)
    local apply=W.Button(env,actions,"Apply "..lib.unit,0,-47,151,function()
        local name=state.selected
        if not name or not lib.bank[name] then return end
        field:ClearFocus()
        state.note, state.watching = lib.apply(name)
        ui.Refresh()
    end,nil,"primary")
    local after=W.Button(env,actions,"Show After",155,-47,88,function()
        runtime.photoPreview.Finish(function()
            if not runtime.photoEditor.before then return true end
            local ok,why=runtime.photoEditor.Compare()
            state.note=not ok and ns.Product.Message(why) or nil; ui.Refresh()
        end)
    end,nil,"quiet")
    local remove=W.Button(env,actions,"Delete",244,-47,66,function()
        local name=state.selected
        if not name or not lib.bank[name] then return end
        local ok=lib.delete(name)
        state.note = ok and lib.deletedMessage or "Finish the current camera action first."
        state.watching=nil; ui.Refresh()
    end,nil,"quiet")
    remove.label:ClearAllPoints(); remove.label:SetPoint("CENTER",remove,"CENTER")
    remove.label:SetWidth(64); remove.label:SetJustifyH("CENTER")
    ui.RefreshSavedLibrary=function()
        local names={}
        for name in pairs(lib.bank) do if matches(name,state.query) then names[#names+1]=name end end
        table.sort(names,alphabetical)
        local pages=math.max(1,math.ceil(#names/pageSize))
        if state.reveal then
            for i,name in ipairs(names) do if name==state.selected then state.page=math.ceil(i/pageSize); break end end
            state.reveal=nil
        end
        state.page=math.max(1,math.min(state.page,pages))
        local first=(state.page-1)*pageSize+1
        local selected
        for i,row in ipairs(rows) do
            local name=names[first+i-1]
            if name then
                local data=lib.bank[name]
                if row.presetName~=name or row.presetData~=data then
                    local detail, tip = lib.card(row,data)
                    row.label:SetText(name); row.detail:SetText(detail); row.presetTip=tip or detail
                end
                row.presetName,row.presetData=name,data; row:Show()
                if name==state.selected then selected=name end
            else row.presetName,row.presetData=nil,nil; row:Hide() end
        end
        state.selected=selected or names[first]
        for _,row in ipairs(rows) do row.SetSelected(row.presetName~=nil and row.presetName==state.selected) end
        if #names==0 then
            empty:SetText(state.query~="" and "No matching "..page:lower().."." or "No saved "..page:lower().." yet.")
            empty:Show(); actions:Hide()
            if state.query~="" then clear:Show() else clear:Hide() end
        else empty:Hide(); clear:Hide(); actions:Show() end
        newSave.SetStyle(next(lib.bank) and "secondary" or "primary")
        local visible=math.min(pageSize,#names-first+1)
        local bottom=40+visible*48
        actions:ClearAllPoints(); actions:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-bottom)
        if pages>1 then
            prev:Show(); nextPage:Show(); enable(prev,state.page>1); enable(nextPage,state.page<pages)
            counter:SetText(first.."–"..math.min(first+pageSize-1,#names).." of "..#names)
        else
            prev:Hide(); nextPage:Hide()
            counter:SetText(#names.." "..lib.unit..(#names==1 and "" or "s"))
        end
        if state.query=="" then hint:Show() else hint:Hide() end
        local available=state.selected~=nil
        enable(apply,available and (not lib.worker or not lib.worker.busy) and not runtime.captureSequence.active and not runtime.composition.capturing)
        enable(remove,available and (not lib.worker or not lib.worker.busy))
        local comparing=lib.compareLook and runtime.photoEditor.before
        if comparing then after:Show() else after:Hide() end
        apply:SetWidth(comparing and 151 or 232); apply.label:SetWidth(apply:GetWidth()-16)
        local note=state.note or ""
        if state.watching and lib.progress then note=lib.progress(state.watching) or note end
        return note, #names==0 and 144 or bottom+82
    end
    W.Script(field,"OnTextChanged",function()
        state.query, state.page, state.note, state.watching = field:GetText(),1,nil,nil
        ui.Refresh()
    end)
    return -274
end
