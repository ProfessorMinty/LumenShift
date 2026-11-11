local _, ns = ...
local P, V, C = {}, ns.Value, ns.PortraitConfig; ns.Portrait = P
function P.New(runtime)
    local env, reader, db = runtime.reader.env, runtime.reader, runtime.db
    local self = { active = false, busy = false, selected = 1, generation = 0, slots = {}, failures = {}, status = "World Photo" }
    local backend = ns.PortraitBackend.New(runtime); self.backend = backend
    self.wardrobe = ns.PortraitWardrobe.New(runtime)
    self.collection = ns.TransmogCollection.New(runtime)
    local function report(ok, why)
        self.status = why or "Portrait ready."
        if self.Refresh then self.Refresh() end
        return ok, why
    end
    local function context()
        return db and runtime.camera.active and not runtime.camera.interrupted and runtime.camera.CanCompose()
            and not runtime.composition.suspended and not reader.resetPending
    end
    local function ready()
        return self.active and context() and not self.busy and not self.layerCapture and not runtime.composition.capturing
            and not runtime.captureSequence.active and not runtime.photoPreview.Pending() and not runtime.camera.busy
    end
    local function busy()
        self.busy = false; for _, slot in pairs(self.slots) do if slot.pending then self.busy = true end end
    end
    local function finishSceneLoad()
        local result = self.sceneLoad
        if not result or not result.pending or self.busy then return end
        local issues = {}
        if next(self.failures) then issues[#issues+1] = "Check cast" end
        if self.notice then issues[#issues+1] = "Lighting unavailable" end
        if backend.kind ~= "ModelScene" then issues[#issues+1] = "Stage lens unavailable" end
        result.pending = false
        result.status = #issues == 0 and "Scene applied." or "Partial scene · "..table.concat(issues," · ")
    end
    function self.Exit()
        self.collection.Cancel()
        self.active, self.busy, self.layerCapture = false, false, nil
        self.generation = self.generation + 1; self.slots = {}; self.failures = {}; self.frozen = nil; self.sceneLoad = nil
        backend.Hide(); self.status = "World Photo"
        if runtime.photoEditor then runtime.photoEditor.Render() end
    end
    local function load(slotID, spec)
        if not C.ValidActor(spec) then return report(nil, "Invalid actor settings.") end
        spec = V.Copy(spec)
        if db.config.preferences.reducedMotion then spec.paused = true end
        local identity, why = backend.Identity(spec.unit)
        if not identity then self.failures[slotID] = why; return report(nil, why) end
        self.failures[slotID] = nil
        local slot = self.slots[slotID] or {}; self.slots[slotID] = slot
        local index = slot.front == (slotID * 2 - 1) and slotID * 2 or slotID * 2 - 1
        local model = backend.models[index]
        local ok, code = backend.Load(model, spec); if not ok then self.failures[slotID] = code; return report(nil, code) end
        slot.pending = true; busy()
        local generation, attempts = self.generation, 0
        local function finish(success, reason)
            slot.pending = nil; busy()
            self.failures[slotID] = not success and reason or nil
            if success then
                backend.Clear(slot.front and backend.models[slot.front])
                slot.front, slot.spec, slot.identity = index, V.Copy(spec), identity; model:Show()
                db.camera.portrait.scene.actors[slotID] = V.Copy(spec)
            else backend.Clear(model) end
            finishSceneLoad()
            report(success, reason)
        end
        local poll
        poll = function()
            if generation ~= self.generation or not self.active or not slot.pending then return end
            if not context() then self.Exit(); return end
            local current = backend.Identity(spec.unit)
            if current ~= identity then finish(false, "Unit changed while loading; previous actor kept."); return end
            attempts = attempts + 1
            local loaded = backend.Loaded(model)
            if loaded == nil then finish(false, "Model readiness unavailable; previous actor kept."); return end
            if loaded then
                local applied, reason = backend.Apply(model, spec)
                if not applied then finish(false, reason); return end
                finish(true); return
            end
            if attempts >= 20 then finish(false, "Model load timed out; previous actor kept."); return end
            if not ns.ReadOnly.Call(reader, env.C_Timer and env.C_Timer.After, .25, poll) then finish(false, "Model load timer unavailable.") end
        end
        if not ns.ReadOnly.Call(reader, env.C_Timer and env.C_Timer.After, .25, poll) then finish(false, "Model load timer unavailable."); return nil, self.status end
        return report(true, "Loading " .. spec.unit .. "...")
    end
    function self.Enter()
        if self.active then return true end
        if not context() or runtime.composition.capturing or runtime.captureSequence.active or runtime.photoPreview.Pending()
            or runtime.cameraActions.busy or runtime.photoComposition.busy then return report(nil, "Finish the current photo operation first.") end
        local stopped, reason = runtime.cameraActions.StopOrbit(); if not stopped then return report(nil, reason) end
        local ok, why = backend.Build(); if not ok then return report(nil, why) end
        ok, why = backend.Show(); if not ok then return report(nil, why) end
        self.active, self.generation, self.slots = true, self.generation + 1, {}
        local scene = db.camera.portrait.scene
        backend.Background(scene.background)
        local lens, lensWhy = backend.Camera(scene); local light, lightWhy = backend.Light(scene.light)
        self.notice = (not lens and lensWhy) or (not light and lightWhy) or nil
        for id = 1, 3 do if scene.actors[id] then load(id, V.Copy(scene.actors[id])) end end
        return true
    end
    function self.World()
        if not self.active then return true end
        if self.layerCapture or runtime.composition.capturing or runtime.captureSequence.active then return report(nil, "Finish or cancel capture first.") end
        self.Exit(); return true
    end
    function self.Add(unit)
        if not ready() then return report(nil, "Finish the current portrait operation first.") end
        for id = 1, 3 do if not self.slots[id] or not self.slots[id].front then
            self.selected = id; local a = C.Actor(unit); a.x = (id - 1) * .8
            return load(id, a)
        end end
        return report(nil, "Three actors maximum. Remove one to add another.")
    end
    function self.Remove(id)
        if not ready() or not V.Finite(id) or id % 1 ~= 0 or id < 1 or id > 3 then return report(nil, "Portrait not ready.") end
        local slot = self.slots[id]; if slot then backend.Clear(slot.front and backend.models[slot.front]) end
        self.slots[id] = nil; self.failures[id] = nil; db.camera.portrait.scene.actors[id] = nil; return report(true, "Actor removed.")
    end
    local function editActor(key, value, vertical)
        if not ready() then return report(nil, "Portrait not ready.") end
        local slot = self.slots[self.selected]; if not slot or not slot.front then return report(nil, "Select a loaded actor.") end
        if not C.ActorRanges[key] and not ({ animation = true, variation = true, spellKit = true, paused = true, sheathed = true, hideWeapons = true,
            transmog = true, hideHead = true, hideCloak = true })[key] then return report(nil, "Unknown actor control.") end
        if not backend.Supports(backend.models[slot.front], key) then return report(nil, "This model control is unavailable; saved choices are kept.") end
        local spec = V.Copy(slot.spec); spec[key] = value
        if vertical ~= nil then spec.y = vertical end
        if not C.ValidActor(spec) then return report(nil, "Invalid actor value.") end
        if key == "time" then spec.paused = true end
        if key == "animation" then spec.time, spec.variation = 0, 0 end
        if ({ sheathed = true, hideWeapons = true, transmog = true, hideHead = true, hideCloak = true })[key] then
            if backend.Identity(slot.spec.unit) ~= slot.identity then
                return report(nil, "Unit changed. Select the staged target again before refreshing its appearance.")
            end
            return load(self.selected, spec)
        end
        local fn = ({ animation = true, variation = true, time = true, speed = true, paused = true })[key] and backend.Pose or backend.Transform
        local ok, why
        if key == "spellKit" then
            ok, why = backend.Spell(backend.models[slot.front],value)
            if not ok then backend.Spell(backend.models[slot.front],slot.spec.spellKit); return report(nil,why) end
        elseif key == "paused" then ok = backend.Pause(backend.models[slot.front], spec.paused); why = "Model pause unavailable."
        else ok, why = fn(backend.models[slot.front], spec) end
        if not ok then fn(backend.models[slot.front], slot.spec); return report(nil, why) end
        slot.spec = spec; db.camera.portrait.scene.actors[self.selected] = V.Copy(spec); return report(true)
    end
    function self.SetActor(key, value)
        return editActor(key, value)
    end
    function self.PlaceActor(horizontal, vertical)
        if not V.Finite(vertical) then return report(nil, "Invalid actor position.") end
        return editActor("x", horizontal, vertical)
    end
    function self.SetOutfit(outfit)
        if not ready() or not C.ValidOutfit(outfit) then return report(nil,"Outfit not ready or invalid.") end
        local slot=self.slots[self.selected]
        if not slot or not slot.front then return report(nil,"Select a loaded actor.") end
        if not backend.Supports(backend.models[slot.front],"outfit") then return report(nil,"Outfit preview is unavailable on this model.") end
        if backend.Identity(slot.spec.unit)~=slot.identity then return report(nil,"Select the staged unit again before changing its outfit.") end
        local spec=V.Copy(slot.spec); spec.outfit=V.Copy(outfit)
        if C.Worn(outfit[1]) then spec.hideHead=false end
        if C.Worn(outfit[15]) then spec.hideCloak=false end
        if C.Worn(outfit[16]) or C.Worn(outfit[17]) or C.Worn(outfit[18]) then spec.hideWeapons=false end
        return load(self.selected,spec)
    end
    function self.TrySource(slotID,sourceID)
        if not ready() then return report(nil,"Portrait not ready.") end
        local selected=self.slots[self.selected]; if not selected or not selected.front then return report(nil,"Select an actor.") end
        if #self.collection.categories==0 then self.collection.Discover() end
        local source=self.collection.Source(sourceID)
        if not source then return report(nil,"Appearance source is unavailable. Refresh the collection and try again.") end
        local fits=false; for _,slot in ipairs(source.slots) do if slot==slotID then fits=true end end
        if not fits then return report(nil,"That appearance does not fit the selected preview slot.") end
        local outfit=V.Copy(selected.spec.outfit); outfit[slotID]={sourceID=sourceID}
        return self.SetOutfit(outfit)
    end
    function self.TryCollectionSet(setID)
        if not ready() then return report(nil,"Portrait not ready.") end
        local outfit,why=self.collection.SetOutfit(setID)
        if not outfit then return report(nil,why) end
        return self.SetOutfit(outfit)
    end
    function self.TryItem(slotID,itemID)
        if not ns.PortraitLibrary.Slot(slotID) then return report(nil,"Choose an outfit slot.") end
        if not V.Finite(itemID) or itemID%1~=0 or itemID<0 or itemID>9999999 then return report(nil,"Enter a valid item ID or item link.") end
        local selected=self.slots[self.selected]; if not selected or not selected.front then return report(nil,"Select an actor.") end
        if itemID~=0 then
            local item=self.wardrobe.Info(itemID)
            if not item then self.wardrobe.Request(itemID); return report(nil,"Item data unavailable. Refresh the browser and try again.") end
            local fits=false; for _,slot in ipairs(item.slots) do if slot==slotID then fits=true end end
            if not fits then return report(nil,"That item does not fit the selected preview slot.") end
        end
        local outfit=V.Copy(selected.spec.outfit); outfit[slotID]=itemID
        return self.SetOutfit(outfit)
    end
    function self.UseEquippedOutfit()
        local outfit,why=self.wardrobe.Capture("player"); if not outfit then return report(nil,why) end
        return self.SetOutfit(outfit)
    end
    function self.SaveOutfit(name)
        if not ready() then return report(nil,"Portrait not ready.") end
        local slot=self.slots[self.selected]; if not slot or not slot.front then return report(nil,"Select an actor.") end
        if backend.Identity(slot.spec.unit)~=slot.identity then return report(nil,"Select the staged unit again before saving its outfit.") end
        local outfit,why=self.wardrobe.Capture(slot.spec.unit); if not outfit then return report(nil,why) end
        for key,id in pairs(slot.spec.outfit) do outfit[key]=id end
        if slot.spec.hideHead then outfit[1]=0 end; if slot.spec.hideCloak then outfit[15]=0 end
        if slot.spec.hideWeapons then outfit[16],outfit[17],outfit[18]=0,0,0 end
        local ok,code=C.Save(db.camera.portrait.outfits,name,outfit,C.ValidOutfit)
        return report(ok,code or "Outfit saved. Collection sources retain their exact appearance; ordinary items use their base items.")
    end
    function self.SetLight(light)
        if not ready() or not C.ValidLight(light) then return report(nil, "Portrait light not ready or invalid.") end
        local ok, why = backend.Light(light)
        if not ok then backend.Light(db.camera.portrait.scene.light); return report(nil, why) end
        db.camera.portrait.scene.light = V.Copy(light); return report(true)
    end
    local function setLens(scene)
        local current = db.camera.portrait.scene
        local ok, why = backend.Camera(scene)
        if not ok then
            if not backend.Camera(current) then
                return nil, "Stage camera could not restore the previous view. Try Reset stage camera."
            end
            return nil, why
        end
        for key in pairs(C.CameraRanges) do current[key] = scene[key] end
        return true
    end
    function self.ResetCamera()
        if not ready() then return report(nil, "Portrait not ready.") end
        return report(setLens(C.Scene()))
    end
    function self.SetOrbit(yaw, pitch)
        if not ready() then return report(nil, "Portrait not ready.") end
        local scene = V.Copy(db.camera.portrait.scene)
        scene.yaw, scene.pitch = yaw, pitch
        if not C.ValidScene(scene) then return report(nil, "Invalid orbit angles.") end
        return report(setLens(scene))
    end
    function self.SetScene(key, value)
        if not ready() then return report(nil, "Portrait not ready.") end
        if key ~= "background" and not C.CameraRanges[key] then return report(nil, "Unknown stage control.") end
        local scene = V.Copy(db.camera.portrait.scene); scene[key] = value
        if not C.ValidScene(scene) then return report(nil, "Invalid stage value.") end
        if key ~= "background" then return report(setLens(scene)) end
        backend.Background(value)
        db.camera.portrait.scene.background = value
        return report(true)
    end
    function self.Save(name, lighting)
        if not ready() then return report(nil, "Portrait not ready.") end
        local data = db.camera.portrait
        local ok, why = C.Save(lighting and data.lights or data.saved, name, lighting and data.scene.light or data.scene, lighting and C.ValidLight or C.ValidScene)
        return report(ok, why or "Saved.")
    end
    function self.Delete(name, lighting)
        if not ready() or not C.Name(name) then return nil end
        local bank = lighting and db.camera.portrait.lights or db.camera.portrait.saved
        bank[name] = nil; return report(true, "Deleted.")
    end
    function self.Load(name, lighting)
        if not ready() then return report(nil, "Portrait not ready.") end
        if not C.Name(name) then return report(nil, "Invalid saved name.") end
        local data = db.camera.portrait
        local value = V.Copy((lighting and data.lights or data.saved)[name])
        if lighting then return self.SetLight(value) end
        if not C.ValidScene(value) then return report(nil, "Invalid saved scene.") end
        if backend.kind == "ModelScene" then
            local ok, why = setLens(value); if not ok then return report(nil, why) end
        else
            for key in pairs(C.CameraRanges) do data.scene[key] = value[key] end
        end
        -- Commit the lens first so a rejected angle leaves the current lighting intact.
        local lit, reason = self.SetLight(value.light)
        self.notice = not lit and reason or nil
        backend.Background(value.background); data.scene.background = value.background
        -- Each replacement is double buffered. Missing targets cannot remove an existing actor.
        for id = 1, 3 do
            if value.actors[id] then load(id, value.actors[id])
            else local slot = self.slots[id]; if slot then backend.Clear(slot.front and backend.models[slot.front]) end
                self.slots[id], data.scene.actors[id], self.failures[id] = nil, nil, nil
            end
        end
        -- All slots have been dispatched. A later successful slot must not mask an earlier failure.
        self.sceneLoad = {pending=true, status="Applying scene…"}
        finishSceneLoad()
        if self.Refresh then self.Refresh() end
        return true
    end
    function self.Freeze()
        if not self.active then return true end
        if self.busy then return nil, "Wait for the portrait to load." end
        if self.frozen then return true end
        self.frozen = {}
        for _, slot in pairs(self.slots) do if slot.front then
            local model = backend.models[slot.front]
            self.frozen[#self.frozen + 1] = { model = model, paused = slot.spec.paused }
            if not backend.Pause(model, true) then self.Thaw(); return report(nil, "Could not pause staged actors for capture.") end
        end end
        return true
    end
    function self.Thaw()
        local frozen = self.frozen; self.frozen = nil
        if frozen and self.active and context() then
            for _, item in ipairs(frozen) do if not backend.Pause(item.model, item.paused) then report(nil, "Could not resume a staged actor. Select its pose again.") end end
        end
    end
    function self.CaptureFinished()
        if not self.layerCapture then self.Thaw() end
    end
    local function layer(showActors, background)
        backend.Background(background)
        for _, slot in pairs(self.slots) do if slot.front then
            local model = backend.models[slot.front]; if showActors then model:Show() else model:Hide() end
        end end
    end
    function self.CancelLayers()
        if not self.layerCapture then return end
        self.layerCapture = nil
        runtime.composition.CancelPendingCapture()
        if self.active then layer(true, db.camera.portrait.scene.background) end
        self.Thaw(); runtime.photoEditor.Render(); report(true, "Layer capture stopped.")
    end
    function self.CaptureLayers()
        if not ready() then return report(nil, "Portrait not ready.") end
        local ok, why = self.Freeze(); if not ok then return nil, why end
        local token = {}; self.layerCapture = token
        runtime.photoEditor.Render()
        layer(false, db.camera.portrait.scene.background)
        local function finish(success, reason)
            if self.layerCapture ~= token then return end
            self.CancelLayers(); report(success, success and "Two separate images saved: background, then green-screen cast." or reason)
        end
        local function shoot(second)
            if self.layerCapture ~= token or not self.active then return end
            local called = false
            local started, code = runtime.composition.Capture(function(success, reason)
                called = true
                if self.layerCapture ~= token then return end
                if not success or second then finish(success, reason); return end
                layer(true, "green"); shoot(true)
            end)
            if not started and not called then finish(false, code) end
            return started, code
        end
        return shoot(false)
    end
    return self
end
