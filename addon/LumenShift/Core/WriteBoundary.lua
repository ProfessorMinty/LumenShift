local _, ns = ...
-- The only future graphics-writing boundary. There is deliberately no writer,
-- injected setter, enable flag or native call here in Phase 01A.
ns.WriteBoundary = {}
function ns.WriteBoundary.Request()
    return nil, "PHASE_01A_READ_ONLY"
end
