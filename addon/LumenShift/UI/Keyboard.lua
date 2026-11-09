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
        W.Script(control, "OnTabPressed", function() nav.Tab() end)
    end
end

function K.Attach(env, window, viewport, shortcuts)
    local nav = { controls = {}, known = {}, viewport = viewport, enabled = false, consumed = {} }
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
        if not nav.enabled or not window:IsVisible() then return end
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
    local function disable(code)
        nav.enabled, nav.error = false, code
        -- Release capture even when a query/handler failed after the previous
        -- key was consumed. Do not leave an enabled frame with no key handler.
        pcall(window.SetPropagateKeyboardInput, window, true)
        local released = pcall(window.EnableKeyboard, window, false)
        pcall(nav.Clear)
        W.Script(window, "OnKeyDown", nil)
        W.Script(window, "OnKeyUp", nil); nav.consumed = {}
        if not released then pcall(window.Hide, window) end
        if nav.OnFailure then pcall(nav.OnFailure, code) end
        ns.Log.Record(ns.runtime and ns.runtime.reader, "keyboard", "fallback", "WARN", code)
    end
    local function propagate(value)
        local ok = pcall(window.SetPropagateKeyboardInput, window, value)
        if not ok then disable("KEYBOARD_PROPAGATION_UNAVAILABLE") end
        return ok
    end
    local function direction()
        local ok, shift = pcall(env.IsShiftKeyDown)
        if not ok or type(shift) ~= "boolean" then disable("KEYBOARD_MODIFIER_UNAVAILABLE"); return nil end
        return shift and -1 or 1
    end
    function nav.Tab()
        if not nav.enabled then return end
        local step = direction()
        if step and propagate(false) then
            nav.consumed.TAB = true
            if not pcall(nav.Move, step) then disable("KEYBOARD_NAVIGATION_FAILED") end
        end
    end
    local function key(_, value)
        if not nav.enabled or not window:IsVisible() then return end
        if ns.runtime and ns.runtime.product.IsCombat() then return end
        -- Establish pass-through before any fallible query or action.
        if not propagate(true) then return end
        local ok, focused = pcall(env.GetCurrentKeyBoardFocus)
        if not ok or focused ~= nil and type(focused) ~= "table" and type(focused) ~= "userdata" then
            disable("KEYBOARD_FOCUS_UNAVAILABLE"); return
        end
        if focused then return end
        local action
        if shortcuts then
            local success, handler = pcall(shortcuts, value)
            if not success then disable("KEYBOARD_ACTION_FAILED"); return end
            action = handler
        end
        if not action and value == "TAB" and #nav.controls > 0 then nav.Tab(); return end
        if not action and (value == "ENTER" or value == "SPACE") and nav.current and nav.current:IsVisible() and not nav.current.lumenEdit then
            local control = nav.current
            local click = control:GetScript("OnClick")
            if click and control:IsEnabled() then action = function() click(control, "LeftButton") end end
        elseif not action and value == "ESCAPE" and nav.current then action = nav.Clear end
        -- Consume before invoking a button, so failure to capture cannot also
        -- activate it and pass the same key into the game.
        if action and propagate(false) then
            nav.consumed[value] = true
            if not pcall(action) then disable("KEYBOARD_ACTION_FAILED") end
        end
    end
    local function keyUp(_, value)
        if not nav.enabled or not window:IsVisible() then return end
        if ns.runtime and ns.runtime.product.IsCombat() then return end
        -- A consumed Tab must not suppress the release of an unrelated held
        -- movement key. Only pair consumption with this key's own down event.
        propagate(not nav.consumed[value]); nav.consumed[value] = nil
    end
    local ok = type(env.GetCurrentKeyBoardFocus) == "function" and type(env.IsShiftKeyDown) == "function"
        and pcall(window.SetPropagateKeyboardInput, window, true)
        and pcall(window.EnableKeyboard, window, true)
    if ok then nav.enabled = true; W.Script(window, "OnKeyDown", key); W.Script(window, "OnKeyUp", keyUp)
    else disable("KEYBOARD_API_UNAVAILABLE") end
    local hide = window:GetScript("OnHide")
    W.Script(window, "OnHide", function(self, ...)
        nav.Clear(); nav.consumed = {}
        if hide then hide(self, ...) end
    end)
    return nav
end
