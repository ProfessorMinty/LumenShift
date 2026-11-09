local _, ns = ...
local U, W = {}, ns.Widgets
ns.PhotoEditorUI = U
function U.New(runtime, composition)
    local env, editor, db, preview = runtime.reader.env, runtime.photoEditor, runtime.db, runtime.photoPreview
    local self = { tab = "Look", sliders = {}, drafts = {} }
    local panel = env.CreateFrame("Frame", nil, composition.root); self.panel = panel
    panel:SetSize(360, 640); panel:SetPoint("TOPRIGHT", composition.root, "TOPRIGHT", -24, -24)
    W.Fill(panel, W.colors.bg); W.Border(panel); W.Window(env, panel, 42, 12)
    W.Text(panel, "Photo Studio", 16, -15, 300, 22)
    local subtitle = W.Text(panel, "Compose in the world", 16, -47, 300, 12, W.colors.muted)
    local world, portrait
    world = W.Button(env, panel, "World Photo", 12, -70, 160, function()
        local ok, why = runtime.portrait.World(); self.notice = not ok and why or nil; self.Build(true)
    end)
    portrait = W.Button(env, panel, "Portrait Stage", 184, -70, 160, function()
        local ok, why = runtime.portrait.Enter(); self.notice = not ok and why or nil
        if ok then self.tab = "Pose" end; self.Build(true)
    end)
    local tabs = {}
    for i, label in ipairs({ "Look", "Light", "Frame", "Pose", "Capture", "Saved" }) do
        local button = W.Button(env, panel, label, 12 + (i - 1) % 3 * 112, -112 - math.floor((i - 1) / 3) * 40, 104, function() runtime.cameraActions.StopOrbit(); self.notice = nil; self.tab = label; self.Build(true) end)
        tabs[label] = button
    end
    local scroll = env.CreateFrame("ScrollFrame", nil, panel); self.scroll = scroll
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -198); scroll:SetSize(310, 402); scroll:EnableMouseWheel(true)
    local content = env.CreateFrame("Frame", nil, scroll); content:SetSize(310, 1); scroll:SetScrollChild(content); content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    local pool = W.CreatePool(env, content); local penv = pool.env
    function self.ClearFocus()
        for _, field in ipairs(pool.frames.EditBox or {}) do field:ClearFocus() end
    end
    composition.root:HookScript("OnHide", function() self.ClearFocus(); editor.EndLookEdit(); runtime.cameraActions.StopOrbit() end)
    local scrollbar = env.CreateFrame("Slider", nil, panel); self.scrollbar = scrollbar
    scrollbar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -198); scrollbar:SetSize(8, 402)
    scrollbar:SetOrientation("VERTICAL"); scrollbar:SetValueStep(20); W.Fill(scrollbar, W.colors.sidebar)
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY"); thumb:SetSize(6, 32); thumb:SetColorTexture(unpack(W.colors.accent)); scrollbar:SetThumbTexture(thumb)
    scrollbar:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
    scroll:SetScript("OnMouseWheel", function(_, delta) scrollbar:SetValue(scroll:GetVerticalScroll() - delta * 54) end)
    local footer = env.CreateFrame("Frame", nil, panel); self.footer = footer
    footer:SetSize(332, 94); footer:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, 12)
    W.Rule(footer, 0, 0, 332)
    self.compare = W.Button(env, footer, "Before / After", 0, -12, 160, function() preview.Finish(editor.Compare) end)
    W.Button(env, footer, "Reset photo look", 172, -12, 160, function() editor.Recipe("neutral"); self.Build() end)
    self.status = W.Text(footer, "", 0, -53, 332, 12, W.colors.muted)
    local marker = env.CreateFrame("Button", nil, composition.root); self.marker = marker
    marker:SetSize(38, 38); marker:EnableMouse(true); marker:SetMovable(true); marker:SetClampedToScreen(true); marker:RegisterForDrag("LeftButton")
    W.Border(marker, W.colors.accent); W.Text(marker, "+", 12, -8, 24, 20, W.colors.accent)
    W.Tip(env, marker, "Drag to place the glow accent. Hidden in clean view and screenshots.")
    marker:SetScript("OnDragStart", function() if not runtime.product.IsCombat() then marker:StartMoving() end end)
    marker:SetScript("OnDragStop", function()
        marker:StopMovingOrSizing()
        local x, y = marker:GetCenter(); local scale = marker:GetEffectiveScale() / composition.root:GetEffectiveScale()
        editor.SetMany({ glowX = math.max(0, math.min(1, x * scale / env.UIParent:GetWidth())),
            glowY = math.max(0, math.min(1, 1 - y * scale / env.UIParent:GetHeight())) })
        self.Build()
    end)
    marker:SetScript("OnHide", function() marker:StopMovingOrSizing() end)
    local function positionMarker()
        local look = db.camera.editor.look
        marker:ClearAllPoints(); marker:SetPoint("CENTER", composition.root, "TOPLEFT", env.UIParent:GetWidth() * look.glowX, -env.UIParent:GetHeight() * look.glowY)
        if self.tab == "Look" and look.glow > 0 and not editor.before then marker:Show() else marker:Hide() end
    end
    function self.Layout()
        local h = math.min(640, env.UIParent:GetHeight() - 154)
        local scale = math.min(1, math.max(.4, (env.UIParent:GetWidth() - 32) / 360), math.max(.4, h / 480))
        panel:SetScale(scale); h = math.max(480, h / scale); panel:SetHeight(h)
        scroll:SetHeight(h - 314); scrollbar:SetHeight(h - 314)
        scrollbar:SetMinMaxValues(0, math.max(0, (self.contentHeight or 1) - scroll:GetHeight()))
        scrollbar:SetValue(math.min(scroll:GetVerticalScroll(), math.max(0, (self.contentHeight or 1) - scroll:GetHeight())))
        positionMarker()
    end
    function self.Build(resetScroll)
        self.building = true
        editor.EndLookEdit()
        self.ClearFocus()
        pool.Reset(); self.sliders = {}
        local staged = runtime.portrait.active
        world.SetSelected(not staged); portrait.SetSelected(staged)
        subtitle:SetText(staged and "Compose with staged models" or "Compose in the world")
        for label, button in pairs(tabs) do
            button.SetSelected(self.tab == label)
            button.label:SetText(staged and ({ Frame = "Scene", Pose = "Actors" })[label] or label)
        end
        local y = 0
        local function text(value, height)
            W.Text(content, value, 0, y, 310, 12, W.colors.muted); y = y - (height or 42)
        end
        local function section(label) W.Section(content, label, 0, y, 310); y = y - 40 end
        local function lookSlider(key, label, step)
            local range = ns.PhotoConfig.Ranges[key]
            self.sliders[key] = W.Slider(penv, content, label, 0, y, range[1], range[2], step or .01,
                function() return db.camera.editor.look[key] end,
                function(n) local ok = editor.Set(key, n); positionMarker(); return ok end, nil, 310)
            W.Script(self.sliders[key], "OnMouseDown", editor.BeginLookEdit)
            W.Script(self.sliders[key], "OnMouseUp", function() editor.EndLookEdit(); self.Refresh() end)
            y = y - 68
        end
        local function liveSlider(key, label, minimum, maximum, step, current)
            local draft = math.max(minimum, math.min(maximum, current))
            local slider = W.Slider(penv, content, label, 0, y, minimum, maximum, step, function() return draft end,
                function(n)
                    local ok = preview.Queue(key, n)
                    if ok then draft = n end
                    return ok
                end, "Live preview while dragging. Changes are paced and verified; the latest value wins. You can also type a value and press Enter.", 310)
            W.Script(slider, "OnMouseDown", function() self.dragging = slider; preview.Begin() end)
            W.Script(slider, "OnMouseUp", function() self.dragging = nil; self.Refresh() end)
            local entered = slider.edit:GetScript("OnEnterPressed")
            W.Script(slider.edit, "OnEnterPressed", function(s) preview.Begin(); entered(s) end)
            self.sliders[key] = slider; y = y - 68
        end
        if staged and (self.tab == "Light" or self.tab == "Frame" or self.tab == "Pose" or self.tab == "Saved") then
            y = ns.PortraitControls.Build(runtime, penv, content, self.tab, self)
        elseif self.tab == "Look" then
            for i, recipe in ipairs({ { "neutral", "Neutral" }, { "ember", "Warm Ember" }, { "night", "Cool Night" }, { "portrait", "Soft Portrait" }, { "sunflare", "Sun Flare" }, { "bluehour", "Blue Hour" } }) do
                local id = recipe[1]
                W.Button(penv, content, recipe[2], (i - 1) % 2 * 160, -math.floor((i - 1) / 2) * 40, 150, function() editor.Recipe(id); self.Build() end)
            end
            W.Button(penv, content, "Undo look", 0, -128, 150, function() editor.Undo(); self.Build() end)
            W.Button(penv, content, "Redo look", 160, -128, 150, function() editor.Undo(true); self.Build() end)
            y = -172; text("Live screen treatments. Your visual modes stay unchanged.", 40)
            lookSlider("strength", "Look strength"); lookSlider("warmth", "Warm / cool"); lookSlider("tint", "Green / rose tint")
            section("VIGNETTE")
            lookSlider("vignette", "Edge darkness"); lookSlider("size", "Clear center size"); lookSlider("feather", "Soft edge", .1)
            lookSlider("centerX", "Center - horizontal"); lookSlider("centerY", "Center - vertical")
            section("GLOW ACCENT")
            text("Decorative screen light. Drag the + onto a fire or highlight; it does not light 3D objects.", 56)
            lookSlider("glow", "Glow strength"); lookSlider("glowSize", "Glow size"); lookSlider("glowSoftness", "Glow softness", .1)
            for _, color in ipairs({ { "Amber", 1, .58, .2 }, { "Ice", .3, .65, 1 }, { "White", 1, 1, 1 } }) do
                local c = color; local x = c[1] == "Amber" and 0 or c[1] == "Ice" and 106 or 212
                W.Button(penv, content, c[1], x, y, 98, function()
                    editor.SetMany({ glowR = c[2], glowG = c[3], glowB = c[4] }); self.Build()
                end)
            end
            y = y - 42
            lookSlider("glowR", "Glow red"); lookSlider("glowG", "Glow green"); lookSlider("glowB", "Glow blue")
            lookSlider("glowX", "Glow - horizontal"); lookSlider("glowY", "Glow - vertical")
            section("EDGE LIGHT"); text("Soft light leak using your glow color. Screen artwork; it does not relight the world.", 54)
            lookSlider("leak", "Light leak strength"); lookSlider("leakSide", "Light leak position", .1); lookSlider("leakWidth", "Light leak width", .1)
            section("TEXTURE"); lookSlider("grain", "Film grain"); lookSlider("grainScale", "Grain size", .1)
        elseif self.tab == "Light" then
            text("Live preview as you drag. Updates are paced; Exit returns your pre-photo values.", 56)
            for _, item in ipairs({ { "Brightness", "Brightness", 0, 100, 1 }, { "Contrast", "Contrast", 0, 100, 1 },
                { "ResampleSharpness", "Sharpness", 0, 100, 5 }, { "bloomUserMult", "Native bloom", 0, 1, .2 } }) do
                local key = item[1]; local value, why = editor.Read(key)
                if key == "ResampleSharpness" and value then
                    local enabled, reason = editor.Read("ResampleAlwaysSharpen"); if enabled == nil then value, why = nil, reason end
                end
                if value then
                    if key == "ResampleSharpness" then value = 100 - value * 50 end
                    liveSlider(key, item[2], item[3], item[4], item[5], value)
                else text(item[2] .. ": " .. (why or "Unavailable"), 64) end
            end
            text("Bloom is renderer-dependent and affects the scene globally. Glow accent on Look is a separate screen effect.", 62)
            W.Button(penv, content, "Restore photo lighting", 0, y, 310, function() preview.Finish(editor.Restore) end); y = y - 48
            local s = db.camera.editor.session
            if s then
                section("PRE-PHOTO VALUES")
                for _, key in ipairs(ns.Value.Keys(s.before)) do text(key .. " = " .. s.before[key], 30) end
            end
        elseif self.tab == "Frame" then
            section("COMPOSITION")
            W.Toggle(penv, content, "Rule of thirds", 0, y, 310, function() return db.camera.thirds end,
                function(v) db.camera.thirds = v; composition.Show() end); y = y - 48
            text("Frame guides disappear in clean view. Letterbox bars below remain in the image.", 52)
            for i, choice in ipairs({ { "none", "No guide" }, { "wide", "16:9" }, { "cinema", "2.39:1" }, { "square", "Square" } }) do
                local id = choice[1]
                local b = W.Button(penv, content, choice[2], (i - 1) % 2 * 160, y - math.floor((i - 1) / 2) * 40, 150, function()
                    db.camera.aspect = id; composition.Show(); self.Build()
                end); b.SetSelected(db.camera.aspect == id)
            end
            y = y - 88; lookSlider("letterbox", "Letterbox height")
            local range = ns.Framing.Range(runtime.reader); local seen = ns.ReadOnly.Read(runtime.reader, "cameraFov")
            if range and ns.Planner.SafeObservation(seen) and ns.Value.Number(seen.raw) then
                liveSlider("cameraFov", "Field of view", range.min, range.max, .1, ns.Value.Number(seen.raw))
            else text("Field of view unavailable; framing guides remain available.", 52) end
            W.Button(penv, content, "Restore field of view", 0, y, 310, function()
                preview.Finish(function()
                    local ok, why = runtime.camera.RestoreFOV(function(done, code)
                        self.notice = not done and ns.Product.Message(code) or nil; self.Refresh()
                    end)
                    if not ok then self.notice = ns.Product.Message(why); self.Refresh() end
                    return ok, why
                end)
            end); y = y - 48
            y = ns.PhotoAdvancedUI.Frame(runtime, penv, content, y, self, function(key, label, low, high, step, value, at)
                y = at; liveSlider(key, label, low, high, step, value); return y
            end)
            y = ns.PhotoToolsUI.Names(runtime, penv, content, y, self)
            section("NEXT CAMERA ENTRY")
            W.Toggle(penv, content, "Temporary photo quality", 0, y, 310, function() return db.camera.photoEnabled end,
                function(v) db.camera.photoEnabled = v end); y = y - 46
            W.Slider(penv, content, "Photo quality level", 0, y, 1, 10, 1, function() return db.camera.photoLevel end,
                function(v) db.camera.photoLevel = v; return true end, nil, 310); y = y - 70
            text("Photo quality takes effect on your next entry. Exit restores it. Your regular quality choices stay unchanged.", 70)
        elseif self.tab == "Pose" or self.tab == "Capture" then
            y = ns.PhotoToolsUI.Build(runtime, penv, content, self.tab, self)
            if self.tab == "Capture" then
                if staged then y = ns.PortraitControls.Capture(runtime, penv, content, y, self) end
                y = ns.PhotoAdvancedUI.Capture(runtime, penv, content, y, self)
            end
        else
            text("Save styling without native graphics values. Native lighting always starts from your current scene.", 54)
            self.name = self.name or "My photo look"
            W.Edit(penv, content, self.name, 0, y, 310, function(name) self.name = name end, 32); y = y - 38
            W.Button(penv, content, "Save / replace look", 0, y, 310, function()
                -- Read the visible field even if the user has not pressed Enter.
                for _, f in ipairs(pool.frames.EditBox or {}) do if f:IsShown() then self.name = f:GetText(); break end end
                editor.Save(self.name); self.Build()
            end); y = y - 48
            for _, name in ipairs(ns.Value.Keys(db.camera.editor.saved)) do
                local selected = name
                W.Button(penv, content, name, 0, y, 224, function() editor.Load(selected); self.Build() end)
                W.Button(penv, content, "Delete", 232, y, 78, function() editor.Delete(selected); self.Build() end); y = y - 40
            end
            y = y - 12; section("SHARE A LOOK")
            local transfer = W.Edit(penv, content, ns.PhotoConfig.Export(db.camera.editor.look), 0, y, 310, function() end, 512)
            transfer:SetScript("OnEditFocusGained", function(s) s:HighlightText() end); y = y - 40
            W.Button(penv, content, "Import pasted photo look", 0, y, 310, function() editor.Import(transfer:GetText()); self.Build() end); y = y - 48
            text("Click the field and copy to share, or paste a look and Import. No scripts are accepted.", 52)
            y = ns.PhotoAdvancedUI.Saved(runtime, penv, content, y, self)
        end
        self.contentHeight = -y + 16; content:SetHeight(self.contentHeight)
        if resetScroll then scroll:SetVerticalScroll(0) end
        self.Layout(); self.Refresh(); self.building = false
    end
    function self.Refresh()
        if not runtime.portrait.active and (self.tab == "Light" or self.tab == "Frame") and not self.building and not self.dragging
            and not preview.Pending() and not runtime.cameraActions.orbit and not runtime.cameraActions.busy and self.panel:IsVisible() then self.Build(); return end
        local seq, pose = runtime.captureSequence, runtime.photoTools
        local extra = self.tab == "Capture" and (seq.state .. (seq.total and " | " .. seq.completed .. " / " .. seq.total .. " captured" or ""))
            or self.tab == "Pose" and ns.PhotoToolsUI.Status(pose.status)
        if self.tab == "Frame" then extra = runtime.cameraActions.status ~= "READY" and runtime.cameraActions.status or nil
        elseif self.tab == "Capture" and runtime.output.error then extra = ns.Product.Message(runtime.output.error)
        elseif self.tab == "Saved" then extra = runtime.photoComposition.status end
        self.status:SetText(self.notice or runtime.portrait.active and runtime.portrait.status or extra or preview.error and ns.Product.Message(preview.error) or preview.Pending() and "Updating live preview..." or editor.status)
        self.compare.label:SetText(editor.before and "Show After" or "Show Before")
        if editor.busy and not preview.busy then self.compare:Disable() else self.compare:Enable() end
        positionMarker()
    end
    runtime.portrait.Refresh = function()
        if not self.building and not self.dragging and self.panel:IsVisible() and not runtime.portrait.busy then self.Build()
        else self.Refresh() end
    end
    editor.Refresh = self.Refresh
    preview.Refresh = self.Refresh
    runtime.photoTools.Refresh = self.Refresh
    runtime.cameraActions.Refresh = self.Refresh
    runtime.output.Refresh = self.Refresh
    runtime.photoComposition.Refresh = self.Refresh
    composition.root:HookScript("OnHide", function() self.dragging = nil end)
    self.Build(true)
    return self
end
