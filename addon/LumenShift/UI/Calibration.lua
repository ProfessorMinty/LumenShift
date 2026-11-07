local _, ns = ...
local U, W = {}, ns.Widgets
ns.CalibrationUI = U
function U.Build(runtime, ui, parent, env)
    local lab, db = runtime.lab, runtime.db
    local y = -8
    local function line(text, height, color) W.Text(parent, text, 0, y, 550, 13, color); y = y - (height or 55) end
    local function action(label, fn)
        W.Button(env, parent, label, 0, y, 540, function()
            local ok, reason = fn()
            if not ok and reason then ns.Diagnostics.Emit(runtime, "LumenShift: " .. ns.Product.Message(reason)) end
            ui.BuildPage()
        end); y = y - 40
    end
    line("Advanced graphics", 30, W.colors.accent)
    if ui.qualityTrials then
        action("Back to detail and sharpening", function() ui.qualityTrials = false; return true end)
        line("Shadows, lighting and water", 32, W.colors.accent)
        line("Choose a level, then Try & Restore. It runs for two seconds and restores the captured tier. Surrounding settings are checked too. Experimental: these native tiers can change related settings.", 100)
        ui.trialKey = ui.trialKey or "graphicsShadowQuality"
        local top = y
        for i, key in ipairs(ns.QualityTrial.Order) do
            local selected = key
            W.Button(env, parent, (ui.trialKey == key and "* " or "") .. ns.QualityTrial.Definition(key).label,
                ((i - 1) % 2) * 275, top - math.floor((i - 1) / 2) * 40, 265, function()
                    if runtime.tierTrial.busy then return end
                    ui.trialKey, ui.trialTarget = selected, nil; ui.BuildPage()
                end)
        end
        y = top - 92
        local key, trial = ui.trialKey, runtime.tierTrial
        local definition = ns.QualityTrial.Definition(key)
        local current = ns.ReadOnly.Read(runtime.reader, key)
        line(definition.label .. " now: " .. ns.Report.Number(current.raw), 35)
        top = y
        for i, label in ipairs(definition.choices) do
            local value = i - 1
            local supported = ns.QualityTrial.Support(runtime.reader, key, value)
            local button = W.Button(env, parent, (ui.trialTarget == value and "* " or "") .. label .. " (" .. value .. ")",
                ((i - 1) % 2) * 275, top - math.floor((i - 1) / 2) * 40, 265, function()
                    ui.trialTarget = value; ui.BuildPage()
                end)
            if not supported then button:Disable() end
        end
        y = top - math.ceil(#definition.choices / 2) * 40 - 12
        local supported, why = ns.QualityTrial.Support(runtime.reader, key, ui.trialTarget or ns.Value.Number(current.raw))
        if not supported then line("Client capability: " .. (why or current.code), 55, W.colors.muted) end
        action("Try selected level & restore", function() return trial.Test(key, ui.trialTarget) end)
        ui.trialStateText = W.Text(parent, "", 0, y, 550, 13, W.colors.accent); y = y - 65
        local status = trial.Status()
        if status.key then line("Captured " .. status.key .. " original: " .. ns.Report.Number(status.original), 40) end
        action("Restore interrupted quality trial", trial.Restore)
        action("Export Complete Diagnostic Report", function() return ns.DiagnosticWindow.Open(runtime) end)
        line("The trial checks named settings, not every engine dependency. If restoration differs, the report retains originals. It never invents repair values or retries after reload. Normal profiles use direct detail controls instead of these tier switches.", 115, W.colors.muted)
        return -y + 20
    end
    action("Shadows, lighting & water", function() ui.qualityTrials = true; return true end)
    line("Choose a setting and a value. Test & Restore tries it for about two seconds, then returns to your original value.", 85)
    line("These controls are experimental. No settings change until you click Test & Restore or Apply. Details and recovery are in Diagnostic Center.", 80, W.colors.muted)
    ui.labKey = ui.labKey or "Contrast"; ui.labProfile = ui.labProfile or "balanced"
    local start = y
    local labels = { Contrast = "Contrast" }
    for _, candidate in ipairs(ns.Quality.Candidates) do labels[candidate.key] = candidate.label end
    for i, key in ipairs(ns.ExperimentPolicy.Keys) do
        local chosen = key
        W.Button(env, parent, (ui.labKey == key and "* " or "") .. (labels[key] or key), ((i - 1) % 2) * 275, start - math.floor((i - 1) / 2) * 38, 265,
            function()
                if lab.busy then ns.Diagnostics.Emit(runtime, "LumenShift: wait for the test to finish before choosing another setting."); return end
                ui.labKey = chosen; ui.labTarget = nil; lab.Cancel(); ui.BuildPage()
            end)
    end
    y = start - math.ceil(#ns.ExperimentPolicy.Keys / 2) * 38 - 12
    local item = ns.ReadOnly.Read(runtime.reader, ui.labKey)
    local bounds, reason = ns.ExperimentPolicy.Bounds(ui.labKey, item.raw)
    line(ui.labKey .. " current=" .. ns.Report.Number(item.raw) .. " [" .. item.code .. "]", 30)
    if bounds then
        line("Available test range: " .. bounds.min .. " to " .. bounds.max .. "; step " .. bounds.step .. ".", 42)
    else line("Unavailable: " .. (reason or "UNKNOWN_REASON") .. ". Export the diagnostic report for investigation.", 65) end
    W.Text(parent, "Value to try", 0, y, 370, 13)
    local edit = W.Edit(env, parent, ui.labTarget or item.raw or "", 380, y + 4, 160, function(text) ui.labTarget = text end)
    y = y - 42
    action("Test & Restore", function()
        ui.labTarget = edit:GetText()
        return lab.Test(ui.labKey, ns.Value.Number(ui.labTarget))
    end)
    action("Preview exact modification (read only)", function()
        ui.labTarget = edit:GetText()
        return lab.Preview(ui.labKey, ns.Value.Number(ui.labTarget))
    end)
    ui.labStateText = W.Text(parent, "", 0, y, 550, 13, W.colors.accent); y = y - 45
    if lab.preview then
        for _, text in ipairs(lab.preview.lines) do line(text, 56) end
        local token = lab.preview.token
        action("Export Complete Diagnostic Report", function() return ns.DiagnosticWindow.Open(runtime) end)
        action("Confirm displayed operation " .. token, function() return lab.Confirm(token) end)
    end
    action("Cancel experiment / preview (does not restore)", lab.Cancel)
    action("Preview recovery of experimental visual settings", function() return lab.PreviewRestore("visual") end)
    action("Preview recovery of experimental quality settings", function() return lab.PreviewRestore("quality") end)
    line("Save and apply", 30, W.colors.accent)
    if ui.labKey == "Contrast" then
        line("Set Contrast in Visual Modes and turn on Adjust Contrast for that mode. Apply uses it immediately; Natural restores your original. A prior test is optional.", 85)
    else
        line("Choose a profile and save your values, then Apply. Saved profiles remain usable after reload; each Apply checks current availability and ranges. Up to eight settings per profile.", 90)
        for _, id in ipairs({ "balanced", "vista", "performance" }) do
            local profile = id
            action((ui.labProfile == id and "* Editing " or "Edit ") .. ns.Quality.Profiles[id], function() ui.labProfile = profile; return true end)
        end
        action("Save value into " .. ns.Quality.Profiles[ui.labProfile], function()
            ui.labTarget = edit:GetText()
            return lab.SaveProfile(ui.labProfile, ui.labKey, ns.Value.Number(ui.labTarget))
        end)
        for _, key in ipairs(ns.Value.Keys(db.experiments.profiles[ui.labProfile])) do
            line(key .. " = " .. db.experiments.profiles[ui.labProfile][key], 28)
        end
        action("Remove selected key from this saved profile", function()
            db.experiments.profiles[ui.labProfile][ui.labKey] = nil
            ns.Log.Record(runtime.reader, "configuration", "profile-remove-key", "INFO", "PASS", { profile = ui.labProfile, key = ui.labKey }); return true
        end)
        action("Apply " .. ns.Quality.Profiles[ui.labProfile] .. " profile", function() return lab.SelectProfile(ui.labProfile) end)
        action("Current Baseline — restore owned quality", function() return lab.SelectProfile("currentBaseline") end)
    end
    line("Shadows, lighting and water have separate native tier trials above. HDR and renderer changes remain in the game's own settings because they can need a restart.", 78, W.colors.muted)
    return -y + 20
end
