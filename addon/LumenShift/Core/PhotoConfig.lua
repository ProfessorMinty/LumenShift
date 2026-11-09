local _, ns = ...
local P, V = {}, ns.Value
ns.PhotoConfig = P
-- All look values are normalized screen treatments, independent of visual modes.
P.Ranges = { strength = { 0, 1 }, warmth = { -1, 1 }, tint = { -1, 1 },
    vignette = { 0, 1 }, size = { 0.25, 1.5 }, feather = { 0.05, 1 },
    centerX = { 0, 1 }, centerY = { 0, 1 }, grain = { 0, 0.35 }, grainScale = { 1, 8 },
    glow = { 0, 1 }, glowSize = { 0.05, 1 }, glowSoftness = { 0.05, 1 },
    glowX = { 0, 1 }, glowY = { 0, 1 }, glowR = { 0, 1 }, glowG = { 0, 1 }, glowB = { 0, 1 },
    letterbox = { 0, 0.3 } }
P.Order = { "strength", "warmth", "tint", "vignette", "size", "feather", "centerX", "centerY", "grain", "grainScale",
    "glow", "glowSize", "glowSoftness", "glowX", "glowY", "glowR", "glowG", "glowB", "letterbox" }
function P.Neutral()
    return { strength = 1, warmth = 0, tint = 0, vignette = 0, size = 0.85, feather = 0.65,
        centerX = 0.5, centerY = 0.5, grain = 0, grainScale = 2, glow = 0, glowSize = 0.35,
        glowSoftness = 0.8, glowX = 0.5, glowY = 0.5, glowR = 1, glowG = 0.58, glowB = 0.2, letterbox = 0 }
end
function P.Recipe(id)
    local look = P.Neutral()
    if id == "ember" then look.warmth, look.vignette, look.grain = 0.55, 0.35, 0.035
    elseif id == "night" then look.warmth, look.tint, look.vignette = -0.5, 0.1, 0.4
    elseif id == "portrait" then look.warmth, look.tint, look.vignette, look.size = 0.2, 0.15, 0.25, 1
    elseif id ~= "neutral" then return nil end
    return look
end
function P.ValidLook(look)
    if not V.Fields(look, P.Ranges) then return false end
    for key, range in pairs(P.Ranges) do
        if not V.Finite(look[key]) or look[key] < range[1] or look[key] > range[2] then return false end
    end
    return true
end
function P.Defaults() return { version = 1, look = P.Neutral(), saved = {} } end
function P.Validate(data)
    if not V.Fields(data, { version = true, look = true, saved = true, session = true })
        or data.version ~= 1 or not P.ValidLook(data.look) or type(data.saved) ~= "table" then return false end
    local count = 0
    for name, look in pairs(data.saved) do
        count = count + 1
        if count > 12 or not P.Name(name) or not P.ValidLook(look) then return false end
    end
    local s = data.session
    if s then
        if not V.Fields(s, { before = true, after = true, expected = true, state = true })
            or not ns.Optics.RawMap(s.before) or not ns.Optics.RawMap(s.after) or not ns.Optics.RawMap(s.expected)
            or not ({ after = true, before = true, pending = true, recovery = true })[s.state] then return false end
        for key in pairs(s.before) do if not s.after[key] or not s.expected[key] then return false end end
        for key in pairs(s.after) do if not s.before[key] then return false end end
        for key in pairs(s.expected) do if not s.before[key] then return false end end
    end
    return true
end
function P.Name(name) return type(name) == "string" and #name > 0 and #name <= 32 and not name:find("[%c|]") and name:find("%S") ~= nil end
function P.Export(look)
    if not P.ValidLook(look) then return nil end
    local parts = { "LSPHOTO1" }
    for _, key in ipairs(P.Order) do parts[#parts + 1] = string.format("%.4f", look[key]) end
    return table.concat(parts, ";")
end
function P.Import(text)
    if type(text) ~= "string" or #text > 512 then return nil end
    local parts = {}; for part in (text .. ";"):gmatch("([^;]*);") do parts[#parts + 1] = part end
    if parts[1] ~= "LSPHOTO1" or #parts ~= #P.Order + 1 then return nil end
    local look = {}
    for i, key in ipairs(P.Order) do look[key] = tonumber(parts[i + 1]) end
    return P.ValidLook(look) and look or nil
end
