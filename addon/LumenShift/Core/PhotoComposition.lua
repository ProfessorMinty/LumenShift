local _, ns = ...
local C, V = {}, ns.Value; ns.PhotoComposition = C
C.MaxPresets = 8
function C.Defaults() return { saved = {} } end
function C.ValidPreset(p)
    if not V.Fields(p, { thirds = true, aspect = true, framing = true, zoom = true }) or type(p.thirds) ~= "boolean"
        or not ({ none = true, wide = true, cinema = true, square = true })[p.aspect] or type(p.framing) ~= "table" then return false end
    if p.zoom ~= nil and (not V.Finite(p.zoom) or p.zoom < 0 or p.zoom > 50) then return false end
    for key, value in pairs(p.framing) do
        if not ns.Framing.Known(key) or ns.Framing.IsComfort(key) or not V.Finite(value) then return false end
        if key == "test_cameraDynamicPitch" and value ~= 0 and value ~= 1 then return false end
        if key == "cameraFov" then if value <= 0 or value >= 180 then return false end
        else local bounds = ns.Framing.Range(nil, key); if value < bounds.min or value > bounds.max then return false end end
    end
    return true
end
function C.Validate(data)
    if not V.Fields(data, { saved = true, zoom = true }) or type(data.saved) ~= "table" then return false end
    local count = 0
    for name, p in pairs(data.saved) do count = count + 1; if count > C.MaxPresets or not ns.PhotoConfig.Name(name) or not C.ValidPreset(p) then return false end end
    local z = data.zoom
    if z and (not V.Fields(z, { original = true, expected = true, requested = true, state = true })
        or not V.Finite(z.original) or z.original < 0 or z.original > 100
        or not V.Finite(z.expected) or z.expected < 0 or z.expected > 100
        or not V.Finite(z.requested) or z.requested < 0 or z.requested > 100
        or not ({ pending = true, owned = true, failed = true })[z.state]) then return false end
    return true
end
function C.New(runtime)
    local db = runtime.db
    local self = { status = "READY", busy = false, generation = 0 }
    local function ready() return db and runtime.camera.active and not runtime.product.IsCombat() and not runtime.reader.resetPending
        and not runtime.camera.interrupted and not runtime.composition.suspended and not self.busy and not runtime.cameraActions.busy and not runtime.output.busy and not runtime.captureSequence.active and not runtime.composition.capturing and not runtime.photoPreview.Pending() end
    function self.Save(name)
        if not ready() then return nil, "CAMERA_NOT_READY" end
        if not ns.PhotoConfig.Name(name) then return nil end
        local saved = db.camera.composition.saved
        if not saved[name] and #V.Keys(saved) >= C.MaxPresets then return nil, "COMPOSITION_LIMIT" end
        local p = { thirds = db.camera.thirds, aspect = db.camera.aspect, framing = {}, zoom = runtime.cameraActions.ReadZoom() }
        if p.zoom and p.zoom > 50 then p.zoom = nil end
        for _, key in ipairs(ns.Framing.Keys) do
            local item = ns.ReadOnly.Read(runtime.reader, key)
            if ns.Planner.SafeObservation(item) and ns.Framing.Bounds(key, item.raw, runtime.reader) then p.framing[key] = V.Number(item.raw) end
        end
        if not C.ValidPreset(p) then return nil end
        saved[name] = p; self.status = "Composition saved. Native framing applies only with Apply."; return true
    end
    function self.Apply(name)
        local p = db and db.camera.composition.saved[name]
        if not ready() or not C.ValidPreset(p) then return nil, "CAMERA_NOT_READY" end
        if runtime.cameraActions.busy then return nil, "BUSY" end
        self.busy, self.generation, self.status = true, self.generation + 1, "Applying composition…"
        local id = self.generation
        local function complete(ok, code)
            if id ~= self.generation or not self.busy then return end
            self.busy = false; self.status = ok and "Composition applied." or code
            if self.Refresh then self.Refresh() end
        end
        local ok, why = runtime.camera.ApplyFraming(V.Copy(p.framing), function(done, code)
            if id ~= self.generation then return end
            if not done then complete(false, code); return end
            local timer = ns.ReadOnly.Call(runtime.reader, runtime.reader.env.C_Timer and runtime.reader.env.C_Timer.After, 0, function()
                if id ~= self.generation then return end
                if not runtime.camera.active or runtime.camera.interrupted or runtime.product.IsCombat() then complete(false, "CAMERA_NOT_READY"); return end
                db.camera.thirds, db.camera.aspect = p.thirds, p.aspect; runtime.composition.Show()
                local moved, reason = true
                if p.zoom then
                    moved, reason = runtime.cameraActions.Zoom(p.zoom, complete)
                    if not moved then complete(false, reason) end
                else complete(true) end
            end)
            if not timer then complete(false, "COMPOSITION_TIMER_FAILED") end
        end)
        if not ok then complete(false, why) end
        return ok, why
    end
    function self.Cancel() self.generation = self.generation + 1; self.busy, self.status = false, "CANCELLED" end
    function self.Delete(name) if not ready() then return nil end; db.camera.composition.saved[name] = nil; return true end
    return self
end
