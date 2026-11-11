local _, ns = ...
local U, W = {}, ns.Widgets
ns.PhotoEditorUI = U
function U.New(runtime, composition)
    local env, editor, db, preview = runtime.reader.env, runtime.photoEditor, runtime.db, runtime.photoPreview
    local style = ns.PhotoStyle
    local self = { tab = "Frame", cameraPage = "Position", lookPage = "Color", glowPage = "Shape",
        actorTab = "Poses", poseTool = "Quick picks", transformPage = "Place", lightPage = "Rig", framingTool = "Guides",
        worldLightPage = "Tone", worldPoseTab = "All emotes", capturePage = "Timer", savedPage = "Looks", precision = false, sliders = {}, drafts = {} }
    local panel = env.CreateFrame("Frame", nil, composition.root); self.panel = panel
    panel:SetSize(360, 640); panel:SetPoint("TOPRIGHT", composition.root, "TOPRIGHT", -24, -24)
    W.Fill(panel, W.colors.bg); local edges = W.Border(panel); W.Window(env, panel, 29, 201)
    W.Decoration(W.Art(panel,"panel-midnight",1,-1,358,44,.62,"BORDER"))
    W.Art(panel, "logo", 10, -9, 25, 25)
    W.Text(panel, "Photo Studio", 42, -11, 125, 18)
    W.Rule(panel, 0, -45, 360)
    local world = style.Tab(env, panel, "World Photo", 164, -7, 86, function()
        local ok, why = runtime.portrait.World()
        self.notice = not ok and why or nil
        if ok then self.tab, self.cameraPage = "Frame", "Position" end
        self.Build(true)
    end)
    local portrait = style.Tab(env, panel, "Portrait Stage", 251, -7, 103, function()
        local ok, why = runtime.portrait.Enter()
        self.notice = not ok and why or nil
        if ok then self.tab, self.cameraPage = "Frame", "Position" end
        self.Build(true)
    end)
    local rail = env.CreateFrame("Frame", nil, panel)
    rail:SetPoint("TOPLEFT",panel,"TOPLEFT",1,-46); rail:SetWidth(40)
    W.Fill(rail,W.colors.sidebar)
    local tabs = {}
    for i, tool in ipairs({{"Frame","Camera","ui-camera"},{"Look","Look","ui-effects"},{"Light","Light","natural"},
        {"Pose","Pose","ui-accessibility"},{"Capture","Capture","ui-export"},{"Saved","Saved","ui-presets"}}) do
        local key=tool[1]
        tabs[key]=style.Tab(env,rail,tool[2],0,-5-(i-1)*54,40,function()
            runtime.cameraActions.StopOrbit(); self.notice=nil; self.tab=key; self.Build(true)
        end,tool[3])
    end
    local title=W.Text(panel,"",48,-58,195,21)
    local function history(label, redo, x)
        local b=W.Button(env,panel,label,x,-53,48,function() editor.Undo(redo); self.Build() end,nil,"quiet")
        b.label:ClearAllPoints(); b.label:SetPoint("TOPLEFT",b,"TOPLEFT",0,-7)
        b.label:SetWidth(48); b.label:SetJustifyH("CENTER"); b.label:SetWordWrap(false)
        return b
    end
    local undo, redo = history("Undo",false,253), history("Redo",true,305)
    local function pages(labels, field)
        local row=env.CreateFrame("Frame",nil,panel)
        row:SetSize(310,30); row:SetPoint("TOPLEFT",panel,"TOPLEFT",44,-89)
        return { row=row, field=field, buttons=style.Pages(env,row,labels,function(page)
            self[field]=page
            if field=="worldPoseTab" then self.worldEmotePage=1 end
            if field=="actorTab" and page=="Outfits" then runtime.portrait.wardrobe.Refresh() end
            self.notice=nil; self.Build(true)
        end) }
    end
    local groups={
        camera=pages({"Position","Framing","Visibility"},"cameraPage"),
        stageCamera=pages({"Position","Lens","Framing","Visibility"},"cameraPage"),
        actors=pages({"Cast","Transform","Poses","Outfits","Effects"},"actorTab"),
        worldPose=pages({"All emotes","Favorites"},"worldPoseTab"),
        stageLight=pages({"Rig","Direction","Color"},"lightPage"),
        worldLight=pages({"Tone","Detail","Originals"},"worldLightPage"),
        look=pages({"Color","Vignette","Glow","Film"},"lookPage"),
        capture=pages({"Timer","Output","Combat"},"capturePage"),
        stageCapture=pages({"Timer","Output","Pair","Combat"},"capturePage"),
        saved=pages({"Looks","Compositions","Share"},"savedPage"),
        stageSaved=pages({"Scenes","Lights"},"stageSavePage"),
    }
    self.stageSavePage="Scenes"
    local scroll = env.CreateFrame("ScrollFrame", nil, panel); self.scroll = scroll
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -198); scroll:SetSize(310, 402); scroll:EnableMouseWheel(true)
    local content = env.CreateFrame("Frame", nil, scroll); content:SetSize(310, 1); scroll:SetScrollChild(content); content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    local pool = W.CreatePool(env, content); local penv = pool.env
    function self.ClearFocus()
        for _, field in ipairs(pool.frames.EditBox or {}) do field:ClearFocus() end
    end
    composition.root:HookScript("OnHide", function() self.ClearFocus(); editor.EndLookEdit(); runtime.cameraActions.StopOrbit(); runtime.portrait.collection.Cancel() end)
    local scrollbar = env.CreateFrame("Slider", nil, panel); self.scrollbar = scrollbar
    scrollbar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -198); scrollbar:SetSize(4, 402)
    scrollbar:SetOrientation("VERTICAL"); scrollbar:SetValueStep(20); W.Fill(scrollbar, W.colors.sidebar)
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY"); thumb:SetSize(4, 24); thumb:SetColorTexture(unpack(W.colors.accent)); scrollbar:SetThumbTexture(thumb)
    scrollbar:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
    scroll:SetScript("OnMouseWheel", function(_, delta) scrollbar:SetValue(scroll:GetVerticalScroll() - delta * 54) end)
    local footer = env.CreateFrame("Frame", nil, panel); self.footer = footer
    footer:SetSize(310, 60); footer:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 44, 8)
    W.Rule(footer, 0, 0, 310)
    self.compare = W.Button(env, footer, "Before / After", 0, -6, 144, function()
        self.notice = nil
        if preview.error == "SHOW_AFTER_FIRST" then preview.Begin() end
        preview.Finish(editor.Compare)
    end)
    local resetLook = W.Button(env, footer, "Reset photo look", 155, -6, 152, function() editor.Recipe("neutral"); self.Build() end,nil,"quiet")
    local restoreLight = W.Button(env, footer, "Restore lighting", 155, -6, 152, function()
        preview.Finish(function()
            local reported = false
            local function result(ok, why)
                if reported then return end
                reported = true
                self.notice = not ok and ns.Product.Message(why) or nil
                if ok then preview.Begin() end
                self.Refresh()
            end
            local ok, why = editor.Restore(result)
            if not ok then result(nil, why) end
        end)
    end, "Return lighting to the values captured before your photo edits.", "quiet")
    self.status = W.Text(footer, "", 0, -53, 332, 12, W.colors.muted)
    local marker = env.CreateFrame("Button", nil, composition.root); self.marker = marker
    marker:SetSize(38, 38); marker:EnableMouse(true); marker:SetMovable(true); marker:SetClampedToScreen(true); marker:RegisterForDrag("LeftButton")
    W.Border(marker, W.colors.accent); W.Text(marker, "+", 12, -8, 24, 20, W.colors.accent)
    W.Tip(env, marker, "Drag to place the glow accent. Hidden in clean view and screenshots.")
    marker:SetScript("OnDragStart", function() if runtime.camera.CanCompose() then marker:StartMoving() end end)
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
        if self.tab == "Look" and self.lookPage == "Glow" and self.glowPage == "Shape"
            and look.glow > 0 and not editor.before then marker:Show() else marker:Hide() end
    end
    function self.Layout()
        local h = math.min(640, env.UIParent:GetHeight() - 154)
        if self.tab == "Look" and self.compactLooks ~= (h < 550) and not self.building then
            self.Build()
            return
        end
        local scale = math.min(1, math.max(.4, (env.UIParent:GetWidth() - 32) / 360), math.max(.4, h / 480))
        panel:SetScale(scale); h = math.max(480, h / scale)
        local hasActions = self.tab == "Look" or (self.tab == "Light" and not runtime.portrait.active)
        local top = self.activePages and -126 or -96
        local footerHeight = hasActions and 62 or 32
        if self.contentHeight then
            h = math.min(h, math.max(390, self.contentHeight - top + footerHeight + 16))
        end
        panel:SetHeight(h); edges[3]:SetHeight(h); edges[4]:SetHeight(h); rail:SetHeight(h-47)
        local viewport = h + top - footerHeight - 16
        scroll:ClearAllPoints(); scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 44, top)
        scrollbar:ClearAllPoints(); scrollbar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, top)
        footer:SetHeight(footerHeight)
        self.status:ClearAllPoints(); self.status:SetWidth(310)
        self.status:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, hasActions and -40 or -6)
        if hasActions then self.compare:Show() else self.compare:Hide() end
        if self.tab == "Look" then resetLook:Show() else resetLook:Hide() end
        if self.tab == "Light" and not runtime.portrait.active then restoreLight:Show() else restoreLight:Hide() end
        scroll:SetHeight(viewport); scrollbar:SetHeight(viewport)
        scrollbar:SetMinMaxValues(0, math.max(0, (self.contentHeight or 1) - scroll:GetHeight()))
        scrollbar:SetValue(math.min(scroll:GetVerticalScroll(), math.max(0, (self.contentHeight or 1) - scroll:GetHeight())))
        if self.contentHeight and self.contentHeight > viewport then scrollbar:Show() else scrollbar:Hide() end
        positionMarker()
    end
    local function collectionVisible()
        return runtime.portrait.active and self.tab == "Pose" and self.actorTab == "Outfits" and self.wardrobeTab == "Collection"
    end
    function self.Build(resetScroll)
        if not collectionVisible() and runtime.portrait.collection.busy then runtime.portrait.collection.Cancel() end
        self.building = true
        self.compactLooks = env.UIParent:GetHeight() - 154 < 550
        editor.EndLookEdit()
        self.ClearFocus()
        self.dragging = nil
        self.RefreshNames, self.RefreshGallery, self.RefreshPlacement, self.RefreshStageMap = nil, nil, nil, nil
        self.RefreshWorldPose = nil
        pool.Reset(); self.sliders = {}
        local staged = runtime.portrait.active
        world.SetSelected(not staged); portrait.SetSelected(staged)
        title:SetText(({Frame="Camera", Look="Color & effects", Light=staged and "Model lighting" or "Scene lighting",
            Pose=staged and "Actors" or "World emotes", Capture="Capture", Saved="Library"})[self.tab])
        if self.tab=="Look" then undo:Show(); redo:Show() else undo:Hide(); redo:Hide() end
        if self.capturePage=="Pair" and not staged then self.capturePage="Timer" end
        self.activePages = ({Frame=staged and groups.stageCamera or groups.camera, Pose=staged and groups.actors or groups.worldPose,
            Light=staged and groups.stageLight or groups.worldLight, Look=groups.look, Capture=staged and groups.stageCapture or groups.capture,
            Saved=staged and groups.stageSaved or groups.saved})[self.tab]
        for _, group in pairs(groups) do
            if group==self.activePages then
                group.row:Show()
                for label,b in pairs(group.buttons) do b.SetSelected(self[group.field]==label) end
            else group.row:Hide() end
        end
        for label, button in pairs(tabs) do
            button.SetSelected(self.tab == label)
            button.label:SetText(label == "Frame" and "Camera" or staged and label == "Pose" and "Actors" or label)
        end
        local y = 0
        local function text(value, height)
            W.Text(content, value, 0, y, 310, 12, W.colors.muted); y = y - (height or 42)
        end
        local function section(label) W.Section(content, label, 0, y, 310); y = y - 40 end
        local function lookSlider(key, label, step, unit)
            local range = ns.PhotoConfig.Ranges[key]
            self.sliders[key] = W.Slider(penv, content, label, 0, y, range[1], range[2], step or .01,
                function() return db.camera.editor.look[key] end,
                function(n) local ok = editor.Set(key, n); positionMarker(); return ok end, nil, 310, unit)
            W.Script(self.sliders[key], "OnMouseDown", editor.BeginLookEdit)
            W.Script(self.sliders[key], "OnMouseUp", function() editor.EndLookEdit(); self.Refresh() end)
            y = y - (unit and 36 or 68)
        end
        local function liveSlider(key, label, minimum, maximum, step, current, unit, illustration)
            local requested = preview.pending[key] or (preview.currentKey == key and preview.currentValue)
            local draft = math.max(minimum, math.min(maximum, requested or current))
            local help
            if not illustration then help = "Drag for live preview, or type a value and press Enter." end
            local slider = W.Slider(penv, content, label, 0, y, minimum, maximum, step, function() return draft end,
                function(n)
                    local ok, why = preview.Queue(key, n)
                    if ok then draft = n
                    else self.notice = ns.Product.Message(why); self.status:SetText(self.notice) end
                    return ok
                end, help, 310, unit, nil, illustration)
            local function begin() self.notice = nil; preview.Begin() end
            W.Script(slider, "OnMouseDown", function() self.dragging = slider; begin() end)
            W.Script(slider, "OnMouseUp", function() self.dragging = nil; self.Refresh() end)
            local entered = slider.edit:GetScript("OnEnterPressed")
            W.Script(slider.edit, "OnEnterPressed", function(s) begin(); entered(s) end)
            self.sliders[key] = slider; y = y - (unit and 36 or 68)
        end
        if self.tab == "Frame" and self.cameraPage == "Visibility" then
            y = ns.PhotoToolsUI.Names(runtime, penv, content, y, self)
        elseif staged and (self.tab == "Light" or self.tab == "Frame" or self.tab == "Pose" or self.tab == "Saved") then
            y = ns.PortraitControls.Build(runtime, penv, content, self.tab, self, y)
        elseif self.tab == "Look" then
            y = style.Look(runtime, penv, content, self)
        elseif self.tab == "Light" then
            y = ns.WorldLightUI.Build(runtime, content, self.worldLightPage, function(spec, value, at)
                y = at
                liveSlider(spec.key, spec.label, 0, spec.maximum, spec.step, value, nil, spec.image)
            end)
        elseif self.tab == "Frame" and self.cameraPage == "Position" then
            y = ns.PhotoAdvancedUI.Position(runtime, penv, content, y, self)
            local range = ns.Framing.Range(runtime.reader); local seen = ns.ReadOnly.Read(runtime.reader, "cameraFov")
            if range and ns.Planner.SafeObservation(seen) and ns.Value.Number(seen.raw) then
                liveSlider("cameraFov", "Field of view", range.min, range.max, .1, ns.Value.Number(seen.raw), "°")
            else text("Field of view unavailable; framing guides remain available.", 52) end
            W.Button(penv, content, "Restore field of view", 0, y, 310, function()
                preview.Finish(function()
                    local ok, why = runtime.camera.RestoreFOV(function(done, code)
                        self.notice = not done and ns.Product.Message(code) or nil; self.Refresh()
                    end)
                    if not ok then self.notice = ns.Product.Message(why); self.Refresh() end
                    return ok, why
                end)
            end); y = y - 36
        elseif self.tab == "Frame" then
            y=ns.StageLayout.Choices(penv,content,y,{"Guides","Offset","Quality"},self.framingTool,function(tool)
                self.framingTool=tool; self.Build(true)
            end)
            if self.framingTool=="Guides" then
                W.Toggle(penv, content, "Rule of thirds", 0, y, 310, function() return db.camera.thirds end,
                    function(v) db.camera.thirds = v; composition.Show() end); y = y - 48
                text("Frame guides disappear in clean view. Letterbox bars below remain in the image.", 52)
                for i, choice in ipairs({ { "none", "No guide" }, { "wide", "16:9" }, { "cinema", "2.39:1" }, { "square", "Square" } }) do
                    local id = choice[1]
                    local b = W.Button(penv, content, choice[2], (i - 1) % 2 * 160, y - math.floor((i - 1) / 2) * 40, 150, function()
                        db.camera.aspect = id; composition.Show(); self.Build()
                    end); b.SetSelected(db.camera.aspect == id)
                end
                y = y - 80; lookSlider("letterbox", "Letterbox height", .01, "")
            elseif self.framingTool=="Offset" then
                y = ns.PhotoAdvancedUI.Frame(runtime, penv, content, y, self, function(key, label, low, high, step, value, at)
                    y = at; liveSlider(key, label, low, high, step, value, ""); return y
                end)
            else
                section("NEXT CAMERA ENTRY")
                W.Toggle(penv, content, "Temporary photo quality", 0, y, 310, function() return db.camera.photoEnabled end,
                    function(v) db.camera.photoEnabled = v end); y = y - 46
                W.Slider(penv, content, "Photo quality level", 0, y, 1, 10, 1, function() return db.camera.photoLevel end,
                    function(v) db.camera.photoLevel = v; return true end, nil, 310); y = y - 70
                text("Photo quality takes effect on your next entry. Exit restores it. Your regular quality choices stay unchanged.", 70)
            end
        elseif self.tab == "Capture" and self.capturePage == "Output" then
            y = ns.PhotoAdvancedUI.Capture(runtime, penv, content, y, self)
        elseif self.tab == "Capture" and self.capturePage == "Pair" then
            y = ns.PortraitControls.Capture(runtime, penv, content, y, self)
        elseif self.tab == "Pose" then
            y = ns.WorldPoseUI.Build(runtime, penv, content, self)
        elseif self.tab == "Capture" then
            y = ns.PhotoToolsUI.Capture(runtime, penv, content, self)
        elseif self.savedPage == "Compositions" then
            y = ns.PhotoAdvancedUI.Saved(runtime, penv, content, y, self)
        elseif self.savedPage == "Looks" then
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
        else
            section("SHARE A LOOK")
            local transfer = W.Edit(penv, content, ns.PhotoConfig.Export(db.camera.editor.look), 0, y, 310, function() end, 512)
            transfer:SetScript("OnEditFocusGained", function(s) s:HighlightText() end); y = y - 40
            W.Button(penv, content, "Import pasted photo look", 0, y, 310, function() editor.Import(transfer:GetText()); self.Build() end); y = y - 48
            text("Click the field and copy to share, or paste a look and Import. No scripts are accepted.", 52)
        end
        self.contentHeight = -y + 16; content:SetHeight(self.contentHeight)
        if resetScroll then scroll:SetVerticalScroll(0) end
        self.Layout(); self.Refresh(); self.building = false
    end
    function self.Refresh()
        if not runtime.portrait.active and (self.tab == "Light" or self.tab == "Frame") and not self.building and not self.dragging
            and not preview.Pending() and not runtime.cameraActions.orbit and not runtime.cameraActions.busy and self.panel:IsVisible() then
            -- A verified drag can finish while the photographer types the next adjustment.
            local focus = self.tab == "Light" and ns.ReadOnly.Call(runtime.reader, env.GetCurrentKeyBoardFocus)
            local editing = false
            if focus and focus[1] then
                for _, slider in pairs(self.sliders) do
                    if slider.edit == focus[1] then editing = true; break end
                end
            end
            if not editing then self.Build(); return end
        end
        if self.RefreshStageMap then self.RefreshStageMap() end
        local seq = runtime.captureSequence
        local extra = self.tab == "Capture" and (seq.state .. (seq.total and " | " .. seq.completed .. " / " .. seq.total .. " captured" or ""))
            or self.RefreshWorldPose and self.RefreshWorldPose()
        if self.tab == "Frame" then extra = runtime.cameraActions.status ~= "READY" and ns.Product.Message(runtime.cameraActions.status) or nil
        elseif self.tab == "Capture" and runtime.output.error then extra = ns.Product.Message(runtime.output.error)
        elseif self.tab == "Saved" then extra = runtime.photoComposition.status end
        local message = self.notice or runtime.portrait.active and self.tab ~= "Look" and runtime.portrait.status or extra or preview.error and ns.Product.Message(preview.error) or preview.Pending() and "Updating live preview..." or editor.status
        self.status:SetText(message ~= "READY" and message or "")
        if self.tab=="Look" then
            for i,b in ipairs({undo,redo}) do
                if #(i==1 and editor.undo or editor.redo)>0 then b:Enable(); b:SetAlpha(1)
                else b:Disable(); b:SetAlpha(.4) end
            end
            if self.RefreshGallery then self.RefreshGallery() end
            if self.RefreshPlacement then self.RefreshPlacement() end
        end
        self.compare.label:SetText(editor.before and "Show After" or "Show Before")
        if editor.busy and not preview.busy then self.compare:Disable() else self.compare:Enable() end
        if db.camera.editor.session or preview.Pending() then restoreLight:Enable(); restoreLight:SetAlpha(1)
        else restoreLight:Disable(); restoreLight:SetAlpha(.65) end
        positionMarker()
    end
    runtime.portrait.Refresh = function()
        if not self.building and not self.dragging and self.panel:IsVisible() and not runtime.portrait.busy then self.Build()
        else self.Refresh() end
    end
    runtime.portrait.collection.RefreshUI = function()
        if collectionVisible() and not self.building and not self.dragging and self.panel:IsVisible() then
            local focus = ns.ReadOnly.Call(runtime.reader, env.GetCurrentKeyBoardFocus)
            -- A completed background read must not erase an unsubmitted search.
            if focus and focus[1] then self.Refresh() else self.Build() end
        end
    end
    editor.Refresh = self.Refresh
    runtime.camera.NamesChanged = function() if self.RefreshNames then self.RefreshNames() end end
    preview.Refresh = self.Refresh
    runtime.photoTools.Refresh = self.Refresh
    runtime.cameraActions.Refresh = self.Refresh
    runtime.output.Refresh = self.Refresh
    runtime.photoComposition.Refresh = self.Refresh
    composition.root:HookScript("OnHide", function() self.dragging = nil end)
    self.Build(true)
    return self
end
