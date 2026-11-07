local _, ns = ...
local R, W = {}, ns.Widgets
ns.Radial = R
function R.Clamp(x, y, width, height, radius)
    return math.max(radius, math.min(width - radius, x)), math.max(radius, math.min(height - radius, y))
end
function R.Hit(x, y)
    if not ns.Value.Finite(x) or not ns.Value.Finite(y) then return nil end
    local radius = math.sqrt(x * x + y * y)
    if radius < 88 or radius > 171 then return nil end
    local clockwise = (90 - math.deg(math.atan2(y, x))) % 360
    local segment = math.floor((clockwise + 30) / 60) % 6
    local offset = ((clockwise - segment * 60 + 180) % 360) - 180
    if math.abs(offset) > 28 then return nil end -- match the visible gaps
    return segment + 1
end
function R.New(runtime, openStudio)
    local env, db, product = runtime.reader.env, runtime.db, runtime.product
    local self = { selection = 1 }
    if not db or not env.UIParent then return self end
    local frame = env.CreateFrame("Frame", "LumenShiftWheel", env.UIParent)
    self.frame = frame
    frame:SetSize(352, 352); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true)
    frame:EnableMouse(true); frame:Hide()
    W.Art(frame, "wheel-base", 0, 0, 352, 352, 1, "BACKGROUND")
    self.sector = W.Art(frame, "wheel-sector-1", 0, 0, 352, 352, 1, "BORDER")
    self.halo = W.Art(frame, "light-halo", 84, -84, 184, 184, 0.65, "BORDER")
    W.Art(frame, "logo", 153, -110, 46, 46)
    local title = W.Text(frame, "LUMENSHIFT", 111, -161, 130, 12, W.colors.accent); title:SetJustifyH("CENTER")
    local help = W.Text(frame, "1–6 / Enter\nEsc to cancel", 112, -182, 128, 10, W.colors.muted); help:SetJustifyH("CENTER")
    self.buttons = {}
    local function highlight()
        if self.drawnSelection ~= self.selection then
            W.Asset(self.sector, "Interface/AddOns/LumenShift/Media/wheel-sector-" .. self.selection .. ".tga")
            self.drawnSelection = self.selection
        end
        W.Decoration(self.halo)
        for i, button in ipairs(self.buttons) do
            local id = ns.StudioConfig.Order[i]
            button.background:SetColorTexture(0, 0, 0, 0)
            button.label:SetTextColor(unpack(i == self.selection and W.colors.accent or W.colors.text))
            local active = product.active == id and (id ~= "natural" or not db.baseline.chosen or product.baselineVerified)
            button.label:SetText((active and "* " or "") .. i .. " " .. ns.StudioConfig.Label(id))
        end
    end
    function self.Close()
        if frame.lumenFade then frame.lumenFade:Stop() end
        frame:Hide()
        ns.Log.Record(runtime.reader, "radial", "close", "DEBUG", "PASS")
    end
    local function selectMode(i)
        self.Close(); product.Select(ns.StudioConfig.Order[i])
    end
    for i, id in ipairs(ns.StudioConfig.Order) do
        local index, modeID = i, id
        local angle = (90 - (i - 1) * 60) * math.pi / 180
        local button = W.Button(env, frame, i .. " " .. ns.StudioConfig.Label(id),
            120 + math.cos(angle) * 112, -151 + math.sin(angle) * 112, 112,
            function() selectMode(index) end, ns.StudioConfig.Descriptions[id])
        button:SetHeight(61); button.label:ClearAllPoints(); button.label:SetPoint("BOTTOM", button, "BOTTOM", 0, 5)
        button.label:SetWidth(108); button.label:SetJustifyH("CENTER")
        local icon = button:CreateTexture(nil, "ARTWORK"); icon:SetSize(30, 30); icon:SetPoint("TOP", button, "TOP", 0, -4)
        ns.Widgets.Asset(icon, "Interface/AddOns/LumenShift/Media/" .. modeID .. ".tga")
        ns.Widgets.Script(button, "OnEnter", function() self.selection = index; highlight() end)
        ns.Widgets.Script(button, "OnLeave", function() highlight() end)
        self.buttons[i] = button
    end
    W.ButtonIcon(W.Button(env, frame, "Studio", 126, -211, 100, function() self.Close(); openStudio() end, nil, "quiet"), "ui-settings", 14)
    ns.Widgets.Script(frame, "OnMouseDown", function(_, button)
        if button == "RightButton" then self.Close(); return end
        if button ~= "LeftButton" then return end
        local position = ns.ReadOnly.Call(runtime.reader, env.GetCursorPosition)
        local scale, cx, cy = frame:GetEffectiveScale(), frame:GetCenter()
        if not position or position.n ~= 2 or not ns.Value.Finite(position[1]) or not ns.Value.Finite(position[2])
            or not ns.Value.Finite(scale) or scale <= 0 or not ns.Value.Finite(cx) or not ns.Value.Finite(cy) then return end
        local selected = R.Hit(position[1] / scale - cx, position[2] / scale - cy)
        if selected then selectMode(selected) end
    end)
    ns.Widgets.Script(frame, "OnKeyDown", function(_, key)
        if key == "ESCAPE" then self.Close()
        elseif key == "ENTER" or key == "SPACE" then selectMode(self.selection)
        elseif tonumber(key) and tonumber(key) >= 1 and tonumber(key) <= 6 then selectMode(tonumber(key))
        elseif key == "RIGHT" or key == "DOWN" or key == "TAB" then self.selection = self.selection % 6 + 1; highlight()
        elseif key == "LEFT" or key == "UP" then self.selection = (self.selection + 4) % 6 + 1; highlight() end
    end)
    function self.Toggle()
        if frame:IsShown() then self.Close(); return end
        if product.IsCombat() then ns.Diagnostics.Emit(runtime, "LumenShift: wheel unavailable during combat; nothing queued."); return end
        if type(frame.SetPropagateKeyboardInput) ~= "function" then
            ns.Diagnostics.Emit(runtime, "LumenShift: wheel keyboard API unavailable; opening Studio."); openStudio(); return
        end
        local scale = env.UIParent:GetEffectiveScale()
        local position = ns.ReadOnly.Call(runtime.reader, env.GetCursorPosition)
        if not position or position.n ~= 2 or not ns.Value.Finite(position[1]) or not ns.Value.Finite(position[2]) then
            ns.Diagnostics.Emit(runtime, "LumenShift: cursor coordinates unavailable; opening Studio."); openStudio(); return
        end
        local x, y = position[1], position[2]
        x, y = R.Clamp(x / scale, y / scale, env.UIParent:GetWidth(), env.UIParent:GetHeight(), 180)
        frame:ClearAllPoints(); frame:SetPoint("CENTER", env.UIParent, "BOTTOMLEFT", x, y)
        local ok = pcall(function() frame:EnableKeyboard(true); frame:SetPropagateKeyboardInput(false) end)
        if not ok then self.Close(); ns.Diagnostics.Emit(runtime, "LumenShift: keyboard capture restricted; opening Studio."); openStudio(); return end
        highlight(); frame:Show(); W.Fade(frame, db.config.preferences)
        ns.Log.Record(runtime.reader, "radial", "open", "INFO", "PASS_INPUT_NOT_CERTIFIED")
    end
    if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftWheel") end
    local launcher = env.CreateFrame("Button", "LumenShiftLauncher", env.UIParent)
    self.launcher = launcher
    launcher:SetSize(146, 46); launcher:SetFrameStrata("MEDIUM"); launcher:SetClampedToScreen(true)
    launcher:SetMovable(true); launcher:EnableMouse(true); launcher:RegisterForDrag("LeftButton")
    launcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    W.Fill(launcher, { 0.055, 0.075, 0.09, 0.94 }); W.Border(launcher)
    local icon = launcher:CreateTexture(nil, "ARTWORK"); icon:SetSize(46, 46); icon:SetPoint("LEFT", launcher, "LEFT", 0, 0)
    ns.Widgets.Asset(icon, "Interface/AddOns/LumenShift/Media/logo.tga")
    W.Text(launcher, "LumenShift", 49, -8, 95, 13, W.colors.accent)
    W.Text(launcher, "Modes / Studio", 49, -26, 95, 10, W.colors.muted)
    ns.Widgets.Script(launcher, "OnDragStart", function(self)
        if not product.IsCombat() then self.lumenDragged = true; self:StartMoving() end
    end)
    ns.Widgets.Script(launcher, "OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        db.config.studio.launcher.x = x - env.UIParent:GetWidth() / 2
        db.config.studio.launcher.y = y - env.UIParent:GetHeight() / 2
    end)
    ns.Widgets.Script(launcher, "OnClick", function(buttonFrame, button)
        if buttonFrame.lumenDragged then buttonFrame.lumenDragged = nil; return end
        if runtime.entry and runtime.entry.Open then runtime.entry.Open(button)
        elseif button == "RightButton" then openStudio() else self.Toggle() end
    end)
    W.Tip(env, launcher, "LumenShift\nClick: visual modes\nRight-click: Studio\nDrag: move launcher")
    function self.Refresh()
        launcher:ClearAllPoints(); launcher:SetPoint("CENTER", env.UIParent, "CENTER", db.config.studio.launcher.x, db.config.studio.launcher.y)
        if db.config.studio.launcher.visible then launcher:Show() else launcher:Hide() end
        highlight()
    end
    self.Refresh()
    ns.Log.Record(runtime.reader, "radial", "initialize", "INFO", "PASS")
    return self
end
