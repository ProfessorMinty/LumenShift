local _, ns = ...
local S, W, C = {}, ns.Widgets, ns.PortraitConfig
ns.StageSavedUI = S

local backgrounds = {}
for _, item in ipairs(C.Backgrounds) do backgrounds[item[1]] = item[2] end
local unitColors = {player=W.colors.accent, target=W.colors.text, pet=W.colors.warning}
local function fraction(value, range)
    return (value-range[1])/(range[2]-range[1])
end

local function initScene(row)
    local center=W.Texture(row,"ARTWORK"); center:SetSize(1,34)
    center:SetPoint("CENTER",row.picture,"CENTER"); center:SetColorTexture(1,1,1,.15)
    local floor=W.Texture(row,"ARTWORK"); floor:SetSize(60,1)
    floor:SetPoint("TOPLEFT",row.picture,"TOPLEFT",0,-(5+24*(1-fraction(0,C.ActorRanges.y))))
    floor:SetColorTexture(1,1,1,.15)
    row.cast = {}
    for slot=1,3 do
        local edge = W.Texture(row,"ARTWORK")
        local dot = W.Texture(row,"OVERLAY")
        for _,t in ipairs({edge,dot}) do W.Asset(t,"Interface/AddOns/LumenShift/Media/switch-knob.tga") end
        edge:SetVertexColor(.07,.08,.1)
        row.cast[slot] = {edge=edge, dot=dot}
    end
end

-- A front-view plot of occupied slots, independent of the live camera and unit identities.
local function sceneCard(row, scene)
    local color = C.Colors[scene.background]
    if color then row.picture:SetColorTexture(color[1],color[2],color[3],1)
    else W.Asset(row.picture,"Interface/AddOns/LumenShift/Media/look-neutral.tga") end
    local cast = {}
    for slot=1,3 do
        local actor, marker = scene.actors[slot], row.cast[slot]
        if actor then
            cast[#cast+1] = slot.." "..actor.unit
            local x = 6+48*fraction(actor.x,C.ActorRanges.x)
            local y = 5+24*(1-fraction(actor.y,C.ActorRanges.y))
            local size = math.min(9,4+2*actor.scale)
            marker.edge:ClearAllPoints(); marker.edge:SetPoint("CENTER",row.picture,"TOPLEFT",x,-y)
            marker.edge:SetSize(size+2,size+2); marker.edge:Show()
            marker.dot:ClearAllPoints(); marker.dot:SetPoint("CENTER",marker.edge,"CENTER")
            marker.dot:SetSize(size,size); marker.dot:SetVertexColor(unpack(unitColors[actor.unit])); marker.dot:Show()
        else marker.edge:Hide(); marker.dot:Hide() end
    end
    local detail=string.format("%d %s · %s · %g° FOV",#cast,#cast==1 and "actor" or "actors",backgrounds[scene.background],scene.fov)
    return detail, #cast>0 and (detail.."\nSlots · "..table.concat(cast,", ")) or detail
end

local function initLight(row)
    row.fillSphere = W.Texture(row,"ARTWORK")
    W.Asset(row.fillSphere,"Interface/AddOns/LumenShift/Media/switch-knob.tga")
    row.fillSphere:SetSize(26,26); row.fillSphere:SetPoint("CENTER",row.picture,"CENTER")
    row.keyLight = W.Texture(row,"OVERLAY")
    W.Asset(row.keyLight,"Interface/AddOns/LumenShift/Media/photo-glow-5.tga")
end

local function lightCard(row, light)
    local fill = .10+.55*light.ambient
    row.picture:SetColorTexture(.08,.10,.12,1)
    row.fillSphere:SetVertexColor(fill,fill,fill)
    local az,el=math.rad(light.azimuth),math.rad(light.elevation)
    local x, y=8*math.sin(az)*math.cos(el),8*math.sin(el)
    local glow = row.keyLight
    glow:ClearAllPoints(); glow:SetPoint("CENTER",row.fillSphere,"CENTER",x,y)
    glow:SetSize(15,15); glow:SetVertexColor(light.red,light.green,light.blue)
    glow:SetAlpha(math.min(1,light.diffuse)*(.65+.35*math.cos(az)*math.cos(el))); glow:Show()
    local detail=string.format("Key %.2g · Fill %.2g · Az %.0f° · El %.0f°",light.diffuse,light.ambient,light.azimuth,light.elevation)
    return detail, string.format("Key %.2g · Fill %.2g\nAzimuth %g° · Elevation %g°",light.diffuse,light.ambient,light.azimuth,light.elevation)
end

function S.Build(runtime, env, parent, ui)
    local stage, data = runtime.portrait, runtime.db.camera.portrait
    local lights = ui.stageSavePage=="Lights"
    local lib = {
        unit = lights and "lighting setup" or "scene",
        description = lights and "Stage light direction, color, key and fill." or "Cast, poses, outfits, stage camera, light and backdrop.",
        bank = lights and data.lights or data.saved, limit=C.BankLimit, validName=C.Name, worker=stage,
        initCard = lights and initLight or initScene, card = lights and lightCard or sceneCard,
        savedMessage = lights and "Lighting setup saved." or "Scene saved.",
        deletedMessage = lights and "Lighting setup deleted." or "Scene deleted.",
    }
    function lib.save(name) return stage.Save(name,lights) end
    function lib.delete(name) return stage.Delete(name,lights) end
    function lib.apply(name)
        local ok, why = stage.Load(name,lights)
        if not ok then return why or "Stage setup could not be applied." end
        if lights then return "Lighting setup applied." end
        return nil, stage.sceneLoad
    end
    function lib.progress(result)
        if result==stage.sceneLoad then return result.status end
    end
    return ns.SavedLibraryUI.Build(runtime,env,parent,ui,ui.stageSavePage,lib)
end
