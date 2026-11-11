return function(make,eq,test)
    local function control(f,label,parent)
        for _,b in ipairs(f.mock.nodes) do
            if b.kind=="Button" and b:IsVisible() and b.label and b.label:GetText()==label and (not parent or b.parent==parent) then return b end
        end
    end
    local function click(f,label,parent)
        local b=assert(control(f,label,parent),label); assert(b:IsEnabled(),label)
        b.scripts.OnClick(b,"LeftButton"); assert(not f.ui.building)
    end
    local function start(fallback)
        local f=make(fallback)
        click(f,"Portrait Stage"); f.flush(); click(f,"Capture")
        f.seq,f.prefs=f.r.captureSequence,f.r.db.camera.tools
        f.prefs.delay=0; f.ui.Refresh()
        assert(f.p.SetScene("background","gray")); assert(f.p.SetActor("paused",false))
        assert(f.r.photoEditor.Recipe("ember"))
        local screenshot=f.env.Screenshot
        f.images={}
        f.env.Screenshot=function()
            screenshot()
            local bg=f.p.backend.background.color
            f.images[#f.images+1]={shown=f.front().shown, paused=f.front().paused, green=bg[1]==0 and bg[2]==1 and bg[3]==0,
                filtered=f.r.photoEffects.root:IsVisible(), chrome=f.c.root:IsVisible()}
        end
        return f
    end
    local function request(f)
        for i=1,30 do if f.c.requested then break end; f.tick() end
        assert(f.c.requested); eq(f.c.root:IsVisible(),false)
    end
    local function result(f,event) f.c.root.scripts.OnEvent(f.c.root,event or "SCREENSHOT_SUCCEEDED") end
    local function restored(f)
        eq(f.p.frozen,nil); eq(f.p.layerCapture,nil); eq(f.front().shown,true); eq(f.front().paused,false)
        eq(f.r.db.camera.portrait.scene.background,"gray"); eq(f.p.backend.background.color[1],.35)
        eq(f.r.photoEffects.root:IsVisible(),true); eq(#f.calls,0)
    end
    test("SC01 all outputs, burst controls and advanced stage capture pages fit both panel sizes",function()
        local f=start()
        f.values.screenshotFormat,f.values.screenshotQuality="jpeg","8"
        f.values.ffxAntiAliasingMode,f.values.MSAAQuality,f.values.MSAAAlphaTest="0","0,0","0"
        for _,size in ipairs({{1280,800},{600,400}}) do
            f.env.UIParent:SetSize(unpack(size)); f.c.Show(); click(f,"Timer"); click(f,"Burst"); click(f,"5")
            for _,label in ipairs({"Full scene","Background","Cast","Pair","Output","JPEG","Antialiasing","Shadows","Combat"}) do
                click(f,label); eq(f.ui.scrollbar.maximum,0,label); eq(f.ui.scrollbar:IsShown(),false,label)
            end
        end
        eq(#f.images,0); restored(f); eq(f.env.Narci,nil); eq(f.env.NarciScreenshotToolbar,nil)
    end)
    test("SC02 full scene, background and cast-only shutters prepare exactly one correct frame on either renderer",function()
        for _,fallback in ipairs({false,true}) do
            local f=start(fallback)
            for _,label in ipairs({"Full scene","Background","Cast"}) do
                click(f,label); restored(f); click(f,"Take shot now",f.c.bar); request(f)
                local frame=f.images[#f.images]
                eq(frame.chrome,false); eq(frame.paused,true); eq(frame.shown,label~="Background")
                eq(frame.green,label=="Cast"); eq(frame.filtered,label=="Full scene")
                result(f); f.flush(); eq(f.seq.completed,1); restored(f)
            end
            eq(#f.images,3)
        end
    end)
    test("SC03 a timed pair holds one pose and confirms the backdrop before requesting the green cast",function()
        local f=start(); f.prefs.delay=3; click(f,"Pair")
        local panel=control(f,"Single pair").parent
        click(f,"Start pair timer",panel); eq(f.seq.remaining,3); eq(f.seq.total,2); restored(f)
        request(f); eq(f.seq.completed,0); eq(#f.images,1); eq(f.images[1].shown,false); eq(f.images[1].filtered,false)
        local frozen=f.p.frozen
        result(f); eq(f.seq.completed,1); eq(f.p.frozen,frozen); eq(f.front().paused,true)
        request(f); eq(#f.images,2); eq(f.images[2].green,true); eq(f.images[2].shown,true)
        eq(f.images[2].filtered,false); result(f); f.flush(); eq(f.seq.state,"COMPLETE"); restored(f)
    end)
    test("SC04 five pairs produce ten confirmed files and restore playback between pairs",function()
        local f=start(); f.prefs.interval=1; click(f,"Pair"); click(f,"Burst"); click(f,"5"); click(f,"Start pair burst",f.c.bar)
        for i=1,10 do
            request(f); eq(f.images[i].green,i%2==0); eq(f.images[i].shown,i%2==0); eq(f.images[i].paused,true)
            eq(f.images[i].chrome,false); result(f); eq(f.seq.completed,i)
            if i%2==0 and i<10 then eq(f.seq.state,"INTERVAL"); eq(f.seq.remaining,1); restored(f) end
        end
        f.flush(); eq(#f.images,10); eq(f.seq.total,10); eq(f.prefs.shots,5); eq(f.seq.state,"COMPLETE"); restored(f)
    end)
    test("SC05 failed or unconfirmed cast pass retains the confirmed background and stops the burst",function()
        for _,reason in ipairs({"SCREENSHOT_FAILED","CAPTURE_RESULT_UNOBSERVED"}) do
            local f=start(); click(f,"Pair"); click(f,"Burst"); click(f,"Start pair burst")
            request(f); result(f); request(f)
            if reason=="SCREENSHOT_FAILED" then result(f,reason) end
            f.flush(); eq(f.seq.state,reason); eq(f.seq.completed,1); eq(#f.images,2)
            assert(f.ui.status:GetText()~=""); restored(f)
        end
    end)
    test("SC06 cancel during first countdown, between passes and between pairs invalidates remaining work",function()
        local f=start(); f.prefs.delay=2; click(f,"Pair"); click(f,"Burst")
        click(f,"Start pair burst"); click(f,"Cancel capture",f.c.bar); f.flush(); eq(#f.images,0); restored(f)
        click(f,"Start pair burst"); request(f); result(f); f.p.CancelLayers(); f.flush()
        eq(#f.images,1); eq(f.seq.completed,1); eq(f.seq.state,"CANCELLED"); restored(f)
        click(f,"Start pair burst"); request(f); result(f); request(f); result(f)
        eq(f.seq.state,"INTERVAL"); click(f,"Stop burst"); f.flush(); eq(#f.images,3); eq(f.seq.completed,2); restored(f)
    end)
    test("SC07 leaving stage cancels scheduled passes and a world shutter cannot replay a stage layer",function()
        local f=start(); click(f,"Pair"); click(f,"Capture pair"); f.p.Exit(); f.flush()
        eq(f.seq.active,false); eq(#f.images,0); eq(f.p.backend.root:IsVisible(),false)
        f.env.Screenshot=function() f.captures=f.captures+1 end
        assert(f.r.camera.Exit()); f.flush(); assert(f.r.camera.Toggle()); f.flush(); click(f,"Capture")
        eq(control(f,"Pair"),nil); click(f,"Take shot now",f.c.bar); request(f); result(f); f.flush()
        eq(f.seq.output,"scene"); eq(f.seq.completed,1); eq(f.captures,1); eq(f.seq.Start(nil,"cast"),nil); eq(#f.calls,0)
    end)
    test("SC08 layer preparation and playback errors remain local and do not claim extra files",function()
        local f=start(); click(f,"Background")
        local hide=f.front().Hide; f.front().Hide=function() error("native hide") end
        click(f,"Take shot now"); eq(#f.images,0); eq(f.seq.active,false); restored(f); f.front().Hide=hide
        click(f,"Pair"); click(f,"Burst"); click(f,"Start pair burst")
        request(f); result(f); request(f); local pause=f.front().SetPaused
        f.front().SetPaused=function(m,v,...) if not v then error("native resume") end; return pause(m,v,...) end
        result(f); f.flush(); eq(f.seq.state,"STAGE_RESTORE_FAILED"); eq(f.seq.completed,2); eq(#f.images,2)
        assert(f.ui.status:GetText():find("playback",1,true)); eq(f.p.layerCapture,nil); eq(f.p.backend.background.color[1],.35)
        eq(f.r.db.camera.portrait.scene.actors[1].paused,false); eq(f.r.photoEffects.root:IsVisible(),true); eq(#f.calls,0)
    end)
end
