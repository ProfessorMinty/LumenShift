local _, ns = ...
local U, W = {}, ns.Widgets
ns.CalibrationUI = U
function U.Build(runtime, ui, parent, env)
    local lab, db = runtime.lab, runtime.db
    local function text(label, x, y, width, color) return W.Text(parent, label, x, y, width, 13, color) end
    local function action(label, x, y, width, fn, style)
        return W.Button(env, parent, label, x, y, width, function()
            local ok, reason = fn()
            if not ok and reason then ns.Diagnostics.Emit(runtime, "LumenShift: " .. ns.Product.Message(reason)) end
            ui.BuildPage()
        end, nil, style)
    end
    local function primary(label, fn)
        ui.Primary(label, function()
            local ok, reason = fn()
            if not ok and reason then ns.Diagnostics.Emit(runtime, "LumenShift: " .. ns.Product.Message(reason)) end
            ui.BuildPage()
        end, "Experimental: tries your value, then restores the captured original.")
    end
    local detailTab = action("Detail & sharpening", 0, 0, 234, function() ui.qualityTrials = false; return true end)
    local tierTab = action("Shadows, lighting & water", 248, 0, 272, function() ui.qualityTrials = true; return true end)
    detailTab.SetSelected(not ui.qualityTrials); tierTab.SetSelected(ui.qualityTrials == true)
    if ui.qualityTrials then
        ui.trialKey = ui.trialKey or "graphicsShadowQuality"
        W.Section(parent, "NATIVE QUALITY TIERS", 0, -62, 836)
        for i, key in ipairs(ns.QualityTrial.Order) do
            local selected = key
            local b = action(ns.QualityTrial.Definition(key).label, ((i - 1) % 2) * 430,
                -105 - math.floor((i - 1) / 2) * 40, 406, function()
                    if runtime.tierTrial.busy then return nil, "BUSY" end
                    ui.trialKey, ui.trialTarget = selected, nil; return true
                end)
            b.SetSelected(ui.trialKey == key)
        end
        local key, trial = ui.trialKey, runtime.tierTrial
        local definition, current = ns.QualityTrial.Definition(key), ns.ReadOnly.Read(runtime.reader, key)
        text(definition.label .. " now: " .. ns.Report.Number(current.raw), 0, -207, 836)
        for i, label in ipairs(definition.choices) do
            local value = i - 1
            local supported, reason = ns.QualityTrial.Support(runtime.reader, key, value)
            local b = action(label .. " (" .. value .. ")", ((i - 1) % 3) * 284,
                -247 - math.floor((i - 1) / 3) * 40, 268, function() ui.trialTarget = value; return true end)
            b.SetSelected(ui.trialTarget == value)
            if not supported then b:Disable(); b.label:SetTextColor(unpack(W.colors.muted)); W.Tip(env, b, reason or "Unavailable on this client") end
        end
        local y = -247 - math.ceil(#definition.choices / 3) * 40 - 22
        ui.trialStateText = text("", 0, y, 836, W.colors.accent)
        text("This two-second trial also checks named neighboring settings. Native tiers can affect more settings than the trial can inspect.", 0, y - 38, 836, W.colors.muted)
        action("Restore interrupted quality trial", 0, y - 100, 340, trial.Restore)
        action("Export Complete Diagnostic Report", 366, y - 100, 360, function() return ns.DiagnosticWindow.Open(runtime) end, "quiet")
        local status = trial.Status()
        if status.key then text("Captured " .. status.key .. " original: " .. ns.Report.Number(status.original), 0, y - 148, 836, W.colors.muted) end
        primary("Try selected level & restore", function() return trial.Test(key, ui.trialTarget) end)
        return math.max(474, -y + 190)
    end
    ui.labKey, ui.labProfile = ui.labKey or "Contrast", ui.labProfile or "balanced"
    W.Section(parent, "INDIVIDUAL CONTROLS", 0, -62, 836)
    local labels = { Contrast = "Contrast" }
    for _, candidate in ipairs(ns.Quality.Candidates) do labels[candidate.key] = candidate.label end
    for i, key in ipairs(ns.ExperimentPolicy.Keys) do
        local chosen = key
        local b = action(labels[key] or key, ((i - 1) % 3) * 284, -105 - math.floor((i - 1) / 3) * 38, 268, function()
            if lab.busy then return nil, "BUSY" end
            ui.labKey = chosen; ui.labTarget = nil; lab.Cancel(); return true
        end)
        b.SetSelected(ui.labKey == key)
    end
    local y = -105 - math.ceil(#ns.ExperimentPolicy.Keys / 3) * 38 - 26
    local item = ns.ReadOnly.Read(runtime.reader, ui.labKey)
    local bounds, reason = ns.ExperimentPolicy.Bounds(ui.labKey, item.raw)
    text((labels[ui.labKey] or ui.labKey) .. " now: " .. ns.Report.Number(item.raw), 0, y, 398)
    text(bounds and ("Test range: " .. bounds.min .. "–" .. bounds.max .. "  /  step " .. bounds.step)
        or ("Unavailable: " .. (reason or item.code)), 0, y - 30, 398, W.colors.muted)
    text("Value to try", 438, y, 220)
    local edit = W.Edit(env, parent, ui.labTarget or item.raw or "", 694, y + 5, 142, function(value) ui.labTarget = value end)
    primary("Test & Restore", function() ui.labTarget = edit:GetText(); return lab.Test(ui.labKey, ns.Value.Number(ui.labTarget)) end)
    y = y - 79
    ui.labStateText = text("", 0, y, 836, W.colors.accent)
    y = y - 46
    action("Preview exact modification (read only)", 0, y, 405, function()
        ui.labTarget = edit:GetText(); return lab.Preview(ui.labKey, ns.Value.Number(ui.labTarget))
    end)
    action("Cancel experiment / preview (does not restore)", 430, y, 406, lab.Cancel, "quiet")
    y = y - 58
    if lab.preview then
        for _, line in ipairs(lab.preview.lines) do text(line, 0, y, 836, W.colors.warning); y = y - 48 end
        local token = lab.preview.token
        action("Confirm displayed operation " .. token, 0, y, 405, function() return lab.Confirm(token) end)
        action("Export Complete Diagnostic Report", 430, y, 406, function() return ns.DiagnosticWindow.Open(runtime) end, "quiet")
        y = y - 60
    end
    W.Section(parent, "SAVE & RECOVER", 0, y, 836); y = y - 43
    if ui.labKey == "Contrast" then
        text("Set Contrast for each look in Visual Modes. Natural restores the captured original.", 0, y, 836, W.colors.muted)
        action("Edit visual modes", 0, y - 36, 220, function() ui.Open(1); return true end, "quiet")
        y = y - 91
    else
        for i, id in ipairs({ "balanced", "vista", "performance" }) do
            local profile = id
            local b = action(ns.Quality.Profiles[id], (i - 1) * 284, y, 268, function() ui.labProfile = profile; return true end)
            b.SetSelected(ui.labProfile == id)
        end
        y = y - 45
        action("Save value into " .. ns.Quality.Profiles[ui.labProfile], 0, y, 405, function()
            ui.labTarget = edit:GetText(); return lab.SaveProfile(ui.labProfile, ui.labKey, ns.Value.Number(ui.labTarget))
        end)
        action("Remove selected key from this saved profile", 430, y, 406, function()
            db.experiments.profiles[ui.labProfile][ui.labKey] = nil
            ns.Log.Record(runtime.reader, "configuration", "profile-remove-key", "INFO", "PASS", { profile = ui.labProfile, key = ui.labKey }); return true
        end, "quiet")
        y = y - 48
        for _, key in ipairs(ns.Value.Keys(db.experiments.profiles[ui.labProfile])) do
            text((labels[key] or key) .. " = " .. db.experiments.profiles[ui.labProfile][key], 0, y, 836, W.colors.muted); y = y - 26
        end
        action("Apply " .. ns.Quality.Profiles[ui.labProfile] .. " profile", 0, y, 405, function() return lab.SelectProfile(ui.labProfile) end)
        action("Current Baseline — restore owned quality", 430, y, 406, function() return lab.SelectProfile("currentBaseline") end)
        y = y - 54
    end
    action("Preview recovery of experimental visual settings", 0, y, 430, function() return lab.PreviewRestore("visual") end, "quiet")
    action("Preview recovery of experimental quality settings", 0, y - 40, 430, function() return lab.PreviewRestore("quality") end, "quiet")
    return -y + 90
end
