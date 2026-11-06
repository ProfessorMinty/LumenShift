local _, ns = ...
local P = {}
ns.Presentation = P
function P.New(env)
    local self = { frame = nil, lastError = nil }
    local function build()
        if self.frame then return end
        local frame = env.CreateFrame("Frame", nil, env.UIParent)
        frame:SetAllPoints(env.UIParent); frame:SetFrameStrata("BACKGROUND"); frame:SetFrameLevel(0)
        frame:EnableMouse(false)
        self.frame, self.edges, self.bars = frame, {}, {}
        self.tint = frame:CreateTexture(nil, "BACKGROUND")
        self.tint:SetAllPoints(frame)
        for i, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local texture = frame:CreateTexture(nil, "BACKGROUND")
            texture:SetTexture("Interface/AddOns/LumenShift/Media/vignette.tga")
            if i <= 2 then
                texture:SetPoint(edge .. "LEFT", frame, edge .. "LEFT")
                texture:SetPoint(edge .. "RIGHT", frame, edge .. "RIGHT"); texture:SetHeight(110)
            else
                texture:SetPoint("TOP" .. edge, frame, "TOP" .. edge)
                texture:SetPoint("BOTTOM" .. edge, frame, "BOTTOM" .. edge); texture:SetWidth(110)
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
    end
    function self.Clear() if self.frame then self.frame:Hide() end end
    function self.Combat() self.Clear() end -- never resize/hide the user's HUD
    function self.Apply(id, mode, config)
        self.Clear()
        if id == "natural" or not config.studio.effects then return true end
        local checked, inCombat = pcall(env.InCombatLockdown)
        if not checked or inCombat ~= false then return true end
        local ok = pcall(function()
            build()
            local rgb = mode.tint
            self.tint:SetColorTexture(rgb.r, rgb.g, rgb.b, mode.tintEnabled and mode.opacity or 0)
            for _, edge in ipairs(self.edges) do edge:SetAlpha(mode.vignette) end
            local bars = config.studio.screenshot and mode.letterbox or 0
            for _, bar in ipairs(self.bars) do bar:SetHeight(math.max(1, env.UIParent:GetHeight() * bars)); bar:SetAlpha(bars > 0 and 1 or 0) end
            self.frame:Show()
        end)
        if not ok then self.Clear(); self.lastError = "PRESENTATION_UNAVAILABLE"; return nil, self.lastError end
        self.lastError = nil
        return true
    end
    return self
end
