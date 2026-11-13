local _, ns = ...
local U, W = {}, ns.Widgets
ns.PresetsUI = U
function U.Build(runtime, ui, parent, env)
    local product, cfg = runtime.product, runtime.db.config.studio
    local function refresh() ui.RebuildInPlace() end
    local function feedback(message)
        product.lastError, product.lastMessage = nil, message; ui.Refresh()
    end
    W.Section(parent, "SAVE A VARIATION", 0, 0, 836)
    W.Text(parent, "Source: " .. ns.StudioConfig.Label(ui.edited) .. ". Save keeps a separate copy of its editor settings.", 0, -42, 820, 13, W.colors.muted)
    ui.presetName = ui.presetName or "My " .. ns.StudioConfig.Label(ui.edited)
    local name = W.Edit(env, parent, ui.presetName, 0, -77, 406, function(value) ui.presetName = value end, 40)
    W.Script(name, "OnTextChanged", function(self) ui.presetName = self:GetText() end)
    W.Button(env, parent, "Choose / edit source mode", 430, -77, 290, function() ui.Open(1) end, nil, "quiet")
    ui.Primary("Save variation", function()
        local id = product.SavePreset(name:GetText(), ui.edited)
        if id then ui.editingPreset = id end
        refresh()
    end, "Save and Update store settings only. Each preset's Apply button changes the scene.")
    if ui.edited == "natural" then
        ui.primary:Disable()
        W.Text(parent, "Choose a mode other than Original to save a variation.", 0, -118, 820, 12, W.colors.warning)
    end
    local transfer = W.Edit(env, parent, ui.presetTransfer or "", 0, -154, 836, function(value) ui.presetTransfer = value end, 2048)
    W.Script(transfer, "OnTextChanged", function(self) ui.presetTransfer = self:GetText() end)
    if ui.focusTransfer then transfer:SetFocus(); transfer:HighlightText(); ui.focusTransfer = nil end
    W.Button(env, parent, "Import preset", 0, -197, 180, function()
        product.ImportPreset(name:GetText(), transfer:GetText()); refresh()
    end)
    W.Text(parent, "Paste the complete LSMODE code above. Import saves without applying.", 204, -202, 628, 12, W.colors.muted)
    W.Section(parent, "YOUR PRESETS", 0, -251, 836)
    local ids = ns.Value.Keys(cfg.presets)
    if #ids == 0 then W.Text(parent, "Your saved looks will appear here.", 0, -298, 820, 16, W.colors.muted) end
    for i, id in ipairs(ids) do
        local presetID, preset = id, cfg.presets[id]
        local x, y = ((i - 1) % 2) * 430, -295 - math.floor((i - 1) / 2) * 188
        local editing = ui.editingPreset == id
        W.Text(parent, ns.StudioConfig.Label(preset.mode) .. (editing and " · EDITING" or ""), x, y, 406, 12, editing and W.colors.accent or W.colors.muted)
        W.Edit(env, parent, preset.name, x, y - 24, 406, function(value)
            if not ns.StudioConfig.Name(value) then feedback(ns.Product.Message("INVALID_PRESET_NAME")); return end
            product.Update(function(copy) copy.studio.presets[presetID].name = value end)
            feedback("Preset renamed.")
        end, 40)
        W.Button(env, parent, "Apply", x, y - 64, 90, function() product.LoadPreset(presetID) end)
        W.Button(env, parent, "Edit", x + 102, y - 64, 90, function()
            local mode = product.EditPreset(presetID)
            if mode then ui.editingPreset, ui.edited = presetID, mode; ui.Open(1) end
        end, nil, "quiet")
        W.Button(env, parent, "Export", x + 204, y - 64, 90, function()
            ui.presetTransfer = ns.StudioConfig.ExportPreset(runtime.db.config.studio, presetID)
            ui.focusTransfer = true; ui.BuildPage()
        end, nil, "quiet")
        W.Button(env, parent, "Delete", x + 306, y - 64, 100, function()
            ui.deletedPreset = { id = presetID, value = ns.Value.Copy(runtime.db.config.studio.presets[presetID]) }
            product.Update(function(copy) copy.studio.presets[presetID] = nil end)
            if ui.editingPreset == presetID then ui.editingPreset = nil end
            refresh(); feedback("Preset deleted. Undo is available below until you leave this session.")
        end, nil, "quiet")
        if editing then
            W.Button(env, parent, "Update from mode editor", x, y - 106, 240, function()
                product.UpdatePreset(presetID, runtime.db.config.studio.presets[presetID].name); refresh()
            end)
            W.Button(env, parent, "Reset editor", x + 252, y - 106, 154, function()
                product.EditPreset(presetID); refresh()
            end, "Discard editor changes for this mode and reload the saved preset. Does not apply.", "quiet")
        end
    end
    local bottom = 310 + math.ceil(#ids / 2) * 188
    if ui.deletedPreset then
        W.Button(env, parent, "Undo last deletion", 0, -bottom, 240, function()
            local removed = ui.deletedPreset
            local ok = product.Update(function(copy)
                assert(not copy.studio.presets[removed.id]); copy.studio.presets[removed.id] = ns.Value.Copy(removed.value)
            end)
            if ok then ui.deletedPreset = nil; refresh(); feedback("Preset restored to your list.") end
        end, nil, "quiet")
        bottom = bottom + 46
    end
    return math.max(474, bottom)
end
