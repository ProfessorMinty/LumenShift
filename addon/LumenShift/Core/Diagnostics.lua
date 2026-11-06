local _, ns = ...
local D = {}
ns.Diagnostics = D
local function bool(value) return value and "yes" or "no" end

function D.Lines(runtime)
    local reader = runtime.reader
    local identity = ns.Compatibility.Inspect(reader)
    local caps = ns.ReadOnly.Capabilities(reader)
    local observed = {}
    local lines = { "LumenShift " .. ns.version .. " | diagnostic only; graphics writes disabled",
        "Client: " .. (identity.version or "unknown") .. " build " .. (identity.build or "unknown")
            .. " interface " .. tostring(identity.interface or "unknown"),
        "Compatibility: " .. identity.status .. " (" .. identity.reason .. "); renderer UNVERIFIED; future writes unavailable",
        "SavedVariables: " .. runtime.storeStatus .. "; no immediate disk-save guarantee" }
    for _, name in ipairs({ "AreCVarsLoaded", "GetCVar", "GetCVarDefault", "GetCVarInfo", "canaccessvalue", "issecretvalue" }) do
        lines[#lines + 1] = name .. ": " .. (caps[name] and "available" or "unavailable")
    end
    for _, key in ipairs(ns.Catalog.Keys()) do
        local item = ns.ReadOnly.Read(reader, key)
        observed[key] = item
        lines[#lines + 1] = key .. ": " .. (item.raw or "unavailable") .. " (" .. item.code .. ")"
            .. "; default " .. (item.defaultRaw or "unavailable") .. " (" .. (item.defaultCode or item.code) .. ")"
        if item.flags then
            lines[#lines + 1] = key .. " flags: secure=" .. bool(item.flags.secure)
                .. " readOnly=" .. bool(item.flags.readOnly) .. " locked=" .. bool(item.flags.locked)
                .. " serverAccount=" .. bool(item.flags.serverAccount) .. " serverCharacter=" .. bool(item.flags.serverCharacter)
        else lines[#lines + 1] = key .. " flags: " .. (item.flagsCode or item.code) end
    end
    local recovery = runtime.db and ns.Recovery.Inspect(runtime.db.journal, observed, identity.signature)
    lines[#lines + 1] = "State: " .. (recovery and recovery.state or "RECOVERY")
        .. "; saved selection is metadata, never an active preset"
    if recovery then
        local count = 0
        for _ in pairs(recovery.entries) do count = count + 1 end
        lines[#lines + 1] = "Recovery records: " .. count .. "; matching values do not prove ownership"
        for _, key in ipairs(ns.Catalog.Keys()) do
            if recovery.entries[key] then lines[#lines + 1] = key .. " recovery: " .. recovery.entries[key] end
        end
    else lines[#lines + 1] = "Recovery: saved data preserved in place; schema quarantined" end
    lines[#lines + 1] = "Supported: read-only diagnostics and pure models. Unverified: native loading, persistence, restoration."
    lines[#lines + 1] = "Unavailable: preset activation, effects, graphics writes. No write-admitted CVars."
    if runtime.lastError then lines[#lines + 1] = "Last error: " .. runtime.lastError end
    return lines
end

function D.Show(runtime)
    local ok, lines = pcall(D.Lines, runtime)
    if not ok then
        runtime.lastError = "DIAGNOSTIC_ERROR"
        lines = { "LumenShift: diagnostic read failed; no graphics settings changed." }
    end
    local chat = runtime.reader.env.DEFAULT_CHAT_FRAME
    if chat and type(chat.AddMessage) == "function" then
        for _, line in ipairs(lines) do pcall(chat.AddMessage, chat, line) end
    end
end
