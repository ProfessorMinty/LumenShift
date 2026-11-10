local _, ns = ...
local W = {}
ns.Widgets = W
function W.Script(frame, script, handler)
    if handler and (script == "OnClick" or script == "OnValueChanged" or script == "OnEnterPressed") then
        local action = handler
        handler = function(self, ...)
            local owner = frame
            while owner do
                if owner.lumenInputBlocked then return end
                owner = owner:GetParent()
            end
            return action(self, ...)
        end
    end
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
W.colors = { bg = { 0.075, 0.087, 0.10, 1 }, sidebar = { 0.052, 0.064, 0.074, 1 },
    card = { 0.105, 0.12, 0.135, 1 }, hover = { 0.14, 0.17, 0.18, 1 },
    selected = { 0.09, 0.20, 0.19, 1 }, border = { 0.19, 0.23, 0.25, 1 },
    accent = { 0.22, 0.86, 0.70, 1 }, text = { 0.94, 0.96, 0.96, 1 }, muted = { 0.63, 0.69, 0.72, 1 },
    warning = { 0.94, 0.70, 0.40, 1 } }
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
    if kind == "texture" then
        if item.SetDrawLayer then item:SetDrawLayer(layer) end
        item:SetAlpha(1); item:SetVertexColor(1, 1, 1, 1); item:SetTexCoord(0, 1, 0, 1)
    end
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
        if kind == "Button" and frame.Enable then frame:Enable() end
        frame:Show(); return frame
    end }, { __index = env })
    function pool.Reset()
        pool.indexes = {}
        for _, owner in ipairs(pool.owners) do
            if owner ~= root then
                if owner.lumenNavigation and owner.lumenNavigation.current == owner then owner.lumenNavigation.Clear() end
                if owner.lumenEdit then owner:ClearFocus() end
                owner:Hide(); owner:ClearAllPoints()
                for _, script in ipairs({ "OnClick", "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnValueChanged", "OnEnterPressed", "OnEscapePressed", "OnEditFocusGained", "OnEditFocusLost", "OnTabPressed", "OnTextChanged" }) do
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
    -- Collection labels disable wrapping; pooled labels must not leak that style.
    f:SetWordWrap(true); f:SetNonSpaceWrap(false)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); f:SetWidth(width); f:SetJustifyH("LEFT")
    if f.GetFont then local font = f:GetFont(); if font then f:SetFont(font, size or 13, "") end end
    f:SetTextColor(unpack(color or W.colors.text)); f:SetText(text)
    return f
end
-- One movable top-level window family. Native Raise keeps descendants together;
-- never enumerate, reparent or change another addon's frames.
function W.Window(env, window, headerHeight, rightInset)
    window:SetFrameStrata("FULLSCREEN_DIALOG"); window:SetToplevel(true)
    window:SetClampedToScreen(true); window:SetMovable(true); window:EnableMouse(true)
    local header = env.CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT", window, "TOPLEFT", 14, -8)
    header:SetSize(window:GetWidth() - 14 - rightInset, headerHeight)
    header:EnableMouse(true); header:RegisterForDrag("LeftButton")
    window.lumenDragHandle = header
    local function raise() window:Raise() end
    local function stop() window:StopMovingOrSizing() end
    W.Script(header, "OnMouseDown", raise)
    W.Script(header, "OnDragStart", function() raise(); window:StartMoving() end)
    W.Script(header, "OnDragStop", stop); W.Script(header, "OnMouseUp", stop)
    W.Script(window, "OnMouseDown", raise)
    W.Script(window, "OnShow", raise)
    local previousHide = window:GetScript("OnHide")
    W.Script(window, "OnHide", function(self, ...)
        stop(); if previousHide then previousHide(self, ...) end
    end)
    W.Tip(env, header, "Drag the title bar to move this window.")
    return header
end
function W.Fill(frame, color)
    local texture = W.Texture(frame, "BACKGROUND")
    texture:SetAllPoints(frame); texture:SetColorTexture(unpack(color or W.colors.card))
    return texture
end
function W.Art(parent, name, x, y, width, height, alpha, layer)
    local texture = W.Texture(parent, layer or "ARTWORK")
    texture:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); texture:SetSize(width, height)
    W.Asset(texture, "Interface/AddOns/LumenShift/Media/" .. name .. ".tga")
    texture:SetVertexColor(1, 1, 1, 1); texture:SetAlpha(alpha or 1)
    return texture
end
function W.HighContrast()
    return ns.runtime and ns.runtime.db and ns.runtime.db.config.studio.highContrast == true
end
function W.Decoration(texture)
    if W.HighContrast() then texture:Hide() else texture:Show() end
    return texture
end
function W.ButtonIcon(button, name, size)
    size = size or 18
    button.icon = W.Art(button, name, 10, -(button:GetHeight() - size) / 2, size, size)
    button.label:ClearAllPoints(); button.label:SetPoint("TOPLEFT", button, "TOPLEFT", size + 20, -7)
    button.label:SetWidth(math.max(1, button:GetWidth() - size - 28))
    button.Paint(false); return button
end
function W.Rule(parent, x, y, width, color, thickness)
    local texture = W.Texture(parent, "BORDER")
    texture:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); texture:SetSize(width, thickness or 1)
    texture:SetColorTexture(unpack(color or W.colors.border)); return texture
end
function W.Border(frame, color)
    local edges = {}
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local edge = W.Texture(frame, "BORDER"); edge:SetPoint(side, frame, side, 0, 0)
        edge:SetSize((side == "TOP" or side == "BOTTOM") and frame:GetWidth() or 1,
            (side == "LEFT" or side == "RIGHT") and frame:GetHeight() or 1)
        edge:SetColorTexture(unpack(color or W.colors.border))
        edges[#edges + 1] = edge
    end
    return edges
end
function W.Section(parent, title, x, y, width)
    W.Text(parent, title, x, y, width, 11, W.colors.muted)
    W.Rule(parent, x, y - 24, width)
end
function W.Checkbox(env, parent, title, description, x, y, width, get, set)
    local button = env.CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); button:SetSize(width, 56)
    local box = env.CreateFrame("Frame", nil, button); box:SetSize(34, 18); box:SetPoint("TOPRIGHT", button, "TOPRIGHT", -6, -2)
    local background = W.Art(box, "switch-track", 0, 0, 34, 18, 1, "BACKGROUND")
    local mark = W.Art(box, "switch-knob", 0, 0, 10, 10, 1, "OVERLAY")
    button.label = W.Text(button, title, 0, 0, width - 48, 16)
    W.Text(button, description, 0, -26, width, 12, W.colors.muted)
    local function refresh()
        background:SetVertexColor(unpack(get() and W.colors.accent or W.colors.border))
        mark:ClearAllPoints(); mark:SetPoint("TOPLEFT", box, "TOPLEFT", get() and 20 or 4, -4)
    end
    W.Script(button, "OnClick", function() set(not get()); refresh() end)
    refresh(); if ns.Keyboard then ns.Keyboard.Control(env, button) end; return button
end
function W.Tip(env, frame, text)
    if not env.GameTooltip then return end
    W.Script(frame, "OnEnter", function(self)
        env.GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); env.GameTooltip:SetText(text, 0.92, 0.96, 1, 1, true); env.GameTooltip:Show()
    end)
    W.Script(frame, "OnLeave", function() env.GameTooltip:Hide() end)
end
function W.Button(env, parent, label, x, y, width, callback, tip, style)
    local button = env.CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); button:SetSize(width, 30)
    button.background = W.Fill(button)
    button.label = W.Text(button, label, 10, -7, width - 16, 13)
    button.style, button.selected, button.icon = style or "secondary", false, nil
    button.marker = W.Texture(button, "BORDER"); button.marker:SetPoint("LEFT", button, "LEFT", 0, 0)
    button.marker:SetSize(2, 24); button.marker:SetColorTexture(unpack(W.colors.accent)); button.marker:Hide()
    function button.Paint(hover)
        local selected = button.selected
        local color = button.style == "primary" and (hover and { 0.30, 0.94, 0.79, 1 } or W.colors.accent)
            or selected and W.colors.selected or hover and W.colors.hover
            or (button.style == "quiet" or button.style == "nav") and { 0, 0, 0, 0 } or W.colors.card
        button.background:SetColorTexture(unpack(color))
        button.label:SetTextColor(unpack(button.style == "primary" and W.colors.sidebar or selected and W.colors.accent or W.colors.text))
        if button.icon then button.icon:SetVertexColor(unpack(button.style == "primary" and W.colors.sidebar or selected and W.colors.accent or W.colors.muted)) end
        if selected then button.marker:Show() else button.marker:Hide() end
    end
    function button.SetSelected(value) button.selected = value == true; button.Paint(false) end
    function button.SetStyle(value) button.style = value; button.Paint(false) end
    W.Script(button, "OnClick", callback)
    W.Script(button, "OnEnter", function(self)
        button.Paint(true)
        if tip and env.GameTooltip then env.GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); env.GameTooltip:SetText(tip, 1, 1, 1, 1, true); env.GameTooltip:Show() end
    end)
    W.Script(button, "OnLeave", function(self)
        button.Paint(false)
        if env.GameTooltip then env.GameTooltip:Hide() end
    end)
    button.Paint(false); if ns.Keyboard then ns.Keyboard.Control(env, button) end; return button
end
function W.Toggle(env, parent, label, x, y, width, get, set, tip)
    local button = W.Button(env, parent, label, x, y, width, function() end, tip, "quiet")
    button.label:SetWidth(width - 74)
    local track = env.CreateFrame("Frame", nil, button); track:SetSize(38, 20); track:SetPoint("TOPRIGHT", button, "TOPRIGHT", -8, -5)
    local background = W.Art(track, "switch-track", 0, 0, 38, 20, 1, "BACKGROUND")
    local knob = W.Art(track, "switch-knob", 0, 0, 12, 12, 1, "OVERLAY")
    local function refresh()
        local value = get()
        background:SetVertexColor(unpack(value and W.colors.accent or W.colors.border))
        knob:ClearAllPoints(); knob:SetPoint("TOPLEFT", track, "TOPLEFT", value and 22 or 4, -4)
        button.value = value
    end
    W.Script(button, "OnClick", function() set(not get()); refresh() end)
    refresh()
    return button
end
function W.Card(env, parent, label, description, x, y, width, height, selected, callback, icon)
    local button = W.Button(env, parent, label, x, y, width, callback)
    button:SetHeight(height)
    W.Border(button, selected and { 0.20, 0.46, 0.42, 1 } or W.colors.border)
    if selected and not W.HighContrast() then
        local glow = W.Art(button, "light-sweep", 1, -height + 35, width - 2, 34, 0.45, "BORDER")
        glow:SetTexCoord(0, 1, 0.40, 0.65)
    end
    local inset = icon and 60 or 18
    button.label:ClearAllPoints(); button.label:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -16)
    button.label:SetWidth(width - inset - 16)
    local font = button.label:GetFont(); button.label:SetFont(font, 16, "")
    W.Text(button, description, inset, -40, width - inset - 16, 12, W.colors.muted)
    if icon then
        local texture = W.Texture(button, "ARTWORK"); texture:SetSize(30, 30)
        texture:SetPoint("TOPLEFT", button, "TOPLEFT", 16, -20); W.Asset(texture, icon)
    end
    button.SetSelected(selected); return button
end
function W.Edit(env, parent, value, x, y, width, callback, maxLetters)
    local edit = env.CreateFrame("EditBox", nil, parent)
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); edit:SetSize(width, 28)
    edit:SetAutoFocus(false); edit:SetFontObject("GameFontHighlight"); edit:SetTextInsets(6, 6, 0, 0)
    edit:SetMaxLetters(maxLetters or 64); W.Fill(edit, W.colors.sidebar); local edges = W.Border(edit); edit:SetText(tostring(value))
    local function focus(active)
        for _, edge in ipairs(edges) do edge:SetColorTexture(unpack(active and W.colors.accent or W.colors.border)) end
    end
    W.Script(edit, "OnEditFocusGained", function() focus(true); if edit.lumenNavigation then if edit.lumenNavigation.current ~= edit then edit.lumenNavigation.Clear() end; edit.lumenNavigation.current = edit end end)
    W.Script(edit, "OnEditFocusLost", function() focus(false) end)
    W.Script(edit, "OnEscapePressed", function(self) self:ClearFocus() end)
    W.Script(edit, "OnEnterPressed", function(self) callback(self:GetText()); self:ClearFocus() end)
    if ns.Keyboard then ns.Keyboard.Control(env, edit, true) end
    return edit
end
function W.Slider(env, parent, label, x, y, minimum, maximum, step, get, set, tip, width)
    width = width or 520
    W.Text(parent, label, x, y - 5, width - 85, 13)
    local slider = env.CreateFrame("Slider", nil, parent)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 36); slider:SetSize(width, 15)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(minimum, maximum); slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    W.Rule(slider, 0, -5, width, W.colors.border, 3)
    local progress = W.Rule(slider, 0, -5, 1, W.colors.accent, 3)
    local thumb = W.Texture(slider, "OVERLAY"); thumb:SetSize(8, 15); thumb:SetColorTexture(unpack(W.colors.accent)); slider:SetThumbTexture(thumb)
    local initialized, edit = false
    local function update(value)
        value = math.max(minimum, math.min(maximum, math.floor(value / step + 0.5) * step))
        if not set(value) then value = get() end
        progress:SetWidth(math.max(1, width * (value - minimum) / (maximum - minimum)))
        edit:SetText(string.format(step < 1 and "%.2f" or "%.0f", value))
    end
    edit = W.Edit(env, parent, get(), x + width - 64, y, 64, function(text)
        local number = tonumber(text)
        if not ns.Value.Finite(number) or number < minimum or number > maximum then edit:SetText(tostring(get())); return end
        slider:SetValue(number)
    end)
    W.Script(slider, "OnValueChanged", function(_, value) if initialized then update(value) end end)
    slider:SetValue(get()); initialized = true
    progress:SetWidth(math.max(1, width * (get() - minimum) / (maximum - minimum)))
    slider.edit = edit
    if tip then W.Tip(env, slider, tip) end
    return slider
end
function W.Fade(frame, preferences)
    if frame.lumenFade then frame.lumenFade:Stop() end
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
