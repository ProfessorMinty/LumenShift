local _, ns = ...
local N, V = {}, ns.Value
ns.NamePolicy = N
N.Keys = { "UnitNameFriendlyPlayerName", "UnitNameFriendlyPetName" }
N.Version = 4
N.Groups = {
    { id = "players", label = "Hide player names", keys = { "UnitNameOwn", "UnitNameFriendlyPlayerName", "UnitNameEnemyPlayerName" } },
    { id = "pets", label = "Hide pet / minion names", keys = { "UnitNameFriendlyPetName", "UnitNameEnemyPetName", "UnitNameFriendlyMinionName", "UnitNameEnemyMinionName", "UnitNameFriendlyGuardianName", "UnitNameEnemyGuardianName", "UnitNameFriendlyTotemName", "UnitNameEnemyTotemName" } },
    { id = "npcs", label = "Hide NPC / quest-giver names", keys = { "UnitNameNPC", "UnitNameFriendlySpecialNPCName", "UnitNameInteractiveNPC", "UnitNameHostleNPC", "UnitNameNonCombatCreatureName" } },
    -- Registered in the Forever 70532 capture; visible behavior still needs native acceptance.
    { id = "focused", label = "Hide focused-unit names", keys = { "UnitNameFocused" } },
    { id = "bubbles", label = "Hide chat bubbles", keys = { "chatBubbles", "chatBubblesParty", "chatBubblesRaid" } },
}
N.AllKeys = {}
local known = {}
for _, group in ipairs(N.Groups) do for _, key in ipairs(group.keys) do
    if not known[key] then N.AllKeys[#N.AllKeys + 1], known[key] = key, true end
end end
function N.Known(key) return known[key] == true end
function N.Targets(reader, data)
    local wanted, targets, unavailable = {}, {}, {}
    if data.hideWithUI then for _, key in ipairs(N.Keys) do wanted[key] = true end end
    for _, group in ipairs(N.Groups) do if data.nameGroups[group.id] then
        for _, key in ipairs(group.keys) do wanted[key] = true end
    end end
    for _, key in ipairs(V.Keys(wanted)) do
        local seen = ns.ReadOnly.Read(reader, key)
        if ns.Planner.SafeObservation(seen, key) and N.Bounds(key, seen.raw) then targets[key] = 0
        else unavailable[#unavailable + 1] = key end
    end
    return targets, unavailable
end
function N.UpgradeTools(data)
    if data.keepInCombat == nil then data.keepInCombat = true end
    if data.effectsInCombat == nil then data.effectsInCombat = true end
    if data.portrait == nil then data.portrait = ns.PortraitConfig.Defaults() end
    if data.output == nil then data.output = ns.PhotoOutput.Defaults() end
    if data.composition == nil then data.composition = ns.PhotoComposition.Defaults() end
    if data.tools == nil then data.tools = ns.PhotoTools.Defaults() end
    if data.nameGroups == nil then data.nameGroups = { players = false, pets = false, npcs = false, focused = false, bubbles = false } end
end
function N.Layer() return "camera" end
function N.Bounds(key, original)
    local value = V.Number(original)
    if not N.Known(key) or (value ~= 0 and value ~= 1) then return nil, "INVALID_NAME_TOGGLE_VALUE" end
    return { min = 0, max = 1, step = 1, basis = "source-boolean-native-checked" }
end
function N.Context(signature) return { signature = signature, testOnly = true, experiment = "CAMERA_NAMES" } end
function N.Descriptor(key, bounds, signature)
    if not N.Known(key) or not ns.Compatibility.Experimental(signature) then return nil end
    return { name = key, layer = "camera", kind = "number", version = N.Version, testOnly = true, admitted = false,
        evidence = "SOURCE_BOOLEAN_NATIVE_CHECKED", signature = signature, scope = "photo_names", min = 0, max = 1,
        settle = "scheduled_readback_test", numericEquivalent = true, dependencies = {}, conflicts = {} }
end
function N.ValidateTargets(targets, layer)
    if type(targets) ~= "table" or layer ~= "camera" then return false end
    for key, value in pairs(targets) do if not N.Known(key) or (value ~= 0 and value ~= 1) then return false end end
    return true
end
function N.Upgrade(data)
    local defaults = { thirds = false, aspect = "none", photoEnabled = false, photoLevel = 7,
        framing = ns.Framing.Defaults(), photo = ns.NativeGraphics.Defaults(), editor = ns.PhotoConfig.Defaults() }
    for key, value in pairs(defaults) do if data[key] == nil then data[key] = value end end
    N.UpgradeTools(data)
end
function N.Defaults()
    local data = { journal = ns.Store.EmptyJournal(), sideEffects = {}, hideWithUI = true, keepEffects = true }
    N.Upgrade(data); return data
end
function N.Validate(data)
    if not V.Fields(data, { journal = true, sideEffects = true, hideWithUI = true, keepEffects = true, thirds = true, aspect = true, photoEnabled = true, photoLevel = true, framing = true, photo = true, nameReturn = true, editor = true, tools = true, nameGroups = true, output = true, composition = true, portrait = true, keepInCombat = true, effectsInCombat = true })
        or not ns.Store.ValidateJournal(data.journal) or type(data.sideEffects) ~= "table"
        or type(data.hideWithUI) ~= "boolean" or type(data.keepEffects) ~= "boolean" then return false end
    if type(data.keepInCombat) ~= "boolean" or type(data.effectsInCombat) ~= "boolean" then return false end
    if type(data.thirds) ~= "boolean" or not ({ none = true, wide = true, cinema = true, square = true })[data.aspect]
        or type(data.photoEnabled) ~= "boolean" or not V.Finite(data.photoLevel) or data.photoLevel % 1 ~= 0
        or data.photoLevel < 1 or data.photoLevel > 10 or not ns.Framing.Validate(data.framing)
        or not ns.NativeGraphics.Validate(data.photo) or not ns.PhotoConfig.Validate(data.editor) then return false end
    if not ns.PortraitConfig.Validate(data.portrait) or not ns.PhotoOutput.Validate(data.output) or not ns.PhotoComposition.Validate(data.composition) or not ns.PhotoTools.Validate(data.tools) or not V.Fields(data.nameGroups, { players = true, pets = true, npcs = true, focused = true, bubbles = true }) then return false end
    for _, group in ipairs(N.Groups) do if type(data.nameGroups[group.id]) ~= "boolean" then return false end end
    if data.nameReturn ~= nil and (not V.Fields(data.nameReturn, { targets = true })
        or not N.ValidateTargets(data.nameReturn.targets, "camera")) then return false end
    for key, record in pairs(data.journal.entries) do
        if not N.Known(key) or record.layer ~= "camera" or record.descriptorVersion ~= N.Version then return false end
    end
    for key, item in pairs(data.sideEffects) do
        if not N.Known(key) or not V.Fields(item, { before = true, after = true })
            or not V.Number(item.before) or not V.Number(item.after) then return false end
    end
    return true
end
