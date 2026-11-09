local _, ns = ...
local P, V = {}, ns.Value
ns.PhotoEditor = P
function P.New(runtime)
    local reader, db = runtime.reader, runtime.db
    local self = { busy = false, before = false, status = "READY", active = false }
    local function data() return db and db.camera.editor end
    local function refresh(code)
        self.status = code or self.renderError or "READY"
        if self.Refresh then self.Refresh() end
    end
    local function gate()
        if not data() or not ns.PhotoConfig.Validate(data()) then return nil, "INVALID_PHOTO_DATA" end
        if runtime.resetPending or reader.resetPending then return nil, "RESET_PENDING" end
        if runtime.product.IsCombat() then return nil, "COMBAT_OR_RESTRICTION" end
        if self.busy or runtime.camera.busy or runtime.product.busy or runtime.visual.busy then return nil, "BUSY" end
        if db.optics.comparison then return nil, "FINISH_COMPARISON" end
        return true
    end
    function self.Render()
        if runtime.photoEffects then
            if self.active and not runtime.product.IsCombat() then
                local look = data().look
                local treated = look.strength > 0 and (look.warmth ~= 0 or look.tint ~= 0 or look.vignette > 0 or look.glow > 0 or look.grain > 0) or look.letterbox > 0
                if self.before or not treated then runtime.product.RefreshPresentation(true, true)
                elseif runtime.presentation then runtime.presentation.Clear() end
                local ok = pcall(runtime.photoEffects.Apply, data().look, self.before)
                self.renderError = not ok and "Photo effects unavailable; Camera capture and exit still work." or nil
                if not ok then runtime.photoEffects.Hide() end
            else runtime.photoEffects.Hide() end
        end
    end
    function self.Enter()
        if runtime.photoPreview then runtime.photoPreview.Begin() end
        self.active, self.before = true, false
        self.Render(); refresh(data().session and "PHOTO_RECOVERY_RETAINED" or nil)
    end
    function self.Hide()
        self.active = false
        if runtime.photoEffects then runtime.photoEffects.Hide() end
    end
    function self.Set(key, value)
        if not self.active or runtime.product.IsCombat() or reader.resetPending then return nil end
        local look = V.Copy(data().look); look[key] = value
        if not ns.PhotoConfig.ValidLook(look) then return nil end
        data().look = look; self.Render(); return true
    end
    function self.Recipe(id)
        local look = ns.PhotoConfig.Recipe(id); if not look or not self.active or reader.resetPending or runtime.product.IsCombat() then return nil end
        data().look = look; self.Render(); refresh(); return true
    end
    function self.Save(name)
        if not self.active or reader.resetPending then return nil end
        if not ns.PhotoConfig.Name(name) then refresh("Use a name of 1-32 characters."); return nil end
        local count = 0; for _ in pairs(data().saved) do count = count + 1 end
        if count >= 12 and not data().saved[name] then refresh("Twelve looks saved; delete one first."); return nil end
        data().saved[name] = V.Copy(data().look); refresh("Photo look saved."); return true
    end
    function self.Load(name)
        if not self.active or reader.resetPending or runtime.product.IsCombat() then return nil end
        local look = data().saved[name]; if not look then return nil end
        data().look = V.Copy(look); self.Render(); refresh("Photo look loaded."); return true
    end
    function self.Delete(name) if not self.active or reader.resetPending then return nil end; data().saved[name] = nil; refresh("Photo look deleted.") end
    function self.Import(text)
        if not self.active or reader.resetPending or runtime.product.IsCombat() then return nil end
        local look = ns.PhotoConfig.Import(text); if not look then refresh("Invalid LSPHOTO1 look."); return nil end
        data().look = look; self.Render(); refresh("Photo look imported."); return true
    end
    function self.Read(key)
        local item = ns.ReadOnly.Read(reader, key)
        if not ns.Planner.SafeObservation(item) or not ns.Optics.RawMap({ [key] = item.raw }) then return nil, "Unavailable or restricted" end
        local ok, why = ns.ExperimentPolicy.Capability(reader, key)
        if not ok then return nil, ns.Product.Message(why) end
        return V.Number(item.raw), item.raw
    end
    local function operation(raw, expected, returning, nextState, done)
        self.busy = true
        local s, completed = data().session, false
        local previousState = s.state; s.state = "pending"
        local ok, why = runtime.visual.Photo(raw, expected, returning, function(success, code, compensated)
            completed, self.busy = true, false
            if success then
                s.state = nextState
                for key, wanted in pairs(raw) do
                    local item = ns.ReadOnly.Read(reader, key)
                    s.expected[key] = item.raw or s.expected[key]
                    if returning and (not ns.Planner.SafeObservation(item) or item.raw ~= wanted) then
                        success, code, s.state = false, "PHOTO_EXACT_RETURN_FAILED", "recovery"
                    end
                end
            elseif compensated then s.state = previousState
            else s.state = "recovery" end
            refresh(success and "Verified. Exit returns your pre-photo values." or ns.Product.Message(code))
            if done then done(success, code, compensated) end
            if runtime.camera.interrupted and runtime.camera.active and not runtime.product.IsCombat() then
                ns.ReadOnly.Call(reader, reader.env.C_Timer and reader.env.C_Timer.After, 0, runtime.camera.Exit)
            end
        end)
        if not ok and not completed then self.busy = false; s.state = previousState; refresh(ns.Product.Message(why)) end
        return ok, why
    end
    function self.Native(values, onComplete)
        local allowed, why = gate(); if not allowed then refresh(ns.Product.Message(why)); return nil, why end
        if not self.active or self.before then return nil, "SHOW_AFTER_FIRST" end
        local raw = {}; for key, value in pairs(values) do
            if not V.Finite(value) then return nil, "INVALID_PHOTO_REQUEST" end
            raw[key] = tostring(value)
        end
        if not ns.Optics.RawMap(raw) then return nil, "INVALID_PHOTO_REQUEST" end
        local s = V.Copy(data().session) or { before = {}, after = {}, expected = {}, state = "after" }
        if s.state ~= "after" then refresh("Restore photo lighting before another native edit."); return nil, "PHOTO_RECOVERY_RETAINED" end
        local previous = V.Copy(s)
        for key in pairs(raw) do
            local value, current = self.Read(key); if not value then refresh(current); return nil, current end
            if not s.before[key] then s.before[key], s.after[key], s.expected[key] = current, current, current end
        end
        local requested = V.Copy(s.after); for key, value in pairs(raw) do requested[key] = value end
        data().session = s -- pre-photo return intent is retained before the single writer runs
        local called = false
        local ok, code = operation(requested, V.Copy(s.expected), false, "after", function(success, reason, compensated)
            called = true
            if success then s.after = V.Copy(s.expected)
            elseif compensated then data().session = next(previous.before) and previous or nil end
            if onComplete then onComplete(success, reason, compensated) end
        end)
        if not ok and not called then data().session = next(previous.before) and previous or nil end
        return ok, code
    end
    function self.Compare()
        local allowed, why = gate(); if not allowed then return nil, why end
        local target = not self.before
        local s = data().session
        if not s then self.before = target; self.Render(); refresh(target and "Before photo edits" or "After photo edits"); return true end
        if s.state ~= "before" and s.state ~= "after" then return nil, "PHOTO_RECOVERY_RETAINED" end
        return operation(V.Copy(target and s.before or s.after), V.Copy(s.expected), true, target and "before" or "after", function(ok)
            if ok then self.before = target; self.Render(); refresh(target and "Before photo edits" or "After photo edits") end
        end)
    end
    function self.Restore(done)
        local s = data() and data().session
        if not s then if done then done(true) end; return true end
        if self.busy then return nil, "BUSY" end
        -- Restore unaffected members together; an externally changed member is
        -- retained, never forcibly re-based to the current value for an Exit.
        local raw, expected, conflict = {}, {}, false
        for key, value in pairs(s.before) do
            local item = ns.ReadOnly.Read(reader, key)
            local entry = key == "Brightness" and db.journal.entries[key] or db.experiments.journal.entries[key]
            if ns.Planner.SafeObservation(item) and (item.raw == s.expected[key] or item.raw == value)
                and (not entry or entry.state == "owned") then raw[key], expected[key] = value, item.raw
            elseif entry and ns.Planner.ReturnedOriginal(entry, item, ns.Compatibility.Inspect(reader).signature, key) then
                -- The owner's fallback already restored the canonical original.
                -- Release it without replaying the pre-photo mode over that choice.
                raw[key], expected[key] = item.raw, item.raw
            else conflict = true end
        end
        if not next(raw) then refresh("Photo recovery retained; external changes kept."); if done then done(false, "EXTERNAL_CONFLICT") end; return nil, "EXTERNAL_CONFLICT" end
        return operation(raw, expected, true, "after", function(ok, why)
            if ok then
                for key in pairs(raw) do s.before[key], s.after[key], s.expected[key] = nil, nil, nil end
                if not next(s.before) then data().session = nil else s.state = "recovery" end
            end
            self.before = false; self.Render()
            if done then done(ok and not conflict, why or conflict and "EXTERNAL_CONFLICT" or nil) end
        end)
    end
    function self.Observe()
        if self.busy then return end
        local s = data() and data().session
        if not s then return end
        for key, raw in pairs(s.expected) do
            local item = ns.ReadOnly.Read(reader, key)
            if not ns.Planner.SafeObservation(item) or item.raw ~= raw then s.state = "recovery" end
        end
    end
    return self
end
