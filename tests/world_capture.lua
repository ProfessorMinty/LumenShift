return function(make, eq, test)
    local function start(count)
        local f=make()
        f.seq, f.prefs=f.r.captureSequence, f.r.db.camera.tools
        if count then f.prefs.shots=count end
        f.mock.Click("Capture"); assert(not f.ui.building)
        return f
    end
    local function control(f, label, parent, occurrence)
        local n=0
        for _,b in ipairs(f.mock.nodes) do
            if b.kind=="Button" and b:IsVisible() and b.label and b.label:GetText()==label and (not parent or b.parent==parent) then
                n=n+1
                if n==(occurrence or 1) then return b end
            end
        end
    end
    local function press(f,label,parent,which)
        local b=assert(control(f,label,parent,which),label)
        assert(b:IsEnabled(),label); b.scripts.OnClick(b,"LeftButton"); assert(not f.ui.building)
    end
    local function shown(f,text)
        for _,node in ipairs(f.mock.nodes) do
            if node.kind=="FontString" and node:IsVisible() and node:GetText()==text then return true end
        end
        return false
    end
    local function fits(f)
        eq(f.ui.scrollbar.maximum,0); eq(f.ui.scrollbar:IsShown(),false); eq(f.ui.scroll:GetVerticalScroll(),0)
    end
    local function requestShot(f)
        for i=1,32 do if f.c.requested then break end; f.tick() end
        assert(f.c.requested); eq(f.c.root:IsShown(),false)
    end
    local function result(f,event)
        f.c.root.scripts.OnEvent(f.c.root,event or "SCREENSHOT_SUCCEEDED")
    end
    test("WC01 World Capture is scroll-free at two sizes with saved burst settings and no startup effects",function()
        local f=start(4)
        f.values.screenshotFormat, f.values.screenshotQuality="jpeg","8"
        f.values.ffxAntiAliasingMode,f.values.MSAAQuality,f.values.MSAAAlphaTest="0","0,0","0"
        for _,size in ipairs({{1280,800},{600,400}}) do
            f.env.UIParent:SetSize(unpack(size)); f.c.Show()
            press(f,"Timer"); assert(control(f,"4").selected); fits(f)
            press(f,"Single shot"); eq(f.prefs.shots,1); eq(control(f,"4"),nil); fits(f)
            press(f,"Burst"); eq(f.prefs.shots,4); fits(f)
            press(f,"Output")
            for _,page in ipairs({"JPEG","Antialiasing","Shadows"}) do
                press(f,page); fits(f)
                if page=="Antialiasing" then assert(control(f,"Apply antialiasing")); eq(control(f,"Apply JPEG quality"),nil) end
            end
            press(f,"Combat"); fits(f); assert(control(f,"Keep filters during combat"))
        end
        eq(f.captures,0); eq(#f.calls,0); eq(#f.mock.timers,0); eq(f.env.Narci,nil)
    end)
    test("WC02 bounded delay, count and spacing remember choices across navigation",function()
        local f=start(); press(f,"Burst"); press(f,"5")
        for i=1,7 do press(f,"+",nil,1) end
        eq(f.prefs.delay,10); eq(control(f,"+"):IsEnabled(),false)
        for i=1,3 do press(f,"+",nil,2) end
        eq(f.prefs.interval,5); eq(control(f,"+",nil,2):IsEnabled(),false)
        for i=1,4 do press(f,"-",nil,2) end
        eq(f.prefs.interval,1); eq(control(f,"-",nil,2):IsEnabled(),false)
        for i=1,10 do press(f,"-",nil,1) end
        eq(f.prefs.delay,0); eq(control(f,"-"):IsEnabled(),false)
        press(f,"Pose"); press(f,"Capture"); assert(control(f,"5").selected)
        press(f,"Single shot"); assert(control(f,"Take shot now")); press(f,"Burst"); eq(f.prefs.shots,5)
        eq(f.prefs.interval,1); eq(f.prefs.delay,0); eq(f.captures,0); eq(#f.calls,0)
    end)
    test("WC03 either shutter starts the configured timer and cancellation invalidates old ticks",function()
        local f=start()
        local panel=assert(control(f,"Single shot")).parent
        press(f,"Start timer",panel); eq(f.seq.remaining,3); eq(f.captures,0); fits(f)
        eq(f.c.cancelButton:IsShown(),false)
        eq(control(f,"Burst"):IsEnabled(),false); f.tick(); eq(f.seq.remaining,2); assert(shown(f,"2 s"))
        press(f,"Combat"); eq(f.c.cancelButton:IsShown(),true); eq(control(f,"Capture screenshot",f.c.bar):IsEnabled(),false)
        press(f,"Timer"); eq(f.c.cancelButton:IsShown(),false); press(f,"Cancel capture",f.c.bar); assert(shown(f,"Cancelled"))
        press(f,"Start timer",f.c.bar); press(f,"Cancel capture",panel); f.flush()
        eq(f.seq.active,false); eq(f.captures,0); eq(f.prefs.delay,3); assert(control(f,"Start timer",panel):IsEnabled())
    end)
    test("WC04 burst counts only confirmed shots and can stop during the inter-shot countdown",function()
        local f=start(3); press(f,"Start burst",f.c.bar)
        requestShot(f); eq(f.seq.completed,0); result(f)
        assert(shown(f,"Shot 2 of 3")); assert(shown(f,"Until next shot")); fits(f)
        eq(f.seq.remaining,2); eq(f.seq.completed,1); press(f,"Stop burst")
        assert(shown(f,"1 shot confirmed")); assert(shown(f,"Cancelled"))
        f.flush(); eq(f.captures,1); eq(f.seq.active,false)
        press(f,"Start burst")
        for i=1,3 do requestShot(f); result(f); eq(f.seq.completed,i) end
        f.flush(); eq(f.captures,4); assert(shown(f,"Burst saved")); assert(shown(f,"3/3"))
    end)
    test("WC05 unavailable, rejected and unconfirmed screenshots stay distinguishable and retryable",function()
        local f=start(); local native=f.env.Screenshot; f.env.Screenshot=nil; f.ui.Refresh()
        eq(control(f,"Start timer"):IsEnabled(),false); assert(shown(f,"Screenshot or timer unavailable.")); eq(#f.mock.timers,0)
        f.env.Screenshot=native; f.ui.Refresh(); press(f,"Start timer"); requestShot(f); result(f,"SCREENSHOT_FAILED")
        eq(f.seq.completed,0); assert(shown(f,"WoW reported a screenshot failure."))
        press(f,"Start timer"); requestShot(f); f.flush()
        eq(f.seq.completed,0); assert(shown(f,"WoW did not confirm the last shot.")); assert(control(f,"Start timer"):IsEnabled())
    end)
    test("WC06 cancelled native request drains before the shutter re-enables without a stray burst",function()
        local f=start(3); press(f,"Start burst"); requestShot(f); f.seq.Cancel()
        result(f); eq(f.seq.completed,0); eq(f.captures,1); assert(control(f,"Start burst"):IsEnabled())
        f.flush(); eq(f.captures,1); eq(f.seq.active,false)
    end)
    test("WC07 visiting Timer mid-pose countdown uses the running single shot and leaves burst preferences intact",function()
        local f=start(4); press(f,"Pose")
        local options=f.ns.Value.Copy(f.prefs); options.shots,options.delay=1,5
        assert(f.seq.Start(options)); press(f,"Capture"); assert(control(f,"Single shot").selected)
        assert(shown(f,"5 s")); assert(shown(f,"Shot 1 of 1")); eq(control(f,"4"),nil)
        press(f,"Cancel capture"); assert(control(f,"Burst").selected); assert(control(f,"4").selected)
        f.flush(); eq(f.prefs.shots,4); eq(f.prefs.delay,3); eq(f.captures,0)
        press(f,"Look"); assert(control(f,"Capture screenshot",f.c.bar)); eq(control(f,"Start burst"),nil)
    end)
    test("WC08 pending lighting finishes before the timer, clean captures retain filters, and Escape cancels",function()
        local f=start(); assert(f.r.photoEditor.Recipe("ember")); assert(f.r.photoPreview.Queue("Brightness",71))
        press(f,"Start timer"); eq(f.seq.state,"WAITING_FOR_PREVIEW"); assert(shown(f,"Finishing photo edits"))
        requestShot(f); eq(f.values.Brightness,"71"); eq(f.r.photoEffects.root:IsShown(),true)
        result(f); f.flush(); eq(f.captures,1); assert(shown(f,"Screenshot saved"))
        press(f,"Start timer"); f.c.input.scripts.OnKeyDown(f.c.input,"ESCAPE"); f.flush()
        eq(f.seq.active,false); eq(f.captures,1); eq(f.r.camera.active,false)
    end)
end
