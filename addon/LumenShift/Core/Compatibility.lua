local _, ns = ...
local C = {}
ns.Compatibility = C
-- Version/interface contract for explicit development controls, not native QA certification.
-- Hotfix numbers are recorded, not individually unlocked. See docs/27.
local policy = { version = "1.60.1", interface = 16001, minimumBuild = 70790 }
local observed = {
    ["1.60.1:70790:16001"] = true,
    ["1.60.1:70840:16001"] = true,
    ["1.60.1:70862:16001"] = true,
}
function C.Experimental(signature)
    if type(signature) ~= "string" then return false end
    local version, build, interface = signature:match("^(%d+%.%d+%.%d+):(%d+):(%d+)$")
    local number = build and tonumber(build)
    return version == policy.version and interface == tostring(policy.interface)
        and ns.Value.Finite(number) and tostring(number) == build and number >= policy.minimumBuild
end
function C.Policy() return ns.Value.Copy(policy) end
function C.ObservedSignatures() return ns.Value.Keys(observed) end
function C.Explain(identity)
    if not identity.signature then return "The game version could not be read. Open Diagnostics for details." end
    if C.Experimental(identity.signature) then
        return "Forever " .. identity.version .. " / interface " .. identity.interface .. " supported; hotfix build " .. identity.build .. " recorded."
    end
    return "This client is outside the supported Forever " .. policy.version .. " / interface " .. policy.interface .. " family. Preferences can still be saved."
end

function C.Inspect(reader)
    local result = { status = "IDENTITY_UNAVAILABLE", futureWrites = false,
        renderer = "UNVERIFIED", liveVerified = false }
    local values, code = ns.ReadOnly.Call(reader, reader.env.GetBuildInfo)
    if not values then result.reason = code; return result end
    local version, build, date, interface = values[1], values[2], values[3], values[4]
    if not ns.Value.Raw(version) or not ns.Value.Raw(build) or not ns.Value.Raw(date)
        or not ns.Value.Finite(interface) or interface % 1 ~= 0 then
        result.reason = "UNEXPECTED_BUILD_INFO"; return result
    end
    result.version, result.build, result.date, result.interface = version, build, date, interface
    result.signature = version .. ":" .. build .. ":" .. tostring(interface)
    result.status = C.Experimental(result.signature) and "FOREVER_SUPPORTED_FAMILY" or "UNSUPPORTED_BUILD"
    result.observedIdentity = observed[result.signature] == true
    result.reason = "OPERATIONS_REQUIRE_CURRENT_CAPABILITIES_AND_READBACK"
    return result
end
