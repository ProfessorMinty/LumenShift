local _, ns = ...
local L = {}; ns.PortraitLibrary = L
-- Native animation/visual identifiers only; original grouping and labels. Sources: docs/61.
L.Groups = { "Everyday", "Social", "Action", "Casting", "Movement" }
L.Poses = {
    {0,"Stand","Everyday"}, {97,"Sit","Everyday"}, {100,"Sleep","Everyday"}, {115,"Kneel","Everyday"},
    {50,"Loot","Everyday"}, {61,"Eat","Everyday"}, {62,"Work","Everyday"}, {134,"Fishing","Everyday"},
    {60,"Talk","Social"}, {64,"Exclaim","Social"}, {65,"Question","Social"}, {66,"Bow","Social"},
    {67,"Wave","Social"}, {68,"Cheer","Social"}, {69,"Dance","Social"}, {70,"Laugh","Social"},
    {74,"Roar","Social"}, {76,"Kiss","Social"}, {77,"Cry","Social"}, {78,"Chicken","Social"},
    {79,"Beg","Social"}, {80,"Applaud","Social"}, {82,"Flex","Social"}, {83,"Shy","Social"},
    {84,"Point","Social"}, {113,"Salute","Social"}, {185,"Yes","Social"}, {186,"No","Social"},
    {16,"Unarmed strike","Action"}, {17,"One-hand strike","Action"}, {18,"Two-hand strike","Action"},
    {25,"Unarmed ready","Action"}, {26,"One-hand ready","Action"}, {27,"Two-hand ready","Action"},
    {29,"Bow ready","Action"}, {48,"Rifle ready","Action"}, {55,"Battle roar","Action"}, {95,"Kick","Action"},
    {31,"Prepare spell","Casting"}, {32,"Cast spell","Casting"}, {33,"Area cast","Casting"},
    {51,"Directed spell ready","Casting"}, {52,"Omni spell ready","Casting"}, {53,"Directed cast","Casting"},
    {54,"Omni cast","Casting"}, {124,"Directed channel","Casting"}, {125,"Omni channel","Casting"},
    {4,"Walk","Movement"}, {5,"Run","Movement"}, {13,"Walk backwards","Movement"},
    {38,"Jump","Movement"}, {41,"Float","Movement"}, {42,"Swim","Movement"},
    {119,"Sneak","Movement"}, {120,"Stealth idle","Movement"}, {143,"Sprint","Movement"},
}
L.Kits = { {0,"No effect"},
    {16556,"Fire surge","Fire"}, {20503,"Fire trail","Fire"},
    {10650,"Frost sparkle","Frost"}, {16343,"Cold aura","Frost"},
    {41004,"Sunlight - left","Sunlight"}, {41005,"Sunlight - right","Sunlight"},
    {15611,"Shadow - right","Shadow"}, {10715,"Shadow - left","Shadow"},
    {10678,"Blue radiance","Arcane"}, {12556,"Teleport shimmer","Arcane"},
    {57874,"Arcane lightning","Arcane"}, {25890,"Fel orbs","Fel"} }
L.Slots = { {1,"Head"}, {3,"Shoulders"}, {4,"Shirt"}, {5,"Chest"}, {6,"Waist"}, {7,"Legs"},
    {8,"Feet"}, {9,"Wrists"}, {10,"Hands"}, {15,"Back"}, {16,"Main hand"}, {17,"Off hand"}, {18,"Ranged"}, {19,"Tabard"} }
L.EquipSlots = { INVTYPE_HEAD={1}, INVTYPE_SHOULDER={3}, INVTYPE_BODY={4}, INVTYPE_CHEST={5}, INVTYPE_ROBE={5},
    INVTYPE_WAIST={6}, INVTYPE_LEGS={7}, INVTYPE_FEET={8}, INVTYPE_WRIST={9}, INVTYPE_HAND={10}, INVTYPE_CLOAK={15},
    INVTYPE_WEAPON={16,17}, INVTYPE_2HWEAPON={16}, INVTYPE_WEAPONMAINHAND={16}, INVTYPE_WEAPONOFFHAND={17},
    INVTYPE_SHIELD={17}, INVTYPE_HOLDABLE={17}, INVTYPE_RANGED={18}, INVTYPE_RANGEDRIGHT={18}, INVTYPE_THROWN={18}, INVTYPE_TABARD={19} }
function L.Slot(id) for _,v in ipairs(L.Slots) do if v[1]==id then return v[2] end end end
function L.Pose(id) for _,v in ipairs(L.Poses) do if v[1]==id then return v end end end
function L.Kit(id) for _,v in ipairs(L.Kits) do if v[1]==id then return v end end end
function L.FindPoses(group, query)
    local result = {}; query = type(query)=="string" and query:lower():sub(1,40) or ""
    for _,p in ipairs(L.Poses) do
        if (not group or group=="All" or p[3]==group) and (query=="" or p[2]:lower():find(query,1,true)) then result[#result+1]=p end
    end
    return result
end
