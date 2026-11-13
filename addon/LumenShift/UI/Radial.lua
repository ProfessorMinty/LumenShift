local _, ns = ...
local R, W = {}, ns.Widgets
ns.Radial = R
function R.Clamp(x, y, width, height, radius, verticalRadius)
    verticalRadius = verticalRadius or radius
    return math.max(radius, math.min(width - radius, x)), math.max(verticalRadius, math.min(height - verticalRadius, y))
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
    frame:SetSize(420, 468); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetToplevel(true); frame:SetClampedToScreen(true)
    frame:EnableMouse(true); frame:Hide()
    local surface = env.CreateFrame("Frame", nil, frame); self.surface = surface
    surface:SetSize(420, 420); surface:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    W.Art(surface, "wheel-base", 0, 0, 420, 420, 1, "BACKGROUND")
    self.sector = W.Art(surface, "wheel-sector-1", 0, 0, 420, 420, 1, "BORDER")
    self.halo = W.Art(surface, "light-halo", 114, -114, 192, 192, 0.35, "BORDER")
    W.Art(surface, "logo", 192, -126, 36, 36)
    local title = W.Text(surface, "LUMENSHIFT", 144, -174, 132, 11, W.colors.accent); title:SetJustifyH("CENTER")
    local footer = env.CreateFrame("Frame", nil, frame); self.footer = footer
    footer:SetSize(420, 34); footer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -434)
    W.Fill(footer, W.colors.sidebar); W.Border(footer)
    local help = W.Text(footer, "1–6 Modes   ·   7 Camera   ·   8 Studio   ·   Esc Close", 10, -10, 400, 11, W.colors.muted)
    help:SetJustifyH("CENTER"); help:SetWordWrap(false); help:SetNonSpaceWrap(false)
    self.buttons = {}
    local function highlight()
        if self.selection <= 6 and self.drawnSelection ~= self.selection then
            W.Asset(self.sector, "Interface/AddOns/LumenShift/Media/wheel-sector-" .. self.selection .. ".tga")
            self.drawnSelection = self.selection
        end
        if self.selection <= 6 then self.sector:Show() else self.sector:Hide() end
        W.Decoration(self.halo)
        for i, button in ipairs(self.buttons) do
            local id = ns.StudioConfig.Order[i]
            button.background:SetColorTexture(0, 0, 0, 0)
            button.label:SetTextColor(unpack(i == self.selection and W.colors.accent or W.colors.text))
            local active = product.state == "ACTIVE" and product.active == id and (id ~= "natural" or not db.baseline.chosen or product.baselineVerified)
            button.label:SetText(ns.StudioConfig.Label(id))
            if active then button.activeMark:Show() else button.activeMark:Hide() end
        end
        if self.camera then
            self.camera.label:SetText(runtime.camera.active and "Exit Camera" or "Camera")
            self.camera.SetSelected(self.selection == 7)
            self.studio.SetSelected(self.selection == 8)
        end
    end
    function self.Close()
        if frame.lumenFade then frame.lumenFade:Stop() end
        if env.GameTooltip then env.GameTooltip:Hide() end
        frame:Hide()
        ns.Log.Record(runtime.reader, "radial", "close", "DEBUG", "PASS")
    end
    local function selectMode(i)
        self.Close()
        if i == 7 then return runtime.camera.Toggle()
        elseif i == 8 then return openStudio() end
        return product.Select(ns.StudioConfig.Order[i])
    end
    -- Layout is explicit: side labels clear the central controls, and lower
    -- labels stay inside the outer arc. Shortcuts have their own small badges.
    local positions = { {146, 22}, {292, 104}, {280, 238}, {146, 320}, {12, 238}, {0, 104} }
    for i, id in ipairs(ns.StudioConfig.Order) do
        local index, modeID = i, id
        local button = W.Button(env, surface, ns.StudioConfig.Label(id),
            positions[i][1], -positions[i][2], 128,
            function() selectMode(index) end, ns.StudioConfig.Descriptions[id])
        button:SetHeight(70); button.label:ClearAllPoints(); button.label:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -45)
        button.label:SetWidth(128); button.label:SetJustifyH("CENTER")
        local font = button.label:GetFont(); button.label:SetFont(font, 13, "")
        button.label:SetWordWrap(false); button.label:SetNonSpaceWrap(false)
        local icon = button:CreateTexture(nil, "ARTWORK"); icon:SetSize(28, 28); icon:SetPoint("TOP", button, "TOP", 0, -12)
        button.shortcut = W.Text(button, tostring(i), 87, -12, 16, 10, W.colors.muted)
        button.activeMark = button:CreateTexture(nil, "ARTWORK"); button.activeMark:SetSize(22, 2)
        button.activeMark:SetPoint("BOTTOM", button, "BOTTOM", 0, 3); button.activeMark:SetColorTexture(unpack(W.colors.accent))
        ns.Widgets.Asset(icon, "Interface/AddOns/LumenShift/Media/" .. modeID .. ".tga")
        local enter, leave = button:GetScript("OnEnter"), button:GetScript("OnLeave")
        ns.Widgets.Script(button, "OnEnter", function(...) enter(...); self.selection = index; highlight() end)
        ns.Widgets.Script(button, "OnLeave", function(...) leave(...); highlight() end)
        self.buttons[i] = button
    end
    local function utility(label, icon, index, y, tip)
        local button = W.ButtonIcon(W.Button(env, surface, label, 144, y, 132, function() selectMode(index) end, tip), icon, 16)
        button.label:SetWidth(80); button.label:SetWordWrap(false); button.label:SetNonSpaceWrap(false)
        W.Text(button, tostring(index), 118, -9, 12, 10, W.colors.muted)
        local enter = button:GetScript("OnEnter")
        W.Script(button, "OnEnter", function(...) enter(...); self.selection = index; highlight() end)
        return button
    end
    self.camera = utility("Camera", "ui-camera", 7, -202, "Enter Camera Mode. Hides the interface using your Camera preferences. Use Exit Camera Mode to return.")
    self.studio = utility("Studio", "ui-settings", 8, -242, "Open Studio. Camera options are on its Camera page.")
    ns.Widgets.Script(frame, "OnMouseDown", function(_, button)
        if button == "RightButton" then self.Close(); return end
        if button ~= "LeftButton" then return end
        local position = ns.ReadOnly.Call(runtime.reader, env.GetCursorPosition)
        local scale, cx, cy = surface:GetEffectiveScale(), surface:GetCenter()
        if not position or position.n ~= 2 or not ns.Value.Finite(position[1]) or not ns.Value.Finite(position[2])
            or not ns.Value.Finite(scale) or scale <= 0 or not ns.Value.Finite(cx) or not ns.Value.Finite(cy) then return end
        -- The texture/hit model uses the original 352-unit coordinate system.
        local selected = R.Hit((position[1] / scale - cx) * 352 / 420, (position[2] / scale - cy) * 352 / 420)
        if selected then selectMode(selected) end
    end)
    -- Use the same focus-aware, paired-key handling as Studio. Movement key-up
    -- and text entry must keep reaching the game while this menu is visible.
    self.keyboard = ns.Keyboard.Attach(env, frame, nil, function(key)
        if key == "ESCAPE" then return self.Close
        elseif key == "ENTER" or key == "SPACE" then return function() selectMode(self.selection) end
        elseif key:match("^[1-8]$") then return function() selectMode(tonumber(key)) end
        elseif key == "RIGHT" or key == "DOWN" or key == "TAB" then
            return function() self.selection = self.selection % 8 + 1; highlight() end
        elseif key == "LEFT" or key == "UP" then
            return function() self.selection = (self.selection + 6) % 8 + 1; highlight() end
        end
    end)
    function self.Toggle()
        if frame:IsShown() then self.Close(); return end
        if product.IsCombat() then ns.Diagnostics.Emit(runtime, "LumenShift: wheel unavailable during combat; nothing queued."); return end
        if not pcall(frame.SetPropagateKeyboardInput, frame, true) then
            ns.Diagnostics.Emit(runtime, "LumenShift: wheel keyboard API unavailable; opening Studio."); openStudio(); return
        end
        local parentScale = env.UIParent:GetEffectiveScale()
        if not ns.Value.Finite(parentScale) or parentScale <= 0 then parentScale = 1 end
        frame:SetScale(math.min(1 / parentScale, env.UIParent:GetWidth() / 460, env.UIParent:GetHeight() / 508))
        local scale = frame:GetEffectiveScale()
        local position = ns.ReadOnly.Call(runtime.reader, env.GetCursorPosition)
        if not position or position.n ~= 2 or not ns.Value.Finite(position[1]) or not ns.Value.Finite(position[2]) then
            ns.Diagnostics.Emit(runtime, "LumenShift: cursor coordinates unavailable; opening Studio."); openStudio(); return
        end
        local x, y = position[1], position[2]
        x, y = R.Clamp(x / scale, y / scale, env.UIParent:GetWidth() * parentScale / scale,
            env.UIParent:GetHeight() * parentScale / scale, 222, 246)
        frame:ClearAllPoints(); frame:SetPoint("CENTER", env.UIParent, "BOTTOMLEFT", x, y)
        highlight(); frame:Show(); frame:Raise(); W.Fade(frame, db.config.preferences)
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
        if runtime.entry and runtime.entry.Refresh then runtime.entry.Refresh() else launcher:Hide() end
        highlight()
    end
    self.Refresh()
    ns.Log.Record(runtime.reader, "radial", "initialize", "INFO", "PASS")
    return self
end
