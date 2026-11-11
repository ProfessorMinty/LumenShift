local _, ns = ...
local U, W, V = {}, ns.Widgets, ns.Value; ns.PhotoAdvancedUI = U
local function report(ui, ok, reason)
    ui.notice = nil
    if not ok then ui.notice = ns.Product.Message(reason or "OPTION_UNAVAILABLE") end
    ui.Refresh()
end
function U.Position(runtime, env, parent, y, ui)
    local actions = runtime.cameraActions
    local function text(label, height) W.Text(parent, label, 0, y, 310, 12, W.colors.muted); y = y - height end
    text("Hold a direction to move. Release to stop.", 24)
    W.Art(parent,"look-neutral",0,y,188,92,.45,"BORDER")
    W.Rule(parent,0,y-46,188,W.colors.muted,1)
    local vertical=W.Texture(parent,"ARTWORK")
    vertical:SetPoint("TOPLEFT",parent,"TOPLEFT",93,y);vertical:SetSize(1,92);vertical:SetColorTexture(.65,.78,.77,.6)
    local buttons = {
        { "up", "Tilt up", 53, 0 }, { "left", "Orbit left", 0, -32 },
        { "right", "Orbit right", 104, -32 }, { "down", "Tilt down", 53, -64 },
    }
    local missing = false
    for _, item in ipairs(buttons) do
        local direction = item[1]
        local button = W.Button(env, parent, item[2], item[3], y + item[4], 84, function() end)
        button:SetHeight(27)
        W.Script(button, "OnMouseDown", function(_, which)
            if which == "LeftButton" then report(ui, actions.Orbit(direction, ui.precision)) end
        end)
        local function stop()
            if actions.orbit == direction then
                actions.StopOrbit(direction)
                ui.status:SetText(ns.Product.Message(actions.status))
            end
        end
        W.Script(button, "OnMouseUp", stop)
        W.Script(button, "OnHide", stop)
        W.Script(button, "OnLeave", stop)
        if not actions.HasMovement(direction) then button:Disable(); missing = true
        elseif runtime.db.config.preferences.reducedMotion then button:Disable() end
    end
    local zoom = actions.ReadZoom()
    W.Text(parent,zoom and ("Distance  "..string.format("%.2f",zoom)) or "Zoom unavailable",198,y,110,12,W.colors.muted)
    for i, item in ipairs({ { "Closer", -1 }, { "Farther", 1 } }) do
        local delta = item[2]
        local b = W.Button(env, parent, item[1], 198, y-22-(i-1)*36, 110, function() report(ui, actions.Step(delta)) end)
        if not zoom then b:Disable() end
    end
    y=y-102
    if runtime.db.config.preferences.reducedMotion then text("Reduced motion is on.", 24)
    elseif missing then text("Dimmed directions are unavailable on this client.", 26) end
    W.Toggle(env,parent,"Precision movement",0,y,310,function() return ui.precision end,
        function(value) ui.precision=value end,"Use a slower movement speed."); y=y-36
    local original = runtime.db.camera.composition.zoom
    if original then
        W.Button(env, parent, "Return zoom", 0, y, 150, function() report(ui, actions.Restore()) end, "Return to distance "..string.format("%.2f", original.original))
        W.Button(env, parent, "Keep current zoom", 160, y, 150, function() report(ui, actions.ForgetZoom()) end)
        y = y - 38
    end
    return y
end
function U.Frame(runtime, env, parent, y, ui, liveSlider)
    local preview = runtime.photoPreview
    local function text(label, height) W.Text(parent, label, 0, y, 310, 12, W.colors.muted); y = y - height end
    W.Section(parent, "SHOULDER & DYNAMIC FRAMING", 0, y, 310); y = y - 29
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
    text("Footroom takes effect when dynamic framing is on.", 36)
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
    y = ns.StageLayout.Choices(env, parent, y, {"JPEG","Antialiasing","Shadows"}, ui.outputPage, function(page)
        ui.outputPage=page; ui.notice=nil; ui.Build(true)
    end)
    if ui.outputPage=="JPEG" then
        local seen, format = ns.ReadOnly.Read(reader, "screenshotQuality"), ns.ReadOnly.Read(reader, "screenshotFormat")
        if format.code == "OK" and format.raw == "jpeg" and ns.PhotoOutput.Safe(seen, "screenshotQuality") then
            ui.jpeg = ui.jpeg or V.Number(seen.raw)
            W.Slider(env, parent, "JPEG quality", 0, y, 1, 10, 1, function() return ui.jpeg end, function(v) ui.jpeg = v; return true end, nil, 310); y = y - 70
            W.Button(env, parent, "Apply JPEG quality", 0, y, 150, function() report(ui, output.Apply("jpeg", { screenshotQuality = tostring(ui.jpeg) })) end)
            W.Button(env, parent, "Restore JPEG quality", 160, y, 150, function() report(ui, output.Restore("jpeg")) end); y = y - 44
            text("Higher JPEG quality reduces compression. Exit restores your previous setting.", 74)
        else text("JPEG quality is unavailable or WoW is using a different output format. Capture still works; the format is unchanged.", 74) end
    elseif ui.outputPage=="Antialiasing" then
        local observed = ns.PhotoOutput.Read(reader, "aa"); local safe = true
        for _, key in ipairs(ns.PhotoOutput.Groups.aa) do if not ns.PhotoOutput.Safe(observed[key], key) then safe = false end end
        if safe then
            local image, samples = ns.PhotoOutput.Options(reader)
            ui.aa = ui.aa or { ffxAntiAliasingMode = observed.ffxAntiAliasingMode.raw, MSAAQuality = observed.MSAAQuality.raw, MSAAAlphaTest = observed.MSAAAlphaTest.raw }
            local function choice(key, label, options)
                local current, index = "Current", 0
                for i, opt in ipairs(options) do if ns.PhotoOutput.Equal(key, tostring(opt.value), ui.aa[key]) then current, index = opt.label, i end end
                local inline = key == "ffxAntiAliasingMode"
                W.Text(parent, label, 0, y - (inline and 6 or 0), inline and 150 or 310, 12, W.colors.muted)
                if not inline then y = y - 24 end
                W.Button(env, parent, current .. "  >", inline and 156 or 0, y, inline and 154 or 310, function()
                    ui.aa[key] = tostring(options[index % #options + 1].value); ui.Build()
                end); y = y - 44
            end
            choice("ffxAntiAliasingMode", "Image antialiasing", image); choice("MSAAQuality", "Multisample antialiasing", samples)
            W.Toggle(env, parent, "Alpha-tested edges", 0, y, 310, function() return V.Number(ui.aa.MSAAAlphaTest) == 1 end,
                function(v) ui.aa.MSAAAlphaTest = v and "1" or "0" end); y = y - 46
            W.Button(env, parent, "Apply antialiasing", 0, y, 150, function() report(ui, output.Apply("aa", V.Copy(ui.aa))) end)
            W.Button(env, parent, "Restore antialiasing", 160, y, 150, function() report(ui, output.Restore("aa")) end); y = y - 44
            text("Higher sample counts can reduce frame rate. Exit restores your previous settings.", 48)
        else text("Native AA values are unavailable or restricted here. Other photo controls remain available.", 60) end
    elseif ui.outputPage=="Shadows" then
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
            text("These levels are available on your renderer. Exit restores your previous photo quality.", 68)
        else text("Ray-traced shadows are unavailable on this renderer. No graphics restart or renderer change is attempted.", 68) end
    end
    return y
end
