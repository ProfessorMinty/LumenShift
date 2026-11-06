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
