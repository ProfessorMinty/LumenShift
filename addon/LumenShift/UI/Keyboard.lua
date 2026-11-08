local _, ns = ...
local K, W = {}, ns.Widgets
ns.Keyboard = K

-- Only our visible window participates. Native text focus outside LumenShift
-- always wins; no bindings, protected frames or other addons are changed.
function K.Control(env, control, edit)
    local parent = control:GetParent()
    while parent and not parent.lumenKeyboard do parent = parent:GetParent() end
    if not parent then return end
    local nav = parent.lumenKeyboard
    if not nav.known[control] then
        nav.known[control] = true; nav.controls[#nav.controls + 1] = control
    end
    control.lumenEdit, control.lumenNavigation = edit, nav
    if edit then
        W.Script(control, "OnTabPressed", function() nav.Move(env.IsShiftKeyDown and env.IsShiftKeyDown() and -1 or 1) end)
    end
end

function K.Attach(env, window, viewport)
    local nav = { controls = {}, known = {}, viewport = viewport }
    window.lumenKeyboard = nav
    local function ring(control, show)
        if not control then return end
        if not control.lumenFocusRing and show then
            local frame = env.CreateFrame("Frame", nil, control)
            frame:SetPoint("TOPLEFT", control, "TOPLEFT", -2, 2)
            frame:SetSize(control:GetWidth() + 4, control:GetHeight() + 4)
            frame:EnableMouse(false); frame.edges = W.Border(frame, W.colors.accent)
            control.lumenFocusRing = frame
        end
        if control.lumenFocusRing then
            if show then
                local frame = control.lumenFocusRing
                frame:SetSize(control:GetWidth() + 4, control:GetHeight() + 4)
                for i, edge in ipairs(frame.edges) do
                    edge:SetSize(i <= 2 and frame:GetWidth() or 1, i > 2 and frame:GetHeight() or 1)
                end
                frame:Show()
            else control.lumenFocusRing:Hide() end
        end
    end
    function nav.Clear()
        local previous = nav.current; nav.current = nil
        ring(previous, false)
        if previous and previous.lumenEdit then previous:ClearFocus() end
    end
    function nav.Move(direction)
        local available, index = {}, 0
        for _, control in ipairs(nav.controls) do
            if control:IsVisible() and (control.lumenEdit or control:IsEnabled()) then
                available[#available + 1] = control
                if control == nav.current then index = #available end
            end
        end
        nav.Clear()
        if #available == 0 then return end
        if index == 0 and direction < 0 then index = 1 end
        nav.current = available[(index - 1 + direction) % #available + 1]
        local control = nav.current
        ring(control, true)
        if control.lumenEdit then control:SetFocus() end
        local view = nav.viewport
        if view then
            local node, top = control, 0
            while node and node ~= view.body do
                local _, _, _, _, y = node:GetPoint(1)
                top = top - (y or 0); node = node:GetParent()
            end
            if node == view.body then
                local offset, height = view.scroll:GetVerticalScroll(), view.scroll:GetHeight()
                if top < offset then offset = top
                elseif top + control:GetHeight() > offset + height then offset = top + control:GetHeight() - height end
                view.bar:SetValue(math.max(0, math.min(view.maximum(), offset)))
            end
        end
    end
    local function key(_, value)
        if ns.runtime and ns.runtime.product.IsCombat() then return end
        local focused = env.GetCurrentKeyBoardFocus and env.GetCurrentKeyBoardFocus()
        local handled = false
        if not focused then
            if value == "TAB" then nav.Move(env.IsShiftKeyDown and env.IsShiftKeyDown() and -1 or 1); handled = true
            elseif (value == "ENTER" or value == "SPACE") and nav.current and nav.current:IsVisible() and not nav.current.lumenEdit then
                local click = nav.current:GetScript("OnClick")
                if click and nav.current:IsEnabled() then click(nav.current, "LeftButton"); handled = true end
            elseif value == "ESCAPE" and nav.current then nav.Clear(); handled = true end
        end
        window:SetPropagateKeyboardInput(not handled)
    end
    -- Keyboard support can be unavailable/restricted independently of mouse UI.
    local ok = type(env.GetCurrentKeyBoardFocus) == "function" and pcall(function() window:EnableKeyboard(true); window:SetPropagateKeyboardInput(true) end)
    if ok then W.Script(window, "OnKeyDown", key) end
    local hide = window:GetScript("OnHide")
    W.Script(window, "OnHide", function(self, ...) nav.Clear(); if hide then hide(self, ...) end end)
    return nav
end
