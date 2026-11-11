return function(make, eq, test)
    local function button(f,label)
        for _,node in ipairs(f.mock.nodes) do
            if node.kind=="Button" and node:IsVisible() and node.label and node.label:GetText()==label then return node end
        end
    end
    local function click(f,label)
        local b=assert(button(f,label),"Missing "..label); assert(b:IsEnabled(),label)
        b.scripts.OnClick(b,"LeftButton"); assert(not f.ui.building,"Interrupted library build")
    end
    local function field(f)
        for _,node in ipairs(f.mock.nodes) do if node.kind=="EditBox" and node:IsVisible() then return node end end
        error("Missing library text box")
    end
    local function save(f,name,unit)
        click(f,"Save current"); field(f):SetText(name); click(f,"Save "..unit)
        assert(button(f,name).selected)
    end
    local function fits(f)
        eq(f.ui.scrollbar.maximum,0); eq(f.ui.scrollbar:IsShown(),false); eq(f.ui.scroll:GetVerticalScroll(),0)
    end
    test("SL01 visible save, find and apply actions keep looks and compositions independent",function()
        local f=make(); local db=f.r.db.camera
        f.zoom=12.5; f.env.GetCameraZoom=function() return f.zoom end
        f.env.CameraZoomIn=function(n) f.zoom=f.zoom-n end
        f.env.CameraZoomOut=function(n) f.zoom=f.zoom+n end
        assert(f.r.photoEditor.Recipe("ember")); click(f,"Saved"); save(f,"Campfire","look")
        db.thirds,db.aspect=true,"cinema"; click(f,"Compositions"); save(f,"Campfire","composition")
        eq(#f.calls,0)
        f.values.cameraFov="80"; f.zoom=16; db.thirds,db.aspect=false,"none"
        assert(f.r.photoEditor.Recipe("night")); click(f,"Looks"); field(f):SetText("FIRE")
        click(f,"Campfire"); eq(db.editor.look.warmth,-.5); click(f,"Apply look")
        eq(db.editor.look.warmth,.55); eq(f.zoom,16); eq(db.aspect,"none"); eq(#f.calls,0)
        click(f,"Compositions"); click(f,"Apply composition"); eq(f.ui.status:GetText(),"Applying composition…")
        eq(button(f,"Apply composition"):IsEnabled(),false); f.flush()
        eq(f.ui.status:GetText(),"Composition applied."); eq(db.aspect,"cinema"); eq(db.thirds,true)
        eq(f.values.cameraFov,"90"); eq(f.zoom,12.5); eq(db.editor.look.warmth,.55)
        eq(f.env.Narci,nil); eq(f.env.NarciScreenshotToolbar,nil)
    end)
    test("SL02 preexisting full banks survive reload and every page fits at both panel sizes",function()
        local seed=make()
        for i=1,12 do assert(seed.r.photoEditor.Save(string.format("Look %02d",i))) end
        for i=1,8 do assert(seed.r.photoComposition.Save(string.format("View %02d",i))) end
        local f=make(false,seed.ns.Value.Copy(seed.r.db)); click(f,"Saved")
        for _,size in ipairs({{1280,800},{600,400}}) do
            f.env.UIParent:SetSize(unpack(size)); f.c.Show()
            for _,group in ipairs({{"Looks","Look",12},{"Compositions","View",8}}) do
                click(f,group[1])
                while button(f,"Previous") and button(f,"Previous"):IsEnabled() do click(f,"Previous") end
                for i=1,group[3],3 do
                    fits(f)
                    for n=1,group[3] do
                        local row=button(f,string.format("%s %02d",group[2],n))
                        eq(row~=nil,n>=i and n<i+3)
                    end
                    if i+3<=group[3] then click(f,"Next") end
                end
                click(f,"Save current"); fits(f); click(f,"Back")
            end
            click(f,"Share"); fits(f)
        end
        eq(#f.calls,0); eq(f.captures,0)
    end)
    test("SL03 literal live search preserves typing focus, look state and independent queries",function()
        local f=make(); assert(f.r.photoEditor.Save("Fire [%]")); assert(f.r.photoEditor.Save("Night"))
        assert(f.r.photoComposition.Save("Other")); click(f,"Saved"); local q=field(f)
        q:SetFocus(); q:SetText("[%]"); eq(f.mock.focus,q); assert(button(f,"Fire [%]").selected)
        eq(button(f,"Night"),nil); eq(button(f,"Next"),nil)
        q:SetText("absent"); assert(button(f,"Clear search")); eq(button(f,"Apply look"),nil); fits(f)
        click(f,"Clear search"); eq(q:GetText(),""); q:SetText("FiRe")
        click(f,"Compositions"); eq(field(f):GetText(),""); field(f):SetText("other")
        click(f,"Looks"); eq(field(f):GetText(),"FiRe"); assert(button(f,"Fire [%]").selected)
        eq(#f.r.photoEditor.undo,0); eq(#f.calls,0); eq(f.captures,0)
    end)
    test("SL04 new saves are revealed under an unrelated filter and replacement works at capacity",function()
        local f=make()
        for i=1,11 do assert(f.r.photoEditor.Save(string.format("Look %02d",i))) end
        click(f,"Saved"); field(f):SetText("01"); save(f,"Zebra","look")
        eq(field(f):GetText(),""); assert(button(f,"Zebra").selected)
        assert(f.r.photoEditor.Recipe("bluehour")); click(f,"Save current")
        local name=field(f); name:SetText("Extra"); eq(button(f,"Save look"):IsEnabled(),false)
        click(f,"Use selected name"); eq(name:GetText(),"Zebra"); click(f,"Replace look")
        eq(f.r.db.camera.editor.saved.Zebra.warmth,-.3); eq(#f.ns.Value.Keys(f.r.db.camera.editor.saved),12)
        eq(#f.calls,0)
    end)
    test("SL05 deleting a filtered or last-page entry removes only its exact key and category",function()
        local f=make()
        for _,name in ipairs({"A","B","Camp","camp"}) do assert(f.r.photoEditor.Save(name)) end
        assert(f.r.photoComposition.Save("camp")); click(f,"Saved"); click(f,"Next")
        assert(button(f,"camp").selected); click(f,"Delete")
        eq(button(f,"Next"),nil); eq(f.r.db.camera.editor.saved.camp,nil); assert(f.r.db.camera.editor.saved.Camp)
        assert(f.r.db.camera.composition.saved.camp)
        field(f):SetText("Camp"); click(f,"Delete"); eq(button(f,"Apply look"),nil)
        click(f,"Clear search"); assert(button(f,"A")); assert(button(f,"B"))
        click(f,"Compositions"); click(f,"Delete"); eq(f.r.db.camera.composition.saved.camp,nil); eq(#f.calls,0)
    end)
    test("SL06 guide-only compositions and existing names apply on a client without zoom or framing reads",function()
        local f=make(); local db=f.r.db.camera; db.aspect,db.thirds="square",true
        f.env.GetCameraZoom=nil; for _,key in ipairs(f.ns.Framing.Keys) do f.values[key]=nil end
        click(f,"Saved"); click(f,"Compositions"); save(f,"Square","composition")
        eq(next(db.composition.saved.Square.framing),nil); eq(db.composition.saved.Square.zoom,nil)
        db.aspect,db.thirds="none",false; click(f,"Apply composition"); f.flush()
        eq(db.aspect,"square"); eq(db.thirds,true); eq(#f.calls,0)
    end)
    test("SL07 failed asynchronous apply is reported without claiming success or changing the look",function()
        local f=make(); f.env.GetCameraZoom=function() return 9 end
        assert(f.r.photoComposition.Save("Zoom")); f.env.GetCameraZoom=function() return 20 end
        f.env.CameraZoomIn=nil; click(f,"Saved"); click(f,"Compositions"); click(f,"Apply composition"); f.flush()
        eq(f.r.photoComposition.status,"ZOOM_UNAVAILABLE"); eq(f.ui.status:GetText(),f.ns.Product.Message("ZOOM_UNAVAILABLE"))
        eq(f.r.db.camera.editor.look.warmth,0); eq(button(f,"Apply composition"):IsEnabled(),true)
        click(f,"Looks"); eq(f.ui.status:GetText(),"")
    end)
    test("SL08 Share preserves bad pasted input, supports valid looks and stays separate from staged scenes",function()
        local f=make(); click(f,"Saved"); click(f,"Share"); local s=field(f)
        s:SetText("broken"); click(f,"Import pasted photo look"); eq(field(f):GetText(),"broken")
        eq(f.ui.status:GetText(),"Could not import this photo look.")
        s:SetText(f.ns.PhotoConfig.Export(f.ns.PhotoConfig.Recipe("ember"))); click(f,"Import pasted photo look")
        eq(f.r.db.camera.editor.look.warmth,.55); click(f,"Looks"); save(f,"Shared","look")
        click(f,"Portrait Stage"); f.flush(); click(f,"Saved"); assert(button(f,"Save / replace scene")); eq(button(f,"Save current"),nil)
        click(f,"World Photo"); click(f,"Saved"); assert(button(f,"Shared")); eq(#f.calls,0)
    end)
    test("SL09 typed names, cancel and Show After operate on the current library and active comparison",function()
        local f=make(); click(f,"Saved"); click(f,"Save current")
        local name=field(f); name:SetText("bad|name"); eq(button(f,"Save look"):IsEnabled(),false)
        name.scripts.OnEnterPressed(name); eq(next(f.r.db.camera.editor.saved),nil)
        name:SetText("Unfinished"); click(f,"Back"); assert(not f.r.db.camera.editor.saved.Unfinished)
        click(f,"Save current"); name=field(f); local long=string.rep("W",32); name:SetText(long)
        name.scripts.OnEnterPressed(name); assert(button(f,long).selected)
        assert(f.r.photoEditor.Compare()); click(f,"Apply look"); eq(f.r.photoEditor.before,true)
        click(f,"Show After"); eq(f.r.photoEditor.before,false); eq(button(f,"Show After"),nil); eq(#f.calls,0)
    end)
end
