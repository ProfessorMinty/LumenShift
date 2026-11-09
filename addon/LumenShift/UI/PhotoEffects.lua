local _, ns = ...
local P = {}; ns.PhotoEffects = P
function P.New(runtime)
    local env = runtime.reader.env
    local self = {}
    local function texture(frame, name, layer)
        local t = frame:CreateTexture(nil, layer or "ARTWORK")
        if name then ns.Widgets.Asset(t, "Interface/AddOns/LumenShift/Media/" .. name .. ".tga") end
        return t
    end
    function self.Hide() if self.root then self.root:Hide() end end
    local function build()
        if self.root then return end
        local root = env.CreateFrame("Frame", nil, env.UIParent); self.root = root
        root:SetParent(nil); root:SetAllPoints(env.UIParent); root:SetFrameStrata("BACKGROUND"); root:SetFrameLevel(5); root:EnableMouse(false)
        self.tint = texture(root, nil, "BACKGROUND"); self.tint:SetAllPoints(root)
        self.glow, self.vignette, self.outside, self.bars = {}, {}, {}, {}
        for i = 1, 2 do self.glow[i] = texture(root); self.glow[i]:SetBlendMode("ADD") end
        self.leak = { texture(root), texture(root) }; for _, t in ipairs(self.leak) do t:SetBlendMode("ADD") end
        self.grain = texture(root, "photo-grain"); self.grain:SetAllPoints(root)
        self.grain:SetTexture("Interface/AddOns/LumenShift/Media/photo-grain.tga", "REPEAT", "REPEAT")
        for i = 1, 2 do self.vignette[i] = texture(root, nil, "OVERLAY") end
        for i = 1, 4 do self.outside[i] = texture(root, nil, "OVERLAY") end
        for i = 1, 2 do self.bars[i] = texture(root, nil, "OVERLAY") end
        root:RegisterEvent("UI_SCALE_CHANGED"); root:RegisterEvent("DISPLAY_SIZE_CHANGED")
        root:SetScript("OnEvent", function() if runtime.photoEditor then runtime.photoEditor.Render() end end)
        self.Hide()
    end
    local function rect(t, root, x, y, w, h, alpha)
        t:ClearAllPoints(); t:SetPoint("TOPLEFT", root, "TOPLEFT", x, -y)
        t:SetSize(math.max(1, w), math.max(1, h)); t:SetColorTexture(0, 0, 0, w > 0 and h > 0 and alpha or 0)
    end
    function self.Apply(look, before)
        if runtime.portrait and runtime.portrait.layerCapture then self.Hide(); return end
        if runtime.product.IsCombat() or not ns.PhotoConfig.ValidLook(look) then self.Hide(); return end
        build()
        if before then self.Hide(); return end
        local root, strength = self.root, look.strength
        local w, h = env.UIParent:GetWidth(), env.UIParent:GetHeight()
        root:SetScale(env.UIParent:GetEffectiveScale())
        local warm, tint = look.warmth, look.tint
        self.tint:SetColorTexture(math.min(1, .5 + warm * .45 + tint * .2), .5 - math.abs(tint) * .25,
            math.min(1, .5 - warm * .45 + tint * .2), math.min(.32, (math.abs(warm) + math.abs(tint)) * .2) * strength)
        local function ellipse(textures, prefix, x, y, width, height, softness, alpha, color)
            local n = math.min(10, math.max(0, softness * 10)); local lo = math.floor(n + .5); local fraction = 0
            for i, t in ipairs(textures) do
                t:ClearAllPoints(); t:SetPoint("CENTER", root, "TOPLEFT", x, -y); t:SetSize(width, height)
                ns.Widgets.Asset(t, "Interface/AddOns/LumenShift/Media/photo-" .. prefix .. "-" .. (i == 1 and lo or math.min(10, lo + 1)) .. ".tga")
                t:SetVertexColor(unpack(color or { 1, 1, 1 }))
                t:SetAlpha(alpha * (i == 1 and (1 - fraction) or fraction))
            end
        end
        ellipse(self.glow, "glow", w * look.glowX, h * look.glowY, h * look.glowSize * 2, h * look.glowSize * 2,
            look.glowSoftness, look.glow * strength, { look.glowR, look.glowG, look.glowB })
        ellipse(self.leak, "glow", w * (look.leakSide + 1) / 2, h / 2, w * look.leakWidth, h * 2.4, 1,
            look.leak * strength, { look.glowR, look.glowG, look.glowB })
        self.grain:SetTexCoord(0, w / (128 * look.grainScale), 0, h / (128 * look.grainScale)); self.grain:SetAlpha(look.grain * strength)
        local ew, eh, x, y = w * look.size * 2, h * look.size * 2, w * look.centerX, h * look.centerY
        ellipse(self.vignette, "vignette", x, y, ew, eh, look.feather, look.vignette * strength)
        local left, right, top, bottom = math.max(0, x - ew / 2), math.min(w, x + ew / 2), math.max(0, y - eh / 2), math.min(h, y + eh / 2)
        local a = look.vignette * strength
        rect(self.outside[1], root, 0, 0, w, top, a); rect(self.outside[2], root, 0, bottom, w, h - bottom, a)
        rect(self.outside[3], root, 0, top, left, bottom - top, a); rect(self.outside[4], root, right, top, w - right, bottom - top, a)
        rect(self.bars[1], root, 0, 0, w, h * look.letterbox, 1)
        rect(self.bars[2], root, 0, h * (1 - look.letterbox), w, h * look.letterbox, 1)
        root:Show()
    end
    return self
end
