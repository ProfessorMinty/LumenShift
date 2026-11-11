local _, ns = ...
local P, V = {}, ns.Value; ns.PortraitConfig = P
P.BankLimit = 8
P.Animations = ns.PortraitLibrary.Poses
P.Backgrounds = { { "world", "World" }, { "charcoal", "Charcoal" }, { "gray", "Gray" }, { "green", "Chroma green" }, { "blue", "Chroma blue" } }
P.Colors = { charcoal = { .025, .03, .04 }, gray = { .35, .35, .35 }, green = { 0, 1, 0 }, blue = { 0, 0, 1 } }
P.ActorRanges = { x = { -3, 3 }, y = { -2, 3 }, depth = { -2, 2 }, yaw = { -180, 180 }, pitch = { -45, 45 },
    roll = { -45, 45 }, scale = { .25, 3 }, time = { 0, 10 }, speed = { .1, 2 } }
P.LightRanges = { azimuth = { -180, 180 }, elevation = { -80, 80 }, ambient = { 0, 1 }, diffuse = { 0, 2 },
    red = { 0, 1 }, green = { 0, 1 }, blue = { 0, 1 } }
local function ranges(value, allowed)
    for key, range in pairs(allowed) do if not V.Finite(value[key]) or value[key] < range[1] or value[key] > range[2] then return false end end
    return true
end
function P.Actor(unit)
    return { unit = unit or "player", x = 0, y = 0, depth = 0, yaw = 0, pitch = 0, roll = 0, scale = 1,
        animation = 0, variation = 0, spellKit = 0, outfit = {}, time = 0, speed = 1, paused = true, sheathed = true, hideWeapons = false, transmog = true, hideHead = false, hideCloak = false }
end
function P.Light() return { azimuth = -35, elevation = 30, ambient = .55, diffuse = .85, red = 1, green = 1, blue = 1 } end
function P.LightPreset(id)
    local l = P.Light()
    if id == "soft" then l.ambient, l.diffuse = .8, .4
    elseif id == "ember" then l.azimuth, l.elevation, l.ambient, l.diffuse, l.green, l.blue = -55, 5, .25, 1.4, .55, .22
    elseif id == "moon" then l.azimuth, l.elevation, l.ambient, l.diffuse, l.red, l.green = 80, 40, .25, 1.2, .45, .7
    elseif id ~= "neutral" then return nil end
    return l
end
P.CameraRanges = { distance = { 3, 12 }, height = { -1, 4 }, fov = { 20, 70 },
    yaw = { -180, 180 }, pitch = { -80, 80 }, roll = { -90, 90 } }
function P.Scene()
    return { version = 4, actors = { P.Actor() }, light = P.Light(), background = "charcoal",
        distance = 6, height = 1.1, fov = 35, yaw = 0, pitch = 0, roll = 0 }
end
function P.Defaults() return { version = 4, scene = P.Scene(), saved = {}, lights = {}, outfits = {} } end
function P.ValidActor(a)
    local fields = { unit = true, animation = true, variation = true, spellKit = true, outfit = true, paused = true, sheathed = true, hideWeapons = true, transmog = true, hideHead = true, hideCloak = true }
    for k in pairs(P.ActorRanges) do fields[k] = true end
    if not V.Fields(a, fields) or not ranges(a, P.ActorRanges) or not ({ player = true, target = true, pet = true })[a.unit] then return false end
    for _, key in ipairs({ "paused", "sheathed", "hideWeapons", "transmog", "hideHead", "hideCloak" }) do if type(a[key]) ~= "boolean" then return false end end
    if not V.Finite(a.variation) or a.variation % 1 ~= 0 or a.variation < 0 or a.variation > 5
        or not ns.PortraitLibrary.Kit(a.spellKit) or not P.ValidOutfit(a.outfit) then return false end
    for _, anim in ipairs(P.Animations) do if a.animation == anim[1] then return true end end
    return false
end
function P.ValidLight(l) return V.Fields(l, P.LightRanges) and ranges(l, P.LightRanges) end
function P.ValidScene(s)
    if not V.Fields(s, { version = true, actors = true, light = true, background = true, distance = true, height = true,
        fov = true, yaw = true, pitch = true, roll = true })
        or s.version ~= 4 or not P.ValidLight(s.light) or type(s.actors) ~= "table"
        or not ranges(s, P.CameraRanges) then return false end
    if s.background ~= "world" and not P.Colors[s.background] then return false end
    for slot, a in pairs(s.actors) do if not V.Finite(slot) or slot % 1 ~= 0 or slot < 1 or slot > 3 or not P.ValidActor(a) then return false end end
    return true
end
function P.Name(name) return type(name) == "string" and #name > 0 and #name <= 32 and name:find("%S") and not name:find("[%c|]") end
local function bank(data, validate)
    if type(data) ~= "table" then return false end
    local n = 0
    for name, value in pairs(data) do n = n + 1; if n > P.BankLimit or not P.Name(name) or not validate(value) then return false end end
    return true
end
function P.Validate(p)
    return V.Fields(p, { version = true, scene = true, saved = true, lights = true, outfits = true }) and p.version == 4
        and P.ValidScene(p.scene) and bank(p.saved, P.ValidScene) and bank(p.lights, P.ValidLight) and bank(p.outfits, P.ValidOutfit)
end
function P.Save(bankValue, name, value, validator)
    if not P.Name(name) or not validator(value) then return nil, "Invalid scene or name (1-32 characters)." end
    if not bankValue[name] and #V.Keys(bankValue) >= P.BankLimit then return nil, "Eight saved entries maximum. Delete one first." end
    local copy = V.Copy(value); if not copy then return nil, "Invalid scene data." end
    bankValue[name] = copy; return true
end

function P.ValidOutfit(outfit)
    if type(outfit) ~= "table" then return false end
    for slot,id in pairs(outfit) do
        if not ns.PortraitLibrary.Slot(slot) then return false end
        if type(id)=="table" then
            if not V.Fields(id,{sourceID=true}) or not V.Finite(id.sourceID) or id.sourceID%1~=0 or id.sourceID<=0 or id.sourceID>9999999 then return false end
        elseif not V.Finite(id) or id%1~=0 or id<0 or id>9999999 then return false end
    end
    return true
end
function P.Worn(value) return type(value)=="table" or type(value)=="number" and value>0 end
function P.Upgrade(data)
    if type(data)~="table" or data.version~=1 and data.version~=2 and data.version~=3 then return end
    local function scene(s)
        if type(s)~="table" or s.version~=1 and s.version~=2 and s.version~=3 then return end
        if s.version < 3 then
            for _, actor in pairs(type(s.actors) == "table" and s.actors or {}) do
                if type(actor) == "table" then
                    if actor.variation == nil then actor.variation = 0 end
                    if actor.spellKit == nil then actor.spellKit = 0 end
                    if actor.outfit == nil then actor.outfit = {} end
                end
            end
        end
        s.yaw, s.pitch, s.roll = 0, 0, 0
        s.version=4
    end
    scene(data.scene); for _,s in pairs(type(data.saved)=="table" and data.saved or {}) do scene(s) end
    if data.outfits==nil and data.version < 3 then data.outfits={} end
    data.version=4
end
