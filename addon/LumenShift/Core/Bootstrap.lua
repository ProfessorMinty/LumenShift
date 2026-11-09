local addonName, ns = ...
local runtime = { reader = ns.ReadOnly.New(_G), storeStatus = "NOT_LOADED" }
ns.runtime = runtime
runtime.log = ns.Log.New(runtime.reader); runtime.reader.log = runtime.log
runtime.log.Add("bootstrap", "module-entry", "INFO", "PASS")
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", runtime.log.Guard("bootstrap", "OnEvent", function(self, event, name)
    if event == "CVAR_UPDATE" then
        if runtime.engine then runtime.engine.Notify() end
        if runtime.names then runtime.names.Observe() end
        if runtime.graphics then runtime.graphics.Observe() end
        if runtime.photo then runtime.photo.Observe() end
        if runtime.photoEditor then runtime.photoEditor.Observe() end
        if runtime.framing then runtime.framing.Observe() end
        if runtime.product then runtime.product.Observe() end
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        if runtime.product then runtime.product.Combat() end
        if runtime.camera then runtime.camera.Combat() end
        return
    end
    if event == "PLAYER_LEAVING_WORLD" then
        if runtime.captureSequence then runtime.captureSequence.Cancel() end
        if runtime.composition then runtime.composition.CancelCapture() end
        if runtime.performance and runtime.performance.active then runtime.performance.Cancel("SAMPLE_SCENE_CHANGED") end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
        if runtime.product then runtime.product.Observe(event == "PLAYER_REGEN_ENABLED") end
        if event == "PLAYER_ENTERING_WORLD" and runtime.loaded then
            ns.Compatibility.WarnOnce(runtime)
            ns.Report.Run(runtime, "world-entry-read-only")
        end
        if runtime.setup then runtime.setup.MaybeOpen() end
        return -- no queued reapply, even when combat ends
    end
    if event ~= "ADDON_LOADED" or name ~= addonName or runtime.loaded then return end
    runtime.loaded = true
    -- Register the report entry before optional UI initialization so diagnosed failures remain reachable.
    SLASH_LUMENSHIFT1, SLASH_LUMENSHIFT2 = "/lumenshift", "/ls"
    SlashCmdList.LUMENSHIFT = runtime.log.Guard("commands", "slash", function(message) ns.Controller.Command(runtime, message) end)
    -- Bind only after our SavedVariables have loaded. Invalid input remains untouched.
    local db, status = ns.Store.Open(LumenShiftDB)
    runtime.db, runtime.storeStatus = db, status
    runtime.log.Add("store", "load", db and "INFO" or "ERROR", status)
    if db then LumenShiftDB = db end
    runtime.identity = ns.Compatibility.Inspect(runtime.reader)
    runtime.reset = ns.Reset.New(runtime, function(replacement)
        local previous = LumenShiftDB
        LumenShiftDB = replacement
        return previous
    end)
    runtime.controller = ns.Controller.New(db and not next(db.journal.entries) and "BASELINE" or "RECOVERY")
    runtime.engine = ns.WriteBoundary.New(runtime.reader, db, function(line) return ns.Diagnostics.Emit(runtime, line) end)
    runtime.lab = ns.WriteBoundary.NewExperiments(runtime)
    runtime.tierTrial = ns.WriteBoundary.NewTierTrials(runtime)
    runtime.names = ns.WriteBoundary.NewExperiments(runtime, true)
    runtime.framing = ns.WriteBoundary.NewExperiments(runtime, "framing")
    runtime.graphics = ns.WriteBoundary.NewNativeGraphics(runtime)
    runtime.photo = ns.WriteBoundary.NewNativeGraphics(runtime, true)
    runtime.visual = ns.WriteBoundary.NewVisual(runtime)
    runtime.product = ns.Product.New(runtime)
    runtime.camera = ns.Camera.New(runtime)
    runtime.photoEditor = ns.PhotoEditor.New(runtime)
    runtime.photoPreview = ns.PhotoPreview.New(runtime)
    runtime.photoEffects = ns.PhotoEffects.New(runtime)
    runtime.performance = ns.Performance.New(runtime)
    runtime.composition = ns.Composition.New(runtime)
    runtime.captureSequence = ns.CaptureSequence.New(runtime)
    runtime.photoTools = ns.PhotoTools.New(runtime)
    runtime.photoCompatibility = ns.PhotoCompatibility.New(runtime)
    runtime.presentation = ns.Presentation.New(runtime.reader.env)
    runtime.audio = ns.Audio.New(runtime.reader)
    if db and UIParent then
        local ok, ui = pcall(ns.Studio.New, runtime)
        if ok then runtime.ui = ui else runtime.lastError = "UI_INITIALIZATION_FAILED"; runtime.log.Add("studio", "initialize", "ERROR", runtime.lastError) end
    end
    runtime.setup = ns.Setup.New(runtime)
    local entryOK, entry = pcall(ns.EntryPoints.New, runtime)
    if entryOK then runtime.entry = entry
    else runtime.log.Add("entry", "initialize", "ERROR", "ENTRY_UI_INITIALIZATION_FAILED") end
    BINDING_HEADER_LUMENSHIFT = "LumenShift"
    BINDING_NAME_LUMENSHIFT_TOGGLE = "Toggle Night Vision"
    BINDING_NAME_LUMENSHIFT_WHEEL = "Open / close visual wheel"
    BINDING_NAME_LUMENSHIFT_STUDIO = "Open Visual Studio"
    BINDING_NAME_LUMENSHIFT_CAMERA = "Enter / exit Camera Mode"
    LumenShift_ToggleNightVision = runtime.log.Guard("bindings", "toggle", function() runtime.product.Toggle() end)
    LumenShift_OpenWheel = runtime.log.Guard("bindings", "wheel", function() if runtime.ui and runtime.ui.Wheel then runtime.ui.Wheel() end end)
    LumenShift_OpenStudio = runtime.log.Guard("bindings", "studio", function() if runtime.ui and runtime.ui.Open then runtime.ui.Open() end end)
    LumenShift_ToggleCamera = runtime.log.Guard("bindings", "camera", function() runtime.camera.Toggle() end)
    self:UnregisterEvent("ADDON_LOADED")
    self:RegisterEvent("CVAR_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LEAVING_WORLD")
    ns.Report.Run(runtime, "startup-read-only")
    runtime.log.Add("bootstrap", "initialize", "INFO", "COMPLETE_NO_STARTUP_WRITE")
end))
