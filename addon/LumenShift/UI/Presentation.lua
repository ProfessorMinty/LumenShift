local _, ns = ...
local P = {}
ns.Presentation = P
function P.New(env)
    local self = { frame = nil, lastError = nil, enabled = false, keepEffects = true, barsFraction = 0 }
    local function inCombat()
        local ok, value = pcall(env.InCombatLockdown)
        return not ok or value ~= false
    end
    function self.Status()
        if self.suspended then return "SUSPENDED_COMBAT" end
        if not self.enabled then return "OFF" end
        if inCombat() and not self.inCombat then return "SUSPENDED_COMBAT" end
        if not self.keepEffects and not env.UIParent:IsShown() then return "HIDDEN_WITH_UI" end
        return self.frame and self.frame:IsVisible() and "VISIBLE" or "HIDDEN"
    end
    function self.SyncVisibility()
        if not self.frame then return end
        if self.enabled and (not inCombat() or self.inCombat) and (self.keepEffects or env.UIParent:IsShown()) then self.frame:Show()
        else self.frame:Hide() end
    end
    local function layout()
        local scale = env.UIParent:GetEffectiveScale()
        self.frame:SetScale(scale)
        local width, height = env.UIParent:GetWidth(), env.UIParent:GetHeight()
        local thickness = math.max(1, math.min(width, height) * 0.10)
        for index, edge in ipairs(self.edges) do
            if index <= 2 then edge:SetHeight(thickness) else edge:SetWidth(thickness) end
        end
        for _, bar in ipairs(self.bars) do bar:SetHeight(math.max(1, height * self.barsFraction)) end
    end
    local function build()
        if self.frame then return end
        local frame = env.CreateFrame("Frame", nil, env.UIParent)
        -- Native SetParent accepts nil. An addon-owned unprotected root survives
        -- Alt+Z without reparenting the HUD or any foreign frame. Created out of combat.
        frame:SetParent(nil)
        frame:SetAllPoints(env.UIParent); frame:SetFrameStrata("BACKGROUND"); frame:SetFrameLevel(0)
        frame:EnableMouse(false)
        self.frame, self.edges, self.bars = frame, {}, {}
        self.tint = frame:CreateTexture(nil, "BACKGROUND")
        self.tint:SetAllPoints(frame)
        for i, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local texture = frame:CreateTexture(nil, "BACKGROUND")
            ns.Widgets.Asset(texture, "Interface/AddOns/LumenShift/Media/vignette.tga")
            if i <= 2 then
                texture:SetPoint(edge .. "LEFT", frame, edge .. "LEFT")
                texture:SetPoint(edge .. "RIGHT", frame, edge .. "RIGHT")
            else
                texture:SetPoint("TOP" .. edge, frame, "TOP" .. edge)
                texture:SetPoint("BOTTOM" .. edge, frame, "BOTTOM" .. edge)
            end
            if i == 1 then texture:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
            elseif i == 2 then texture:SetTexCoord(0, 1, 0, 0, 1, 1, 1, 0)
            elseif i == 3 then texture:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
            else texture:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1) end
            self.edges[i] = texture
        end
        for i, edge in ipairs({ "TOP", "BOTTOM" }) do
            local bar = frame:CreateTexture(nil, "BACKGROUND")
            bar:SetPoint(edge .. "LEFT", frame, edge .. "LEFT"); bar:SetPoint(edge .. "RIGHT", frame, edge .. "RIGHT")
            bar:SetColorTexture(0, 0, 0, 1); self.bars[i] = bar
        end
        frame:Hide()
        local function resize()
            if not inCombat() or self.inCombat then
                local ok = pcall(layout)
                if not ok then self.Clear(); self.lastError = "PRESENTATION_UNAVAILABLE" end
            end
        end
        env.UIParent:HookScript("OnShow", self.SyncVisibility)
        env.UIParent:HookScript("OnHide", self.SyncVisibility)
        env.UIParent:HookScript("OnSizeChanged", resize)
        frame:RegisterEvent("UI_SCALE_CHANGED"); frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
        frame:SetScript("OnEvent", resize)
    end
    function self.Clear() self.enabled, self.suspended = false, false; if self.frame then self.frame:Hide() end end
    function self.Combat(keep)
        self.inCombat=keep==true
        if keep then self.suspended=false; self.SyncVisibility() else self.Clear(); self.suspended=true end
    end -- never resize/hide the user's HUD
    function self.Apply(id, mode, config, keepEffects, keepInCombat)
        self.Clear()
        if id == "natural" or mode.styling == "clear" or not config.studio.effects then return true end
        local checked, inCombat = pcall(env.InCombatLockdown)
        if not checked or type(inCombat)~="boolean" or inCombat and not keepInCombat then return true end
        self.inCombat=keepInCombat==true
        local ok = pcall(function()
            build()
            self.keepEffects, self.enabled = keepEffects ~= false, true
            local rgb = mode.tint
            self.tint:SetColorTexture(rgb.r, rgb.g, rgb.b, mode.tintEnabled and mode.opacity or 0)
            for _, edge in ipairs(self.edges) do edge:SetAlpha(mode.vignette) end
            local bars = config.studio.screenshot and mode.letterbox or 0
            self.barsFraction = bars
            for _, bar in ipairs(self.bars) do bar:SetAlpha(bars > 0 and 1 or 0) end
            layout(); self.SyncVisibility()
        end)
        if not ok then self.Clear(); self.lastError = "PRESENTATION_UNAVAILABLE"; return nil, self.lastError end
        self.lastError = nil
        return true
    end
    return self
end
