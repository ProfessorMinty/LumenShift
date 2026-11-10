local _, ns = ...
local B = {}; ns.PortraitBackend = B
-- Owned UI models only. No world camera, equipment, unit or graphics mutations.
function B.New(runtime)
    local reader, env = runtime.reader, runtime.reader.env
    local self = { models = {} }
    local function call(object, method, ...)
        local r = ns.ReadOnly.Call(reader, object and object[method], object, ...)
        return r ~= nil and r.n == 0, r
    end
    local function methods(object, names)
        if not object then return false end
        for _, name in ipairs(names) do if type(object[name]) ~= "function" then return false end end
        return true
    end
    local function create(kind, parent)
        local r = ns.ReadOnly.Call(reader, env.CreateFrame, kind, nil, parent)
        return r and r.n == 1 and r[1] or nil
    end
    function self.Build()
        if self.root then return true end
        local root = create("Frame", env.UIParent); if not root then return nil, "Portrait frames unavailable." end
        root:SetParent(nil); root:SetAllPoints(env.UIParent); root:SetFrameStrata("BACKGROUND"); root:SetFrameLevel(0); root:EnableMouse(false); root:Hide()
        self.root = root
        self.background = root:CreateTexture(nil, "BACKGROUND"); self.background:SetAllPoints(root)
        local scene = create("ModelScene", root)
        local sceneMethods = { "CreateActor", "SetCameraPosition", "SetCameraOrientationByYawPitchRoll", "SetCameraFieldOfView" }
        if methods(scene, sceneMethods) then
            scene:SetAllPoints(root); scene:SetFrameLevel(2); scene:EnableMouse(false)
            self.scene, self.kind = scene, "ModelScene"
            for i = 1, 6 do
                local r = ns.ReadOnly.Call(reader, scene.CreateActor, scene, "LumenShiftPortraitActor" .. i, "ModelSceneActorTemplate")
                local actor = r and r[1]
                if not methods(actor, { "SetModelByUnit", "IsLoaded", "ClearModel", "SetPosition", "SetYaw", "SetScale", "SetAnimation", "SetPaused", "Show", "Hide" }) then
                    self.kind = nil; break
                end
                self.models[i] = actor; actor:Hide()
            end
        end
        if not self.kind then
            if scene then scene:Hide() end
            for _, model in pairs(self.models) do call(model, "ClearModel"); call(model, "Hide") end
            self.models, self.scene = {}, nil
            for i = 1, 6 do
                local model = create("DressUpModel", root)
                if not methods(model, { "SetUnit", "GetModelFileID", "ClearModel", "SetPosition", "SetFacing", "SetModelScale", "SetAnimation", "SetPaused" }) then
                    self.Hide(); self.error = "Portrait model APIs unavailable on this client."; return nil, self.error
                end
                model:SetAllPoints(root); model:SetFrameLevel(2 + math.floor((i - 1) / 2)); model:EnableMouse(false); model:Hide()
                self.models[i] = model
            end
            self.kind = "DressUpModel"
        end
        return true
    end
    function self.Pause(model, value)
        if self.kind == "ModelScene" then return call(model, "SetPaused", value, false) end
        return call(model, "SetPaused", value)
    end
    function self.Clear(model)
        if not model then return end
        if self.Supports(model,"spellKit") then self.Spell(model,0) end
        self.Pause(model, true); call(model, "Hide"); call(model, "ClearModel")
    end
    function self.Hide()
        for _, model in pairs(self.models) do self.Clear(model) end
        if self.root then self.root:Hide() end
    end
    function self.Show()
        if self.error then return nil, self.error end
        self.root:SetScale(env.UIParent:GetEffectiveScale()); self.root:Show(); return true
    end
    function self.Identity(unit)
        if not ({ player = true, target = true, pet = true })[unit] then return nil, "Unsupported portrait unit." end
        if env.C_Secrets and type(env.C_Secrets.ShouldUnitIdentityBeSecret) == "function" then
            local access = ns.ReadOnly.Call(reader, env.C_Secrets.ShouldUnitIdentityBeSecret, unit)
            if not access or access.n ~= 1 or access[1] ~= false then return nil, "This unit is restricted." end
        end
        local exists = ns.ReadOnly.Call(reader, env.UnitExists, unit)
        if not exists or exists.n ~= 1 or exists[1] ~= true then return nil, "No accessible " .. unit .. "." end
        local guid = ns.ReadOnly.Call(reader, env.UnitGUID, unit)
        if not guid or guid.n ~= 1 or type(guid[1]) ~= "string" or #guid[1] == 0 then return nil, "Unit identity unavailable." end
        return guid[1] -- transient only; never saved or exported
    end
    function self.Load(model, spec)
        self.Clear(model)
        local method = self.kind == "ModelScene" and "SetModelByUnit" or "SetUnit"
        local r
        if self.kind == "ModelScene" then
            r = ns.ReadOnly.Call(reader, model[method], model, spec.unit, spec.sheathed, true, spec.hideWeapons, true)
        else r = ns.ReadOnly.Call(reader, model[method], model, spec.unit, false, true) end
        if not r or r.n ~= 1 or r[1] ~= true then self.Clear(model); return nil, "Client could not load this unit." end
        return true
    end
    function self.Loaded(model)
        local r = ns.ReadOnly.Call(reader, self.kind == "ModelScene" and model.IsLoaded or model.GetModelFileID, model)
        if not r or r.n ~= 1 then return nil end
        if self.kind == "ModelScene" then if type(r[1]) == "boolean" then return r[1] end
        elseif ns.Value.Finite(r[1]) and r[1] >= 0 then return r[1] > 0 end
    end
    function self.Supports(model, key)
        if key == "spellKit" then return self.kind == "ModelScene" and type(model.SetSpellVisualKit) == "function" end
        if key == "outfit" then return type(model.TryOn) == "function" and type(model.UndressSlot) == "function" end
        if key == "time" or key == "speed" then return self.kind == "ModelScene" end
        if key == "sheathed" or key == "hideWeapons" then
            return self.kind == "ModelScene" or type(model.SetSheathed) == "function"
        end
        local method = ({ transmog = "SetUseTransmogSkin", hideHead = "UndressSlot", hideCloak = "UndressSlot",
            pitch = "SetPitch", roll = "SetRoll" })[key]
        return not method or type(model[method]) == "function"
    end
    function self.Transform(model, spec)
        local ok = call(model, "SetPosition", spec.depth, -spec.x, spec.y)
        local yaw = call(model, self.kind == "ModelScene" and "SetYaw" or "SetFacing", math.rad(spec.yaw))
        local scale = call(model, self.kind == "ModelScene" and "SetScale" or "SetModelScale", spec.scale)
        if self.kind == "ModelScene" and type(model.SetRequestedScale) == "function" then scale = call(model, "SetRequestedScale", spec.scale) and scale end
        -- Missing optional methods do not reject an otherwise usable model.
        -- Their saved values remain intact; the UI identifies unavailable controls.
        local pitch = not self.Supports(model, "pitch") or call(model, "SetPitch", math.rad(spec.pitch))
        local roll = not self.Supports(model, "roll") or call(model, "SetRoll", math.rad(spec.roll))
        return ok and yaw and scale and pitch and roll, "Model transform unavailable."
    end
    function self.Pose(model, spec)
        if type(model.HasAnimation) == "function" then
            local r = ns.ReadOnly.Call(reader, model.HasAnimation, model, spec.animation)
            if not r or r.n ~= 1 or r[1] ~= true then return nil, "This model does not support that pose." end
        end
        local ok
        if self.kind == "ModelScene" then ok = call(model, "SetAnimation", spec.animation, spec.variation, spec.speed, spec.time)
        else ok = call(model, "SetAnimation", spec.animation, spec.variation) end
        local paused = self.Pause(model, spec.paused)
        return ok and paused, "Model animation unavailable."
    end
    function self.Appearance(model, spec)
        if type(model.SetSheathed) == "function" and not call(model, "SetSheathed", spec.sheathed, spec.hideWeapons) then return nil, "Model weapon preview unavailable." end
        if self.Supports(model, "transmog") and not call(model, "SetUseTransmogSkin", spec.transmog) then return nil, "Model appearance preview unavailable." end
        for _, part in ipairs({ { spec.hideHead, 1 }, { spec.hideCloak, 15 } }) do
            if part[1] and type(model.UndressSlot) == "function" and not call(model, "UndressSlot", part[2]) then return nil, "Model clothing preview unavailable." end
        end
        return true
    end
    function self.Outfit(model, spec)
        if not next(spec.outfit) then return true end
        if not self.Supports(model,"outfit") then return true end -- retained data; control reports local absence
        for _,slot in ipairs(ns.Value.Keys(spec.outfit)) do
            local item=spec.outfit[slot]
            if not call(model,"UndressSlot",slot) then return nil,"Could not clear the preview slot." end
            local hidden=slot==1 and spec.hideHead or slot==15 and spec.hideCloak or (slot==16 or slot==17 or slot==18) and spec.hideWeapons
            if item>0 and not hidden then
                local r=ns.ReadOnly.Call(reader,model.TryOn,model,"item:"..item,slot==16 and "MAINHANDSLOT" or slot==17 and "SECONDARYHANDSLOT" or nil)
                if not r or r.n>1 or r[1]~=nil and r[1]~=0 then
                    return nil,r and r[1]==3 and "Item data is loading. Refresh the browser and try again." or "This item cannot be previewed on that model. Previous outfit kept."
                end
            end
        end
        if type(model.SetSheathed)=="function" and not call(model,"SetSheathed",spec.sheathed,spec.hideWeapons) then return nil,"Model weapon preview unavailable." end
        return true
    end
    function self.Spell(model, kit)
        if not self.Supports(model,"spellKit") then return nil,"Model spell effects need the ModelScene backend." end
        local ok=call(model,"SetSpellVisualKit",kit,false)
        if ok and type(model.GetSpellVisualKit)=="function" then
            local r=ns.ReadOnly.Call(reader,model.GetSpellVisualKit,model); ok=r and r.n==1 and r[1]==kit
        end
        return ok,"Model spell effect unavailable."
    end
    function self.Apply(model, spec)
        for _, fn in ipairs({ self.Transform, self.Pose, self.Appearance, self.Outfit }) do local ok, why = fn(model, spec); if not ok then return nil, why end end
        if self.Supports(model,"spellKit") then return self.Spell(model,spec.spellKit) end
        return true
    end
    function self.CanLight()
        if self.scene then return methods(self.scene, { "SetLightType", "SetLightVisible", "SetLightDirection", "SetLightAmbientColor", "SetLightDiffuseColor" }) end
        if type(env.CreateVector3D) ~= "function" or type(env.CreateColor) ~= "function" then return false end
        for _, model in pairs(self.models) do if type(model.SetLight) ~= "function" then return false end end
        return true
    end
    function self.Light(light)
        if not self.CanLight() then return nil, "Model lighting unavailable. Other portrait controls remain available." end
        local az, el = math.rad(light.azimuth), math.rad(light.elevation)
        local x, y, z = -math.cos(el) * math.cos(az), -math.cos(el) * math.sin(az), -math.sin(el)
        if self.scene then
            local a = call(self.scene, "SetLightType", 0)
            local b = call(self.scene, "SetLightVisible", true)
            local c = call(self.scene, "SetLightDirection", x, y, z)
            local d = call(self.scene, "SetLightAmbientColor", light.ambient, light.ambient, light.ambient)
            local e = call(self.scene, "SetLightDiffuseColor", light.red * light.diffuse, light.green * light.diffuse, light.blue * light.diffuse)
            return a and b and c and d and e, "Stage lighting unavailable."
        end
        local vector = ns.ReadOnly.Call(reader, env.CreateVector3D, x, y, z)
        local ambient = ns.ReadOnly.Call(reader, env.CreateColor, 1, 1, 1)
        local diffuse = ns.ReadOnly.Call(reader, env.CreateColor, light.red, light.green, light.blue)
        if not vector or not ambient or not diffuse then return nil, "Model-widget lighting unavailable." end
        for _, model in pairs(self.models) do
            if not call(model, "SetLight", true, { omnidirectional = false, point = vector[1], ambientIntensity = light.ambient,
                ambientColor = ambient[1], diffuseIntensity = light.diffuse, diffuseColor = diffuse[1] }) then return nil, "Model-widget lighting unavailable." end
        end
        return true
    end
    function self.Camera(scene)
        if not self.scene then return nil, "Stage camera lens needs the ModelScene backend; actor transforms still work." end
        local a = call(self.scene, "SetCameraPosition", scene.distance, 0, scene.height)
        local b = call(self.scene, "SetCameraOrientationByYawPitchRoll", math.pi, 0, 0)
        local c = call(self.scene, "SetCameraFieldOfView", math.rad(scene.fov))
        return a and b and c, "Stage camera unavailable."
    end
    function self.Background(id)
        local color = ns.PortraitConfig.Colors[id]
        if color then self.background:SetColorTexture(color[1], color[2], color[3], 1) else self.background:SetColorTexture(0, 0, 0, 0) end
    end
    return self
end
