local _, ns = ...
local L, W = {}, ns.Widgets
ns.WorldSavedUI = L

local pageSize = 3
local aspectNames = {none="No aspect guide", wide="16:9", cinema="2.39:1", square="Square"}
local ratios = {wide=16/9, cinema=2.39, square=1}

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

local function lookCard(look)
    local id, name = ns.PhotoStyle.IdentifyLook(look)
    local strength = math.floor(look.strength*100+.5).."% strength"
    if id then return "look-"..id, name.." · "..strength end
    local details = {}
    if look.warmth ~= 0 then details[#details+1] = look.warmth > 0 and "Warm" or "Cool" end
    for _, effect in ipairs({{"vignette","Vignette"},{"glow","Glow"},{"grain","Grain"},{"leak","Light leak"}}) do
        if look[effect[1]] > 0 and #details < 2 then details[#details+1] = effect[2] end
    end
    if #details == 0 then details[1] = "Custom" end
    details[#details+1] = strength
    return "ui-effects", table.concat(details, " · ")
end

local function compositionCard(preset)
    local details = {aspectNames[preset.aspect]}
    if preset.thirds then details[#details+1] = "Thirds" end
    if preset.framing.cameraFov then details[#details+1] = string.format("%g° FOV", preset.framing.cameraFov)
    elseif preset.zoom then details[#details+1] = string.format("Zoom %g", preset.zoom) end
    return "look-neutral", table.concat(details, " · ")
end

-- Draw the saved guide over a reference landscape. No world image is captured.
local function guides(row, preset)
    local index = 0
    local function line(x, y, width, height)
        index = index + 1
        local t = row.guides[index]
        t:ClearAllPoints(); t:SetPoint("TOPLEFT", row.picture, "TOPLEFT", x, -y)
        t:SetSize(width,height); t:SetColorTexture(1,1,1,.88); t:Show()
    end
    local width, height = 60, 34
    local ratio = ratios[preset.aspect]
    if ratio then
        local w,h = math.min(width,height*ratio), math.min(height,width/ratio)
        local left, top = (width-w)/2, (height-h)/2
        line(left,top,w,1); line(left,top+h-1,w,1)
        line(left,top,1,h); line(left+w-1,top,1,h)
    end
    if preset.thirds then
        for i=1,2 do line(width*i/3,0,1,height); line(0,height*i/3,width,1) end
    end
    for i=index+1,#row.guides do row.guides[i]:Hide() end
end

local function nameForm(lib, env, parent, ui, state)
    local field, commit
    local function save()
        local name = field:GetText()
        if not ns.PhotoConfig.Name(name) then return end
        local ok, why = lib.controller.Save(name)
        if not ok then
            state.note = ns.Product.Message(why) or (lib.looks and lib.controller.status or "Could not save this composition.")
            ui.Refresh(); return
        end
        if not matches(name, state.query) then state.query="" end
        state.selected, state.reveal = name, true
        state.naming, state.draft, state.note = false, nil, lib.savedMessage
        ui.Build(true)
    end
    W.Text(parent, "Save current "..lib.unit, 0, 0, 310, 17)
    W.Text(parent, lib.looks and "Color, vignette, glow, grain and letterbox." or "Guides, zoom and available camera framing.",
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
    ui.RefreshWorldSaved = function()
        local name = field:GetText()
        local exists = lib.bank[name] ~= nil
        local count = #ns.Value.Keys(lib.bank)
        local full = count >= lib.limit
        local valid = ns.PhotoConfig.Name(name)
        commit.label:SetText((exists and "Replace " or "Save ")..lib.unit)
        enable(commit, valid and (exists or not full) and (lib.looks or not lib.controller.busy))
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

function L.Build(runtime, env, parent, ui)
    local looks = ui.savedPage == "Looks"
    local lib = {
        looks=looks, unit=looks and "look" or "composition",
        controller=looks and runtime.photoEditor or runtime.photoComposition,
        bank=looks and runtime.db.camera.editor.saved or runtime.db.camera.composition.saved,
        limit=looks and ns.PhotoConfig.MaxLooks or ns.PhotoComposition.MaxPresets,
        savedMessage=looks and "Look saved." or "Composition saved.",
    }
    local state = ui.savedLibraries[ui.savedPage]
    if state.naming then return nameForm(lib,env,parent,ui,state) end
    local field = W.Edit(env,parent,state.query,0,0,182,function() end,32)
    local hint = W.Text(field,"Find "..ui.savedPage:lower(),7,-6,169,12,W.colors.muted)
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
        row.guides={}
        if not looks then for j=1,8 do row.guides[j]=W.Texture(row,"OVERLAY") end end
        local enter=row:GetScript("OnEnter")
        W.Script(row,"OnEnter",function(b)
            enter(b)
            if b.presetName and env.GameTooltip then
                env.GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
                env.GameTooltip:SetText(b.presetName.."\n"..b.detail:GetText()); env.GameTooltip:Show()
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
        if looks then
            local ok=lib.controller.Load(name)
            state.note=ok and (runtime.photoEditor.before and "Look applied. Choose Show After to view it." or "Look applied.")
                or "Finish the current capture before applying a look."
        else
            state.note=nil
            local ok,why=lib.controller.Apply(name)
            state.watching=ok and lib.controller.generation or nil
            if not ok then state.note=ns.Product.Message(why) or "Could not apply this composition." end
        end
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
        local ok=lib.controller.Delete(name)
        state.note = ok and (looks and "Look deleted." or "Composition deleted.") or "Finish the current camera action first."
        state.watching=nil; ui.Refresh()
    end,nil,"quiet")
    remove.label:ClearAllPoints(); remove.label:SetPoint("CENTER",remove,"CENTER")
    remove.label:SetWidth(64); remove.label:SetJustifyH("CENTER")
    ui.RefreshWorldSaved=function()
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
                    local art, detail
                    if looks then art,detail=lookCard(data) else art,detail=compositionCard(data) end
                    row.label:SetText(name); row.detail:SetText(detail)
                    W.Asset(row.picture,"Interface/AddOns/LumenShift/Media/"..art..".tga")
                    row.picture:ClearAllPoints(); row.picture:SetPoint("CENTER",row,"LEFT",38,0)
                    if art=="ui-effects" then row.picture:SetSize(26,26) else row.picture:SetSize(60,34) end
                    if not looks then guides(row,data) end
                end
                row.presetName,row.presetData=name,data; row:Show()
                if name==state.selected then selected=name end
            else row.presetName,row.presetData=nil,nil; row:Hide() end
        end
        state.selected=selected or names[first]
        for _,row in ipairs(rows) do row.SetSelected(row.presetName~=nil and row.presetName==state.selected) end
        if #names==0 then
            empty:SetText(state.query~="" and "No matching "..ui.savedPage:lower().."." or "No saved "..ui.savedPage:lower().." yet.")
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
        enable(apply,available and (looks or not lib.controller.busy) and not runtime.captureSequence.active and not runtime.composition.capturing)
        enable(remove,available and (looks or not lib.controller.busy))
        local comparing=looks and runtime.photoEditor.before
        if comparing then after:Show() else after:Hide() end
        apply:SetWidth(comparing and 151 or 232); apply.label:SetWidth(apply:GetWidth()-16)
        local note=state.note or ""
        if not looks and state.watching==lib.controller.generation then note=ns.Product.Message(lib.controller.status) end
        return note, #names==0 and 144 or bottom+82
    end
    W.Script(field,"OnTextChanged",function()
        state.query, state.page, state.note, state.watching = field:GetText(),1,nil,nil
        ui.Refresh()
    end)
    return -274
end
