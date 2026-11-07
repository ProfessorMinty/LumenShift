local _, ns = ...
local C = {}
ns.Compatibility = C
-- Exact experimental identities, not production admission. Evidence: docs/25.
-- Never infer that a new patch/build shares native behavior with these clients.
local experimental = {
    ["1.60.1:70790:16001"] = true,
    ["1.60.1:70840:16001"] = true,
}
function C.Experimental(signature) return experimental[signature] == true end
function C.ExperimentalSignatures() return ns.Value.Keys(experimental) end
function C.Explain(identity)
    if not identity.signature then return "The game build could not be read. Visual switching is unavailable." end
    if C.Experimental(identity.signature) then
        return "Build " .. identity.build .. " / interface " .. identity.interface .. ": available for development testing."
    end
    return "Build " .. identity.build .. " / interface " .. identity.interface
        .. " has not been reviewed. Visual switching is unavailable; you can still finish read-only setup."
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
    if C.Experimental(result.signature) then
        result.status = "FOREVER_CANDIDATE_UNVERIFIED"
    else result.status = "UNSUPPORTED_BUILD" end
    result.reason = "NO_LIVE_VALIDATED_WRITE_SIGNATURES"
    return result
end
