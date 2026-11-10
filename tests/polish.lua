-- Offline regression tests, not native rendering or input acceptance.
return function(make, eq, test)
    local player, pet = "UnitNameFriendlyPlayerName", "UnitNameFriendlyPetName"
    test("POL01 HUD-only Camera exit preserves independent names ownership", function()
        local f = make(); assert(f.r.camera.ToggleNames()); f.flush()
        local original = f.r.db.camera.journal.entries[player].originalRaw
        local count = #f.calls
        assert(f.r.camera.Toggle()); assert(f.r.camera.Exit()); f.flush()
        eq(f.values[player], "0"); eq(#f.calls, count)
        eq(f.r.db.camera.journal.entries[player].originalRaw, original)
        assert(f.r.camera.ToggleNames()); f.flush(); eq(f.values[player], "1")
    end)
    test("POL02 Camera restores prior manual intent and keeps the first original", function()
        local f = make(nil, { [player] = "0", [pet] = "0" })
        assert(f.r.camera.ToggleNames()); f.flush(); eq(f.values[player], "1")
        f.r.db.camera.hideWithUI = true; assert(f.r.camera.Toggle()); f.flush()
        eq(f.values[player], "0"); eq(f.r.db.camera.nameReturn.targets[player], 1)
        assert(f.r.camera.Exit()); f.flush(); eq(f.values[player], "1")
        eq(f.r.db.camera.journal.entries[player].originalRaw, "0"); eq(f.r.db.camera.nameReturn, nil)
        assert(f.r.camera.ToggleNames()); f.flush(); eq(f.values[player], "0")
    end)
    test("POL03 reloaded Camera names intent is read-only until explicit restore", function()
        local f = make(); f.r.db.camera.hideWithUI = true
        assert(f.r.camera.Toggle()); f.flush()
        local g = make(f.r.db, f.values); eq(#g.calls, 0)
        assert(g.r.db.camera.nameReturn); assert(g.r.camera.Exit()); g.flush()
        eq(g.values[player], "1"); eq(g.values[pet], "0"); eq(g.r.db.camera.nameReturn, nil)
    end)
    test("POL04 Camera conflict retains session intent and names originals", function()
        local f = make(); f.r.db.camera.hideWithUI = true; assert(f.r.camera.Toggle()); f.flush()
        f.values[player] = "1"; f.r.names.Observe(); local count = #f.calls
        f.r.camera.Exit(); f.flush(); eq(#f.calls, count); assert(f.r.db.camera.nameReturn)
        eq(f.r.db.camera.journal.entries[player].originalRaw, "1")
        assert(f.r.camera.RestoreNames()); f.flush(); eq(f.r.db.camera.nameReturn, nil)
    end)
    test("POL05 capture cannot cross an exit and immediate re-entry", function()
        local f = make(); assert(f.r.camera.Toggle()); assert(f.r.composition.Capture())
        assert(f.r.camera.Exit()); assert(f.r.camera.Toggle()); f.flush()
        eq(f.captures, 0); eq(f.r.composition.status, "CAPTURE_CANCELLED")
        assert(f.r.composition.Capture()); f.tick(); eq(f.captures, 1)
        f.r.camera.Exit(); f.r.camera.Toggle()
        eq(f.r.composition.Capture(), nil) -- issued native request drains; no duplicate request
        f.flush(); eq(f.captures, 1); eq(f.r.composition.capturing, false)
    end)
    test("POL06 schema eleven upgrade preserves completion and rejects forged name intent", function()
        local f = make(); local old = f.ns.Value.Copy(f.r.db)
        old.schemaVersion, old.onboarding.completed = 11, true
        local copy, code = f.ns.Store.Open(old)
        eq(code, "MIGRATED_11_TO_17"); eq(copy.onboarding.completed, true); eq(copy.camera.nameReturn, nil)
        copy.camera.nameReturn = { targets = { Gamma = 1 } }; eq(f.ns.Store.Open(copy), nil)
        copy.camera.nameReturn = { targets = { [player] = 2 } }; eq(f.ns.Store.Open(copy), nil)
        copy.camera.nameReturn = { targets = {} }; assert(f.ns.Store.Open(copy))
    end)
    test("POL07 edit update reset and transfer preserve quality without graphics writes", function()
        local f = make(); local p, db = f.r.product, f.r.db
        local id = assert(p.SavePreset("My look", "nightVision"))
        p.Update(function(c) c.studio.modes.nightVision.brightness = 66 end)
        eq(p.EditPreset(id), "nightVision"); eq(db.config.studio.modes.nightVision.brightness, 75)
        p.Update(function(c) c.studio.modes.nightVision.brightness = 69 end)
        assert(p.UpdatePreset(id, "Night trail")); eq(db.config.studio.presets[id].settings.brightness, 69)
        p.Update(function(c) c.studio.modes.nightVision.brightness = 72 end)
        p.EditPreset(id); eq(db.config.studio.modes.nightVision.brightness, 69)
        local transfer = f.ns.StudioConfig.ExportPreset(db.config.studio, id)
        local imported = assert(p.ImportPreset("Imported", transfer))
        eq(db.config.studio.presets[imported].settings.brightness, 69)
        eq(db.config.selected.quality, "currentBaseline"); eq(#f.calls, 0)
        eq(p.UpdatePreset(id, "|bad"), nil); eq(db.config.studio.presets[id].name, "Night trail")
        assert(p.UpdatePreset(id, "Good")); eq(p.lastError, nil)
        local g = make(db, f.values); eq(g.r.db.config.studio.presets[id].name, "Good"); eq(#g.calls, 0)
    end)
    test("POL08 preset drafts survive rebuild and delete undo does not apply", function()
        local f = make(); local ui = f.r.ui; ui.Open(5)
        local function editAt(y)
            for _, n in ipairs(f.mock.nodes) do
                if n.kind == "EditBox" and n:IsVisible() and n.points[1][5] == y then return n end
            end
        end
        editAt(-77):SetText("Keep my typing"); editAt(-154):SetText("invalid paste")
        ui.RebuildInPlace(); eq(editAt(-77):GetText(), "Keep my typing"); eq(editAt(-154):GetText(), "invalid paste")
        f.mock.Click("Save variation"); eq(f.r.db.config.studio.presets.p1.name, "Keep my typing")
        f.mock.Click("Delete"); eq(f.r.db.config.studio.presets.p1, nil)
        f.mock.Click("Undo last deletion"); eq(f.r.db.config.studio.presets.p1.name, "Keep my typing")
        eq(#f.calls, 0)
    end)
    test("POL09 expanded setup scrolls with fixed actions and saves without applying", function()
        local f = make(); local ui = f.r.setup; ui.Open(); ui.page = 2
        ui.draft.graphics.normal.source = "level"; ui.draft.graphics.raidEnabled = "on"; ui.draft.graphics.raid.source = "level"
        ui.Build(); assert(ui.maximum > 0); eq(ui.bar:IsShown(), true)
        ui.scroll.scripts.OnMouseWheel(ui.scroll, -1); assert(ui.scroll:GetVerticalScroll() > 0)
        assert(ui.SaveAndClose()); eq(#f.calls, 0); eq(f.r.db.onboarding.completed, true)
        local g = make(f.r.db, f.values); g.r.setup.MaybeOpen(); eq(g.r.setup.window, nil); eq(#g.calls, 0)
    end)
    test("POL10 applying setup cannot be reopened or edited during verification", function()
        local f = make(); local ui = f.r.setup; ui.Open(); ui.page = 2
        ui.draft.graphics.normal.source = "level"; ui.draft.graphics.normal.level = 4; ui.Build()
        assert(ui.Finish()); eq(ui.finishing, true); eq(ui.Open(), nil)
        local page = ui.page; f.mock.Click("1  Appearance"); eq(ui.page, page)
        f.mock.Click("Save & Close"); eq(ui.window:IsShown(), true)
        f.flush(); eq(f.reloads, 1); eq(f.r.db.graphics.choices.normal.level, 4)
    end)
    test("POL11 failed setup apply retains saved preferences without reloading", function()
        local f = make(); f.setter = function(key, target, count)
            if count == 1 then f.values[key] = target end
            return false
        end
        local ui = f.r.setup; ui.Open(); ui.page = 2; ui.draft.sound = false; ui.draft.graphics.normal.source = "level"; ui.draft.graphics.normal.level = 4
        ui.Build(); ui.Finish(); f.flush()
        eq(f.reloads, 0); eq(ui.finishing, false); eq(ui.window.lumenInputBlocked, false)
        eq(f.r.db.config.preferences.sound, false); eq(f.r.db.onboarding.completed, true)
        assert(ui.SaveAndClose()); assert(next(f.r.db.graphics.records))
    end)
    test("POL12 keyboard focus skips hidden controls and yields to native chat editing", function()
        local f = make(); local ui = f.r.ui; ui.Open(5)
        local key = ui.window.scripts.OnKeyDown
        key(ui.window, "TAB"); assert(ui.keyboard.current); eq(ui.window.SetPropagateKeyboardInputArgs[1], false)
        eq(ui.keyboard.current.lumenFocusRing:IsShown(), true)
        local current = ui.keyboard.current
        local chat = f.env.CreateFrame("EditBox", nil, f.env.UIParent); chat:SetFocus()
        key(ui.window, "TAB"); eq(ui.keyboard.current, current); eq(ui.window.SetPropagateKeyboardInputArgs[1], true)
        chat:ClearFocus(); f.env.IsShiftKeyDown = function() return true end
        key(ui.window, "TAB"); assert(ui.keyboard.current ~= current)
        ui.window:Hide(); eq(ui.keyboard.current, nil)
        eq(#f.calls, 0)
    end)
    test("POL13 pooled edits release focus and keyboard scroll reaches lower presets", function()
        local f = make(); for i = 1, 10 do assert(f.r.product.SavePreset("Look " .. i, "nightVision")) end
        local ui = f.r.ui; ui.Open(5)
        local found
        for _ = 1, 100 do
            ui.keyboard.Move(1)
            if ui.scroll:GetVerticalScroll() > 0 then found = true; break end
        end
        assert(found); assert(ui.keyboard.current)
        ui.Open(1); eq(f.mock.focus, nil); eq(#f.calls, 0)
    end)
    test("POL14 resize handles fit windows and reduced motion stops an existing fade", function()
        local f = make(); local ui = f.r.ui; ui.Open(1); assert(ui.window.lumenFade.playing)
        f.r.db.config.preferences.reducedMotion = true
        f.ns.Widgets.Fade(ui.window, f.r.db.config.preferences); eq(ui.window.lumenFade.playing, false); eq(ui.window.alpha, 1)
        for _, size in ipairs({ { 1024, 768 }, { 1366, 768 }, { 2560, 1080 } }) do
            f.env.UIParent:SetSize(unpack(size)); ui.window.scripts.OnEvent(ui.window, "DISPLAY_SIZE_CHANGED")
            assert(ui.window:GetWidth() * ui.window.scale < size[1]); assert(ui.window:GetHeight() * ui.window.scale < size[2])
        end
        f.r.setup.Open(); f.env.UIParent:SetSize(1024, 768)
        f.r.setup.window.scripts.OnEvent(f.r.setup.window, "DISPLAY_SIZE_CHANGED")
        assert(f.r.setup.window:GetHeight() * f.r.setup.window.scale < 768); eq(#f.calls, 0)
    end)
    test("POL15 normal FPS status is readable while reports retain technical evidence", function()
        local f = make(); assert(f.r.performance.Start()); assert(f.r.performance.Text():match("Settling"))
        f.tick(); f.tick(); assert(f.r.performance.Text():match("Reading 1 of 10"))
        f.flush(); assert(f.r.performance.Text():match("Observation complete")); eq(#f.calls, 0)
        assert(f.ns.Report.Export(f.r):match("COMPLETE"))
    end)
    test("POL16 keyboard activation reaches buttons and fields without hidden writes", function()
        local f = make(); local ui = f.r.ui; ui.Open(5)
        local key = ui.window.scripts.OnKeyDown
        for _ = 1, 80 do
            ui.keyboard.Move(1)
            if ui.keyboard.current.label and ui.keyboard.current.label:GetText() == "Save variation" then break end
        end
        eq(ui.keyboard.current.label:GetText(), "Save variation"); key(ui.window, "ENTER")
        assert(f.r.db.config.studio.presets.p1); eq(#f.calls, 0)
        for _ = 1, 80 do ui.keyboard.Move(1); if ui.keyboard.current.lumenEdit then break end end
        local edit = ui.keyboard.current; eq(f.mock.focus, edit)
        edit.scripts.OnTabPressed(edit); assert(ui.keyboard.current ~= edit)
        ui.window:Hide(); eq(f.mock.focus, nil)
    end)
    test("POL17 name restore failure retains return intent without automatic retries", function()
        local f = make(); f.r.db.camera.hideWithUI = true; assert(f.r.camera.Toggle()); f.flush()
        f.setter = function() return false end
        f.r.camera.Exit(); f.flush(); assert(f.r.db.camera.nameReturn)
        assert(f.r.db.camera.journal.entries[player]); local count = #f.calls
        local g = make(f.r.db, f.values); eq(#g.calls, 0); assert(g.r.db.camera.nameReturn)
        eq(#f.calls, count); assert(g.r.camera.RestoreNames()); g.flush(); eq(g.values[player], "1")
    end)
    if os.getenv("LUMENSHIFT_UI_MODEL_PATH") then
        local f = make(); local path = os.getenv("LUMENSHIFT_UI_MODEL_PATH")
        f.r.product.SavePreset("Night trail", "nightVision"); f.r.ui.editingPreset = "p1"
        f.r.ui.Open(5); f.mock.Export(path .. "-presets.tsv")
        f.r.setup.Open(); f.mock.Export(path .. "-welcome.tsv")
        f.r.setup.page = 2; f.r.setup.draft.graphics.normal.source = "level"
        f.r.setup.draft.graphics.raidEnabled = "on"; f.r.setup.draft.graphics.raid.source = "level"; f.r.setup.Build()
        f.mock.Export(path .. "-setup-graphics.tsv")
    end
end
