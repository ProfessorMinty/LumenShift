local _, ns = ...
local A, V = {}, ns.Value; ns.CameraActions = A
local movement = {
    up = { "MoveViewUpStart", "MoveViewUpStop" },
    down = { "MoveViewDownStart", "MoveViewDownStop" },
    left = { "MoveViewLeftStart", "MoveViewLeftStop" },
    right = { "MoveViewRightStart", "MoveViewRightStop" },
}
-- Native movement only. No CVar setters, view-slot writes or imported camera library.
function A.New(runtime)
    local env, reader, db = runtime.reader.env, runtime.reader, runtime.db
    local self = { busy = false, status = "READY", generation = 0 }
    local function refresh(code) self.status = code or self.status; if self.Refresh then self.Refresh() end end
    function self.ReadZoom()
        local r = ns.ReadOnly.Call(reader, env.GetCameraZoom)
        if r and r.n == 1 and V.Finite(r[1]) and r[1] >= 0 and r[1] <= 100 then return r[1] end
        return nil, "ZOOM_UNAVAILABLE"
    end
    local function ready()
        return db and runtime.camera.active and not runtime.product.IsCombat() and not reader.resetPending
            and not runtime.camera.interrupted and not runtime.composition.suspended and not runtime.captureSequence.active and not runtime.composition.capturing
            and not runtime.photoPreview.Pending() and not self.busy
    end
    function self.StopOrbit(direction)
        if not self.orbitStop or direction and self.orbit ~= direction then return true end
        local fn = self.orbitStop
        local ok = ns.ReadOnly.Call(reader, fn)
        if not ok or ok.n ~= 0 then refresh("CAMERA_STOP_FAILED"); return nil, self.status end
        self.orbitStop, self.orbit = nil, nil; self.orbitGeneration = (self.orbitGeneration or 0) + 1
        self.status = "Motion stopped."; return true
    end
    function self.HasMovement(direction)
        local pair = movement[direction]
        return pair ~= nil and type(env[pair[1]]) == "function" and type(env[pair[2]]) == "function"
            and type(env.C_Timer) == "table" and type(env.C_Timer.After) == "function"
    end
    function self.Orbit(direction, precision)
        if not ready() or runtime.db.config.preferences.reducedMotion or runtime.portrait.active then return nil, "CAMERA_NOT_READY" end
        if not self.HasMovement(direction) then return nil, "ORBIT_UNAVAILABLE" end
        local pair = movement[direction]
        local stopped = self.StopOrbit(); if not stopped then return nil, self.status end
        self.orbitStop, self.orbit = env[pair[2]], direction
        self.orbitGeneration = (self.orbitGeneration or 0) + 1; local id = self.orbitGeneration
        -- A held control is capped at five seconds even if its release event is lost.
        local timer = ns.ReadOnly.Call(reader, env.C_Timer.After, 5, function()
            if id == self.orbitGeneration and self.StopOrbit() then refresh() end
        end)
        if not timer then self.orbitStop, self.orbit = nil, nil; return nil, "ORBIT_TIMER_UNAVAILABLE" end
        local ok = ns.ReadOnly.Call(reader, env[pair[1]], precision and .025 or .08)
        if not ok or ok.n ~= 0 then self.StopOrbit(); refresh("ORBIT_FAILED"); return nil, self.status end
        refresh("Moving " .. direction .. ". Release to stop."); return true
    end
    local function move(target, restoring, callback)
        if self.busy or not db or runtime.product.IsCombat() or reader.resetPending then return nil, "CAMERA_NOT_READY" end
        if not restoring and not ready() then return nil, "CAMERA_NOT_READY" end
        if not V.Finite(target) or target < 0 or target > (restoring and 100 or 50) then return nil, "ZOOM_OUTSIDE_CONTROL_RANGE" end
        local current, why = self.ReadZoom(); if current == nil then return nil, why end
        local data = db.camera.composition
        local old = data.zoom
        if old and (old.state ~= "owned" or math.abs(current - old.expected) > .05) then refresh("ZOOM_EXTERNAL_CHANGE_KEPT"); return nil, self.status end
        if math.abs(current - target) <= .01 then if restoring then data.zoom = nil end; if callback then callback(true) end; return true end
        local fn
        if current > target then fn = env.CameraZoomIn else fn = env.CameraZoomOut end
        if type(fn) ~= "function" or not env.C_Timer or type(env.C_Timer.After) ~= "function" then return nil, "ZOOM_UNAVAILABLE" end
        data.zoom = old or { original = current, expected = current, requested = target, state = "pending" }
        local record = data.zoom; record.state, record.requested = "pending", target
        self.generation, self.busy = self.generation + 1, true; local id = self.generation
        local result = ns.ReadOnly.Call(reader, fn, math.abs(current - target))
        if not result or result.n ~= 0 then record.state = "failed"; self.busy = false; refresh("ZOOM_FAILED"); return nil, self.status end
        local previous, stable, attempts = current, 0, 0
        local function finish(ok, code)
            self.busy = false; refresh(code)
            local done = self.exitAfterZoom or callback; self.exitAfterZoom = nil
            if done then done(ok, code) end
        end
        local poll
        poll = function()
            if id ~= self.generation then return end
            local value = self.ReadZoom(); attempts = attempts + 1
            if value == nil then record.state = "failed"; finish(false, "ZOOM_READ_FAILED"); return end
            record.expected = value
            stable = math.abs(value - previous) <= .01 and stable + 1 or 0; previous = value
            if attempts >= 20 and stable < 2 then
                record.state = "failed"; finish(false, "Zoom did not settle; actual " .. string.format("%.2f", value) .. ". No automatic return."); return
            end
            if stable >= 2 then
                local matched = math.abs(value - target) <= .05
                record.state = "owned"
                if restoring and matched then data.zoom = nil end
                finish(not restoring or matched, matched and "Zoom verified." or "Zoom limited by collision or the client; actual " .. string.format("%.2f", value))
                return
            end
            local timer = ns.ReadOnly.Call(reader, env.C_Timer.After, .1, poll)
            if not timer then record.state = "failed"; finish(false, "ZOOM_TIMER_FAILED") end
        end
        local timer = ns.ReadOnly.Call(reader, env.C_Timer.After, .1, poll)
        if not timer then record.state = "failed"; self.busy = false; refresh("ZOOM_TIMER_FAILED"); return nil, self.status end
        refresh("Reading actual zoom..."); return true
    end
    function self.Zoom(target, callback) return move(target, false, callback) end
    function self.Step(delta)
        local current = self.ReadZoom()
        if current == nil or (delta ~= -1 and delta ~= 1) then return nil, "ZOOM_UNAVAILABLE" end
        return self.Zoom(math.max(0, math.min(50, current + delta)))
    end
    function self.Restore(callback)
        self.StopOrbit()
        if not db or not db.camera.composition.zoom then if callback then callback(true) end; return true end
        if self.busy then
            self.exitAfterZoom = function(ok, code) if ok then self.Restore(callback) elseif callback then callback(false, code) end end
            return true
        end
        return move(db.camera.composition.zoom.original, true, callback)
    end
    function self.Cancel()
        self.StopOrbit()
        local waiting = self.exitAfterZoom
        self.generation = self.generation + 1; self.exitAfterZoom = nil
        if self.busy then
            -- Stop requesting movement; do not infer a restorable zoom after interruption.
            self.busy = false
            if db.camera.composition.zoom then db.camera.composition.zoom.state = "failed" end
            refresh("Zoom interrupted; no automatic return.")
        end
        if waiting then waiting(false, "ZOOM_INTERRUPTED") end
    end
    function self.ForgetZoom()
        if not ready() then return nil, "CAMERA_NOT_READY" end
        db.camera.composition.zoom = nil; refresh("Keeping your current zoom."); return true
    end
    return self
end
