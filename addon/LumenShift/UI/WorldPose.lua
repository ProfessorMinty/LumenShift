local _, ns = ...
local P, W = {}, ns.Widgets
ns.WorldPoseUI = P

local stageArt = { WAVE="wave", KNEEL="kneel", SIT="sit", STAND="stand" }
local pageSize = 6
local messages = {
    POSE_STOP_REQUESTED="Stop requested.", POSE_REJECTED="WoW declined this emote.",
    SCREENSHOT_UNAVAILABLE="Screenshot unavailable on this client.", SCREENSHOT_FAILED="WoW reported a screenshot failure.",
    CAPTURE_RESULT_UNOBSERVED="WoW did not confirm the screenshot.", CAPTURE_TIMER_FAILED="The screenshot timer could not run.",
    COMPLETE="Screenshot saved.", CANCELLED="Shot cancelled.", WAITING_FOR_PREVIEW="Finishing photo edits…",
    CAPTURING="Taking the screenshot…", PHOTO_ACTION_WAITING="Finish the pending photo action first.",
}
local function message(code)
    return messages[code] or ns.Product.Message(code)
end
local function enabled(control, on)
    if on then control:Enable(); control:SetAlpha(1)
    else control:Disable(); control:SetAlpha(.55) end
end

function P.Build(runtime, env, parent, ui)
    local pose, sequence, prefs = runtime.photoTools, runtime.captureSequence, runtime.db.camera.tools
    local tiles, selected = {}, nil
    local filter
    local page = ui.worldEmotePage or 1
    local function selectItem(item)
        selected = item
        ui.worldEmote = item and item[1]
        for _, tile in ipairs(tiles) do tile.SetSelected(selected ~= nil and tile.item == selected) end
    end
    local field = W.Edit(env, parent, ui.worldEmoteQuery or "", 0, 0, 238, function() end, 32)
    local hint = W.Text(field, "Search emotes", 8, -6, 215, 13, W.colors.muted)
    local clear = W.Button(env, parent, "Clear", 244, 0, 66, function()
        field:SetText(""); filter(true); field:SetFocus()
    end, nil, "quiet")
    for i=1,pageSize do
        local tile
        tile = W.Button(env, parent, "", (i-1)%3*105, -36-math.floor((i-1)/3)*44, 100, function()
            field:ClearFocus()
            selectItem(tile.item)
            if not sequence.active then ui.worldShot, ui.worldPoseMessage = nil, nil end
            ui.Refresh()
        end)
        tile:SetHeight(40)
        tile.item=nil
        tile.art = W.Texture(tile, "ARTWORK")
        tile.art:SetSize(27,36); tile.art:SetPoint("LEFT",tile,"LEFT",4,0)
        tile.label:ClearAllPoints(); tile.label:SetPoint("LEFT",tile,"LEFT",35,0)
        tile.label:SetWidth(62); tile.label:SetFont(tile.label:GetFont(),12,"")
        tiles[i] = tile
    end
    local empty = W.Text(parent, "", 4, -60, 302, 13, W.colors.muted)
    empty:SetJustifyH("CENTER")
    local previous = W.Button(env, parent, "Previous", 0,-126,85,function() page=page-1; filter() end,nil,"quiet")
    local nextPage = W.Button(env, parent, "Next", 226,-126,84,function() page=page+1; filter() end,nil,"quiet")
    local count = W.Text(parent,"",86,-133,138,12,W.colors.muted); count:SetJustifyH("CENTER")
    W.Rule(parent,0,-159,310)
    local try = W.Button(env,parent,"Try emote",0,-167,150,function()
        if not selected then return end
        field:ClearFocus(); ui.worldShot=nil
        local ok, why=pose.Perform(selected[1],false)
        ui.worldPoseMessage=ok and (selected[2].." requested.") or message(why)
        ui.Refresh()
    end)
    local pin = W.Button(env,parent,"Pin",156,-167,66,function()
        if selected then pose.Favorite(selected[1]); filter() end
    end,nil,"quiet")
    local stop = W.Button(env,parent,"Stop",226,-167,84,function()
        if sequence.active then
            ui.worldShot=sequence.generation
            sequence.Cancel()
        else
            ui.worldShot=nil
            local _, why=pose.Stop()
            ui.worldPoseMessage=message(why); ui.Refresh()
        end
    end,"Stop the pose, or cancel a pending shot.","quiet")
    local timer = W.Toggle(env,parent,"Pose timer",0,-204,158,function() return prefs.autoPose end,function(on)
        prefs.autoPose=on; ui.Refresh()
    end,"Replay your selected emote and take one shot after the delay.")
    local function delay(delta)
        prefs.delay=math.max(0,math.min(10,prefs.delay+delta)); ui.Refresh()
    end
    local minus=W.Button(env,parent,"-",170,-204,37,function() delay(-1) end,"Shorten the delay")
    local seconds=W.Text(parent,"",208,-211,60,13); seconds:SetJustifyH("CENTER")
    local plus=W.Button(env,parent,"+",273,-204,37,function() delay(1) end,"Lengthen the delay")
    local shot=W.Button(env,parent,"Take shot",0,-245,310,function()
        field:ClearFocus()
        ui.worldShot, ui.worldPoseMessage = sequence.generation+1, nil
        local ok, why
        if prefs.autoPose and selected then ok,why=pose.Perform(selected[1],true)
        elseif not prefs.autoPose then ok,why=pose.TakeShot() end
        if not ok then ui.worldShot=nil; ui.worldPoseMessage=message(why or "INVALID_POSE") end
        ui.Refresh()
    end,nil,"primary")

    local function refreshActions()
        local available=pose.Available()
        local idle=not sequence.active and not runtime.composition.capturing
        local canEmote=idle and available and not runtime.product.IsCombat()
        try.label:SetText(selected and "Try "..selected[2] or "Try emote")
        enabled(try,selected and canEmote)
        pin.label:SetText(selected and prefs.favorites[selected[1]] and "Unpin" or "Pin")
        enabled(pin,selected)
        stop.label:SetText(sequence.active and "Cancel" or "Stop pose")
        enabled(stop,sequence.active or canEmote)
        timer.RefreshValue(); enabled(timer,idle)
        if prefs.autoPose then
            minus:Show(); seconds:Show(); plus:Show()
            seconds:SetText(prefs.delay.." s")
            enabled(minus,idle and prefs.delay>0); enabled(plus,idle and prefs.delay<10)
        else minus:Hide(); seconds:Hide(); plus:Hide() end
        shot.label:SetText(prefs.autoPose and "Pose & shoot" or "Take shot")
        local canShoot, reason=sequence.CanStart()
        enabled(shot,canShoot and (not prefs.autoPose or selected and canEmote))
        if sequence.active then
            if sequence.state=="COUNTDOWN" or sequence.state=="INTERVAL" then return "Shot in "..sequence.remaining.." s" end
            return message(sequence.state)
        end
        if ui.worldShot and sequence.generation==ui.worldShot+1 then return message(sequence.state) end
        if ui.worldPoseMessage then return ui.worldPoseMessage end
        if not available then return "World emotes unavailable on this client." end
        if not canShoot and reason=="SCREENSHOT_UNAVAILABLE" then return message(reason) end
        if runtime.product.IsCombat() then return "Try emotes after combat." end
        return "Nearby players can see or hear world emotes."
    end
    filter=function(firstPage)
        ui.worldEmoteQuery=field:GetText()
        local query=ui.worldEmoteQuery:lower():match("^%s*/?(.-)%s*$")
        if firstPage then
            page=1
            if not sequence.active then ui.worldShot, ui.worldPoseMessage=nil,nil end
        end
        local matches={}
        for _,item in ipairs(ns.PhotoTools.Poses) do
            if (ui.worldPoseTab~="Favorites" or prefs.favorites[item[1]])
                and item[2]:lower():find(query,1,true) then matches[#matches+1]=item end
        end
        local pages=math.max(1,math.ceil(#matches/pageSize))
        page=math.max(1,math.min(page,pages)); ui.worldEmotePage=page
        local chosen
        for i,tile in ipairs(tiles) do
            local item=matches[(page-1)*pageSize+i]
            if item then
                if tile.item~=item then
                    local existing=stageArt[item[1]]
                    local name=existing and "pose-"..existing or "emote-"..item[1]:lower()
                    W.Asset(tile.art,"Interface/AddOns/LumenShift/Media/"..name..".tga")
                    if existing then tile.art:SetTexCoord(40/128,88/128,0,1) else tile.art:SetTexCoord(0,1,0,1) end
                    tile.label:SetText(item[2])
                end
                if item[1]==ui.worldEmote then chosen=item end
                tile:Show()
            else tile:Hide() end
            tile.item=item
        end
        selectItem(chosen or tiles[1].item)
        if #matches==0 then
            empty:SetText(query~="" and "No matching emotes." or "Pin an emote in All emotes to find it here."); empty:Show()
        else empty:Hide() end
        if pages>1 then
            count:SetText("Page "..page.." of "..pages)
            previous:Show(); nextPage:Show()
            enabled(previous,page>1); enabled(nextPage,page<pages)
        else
            count:SetText(#matches..(#matches==1 and " emote" or " emotes"))
            previous:Hide(); nextPage:Hide()
        end
        if ui.worldEmoteQuery=="" then hint:Show() else hint:Hide() end
        enabled(clear,ui.worldEmoteQuery~="")
        ui.Refresh()
    end
    W.Script(field,"OnTextChanged",function()
        if field:GetText()~=ui.worldEmoteQuery then filter(true) end
    end)
    ui.RefreshWorldPose=refreshActions
    filter(false)
    return -280
end
