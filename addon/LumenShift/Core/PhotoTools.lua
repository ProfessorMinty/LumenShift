local _, ns = ...
local T, V = {}, ns.Value
ns.PhotoTools = T
T.Poses = { { "WAVE", "Wave" }, { "BOW", "Bow" }, { "CHEER", "Cheer" }, { "DANCE", "Dance" },
    { "FLEX", "Flex" }, { "KNEEL", "Kneel" }, { "LAUGH", "Laugh" }, { "POINT", "Point" },
    { "READ", "Read" }, { "SALUTE", "Salute" }, { "SIT", "Sit" }, { "STAND", "Stand" } }
function T.Known(token)
    for _, item in ipairs(T.Poses) do if item[1] == token then return true end end
    return false
end
function T.Defaults() return { delay = 3, shots = 1, interval = 2, autoPose = false, favorites = { WAVE = true, KNEEL = true, DANCE = true } } end
function T.Validate(data)
    if not V.Fields(data, { delay = true, shots = true, interval = true, autoPose = true, favorites = true })
        or type(data.autoPose) ~= "boolean" or type(data.favorites) ~= "table" then return false end
    for key, range in pairs({ delay = { 0, 10 }, shots = { 1, 5 }, interval = { 1, 5 } }) do
        local value = data[key]
        if not V.Finite(value) or value % 1 ~= 0 or value < range[1] or value > range[2] then return false end
    end
    for token, value in pairs(data.favorites) do if not T.Known(token) or value ~= true then return false end end
    return true
end
function T.New(runtime)
    local reader, env = runtime.reader, runtime.reader.env
    local self = { status = "READY" }
    local function ready()
        return runtime.camera.active and not reader.resetPending and not runtime.composition.suspended
            and not (runtime.portrait and runtime.portrait.active)
            and not runtime.camera.interrupted and not runtime.composition.capturing
            and not runtime.captureSequence.active
    end
    local function result(ok, code)
        self.status = code
        if self.Refresh then self.Refresh() end
        return ok, code
    end
    function self.Available()
        return type(env.C_ChatInfo) == "table" and type(env.C_ChatInfo.PerformEmote) == "function" or type(env.DoEmote) == "function"
    end
    local function oneShot(delay)
        local prefs = V.Copy(runtime.db.camera.tools)
        prefs.shots, prefs.delay = 1, delay
        return runtime.captureSequence.Start(prefs)
    end
    function self.TakeShot()
        return oneShot(0)
    end
    function self.Perform(token, takeShot)
        if not T.Known(token) then return result(nil, "INVALID_POSE") end
        if runtime.product.IsCombat() then return result(nil, "COMBAT_OR_RESTRICTION") end
        if not ready() then return result(nil, "CAMERA_NOT_READY") end
        if takeShot == nil then takeShot = runtime.db.camera.tools.autoPose end
        if takeShot then
            local ok, why = runtime.captureSequence.CanStart()
            if not ok then return result(nil, why) end
        end
        local modern = type(env.C_ChatInfo) == "table" and type(env.C_ChatInfo.PerformEmote) == "function"
        local fn = modern and env.C_ChatInfo.PerformEmote or env.DoEmote
        if type(fn) ~= "function" then return result(nil, "POSE_UNAVAILABLE") end
        local call = ns.ReadOnly.Call(reader, fn, token, "none")
        if not call or modern and (call.n ~= 1 or call[1] ~= true) or not modern and call[1] == false then
            return result(nil, "POSE_REJECTED") -- never retry through another API
        end
        result(true, "POSE_REQUESTED")
        if takeShot then return oneShot(runtime.db.camera.tools.delay) end
        return true
    end
    function self.Stop()
        if not runtime.camera.active or runtime.product.IsCombat() or reader.resetPending then return result(nil, "CAMERA_NOT_READY") end
        runtime.captureSequence.Cancel()
        local fn = type(env.C_ChatInfo) == "table" and env.C_ChatInfo.CancelEmote
        if type(fn) == "function" then
            local call = ns.ReadOnly.Call(reader, fn)
            return result(call and call[1] ~= false or nil, call and call[1] ~= false and "POSE_STOP_REQUESTED" or "POSE_REJECTED")
        end
        -- Explicit Stop uses the ordinary Stand emote on clients without CancelEmote.
        local ok, why = self.Perform("STAND", false)
        if not ok then return nil, why end
        return result(true, "POSE_STOP_REQUESTED")
    end
    function self.Favorite(token)
        if not T.Known(token) or not runtime.db or reader.resetPending then return nil end
        local favorites = runtime.db.camera.tools.favorites
        favorites[token] = not favorites[token] and true or nil
        return true
    end
    return self
end
