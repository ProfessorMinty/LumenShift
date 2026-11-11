return function(make, eq, test)
    local function click(f,label)
        f.mock.Click(label); assert(not f.ui.building, "Interrupted panel build: "..label)
    end
    local function button(f,label)
        for _,node in ipairs(f.mock.nodes) do
            if node.kind=="Button" and node:IsVisible() and node.label and node.label:GetText()==label then return node end
        end
    end
    local function searchField(f)
        for _,node in ipairs(f.mock.nodes) do
            if node.kind=="EditBox" and node:IsVisible() then return node end
        end
        error("Missing emote search field")
    end
    local function start()
        local f=make()
        f.emotes={}; f.seq=f.r.captureSequence; f.prefs=f.r.db.camera.tools
        f.env.C_ChatInfo={PerformEmote=function(token,target)
            eq(target,"none"); table.insert(f.emotes,token); return true
        end}
        click(f,"Pose")
        return f
    end
    local function receive(f,event)
        for i=1,15 do
            if f.c.requested then break end
            f.tick()
        end
        eq(f.c.requested,true); eq(f.c.root:IsShown(),false)
        f.c.root.scripts.OnEvent(f.c.root,event or "SCREENSHOT_SUCCEEDED"); f.flush()
    end
    test("WP01 all world emotes, favorites and timed shutter fit the compact and standard panels",function()
        local f=start()
        for _,size in ipairs({{1280,800},{600,400}}) do
            f.env.UIParent:SetSize(unpack(size)); f.c.Show(); click(f,"All emotes")
            local seen={}
            for page=1,2 do
                local n=0
                for _,item in ipairs(f.ns.PhotoTools.Poses) do
                    if button(f,item[2]) then assert(not seen[item[1]]); seen[item[1]]=true; n=n+1 end
                end
                eq(n,6); eq(f.ui.scrollbar.maximum,0)
                if page==1 then click(f,"Next") end
            end
            click(f,"Favorites"); eq(f.ui.scrollbar:IsShown(),false); assert(button(f,"Dance"))
            click(f,"Pose timer"); eq(f.ui.scrollbar.maximum,0)
        end
        eq(#f.emotes,0); eq(f.captures,0); eq(#f.calls,0); eq(f.env.Narci,nil)
    end)
    test("WP02 live search keeps focus, accepts slash names and has a recoverable empty state",function()
        local f=start(); local field=searchField(f); field:SetFocus()
        field:SetText("  /saL "); eq(button(f,"Wave"),nil); assert(button(f,"Salute"))
        eq(f.mock.focus,field); eq(f.ui.worldEmote,"SALUTE")
        field:SetText("%["); eq(f.ui.worldEmote,nil); eq(button(f,"Try emote"):IsEnabled(),false)
        eq(f.ui.scrollbar.maximum,0); eq(#f.emotes,0)
        click(f,"Clear"); eq(f.mock.focus,field); assert(button(f,"Next")); eq(f.captures,0)
    end)
    test("WP03 trying previews even with an existing auto-shot preference and persists pins",function()
        local f=start(); f.prefs.autoPose=true; f.prefs.shots=5; f.ui.Build()
        local field=searchField(f); field:SetText("read")
        click(f,"Read"); click(f,"Try Read"); eq(#f.emotes,1); eq(f.emotes[1],"READ")
        eq(f.seq.active,false); eq(f.captures,0); eq(#f.mock.timers,0)
        click(f,"Pin"); click(f,"Favorites"); assert(button(f,"Read")); eq(f.prefs.favorites.READ,true)
        click(f,"Unpin"); eq(f.ui.worldEmote,nil); click(f,"All emotes"); click(f,"Stop pose")
        eq(f.emotes[2],"STAND"); eq(f.captures,0); eq(f.prefs.autoPose,true); eq(f.prefs.shots,5)
    end)
    test("WP04 Take shot captures the current pose once without replay or burst",function()
        local f=start(); f.prefs.shots=5; f.prefs.delay=8
        click(f,"Dance"); click(f,"Try Dance"); click(f,"Take shot")
        eq(f.seq.total,1); eq(f.seq.remaining,0); receive(f)
        eq(f.captures,1); eq(#f.emotes,1); eq(f.emotes[1],"DANCE"); eq(f.ui.status:GetText(),"Screenshot saved.")
        eq(f.prefs.delay,8); eq(f.prefs.shots,5); eq(#f.calls,0)
    end)
    test("WP05 Pose timer replays exactly once, honors delay and cancels stale shots",function()
        local f=start(); click(f,"Wave"); click(f,"Pose timer"); click(f,"+")
        click(f,"Try Wave"); eq(#f.emotes,1); eq(f.seq.active,false)
        click(f,"Pose & shoot"); eq(#f.emotes,2); eq(f.seq.remaining,4)
        eq(f.ui.status:GetText(),"Shot in 4 s"); eq(button(f,"Try Wave"):IsEnabled(),false)
        click(f,"Cancel"); f.flush(); eq(f.captures,0); eq(f.ui.status:GetText(),"Shot cancelled.")
        click(f,"-"); click(f,"Pose & shoot"); eq(f.seq.remaining,3)
        receive(f); eq(f.captures,1); eq(#f.emotes,3); eq(f.seq.completed,1); eq(#f.calls,0)
    end)
    test("WP06 failed or missing emote and screenshot APIs leave independent actions usable",function()
        local f=start(); click(f,"Pose timer"); f.env.C_ChatInfo.PerformEmote=function() return false end
        f.env.DoEmote=function() error("must not retry a rejected emote") end
        click(f,"Pose & shoot"); eq(f.seq.active,false); eq(f.ui.status:GetText(),"WoW declined this emote.")
        f.env.C_ChatInfo=nil; f.env.DoEmote=nil; f.ui.Refresh()
        eq(button(f,"Try Wave"):IsEnabled(),false); click(f,"Pose timer"); click(f,"Take shot")
        receive(f,"SCREENSHOT_FAILED"); eq(f.ui.status:GetText(),"WoW reported a screenshot failure.")
        f.env.DoEmote=function(token) table.insert(f.emotes,token) end; f.env.Screenshot=nil
        click(f,"Pose timer"); eq(button(f,"Pose & shoot"):IsEnabled(),false)
        eq(f.r.photoTools.Perform("WAVE",true),nil); eq(#f.emotes,0)
        click(f,"Try Wave"); eq(#f.emotes,1); eq(f.seq.active,false)
    end)
    test("WP07 search and selection survive renderer switches without touching staged actors",function()
        local f=start(); searchField(f):SetText("/kne"); click(f,"Kneel")
        click(f,"Portrait Stage"); f.flush(); click(f,"Actors"); assert(button(f,"Play pose"))
        eq(button(f,"Take shot"),nil); eq(f.r.photoTools.Perform("KNEEL",false),nil)
        click(f,"World Photo"); click(f,"Pose"); eq(searchField(f):GetText(),"/kne")
        assert(button(f,"Try Kneel")); eq(#f.emotes,0); eq(f.captures,0)
    end)
    test("WP08 a competing deferred action cannot strand a pose timer or trigger a stray emote",function()
        local f=start(); click(f,"Pose timer"); assert(f.r.photoPreview.Queue("Brightness",70))
        assert(f.r.photoPreview.Finish(function() end))
        eq(f.r.photoTools.Perform("WAVE",true),nil); eq(f.seq.active,false); eq(#f.emotes,0)
        f.flush(); eq(f.captures,0)
        click(f,"Pose & shoot"); assert(f.r.camera.Exit()); f.flush()
        eq(f.seq.active,false); eq(f.captures,0); eq(#f.emotes,1)
    end)
end
