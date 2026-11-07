local _, ns = ...
local L, V = {}, ns.Value
ns.Log = L
local severity = { INFO = true, DEBUG = true, WARN = true, ERROR = true }
local fields = { key = true, layer = true, mode = true, profile = true, tx = true, state = true,
    original = true, before = true, requested = true, setter = true, immediate = true, followup = true,
    after = true, error = true, detail = true, count = true, result = true }
local numeric = { original = true, before = true, requested = true, immediate = true, followup = true, after = true }
local function code(value)
    if type(value) ~= "string" or #value > 96 or not value:match("^[%w_:%-%. ]+$") then return "REDACTED" end
    return value
end
L.Code = code
function L.New(reader)
    local log = { capacity = 240, sequence = 0, dropped = 0, coalesced = 0, events = {}, issues = {}, latest = {}, counts = {},
        native = { attempts = 0, accepted = 0, rejected = 0, verified = 0, restored = 0 } }
    local session = ns.ReadOnly.Call(reader, reader.env.GetServerTime)
    log.session = session and V.Finite(session[1]) and tostring(session[1]) or "current-login-time-unavailable"
    function log.Add(subsystem, operation, level, result, data)
        -- Slider drags can emit dozens of identical edits per second. Keep a count,
        -- not hundreds of records that evict actual operations and recovery history.
        local previous = log.events[(log.sequence - 1) % log.capacity + 1]
        if subsystem == "configuration" and operation == "edit" and level == "DEBUG" and result == "VALIDATED_NO_WRITE"
            and previous and previous.subsystem == subsystem and previous.operation == operation and previous.result == result then
            previous.data.count = math.min(2147483647, (previous.data.count or 1) + 1)
            log.coalesced = log.coalesced + 1
            return previous.sequence
        end
        if subsystem == "graphics" and operation == "setter" then
            log.native.attempts = log.native.attempts + 1
            local key = result == "ACCEPTED" and "accepted" or "rejected"
            log.native[key] = log.native[key] + 1
        elseif subsystem == "brightness" and operation == "verified" and (result == "BASELINE" or result == "ACTIVE") then
            log.native.verified = log.native.verified + 1
            if result == "BASELINE" then log.native.restored = log.native.restored + 1 end
        end
        local entry = { sequence = log.sequence + 1, subsystem = code(subsystem), operation = code(operation),
            severity = severity[level] and level or "INFO", result = code(result or "UNKNOWN"), data = {} }
        local now = ns.ReadOnly.Call(reader, reader.env.GetTime)
        if now and V.Finite(now[1]) then entry.time = now[1] end
        for key in pairs(fields) do
            local value = type(data) == "table" and data[key] or nil
            if value ~= nil then
                if numeric[key] then entry.data[key] = V.Number(value) and value or V.Finite(value) and tostring(value) or "REDACTED"
                elseif key == "key" then entry.data[key] = ns.Catalog.Get(value) and value or "REDACTED"
                elseif type(value) == "number" and V.Finite(value) then entry.data[key] = value
                elseif type(value) == "boolean" then entry.data[key] = value and "true" or "false"
                else entry.data[key] = code(value) end
            end
        end
        log.sequence = entry.sequence
        local slot = (entry.sequence - 1) % log.capacity + 1
        if log.events[slot] then log.dropped = log.dropped + 1 end
        log.events[slot] = entry
        log.counts[entry.severity] = (log.counts[entry.severity] or 0) + 1
        if entry.severity == "WARN" or entry.severity == "ERROR" then
            if #log.issues == 32 then table.remove(log.issues, 1) end
            log.issues[#log.issues + 1] = entry
        end
        if entry.data.key and entry.data.key ~= "REDACTED" then
            local latest = operation == "write" and {} or log.latest[entry.data.key] or {}
            for key, value in pairs(entry.data) do latest[key] = value end
            latest.operation, latest.result, latest.sequence = entry.operation, entry.result, entry.sequence
            log.latest[entry.data.key] = latest
        end
        return entry.sequence
    end
    function log.History()
        local result = {}
        for seq = math.max(1, log.sequence - log.capacity + 1), log.sequence do
            result[#result + 1] = V.Copy(log.events[(seq - 1) % log.capacity + 1])
        end
        return result
    end
    function log.Guard(subsystem, operation, fn, onError)
        return function(...)
            local function pack(...) return { n = select("#", ...), ... } end
            local result = pack(pcall(fn, ...))
            if result[1] then return unpack(result, 2, result.n) end
            -- Native error text/stack can contain names, paths or third-party data. Never retain it.
            log.Add(subsystem, operation, "ERROR", "OWNED_HANDLER_ERROR", { error = "DETAIL_REDACTED_FOR_PRIVACY" })
            if onError then pcall(onError) end
            if not log.notified then
                log.notified = true
                local chat = reader.env.DEFAULT_CHAT_FRAME
                if chat and type(chat.AddMessage) == "function" then
                    pcall(chat.AddMessage, chat, "LumenShift: an addon error was recorded. Click LumenShift, then Diagnostic Center and Export Complete Diagnostic Report.")
                end
            end
            return nil, "OWNED_HANDLER_ERROR"
        end
    end
    return log
end
function L.Record(reader, subsystem, operation, level, result, data)
    -- Logging failure must never turn a successful/failed native setter into a retry.
    if reader and reader.log then pcall(reader.log.Add, subsystem, operation, level, result, data) end
end
