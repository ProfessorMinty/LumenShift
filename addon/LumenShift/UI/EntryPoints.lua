local _, ns = ...
local E, W = {}, ns.Widgets
ns.EntryPoints = E
function E.New(runtime)
    local env, entry = runtime.reader.env, {}
    if not env.UIParent then return entry end
    function entry.Studio(page)
        if runtime.setup and runtime.setup.window then runtime.setup.window:Hide() end
        if runtime.ui and runtime.ui.Open then runtime.ui.Open(page or 1)
        else ns.DiagnosticWindow.Open(runtime) end
    end
    function entry.Open(button)
        if not runtime.db then return ns.DiagnosticWindow.Open(runtime) end
        if button == "RightButton" then return entry.Studio() end
        if not runtime.db.onboarding.completed then return runtime.setup.Open() end
        if runtime.ui and runtime.ui.Wheel then return runtime.ui.Wheel() end
        return ns.DiagnosticWindow.Open(runtime)
    end
    function entry.Diagnostics()
        ns.Report.Run(runtime, "user-button"); entry.Studio(7)
    end
    local button = env.CreateFrame("Button", "LumenShiftMinimapButton", env.UIParent); entry.button = button
    button:SetSize(38, 38); button:SetFrameStrata("MEDIUM"); button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local icon = button:CreateTexture(nil, "ARTWORK"); icon:SetAllPoints(button)
    W.Asset(icon, "Interface/AddOns/LumenShift/Media/logo.tga")
    if env.Minimap then button:SetPoint("TOPLEFT", env.Minimap, "BOTTOMLEFT", -8, 10)
    else
        button:SetSize(140, 38); button:SetPoint("TOPRIGHT", env.UIParent, "TOPRIGHT", -28, -140)
        icon:ClearAllPoints(); icon:SetSize(38, 38); icon:SetPoint("LEFT", button, "LEFT", 0, 0)
        W.Text(button, "LumenShift", 43, -10, 96, 13, W.colors.accent)
    end
    W.Script(button, "OnClick", function(_, mouse) entry.Open(mouse) end)
    W.Tip(env, button, "LumenShift\nClick: setup or mode wheel\nRight-click: Studio\nDiagnostics and recovery are in Studio.")
    function entry.Refresh()
        local radial = runtime.ui and runtime.ui.radial
        local floating = radial and radial.launcher
        local useFloating = floating and runtime.db and runtime.db.config.studio.launcher.visible
        -- Exactly one entry button. Keep a fallback even when Studio failed.
        if useFloating then button:Hide(); floating:Show()
        else button:Show(); if floating then floating:Hide() end end
    end
    entry.Refresh()
    -- Independent of Studio initialization: a failed Studio still has a clickable report path.
    if type(env.Settings) == "table" and type(env.Settings.RegisterCanvasLayoutCategory) == "function"
        and type(env.Settings.RegisterAddOnCategory) == "function" then
        local ok = pcall(function()
            local canvas = env.CreateFrame("Frame")
            W.Art(canvas, "logo", 20, -12, 40, 40)
            W.Text(canvas, "LumenShift — Northern Lights Labs", 74, -20, 520, 20)
            W.Button(env, canvas, "Open Visual Studio", 20, -70, 300, function() entry.Studio() end)
            W.Button(env, canvas, "Setup wizard", 20, -115, 300, function() runtime.setup.Open() end)
            W.Button(env, canvas, "Run Diagnostics", 20, -160, 300, entry.Diagnostics)
            W.Button(env, canvas, "Export Complete Diagnostic Report", 20, -205, 420, function() ns.DiagnosticWindow.Open(runtime) end)
            W.Text(canvas, "Use the minimap button or movable launcher to open LumenShift. Setup finishes with a user-controlled UI reload. No graphics changes occur at login.", 20, -265, 580, 14)
            W.Button(env, canvas, "Reset LumenShift & Restart Setup", 20, -330, 420, function() runtime.reset.Open() end)
            env.Settings.RegisterAddOnCategory(env.Settings.RegisterCanvasLayoutCategory(canvas, "LumenShift"))
        end)
        ns.Log.Record(runtime.reader, "entry", "settings-registration", ok and "INFO" or "WARN", ok and "PASS" or "NATIVE_SETTINGS_REGISTRATION_FAILED")
    else ns.Log.Record(runtime.reader, "entry", "settings-registration", "WARN", "SETTINGS_API_UNAVAILABLE_USE_VISIBLE_BUTTON") end
    ns.Log.Record(runtime.reader, "entry", "initialize", "INFO", env.Minimap and "MINIMAP_BUTTON" or "VISIBLE_FALLBACK_BUTTON")
    return entry
end
