local _, ns = ...
local C, W = {}, ns.Widgets
ns.WorldCaptureUI = C

local errors = {
    SCREENSHOT_UNAVAILABLE = "Screenshot or timer unavailable.",
    SCREENSHOT_FAILED = "WoW reported a screenshot failure.",
    CAPTURE_RESULT_UNOBSERVED = "WoW did not confirm the last shot.",
    CAPTURE_TIMER_FAILED = "The capture timer could not run.",
    PHOTO_ACTION_WAITING = "Finishing another photo action.",
}

local function enable(button, available)
    if available then button:Enable(); button:SetAlpha(1)
    else button:Disable(); button:SetAlpha(.55) end
end

local function stepper(env, parent, label, y, minimum, maximum, change)
    W.Text(parent, label, 0, y-6, 125, 13)
    local less = W.Button(env, parent, "-", 154, y, 38, function() change(-1) end, "Decrease "..label:lower())
    local number = W.Text(parent, "", 197, y-5, 70, 16)
    number:SetJustifyH("CENTER")
    local more = W.Button(env, parent, "+", 272, y, 38, function() change(1) end, "Increase "..label:lower())
    return function(value, editing)
        number:SetText(value.." s")
        enable(less, editing and value > minimum); enable(more, editing and value < maximum)
    end
end

function C.Timer(runtime, env, parent, ui)
    local seq, prefs = runtime.captureSequence, runtime.db.camera.tools
    local function shotCount() return seq.active and seq.total or prefs.shots end
    local burst = shotCount() > 1
    local function choose(key, value)
        if seq.active or runtime.composition.capturing then return end
        if key == "shots" and prefs.shots > 1 then ui.lastBurst = prefs.shots end
        prefs[key] = value
        ui.dismissedCapture, ui.captureError = seq.generation, nil
        ui.Refresh()
    end
    local single = W.Button(env, parent, "Single shot", 0, 0, 151, function() choose("shots",1) end)
    local multiple = W.Button(env, parent, "Burst", 159, 0, 151, function()
        choose("shots", prefs.shots > 1 and prefs.shots or ui.lastBurst or 3)
    end)
    W.ButtonIcon(single, "ui-camera", 17); W.ButtonIcon(multiple, "ui-presets", 17)
    local delay = stepper(env, parent, "First shot delay", -41, 0, 10, function(delta)
        choose("delay", math.max(0, math.min(10, prefs.delay + delta)))
    end)
    local counts, spacing = {}, nil
    if burst then
        W.Text(parent, "Shots in burst", 0, -86, 115, 13)
        for i=2,5 do
            local n = i
            local b = W.Button(env, parent, tostring(n), 122+(i-2)*48, -80, 44, function() choose("shots",n) end)
            b.label:ClearAllPoints(); b.label:SetPoint("CENTER", b, "CENTER"); b.label:SetWidth(40); b.label:SetJustifyH("CENTER")
            counts[n] = b
        end
        spacing = stepper(env, parent, "Between shots", -119, 1, 5, function(delta)
            choose("interval", math.max(1, math.min(5, prefs.interval + delta)))
        end)
    end

    local y = burst and -162 or -84
    local board = env.CreateFrame("Frame", nil, parent)
    board:SetPoint("TOPLEFT",parent,"TOPLEFT",0,y); board:SetSize(310,73)
    W.Fill(board,W.colors.sidebar)
    local meter = W.Text(board,"",8,-9,96,28,W.colors.accent)
    meter:SetJustifyH("CENTER")
    local headline = W.Text(board,"",113,-9,191,15)
    local detail = W.Text(board,"",113,-32,191,12,W.colors.muted)
    local segments = {}
    for i=1,5 do segments[i]=W.Texture(board,"ARTWORK") end
    local function press()
        if seq.active then seq.Cancel(); return end
        ui.captureError = nil
        local ok, why = seq.Start()
        if not ok then ui.captureError = why; ui.Refresh() end
    end
    local action = W.Button(env,parent,"Start timer",0,y-82,310,press,nil,"primary")

    ui.RefreshWorldCapture = function()
        local count = shotCount()
        if burst ~= (count > 1) then return true end -- Reflow only when switching single/burst.
        local active, editing = seq.active, not seq.active and not runtime.composition.capturing
        local wait = active and seq.delay or prefs.delay
        local interval = active and seq.interval or prefs.interval
        single.SetSelected(not burst); multiple.SetSelected(burst)
        enable(single,editing); enable(multiple,editing); delay(wait,editing)
        if burst then
            for n,b in pairs(counts) do b.SetSelected(n==count); enable(b,editing) end
            spacing(interval,editing)
        end

        local canStart, reason = seq.CanStart()
        local state = seq.state
        local confirmed, total = 0, count
        local title, subtitle = "Ready to shoot", burst and (count.." shots · "..interval.." s apart") or "Single shot"
        local value = wait==0 and "Now" or wait.." s"
        local errorCode = ui.captureError or (not active and not canStart and reason)
        if active then
            confirmed, total = seq.completed, seq.total
            title = "Shot "..(confirmed+1).." of "..total
            if state=="WAITING_FOR_PREVIEW" then value, subtitle="…","Finishing photo edits"
            elseif state=="CAPTURING" then value, subtitle="…","Waiting for WoW"
            else value, subtitle=seq.remaining.." s", state=="INTERVAL" and "Until next shot" or "Until first shot" end
        elseif seq.total and seq.generation~=ui.dismissedCapture then
            confirmed, total = seq.completed, seq.total
            value = confirmed.."/"..total
            subtitle = confirmed..(confirmed==1 and " shot confirmed" or " shots confirmed")
            if state=="COMPLETE" then title = total==1 and "Screenshot saved" or "Burst saved"
            elseif state=="CANCELLED" then title = "Cancelled"
            else title = "Capture stopped"; errorCode = errorCode or state end
        elseif errorCode then
            value, title, subtitle = "—", "Capture unavailable", ""
        end
        meter:SetText(value); headline:SetText(title); detail:SetText(subtitle)
        local width = (290-4*(total-1))/total
        for i,segment in ipairs(segments) do
            if i<=total then
                segment:ClearAllPoints(); segment:SetPoint("TOPLEFT",board,"TOPLEFT",10+(i-1)*(width+4),-61)
                segment:SetSize(width,4)
                local color = i<=confirmed and W.colors.accent or active and i==confirmed+1 and W.colors.text or W.colors.border
                segment:SetColorTexture(unpack(color)); segment:Show()
            else segment:Hide() end
        end
        local label = burst and "Start burst" or wait>0 and "Start timer" or "Take shot now"
        if active then label = state=="INTERVAL" and "Stop burst" or "Cancel capture" end
        action.label:SetText(label)
        enable(action, active or canStart)
        runtime.composition.SetTimerShutter(press,label,active or canStart or false)
        ui.captureHint = errorCode and (errors[errorCode] or ns.Product.Message(errorCode)) or ""
        return false
    end
    return y-120
end
