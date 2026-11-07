local _, ns = ...
local C = {}
ns.Compatibility = C

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
    if version == "1.60.1" and build == "70790" and interface == 16001 then
        result.status = "FOREVER_CANDIDATE_UNVERIFIED"
    else result.status = "UNSUPPORTED_BUILD" end
    result.reason = "NO_LIVE_VALIDATED_WRITE_SIGNATURES"
    return result
end
