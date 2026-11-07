local _, ns = ...
local W = {}
ns.Widgets = W
function W.Script(frame, script, handler)
    local log = ns.runtime and ns.runtime.log
    frame:SetScript(script, handler and log and log.Guard("ui", script, handler) or handler)
end
function W.Asset(texture, path)
    local ok, result = pcall(texture.SetTexture, texture, path)
    local reader = ns.runtime and ns.runtime.reader
    ns.Log.Record(reader, "assets", "texture", (not ok or result == false) and "WARN" or "DEBUG",
        not ok and "TEXTURE_API_ERROR" or result == false and "TEXTURE_REJECTED" or result == true and "TEXTURE_API_ACCEPTED" or "REQUESTED_NO_NATIVE_STATUS")
    return ok and result ~= false
end
W.colors = { bg = { 0.035, 0.055, 0.080, 0.97 }, card = { 0.065, 0.095, 0.13, 1 },
    accent = { 0.38, 0.88, 0.79, 1 }, text = { 0.91, 0.95, 0.98, 1 }, muted = { 0.65, 0.73, 0.80, 1 } }
local function region(parent, kind, layer)
    if not parent.lumenPool then
        return kind == "font" and parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight") or parent:CreateTexture(nil, layer)
    end
    parent.lumenRegions = parent.lumenRegions or { font = {}, texture = {}, fontIndex = 0, textureIndex = 0 }
    local pool = parent.lumenRegions
    pool[kind .. "Index"] = pool[kind .. "Index"] + 1
    local index = pool[kind .. "Index"]
    if not pool[kind][index] then
        pool[kind][index] = kind == "font" and parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight") or parent:CreateTexture(nil, layer)
    end
    local item = pool[kind][index]; item:ClearAllPoints(); item:Show()
    return item
end
function W.Texture(parent, layer) return region(parent, "texture", layer) end
function W.CreatePool(env, root)
    local pool = { frames = {}, indexes = {}, owners = { root } }
    root.lumenPool = pool
    pool.env = setmetatable({ CreateFrame = function(kind, name, parent, template)
        pool.indexes[kind] = (pool.indexes[kind] or 0) + 1
        pool.frames[kind] = pool.frames[kind] or {}
        local index = pool.indexes[kind]
        local frame = pool.frames[kind][index]
        if not frame then
            frame = env.CreateFrame(kind, name, parent, template)
            pool.frames[kind][index] = frame; pool.owners[#pool.owners + 1] = frame
            frame.lumenPool = pool
        else frame:SetParent(parent) end
        if kind == "EditBox" then frame:SetMultiLine(false) end
        frame:Show(); return frame
    end }, { __index = env })
    function pool.Reset()
        pool.indexes = {}
        for _, owner in ipairs(pool.owners) do
            if owner ~= root then
                owner:Hide(); owner:ClearAllPoints()
                for _, script in ipairs({ "OnClick", "OnEnter", "OnLeave", "OnValueChanged", "OnEnterPressed", "OnEscapePressed" }) do
                    -- Native frames reject unsupported script names, so clear only installed scripts.
                    local ok, fn = pcall(owner.GetScript, owner, script)
                    if ok and fn then W.Script(owner, script, nil) end
                end
            end
            if owner.lumenRegions then
                local regions = owner.lumenRegions
                regions.fontIndex, regions.textureIndex = 0, 0
                for _, kind in ipairs({ "font", "texture" }) do for _, item in ipairs(regions[kind]) do item:Hide() end end
            end
        end
    end
    return pool
end
function W.Text(parent, text, x, y, width, size, color)
    local f = region(parent, "font", "OVERLAY")
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); f:SetWidth(width); f:SetJustifyH("LEFT")
    if f.GetFont then local font = f:GetFont(); if font then f:SetFont(font, size or 13, "") end end
    f:SetTextColor(unpack(color or W.colors.text)); f:SetText(text)
    return f
end
function W.Fill(frame, color)
    local texture = W.Texture(frame, "BACKGROUND")
    texture:SetAllPoints(frame); texture:SetColorTexture(unpack(color or W.colors.card))
    return texture
end
function W.Tip(env, frame, text)
    if not env.GameTooltip then return end
    W.Script(frame, "OnEnter", function(self)
        env.GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); env.GameTooltip:SetText(text, 0.92, 0.96, 1, 1, true); env.GameTooltip:Show()
    end)
    W.Script(frame, "OnLeave", function() env.GameTooltip:Hide() end)
end
function W.Button(env, parent, label, x, y, width, callback, tip)
    local button = env.CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); button:SetSize(width, 30)
    button.background = W.Fill(button)
    button.label = W.Text(button, label, 10, -7, width - 16, 13)
    W.Script(button, "OnClick", callback)
    W.Script(button, "OnEnter", function(self)
        self.background:SetColorTexture(0.12, 0.24, 0.28, 1)
        if tip and env.GameTooltip then env.GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); env.GameTooltip:SetText(tip, 1, 1, 1, 1, true); env.GameTooltip:Show() end
    end)
    W.Script(button, "OnLeave", function(self)
        self.background:SetColorTexture(unpack(W.colors.card))
        if env.GameTooltip then env.GameTooltip:Hide() end
    end)
    return button
end
function W.Toggle(env, parent, label, x, y, width, get, set, tip)
    local button
    local function refresh()
        button.label:SetText((get() and "[ON]  " or "[OFF] ") .. label)
        button.label:SetTextColor(unpack(get() and W.colors.accent or W.colors.text))
    end
    button = W.Button(env, parent, label, x, y, width, function() set(not get()); refresh() end, tip)
    refresh()
    return button
end
function W.Edit(env, parent, value, x, y, width, callback)
    local edit = env.CreateFrame("EditBox", nil, parent)
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); edit:SetSize(width, 28)
    edit:SetAutoFocus(false); edit:SetFontObject("GameFontHighlight"); edit:SetTextInsets(6, 6, 0, 0)
    edit:SetMaxLetters(64); W.Fill(edit, { 0.10, 0.14, 0.18, 1 }); edit:SetText(tostring(value))
    W.Script(edit, "OnEscapePressed", function(self) self:ClearFocus() end)
    W.Script(edit, "OnEnterPressed", function(self) callback(self:GetText()); self:ClearFocus() end)
    return edit
end
function W.Slider(env, parent, label, x, y, minimum, maximum, step, get, set, tip)
    W.Text(parent, label, x, y, 260, 13)
    local slider = env.CreateFrame("Slider", nil, parent)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 23); slider:SetSize(430, 15)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(minimum, maximum); slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    W.Fill(slider, { 0.13, 0.20, 0.25, 1 })
    local thumb = W.Texture(slider, "OVERLAY"); thumb:SetSize(10, 21); thumb:SetColorTexture(unpack(W.colors.accent)); slider:SetThumbTexture(thumb)
    local initialized, edit = false
    local function update(value)
        value = math.max(minimum, math.min(maximum, math.floor(value / step + 0.5) * step))
        if not set(value) then value = get() end
        edit:SetText(string.format(step < 1 and "%.2f" or "%.0f", value))
    end
    edit = W.Edit(env, parent, get(), x + 450, y - 14, 70, function(text)
        local number = tonumber(text)
        if not ns.Value.Finite(number) or number < minimum or number > maximum then edit:SetText(tostring(get())); return end
        slider:SetValue(number)
    end)
    W.Script(slider, "OnValueChanged", function(_, value) if initialized then update(value) end end)
    slider:SetValue(get()); initialized = true
    if tip then W.Tip(env, slider, tip) end
    return slider
end
function W.Fade(frame, preferences)
    frame:SetAlpha(1)
    if not preferences.animation or preferences.reducedMotion or type(frame.CreateAnimationGroup) ~= "function" then return end
    if not frame.lumenFade then
        local ok = pcall(function()
            local group = frame:CreateAnimationGroup()
            local alpha = group:CreateAnimation("Alpha")
            alpha:SetFromAlpha(0); alpha:SetToAlpha(1); alpha:SetDuration(0.12)
            frame.lumenFade = group
        end)
        if not ok then return end
    end
    frame.lumenFade:Stop(); frame.lumenFade:Play()
end
return W
