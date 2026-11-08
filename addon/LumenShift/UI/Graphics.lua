local _, ns = ...
local U, W, G = {}, ns.Widgets, ns.NativeGraphics
ns.GraphicsUI = U
function U.Comparison(runtime, ui, parent, env, offset)
    local perf = runtime.performance
    local y = -offset
    W.Text(parent, "FIND YOUR BALANCE", 0, y, 820, 12, W.colors.muted)
    for i, item in ipairs({ { "smooth", "Smooth gameplay" }, { "scenery", "Richer scenery" }, { "quiet", "Quieter operation" } }) do
        local id = item[1]
        local button = W.Button(env, parent, item[2], (i - 1) * 282, y - 32, 270, function() perf.priority = id; ui.RebuildInPlace() end)
        button.SetSelected(perf.priority == id)
    end
    local tips = {
        smooth = "Compare your current view, then try one lower native level if it feels uneven. Judge spell readability during your own raid test.",
        scenery = "Compare your current view, then try one higher native level. Look at shadows, water and distant detail while moving.",
        quiet = "Compare a lower native level and your usual FPS cap in WoW Settings. FPS alone cannot measure power, fan noise or heat.",
    }
    W.Text(parent, tips[perf.priority], 0, y - 88, 820, 13, W.colors.muted)
    W.Text(parent, "SCENE FOR THIS OBSERVATION", 0, y - 158, 820, 12, W.colors.muted)
    for i, id in ipairs({ "outdoor", "town", "interior", "raid", "battleground" }) do
        local scene = id
        local button = W.Button(env, parent, ns.Performance.Scenes[id], (i - 1) * 169, y - 190, 158, function() perf.scene = scene; ui.RebuildInPlace() end)
        button.SetSelected(perf.scene == id)
    end
    W.Text(parent, "Hold the same viewpoint and workload for both samples. Sample A, apply your chosen graphics above, then sample B. No settings change during sampling.", 0, y - 248, 820, 13, W.colors.muted)
    W.Button(env, parent, "Observe FPS for 10 seconds", 0, y - 318, 310, function() perf.Start(); ui.Refresh() end)
    W.Button(env, parent, "Cancel observation", 330, y - 318, 240, function() perf.Cancel(); ui.Refresh() end, nil, "quiet")
    ui.performanceText = W.Text(parent, perf.Text(), 0, y - 382, 820, 13)
    W.Text(parent, "Ten native FPS readings, not frame-time percentiles or a hardware benchmark. Short samples cannot predict raid performance. Results remain for this session and in your exported report.", 0, y - 486, 820, 12, W.colors.muted)
    return offset + 558
end
function U.Status(engine)
    local status = engine.Status()
    local labels = { IDLE = "Ready", ACTIVE = "Graphics applied", RECOVERY = "Captured originals available",
        APPLYING = "Applying graphics...", VERIFYING = "Checking graphics..." }
    return status.error and U.Message(status.error) or labels[status.state] or "Check Diagnostic Center for details."
end
function U.Message(code)
    if not code then return "Graphics verified." end
    local prefix, key = code:match("^([^:]+):?(.*)$")
    local def = key and G.Definition(key)
    local label = def and def.label or key
    local messages = {
        BUSY = "Wait for the current change to finish.",
        OTHER_OPERATION_ACTIVE = "Wait for the current change to finish.",
        COMBAT_OR_RESTRICTION = "Apply graphics after combat.",
        RESTORE_DETAIL_PROFILE_FIRST = "Restore your detail profile before changing everyday graphics.",
        RESTORE_GRAPHICS_BANK_FIRST = "Restore everyday graphics before applying overlapping detail changes.",
        GRAPHICS_RECOVERY_REQUIRED = "Review the captured graphics below, then use Restore to return to them.",
        GRAPHICS_EXTERNAL_CONFLICT = "Graphics changed elsewhere. Your change was kept. Restore is available below.",
        GRAPHICS_CAPTURE_UNAVAILABLE = "The game could not read a setting needed to preserve your originals.",
        NATIVE_RECIPE_UNAVAILABLE = "The game did not provide this graphics recipe.",
        GRAPHICS_VALUE_UNAVAILABLE = "A graphics option is currently unavailable.",
        UNSUPPORTED_GRAPHICS_OPTION = "This graphics option is not supported on your current configuration.",
        API_UNAVAILABLE = "The game does not expose the API needed for this choice.",
        OTHER_BANK_OR_VISUAL_CHANGED = "Another setting changed during Apply. The captured originals were retained.",
        GRAPHICS_SETTER_OR_READBACK_FAILED = "The game did not accept a graphics change. Check the operation status.",
        GRAPHICS_FINAL_MISMATCH = "Some graphics values did not match. Captured originals remain available.",
    }
    return (messages[prefix] or "The graphics operation did not finish. Diagnostic Center has the details.")
        .. (def and label and (" (" .. label .. ")") or "")
end
function U.HasChanges(draft)
    return draft.normal.source ~= "keep" or draft.raid.source ~= "keep" or draft.raidEnabled ~= "keep"
end
function U.Build(runtime, env, parent, draft, rebuild, width)
    local reader = runtime.reader
    local function bankPanel(bank, y)
        local title = bank == "normal" and "Everyday graphics" or "Raid & battleground graphics"
        W.Text(parent, title, 0, y, width, 16)
        W.Text(parent, "Current: " .. G.Current(reader, bank), 0, y - 25, width, 12, W.colors.muted)
        local options = { { "keep", "Keep current" }, { "recommended", "WoW recommendation" }, { "level", "Choose a level" } }
        local cell = (width - 20) / 3
        for i, option in ipairs(options) do
            local source = option[1]
            local button = W.Button(env, parent, option[2], (i - 1) * (cell + 10), y - 49, cell, function()
                draft[bank].source = source; rebuild()
            end)
            button.SetSelected(draft[bank].source == source)
            button.label:SetWordWrap(false)
        end
        if draft[bank].source == "level" then
            W.Slider(env, parent, "Quality level", 0, y - 88, 1, 10, 1,
                function() return draft[bank].level end, function(value) draft[bank].level = value; return true end,
                "1 favors performance; 10 favors detail. Actual performance depends on the scene and your computer.", width)
        else
            W.Text(parent, draft[bank].source == "keep" and "Preserve this bank's current custom settings."
                or "Use the recommended defaults reported by WoW.", 0, y - 94, width, 12, W.colors.muted)
        end
        return y - 155
    end
    local y = bankPanel("normal", 0)
    W.Button(env, parent, "Review changes", width - 150, 2, 150, function() U.ShowPreview(runtime, draft) end, nil, "quiet")
    local raidRead = ns.ReadOnly.Read(reader, "RAIDsettingsEnabled")
    local function raidEnabled() return draft.raidEnabled == "on" or draft.raidEnabled == "keep" and raidRead.raw == "1" end
    W.Toggle(env, parent, "Use different graphics in raids and battlegrounds", 0, y, width, raidEnabled, function(value)
        draft.raidEnabled = value and "on" or "off"
        if not value then draft.raid.source = "keep" end
        rebuild()
    end)
    y = y - 44
    if raidEnabled() then y = bankPanel("raid", y) end
    W.Text(parent, "Recommended uses WoW's defaults, not an FPS benchmark. Projected textures and particles stay enabled.", 0, y - 4, width, 12, W.colors.muted)
    W.Text(parent, "Choosing options does not change graphics. Apply uses the selected banks only.", 0, y - 37, width, 12, W.colors.muted)
    return -y + 70
end
function U.ShowPreview(runtime, draft)
    local count, rows = U.Preview(runtime, draft)
    local env, ui = runtime.reader.env, runtime.graphicsPreview
    if not ui then
        ui = {}
        local window = env.CreateFrame("Frame", "LumenShiftGraphicsPreview", env.UIParent); ui.window = window
        window:SetSize(650, 540); window:SetPoint("CENTER"); W.Window(env, window, 70, 120)
        W.Fill(window, W.colors.bg); W.Border(window)
        W.Text(window, "Graphics preview", 24, -24, 470, 24)
        W.Button(env, window, "Close", 530, -24, 96, function() window:Hide() end, nil, "quiet")
        local scroll = env.CreateFrame("ScrollFrame", nil, window); scroll:SetSize(586, 406)
        scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -110); scroll:EnableMouseWheel(true)
        ui.body = env.CreateFrame("Frame", nil, scroll); ui.body:SetWidth(586); scroll:SetScrollChild(ui.body)
        ui.body:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
        ui.pool = W.CreatePool(env, ui.body); ui.scroll = scroll
        ui.summary = W.Text(window, "", 24, -76, 598, 13, W.colors.muted)
        local bar = env.CreateFrame("Slider", nil, window); ui.bar = bar
        bar:SetPoint("TOPLEFT", window, "TOPLEFT", 616, -110); bar:SetSize(8, 406)
        bar:SetOrientation("VERTICAL"); bar:SetValueStep(40); W.Fill(bar, W.colors.sidebar)
        local thumb = bar:CreateTexture(nil, "OVERLAY"); thumb:SetSize(8, 36); thumb:SetColorTexture(unpack(W.colors.accent)); bar:SetThumbTexture(thumb)
        W.Script(bar, "OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
        W.Script(scroll, "OnMouseWheel", function(_, delta)
            bar:SetValue(math.max(0, math.min(ui.maximum, scroll:GetVerticalScroll() - delta * 40)))
        end)
        if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftGraphicsPreview") end
        runtime.graphicsPreview = ui
    end
    ui.pool.Reset()
    ui.summary:SetText(count and (count .. " direct changes. Preview only; nothing applied.") or "This choice is unavailable.")
    local lines = count and rows or { rows }
    if count == 0 then lines = { "Your selected settings already match. No direct changes needed." } end
    lines[#lines + 1] = "Native presets may also change detail settings. Available known originals are captured before Apply."
    for i, line in ipairs(lines) do W.Text(ui.body, line, 0, -(i - 1) * 42, 584, 13) end
    local height = math.max(406, #lines * 42)
    ui.body:SetHeight(height); ui.maximum = height - 406; ui.scroll:SetVerticalScroll(0)
    ui.bar:SetMinMaxValues(0, ui.maximum); ui.bar:SetValue(0)
    if ui.maximum > 0 then ui.bar:Show() else ui.bar:Hide() end
    ui.window:SetScale(math.min(1, env.UIParent:GetWidth() / 690, env.UIParent:GetHeight() / 580)); ui.window:Show()
end
function U.Preview(runtime, draft)
    local count, rows = 0, {}
    for _, bank in ipairs(G.Banks) do
        local targets, why = G.Recipe(runtime.reader, bank, draft[bank])
        if not targets then return nil, U.Message(why) end
        if bank == "raid" and draft.raidEnabled ~= "keep" then targets.RAIDsettingsEnabled = draft.raidEnabled == "on" and 1 or 0 end
        for _, key in ipairs(ns.Value.Keys(targets)) do
            local item = ns.ReadOnly.Read(runtime.reader, key)
            if ns.Value.Number(item.raw) ~= targets[key] then
                count = count + 1
                local def = G.Definition(key)
                local before, after = ns.Report.Number(item.raw), targets[key]
                if def.overall or def.suffix == "ViewDistance" or def.suffix == "EnvironmentDetail" or def.suffix == "GroundClutter" then
                    local raw = ns.Value.Number(item.raw)
                    before = raw and raw >= 0 and (raw + 1) or "Custom"
                    after = targets[key] + 1
                elseif def.flag or def.suffix == "ProjectedTextures" then
                    before = item.raw == "1" and "On" or item.raw == "0" and "Off" or before
                    after = targets[key] == 1 and "On" or "Off"
                end
                rows[#rows + 1] = (bank == "normal" and "Everyday: " or "Raid: ") .. def.label .. " " .. before .. " → " .. after
            end
        end
    end
    return count, rows
end
