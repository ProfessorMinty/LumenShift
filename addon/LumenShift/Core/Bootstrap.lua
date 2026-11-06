local addonName, ns = ...
local runtime = { reader = ns.ReadOnly.New(_G), storeStatus = "NOT_LOADED" }
ns.runtime = runtime
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if event ~= "ADDON_LOADED" or name ~= addonName or runtime.loaded then return end
    runtime.loaded = true
    -- Bind only after our SavedVariables have loaded. Invalid input remains untouched.
    local db, status = ns.Store.Open(LumenShiftDB)
    runtime.db, runtime.storeStatus = db, status
    if db then LumenShiftDB = db end
    runtime.identity = ns.Compatibility.Inspect(runtime.reader)
    runtime.controller = ns.Controller.New(db and not next(db.journal.entries) and "BASELINE" or "RECOVERY")
    SLASH_LUMENSHIFT1, SLASH_LUMENSHIFT2 = "/lumenshift", "/ls"
    SlashCmdList.LUMENSHIFT = function() ns.Diagnostics.Show(runtime) end
    self:UnregisterEvent("ADDON_LOADED")
end)
