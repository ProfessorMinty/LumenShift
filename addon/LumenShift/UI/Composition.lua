local _, ns = ...
local C, W = {}, ns.Widgets
ns.Composition = C
function C.New(runtime)
    local env, db = runtime.reader.env, runtime.db
    local self = { capturing = false, controlsHidden = false, status = "READY", generation = 0 }
    local function sync()
        if not self.root then return end
        local active = runtime.camera.active and not runtime.product.IsCombat()
        if active and not self.capturing and not self.controlsHidden then self.root:Show() else self.root:Hide() end
        -- This pixel-free, mouse-transparent frame must survive a clean view or
        -- pending screenshot so Escape can still exit. It never captures outside Camera.
        if active and self.keyboard.enabled then self.input:Show() else self.input:Hide() end
    end
    local function layout()
        local root, prefs = self.root, db.camera
        local width, height = env.UIParent:GetWidth(), env.UIParent:GetHeight()
        root:SetScale(env.UIParent:GetEffectiveScale())
        self.bar:SetScale(math.min(1, math.max(0.1, (width - 24) / 720)))
        if self.editor then self.editor.Layout() end
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
    function self.Hide()
        if self.root then self.root:Hide(); self.input:Hide() end
    end
    function self.ToggleControls()
        if not runtime.camera.active or runtime.product.IsCombat() or not self.keyboard or not self.keyboard.enabled then return nil end
        if not self.controlsHidden and runtime.photoPreview and runtime.photoPreview.Pending() then
            return runtime.photoPreview.Finish(self.ToggleControls)
        end
        self.controlsHidden = not self.controlsHidden
        if env.GameTooltip then env.GameTooltip:Hide() end
        sync(); return true
    end
    function self.CancelCapture()
        -- A scheduled capture belongs to this Camera entry only. An already
        -- issued native request drains until its event/timeout; it cannot be undone.
        if self.capturing and not self.requested then
            self.generation = self.generation + 1
            self.capturing, self.status = false, "CAPTURE_CANCELLED"
        end
        self.controlsHidden = false; self.Hide()
    end
    local function build()
        if self.root then return end
        local root = env.CreateFrame("Frame", nil, env.UIParent); self.root, self.lines = root, {}
        root:SetParent(nil); root:SetAllPoints(env.UIParent); root:SetFrameStrata("DIALOG"); root:EnableMouse(false)
        for i = 1, 8 do local line = root:CreateTexture(nil, "OVERLAY"); line:SetColorTexture(1, 1, 1, 1); self.lines[i] = line end
        local input = env.CreateFrame("Frame", nil, env.UIParent); self.input = input
        input:SetParent(nil); input:SetSize(1, 1); input:SetPoint("TOPLEFT", env.UIParent, "TOPLEFT")
        input:SetFrameStrata("DIALOG"); input:SetFrameLevel(50); input:EnableMouse(false)
        self.keyboard = ns.Keyboard.Attach(env, input, nil, function(key)
            if key == "ESCAPE" then return function() runtime.camera.Exit() end end
            if key == "H" then return self.ToggleControls end
        end)
        local bar = env.CreateFrame("Frame", nil, root); self.bar = bar
        bar:SetSize(720, 84); bar:SetPoint("BOTTOM", root, "BOTTOM", 0, 32)
        W.Fill(bar, W.colors.bg); W.Border(bar)
        W.Button(env, bar, "Capture screenshot", 10, -9, 224, self.Capture, "Hides these guides and controls for the capture.")
        self.hideButton = W.Button(env, bar, "Hide controls", 248, -9, 224, self.ToggleControls,
            "Clean view for external screenshots or recording. H shows controls again; Escape exits Camera Mode.")
        W.Button(env, bar, "Exit Camera Mode", 486, -9, 224, function() runtime.camera.Exit() end)
        local hint = W.Text(bar, "H: hide / show controls   |   Esc: exit Camera Mode", 14, -56, 692, 12, W.colors.muted)
        self.keyboard.OnFailure = function(code)
            self.controlsHidden, self.status = false, code; self.hideButton:Disable()
            hint:SetText("Keyboard unavailable. Use Exit Camera Mode or your Camera keybinding.")
            sync()
        end
        if not self.keyboard.enabled then self.keyboard.OnFailure(self.keyboard.error) end
        self.editor = ns.PhotoEditorUI.New(runtime, self)
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
        self.Hide()
    end
    function self.Show()
        if not db or runtime.product.IsCombat() then return end
        build(); layout(); sync()
        if self.editor then self.editor.Refresh() end
    end
    function self.Capture()
        if self.capturing or not runtime.camera.active or runtime.product.IsCombat() then return nil, "CAMERA_NOT_READY" end
        if runtime.photoPreview and runtime.photoPreview.Pending() then return runtime.photoPreview.Finish(self.Capture) end
        if type(env.Screenshot) ~= "function" or type(env.C_Timer) ~= "table" or type(env.C_Timer.After) ~= "function" then
            self.status = "SCREENSHOT_UNAVAILABLE"; return nil, self.status
        end
        self.generation = self.generation + 1
        local id = self.generation
        self.capturing, self.status = true, "CAPTURING"
        if env.GameTooltip then env.GameTooltip:Hide() end
        sync()
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
