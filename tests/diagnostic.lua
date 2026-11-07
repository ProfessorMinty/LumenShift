return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function setup(saved, values)
        local f = fixture(saved)
        f.mock = widgets(f.env); f.calls = {}
        for _, key in ipairs(f.ns.Catalog.WatchKeys()) do if not f.values[key] then f.values[key] = "100" end end
        f.values.ResampleSharpness, f.values.ResampleAlwaysSharpen, f.values.bloomUserMult = "1", "0", "0.2"
        f.values.RenderScale, f.values.Gamma, f.values.gxapi = "1", "1", "D3D12"
        for key, value in pairs(values or {}) do f.values[key] = value end
        f.env.GetTime = function() return 10 + #f.calls end
        f.env.GetServerTime = function() return 100000 end
        f.env.GetPhysicalScreenSize = function() return 2560, 1440 end
        f.env.C_CVar.SetCVar = function(key, target)
            f.calls[#f.calls + 1] = { key, target }
            local db = f.env.LumenShiftDB
            local held = key == "Brightness" and db.journal.entries[key] or db.experiments.journal.entries[key]
            assert(held and held.originalRaw, "original must precede native setter")
            if f.setter then return f.setter(key, target, #f.calls) end
            f.values[key] = target; return true
        end
        f.load(); f.runtime = f.ns.runtime; f.lab = f.runtime.lab; f.product = f.runtime.product; f.ui = f.runtime.ui
        function f.calibrate(key, target)
            local ok, why = f.lab.Preview(key, target); assert(ok, why)
            assert(f.lab.Confirm(f.lab.Status().token)); f.mock.Flush()
            assert(f.lab.certificates[key] and f.lab.certificates[key][tostring(target)], f.lab.lastError)
        end
        function f.enable() assert(f.product.Enable(true)) end
        function f.select(id) local ok, why = f.product.Select(id); assert(ok, why); f.mock.Flush() end
        return f
    end
    test("D01 startup read-only diagnostics collect real API fixture results without graphics or audio", function()
        local f = setup(); eq(#f.calls, 0); eq(#f.mock.soundCalls, 0); f.zero()
        local report = f.ns.Report.Export(f.runtime)
        assert(report:find("2560x1440", 1, true)); assert(report:find("date Nov 4 2026", 1, true))
        assert(report:find("Renderer (gxapi): d3d12", 1, true)); assert(report:find("NOT TESTED | native-writes", 1, true))
        eq(f.runtime.storeStatus, "NEW"); assert(#f.runtime.checks > 40)
    end)
    test("D02 report privacy excludes user names, paths, arbitrary metadata and native exception text", function()
        local f = setup(); assert(f.product.SavePreset("Private Character", "nightVision"))
        f.values.gxapi = "PRIVATE_ACCOUNT_123"
        f.runtime.log.Guard("ui", "private-error", function() error("SECRET_ACCOUNT C:/Private/Path PlayerName") end)()
        f.runtime.log.Add("ui", "test", "ERROR", "SAFE_CODE", { original = "PRIVATE_NUMBER", detail = "C:/Private/Path", account = "PRIVATE_ACCOUNT_123" })
        local report = f.ns.Report.Export(f.runtime)
        for _, token in ipairs({ "Private Character", "PRIVATE_ACCOUNT_123", "SECRET_ACCOUNT", "C:/Private/Path", "PlayerName", "PRIVATE_NUMBER" }) do
            eq(report:find(token, 1, true), nil)
        end
        assert(report:find("REDACTED", 1, true)); assert(report:find("OWNED_HANDLER_ERROR", 1, true)); eq(#f.calls, 0)
    end)
    test("D03 event history and issue history remain bounded, ordered and independent", function()
        local f = setup(); local log = f.runtime.log
        for i = 1, 1000 do log.Add("test", "bounded", i % 2 == 0 and "ERROR" or "DEBUG", "RESULT", { count = i }) end
        local history = log.History(); eq(#history, 240); eq(#log.issues, 32)
        eq(history[240].sequence, log.sequence); eq(history[1].sequence, log.sequence - 239)
        history[1].result = "modified"; assert(log.History()[1].result ~= "modified")
        assert(log.dropped >= 760); assert(#f.ns.Report.Export(f.runtime) <= 120000); eq(#f.calls, 0)
    end)
    test("D04 dedicated export supports Select All and scroll, reuses its window and never writes", function()
        local f = setup(); assert(f.ns.DiagnosticWindow.Open(f.runtime))
        local export = f.runtime.exportUI
        eq(export.box.focus, true); eq(export.box.highlight[1], 0); eq(export.box.highlight[2], -1)
        assert(export.maximum > 0); assert(export.box:GetText():find("END LUMENSHIFT REPORT", 1, true))
        local count = #f.mock.nodes
        for _ = 1, 20 do f.env.SlashCmdList.LUMENSHIFT("report") end
        eq(#f.mock.nodes, count); eq(#f.calls, 0); eq(#f.mock.soundCalls, 0)
        export.box:SetText("altered"); export.box.scripts.OnTextChanged(export.box, true)
        eq(export.box:GetText(), export.text); f.zero()
    end)
    test("D05 guarded addon UI errors remain exportable without capturing unrelated global errors", function()
        local f = setup(); f.ui.Open(1)
        local button = f.ns.Widgets.Button(f.env, f.ui.window, "test", 0, 0, 100, function() error("PRIVATE_ERROR") end)
        local ok = pcall(button.scripts.OnClick, button); eq(ok, true)
        assert(f.runtime.log.counts.ERROR >= 1); eq(f.env.geterrorhandler, nil)
        f.env.SlashCmdList.LUMENSHIFT("report"); assert(f.runtime.exportUI.window:IsShown()); eq(#f.calls, 0)
    end)
    test("D06 checks and report cannot complete or restore a pending experiment", function()
        local f = setup(); assert(f.lab.Preview("Contrast", 65)); assert(f.lab.Confirm(f.lab.Status().token))
        eq(#f.calls, 1)
        f.ns.Report.Run(f.runtime, "user"); f.ns.Report.Export(f.runtime); eq(#f.calls, 1); eq(f.lab.busy, true)
        f.mock.Flush(); eq(#f.calls, 2); eq(f.values.Contrast, "60")
    end)
    test("D07 Contrast calibration captures exact raw original, verifies twice and restores automatically", function()
        local f = setup(nil, { Contrast = "060.00" }); assert(f.lab.Preview("Contrast", 65)); eq(#f.calls, 0)
        assert(f.lab.preview.lines[4]:find("original=060.00", 1, true))
        assert(f.lab.Confirm(f.lab.Status().token)); eq(f.values.Contrast, "65")
        eq(f.lab.certificates.Contrast, nil); f.mock.Flush()
        eq(f.values.Contrast, "060.00"); eq(#f.calls, 2); eq(f.lab.state, "BASELINE")
        eq(next(f.env.LumenShiftDB.experiments.journal.entries), nil)
        assert(f.lab.certificates.Contrast["65"])
        local report = f.ns.Report.Export(f.runtime)
        for _, text in ipairs({ "setter", "immediate", "followup", "ROUNDTRIP_PASS_VISUAL_EFFECT_NOT_TESTED", "060.00" }) do assert(report:find(text, 1, true)) end
    end)
    test("D08 excluded keys, unsafe values, bad steps and same-value tests never become writes", function()
        local f = setup()
        for _, pair in ipairs({ { "graphicsShadowQuality", 3 }, { "Brightness", 75 }, { "Unknown", 1 },
            { "Contrast", 101 }, { "Contrast", 60 }, { "Contrast", 60.5 }, { "ResampleAlwaysSharpen", 0.5 }, { "farclip", 5000 } }) do
            eq(f.lab.Preview(pair[1], pair[2]), nil)
        end
        eq(f.lab.Preview("Contrast", 0/0), nil); eq(#f.calls, 0); f.zero()
    end)
    test("D09 fresh preview changes and single-use tokens prevent stale writes", function()
        local f = setup(); assert(f.lab.Preview("Contrast", 65)); local token = f.lab.Status().token
        f.values.Contrast = "61"; eq(f.lab.Confirm(token), nil); eq(#f.calls, 0)
        eq(f.lab.Confirm(token), nil); assert(f.lab.Preview("Contrast", 65))
        f.env.LumenShiftDB.experiments.journal.nextEpoch = 2
        eq(f.lab.Confirm(f.lab.Status().token), nil); eq(#f.calls, 0)
    end)
    test("D10 late drift retains the original and requires a new explicit recovery confirmation", function()
        local f = setup(); assert(f.lab.Preview("Contrast", 65)); assert(f.lab.Confirm(f.lab.Status().token))
        f.values.Contrast = "66"; f.mock.Flush(); eq(#f.calls, 1); eq(f.lab.state, "RECOVERY")
        eq(f.env.LumenShiftDB.experiments.journal.entries.Contrast.originalRaw, "60")
        assert(f.lab.PreviewRestore("visual")); eq(#f.calls, 1)
        assert(f.lab.Confirm(f.lab.Status().token)); f.mock.Flush(); eq(f.values.Contrast, "60")
        eq(f.lab.certificates.Contrast, nil); eq(f.lab.state, "BASELINE")
    end)
    test("D11 false, nil, thrown, clamped and no-op setters cannot earn calibration permission", function()
        for _, kind in ipairs({ "false", "nil", "throw", "clamp", "noop" }) do
            local f = setup()
            f.setter = function(key, target, index)
                if index > 1 then f.values[key] = target; return true end
                if kind ~= "noop" then f.values[key] = kind == "clamp" and "66" or target end
                if kind == "throw" then error("PRIVATE_EXCEPTION") end
                if kind == "false" then return false elseif kind == "nil" then return nil end
                return true
            end
            assert(f.lab.Preview("Contrast", 65)); f.lab.Confirm(f.lab.Status().token); f.mock.Flush()
            eq(f.values.Contrast, "60"); eq(f.lab.certificates.Contrast, nil)
            assert(#f.calls <= 2); eq(f.lab.state, "BASELINE")
            eq(f.ns.Report.Export(f.runtime):find("PRIVATE_EXCEPTION", 1, true), nil)
        end
    end)
    test("D12 explicit recovery failure never reapplies an uncertain prior target", function()
        local f = setup(); assert(f.lab.Preview("Contrast", 65)); assert(f.lab.Confirm(f.lab.Status().token))
        f.values.Contrast = "67"; f.mock.Flush()
        f.setter = function() return false end
        assert(f.lab.PreviewRestore("visual")); f.lab.Confirm(f.lab.Status().token); f.mock.Flush()
        eq(#f.calls, 2); eq(f.values.Contrast, "67"); eq(f.lab.state, "RECOVERY")
        eq(f.env.LumenShiftDB.experiments.journal.entries.Contrast.originalRaw, "60")
    end)
    test("D13 detected dependent or external changes stop automation and persist the observations", function()
        local f = setup()
        f.setter = function(key, target) f.values[key] = target; f.values.farclip = "110"; return true end
        assert(f.lab.Preview("Contrast", 65)); eq(f.lab.Confirm(f.lab.Status().token), nil)
        eq(#f.calls, 1); eq(f.values.Contrast, "65"); eq(f.values.farclip, "110")
        eq(f.env.LumenShiftDB.experiments.sideEffects.farclip.before, "100")
        eq(f.env.LumenShiftDB.experiments.sideEffects.farclip.after, "110")
        assert(f.ns.Report.Export(f.runtime):find("UNRESOLVED watched change farclip", 1, true)); eq(f.lab.certificates.Contrast, nil)
    end)
    test("D14 missing, restricted, secret and unsupported native capabilities refuse calibration", function()
        for _, change in ipairs({ function(f) f.env.C_CVar.SetCVar = nil end,
            function(f) f.env.C_CVar.GetCVar = function() return "SECRET" end end,
            function(f) f.env.C_CVar.GetCVarInfo = function(key) return f.values[key], "50", false, false, false, false, true end end,
            function(f) f.env.GetBuildInfo = function() return "1.60.2", "99999", "Nov 4 2026", 16002 end end,
            function(f) f.env.C_Timer = nil end,
            function(f) f.env.InCombatLockdown = function() return true end end }) do
            local f = setup(); change(f); eq(f.lab.Preview("Contrast", 65), nil); eq(#f.calls, 0); f.zero()
        end
    end)
    test("D15 calibrated quality and visual ownership stay independent in both restoration directions", function()
        local f = setup(); f.calibrate("ResampleSharpness", 1.1)
        assert(f.lab.SaveProfile("vista", "ResampleSharpness", 1.1)); f.enable(); f.select("nightVision")
        assert(f.lab.SelectProfile("vista")); f.mock.Flush(); eq(f.values.Brightness, "75"); eq(f.values.ResampleSharpness, "1.1")
        f.select("natural"); eq(f.values.Brightness, "52"); eq(f.values.ResampleSharpness, "1.1")
        assert(f.lab.SelectProfile("currentBaseline")); f.mock.Flush(); eq(f.values.ResampleSharpness, "1")
        eq(f.env.LumenShiftDB.config.selected.quality, "currentBaseline"); eq(f.values.Contrast, "60")
    end)
    test("D16 mode Contrast needs exact calibration before any Brightness write and Natural restores both", function()
        local f = setup(nil, { Contrast = "060.00" }); f.enable()
        assert(f.product.Update(function(c) c.studio.modes.nightVision.useContrast = true; c.studio.modes.nightVision.contrast = 65 end))
        eq(f.product.Select("nightVision"), nil); eq(#f.calls, 0)
        f.calibrate("Contrast", 65); f.select("nightVision")
        eq(f.product.active, "nightVision"); eq(f.values.Contrast, "65"); eq(f.values.Brightness, "75")
        f.select("natural"); eq(f.values.Brightness, "52"); eq(f.values.Contrast, "060.00")
        eq(next(f.env.LumenShiftDB.experiments.journal.entries), nil)
    end)
    test("D17 incomplete composite mode reports partial state and retains the Brightness original", function()
        local f = setup(); f.calibrate("Contrast", 65); f.enable()
        f.product.Update(function(c) c.studio.modes.nightVision.useContrast = true; c.studio.modes.nightVision.contrast = 65 end)
        f.setter = function(key, target) if key == "Contrast" then return false end; f.values[key] = target; return true end
        assert(f.product.Select("nightVision")); f.mock.Flush()
        eq(f.product.active, "natural"); eq(f.product.busy, false); assert(f.product.lastError:find("MODE_PARTIAL", 1, true))
        eq(f.runtime.engine.Status().original, "52"); eq(f.values.Brightness, "75")
        f.select("natural"); eq(f.values.Brightness, "52")
    end)
    test("D18 multi-key partial failure compensates in reverse and revokes failed certificates", function()
        local f = setup(); f.calibrate("ResampleSharpness", 1.1); f.calibrate("groundEffectDensity", 105)
        assert(f.lab.SaveProfile("balanced", "ResampleSharpness", 1.1)); assert(f.lab.SaveProfile("balanced", "groundEffectDensity", 105))
        local start = #f.calls
        f.setter = function(key, target, index)
            if index == start + 2 then f.values[key] = "106"; return true end
            f.values[key] = target; return true
        end
        assert(f.lab.SelectProfile("balanced")); f.mock.Flush()
        eq(f.calls[start + 3][1], "groundEffectDensity"); eq(f.calls[start + 4][1], "ResampleSharpness")
        eq(f.values.ResampleSharpness, "1"); eq(f.values.groundEffectDensity, "100")
        eq(f.lab.state, "BASELINE"); eq(f.lab.certificates.ResampleSharpness, nil)
        eq(f.lab.activeProfile, "currentBaseline")
    end)
    test("D19 reload preserves experimental recovery but never trusts saved permissions or reapplies", function()
        local f = setup(); f.calibrate("Contrast", 65)
        assert(f.lab.Apply("visual", { Contrast = 65 })); f.mock.Flush()
        local reloaded = setup(f.env.LumenShiftDB, { Contrast = "65" })
        eq(#reloaded.calls, 0); eq(reloaded.lab.state, "RECOVERY"); eq(next(reloaded.lab.certificates), nil)
        eq(reloaded.lab.Apply("visual", { Contrast = 65 }), nil)
        assert(reloaded.lab.PreviewRestore("visual")); assert(reloaded.lab.Confirm(reloaded.lab.Status().token)); reloaded.mock.Flush()
        eq(reloaded.values.Contrast, "60"); eq(#reloaded.calls, 1)
    end)
    test("D20 failed scheduling retains the original and performs no unapproved automatic retry", function()
        local f = setup(); assert(f.lab.Preview("Contrast", 65))
        f.env.C_Timer.After = function() error("PRIVATE_TIMER_ERROR") end
        eq(f.lab.Confirm(f.lab.Status().token), nil); eq(#f.calls, 1)
        eq(f.lab.state, "RECOVERY"); eq(f.env.LumenShiftDB.experiments.journal.entries.Contrast.originalRaw, "60")
        eq(f.ns.Report.Export(f.runtime):find("PRIVATE_TIMER_ERROR", 1, true), nil)
    end)
    test("D21 cancellation invalidates pending callbacks and releases a waiting Product controller", function()
        local f = setup(); f.calibrate("Contrast", 65); f.enable()
        f.product.Update(function(c) c.studio.modes.nightVision.useContrast = true; c.studio.modes.nightVision.contrast = 65 end)
        assert(f.product.Select("nightVision"))
        table.remove(f.mock.timers, 1)[2]() -- Brightness verified; Contrast now awaits verification
        eq(f.lab.busy, true); eq(f.product.busy, true)
        local count = #f.calls; assert(f.lab.Cancel()); f.mock.Flush()
        eq(f.product.busy, false); eq(#f.calls, count); eq(f.lab.state, "RECOVERY")
    end)
    test("D22 synchronous native callbacks cannot reenter calibration or the Brightness writer", function()
        local f = setup()
        f.setter = function(key, target)
            eq(f.lab.Confirm("1"), nil); eq(f.runtime.engine.Prepare("on"), nil)
            f.frame.OnEvent(f.frame, "CVAR_UPDATE", key, target)
            f.values[key] = target; return true
        end
        f.calibrate("Contrast", 65); eq(#f.calls, 2); eq(f.values.Brightness, "52")
    end)
    test("D23 schema-2 migration preserves existing state and malformed experimental data is quarantined", function()
        local f = setup(); local old = f.ns.Value.Copy(f.env.LumenShiftDB); old.schemaVersion = 2; old.experiments = nil; old.onboarding = nil
        local migrated, code = f.ns.Store.Open(old); eq(code, "MIGRATED_2_TO_4"); eq(migrated.schemaVersion, 4)
        eq(old.schemaVersion, 2); eq(old.experiments, nil); eq(next(migrated.experiments.journal.entries), nil)
        migrated.experiments.profiles.vista.Unknown = 100
        local reloaded = setup(migrated); eq(reloaded.runtime.db, nil); eq(reloaded.env.LumenShiftDB, migrated); eq(#reloaded.calls, 0)
    end)
    test("D24 a profile containing an uncalibrated required key refuses the entire operation", function()
        local f = setup(); f.calibrate("ResampleSharpness", 1.1)
        assert(f.lab.SaveProfile("performance", "ResampleSharpness", 1.1))
        f.env.LumenShiftDB.experiments.profiles.performance.groundEffectDensity = 99
        local count = #f.calls; eq(f.lab.SelectProfile("performance"), nil); eq(#f.calls, count)
        eq(f.lab.SelectProfile("vista"), nil); eq(#f.calls, count)
    end)
    test("D25 Calibration Lab buttons and slash Diagnostic Center form a complete exportable flow", function()
        local f = setup(); f.env.SlashCmdList.LUMENSHIFT("calibrate"); eq(f.ui.page, 8)
        f.ui.labTarget = "65"; f.ui.BuildPage()
        f.mock.Click("Preview exact modification (read only)"); eq(#f.calls, 0)
        local token = f.lab.Status().token; assert(token)
        f.mock.Click("Confirm displayed operation " .. token); f.mock.Flush(); eq(f.values.Contrast, "60")
        assert(f.lab.certificates.Contrast["65"])
        f.env.SlashCmdList.LUMENSHIFT("diag"); eq(f.ui.page, 7)
        f.mock.Click("Export Complete Diagnostic Report"); assert(f.runtime.exportUI.window:IsShown())
        assert(f.runtime.exportUI.text:find("ROUNDTRIP_PASS_VISUAL_EFFECT_NOT_TESTED", 1, true))
    end)
    test("D26 experimental descriptor admission rejects expanded or forged domains", function()
        local f = setup(); local policy = f.ns.ExperimentPolicy; local context = policy.Context("1.60.1:70790:16001")
        for _, key in ipairs(policy.Keys) do
            local bounds = assert(policy.Bounds(key, f.values[key]))
            local descriptor = policy.Descriptor(key, bounds)
            assert(f.ns.Catalog.Admitted(descriptor, context))
            descriptor.max = 10001; eq(f.ns.Catalog.Admitted(descriptor, context), false)
            descriptor = policy.Descriptor(key, bounds); descriptor.min = 0; descriptor.max = 9999
            eq(f.ns.Catalog.Admitted(descriptor, context), false)
        end
        eq(#f.calls, 0)
    end)
    test("D27 read callbacks cannot enter either writer during preflight or delayed verification", function()
        local f = setup(); local get = f.env.C_CVar.GetCVar; local attempts = 0
        f.env.C_CVar.GetCVar = function(key)
            if key == "Contrast" then
                attempts = attempts + 1
                eq(f.runtime.engine.Prepare("on"), nil)
                eq(f.lab.Preview("Contrast", 66), nil)
            end
            return get(key)
        end
        f.calibrate("Contrast", 65); assert(attempts > 3); eq(#f.calls, 2)
        eq(f.values.Brightness, "52"); eq(f.values.Contrast, "60")
    end)
    test("D28 already-original experimental recovery releases ownership without a setter", function()
        local f = setup(nil, { Contrast = "060.00" }); f.calibrate("Contrast", 65)
        assert(f.lab.Apply("visual", { Contrast = 65 })); f.mock.Flush()
        local restored = setup(f.env.LumenShiftDB, { Contrast = "060.00" })
        assert(restored.lab.PreviewRestore("visual")); assert(restored.lab.Confirm(restored.lab.Status().token))
        restored.mock.Flush(); eq(#restored.calls, 0); eq(restored.lab.state, "BASELINE")
        eq(next(restored.env.LumenShiftDB.experiments.journal.entries), nil)
    end)
    test("D29 changed recovery data invalidates delayed work without clearing the original", function()
        local f = setup(); assert(f.lab.Preview("Contrast", 65)); assert(f.lab.Confirm(f.lab.Status().token))
        f.env.LumenShiftDB.experiments.journal.nextEpoch = 99; f.mock.Flush()
        eq(#f.calls, 1); eq(f.lab.state, "RECOVERY"); eq(f.lab.lastError, "RECOVERY_DATA_CHANGED")
        eq(f.env.LumenShiftDB.experiments.journal.entries.Contrast.originalRaw, "60")
    end)
    test("D30 export construction failure is guarded and a later open can recover", function()
        local f = setup(); local create = f.env.CreateFrame
        f.env.CreateFrame = function() error("PRIVATE_UI_PATH") end
        f.env.SlashCmdList.LUMENSHIFT("report"); eq(f.runtime.exportUI, nil)
        f.env.CreateFrame = create; f.env.SlashCmdList.LUMENSHIFT("report")
        assert(f.runtime.exportUI.window:IsShown()); eq(f.runtime.exportUI.text:find("PRIVATE_UI_PATH", 1, true), nil)
        assert(f.runtime.exportUI.text:find("OWNED_HANDLER_ERROR", 1, true)); eq(#f.calls, 0)
    end)
    test("D31 choosing another calibration key cannot silently cancel a running test", function()
        local f = setup(); f.ui.Open(8); f.ui.labTarget = "65"; f.ui.BuildPage()
        f.mock.Click("Preview exact modification (read only)"); f.mock.Click("Confirm displayed operation " .. f.lab.Status().token)
        eq(f.lab.busy, true); f.mock.Click("farclip"); eq(f.ui.labKey, "Contrast"); eq(f.lab.busy, true)
        f.mock.Flush(); eq(f.values.Contrast, "60"); assert(f.lab.certificates.Contrast["65"])
    end)
    test("D32 media failures are reported without graphics writes or raw native error text", function()
        local f = setup(); f.ns.Widgets.Asset({ SetTexture = function() return false end }, "ignored")
        f.product.Update(function(c) c.preferences.sound = true end)
        f.env.PlaySoundFile = function() error("PRIVATE_MEDIA_PATH") end
        f.runtime.audio.Play("on", f.env.LumenShiftDB.config)
        local report = f.ns.Report.Export(f.runtime)
        assert(report:find("TEXTURE_REJECTED", 1, true)); assert(report:find("API_ERROR", 1, true))
        eq(report:find("PRIVATE_MEDIA_PATH", 1, true), nil); eq(#f.calls, 0)
    end)
    test("D33 repeated debug events and owned errors do not flood chat", function()
        local f = setup(); local count = #f.output
        for i = 1, 500 do f.runtime.log.Add("ui", "test", "DEBUG", "PASS") end
        eq(#f.output, count)
        local failed = f.runtime.log.Guard("ui", "test", function() error("PRIVATE") end)
        for i = 1, 50 do failed() end
        eq(#f.output, count + 1); eq(#f.calls, 0)
    end)
    test("D34 incomplete multi-key compensation retains only unresolved originals", function()
        local f = setup(); f.calibrate("ResampleSharpness", 1.1); f.calibrate("groundEffectDensity", 105)
        f.lab.SaveProfile("balanced", "ResampleSharpness", 1.1); f.lab.SaveProfile("balanced", "groundEffectDensity", 105)
        local count = #f.calls
        f.setter = function(key, target, index)
            if index == count + 2 then f.values[key] = "106"; return true end
            if index == count + 3 then return false end
            f.values[key] = target; return true
        end
        eq(f.lab.SelectProfile("balanced"), nil); f.mock.Flush()
        eq(f.lab.lastError, "COMPENSATION_FAILED"); eq(f.lab.state, "RECOVERY")
        eq(f.values.ResampleSharpness, "1"); eq(f.values.groundEffectDensity, "106")
        eq(f.env.LumenShiftDB.experiments.journal.entries.groundEffectDensity.originalRaw, "100")
        eq(f.env.LumenShiftDB.experiments.journal.entries.ResampleSharpness, nil); eq(#f.calls, count + 4)
    end)
end
