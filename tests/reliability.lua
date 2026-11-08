return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function make(saved)
        local f = fixture(saved); f.mock = widgets(f.env); f.calls = {}
        f.values.Brightness, f.values.Contrast = "052.00", "060.00"
        f.env.SetUIVisibility = function(shown) if shown then f.env.UIParent:Show() else f.env.UIParent:Hide() end end
        f.env.C_CVar.SetCVar = function(key, raw)
            local db = f.env.LumenShiftDB
            local entry = db.journal.entries[key] or db.experiments.journal.entries[key]
            assert(entry and entry.originalRaw, "capture before every write")
            f.calls[#f.calls + 1] = { key, raw }
            if f.setter then return f.setter(key, raw, #f.calls) end
            f.values[key] = raw; return true
        end
        f.load(); f.r = f.ns.runtime; f.p = f.r.product
        f.r.db.config.studio.modes.nightVision.useContrast = true
        f.r.db.config.studio.modes.nightVision.contrast = 65
        function f.select(id) assert(f.p.Select(id)); f.mock.Flush() end
        return f
    end
    test("R01 composite captures both originals before first setter and commits after fresh verification", function()
        local f = make()
        f.setter = function(key, raw)
            eq(f.r.db.journal.entries.Brightness.originalRaw, "052.00")
            eq(f.r.db.experiments.journal.entries.Contrast.originalRaw, "060.00")
            f.values[key] = raw; return true
        end
        assert(f.p.Select("nightVision")); eq(f.p.state, "APPLYING"); eq(#f.calls, 2)
        f.mock.Flush(); eq(f.p.state, "ACTIVE"); eq(f.p.active, "nightVision")
        eq(f.r.engine.Status().state, "ACTIVE"); eq(f.r.lab.state, "ACTIVE")
        f.setter = nil; f.select("natural")
        eq(f.values.Brightness, "052.00"); eq(f.values.Contrast, "060.00")
        eq(next(f.r.db.journal.entries), nil); eq(next(f.r.db.experiments.journal.entries), nil)
    end)
    test("R02 failed second setter restores exact pre-operation values and previous active mode", function()
        local f = make(); f.select("cinematic")
        local priorOpacity = f.p.appliedSettings.opacity
        f.r.db.config.studio.modes.cinematic.opacity = 0.11 -- unsaved-to-scene editor change
        f.setter = function(key, raw) if key == "Contrast" then return false end; f.values[key] = raw; return true end
        assert(f.p.Select("nightVision")); f.mock.Flush()
        eq(f.values.Brightness, "42"); eq(f.values.Contrast, "060.00")
        eq(f.p.active, "cinematic"); eq(f.p.state, "ACTIVE"); eq(f.p.lastError, "MODE_COMPENSATED")
        eq(f.p.appliedSettings.opacity, priorOpacity); eq(f.r.presentation.tint.color[4], priorOpacity)
        eq(f.r.db.journal.entries.Brightness.originalRaw, "052.00"); eq(f.r.db.experiments.journal.entries.Contrast, nil)
    end)
    test("R03 clamping and failed compensation retain both originals and honest partial label", function()
        local f = make()
        f.setter = function(key, raw) f.values[key] = key == "Contrast" and "55" or raw; return true end
        eq(f.p.Select("nightVision"), nil); f.mock.Flush()
        eq(f.p.ActiveLabel(), "Partial / Recovery"); eq(f.p.state, "PARTIAL")
        eq(f.r.db.journal.entries.Brightness.originalRaw, "052.00")
        eq(f.r.db.experiments.journal.entries.Contrast.originalRaw, "060.00")
        local n = #f.calls; f.p.Observe(); f.mock.Flush(); eq(#f.calls, n)
        f.setter = nil; f.r.ui.Open(7); f.mock.Click("Restore captured visuals"); f.mock.Flush()
        eq(f.values.Brightness, "052.00"); eq(f.values.Contrast, "060.00"); eq(f.p.state, "IDLE")
        local refreshed = false
        for _, node in ipairs(f.mock.nodes) do
            if node.kind == "FontString" and node:IsVisible() and node.text
                and node.text:find("CONTRAST  060.00", 1, true) and node.text:find("CAPTURED ORIGINAL  unavailable", 1, true) then refreshed = true end
        end
        eq(refreshed, true)
    end)
    test("R04 external edit between members is preserved with no compensating overwrite", function()
        local f = make()
        f.setter = function(key, raw) f.values[key] = raw; f.values.Contrast = "67"; return true end
        eq(f.p.Select("nightVision"), nil); eq(#f.calls, 1); eq(f.values.Contrast, "67")
        eq(f.values.Brightness, "75"); eq(f.p.state, "PARTIAL")
        eq(f.r.db.experiments.journal.entries.Contrast.originalRaw, "060.00")
    end)
    test("R05 delayed drift never auto-restores and no other writer can reenter mode application", function()
        local f = make()
        f.setter = function(key, raw)
            eq(f.r.engine.Switch(70), nil); eq(f.r.lab.Apply("visual", { Contrast = 66 }), nil)
            eq(f.r.visual.Apply({ Brightness = 70 }), nil)
            f.values[key] = raw; return true
        end
        assert(f.p.Select("nightVision")); f.values.Brightness = "68"; f.mock.Flush()
        eq(#f.calls, 2); eq(f.values.Brightness, "68"); eq(f.p.state, "PARTIAL")
        eq(f.r.db.journal.entries.Brightness.originalRaw, "052.00")
    end)
    test("R06 pending reload preserves journals and zero startup/diagnostic writes", function()
        local f = make(); assert(f.p.Select("nightVision"))
        local g = make(f.r.db); eq(#g.calls, 0)
        eq(g.r.db.journal.entries.Brightness.state, "pending")
        eq(g.r.db.experiments.journal.entries.Contrast.state, "pending")
        g.ns.Report.Export(g.r); g.r.ui.Open(7); eq(#g.calls, 0)
        eq(g.p.Select("nightVision"), nil); eq(#g.calls, 0)
    end)
    test("R07 timer failure and combat during verification retain recovery without retries", function()
        for _, fault in ipairs({ "timer", "combat" }) do
            local f = make()
            if fault == "timer" then f.env.C_Timer.After = function() error("no timer") end end
            f.p.Select("nightVision")
            if fault == "combat" then f.env.InCombatLockdown = function() return true end end
            f.mock.Flush(); eq(#f.calls, 2); eq(f.p.state, "PARTIAL")
            eq(f.r.db.journal.entries.Brightness.originalRaw, "052.00")
        end
    end)
    test("R08 explicit recovery does not reapply uncertain values on failure", function()
        local f = make(); f.select("nightVision"); f.values.Brightness, f.values.Contrast = "68", "67"
        f.setter = function() return false end
        local n = #f.calls; eq(f.p.RestoreVisuals(), nil); f.mock.Flush()
        eq(#f.calls, n + 1); eq(f.values.Brightness, "68"); eq(f.values.Contrast, "67")
        eq(f.r.db.journal.entries.Brightness.originalRaw, "052.00")
        eq(f.r.db.experiments.journal.entries.Contrast.originalRaw, "060.00")
    end)
    test("R09 composite observation-only release uses zero setters", function()
        local f = make(); f.select("nightVision")
        f.values.Brightness, f.values.Contrast = "052.00", "060.00"
        local n = #f.calls; assert(f.p.RestoreVisuals()); f.mock.Flush()
        eq(#f.calls, n); eq(next(f.r.db.journal.entries), nil); eq(next(f.r.db.experiments.journal.entries), nil)
    end)
    test("R10 Camera effects survive HUD hiding and respect the saved opt-out", function()
        local f = make(); f.select("nightVision"); f.r.db.camera.hideWithUI = false
        local n = #f.calls; assert(f.r.camera.Toggle()); eq(f.env.UIParent:IsShown(), false)
        eq(f.r.presentation.frame:GetParent(), nil); eq(f.r.presentation.frame:IsVisible(), true)
        eq(f.r.presentation.Status(), "VISIBLE"); eq(#f.calls, n)
        f.r.db.camera.keepEffects = false; assert(f.p.RefreshPresentation())
        eq(f.r.presentation.frame:IsVisible(), false); eq(f.r.presentation.Status(), "HIDDEN_WITH_UI")
        f.env.UIParent:Show(); eq(f.r.presentation.frame:IsVisible(), true); eq(#f.calls, n)
    end)
    test("R11 combat resumes cosmetics only after validation and does not replay cues", function()
        local f = make(); f.select("nightVision"); local n, sounds = #f.calls, #f.mock.soundCalls
        f.env.InCombatLockdown = function() return true end; f.frame.OnEvent(f.frame, "PLAYER_REGEN_DISABLED")
        eq(f.r.presentation.frame:IsVisible(), false)
        f.env.InCombatLockdown = function() return false end; f.frame.OnEvent(f.frame, "PLAYER_REGEN_ENABLED")
        eq(f.r.presentation.frame:IsVisible(), true); eq(#f.calls, n); eq(#f.mock.soundCalls, sounds)
        f.frame.OnEvent(f.frame, "PLAYER_REGEN_DISABLED"); f.values.Brightness = "68"
        f.frame.OnEvent(f.frame, "PLAYER_REGEN_ENABLED"); eq(f.r.presentation.frame:IsVisible(), false); eq(#f.calls, n)
    end)
    test("R12 viewport edges scale with viewport dimensions without touching HUD geometry", function()
        local f = make(); f.select("nightVision"); local p = f.r.presentation
        eq(p.edges[1]:GetHeight(), 80); eq(p.edges[3]:GetWidth(), 80)
        f.env.UIParent:SetSize(3440, 1440); f.env.UIParent:SetScale(0.7)
        p.frame.scripts.OnEvent(p.frame, "UI_SCALE_CHANGED")
        eq(p.edges[1]:GetHeight(), 144); eq(p.edges[3]:GetWidth(), 144); eq(p.frame.scale, 0.7)
        eq(f.env.UIParent:GetWidth(), 3440); eq(f.env.UIParent:GetHeight(), 1440)
    end)
    test("R13 unavailable bloom affects only its own control and is checked again before writing", function()
        for _, value in ipairs({ false, "unexpected", "error", "absent" }) do
            local f = make(); f.values.bloomUserMult = "0.2"
            f.env.C_VideoOptions.IsLinearEnabledOnStart = function()
                if value == "error" then error("private") end; return value
            end
            if value == "absent" then f.env.C_VideoOptions.IsLinearEnabledOnStart = nil end
            local ok, why = f.r.lab.CanApply("quality", { bloomUserMult = 0.4 })
            eq(ok, nil); assert(why:find("BLOOM_")); eq(#f.calls, 0)
            f.select("nightVision"); eq(f.p.active, "nightVision")
        end
        local f = make(); f.values.bloomUserMult = "0.2"
        assert(f.r.lab.Preview("bloomUserMult", 0.4))
        f.env.C_VideoOptions.IsLinearEnabledOnStart = function() return false end
        eq(f.r.lab.Confirm(f.r.lab.Status().token), nil); eq(#f.calls, 0)
        f.env.C_VideoOptions = true
        local ok, why = f.ns.ExperimentPolicy.Capability(f.r.reader, "bloomUserMult")
        eq(ok, nil); eq(why, "BLOOM_CAPABILITY_UNAVAILABLE")
    end)
    test("R14 schema-7 migration keeps completed setup, presets and pending originals", function()
        local f = make(); assert(f.p.Select("nightVision"))
        local old = f.ns.Value.Copy(f.r.db); old.schemaVersion = 7; old.camera.keepEffects = nil; old.onboarding.completed = true
        local copy, code = f.ns.Store.Open(old); eq(code, "MIGRATED_7_TO_12")
        eq(copy.camera.keepEffects, true); eq(copy.onboarding.completed, true); eq(old.camera.keepEffects, nil)
        eq(copy.journal.entries.Brightness.originalRaw, "052.00"); eq(copy.journal.entries.Brightness.state, "pending")
        copy.camera.keepEffects = "yes"; eq(f.ns.Store.Open(copy), nil)
    end)
    test("R15 legacy writer and lab preflight callbacks cannot reenter composite writes", function()
        for _, source in ipairs({ "brightness", "lab" }) do
            local f = make(); local get = f.env.C_CVar.GetCVar; local nested = false
            f.env.C_CVar.GetCVar = function(key)
                if not nested then
                    nested = true
                    eq(f.r.visual.Apply({ Brightness = 70, Contrast = 66 }), nil)
                    nested = false
                end
                return get(key)
            end
            if source == "brightness" then assert(f.r.engine.Prepare("on"))
            else assert(f.r.lab.CanApply("visual", { Contrast = 65 })) end
            eq(#f.calls, 0)
        end
    end)
    test("R16 supported bloom applies/restores while unsupported UI does not disable other pages", function()
        local f = make(); f.values.bloomUserMult = "0.2"
        assert(f.r.lab.Apply("quality", { bloomUserMult = 0.4 })); f.mock.Flush(); eq(f.values.bloomUserMult, "0.4")
        assert(f.r.lab.Apply("quality", {})); f.mock.Flush(); eq(f.values.bloomUserMult, "0.2")
        f.env.C_VideoOptions.IsLinearEnabledOnStart = nil
        f.r.ui.labKey = "bloomUserMult"; f.r.ui.Open(8); eq(f.r.ui.primary:IsEnabled(), false)
        f.r.ui.Open(1); eq(f.r.ui.primary:IsEnabled(), true)
    end)

end
