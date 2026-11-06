local _, ns = ...
local S, W = {}, ns.Widgets
ns.Studio = S
local pages = { "Visual Modes", "Graphics Quality", "Colors and Effects", "Audio", "Personal Presets", "Accessibility", "Diagnostics and Recovery" }
function S.New(runtime)
    local env, db, product = runtime.reader.env, runtime.db, runtime.product
    local ui = { page = 1, edited = "nightVision", acknowledged = false, pageFrames = {} }
    if not db or not env.UIParent then return ui end
    local window = env.CreateFrame("Frame", "LumenShiftStudio", env.UIParent)
    ui.window = window
    window:SetSize(850, 640); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true); window:SetMovable(true); window:EnableMouse(true); window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) if not product.IsCombat() then self:StartMoving() end end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:SetScript("OnHide", function(self) if self.lumenFade then self.lumenFade:Stop() end end)
    ui.background = W.Fill(window, W.colors.bg)
    local logo = window:CreateTexture(nil, "ARTWORK"); logo:SetSize(40, 40); logo:SetPoint("TOPLEFT", 20, -14)
    logo:SetTexture("Interface/AddOns/LumenShift/Media/logo.tga")
    W.Text(window, "L U M E N S H I F T", 72, -17, 540, 19, W.colors.accent)
    W.Text(window, "NORTHERN LIGHTS LABS  /  VISUAL STUDIO", 73, -42, 570, 10, W.colors.muted)
    ui.status = W.Text(window, "", 20, -70, 800, 12)
    ui.footer = W.Text(window, "", 20, -606, 810, 12, W.colors.muted)
    W.Button(env, window, "Close", 766, -18, 66, function() window:Hide() end)
    local scroll = env.CreateFrame("ScrollFrame", nil, window)
    ui.scroll = scroll
    scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 230, -112); scroll:SetSize(585, 476); scroll:EnableMouseWheel(true)
    local scrollBar = env.CreateFrame("Slider", nil, window)
    scrollBar:SetPoint("TOPLEFT", window, "TOPLEFT", 824, -112); scrollBar:SetSize(10, 476)
    scrollBar:SetOrientation("VERTICAL"); scrollBar:SetMinMaxValues(0, 1); scrollBar:SetValueStep(24)
    W.Fill(scrollBar)
    local thumb = scrollBar:CreateTexture(nil, "OVERLAY"); thumb:SetSize(10, 38); thumb:SetColorTexture(unpack(W.colors.accent)); scrollBar:SetThumbTexture(thumb)
    scrollBar:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        scrollBar:SetValue(math.max(0, math.min(ui.scrollMaximum or 0, scroll:GetVerticalScroll() - delta * 36)))
    end)
    local function cfg() return db.config.studio end
    local function mode() return cfg().modes[ui.edited] end
    local function update(fn) return product.Update(fn) end
    local function emit(code) if code then ns.Diagnostics.Emit(runtime, "LumenShift: " .. code) end end
    local function modeSet(key, value) return update(function(copy) copy.studio.modes[ui.edited][key] = value end) end
    local function controls(parent, widgetEnv)
        local env = widgetEnv
        local y = -8
        local function line(text, height, color)
            W.Text(parent, text, 0, y, 550, 13, color); y = y - (height or 48)
        end
        local function button(label, fn, tip)
            local b = W.Button(env, parent, label, 0, y, 540, fn, tip); y = y - 40; return b
        end
        local function toggle(label, get, set, tip)
            W.Toggle(env, parent, label, 0, y, 540, get, set, tip); y = y - 40
        end
        local function slider(label, low, high, step, get, set, tip)
            W.Slider(env, parent, label, 0, y, low, high, step, get, set, tip); y = y - 66
        end
        return line, button, toggle, slider, function() return -y + 20 end
    end
    local function selectEditor(parent, y, env)
        for i, id in ipairs(ns.StudioConfig.Order) do
            local modeID = id
            W.Button(env, parent, (ui.edited == id and "* " or "") .. ns.StudioConfig.Labels[id],
                ((i - 1) % 3) * 182, y - math.floor((i - 1) / 3) * 38, 174,
                function() ui.edited = modeID; ui.BuildPage() end, ns.StudioConfig.Descriptions[id])
        end
    end
    function ui.Refresh()
        local status = runtime.engine.Status()
        local current = ns.ReadOnly.Read(runtime.reader, "Brightness")
        ui.status:SetText("MODE  " .. ns.StudioConfig.Labels[product.active] .. "     BRIGHTNESS  " .. (current.raw or "unavailable")
            .. "     ORIGINAL  " .. (status.original or "none") .. "     " .. (product.busy and "VERIFYING" or status.state))
        ui.footer:SetText(product.lastError or (status.error and "Recovery: " .. status.error)
            or (cfg().enabled and "Ready. Modes never reapply at login. Quality settings remain independent." or "Setup required. No mode has been applied."))
        if ui.radial then ui.radial.Refresh() end
    end
    function ui.BuildPage()
        -- Reuse a bounded page pool; release child references by hiding the old content.
        -- Page creation is only on deliberate navigation, never every frame or slider tick.
        for _, page in pairs(ui.pageFrames) do page:Hide() end
        local old = ui.pageFrames[ui.page]
        if old then
            -- Frames cannot be destroyed in WoW. Reuse pooled widgets on rebuild.
            -- The page's controls read live values; editor changes select a separate fixed pool.
            old:Hide()
        end
        local key = ui.page .. ":" .. ((ui.page == 1 or ui.page == 3) and ui.edited or "shared")
        ui.cache = ui.cache or {}
        local cached = ui.cache[key]
        local parent = cached or env.CreateFrame("Frame", nil, scroll)
        parent.lumenInvalid = false
        parent.pool = parent.pool or W.CreatePool(env, parent)
        parent.pool.Reset()
        local env = parent.pool.env
        parent:SetSize(570, 1000); scroll:SetScrollChild(parent)
        parent:ClearAllPoints(); parent:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
        ui.pageFrames[ui.page] = parent; ui.cache[key] = parent
        local line, button, toggle, slider, height = controls(parent, env)
        local pageHeight
        if ui.page == 1 then
            line("Visual modes", 30, W.colors.accent)
            line("Set up once, then switch from the wheel or a key binding. Original Brightness is captured before ownership; save recovery notes outside the game.", 70)
            toggle("I understand recovery data can be lost in a crash", function() return ui.acknowledged end,
                function(value) ui.acknowledged = value end)
            button("Enable visual switching", function() product.Enable(ui.acknowledged) end)
            toggle("Experimental Brightness targets beyond 75", function() return cfg().experimentalBrightness end,
                function(value) update(function(copy) copy.studio.experimentalBrightness = value end) end,
                "Only the 45 to 75 to 45 path has native evidence. Other 0-100 targets follow the source UI domain and remain experimental.")
            line("Editing a slider changes a saved mode. Apply is a separate action. Contrast remains unavailable until its native round trip is validated.", 62)
            selectEditor(parent, -300, env)
            local body = env.CreateFrame("Frame", nil, parent); body:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -390); body:SetSize(560, 280)
            W.Text(body, ns.StudioConfig.Labels[ui.edited] .. "  /  " .. ns.StudioConfig.Descriptions[ui.edited], 0, 0, 550, 13)
            if ui.edited ~= "natural" then
                local selected = ui.edited
                W.Slider(env, body, "Brightness target (experimental except 75)", 0, -55, 0, 100, 1,
                    function() return cfg().modes[selected].brightness end,
                    function(value) return update(function(copy) copy.studio.modes[selected].brightness = value end) end)
                W.Text(body, "Contrast target: " .. mode().contrast .. " — disabled; native validation required", 0, -119, 550, 13, W.colors.muted)
            else W.Text(body, "Restores your exact captured original. Leaves quality selection alone.", 0, -55, 550, 13) end
            button = W.Button(env, body, "Apply " .. ns.StudioConfig.Labels[ui.edited], 0, -160, 260, function() product.Select(ui.edited) end)
            W.Button(env, body, "Reset this mode's saved settings", 272, -160, 275, function()
                local selected = ui.edited
                update(function(copy) copy.studio.modes[selected] = ns.StudioConfig.Defaults().modes[selected] end)
                ui.Invalidate(1); ui.Invalidate(3); ui.BuildPage()
            end)
            W.Button(env, body, "Disable controls (restore Natural first)", 0, -208, 547, function() product.Disable() end)
            pageHeight = 660
        elseif ui.page == 2 then
            line("Independent graphics quality", 30, W.colors.accent)
            line("Quality presets cannot safely apply yet: native ranges, dependent settings and exact restoration are not established. Readable does not mean writable or visually effective.", 78)
            for _, id in ipairs({ "currentBaseline", "balanced", "vista", "performance" }) do
                local profileID = id
                local b = button(ns.Quality.Profiles[id] .. (id == "currentBaseline" and " — current" or " — validation required"), function()
                    local ok, code = ns.Quality.Select(db, profileID); if not ok then emit(code) end; ui.Refresh()
                end, ns.Quality.Descriptions[id])
                if id ~= "currentBaseline" then b.label:SetTextColor(unpack(W.colors.muted)) end
            end
            button("Refresh read-only capability scan", function() ui.Invalidate(2); ui.BuildPage() end)
            button("Print detailed read-only scan to chat", function()
                for _, text in ipairs(ns.Diagnostics.QualityLines(runtime)) do ns.Diagnostics.Emit(runtime, text) end
            end)
            for _, row in ipairs(ns.Quality.Scan(runtime.reader)) do
                line(row.group .. " / " .. row.label .. ": " .. (row.observation.raw or row.observation.code)
                    .. "\n" .. row.dependency .. ". Disabled pending native validation.", 62, W.colors.muted)
            end
        elseif ui.page == 3 then
            line("Colors and effects", 30, W.colors.accent)
            line("These are noninteractive UI overlays, not world shaders or engine color grading. They sit below ordinary HUD frames, but compatibility with custom UIs still needs testing.", 78)
            toggle("Enable optional presentation effects", function() return cfg().effects end,
                function(value) update(function(copy) copy.studio.effects = value end); product.RefreshPresentation() end)
            toggle("Screenshot letterbox (automatically hidden in combat)", function() return cfg().screenshot end,
                function(value) update(function(copy) copy.studio.screenshot = value end); product.RefreshPresentation() end)
            selectEditor(parent, -200, env)
            local body = env.CreateFrame("Frame", nil, parent); body:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -295); body:SetSize(560, 540)
            local selected = ui.edited
            local function settings() return cfg().modes[selected] end
            W.Toggle(env, body, "Tint for " .. ns.StudioConfig.Labels[selected], 0, 0, 540,
                function() return settings().tintEnabled end, function(value)
                    update(function(copy) copy.studio.modes[selected].tintEnabled = value end)
                end)
            local controls = { { "Tint opacity", "opacity", 0.12 }, { "Vignette", "vignette", 0.15 }, { "Letterbox height", "letterbox", 0.12 } }
            for i, item in ipairs(controls) do
                local field = item[2]
                W.Slider(env, body, item[1], 0, -i * 66, 0, item[3], 0.01, function() return settings()[field] end,
                    function(value) return update(function(copy) copy.studio.modes[selected][field] = value end) end)
            end
            for i, color in ipairs({ "r", "g", "b" }) do
                local channel = color
                W.Slider(env, body, ({ "Red", "Green", "Blue" })[i], 0, -(i + 3) * 66, 0, 1, 0.01,
                    function() return settings().tint[channel] end,
                    function(value) return update(function(copy) copy.studio.modes[selected].tint[channel] = value end) end)
            end
            W.Button(env, body, "Apply saved effects to the active mode", 0, -475, 540, function() product.RefreshPresentation() end)
            pageHeight = 830
        elseif ui.page == 4 then
            line("Original electronic cues", 30, W.colors.accent)
            line("Short original on/off cues play only after successful mode verification. Uses the game's SFX channel; LumenShift never changes global sound settings.", 70)
            toggle("Enable activation / deactivation sounds", function() return db.config.preferences.sound end,
                function(value) update(function(copy) copy.preferences.sound = value end); if not value then runtime.audio.Stop() end end)
            button("Soft cue level", function() update(function(copy) copy.studio.audioLevel = "soft" end) end,
                "A quieter original file, not a global volume change.")
            button("Normal cue level", function() update(function(copy) copy.studio.audioLevel = "normal" end) end)
            button("Preview activation cue", function() local _, code = runtime.audio.Play("on", db.config); emit(code) end)
            button("Preview deactivation cue", function() local _, code = runtime.audio.Play("off", db.config); emit(code) end)
            button("Stop current cue", function() runtime.audio.Stop() end)
            line("Muted by default. Client codec/channel behavior remains part of native acceptance. Missing or muted audio cannot alter graphics verification.", 65, W.colors.muted)
        elseif ui.page == 5 then
            line("Personal presets", 30, W.colors.accent)
            line("Save a variation of the currently edited visual mode. Presets contain validated numbers and toggles; they cannot introduce CVar names or executable code. Quality remains independent.", 78)
            local name = W.Edit(env, parent, "My " .. ns.StudioConfig.Labels[ui.edited], 0, -110, 540, function() end)
            W.Button(env, parent, "Save variation of " .. ns.StudioConfig.Labels[ui.edited], 0, -151, 540, function()
                product.SavePreset(name:GetText(), ui.edited); ui.Invalidate(5); ui.BuildPage()
            end)
            local y = -205
            for _, id in ipairs(ns.Value.Keys(cfg().presets)) do
                local presetID, preset = id, cfg().presets[id]
                W.Text(parent, preset.name .. " / " .. ns.StudioConfig.Labels[preset.mode], 0, y, 540, 14)
                local rename = W.Edit(env, parent, preset.name, 0, y - 27, 270, function(text)
                    if ns.StudioConfig.Name(text) then update(function(copy) copy.studio.presets[presetID].name = text end) end
                end)
                W.Button(env, parent, "Apply", 284, y - 27, 110, function() product.LoadPreset(presetID); ui.Invalidate(1); ui.Invalidate(3) end)
                W.Button(env, parent, "Delete", 406, y - 27, 130, function()
                    update(function(copy) copy.studio.presets[presetID] = nil end); ui.Invalidate(5); ui.BuildPage()
                end)
                y = y - 87
            end
            pageHeight = math.max(290, -y + 20)
        elseif ui.page == 6 then
            line("Accessibility and controls", 30, W.colors.accent)
            toggle("Reduced motion", function() return db.config.preferences.reducedMotion end,
                function(value) update(function(copy) copy.preferences.reducedMotion = value end) end)
            toggle("Menu fade animation", function() return db.config.preferences.animation end,
                function(value) update(function(copy) copy.preferences.animation = value end) end)
            toggle("High-contrast panel", function() return cfg().highContrast end,
                function(value) update(function(copy) copy.studio.highContrast = value end); ui.background:SetColorTexture(value and 0 or 0.035, value and 0 or 0.055, value and 0 or 0.08, 1) end)
            toggle("Show draggable launcher", function() return cfg().launcher.visible end,
                function(value) update(function(copy) copy.studio.launcher.visible = value end) end)
            slider("Studio scale", 0.75, 1.5, 0.05, function() return cfg().scale end,
                function(value) update(function(copy) copy.studio.scale = value end); ui.Size(); return true end)
            button("Reset launcher position", function() update(function(copy) copy.studio.launcher.x = 80; copy.studio.launcher.y = -160 end) end)
            line("Set keys in the game's Key Bindings > LumenShift: Toggle Night Vision, Open wheel, Open Studio. No key is assigned automatically.", 65)
            line("Wheel keyboard: 1–6 select; arrows/Tab navigate; Enter applies; Escape cancels. Click selection is supported. Hold/release selection stays unavailable until input-focus behavior is verified.", 85, W.colors.muted)
        elseif ui.page == 7 then
            line("Diagnostics and Recovery", 30, W.colors.accent)
            line("Natural restores a trusted current-session baseline. After reload or conflict, use an explicit recovery preview and confirm its displayed value. Never delete the journal to hide an error.", 78)
            button("Natural — restore current-session visual baseline", function() product.Select("natural") end)
            button("Restore My Brightness — preview only", function()
                runtime.engine.Prepare("restore"); ui.Invalidate(7); ui.BuildPage()
            end)
            local status = runtime.engine.Status()
            if status.token then
                local token = status.token
                button("Confirm displayed recovery card " .. token, function()
                    runtime.engine.Confirm(token); product.Observe(); ui.Invalidate(7); ui.BuildPage()
                end, "This is a real Brightness operation. Review the current and original values in the chat recovery card before confirming.")
            end
            button("Verify pending recovery (read only)", function() runtime.engine.Verify(); product.Observe(); ui.Invalidate(7); ui.BuildPage() end)
            button("Cancel preview (does not restore graphics)", function() runtime.engine.Cancel(); product.Observe(); ui.Invalidate(7); ui.BuildPage() end)
            button("Refresh diagnostic report", function() ui.Invalidate(7); ui.BuildPage() end)
            local report = table.concat(ns.Diagnostics.Lines(runtime), "\n")
            local box = W.Edit(env, parent, report, 0, -height(), 540, function() end)
            box:SetMultiLine(true); box:SetMaxLetters(12000); box:SetText(report); box:SetHeight(680)
            box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            W.Tip(env, box, "Click, Ctrl+A, Ctrl+C to copy the sanitized addon report. No character/account identifiers or saved-table dump.")
            pageHeight = height() + 700
        end
        parent:SetHeight(pageHeight or height())
        ui.scrollMaximum = math.max(0, parent:GetHeight() - 476)
        scrollBar:SetMinMaxValues(0, ui.scrollMaximum); scrollBar:SetValue(0)
        parent:Show(); ui.Refresh()
    end
    function ui.Invalidate(page)
        -- Existing pooled content is hidden before replacement; navigation itself is bounded.
        -- Rebuilding editable collections is limited below by a reusable widget pool.
        if ui.cache then for key, frame in pairs(ui.cache) do if key:match("^" .. page .. ":") then frame.lumenInvalid = true end end end
    end
    function ui.Size()
        local scale = math.min(cfg().scale, env.UIParent:GetWidth() / 880, env.UIParent:GetHeight() / 670)
        window:SetScale(math.max(0.5, scale))
        ui.background:SetColorTexture(cfg().highContrast and 0 or 0.035, cfg().highContrast and 0 or 0.055,
            cfg().highContrast and 0 or 0.08, 1)
    end
    function ui.Open(page)
        if product.IsCombat() then emit("Studio is unavailable during combat. Nothing queued."); return end
        product.Observe()
        if page then ui.page = page end
        ui.Size(); ui.BuildPage(); window:Show(); W.Fade(window, db.config.preferences)
    end
    for i, label in ipairs(pages) do
        local index = i
        W.Button(env, window, label, 16, -112 - (i - 1) * 47, 198, function() ui.page = index; ui.BuildPage() end)
    end
    if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftStudio") end
    ui.radial = ns.Radial.New(runtime, function() ui.Open() end)
    function ui.CloseWheel() if ui.radial.Close then ui.radial.Close() end; window:Hide() end
    function ui.Wheel() if ui.radial.Toggle then ui.radial.Toggle() end end
    product.Refresh = ui.Refresh
    window:Hide()
    -- Native Settings is discoverability only; no proxy CVar setters are registered.
    if type(env.Settings) == "table" and type(env.Settings.RegisterCanvasLayoutCategory) == "function"
        and type(env.Settings.RegisterAddOnCategory) == "function" then
        pcall(function()
            local canvas = env.CreateFrame("Frame")
            W.Text(canvas, "LumenShift — Northern Lights Labs", 20, -20, 580, 20)
            W.Button(env, canvas, "Open Visual Studio", 20, -70, 280, function() ui.Open() end)
            W.Text(canvas, "Visual modes, optional UI effects, independent quality diagnostics and recovery. No automatic graphics changes at login.", 20, -120, 580, 14)
            local category = env.Settings.RegisterCanvasLayoutCategory(canvas, "LumenShift")
            env.Settings.RegisterAddOnCategory(category)
        end)
    end
    return ui
end
