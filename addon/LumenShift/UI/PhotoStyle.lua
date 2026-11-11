local _, ns = ...
local S, W = {}, ns.Widgets
ns.PhotoStyle = S

-- Quiet text tabs and an icon rail keep navigation visually separate from actions.
function S.Tab(env, parent, label, x, y, width, action, icon)
    local b = W.Button(env, parent, label, x, y, width, action, nil, "quiet")
    b:SetHeight(icon and 50 or 28)
    b.label:ClearAllPoints()
    b.label:SetPoint("TOPLEFT", b, "TOPLEFT", 0, icon and -30 or -6)
    b.label:SetWidth(width); b.label:SetJustifyH("CENTER")
    b.label:SetFont(b.label:GetFont(), icon and 10 or 12, "")
    if icon then
        b.icon = W.Art(b, icon, (width - 18) / 2, -7, 18, 18)
    else
        b.marker:ClearAllPoints(); b.marker:SetPoint("BOTTOM", b, "BOTTOM", 0, 0)
        b.marker:SetSize(width - 10, 2)
    end
    function b.Paint(hover)
        local color = b.selected and W.colors.accent or hover and W.colors.text or W.colors.muted
        b.label:SetTextColor(unpack(color))
        if b.icon then b.icon:SetVertexColor(unpack(color)) end
        b.background:SetColorTexture(.12, .24, .23, hover and .65 or icon and b.selected and .5 or 0)
        if b.selected then b.marker:Show() else b.marker:Hide() end
    end
    b.Paint(false)
    return b
end

function S.Enable(b,on)
    if on then b:Enable(); b:SetAlpha(1) else b:Disable(); b:SetAlpha(.48) end
end

function S.Pager(env,parent,y,turn)
    local previous=W.Button(env,parent,"Previous",0,y,84,function() turn(-1) end,nil,"quiet")
    local nextPage=W.Button(env,parent,"Next",226,y,84,function() turn(1) end,nil,"quiet")
    local count=W.Text(parent,"",85,y-7,140,12,W.colors.muted); count:SetJustifyH("CENTER")
    return function(page,size,n)
        local first=(page-1)*size+1
        count:SetText(n==0 and "0 results" or first.."–"..math.min(page*size,n).." of "..n)
        S.Enable(previous,page>1); S.Enable(nextPage,page*size<n)
    end
end

function S.Pages(env, row, labels, selectPage)
    local tabs = {}
    local width = 310 / #labels
    for i, label in ipairs(labels) do
        local page = label
        tabs[page] = S.Tab(env, row, page, (i-1)*width, 0, width, function() selectPage(page) end)
    end
    return tabs
end

local recipes = {
    { "neutral", "Neutral" }, { "ember", "Warm Ember" }, { "night", "Cool Night" },
    { "portrait", "Soft Portrait" }, { "sunflare", "Sun Flare" }, { "bluehour", "Blue Hour" },
}
local spectra = {
    warmth = {{.28,.64,.95},{1,.62,.24}},
    tint = {{.32,.80,.54},{.89,.44,.72}},
}
for _, recipe in ipairs(recipes) do recipe.look = ns.PhotoConfig.Recipe(recipe[1]) end

local function matches(look, recipe)
    for key, value in pairs(recipe) do
        if key ~= "strength" and look[key] ~= value then return false end
    end
    return true
end

function S.IdentifyLook(look)
    for _, recipe in ipairs(recipes) do
        if matches(look, recipe.look) then return recipe[1], recipe[2] end
    end
    return nil, "Custom"
end

function S.Swatch(env,parent,label,x,y,width,pictureHeight,asset,apply,tip)
    local b=W.Button(env,parent,label,x,y,width,apply,tip,"quiet")
    b:SetHeight(pictureHeight+20)
    W.Art(b,asset,0,0,width,pictureHeight)
    b.label:ClearAllPoints(); b.label:SetPoint("TOPLEFT",b,"TOPLEFT",2,-pictureHeight-3)
    b.label:SetWidth(width-4); b.label:SetFont(b.label:GetFont(),12,"")
    b.marker:ClearAllPoints(); b.marker:SetPoint("TOPLEFT",b,"TOPLEFT",0,2-pictureHeight)
    b.marker:SetDrawLayer("OVERLAY"); b.marker:SetSize(width,2)
    return b
end

local function gallery(runtime, env, parent, ui)
    local buttons = {}
    local pictureHeight = ui.compactLooks and 32 or 43
    local stride = pictureHeight + 25
    W.Text(parent, "FILTERS", 0, -1, 110, 11, W.colors.muted)
    local selection = W.Text(parent, "", 116, -1, 194, 12, W.colors.accent)
    selection:SetJustifyH("RIGHT")
    for i, recipe in ipairs(recipes) do
        local id, name = recipe[1], recipe[2]
        local b=S.Swatch(env,parent,name,((i-1)%3)*105,-23-math.floor((i-1)/3)*stride,100,pictureHeight,
            "look-"..id,function() runtime.photoEditor.Recipe(id);ui.Build() end,"Apply "..name)
        buttons[i] = b
    end
    ui.RefreshGallery = function()
        local id, current = S.IdentifyLook(runtime.db.camera.editor.look)
        for i, recipe in ipairs(recipes) do buttons[i].SetSelected(recipe[1] == id) end
        selection:SetText(current)
    end
    ui.RefreshGallery()
    return -24 - 2*stride
end

function S.Look(runtime, env, parent, ui)
    local editor, y = runtime.photoEditor, 0
    local function placement(xKey, yKey)
        local function apply(values)
            editor.SetMany(values)
            ui.Refresh()
        end
        local pad = W.Button(env, parent, "Place effect center", 0, y, 136, function(b)
            local cursor = ns.ReadOnly.Call(runtime.reader, env.GetCursorPosition)
            local left, top, scale = b:GetLeft(), b:GetTop(), b:GetEffectiveScale()
            if not cursor or cursor.n ~= 2 or not ns.Value.Finite(cursor[1]) or not ns.Value.Finite(cursor[2])
                or not left or not top or not scale or scale <= 0 then return end
            local function percent(n) return math.max(0, math.min(1, math.floor(n*100+.5)/100)) end
            apply({[xKey]=percent((cursor[1]/scale-left)/b:GetWidth()),
                [yKey]=percent((top-cursor[2]/scale)/b:GetHeight())})
        end, "Click the image to place the center of the effect.", "quiet")
        pad:SetHeight(64); pad.label:Hide()
        W.Art(pad,"look-neutral",0,0,136,64)
        local cross = {}
        for i,d in ipairs({{13,3},{3,13},{11,1},{1,11}}) do
            local t=W.Texture(pad,"OVERLAY"); t:SetSize(d[1],d[2])
            local v=i<=2 and .12 or 1
            t:SetColorTexture(v,v,v,1); cross[i]=t
        end
        local fields, editing = {}, nil
        for i,item in ipairs({{xKey,"Center X"},{yKey,"Center Y"}}) do
            local key=item[1]; local at=y-(i-1)*34
            W.Text(parent,item[2],148,at-5,70,12)
            fields[key]=W.Edit(env,parent,"",226,at,53,function(value)
                local n=tonumber(value)
                if ns.Value.Finite(n) and n>=0 and n<=100 then apply({[key]=n/100})
                else ui.RefreshPlacement() end
            end)
            W.Text(parent,"%",284,at-6,20,11,W.colors.muted)
        end
        ui.RefreshPlacement=function()
            local look=runtime.db.camera.editor.look
            for _,t in ipairs(cross) do
                t:ClearAllPoints(); t:SetPoint("CENTER",pad,"TOPLEFT",look[xKey]*136,-look[yKey]*64)
            end
            for key,field in pairs(fields) do
                if field ~= editing then field:SetText(string.format("%.0f",look[key]*100)) end
            end
        end
        for key,field in pairs(fields) do
            local gained=field:GetScript("OnEditFocusGained")
            W.Script(field,"OnEditFocusGained",function(f)
                editing=f
                if gained then gained(f) end
            end)
            local previous=field:GetScript("OnEditFocusLost")
            W.Script(field,"OnEditFocusLost",function(f)
                if editing==f then editing=nil end
                if previous then previous(f) end
                f:SetText(string.format("%.0f",runtime.db.camera.editor.look[key]*100))
            end)
        end
        ui.RefreshPlacement()
        W.Text(parent,"Click to place",0,y-68,136,11,W.colors.muted)
        y=y-86
    end
    local function section(title)
        W.Text(parent, title, 0, y - 1, 310, 11, W.colors.muted)
        y = y - 24
    end
    local function slider(key, label, step)
        local range = ns.PhotoConfig.Ranges[key]
        local factor = key == "grainScale" and 1 or 100
        local s = W.Slider(env, parent, label, 0, y, range[1]*factor, range[2]*factor, step or 1,
            function() return runtime.db.camera.editor.look[key]*factor end,
            function(amount)
                local ok = editor.Set(key, amount/factor)
                ui.Refresh()
                return ok
            end, nil, 310, factor == 1 and "x" or "%", spectra[key])
        ui.sliders[key] = s
        W.Script(s, "OnMouseDown", editor.BeginLookEdit)
        W.Script(s, "OnMouseUp", function() editor.EndLookEdit(); ui.Refresh() end)
        y = y - (ui.compactLooks and 32 or 37)
    end
    if ui.lookPage == "Color" then
        y = gallery(runtime, env, parent, ui)
        section("COLOR MIX")
        slider("strength", "Intensity"); slider("warmth", "Cool / warm"); slider("tint", "Green / rose")
    elseif ui.lookPage == "Vignette" then
        section("EDGE SHADING")
        slider("vignette", "Darkness"); slider("size", "Clear center"); slider("feather", "Softness")
        y = y - 8; section("CENTER")
        placement("centerX","centerY")
    elseif ui.lookPage == "Glow" then
        for i, page in ipairs({"Shape", "Color mix"}) do
            local choice = page
            local b = S.Tab(env, parent, page, (i-1)*84, y, 82, function() ui.glowPage=choice; ui.Build(true) end)
            b.SetSelected(ui.glowPage == choice)
        end
        y = y - 44
        if ui.glowPage == "Shape" then
            slider("glow", "Amount"); slider("glowSize", "Radius"); slider("glowSoftness", "Softness")
            section("POSITION")
            placement("glowX","glowY")
        else
            for i, color in ipairs({{"Amber",1,.58,.2},{"Ice",.3,.65,1},{"White",1,1,1}}) do
                local c=color
                local b=W.Button(env,parent,c[1],(i-1)*104,y,100,function()
                    editor.SetMany({glowR=c[2],glowG=c[3],glowB=c[4]});ui.Build()
                end,nil,"quiet")
                local look = runtime.db.camera.editor.look
                b.SetSelected(look.glowR==c[2] and look.glowG==c[3] and look.glowB==c[4])
                W.Rule(b,4,-25,82,{c[2],c[3],c[4],1},3)
            end
            y=y-48
            slider("glowR","Red"); slider("glowG","Green"); slider("glowB","Blue")
        end
    else
        section("LIGHT LEAK")
        slider("leak", "Amount"); slider("leakSide", "Position"); slider("leakWidth", "Width")
        y=y-8; section("FILM GRAIN")
        slider("grain", "Grain", .5); slider("grainScale", "Grain size", .1)
    end
    return y
end
