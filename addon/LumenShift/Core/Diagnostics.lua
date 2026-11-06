local _, ns = ...
local D = {}
ns.Diagnostics = D
local function bool(value) return value and "yes" or "no" end

function D.Lines(runtime)
    local reader = runtime.reader
    local identity = ns.Compatibility.Inspect(reader)
    local caps = ns.ReadOnly.Capabilities(reader)
    local observed = {}
    local status = runtime.engine and runtime.engine.Status()
    local lines = { "LumenShift " .. ns.version .. " | Brightness test engine; writes locked until explicit confirmation",
        "Client: " .. (identity.version or "unknown") .. " build " .. (identity.build or "unknown")
            .. " interface " .. tostring(identity.interface or "unknown"),
        "Compatibility: " .. identity.status .. "; renderer UNVERIFIED; production write admission unavailable",
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
    lines[#lines + 1] = "State: " .. (status and status.state or recovery and recovery.state or "RECOVERY")
        .. "; saved selection is metadata, never an active preset"
    if status then
        lines[#lines + 1] = "Native Brightness writer API: " .. (status.setterAvailable and "available" or "unavailable")
            .. "; only a confirmed test can call it"
        lines[#lines + 1] = "Brightness original: " .. (status.original or "not captured")
            .. "; last verified: " .. (status.lastVerified or "none") .. "; operation: " .. status.operation
        lines[#lines + 1] = "Preview confirmation: " .. (status.token or "none") .. "; startup/reload never enables writes"
        if status.error then lines[#lines + 1] = "Engine status: " .. status.error end
    end
    if recovery then
        local count = 0
        for _ in pairs(recovery.entries) do count = count + 1 end
        lines[#lines + 1] = "Recovery records: " .. count .. "; matching values do not prove ownership"
        for _, key in ipairs(ns.Catalog.Keys()) do
            if recovery.entries[key] then lines[#lines + 1] = key .. " recovery: " .. recovery.entries[key] end
        end
    else lines[#lines + 1] = "Recovery: saved data preserved in place; schema quarantined" end
    lines[#lines + 1] = "Commands: /ls on | off | restore (read-only previews); /ls confirm TOKEN; /ls verify; /ls cancel"
    lines[#lines + 1] = "Restore My Brightness: /ls restore. Save the displayed recovery card before confirming a live-approved test."
    lines[#lines + 1] = "Unverified: native writes, settling, persistence and restoration. Contrast and quality controls remain read-only."
    if runtime.lastError then lines[#lines + 1] = "Last error: " .. runtime.lastError end
    return lines
end

function D.Emit(runtime, line)
    local chat = runtime.reader.env.DEFAULT_CHAT_FRAME
    if not chat or type(chat.AddMessage) ~= "function" then return false end
    return pcall(chat.AddMessage, chat, line)
end

function D.Show(runtime)
    local ok, lines = pcall(D.Lines, runtime)
    if not ok then
        runtime.lastError = "DIAGNOSTIC_ERROR"
        lines = { "LumenShift: diagnostic read failed; this report made no graphics writes. Preserve any recovery card." }
    end
    for _, line in ipairs(lines) do D.Emit(runtime, line) end
end
