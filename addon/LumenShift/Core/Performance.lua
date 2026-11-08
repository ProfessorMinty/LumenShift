local _, ns = ...
local P, V = {}, ns.Value
ns.Performance = P
P.Scenes = { outdoor = "Outdoor", town = "Busy town", interior = "Interior", raid = "Raid", battleground = "Battleground" }
P.Priorities = { smooth = "Smooth gameplay", scenery = "Richer scenery", quiet = "Quieter operation" }
function P.New(runtime)
    local reader, env = runtime.reader, runtime.reader.env
    local self = { active = false, generation = 0, results = {}, scene = "outdoor", priority = "smooth", status = "READY" }
    local function refresh() if runtime.ui then runtime.ui.Refresh() end end
    local function number(fn)
        local result = ns.ReadOnly.Call(reader, fn)
        return result and result.n == 1 and V.Finite(result[1]) and result[1] or nil
    end
    local function snapshot()
        local values = {}
        local keys = ns.NativeGraphics.Keys()
        for _, key in ipairs({ "Brightness", "Contrast", "Gamma", "RenderScale", "ResampleAlwaysSharpen", "ResampleSharpness", "bloomUserMult", "cameraFov", "maxFPS", "maxFPSBk" }) do keys[#keys + 1] = key end
        for _, key in ipairs(keys) do
            local item = ns.ReadOnly.Read(reader, key)
            values[key] = ns.Planner.SafeObservation(item) and item.raw or "unavailable"
        end
        return values
    end
    local function same(a, b)
        for key, raw in pairs(a) do if raw ~= b[key] then return false end end
        return true
    end
    function self.Cancel(code)
        self.generation = self.generation + 1
        self.active, self.status = false, code or "CANCELLED"; refresh()
    end
    function self.Start()
        if self.active then return nil, "BUSY" end
        if not P.Scenes[self.scene] or not P.Priorities[self.priority] then return nil, "INVALID_SAMPLE_CHOICE" end
        for _, name in ipairs({ "brightnessBusy", "visualBusy", "graphicsBusy", "experimentBusy", "nameBusy", "tierOccupied" }) do
            if reader[name] and reader[name]() then self.status = "SAMPLE_AFTER_OPERATION"; return nil, self.status end
        end
        local clock, fps = number(env.GetTime), number(env.GetFramerate)
        if not clock or not fps or fps <= 0 or type(env.C_Timer) ~= "table" or type(env.C_Timer.After) ~= "function" then
            self.status = "FPS_API_UNAVAILABLE"; return nil, self.status
        end
        self.generation = self.generation + 1
        local id, before, points = self.generation, snapshot(), {}
        local result = { scene = self.scene, priority = self.priority, requested = runtime.db and V.Copy(runtime.db.graphics.choices),
            effective = before, signature = ns.Compatibility.Inspect(reader).signature, window = 10, combatSamples = 0, combatUnknown = 0 }
        self.active, self.status = true, "SETTLING"
        local start, previous
        local function schedule(delay, fn)
            if not pcall(env.C_Timer.After, delay, fn) then self.Cancel("SAMPLE_TIMER_FAILED"); return nil end
            return true
        end
        local function sample()
            if id ~= self.generation or not self.active then return end
            if not same(before, snapshot()) then self.Cancel("SAMPLE_SETTINGS_CHANGED"); return end
            local now, value = number(env.GetTime), number(env.GetFramerate)
            if not now or not value or value <= 0 or now <= previous then self.Cancel("FPS_OBSERVATION_INVALID"); return end
            points[#points + 1], previous = value, now
            local combat = ns.ReadOnly.Call(reader, env.InCombatLockdown)
            if not combat or combat.n ~= 1 or type(combat[1]) ~= "boolean" then result.combatUnknown = result.combatUnknown + 1
            elseif combat[1] then result.combatSamples = result.combatSamples + 1 end
            self.status = "SAMPLING_" .. #points .. "_OF_10"; refresh()
            if #points < 10 then schedule(1, sample); return end
            local sum, low, high = 0, points[1], points[1]
            for _, n in ipairs(points) do sum = sum + n; low = math.min(low, n); high = math.max(high, n) end
            result.mean, result.low, result.high, result.count, result.elapsed = sum / #points, low, high, #points, now - start
            self.results[#self.results + 1] = result
            if #self.results > 2 then table.remove(self.results, 1) end
            self.active, self.status = false, "COMPLETE"; refresh()
        end
        schedule(2, function()
            if id ~= self.generation or not self.active then return end
            start = number(env.GetTime); previous = start
            if not start then self.Cancel("FPS_OBSERVATION_INVALID"); return end
            self.status = "SAMPLING_0_OF_10"; schedule(1, sample)
        end)
        refresh(); return self.active or nil, self.active and nil or self.status
    end
    function self.Text()
        local lines = { self.status == "READY" and "Ready for a 10-second observation after a 2-second settling period." or self.status }
        for i, result in ipairs(self.results) do
            lines[#lines + 1] = string.format("%s · %s · %.1f seconds · FPS mean %.1f / min %.1f / max %.1f", i == 1 and "A" or "B",
                P.Scenes[result.scene], result.elapsed, result.mean, result.low, result.high)
        end
        if #self.results == 2 then
            lines[#lines + 1] = self.results[1].scene == self.results[2].scene
                and "Same scene label; matching viewpoint, movement and load still need your judgment."
                or "Different scene labels: these observations are not a controlled comparison."
        end
        return table.concat(lines, "\n")
    end
    return self
end
