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
            if not ok and reason then ns.Diagnostics.Emit(runtime, "LumenShift: " .. reason .. ". See Diagnostic Center.") end
            ui.BuildPage()
        end); y = y - 40
    end
    line("Experimental calibration", 30, W.colors.accent)
    line("Choose a named leaf setting and an exact target. Preview is read-only. Confirming runs a bounded test, collects readbacks and watched changes, then restores the captured original if observations stay trustworthy.", 85)
    line("No test ran just by opening this page. Stop if the scene or game behaves unexpectedly. Readback cannot prove a rendered effect. Export the preview before starting; SavedVariables can lag behind disk.", 80, W.colors.muted)
    ui.labKey = ui.labKey or "Contrast"; ui.labProfile = ui.labProfile or "balanced"
    local start = y
    for i, key in ipairs(ns.ExperimentPolicy.Keys) do
        local chosen = key
        W.Button(env, parent, (ui.labKey == key and "* " or "") .. key, ((i - 1) % 2) * 275, start - math.floor((i - 1) / 2) * 38, 265,
            function()
                if lab.busy then ns.Diagnostics.Emit(runtime, "LumenShift: wait for calibration, or explicitly Cancel to retain recovery."); return end
                ui.labKey = chosen; ui.labTarget = nil; lab.Cancel(); ui.BuildPage()
            end)
    end
    y = start - math.ceil(#ns.ExperimentPolicy.Keys / 2) * 38 - 12
    local item = ns.ReadOnly.Read(runtime.reader, ui.labKey)
    local bounds, reason = ns.ExperimentPolicy.Bounds(ui.labKey, item.raw)
    line(ui.labKey .. " current=" .. ns.Report.Number(item.raw) .. " [" .. item.code .. "]", 30)
    if bounds then
        line("Test-policy range " .. bounds.min .. " to " .. bounds.max .. "; step " .. bounds.step .. ". " .. bounds.basis .. ". This is not a measured native safe range.", 65)
    else line("Calibration blocked: " .. (reason or "UNKNOWN_REASON") .. ". Export the diagnostic report for investigation.", 65) end
    W.Text(parent, "Exact proposed value (press Enter to retain edit)", 0, y, 370, 13)
    local edit = W.Edit(env, parent, ui.labTarget or item.raw or "", 380, y + 4, 160, function(text) ui.labTarget = text end)
    y = y - 42
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
    line("Use successful targets", 30, W.colors.accent)
    if ui.labKey == "Contrast" then
        line("After a successful round trip, edit Contrast in Visual Modes and enable it for that mode. The exact target must have passed calibration in this login. Natural restores its captured original independently of quality.", 85)
    else
        line("Quality profiles are your own explicit tested target sets. No guessed values are assigned to Balanced, Vista or Performance. Configure at most eight leaf settings per profile. Session calibration expires on reload.", 90)
        for _, id in ipairs({ "balanced", "vista", "performance" }) do
            local profile = id
            action((ui.labProfile == id and "* Editing " or "Edit ") .. ns.Quality.Profiles[id], function() ui.labProfile = profile; return true end)
        end
        action("Save tested target into " .. ns.Quality.Profiles[ui.labProfile], function()
            return lab.SaveProfile(ui.labProfile, ui.labKey, ns.Value.Number(ui.labTarget))
        end)
        for _, key in ipairs(ns.Value.Keys(db.experiments.profiles[ui.labProfile])) do
            line(key .. " = " .. db.experiments.profiles[ui.labProfile][key], 28)
        end
        action("Remove selected key from this saved profile", function()
            db.experiments.profiles[ui.labProfile][ui.labKey] = nil
            ns.Log.Record(runtime.reader, "configuration", "profile-remove-key", "INFO", "PASS", { profile = ui.labProfile, key = ui.labKey }); return true
        end)
        action("Apply " .. ns.Quality.Profiles[ui.labProfile] .. " tested target set", function() return lab.SelectProfile(ui.labProfile) end)
        action("Current Baseline — restore owned quality", function() return lab.SelectProfile("currentBaseline") end)
    end
    line("Shadow, lighting and water tiers, HDR and renderer settings are observation-only: their indirect writes/restart/hardware contracts are not mapped. Use the diagnostic report to see the actual read/capability results.", 90, W.colors.muted)
    return -y + 20
end
