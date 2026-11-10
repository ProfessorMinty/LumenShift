local _, ns = ...
local S = {}; ns.CaptureSequence = S
function S.New(runtime)
    local reader, env = runtime.reader, runtime.reader.env
    local self = { active = false, state = "IDLE", generation = 0, completed = 0, remaining = 0 }
    local function refresh() if self.Refresh then self.Refresh() end end
    local function context()
        return runtime.camera.active and not runtime.camera.interrupted and runtime.camera.CanCompose() and not reader.resetPending
    end
    local function finish(state)
        self.active, self.state, self.remaining = false, state, 0
        self.generation = self.generation + 1; refresh()
    end
    function self.Cancel()
        if not self.active then return end
        finish("CANCELLED")
        if runtime.composition then runtime.composition.CancelPendingCapture() end
    end
    local function later(seconds, id, fn)
        local call = ns.ReadOnly.Call(reader, env.C_Timer and env.C_Timer.After, seconds, function()
            if not self.active or self.generation ~= id then return end
            if not context() then self.Cancel(); return end
            fn()
        end)
        if not call then finish("CAPTURE_TIMER_FAILED"); return nil end
        return true
    end
    function self.Start(options)
        if runtime.portrait and (runtime.portrait.busy or runtime.portrait.layerCapture) then return nil, "PORTRAIT_NOT_READY" end
        if self.active or runtime.composition.capturing or not context() then return nil, "CAMERA_NOT_READY" end
        local prefs = ns.Value.Copy(options or runtime.db.camera.tools)
        if not ns.PhotoTools.Validate(prefs) then return nil, "INVALID_CAPTURE_OPTIONS" end
        if type(env.Screenshot) ~= "function" or type(env.C_Timer) ~= "table" or type(env.C_Timer.After) ~= "function" then
            self.state = "SCREENSHOT_UNAVAILABLE"; refresh(); return nil, self.state
        end
        self.generation = self.generation + 1
        local id = self.generation
        self.active, self.completed, self.total, self.state = true, 0, prefs.shots, "WAITING_FOR_PREVIEW"
        local shot, countdown
        shot = function()
            if not self.active or id ~= self.generation then return end
            if not context() then self.Cancel(); return end
            self.state, self.remaining = "CAPTURING", 0; refresh()
            local called = false
            local ok, why = runtime.composition.Capture(function(success, code)
                called = true
                if not self.active or id ~= self.generation then return end
                if not success then finish(code or "SCREENSHOT_FAILED"); return end
                self.completed = self.completed + 1
                if self.completed >= prefs.shots then finish("COMPLETE")
                else countdown(prefs.interval, "INTERVAL") end
            end)
            if not ok and not called then finish(why or "SCREENSHOT_FAILED") end
        end
        countdown = function(seconds, state)
            if not self.active or id ~= self.generation then return end
            self.remaining, self.state = seconds, state; refresh()
            if seconds == 0 then shot() else later(1, id, function() countdown(seconds - 1, state) end) end
        end
        local function begin()
            if self.active and id == self.generation then countdown(prefs.delay, "COUNTDOWN") end
        end
        if runtime.photoPreview.Pending() then
            local ok, why = runtime.photoPreview.Finish(begin)
            if not ok then finish(why or "PHOTO_PREVIEW_FAILED"); return nil, self.state end
        else begin() end
        refresh()
        if not self.active and self.state ~= "COMPLETE" then return nil, self.state end
        return true
    end
    function self.ObservePreview()
        if self.active and self.state == "WAITING_FOR_PREVIEW" and not runtime.photoPreview.Pending() and runtime.photoPreview.error then
            finish(runtime.photoPreview.error)
        end
    end
    return self
end
