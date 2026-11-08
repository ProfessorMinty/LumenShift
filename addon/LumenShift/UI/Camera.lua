local _, ns = ...
local U, W = {}, ns.Widgets
ns.CameraUI = U
function U.Build(runtime, ui, parent, env)
    local db, camera = runtime.db, runtime.camera
    local function rebuild() ui.RebuildInPlace() end
    W.Text(parent, "COMPOSE YOUR SHOT", 0, 0, 820, 12, W.colors.muted)
    W.Text(parent, "Hide the interface. Keep the scene.", 0, -34, 820, 22)
    W.Text(parent, "Enter hides the HUD. A small capture / exit bar stays available. Capture hides the bar and guides.", 0, -74, 820, 13, W.colors.muted)
    W.Toggle(env, parent, "Hide friendly player and pet names", 0, -126, 400, function() return db.camera.hideWithUI end,
        function(value) db.camera.hideWithUI = value end)
    W.Toggle(env, parent, "Keep visual effects", 430, -126, 400, function() return db.camera.keepEffects end,
        function(value) db.camera.keepEffects = value; runtime.product.RefreshPresentation() end)
    W.Toggle(env, parent, "Rule of thirds guides", 0, -183, 400, function() return db.camera.thirds end,
        function(value) db.camera.thirds = value; if camera.active then runtime.composition.Show() end end)
    W.Text(parent, "Frame guide (does not crop the screenshot)", 0, -241, 820, 13)
    for i, choice in ipairs({ { "none", "No frame" }, { "wide", "16:9" }, { "cinema", "2.39:1" }, { "square", "Square" } }) do
        local id = choice[1]
        local button = W.Button(env, parent, choice[2], (i - 1) * 211, -272, 198, function()
            db.camera.aspect = id; if camera.active then runtime.composition.Show() end; rebuild()
        end)
        button.SetSelected(db.camera.aspect == id)
    end
    W.Text(parent, "MANUAL FRAMING", 0, -334, 820, 12, W.colors.muted)
    local range = ns.Framing.Range(runtime.reader)
    local value = ns.ReadOnly.Read(runtime.reader, "cameraFov")
    if range and ns.Planner.SafeObservation(value) and ns.Value.Number(value.raw) then
        ui.fov = ui.fov or math.floor(ns.Value.Number(value.raw) * 10 + 0.5) / 10
        W.Slider(env, parent, "Field of view", 0, -371, range.min, range.max, 0.1, function() return ui.fov end,
            function(n) ui.fov = n; return true end, "Uses the game's current bounds. Apply is manual; no animation or camera tracking.", 400)
        W.Button(env, parent, "Apply field of view", 430, -383, 198, function() camera.ApplyFOV(ui.fov); ui.Refresh() end)
        W.Button(env, parent, "Restore framing", 642, -383, 194, function() camera.RestoreFOV(); ui.Refresh() end, nil, "quiet")
    else W.Text(parent, "Field of view is unavailable on this client/configuration. Guides and HUD controls still work.", 0, -371, 820, 13, W.colors.muted) end
    W.Text(parent, "Mouse / wheel framing stays native. DynamicCam or Narcissus can keep control; an external FOV edit stops our restoration.", 0, -445, 820, 13, W.colors.muted)
    W.Text(parent, "TEMPORARY PHOTO QUALITY", 0, -514, 820, 12, W.colors.muted)
    W.Toggle(env, parent, "Use a photo quality level on Camera entry", 0, -550, 820, function() return db.camera.photoEnabled end,
        function(value) db.camera.photoEnabled = value end)
    W.Slider(env, parent, "Photo quality level", 0, -606, 1, 10, 1, function() return db.camera.photoLevel end,
        function(n) db.camera.photoLevel = n; return true end, "Optional native recipe. No claim this computer can sustain it.", 836)
    W.Text(parent, "Exit restores captured everyday and enabled raid values. Your saved choices stay unchanged. Other detail profiles must be restored first.", 0, -682, 820, 13, W.colors.muted)
    W.Button(env, parent, "Restore Camera changes", 0, -741, 310, function() camera.Exit(); ui.Refresh() end, nil, "quiet")
    W.Text(parent, "Also available after reload. External edits are preserved; captured originals remain in Diagnostics.", 330, -744, 506, 12, W.colors.muted)
    W.Text(parent, "FLOATING NAMES", 0, -817, 820, 12, W.colors.muted)
    ui.cameraStateText = W.Text(parent, "", 0, -851, 820, 13, W.colors.muted)
    W.Button(env, parent, "Toggle friendly player and pet names", 0, -928, 406, function() camera.ToggleNames(); ui.Refresh() end)
    W.Button(env, parent, "Restore original name settings", 430, -928, 406, function() camera.RestoreNames(); ui.Refresh() end, nil, "quiet")
    ui.Primary("Enter Camera Mode — hide interface", function() camera.Toggle(); rebuild() end,
        "Exit with the visible button, Camera keybinding, or Alt+Z then Exit. Combat shows the HUD; it never restores graphics.")
    return 986
end
