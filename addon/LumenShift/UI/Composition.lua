local _, ns = ...
local C, W = {}, ns.Widgets
ns.Composition = C
function C.New(runtime)
    local env, db = runtime.reader.env, runtime.db
    local self = { capturing = false, status = "READY", generation = 0 }
    local function sync()
        if not self.root then return end
        if runtime.camera.active and not runtime.product.IsCombat() and not self.capturing then self.root:Show() else self.root:Hide() end
    end
    local function layout()
        local root, prefs = self.root, db.camera
        local width, height = env.UIParent:GetWidth(), env.UIParent:GetHeight()
        root:SetScale(env.UIParent:GetEffectiveScale())
        local ratio = ({ wide = 16 / 9, cinema = 2.39, square = 1 })[prefs.aspect]
        local w, h = width, height
        if ratio then if width / height > ratio then w = height * ratio else h = width / ratio end end
        local left, top = (width - w) / 2, (height - h) / 2
        for i, line in ipairs(self.lines) do
            line:ClearAllPoints()
            if i <= 2 then line:SetSize(1, h); line:SetPoint("TOPLEFT", root, "TOPLEFT", left + w * i / 3, -top)
            elseif i <= 4 then line:SetSize(w, 1); line:SetPoint("TOPLEFT", root, "TOPLEFT", left, -top - h * (i - 2) / 3)
            elseif i <= 6 then line:SetSize(w, 1); line:SetPoint("TOPLEFT", root, "TOPLEFT", left, -top - (i - 5) * h)
            else line:SetSize(1, h); line:SetPoint("TOPLEFT", root, "TOPLEFT", left + (i - 7) * w, -top) end
            line:SetAlpha((i <= 4 and prefs.thirds or i > 4 and ratio) and 0.55 or 0)
        end
    end
    function self.Hide() if self.root then self.root:Hide() end end
    function self.CancelCapture()
        -- A scheduled capture belongs to this Camera entry only. An already
        -- issued native request drains until its event/timeout; it cannot be undone.
        if self.capturing and not self.requested then
            self.generation = self.generation + 1
            self.capturing, self.status = false, "CAPTURE_CANCELLED"
        end
        self.Hide()
    end
    local function build()
        if self.root then return end
        local root = env.CreateFrame("Frame", nil, env.UIParent); self.root, self.lines = root, {}
        root:SetParent(nil); root:SetAllPoints(env.UIParent); root:SetFrameStrata("DIALOG"); root:EnableMouse(false)
        for i = 1, 8 do local line = root:CreateTexture(nil, "OVERLAY"); line:SetColorTexture(1, 1, 1, 1); self.lines[i] = line end
        local bar = env.CreateFrame("Frame", nil, root); bar:SetSize(520, 52); bar:SetPoint("BOTTOM", root, "BOTTOM", 0, 32)
        W.Fill(bar, W.colors.bg); W.Border(bar)
        W.Button(env, bar, "Capture screenshot", 10, -9, 240, self.Capture, "Hides these guides and controls for the capture.")
        W.Button(env, bar, "Exit Camera Mode", 264, -9, 246, function() runtime.camera.Exit() end)
        root:RegisterEvent("SCREENSHOT_SUCCEEDED"); root:RegisterEvent("SCREENSHOT_FAILED")
        root:RegisterEvent("UI_SCALE_CHANGED"); root:RegisterEvent("DISPLAY_SIZE_CHANGED")
        root:SetScript("OnEvent", function(_, event)
            if event == "SCREENSHOT_SUCCEEDED" or event == "SCREENSHOT_FAILED" then
                if self.capturing and self.requested then
                    self.capturing, self.requested, self.status = false, false, event
                    sync()
                end
            elseif not runtime.product.IsCombat() then layout() end
        end)
        root:Hide()
    end
    function self.Show()
        if not db or runtime.product.IsCombat() then return end
        build(); layout(); sync()
    end
    function self.Capture()
        if self.capturing or not runtime.camera.active or runtime.product.IsCombat() then return nil, "CAMERA_NOT_READY" end
        if type(env.Screenshot) ~= "function" or type(env.C_Timer) ~= "table" or type(env.C_Timer.After) ~= "function" then
            self.status = "SCREENSHOT_UNAVAILABLE"; return nil, self.status
        end
        self.generation = self.generation + 1
        local id = self.generation
        self.capturing, self.status = true, "CAPTURING"; self.Hide()
        -- Let the hidden guides render before requesting the native screenshot.
        local scheduled = pcall(env.C_Timer.After, 0.1, function()
            if id ~= self.generation then return end
            if not runtime.camera.active or runtime.product.IsCombat() then
                self.capturing, self.status = false, "CAPTURE_CANCELLED"; sync(); return
            end
            self.requested = true
            local result = ns.ReadOnly.Call(runtime.reader, env.Screenshot)
            if not result then self.capturing, self.requested, self.status = false, false, "SCREENSHOT_UNAVAILABLE"; sync(); return end
            -- Start the timeout after the request, so a long frame before this
            -- callback cannot expire it in the same frame as the screenshot.
            local timeout = pcall(env.C_Timer.After, 5, function()
                if id == self.generation and self.capturing then
                    self.capturing, self.requested, self.status = false, false, "CAPTURE_RESULT_UNOBSERVED"; sync()
                end
            end)
            if not timeout then
                self.capturing, self.requested, self.status = false, false, "CAPTURE_TIMER_FAILED"; sync()
            end
        end)
        if not scheduled then self.capturing, self.status = false, "CAPTURE_TIMER_FAILED"; self.generation = id + 1; sync(); return nil, self.status end
        return true
    end
    return self
end
