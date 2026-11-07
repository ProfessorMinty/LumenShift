local _, ns = ...
local D, W = {}, ns.Widgets
ns.DiagnosticWindow = D
function D.Open(runtime)
    local env = runtime.reader.env
    if not env.UIParent or type(env.CreateFrame) ~= "function" then
        ns.Log.Record(runtime.reader, "export", "window", "ERROR", "NATIVE_UI_UNAVAILABLE")
        ns.Diagnostics.Emit(runtime, "LumenShift: export window unavailable; native UI initialization failed. Recovery data is preserved.")
        return nil, "NATIVE_UI_UNAVAILABLE"
    end
    local report = ns.Report.Export(runtime)
    local ui = runtime.exportUI
    if not ui then
        ui = {}
        local window = env.CreateFrame("Frame", "LumenShiftDiagnosticReport", env.UIParent); ui.window = window
        window:SetSize(800, 620); window:SetPoint("CENTER"); window:SetFrameStrata("FULLSCREEN_DIALOG")
        window:SetClampedToScreen(true); window:EnableMouse(true); W.Fill(window, W.colors.bg)
        ui.panelArt = W.Art(window, "panel-steel", 1, -1, 798, 618, 0.25, "BACKGROUND"); W.Border(window)
        W.Art(window, "ui-diagnostics", 20, -20, 22, 22)
        W.Text(window, "Diagnostic Report", 56, -17, 700, 24)
        W.Text(window, "Click Select All, then press Ctrl+C. Paste into Codex or ChatGPT. Nothing is uploaded automatically.", 18, -50, 750, 13)
        local scroll = env.CreateFrame("ScrollFrame", nil, window); ui.scroll = scroll
        scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 18, -135); scroll:SetSize(744, 460); scroll:EnableMouseWheel(true)
        local box = env.CreateFrame("EditBox", nil, scroll); ui.box = box
        box:SetMultiLine(true); box:SetAutoFocus(false); box:SetFontObject("GameFontHighlightSmall")
        box:SetMaxLetters(120000); box:SetWidth(730); box:SetTextInsets(6, 6, 6, 6)
        scroll:SetScrollChild(box); box:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
        local bar = env.CreateFrame("Slider", nil, window); ui.bar = bar
        bar:SetSize(12, 460); bar:SetPoint("TOPLEFT", window, "TOPLEFT", 771, -135)
        bar:SetOrientation("VERTICAL"); bar:SetValueStep(20); W.Fill(bar)
        local thumb = bar:CreateTexture(nil, "OVERLAY"); thumb:SetSize(12, 40); thumb:SetColorTexture(unpack(W.colors.accent)); bar:SetThumbTexture(thumb)
        W.Script(bar, "OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
        W.Script(scroll, "OnMouseWheel", function(_, delta) bar:SetValue(math.max(0, math.min(ui.maximum, scroll:GetVerticalScroll() - delta * 45))) end)
        W.Script(box, "OnEscapePressed", function(self) self:ClearFocus(); window:Hide() end)
        W.Script(box, "OnTextChanged", function(self, userInput) if userInput and ui.text then self:SetText(ui.text) end end)
        W.Script(window, "OnHide", function() box:ClearFocus() end)
        function ui.SelectAll() box:SetFocus(); box:HighlightText(0, -1) end
        W.Button(env, window, "Select All", 18, -91, 160, ui.SelectAll, nil, "primary")
        W.Button(env, window, "Refresh report", 190, -91, 170, function() D.Open(runtime) end)
        W.Button(env, window, "Close", 676, -91, 105, function() window:Hide() end)
        if type(env.UISpecialFrames) == "table" then table.insert(env.UISpecialFrames, "LumenShiftDiagnosticReport") end
        runtime.exportUI = ui -- publish only a fully initialized export interface
    end
    W.Decoration(ui.panelArt)
    ui.text = report; ui.box:SetText(report)
    local estimated = 0
    for line in (report .. "\n"):gmatch("(.-)\n") do estimated = estimated + math.max(1, math.ceil(#line / 85)) end
    ui.box:SetHeight(math.max(460, estimated * 16 + 24))
    ui.maximum = math.max(0, ui.box:GetHeight() - 460)
    ui.bar:SetMinMaxValues(0, ui.maximum); ui.bar:SetValue(0)
    ui.window:SetScale(math.min(1, env.UIParent:GetWidth() / 830, env.UIParent:GetHeight() / 650))
    ui.window:Show(); ui.SelectAll()
    ns.Log.Record(runtime.reader, "export", "window", "INFO", "READY_FOR_CTRL_C", { count = #report })
    return true
end
