local _, ns = ...
local C = {}
ns.Compatibility = C
-- Reference identities describe evidence, not a lock on user controls. See docs/28.
local policy = { version = "1.60.1", interface = 16001, minimumBuild = 70790, mismatchAction = "warn" }
local observed = {
    ["1.60.1:70790:16001"] = true,
    ["1.60.1:70840:16001"] = true,
    ["1.60.1:70862:16001"] = true,
}
function C.Experimental(signature)
    if type(signature) ~= "string" then return false end
    local version, build, interface = signature:match("^(%d+%.%d+%.%d+):(%d+):(%d+)$")
    local number, ui = build and tonumber(build), interface and tonumber(interface)
    return version ~= nil and ns.Value.Finite(number) and tostring(number) == build and number > 0
        and ns.Value.Finite(ui) and tostring(ui) == interface and ui > 0
end
function C.Policy() return ns.Value.Copy(policy) end
function C.ObservedSignatures() return ns.Value.Keys(observed) end
function C.Explain(identity)
    if not C.Experimental(identity.signature) then return "The game identity could not be read. Open Diagnostics for details." end
    if identity.warning then
        return "This game version (" .. identity.signature .. ") has not been reviewed for LumenShift. Controls remain available; report any problems."
    end
    return "Known client identity " .. identity.signature .. "; controls check current game capabilities."
end
function C.WarnOnce(runtime)
    if runtime.compatibilityWarned then return end
    local identity = C.Inspect(runtime.reader)
    if not identity.warning then return end
    runtime.compatibilityWarned = true
    ns.Log.Record(runtime.reader, "compatibility", "version", "WARN", "UNREVIEWED_CLIENT_WARNING", { detail = identity.signature })
    ns.Diagnostics.Emit(runtime, "LumenShift: " .. C.Explain(identity))
end
function C.Inspect(reader)
    local result = { status = "IDENTITY_UNAVAILABLE", futureWrites = false,
        renderer = "UNVERIFIED", liveVerified = false, warning = false }
    local values, code = ns.ReadOnly.Call(reader, reader.env.GetBuildInfo)
    if not values then result.reason = code; return result end
    local version, build, date, interface = values[1], values[2], values[3], values[4]
    if not ns.Value.Raw(version) or not ns.Value.Raw(build) or not ns.Value.Raw(date)
        or not ns.Value.Finite(interface) or interface % 1 ~= 0 then
        result.reason = "UNEXPECTED_BUILD_INFO"; return result
    end
    result.version, result.build, result.date, result.interface = version, build, date, interface
    local signature = version .. ":" .. build .. ":" .. tostring(interface)
    if not C.Experimental(signature) then result.reason = "MALFORMED_CLIENT_IDENTITY"; return result end
    result.signature = signature
    result.observedIdentity = observed[signature] == true
    result.warning = not result.observedIdentity
    result.status = result.warning and "UNREVIEWED_CLIENT_WARNING" or "OBSERVED_CLIENT_IDENTITY"
    result.reason = "VERSION_MISMATCH_WARNS_CAPABILITIES_CHECKED_PER_OPERATION"
    return result
end
