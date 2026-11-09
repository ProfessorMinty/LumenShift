local _, ns = ...
local U, W, V = {}, ns.Widgets, ns.Value; ns.PhotoAdvancedUI = U
local function report(ui, ok, reason)
    ui.notice = ok and nil or ns.Product.Message(reason or "OPTION_UNAVAILABLE")
    ui.Refresh()
end
function U.Frame(runtime, env, parent, y, ui, liveSlider)
    local actions, preview = runtime.cameraActions, runtime.photoPreview
    local function text(label, height) W.Text(parent, label, 0, y, 310, 12, W.colors.muted); y = y - height end
    W.Section(parent, "WORLD CAMERA", 0, y, 310); y = y - 40
    local zoom = actions.ReadZoom()
    text(zoom and ("Actual distance: " .. string.format("%.2f", zoom)) or "Zoom is unavailable on this client.", 32)
    for i, item in ipairs({ { "Closer", -1 }, { "Farther", 1 } }) do
        local delta = item[2]
        local b = W.Button(env, parent, item[1], (i - 1) * 160, y, 150, function() report(ui, actions.Step(delta)) end)
        if not zoom then b:Disable() end
    end
    y = y - 40
    W.Button(env, parent, "Return zoom", 0, y, 150, function() report(ui, actions.Restore()) end)
    W.Button(env, parent, "Keep current zoom", 160, y, 150, function() report(ui, actions.ForgetZoom()) end); y = y - 44
    local original = runtime.db.camera.composition.zoom
    text(original and "Pre-photo distance: " .. string.format("%.2f", original.original) .. ". Exit attempts a return; collision can limit it."
        or "Closer / Farther captures your distance first. World collision can limit zoom.", 58)
    for i, direction in ipairs({ "left", "right" }) do
        local d = direction
        local b = W.Button(env, parent, "Hold orbit " .. d, (i - 1) * 160, y, 150, function() end)
        W.Script(b, "OnMouseDown", function(_, button) if button == "LeftButton" then report(ui, actions.Orbit(d)) end end)
        W.Script(b, "OnMouseUp", function() actions.StopOrbit() end)
        W.Script(b, "OnHide", function() actions.StopOrbit() end)
        W.Script(b, "OnLeave", function() actions.StopOrbit() end)
        local start = d == "left" and "MoveViewLeftStart" or "MoveViewRightStart"
        local stop = d == "left" and "MoveViewLeftStop" or "MoveViewRightStop"
        if runtime.db.config.preferences.reducedMotion or type(runtime.reader.env[start]) ~= "function" or type(runtime.reader.env[stop]) ~= "function" then b:Disable() end
    end
    y = y - 44; text("Hold to turn, release to stop. Each hold lasts at most 5 seconds. Your chosen angle stays; no saved views are replaced.", 70)
    W.Section(parent, "SHOULDER & DYNAMIC FRAMING", 0, y, 310); y = y - 40
    for _, item in ipairs({ { "test_cameraOverShoulder", "Shoulder offset" }, { "test_cameraDynamicPitchBaseFovPad", "Dynamic footroom" } }) do
        local key = item[1]; local seen = ns.ReadOnly.Read(runtime.reader, key)
        local capable, why = ns.Framing.Capability(runtime.reader, key)
        local range = capable and ns.Framing.Bounds(key, seen.raw, runtime.reader)
        if range then y = liveSlider(key, item[2], range.min, range.max, range.step, V.Number(seen.raw), y)
        else text(item[2] .. ": " .. (why == "CAMERA_COMFORT_SETTING_ENABLED" and "disabled by your WoW camera comfort setting." or "unavailable."), 54) end
    end
    local seen = ns.ReadOnly.Read(runtime.reader, "test_cameraDynamicPitch")
    local capable = ns.Framing.Capability(runtime.reader, "test_cameraDynamicPitch")
    if capable and ns.Framing.Bounds("test_cameraDynamicPitch", seen.raw, runtime.reader) then
        W.Toggle(env, parent, "Dynamic framing", 0, y, 310, function() return V.Number(seen.raw) == 1 end,
            function(v) preview.Begin(); local ok, why = preview.Queue("test_cameraDynamicPitch", v and 1 or 0); report(ui, ok, why) end); y = y - 46
    end
    text("Footroom affects native dynamic framing when enabled. These controls use bounded adjustments, not a free camera.", 64)
    W.Button(env, parent, "Restore all framing", 0, y, 310, function()
        preview.Finish(function()
            local ok, why = runtime.camera.RestoreFraming(function(done, code) report(ui, done, code) end)
            if not ok then report(ui, ok, why) end
            return ok, why
        end)
    end)
    return y - 48
end
function U.Capture(runtime, env, parent, y, ui)
    local output, reader = runtime.output, runtime.reader
    local function text(label, height) W.Text(parent, label, 0, y, 310, 12, W.colors.muted); y = y - height end
    local function section(label) W.Section(parent, label, 0, y, 310); y = y - 40 end
    section("SCREENSHOT OUTPUT")
    local seen, format = ns.ReadOnly.Read(reader, "screenshotQuality"), ns.ReadOnly.Read(reader, "screenshotFormat")
    if format.code == "OK" and format.raw == "jpeg" and ns.PhotoOutput.Safe(seen, "screenshotQuality") then
        ui.jpeg = ui.jpeg or V.Number(seen.raw)
        W.Slider(env, parent, "JPEG quality", 0, y, 1, 10, 1, function() return ui.jpeg end, function(v) ui.jpeg = v; return true end, nil, 310); y = y - 70
        W.Button(env, parent, "Apply JPEG quality", 0, y, 150, function() report(ui, output.Apply("jpeg", { screenshotQuality = tostring(ui.jpeg) })) end)
        W.Button(env, parent, "Restore JPEG quality", 160, y, 150, function() report(ui, output.Restore("jpeg")) end); y = y - 44
        text("WoW is saving JPEG images. Higher quality reduces compression; it does not add scene detail. Exit restores the previous value.", 74)
    else text("JPEG quality is unavailable or WoW is using a different output format. Capture still works; the format is unchanged.", 74) end
    section("ANTIALIASING")
    local observed = ns.PhotoOutput.Read(reader, "aa"); local safe = true
    for _, key in ipairs(ns.PhotoOutput.Groups.aa) do if not ns.PhotoOutput.Safe(observed[key], key) then safe = false end end
    if safe then
        local image, samples = ns.PhotoOutput.Options(reader)
        ui.aa = ui.aa or { ffxAntiAliasingMode = observed.ffxAntiAliasingMode.raw, MSAAQuality = observed.MSAAQuality.raw, MSAAAlphaTest = observed.MSAAAlphaTest.raw }
        local function choice(key, label, options)
            local current, index = "Current", 0
            for i, opt in ipairs(options) do if ns.PhotoOutput.Equal(key, tostring(opt.value), ui.aa[key]) then current, index = opt.label, i end end
            W.Text(parent, label, 0, y, 310, 12, W.colors.muted); y = y - 24
            W.Button(env, parent, current .. "  >", 0, y, 310, function()
                ui.aa[key] = tostring(options[index % #options + 1].value); ui.Build()
            end); y = y - 44
        end
        choice("ffxAntiAliasingMode", "Image antialiasing", image); choice("MSAAQuality", "Multisample antialiasing", samples)
        W.Toggle(env, parent, "Alpha-tested edges", 0, y, 310, function() return V.Number(ui.aa.MSAAAlphaTest) == 1 end,
            function(v) ui.aa.MSAAAlphaTest = v and "1" or "0" end); y = y - 46
        W.Button(env, parent, "Apply antialiasing", 0, y, 150, function() report(ui, output.Apply("aa", V.Copy(ui.aa))) end)
        W.Button(env, parent, "Restore antialiasing", 160, y, 150, function() report(ui, output.Restore("aa")) end); y = y - 44
        text("Choices come from WoW's supported options. Apply verifies the full AA group; Exit restores it. Higher samples can reduce frame rate.", 76)
    else text("Native AA values are unavailable or restricted here. Other photo controls remain available.", 60) end
    section("RAY-TRACED SHADOWS")
    local count = 0
    for level = 0, 3 do
        local value = level
        if ns.NativeGraphics.RaySupport(reader, value) then
            W.Button(env, parent, ({ "Off", "Fair", "Good", "High" })[value + 1], count % 2 * 160, y - math.floor(count / 2) * 40, 150,
                function() report(ui, runtime.photo.ApplyRay(value, function(ok, why) report(ui, ok, why) end)) end); count = count + 1
        end
    end
    if count > 0 then y = y - math.ceil(count / 2) * 40 - 8
        W.Button(env, parent, "Restore photo quality", 0, y, 310, function() report(ui, runtime.photo.RestorePhoto(function(ok, why) report(ui, ok, why) end)) end); y = y - 44
        text("Only choices supported by your renderer are shown. Uses the photo-quality original; no driver restart is requested.", 68)
    else text("Ray-traced shadows are unavailable on this renderer. No graphics restart or renderer change is attempted.", 68) end
    return y
end
function U.Saved(runtime, env, parent, y, ui)
    local saved = runtime.photoComposition
    W.Section(parent, "SAVED COMPOSITIONS", 0, y, 310); y = y - 40
    W.Text(parent, "Save guides, zoom and available framing separately from looks. Apply changes the camera; it never applies AA or lighting.", 0, y, 310, 12, W.colors.muted); y = y - 74
    local field = W.Edit(env, parent, ui.compositionName or "My composition", 0, y, 310, function(v) ui.compositionName = v end, 32); y = y - 40
    W.Button(env, parent, "Save / replace composition", 0, y, 310, function()
        ui.compositionName = field:GetText(); local ok, why = saved.Save(ui.compositionName); report(ui, ok, why); ui.Build()
    end); y = y - 48
    for _, name in ipairs(V.Keys(runtime.db.camera.composition.saved)) do
        local selected = name
        W.Text(parent, name, 0, y, 310, 12); y = y - 24
        W.Button(env, parent, "Apply composition", 0, y, 224, function() report(ui, saved.Apply(selected)) end)
        W.Button(env, parent, "Delete", 232, y, 78, function() saved.Delete(selected); ui.Build() end); y = y - 44
    end
    return y
end
