-- Simulated native recipes and side effects. This is not an in-game acceptance run.
return function(fixture, eq, test)
    local widgets = assert(loadfile("tests/ui_mock.lua"))()
    local function make(saved, values)
        local f = fixture(saved); f.mock = widgets(f.env); f.calls, f.defaults = {}, {}
        local G = f.ns.NativeGraphics
        f.env.GetBuildInfo = function() return "1.60.1", "70862", "Nov 2026", 16001 end
        for _, key in ipairs(G.Keys()) do
            local def = G.Definition(key)
            f.values[key] = def.leaf and "123.25" or "1"
            f.defaults[key] = def.leaf and "100" or "1"
        end
        f.values.farclip, f.values.RAIDfarclip, f.values.RAIDsettingsEnabled = "05432.00", "03210.00", "0"
        f.values.Gamma, f.values.RenderScale = "1", "1"
        for key, value in pairs(values or {}) do f.values[key] = value end
        f.env.C_CVar.GetCVarDefault = function(key) return f.defaults[key] or "50" end
        f.env.C_CVar.GetCVarInfo = function(key)
            return f.values[key], f.defaults[key] or "50", false, false, false, false, f.restricted == key
        end
        f.env.GetGraphicsCVarValueForQualityLevel = function(key, raw, raid)
            local def = assert(G.Definition(key)); eq(raid, def.bank == "raid")
            if f.mapping then return f.mapping(key, raw, raid) end
            return math.min(raw, def.suffix == "ParticleDensity" and 4 or def.max)
        end
        f.env.IsGraphicsSettingValueSupported = function() return 0 end
        f.env.C_VideoOptions = {}
        for _, name in ipairs({ "IsPBRWaterSupported", "IsSecondaryLightingSupported", "IsOutlineModeSupported", "IsSpellVisualDensitySystemSupported" }) do
            f.env.C_VideoOptions[name] = function() return true end
        end
        function f.native(key, target)
            f.values[key] = target
            if key == "graphicsViewDistance" then f.values.farclip = tostring(1000 + tonumber(target) * 200) end
            if key == "raidGraphicsViewDistance" then f.values.RAIDfarclip = tostring(800 + tonumber(target) * 100) end
            return true
        end
        f.env.C_CVar.SetCVar = function(key, target)
            local def = G.Definition(key)
            local record = def and (f.env.LumenShiftDB.camera.photo.records[def.bank] or f.env.LumenShiftDB.graphics.records[def.bank])
            local visual = f.env.LumenShiftDB.journal.entries[key] or f.env.LumenShiftDB.experiments.journal.entries[key]
                or f.env.LumenShiftDB.camera.journal.entries[key] or f.env.LumenShiftDB.camera.framing.journal.entries[key]
            assert(record and record.original[key] ~= nil or visual and visual.originalRaw, "capture must precede every write")
            f.calls[#f.calls + 1] = { key, target }
            if f.setter then return f.setter(key, target, #f.calls) end
            return f.native(key, target)
        end
        f.reloads = 0; f.env.ReloadUI = function() f.reloads = f.reloads + 1 end
        f.load(); f.r = f.ns.runtime; f.g = f.r.graphics
        function f.choice(bank, level)
            local choice = G.Defaults().choices
            choice[bank] = { source = level == "recommended" and "recommended" or "level", level = type(level) == "number" and level or 5 }
            return choice
        end
        function f.apply(bank, level)
            local ok, code = f.g.Apply(f.choice(bank, level)); assert(ok, code); f.mock.Flush()
            assert(not f.g.Status().error, f.g.Status().error)
        end
        return f
    end
    test("N01 startup, preview, recommendation reads and keep-current reload never write", function()
        local f = make(); f.frame.OnEvent(f.frame, "PLAYER_ENTERING_WORLD"); f.mock.Flush()
        f.mock.Click("Next: Graphics"); f.mock.Click("Review changes"); eq(#f.calls, 0)
        f.r.graphicsPreview.window:Hide(); f.mock.Click("Finish & Reload UI"); eq(f.reloads, 1)
        assert(f.ns.NativeGraphics.Recipe(f.r.reader, "normal", f.choice("normal", "recommended").normal))
        local report = f.ns.Report.Export(f.r); assert(report:find("native graphics normal", 1, true))
        eq(#f.calls, 0); f.zero()
    end)
    test("N02 1-10 maps to native 0-9, defaults stay per-key, invalid mappings refuse", function()
        local f = make(); local G = f.ns.NativeGraphics
        for _, bank in ipairs(G.Banks) do
            for _, level in ipairs({ 1, 10 }) do
                local recipe = assert(G.Recipe(f.r.reader, bank, f.choice(bank, level)[bank]))
                eq(recipe[G.Overall(bank)], level - 1)
            end
        end
        f.defaults.graphicsShadowQuality = "4"; f.defaults.graphicsViewDistance = "7"
        local recipe = assert(G.Recipe(f.r.reader, "normal", f.choice("normal", "recommended").normal))
        eq(recipe.graphicsShadowQuality, 4); eq(recipe.graphicsViewDistance, 7); eq(recipe.graphicsQuality, 1)
        for _, bad in ipairs({ "2", true, -5, 999 }) do
            f.mapping = function() return bad end
            eq(G.Recipe(f.r.reader, "normal", f.choice("normal", 5).normal), nil)
        end
        eq(#f.calls, 0)
    end)
    test("N03 hardware support is numeric zero; missing or restricted APIs refuse only Apply", function()
        for _, value in ipairs({ true, false, 1 }) do
            local f = make(); f.env.IsGraphicsSettingValueSupported = function() return value end
            eq(f.g.Apply(f.choice("normal", 5)), nil); eq(#f.calls, 0)
        end
        for _, name in ipairs({ "GetGraphicsCVarValueForQualityLevel", "IsGraphicsSettingValueSupported" }) do
            local f = make(); f.env[name] = nil
            eq(f.g.Apply(f.choice("normal", 5)), nil); assert(f.g.Apply(f.ns.NativeGraphics.Defaults().choices)); eq(#f.calls, 0)
        end
        local f = make(); f.restricted = "graphicsShadowQuality"
        eq(f.g.Apply(f.choice("normal", 5)), nil); eq(#f.calls, 0)
        f.restricted = nil; f.env.C_CVar.SetCVar = nil
        eq(f.g.Apply(f.choice("normal", 5)), nil); eq(#f.calls, 0)
    end)
    test("N04 optional unavailable hardware is omitted; combat cues retained at lowest level", function()
        local f = make(); local G = f.ns.NativeGraphics
        f.env.C_VideoOptions.IsPBRWaterSupported = function() return false end
        f.env.C_VideoOptions.IsSecondaryLightingSupported = function() return false end
        local recipe, omitted = G.Recipe(f.r.reader, "raid", f.choice("raid", 1).raid)
        assert(recipe); eq(recipe.raidGraphicsPBRLiquidDetail, nil); eq(#omitted, 2)
        eq(recipe.raidGraphicsParticleDensity, 1); eq(recipe.raidGraphicsProjectedTextures, 1)
        f.env.C_VideoOptions.IsOutlineModeSupported = nil
        eq(f.g.Apply(f.choice("normal", 5)), nil); eq(#f.calls, 0)
    end)
    test("N05 normal and raid banks stay independent of each other and visual settings", function()
        local f = make(); local oldRaid = f.ns.NativeGraphics.Snapshot(f.r.reader, "raid")
        f.apply("normal", 7); assert(f.ns.NativeGraphics.Matches(f.r.reader, oldRaid))
        eq(f.values.Brightness, "52"); eq(f.values.Contrast, "60"); eq(f.values.Gamma, "1"); eq(f.values.RenderScale, "1")
        local oldNormal = f.ns.NativeGraphics.Snapshot(f.r.reader, "normal")
        f.apply("raid", 3); assert(f.ns.NativeGraphics.Matches(f.r.reader, oldNormal))
        eq(f.values.RAIDsettingsEnabled, "0")
        for _, bank in ipairs({ "normal", "raid" }) do eq(f.r.db.graphics.records[bank].state, "owned") end
        assert(f.ns.Store.Open(f.r.db))
    end)
    test("N06 exact custom leaves restored after parent selectors, never recaptured on second Apply", function()
        local f = make(); local original = f.ns.NativeGraphics.Snapshot(f.r.reader, "normal")
        f.apply("normal", 7); eq(f.values.farclip, "2200")
        f.apply("normal", 9); eq(f.r.db.graphics.records.normal.original.farclip, "05432.00")
        local start = #f.calls; assert(f.g.Restore("normal")); f.mock.Flush()
        assert(f.ns.NativeGraphics.Matches(f.r.reader, original)); eq(f.r.db.graphics.records.normal, nil)
        local parentIndex, leafIndex
        for i = start + 1, #f.calls do
            if f.calls[i][1] == "graphicsViewDistance" then parentIndex = i end
            if f.calls[i][1] == "farclip" then leafIndex = i end
        end
        assert(parentIndex < leafIndex); eq(f.values.farclip, "05432.00")
    end)
    test("N07 both recipes preflight before first write and raid enable is explicit", function()
        local f = make(); local choices = f.choice("normal", 5); choices.raid = { source = "level", level = 3 }; choices.raidEnabled = "on"
        f.values.raidGraphicsQuality = nil
        eq(f.g.Apply(choices), nil); eq(#f.calls, 0); eq(f.values.RAIDsettingsEnabled, "0")
        f.values.raidGraphicsQuality = "1"
        local callbacks = 0; assert(f.g.Apply(choices, function(ok) assert(ok); callbacks = callbacks + 1 end))
        eq(callbacks, 0); f.mock.Flush(); eq(callbacks, 1); eq(f.values.RAIDsettingsEnabled, "1")
        assert(f.g.Restore("raid")); f.mock.Flush(); eq(f.values.RAIDsettingsEnabled, "0")
    end)
    test("N08 false setter and clamping compensate once to exact pre-Apply bank", function()
        for _, mode in ipairs({ "false", "clamp" }) do
            local f = make(); local original = f.ns.NativeGraphics.Snapshot(f.r.reader, "normal")
            f.setter = function(key, value, count)
                if count == 2 then
                    if mode == "clamp" then f.values[key] = "0"; return true end
                    f.native(key, value); return false
                end
                return f.native(key, value)
            end
            assert(f.g.Apply(f.choice("normal", 6))); f.mock.Flush()
            assert(f.g.Status().error); assert(f.ns.NativeGraphics.Matches(f.r.reader, original))
            eq(f.r.db.graphics.records.normal, nil); assert(#f.calls < 20)
        end
    end)
    test("N09 compensation failure retains original and never schedules a retry", function()
        local f = make(); f.setter = function(key, value, count) f.native(key, value); return count == 1 end
        eq(f.g.Apply(f.choice("normal", 5)), false)
        local calls = #f.calls; f.mock.Flush(); eq(#f.calls, calls)
        local record = assert(f.r.db.graphics.records.normal); eq(record.original.farclip, "05432.00"); eq(record.state, "failed")
        eq(f.g.Apply(f.choice("normal", 5)), nil); eq(#f.calls, calls)
    end)
    test("N10 external change stops reapply; only explicit Restore replaces that bank", function()
        local f = make(); f.apply("normal", 6); f.values.farclip = "7777"
        f.g.Observe(); eq(f.r.db.graphics.records.normal.state, "conflict")
        local count = #f.calls; eq(f.g.Apply(f.choice("normal", 5)), nil); eq(#f.calls, count); eq(f.values.farclip, "7777")
        assert(f.g.Restore("normal")); f.mock.Flush(); eq(f.values.farclip, "05432.00")
    end)
    test("N11 drift before delayed verification is preserved with no compensation writes", function()
        local f = make(); assert(f.g.Apply(f.choice("normal", 6)))
        local count = #f.calls; f.values.farclip = "7777"; f.mock.Flush()
        eq(#f.calls, count); eq(f.values.farclip, "7777"); eq(f.r.db.graphics.records.normal.state, "conflict")
    end)
    test("N12 reload keeps records read-only, matching next explicit action can continue", function()
        local f = make(); f.apply("normal", 6)
        local nextLogin = make(f.r.db, f.values); nextLogin.frame.OnEvent(nextLogin.frame, "PLAYER_ENTERING_WORLD"); nextLogin.mock.Flush()
        eq(#nextLogin.calls, 0); eq(nextLogin.g.Status().state, "RECOVERY")
        nextLogin.apply("normal", 4); eq(nextLogin.r.db.graphics.records.normal.original.farclip, "05432.00")
        assert(nextLogin.g.Restore("normal")); nextLogin.mock.Flush(); eq(nextLogin.values.farclip, "05432.00")
    end)
    test("N13 pending reload and failed restoration preserve recoverable originals", function()
        local f = make(); assert(f.g.Apply(f.choice("normal", 6)))
        local nextLogin = make(f.r.db, f.values); eq(#nextLogin.calls, 0)
        eq(nextLogin.g.Apply(nextLogin.choice("normal", 5)), nil)
        nextLogin.setter = function() return false end
        eq(nextLogin.g.Restore("normal"), false); local count = #nextLogin.calls; nextLogin.mock.Flush()
        eq(#nextLogin.calls, count); eq(nextLogin.r.db.graphics.records.normal.original.farclip, "05432.00")
    end)
    test("N14 native callback reentry cannot start graphics, brightness or lab operations", function()
        local f = make(); local attempted = false
        f.setter = function(key, value)
            attempted = true; local count = #f.calls
            eq(f.g.Apply(f.choice("raid", 5)), nil)
            eq(f.r.engine.Prepare("on"), nil)
            eq(f.r.lab.SelectProfile("vista"), nil)
            eq(f.r.tierTrial.Test("graphicsShadowQuality", 2), nil)
            eq(#f.calls, count); return f.native(key, value)
        end
        f.apply("normal", 6); assert(attempted)
    end)
    test("N15 combat, failed scheduling and late combat retain state without retry", function()
        local f = make(); f.env.InCombatLockdown = function() return true end
        eq(f.g.Apply(f.choice("normal", 5)), nil); eq(#f.calls, 0)
        f.env.InCombatLockdown = function() return false end
        f.env.C_Timer.After = function() error("timer failure") end
        eq(f.g.Apply(f.choice("normal", 5)), false); eq(f.r.db.graphics.records.normal.state, "failed")
        local g = make(); assert(g.g.Apply(g.choice("normal", 5)))
        g.env.InCombatLockdown = function() return true end; local count = #g.calls; g.mock.Flush()
        eq(#g.calls, count); eq(g.r.db.graphics.records.normal.state, "failed")
    end)
    test("N16 unexpected foreign bank/visual changes are recorded, not overwritten", function()
        local f = make(); f.setter = function(key, value, count)
            f.native(key, value); if count == 1 then f.values.Brightness = "59" end; return true
        end
        eq(f.g.Apply(f.choice("normal", 5)), false); eq(f.values.Brightness, "59")
        eq(#f.calls, 1)
        eq(f.r.db.graphics.sideEffects.Brightness.before, "52"); eq(f.r.db.graphics.sideEffects.Brightness.after, "59")
        assert(f.ns.Store.Open(f.r.db)); assert(f.ns.Report.Export(f.r):find("native-graphics watched change Brightness", 1, true))
    end)
    test("N17 saved graphics data is strict, schema-6 migration preserves prior preferences", function()
        local f = make(); local old = f.ns.Value.Copy(f.r.db); old.schemaVersion, old.graphics, old.optics = 6, nil, nil
        old.onboarding.completed = true; old.config.preferences.sound = true
        local migrated, why = f.ns.Store.Open(old); eq(why, "MIGRATED_6_TO_12"); eq(migrated.schemaVersion, 12)
        eq(migrated.onboarding.completed, true); eq(migrated.config.preferences.sound, true); eq(old.graphics, nil)
        f.apply("normal", 6); f.apply("raid", 4); assert(f.ns.Store.Open(f.r.db))
        for _, mutate in ipairs({
            function(d) d.records.normal.original.unknownSetting = "1" end,
            function(d) d.records.normal.expected.farclip = "not numeric" end,
            function(d) d.records.normal.original.Brightness = "52" end,
            function(d) d.choices.normal.level = 11 end,
        }) do local data = f.ns.Value.Copy(f.r.db); mutate(data.graphics); eq(f.ns.Store.Open(data), nil) end
    end)
    test("N18 saving setup keeps selected levels without writing; Apply reload waits for both banks", function()
        local f = make(); assert(f.r.setup.Open()); f.mock.Click("Next: Graphics")
        f.r.setup.draft.graphics = f.choice("normal", 6); f.r.setup.draft.graphics.raid = { source = "level", level = 3 }
        f.r.setup.draft.graphics.raidEnabled = "on"; f.r.setup.Build(); f.mock.Click("Save & Close")
        eq(#f.calls, 0); eq(f.r.db.graphics.choices.normal.level, 6)
        assert(f.r.setup.Open()); eq(f.r.setup.draft.graphics.normal.source, "level")
        f.mock.Click("Next: Graphics"); f.mock.Click("Apply & Reload UI"); eq(f.reloads, 0)
        f.mock.Flush(); eq(f.reloads, 1); eq(f.r.db.graphics.records.normal.state, "owned"); eq(f.r.db.graphics.records.raid.state, "owned")
    end)
    test("N19 failed graphics Apply keeps saved preferences and does not reload", function()
        local f = make(); assert(f.r.setup.Open()); f.mock.Click("Next: Graphics")
        f.r.setup.draft.graphics = f.choice("normal", 5); f.r.setup.Build()
        f.env.GetGraphicsCVarValueForQualityLevel = nil; f.mock.Click("Apply & Reload UI")
        eq(f.reloads, 0); eq(#f.calls, 0); eq(f.r.db.graphics.choices.normal.source, "level"); eq(f.r.db.onboarding.completed, true)
    end)
    test("N20 Studio preview is read-only, restore controls appear after Apply, pools bounded", function()
        local f = make(); f.r.ui.Open(2); f.r.ui.graphicsDraft = f.choice("normal", 7); f.r.ui.BuildPage()
        f.mock.Click("Review changes"); eq(#f.calls, 0); f.r.graphicsPreview.window:Hide()
        f.mock.Click("Apply graphics"); f.mock.Flush(); eq(f.r.db.graphics.records.normal.state, "owned")
        f.mock.Click("Restore everyday graphics"); f.mock.Flush(); eq(f.values.farclip, "05432.00")
        f.r.ui.BuildPage(); local nodes = #f.mock.nodes
        for i = 1, 20 do f.r.ui.BuildPage() end
        eq(#f.mock.nodes, nodes)
    end)
    test("N21 overlapping detail profile and native bank ownership cannot silently replace each other", function()
        local f = make(); f.apply("normal", 6)
        local count = #f.calls; eq(f.r.lab.SelectProfile("vista"), nil); eq(f.r.tierTrial.Test("graphicsShadowQuality", 2), nil); eq(#f.calls, count)
        local record = { originalRaw = "05432.00", lastVerifiedRaw = "05432.00", intendedRaw = "05432.00", layer = "quality", epoch = 1,
            state = "owned", signature = "1.60.1:70862:16001", descriptorVersion = 3 }
        local g = make(); g.r.db.experiments.journal.entries.farclip = record; g.r.db.experiments.journal.nextEpoch = 2
        eq(g.g.Apply(g.choice("normal", 6)), nil); eq(#g.calls, 0)
    end)
    test("N22 missing leaves are disclosed without inventing captures", function()
        local f = make(); f.values.sunShafts = nil
        local values, missing = f.ns.NativeGraphics.Snapshot(f.r.reader, "normal"); eq(values.sunShafts, nil); eq(#missing, 1)
        f.apply("normal", 6); eq(f.r.db.graphics.records.normal.original.sunShafts, nil)
        assert(f.ns.Report.Export(f.r):find("uncaptured sunShafts", 1, true))
    end)
    test("N23 second-bank failure reports partial completion without erasing first-bank originals", function()
        local f = make(); local choices = f.choice("normal", 7); choices.raid = { source = "level", level = 3 }
        f.setter = function(key, value)
            if key:match("^raidGraphics") then return false end
            return f.native(key, value)
        end
        local result, count = nil, 0
        assert(f.g.Apply(choices, function(ok) result = ok; count = count + 1 end)); f.mock.Flush()
        eq(result, false); eq(count, 1); eq(f.r.db.graphics.records.normal.state, "owned")
        eq(f.r.db.graphics.records.normal.original.farclip, "05432.00")
    end)
    test("N24 preview and custom status never silently round a custom component vector", function()
        local f = make(); f.values.graphicsShadowQuality = "4"
        assert(f.ns.NativeGraphics.Current(f.r.reader, "normal"):find("Custom", 1, true))
        local count, rows = f.ns.GraphicsUI.Preview(f.r, f.choice("normal", 8)); assert(count > 0); eq(#rows, count); eq(#f.calls, 0)
    end)
    test("N25 other controllers' preflight blocks nested native graphics Apply", function()
        for _, action in ipairs({ "brightness", "names", "lab" }) do
            local f = make(); local invoked, result = false, true
            local getter = f.env.C_CVar.GetCVar
            f.env.C_CVar.GetCVar = function(key)
                if not invoked then invoked = true; result = f.g.Apply(f.choice("normal", 6)) end
                return getter(key)
            end
            if action == "brightness" then f.r.engine.Prepare("on")
            elseif action == "names" then f.r.names.Apply("camera", { UnitNameFriendlyPlayerName = 0, UnitNameFriendlyPetName = 0 })
            else f.r.lab.SelectProfile("vista") end
            assert(invoked); assert(result == nil, action .. " allowed nested graphics")
            eq(f.r.db.graphics.records.normal, nil)
            for _, call in ipairs(f.calls) do assert(f.ns.ExperimentPolicy.Known(call[1]), "nested native recipe wrote a parent") end
            if action ~= "lab" then eq(#f.calls, 0) end
        end
    end)
    test("N26 native custom status compares unmodified recipe and sliders bypass dropdown support API", function()
        local f = make(); local G = f.ns.NativeGraphics
        local recipe = assert(G.Recipe(f.r.reader, "normal", f.choice("normal", 1).normal, true))
        for key, value in pairs(recipe) do f.values[key] = tostring(value) end
        eq(G.Current(f.r.reader, "normal"), "Level 1")
        f.env.IsGraphicsSettingValueSupported = function(key)
            local def = G.Definition(key)
            assert(not def.overall and def.suffix ~= "ViewDistance" and def.suffix ~= "EnvironmentDetail" and def.suffix ~= "GroundClutter")
            return 0
        end
        f.apply("normal", 6)
    end)
    test("N27 custom minus-one selectors and exact raw originals restore; normal particles honor native minimum", function()
        local f = make(nil, { graphicsQuality = "-1", graphicsShadowQuality = "-1" })
        f.defaults.graphicsParticleDensity = "0"
        local recipe = assert(f.ns.NativeGraphics.Recipe(f.r.reader, "normal", f.choice("normal", "recommended").normal))
        eq(recipe.graphicsParticleDensity, 1)
        f.apply("normal", 6); assert(f.g.Restore("normal")); f.mock.Flush()
        eq(f.values.graphicsQuality, "-1"); eq(f.values.graphicsShadowQuality, "-1"); eq(f.values.farclip, "05432.00")
        local count = #f.calls; assert(f.g.Restore("normal")); eq(#f.calls, count)
    end)
    test("N28 prior build record stays inert until explicit restoration; no launch version lock", function()
        local f = make(); f.apply("normal", 6)
        f.r.db.graphics.records.normal.signature = "1.60.1:70790:16001"
        local g = make(f.r.db, f.values); eq(#g.calls, 0)
        eq(g.g.Apply(g.choice("normal", 5)), nil)
        eq(g.r.db.graphics.records.normal.signature, "1.60.1:70790:16001")
        assert(g.g.Restore("normal")); g.mock.Flush(); eq(g.values.farclip, "05432.00")
        g.env.GetBuildInfo = function() return "1.60.2", "71000", "new build", 16002 end
        g.apply("normal", 5); eq(g.r.db.graphics.records.normal.signature, "1.60.2:71000:16002")
    end)
    test("N29 inaccessible recipe results and late restrictions never guess or erase recovery", function()
        for _, value in ipairs({ "SECRET", math.huge, 0 / 0, 1.5 }) do
            local f = make(); f.mapping = function() return value end
            eq(f.g.Apply(f.choice("normal", 6)), nil); eq(#f.calls, 0)
        end
        local f = make(); assert(f.g.Apply(f.choice("normal", 6)))
        f.restricted = "farclip"; local calls = #f.calls; f.mock.Flush()
        eq(#f.calls, calls); eq(f.r.db.graphics.records.normal.original.farclip, "05432.00")
        eq(f.g.Restore("normal"), nil); eq(#f.calls, calls)
    end)
    test("N30 a raid recipe cannot silently enable its bank when the checkbox was kept", function()
        local f = make(); f.values.RAIDsettingsEnabled = nil
        eq(f.g.Apply(f.choice("raid", 5)), nil); eq(#f.calls, 0)
        f.values.RAIDsettingsEnabled = "0"
        f.setter = function(key, value, count)
            f.native(key, value); if count == 1 then f.values.RAIDsettingsEnabled = "1" end; return true
        end
        assert(f.g.Apply(f.choice("raid", 5))); f.mock.Flush()
        eq(f.g.Status().error, "UNREQUESTED_RAID_SWITCH_CHANGED"); eq(f.values.RAIDsettingsEnabled, "0")
        eq(f.r.db.graphics.records.raid, nil)
    end)
    test("N31 native normal and raid banks coexist with shared optical mode and quality requests", function()
        local f = make(nil, { ResampleSharpness = "1.000", ResampleAlwaysSharpen = "0" })
        assert(f.r.lab.Apply("quality", { ResampleSharpness = 0.4 })); f.mock.Flush()
        local m = f.r.db.config.studio.modes.nightVision; m.sharpening, m.detail = "custom", 90
        assert(f.r.product.Select("nightVision")); f.mock.Flush(); eq(f.values.ResampleSharpness, "0.2")
        f.apply("normal", 6); f.apply("raid", 4); eq(f.values.ResampleSharpness, "0.2")
        eq(f.r.db.graphics.records.normal.original.ResampleSharpness, nil)
        eq(f.r.db.graphics.records.raid.original.ResampleSharpness, nil)
        assert(f.r.lab.Apply("quality", { ResampleSharpness = 0.7 })); f.mock.Flush()
        assert(f.r.product.Select("natural")); f.mock.Flush(); eq(f.values.ResampleSharpness, "0.7")
        assert(f.r.lab.Apply("quality", {})); f.mock.Flush(); eq(f.values.ResampleSharpness, "1.000")
    end)
    test("N32 unexpected native bank optical side effects stop without overwriting the changed optical key", function()
        local f = make(nil, { ResampleSharpness = "1.000", ResampleAlwaysSharpen = "0" })
        local m = f.r.db.config.studio.modes.nightVision; m.sharpening, m.detail = "custom", 90
        assert(f.r.product.Select("nightVision")); f.mock.Flush()
        f.setter = function(key, raw) f.native(key, raw); f.values.ResampleSharpness = "0.8"; return true end
        local count = #f.calls; eq(f.g.Apply(f.choice("normal", 6)), false)
        eq(#f.calls, count + 1); eq(f.values.ResampleSharpness, "0.8")
        eq(f.r.db.experiments.journal.entries.ResampleSharpness.originalRaw, "1.000")
        assert(f.ns.NativeGraphics.Validate(f.r.db.graphics))
    end)
    if os.getenv("LUMENSHIFT_UI_MODEL_PATH") then
        local path = os.getenv("LUMENSHIFT_UI_MODEL_PATH")
        local f = make(); f.r.setup.Open(); f.mock.Export(path .. "-setup-appearance.tsv")
        f.r.setup.page = 2; f.r.setup.draft.graphics = f.choice("normal", 7)
        f.r.setup.draft.graphics.raidEnabled = "on"; f.r.setup.draft.graphics.raid = { source = "level", level = 4 }
        f.r.setup.Build(); f.mock.Export(path .. "-setup-graphics.tsv")
        f.r.setup.window:Hide(); f.r.ui.Open(2); f.r.ui.graphicsDraft = f.r.setup.draft.graphics; f.r.ui.BuildPage()
        f.mock.Export(path .. "-graphics.tsv")
        f.ns.GraphicsUI.ShowPreview(f.r, f.r.ui.graphicsDraft); f.mock.Export(path .. "-graphics-preview.tsv")
    end
    return make
end
