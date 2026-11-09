-- Strictly off-client native-widget model. Records geometry/visibility and dispatches handlers.
-- It cannot establish native rendering, input focus, taint, sound decoding or addon compatibility.
return function(env)
    local mock = { nodes = {}, timers = {}, soundCalls = {}, stops = {} }
    local methods = {}
    local create
    function methods:SetSize(w, h) self.width, self.height = w, h end
    function methods:SetWidth(w) self.width = w end
    function methods:SetHeight(h) self.height = h end
    function methods:GetWidth() return self.width or self.allPoints and self.allPoints:GetWidth() or 0 end
    function methods:GetHeight() return self.height or self.allPoints and self.allPoints:GetHeight() or 0 end
    function methods:GetSize() return self:GetWidth(), self:GetHeight() end
    function methods:Enable() self.disabled = false end
    function methods:Disable() self.disabled = true end
    function methods:IsEnabled() return not self.disabled end
    function methods:SetDrawLayer(layer) self.layer = layer end
    function methods:SetPoint(anchor, relative, relativePoint, x, y)
        if type(relative) ~= "table" then x, y, relativePoint, relative = relative or 0, relativePoint or 0, anchor, self.parent end
        self.points = self.points or {}; self.points[#self.points + 1] = { anchor, relative, relativePoint or anchor, x or 0, y or 0 }
    end
    function methods:GetPoint(index) return unpack(self.points and self.points[index or 1] or {}) end
    function methods:ClearAllPoints() self.points, self.allPoints = {}, nil end
    function methods:SetAllPoints(other) self.allPoints = other or self.parent end
    function methods:SetParent(parent) self.parent = parent end
    function methods:GetParent() return self.parent end
    function methods:SetScale(scale) self.scale = scale end
    function methods:GetEffectiveScale() return (self.scale or 1) * (self.parent and self.parent:GetEffectiveScale() or 1) end
    function methods:GetCenter() return self.centerX or 640, self.centerY or 400 end
    function methods:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
    function methods:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:SetAlpha(alpha) self.alpha = alpha end
    function methods:SetScript(name, fn) self.scripts[name] = fn end
    function methods:HookScript(name, fn)
        local previous = self.scripts[name]
        self.scripts[name] = function(...) if previous then previous(...) end; fn(...) end
    end
    function methods:GetScript(name) return self.scripts[name] end
    function methods:RegisterEvent(name) self.events[name] = true end
    function methods:UnregisterEvent(name) self.events[name] = nil end
    function methods:CreateTexture(_, layer) return create("Texture", nil, self, layer) end
    function methods:CreateFontString(_, layer) return create("FontString", nil, self, layer) end
    function methods:SetColorTexture(r, g, b, a) self.color = { r, g, b, a or 1 }; self.texture = nil end
    function methods:SetVertexColor(r, g, b, a) self.vertexColor = { r, g, b, a or 1 } end
    function methods:SetTextColor(r, g, b, a) self.textColor = { r, g, b, a or 1 } end
    function methods:SetTexture(path) self.texture = path end
    function methods:SetText(value) self.text = tostring(value or ""); if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
    function methods:GetText() return self.text or "" end
    function methods:SetFont(font, size, flags) self.font, self.fontSize, self.fontFlags = font, size, flags end
    function methods:GetFont() return self.font or "GameFont", self.fontSize or 13, "" end
    function methods:SetFontObject(name) self.fontObject = name end
    function methods:SetJustifyH(alignment) self.justify = alignment end
    function methods:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
    function methods:SetValue(value)
        value = math.max(self.minimum or value, math.min(self.maximum or value, value))
        local old = self.value; self.value = value
        if self.thumb and self.maximum > self.minimum then
            -- Offline approximation of native thumb positioning, never runtime UI behavior.
            local fraction = (value - self.minimum) / (self.maximum - self.minimum)
            self.thumb:ClearAllPoints()
            if self.SetOrientationArgs[1] == "HORIZONTAL" then
                self.thumb:SetPoint("CENTER", self, "LEFT", fraction * self:GetWidth(), 0)
            else self.thumb:SetPoint("TOP", self, "TOP", 0, -fraction * (self:GetHeight() - self.thumb:GetHeight())) end
        end
        if old ~= value and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
    end
    function methods:GetValue() return self.value end
    function methods:SetScrollChild(child) self.scrollChild = child end
    function methods:SetVerticalScroll(value) self.scroll = value end
    function methods:GetVerticalScroll() return self.scroll or 0 end
    function methods:SetThumbTexture(texture) self.thumb = texture end
    function methods:ClearFocus() self.focus = false; if mock.focus == self then mock.focus = nil end; if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end end
    function methods:SetFocus() if mock.focus and mock.focus ~= self then mock.focus:ClearFocus() end; mock.focus = self; self.focus = true; if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end end
    function methods:HighlightText(first, last) self.highlight = { first, last } end
    function methods:CreateAnimationGroup()
        local group = { animations = {} }
        function group:Stop() self.playing = false end
        function group:Play() self.playing = true end
        function group:CreateAnimation(kind)
            local anim = { kind = kind }
            function anim:SetFromAlpha(value) self.from = value end
            function anim:SetToAlpha(value) self.to = value end
            function anim:SetDuration(value) self.duration = value end
            self.animations[#self.animations + 1] = anim; return anim
        end
        return group
    end
    for _, method in ipairs({ "SetClampedToScreen", "SetMovable", "EnableMouse", "EnableMouseWheel", "EnableKeyboard",
        "SetPropagateKeyboardInput", "SetFrameStrata", "SetFrameLevel", "SetToplevel", "Raise", "RegisterForDrag", "RegisterForClicks", "StartMoving",
        "StopMovingOrSizing", "SetOrientation", "SetValueStep", "SetObeyStepOnDrag", "SetAutoFocus", "SetTextInsets",
        "SetMaxLetters", "SetMultiLine", "SetTexCoord", "SetBlendMode", "SetOwner", "SetWordWrap", "SetNonSpaceWrap" }) do
        local name = method
        methods[name] = function(self, ...) self[name .. "Args"] = { ... } end
    end
    create = function(kind, name, parent, layer)
        local node = setmetatable({ kind = kind, name = name, parent = parent, layer = layer,
            shown = true, scripts = {}, events = {}, alpha = 1, id = #mock.nodes + 1 }, { __index = methods })
        mock.nodes[#mock.nodes + 1] = node
        if name then env[name] = node end
        return node
    end
    env.CreateFrame = create
    env.UIParent = create("Frame", "UIParent"); env.UIParent:SetSize(1280, 800)
    env.GetCurrentKeyBoardFocus = function() return mock.focus end
    env.IsShiftKeyDown = function() return false end
    env.UISpecialFrames = {}; env.GetCursorPosition = function() return 1250, 790 end
    env.GameTooltip = create("Frame", "GameTooltip"); env.GameTooltip:Hide()
    env.Settings = { RegisterCanvasLayoutCategory = function(frame, name) return { frame = frame, name = name } end,
        RegisterAddOnCategory = function(category) mock.category = category end }
    env.C_Timer = { After = function(delay, callback) mock.timers[#mock.timers + 1] = { delay, callback } end }
    env.PlaySoundFile = function(path, channel)
        mock.soundCalls[#mock.soundCalls + 1] = { path, channel }; return true, #mock.soundCalls
    end
    env.StopSound = function(handle) mock.stops[#mock.stops + 1] = handle end
    function mock.Flush()
        local guard = 0
        while #mock.timers > 0 do
            guard = guard + 1; assert(guard < 20, "unbounded callbacks")
            table.remove(mock.timers, 1)[2]()
        end
    end
    function mock.Click(label)
        for _, node in ipairs(mock.nodes) do
            if node.kind == "Button" and node.label and node.label.text == label and node:IsVisible() then
                if node.disabled then return end
                assert(node.scripts.OnClick, label); return node.scripts.OnClick(node, "LeftButton")
            end
        end
        error("Visible button not found: " .. label)
    end
    function mock.Export(path)
        local file = assert(io.open(path, "w"))
        -- A tab-separated geometry model for optional offline rendering, not a game screenshot.
        local function escape(s) return tostring(s or ""):gsub("\t", " "):gsub("\n", "\\n") end
        for _, n in ipairs(mock.nodes) do
            local point = n.points and n.points[1] or {}
            file:write(table.concat({ n.id, n.kind, n.parent and n.parent.id or 0, n:IsVisible() and 1 or 0,
                n:GetWidth(), n:GetHeight(), escape(point[1]), point[2] and point[2].id or 0,
                escape(point[3]), point[4] or 0, point[5] or 0, escape(n.text), escape(n.texture),
                n.allPoints and n.allPoints.id or 0, n.fontSize or 13, n.justify or "LEFT",
                table.concat(n.color or n.textColor or { 1, 1, 1, 1 }, ","), n.scroll or 0,
                n.alpha or 1, table.concat(n.vertexColor or { 1, 1, 1, 1 }, ","),
                table.concat(n.SetTexCoordArgs or { 0, 1, 0, 1 }, ","), n.layer or "" }, "\t"), "\n")
        end
        file:close()
    end
    return mock
end
