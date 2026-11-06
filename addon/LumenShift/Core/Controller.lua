local _, ns = ...
local C = {}
ns.Controller = C
local transitions = {
    BASELINE = { preview = "PREVIEW" }, ACTIVE = { preview = "PREVIEW", drift = "CONFLICT", release = "RESTORING" },
    PREVIEW = { simulate = "APPLYING", defer = "DEFERRED" },
    APPLYING = { verified = "ACTIVE", failure = "ROLLING_BACK", defer = "ROLLING_BACK" },
    ROLLING_BACK = { partial = "PARTIAL_ERROR", recovered = "BASELINE" },
    PARTIAL_ERROR = { recover = "RECOVERY" }, CONFLICT = { recover = "RECOVERY" },
    RECOVERY = { preview = "PREVIEW" }, DEFERRED = { preview = "PREVIEW" },
    RESTORING = { verified = "BASELINE", verifiedOtherLayer = "ACTIVE", failure = "ROLLING_BACK", drift = "CONFLICT" },
}
function C.New(state)
    return { state = state or "INSPECTING", token = 0, observationsPending = false }
end
-- Pure state model. 'simulate' has no runtime caller or action executor.
function C.Reduce(model, event, token)
    if token ~= model.token then return nil, "STALE_TOKEN" end
    local result = ns.Value.Copy(model)
    if not result then return nil, "MODEL_LIMIT" end
    if event == "observation" then
        result.observationsPending = true -- coalesce notifications; ignore event payloads
        return result
    end
    if event == "cancel" then
        if model.state == "APPLYING" or model.state == "ROLLING_BACK" or model.state == "RESTORING" then return nil, "BUSY" end
        result.state, result.token = "INSPECTING", model.token + 1
        return result
    end
    local nextState = transitions[model.state] and transitions[model.state][event]
    if not nextState then return nil, "INVALID_TRANSITION" end
    result.state = nextState
    if event == "preview" then
        result.token = result.token + 1
        if model.state == "BASELINE" or model.state == "ACTIVE" then result.previousState = model.state end
    end
    if event == "recovered" then result.state = model.previousState or "RECOVERY" end
    if event == "release" then result.previousState, result.token = model.state, result.token + 1 end
    return result
end
function C.Apply()
    return ns.WriteBoundary.Request()
end

function C.Command(runtime, message)
    local command = type(message) == "string" and message:match("^%s*(.-)%s*$") or ""
    if command == "studio" or command == "wheel" then
        if runtime.ui and runtime.ui.Open then
            if command == "wheel" then runtime.ui.Wheel() else runtime.ui.Open() end
        else ns.Diagnostics.Emit(runtime, "LumenShift: native UI unavailable; /ls still provides diagnostics.") end
        return
    end
    if command == "toggle" and runtime.product then runtime.product.Toggle(); return end
    local selected = command:match("^mode (%a+)$")
    if selected and runtime.product then
        if selected:lower() == "nightvision" then selected = "nightVision" else selected = selected:lower() end
        runtime.product.Select(selected); return
    end
    if command == "" or command == "status" or command == "help" then ns.Diagnostics.Show(runtime); return end
    if not runtime.engine then ns.Diagnostics.Emit(runtime, "LumenShift: engine unavailable; no writes enabled."); return end
    local token = command:match("^confirm (%d+)$")
    if token then runtime.engine.Confirm(token)
    elseif command == "on" or command == "off" or command == "restore" then runtime.engine.Prepare(command)
    elseif command == "verify" then runtime.engine.Verify()
    elseif command == "cancel" then
        local ok = runtime.engine.Cancel()
        ns.Diagnostics.Emit(runtime, ok and "LumenShift: preview cancelled; no automatic restore. Inspect /ls for recovery status."
            or "LumenShift: operation busy; cancel was refused.")
    else ns.Diagnostics.Emit(runtime, "LumenShift: unknown command; use /ls help. No write performed.") end
    if runtime.product then runtime.product.Observe() end
end
