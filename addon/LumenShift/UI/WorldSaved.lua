local _, ns = ...
local L, W = {}, ns.Widgets
ns.WorldSavedUI = L

local aspectNames = {none="No aspect guide", wide="16:9", cinema="2.39:1", square="Square"}
local ratios = {wide=16/9, cinema=2.39, square=1}

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

function L.Build(runtime, env, parent, ui)
    local looks = ui.savedPage == "Looks"
    local controller = looks and runtime.photoEditor or runtime.photoComposition
    local lib = {
        unit = looks and "look" or "composition",
        description = looks and "Color, vignette, glow, grain and letterbox." or "Guides, zoom and available camera framing.",
        bank = looks and runtime.db.camera.editor.saved or runtime.db.camera.composition.saved,
        limit = looks and ns.PhotoConfig.MaxLooks or ns.PhotoComposition.MaxPresets,
        validName = ns.PhotoConfig.Name,
        save = controller.Save, delete = controller.Delete,
        savedMessage = looks and "Look saved." or "Composition saved.",
        deletedMessage = looks and "Look deleted." or "Composition deleted.",
    }
    if looks then
        lib.compareLook = true
        function lib.card(row, data)
            local art, detail = lookCard(data)
            W.Asset(row.picture,"Interface/AddOns/LumenShift/Media/"..art..".tga")
            if art=="ui-effects" then row.picture:SetSize(26,26) else row.picture:SetSize(60,34) end
            return detail
        end
        function lib.apply(name)
            if not controller.Load(name) then return "Finish the current capture before applying a look." end
            return controller.before and "Look applied. Choose Show After to view it." or "Look applied."
        end
    else
        lib.worker = controller
        function lib.initCard(row)
            row.guides={}
            for i=1,8 do row.guides[i]=W.Texture(row,"OVERLAY") end
        end
        function lib.card(row, data)
            local art, detail = compositionCard(data)
            W.Asset(row.picture,"Interface/AddOns/LumenShift/Media/"..art..".tga")
            guides(row,data)
            return detail
        end
        function lib.apply(name)
            local ok,why=controller.Apply(name)
            if not ok then return ns.Product.Message(why) or "Could not apply this composition." end
            return nil,controller.generation
        end
        function lib.progress(generation)
            if generation==controller.generation then return ns.Product.Message(controller.status) end
        end
    end
    return ns.SavedLibraryUI.Build(runtime,env,parent,ui,ui.savedPage,lib)
end
