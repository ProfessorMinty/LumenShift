-- UI/entry behavior is simulated. Geometry exports are not native screenshots.
return function(make, fixture, eq, test)
    local function single(f, floating)
        eq(f.r.ui.radial.launcher:IsShown(), floating)
        eq(f.r.entry.button:IsShown(), not floating)
    end
    test("NAV01 fresh setup defaults to one minimap entry; choosing floating replaces it immediately", function()
        local f = make(); single(f, false)
        assert(f.r.setup.Open()); f.mock.Click("Floating launcher"); assert(f.r.setup.SaveAndClose())
        single(f, true); eq(#f.calls, 0)
        f.r.ui.Open(6); f.mock.Click("Floating launcher instead of minimap"); single(f, false)
        eq(#f.calls, 0)
    end)
    test("NAV02 old floating choice and position survive upgrade with exactly one entry button", function()
        local f = make(); local saved = f.ns.Value.Copy(f.r.db)
        saved.config.studio.launcher.visible = true
        saved.config.studio.launcher.x, saved.config.studio.launcher.y = 121, -99
        local g = make(saved); single(g, true)
        eq(g.r.db.config.studio.launcher.x, 121); eq(g.r.db.config.studio.launcher.y, -99)
        g.r.ui.Refresh(); single(g, true)
        local h = make(g.r.db); single(h, true); eq(#h.calls, 0)
    end)
    test("NAV03 failed Studio initialization retains one fallback even with floating saved", function()
        local seed = make(); local saved = seed.ns.Value.Copy(seed.r.db); saved.config.studio.launcher.visible = true
        local f = fixture(saved); f.mock = assert(loadfile("tests/ui_mock.lua"))()(f.env)
        f.ns.Studio.New = function() error("simulated initialization failure") end
        f.load(); local r = f.ns.runtime
        eq(r.ui, nil); eq(r.entry.button:IsShown(), true)
        r.entry.Open("RightButton"); eq(r.exportUI.window:IsShown(), true); f.zero()
    end)
    test("NAV04 wheel Camera icon enters and visible exit returns through the existing controller", function()
        local f = make(); local wheel = f.r.ui.radial
        wheel.Toggle(); assert(wheel.camera.icon.texture:find("ui-camera", 1, true))
        f.mock.Click("Camera"); f.flush()
        eq(wheel.frame:IsShown(), false); eq(f.r.camera.active, true); eq(f.env.UIParent:IsShown(), false)
        f.mock.Click("Exit Camera Mode"); f.flush()
        eq(f.r.camera.active, false); eq(f.env.UIParent:IsShown(), true)
        eq(#f.calls, 0); eq(f.r.product.active, "natural")
    end)
    test("NAV05 wheel Camera and Studio keyboard actions preserve text focus and combat behavior", function()
        local f = make(); local w = f.r.ui.radial
        w.Toggle(); local chat = f.env.CreateFrame("EditBox", nil, f.env.UIParent); chat:SetFocus()
        w.frame.scripts.OnKeyDown(w.frame, "7"); eq(f.r.camera.active, false); eq(w.frame:IsShown(), true)
        chat:ClearFocus(); f.env.InCombatLockdown = function() return true end
        w.frame.scripts.OnKeyDown(w.frame, "7"); eq(f.r.camera.active, false)
        f.env.InCombatLockdown = function() return false end
        w.frame.scripts.OnKeyDown(w.frame, "7"); f.flush(); eq(f.r.camera.active, true)
        assert(f.r.camera.Exit()); f.flush(); w.Toggle()
        w.frame.scripts.OnKeyDown(w.frame, "8"); eq(f.r.ui.window:IsShown(), true); eq(w.frame:IsShown(), false)
        eq(#f.calls, 0)
    end)
    test("NAV06 wheel pointer targets are separate and shortcuts never lengthen mode labels", function()
        local f = make(); local w = f.r.ui.radial
        local controls = {}; for _, b in ipairs(w.buttons) do controls[#controls + 1] = b end
        controls[#controls + 1], controls[#controls + 2] = w.camera, w.studio
        local function box(b)
            local p = b.points[1]; return p[4], -p[5], p[4] + b.width, -p[5] + b.height
        end
        for i, a in ipairs(controls) do
            local x, y, right, bottom = box(a)
            assert(x >= 0 and y >= 0 and right <= 420 and bottom <= 420)
            for j = i + 1, #controls do
                local bx, by, br, bb = box(controls[j])
                assert(right <= bx or br <= x or bottom <= by or bb <= y, "overlapping wheel controls")
            end
        end
        f.r.db.baseline.source = "gameDefaults"; w.Refresh()
        eq(w.buttons[1].label.text, "Game Defaults"); eq(w.buttons[2].label.text, "Night Vision")
        eq(w.footer.points[1][5], -434); assert(-w.footer.points[1][5] > w.surface.height)
        eq(#f.calls, 0)
    end)
    test("NAV07 wheel and hint strip fit small displays at multiple UI scales and cursor corners", function()
        for _, scale in ipairs({ 0.65, 1, 1.4 }) do
            for _, corner in ipairs({ -100, 10000 }) do
                local f = make(); local w = f.r.ui.radial
                f.env.UIParent:SetSize(640, 480); f.env.UIParent:SetScale(scale)
                f.env.GetCursorPosition = function() return corner, corner end
                w.Toggle(); assert(w.frame:IsShown())
                local p, effective = w.frame.points[1], w.frame:GetEffectiveScale()
                assert((p[4] - w.frame.width / 2) * effective >= -0.01)
                assert((p[5] - w.frame.height / 2) * effective >= -0.01)
                assert((p[4] + w.frame.width / 2) * effective <= 640 * scale + 0.01)
                assert((p[5] + w.frame.height / 2) * effective <= 480 * scale + 0.01)
                eq(#f.calls, 0)
            end
        end
    end)
    test("NAV08 keyboard traversal reaches Camera and Studio and keeps active mode indication separate", function()
        local f = make(); local w = f.r.ui.radial; w.Toggle()
        for _ = 1, 6 do w.frame.scripts.OnKeyDown(w.frame, "RIGHT") end
        eq(w.selection, 7); eq(w.sector:IsShown(), false); eq(w.camera.selected, true)
        w.frame.scripts.OnKeyDown(w.frame, "RIGHT"); eq(w.selection, 8); eq(w.studio.selected, true)
        w.frame.scripts.OnKeyDown(w.frame, "RIGHT"); eq(w.selection, 1); eq(w.sector:IsShown(), true)
        w.buttons[2].scripts.OnEnter(w.buttons[2]); eq(w.selection, 2); eq(f.env.GameTooltip:IsShown(), true)
        w.Close(); eq(f.env.GameTooltip:IsShown(), false); eq(#f.calls, 0)
    end)
    test("NAV09 opening Studio setup or the wheel closes the other primary surfaces", function()
        local f = make(); assert(f.r.setup.Open()); assert(f.r.setup.SaveAndClose()); assert(f.r.setup.Open())
        f.r.ui.Wheel(); eq(f.r.setup.window:IsShown(), false); eq(f.r.ui.window:IsShown(), false)
        eq(f.r.ui.radial.frame:IsShown(), true)
        f.r.entry.Studio(9); eq(f.r.ui.radial.frame:IsShown(), false); eq(f.r.ui.window:IsShown(), true)
        assert(f.r.setup.Open()); eq(f.r.ui.window:IsShown(), false); eq(f.r.ui.radial.frame:IsShown(), false)
        f.r.ui.Open(6); eq(f.r.setup.window:IsShown(), false); eq(f.r.ui.window:IsShown(), true)
        eq(#f.calls, 0)
    end)
    if os.getenv("LUMENSHIFT_NAV_MODEL") then
        local f = make(); local w = f.r.ui.radial
        f.env.GetCursorPosition = function() return 640, 400 end
        w.Toggle(); f.r.entry.button:Hide()
        f.mock.Export(os.getenv("LUMENSHIFT_NAV_MODEL") .. ".tsv")
        f.r.db.baseline.source = "gameDefaults"; w.Refresh(); f.r.entry.button:Hide()
        f.mock.Export(os.getenv("LUMENSHIFT_NAV_MODEL") .. "-defaults.tsv")
    end
end
