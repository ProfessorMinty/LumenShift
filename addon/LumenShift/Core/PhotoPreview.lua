local _, ns = ...
local P = {}; ns.PhotoPreview = P
-- A finite, event-driven queue. One native transaction at a time, newest value
-- per control, with a short pause after verification. No idle polling or writer.
function P.New(runtime)
    local env, editor = runtime.reader.env, runtime.photoEditor
    local self = { pending = {}, order = {}, generation = 0, busy = false, scheduled = false, status = "IDLE" }
    local known = { Brightness = true, Contrast = true, ResampleSharpness = true, bloomUserMult = true, cameraFov = true }
    local pump, schedule
    local function refresh() if self.Refresh then self.Refresh() end end
    local function ready()
        local c = runtime.composition
        return editor.active and runtime.camera.active and not runtime.product.IsCombat() and not runtime.reader.resetPending
            and not runtime.camera.interrupted and c and not c.controlsHidden and not c.capturing
    end
    function self.Pending() return self.busy or self.scheduled or #self.order > 0 or self.action ~= nil end
    function self.Begin()
        self.halted, self.error = false, nil -- new deliberate gesture, never a recovery-data reset
    end
    function self.Cancel(reason)
        self.generation = self.generation + 1
        self.pending, self.order, self.action, self.scheduled = {}, {}, nil, false
        self.status = reason or "CANCELLED"
        -- An issued transaction must finish verification; it cannot be recalled.
        refresh()
    end
    local function fail(code)
        self.generation = self.generation + 1
        self.pending, self.order, self.action, self.scheduled = {}, {}, nil, false
        self.halted, self.error, self.status = true, code or "PHOTO_PREVIEW_FAILED", "FAILED"
        refresh()
    end
    schedule = function()
        if self.scheduled or self.busy then return true end
        if #self.order == 0 and not self.action then self.status = "IDLE"; refresh(); return true end
        local generation = self.generation
        self.scheduled, self.status = true, "QUEUED"
        local result = ns.ReadOnly.Call(runtime.reader, env.C_Timer and env.C_Timer.After, 0.05, function()
            if generation ~= self.generation then return end
            self.scheduled = false; pump()
        end)
        if not result then fail("FOLLOWUP_TIMER_UNAVAILABLE"); return nil, self.error end
        return true
    end
    pump = function()
        if not ready() then self.Cancel("CONTEXT_CHANGED"); return end
        local key = table.remove(self.order, 1)
        if not key then
            local action = self.action; self.action, self.status = nil, "IDLE"
            refresh(); if action then action() end; return
        end
        local value, generation = self.pending[key], self.generation
        self.pending[key] = nil
        self.busy, self.status, self.currentKey, self.currentValue = true, "VERIFYING", key, value
        local completed = false
        local function done(ok, why)
            if completed then return end
            completed, self.busy, self.currentKey, self.currentValue = true, false, nil, nil
            if generation ~= self.generation then
                -- A new entry may have queued input while a cancelled operation
                -- finished. Only a fresh, still-visible context can schedule it.
                if ready() then schedule() else refresh() end
                return
            end
            if not ok then fail(why); return end
            schedule() -- leaves the writer callback guard before another request
        end
        local called, ok, why = pcall(function()
            if key == "cameraFov" then return runtime.camera.ApplyFOV(value, done) end
            local values = key == "ResampleSharpness" and { ResampleAlwaysSharpen = 1, ResampleSharpness = (100 - value) / 50 }
                or { [key] = value }
            return editor.Native(values, done)
        end)
        if not called then done(false, "PHOTO_PREVIEW_HANDLER_ERROR")
        elseif not ok and not completed then done(false, why) end
        refresh()
    end
    function self.Queue(key, value)
        if not known[key] or not ns.Value.Finite(value) then return nil, "INVALID_PHOTO_REQUEST" end
        if not ready() then return nil, "CAMERA_NOT_READY" end
        if self.halted then return nil, self.error end
        if self.action then return nil, "PHOTO_ACTION_WAITING" end
        if editor.before and key ~= "cameraFov" then fail("SHOW_AFTER_FIRST"); return nil, self.error end
        if self.pending[key] == nil then self.order[#self.order + 1] = key end
        self.pending[key] = value
        local ok, why = schedule(); refresh(); return ok, why
    end
    -- Capture, clean view and comparison honor the latest drag endpoint first.
    -- Exit/combat instead cancel unissued work and preserve the existing return path.
    function self.Finish(action)
        if self.action then return true end
        if not self.Pending() then return action() end
        self.action = action
        return schedule()
    end
    return self
end
