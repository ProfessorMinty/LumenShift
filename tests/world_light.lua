return function(make, eq, test)
    local function click(f, label)
        f.mock.Click(label)
        assert(not f.ui.building, "Interrupted build on "..label)
    end
    local function start()
        local f = make()
        f.env.C_VideoOptions.IsLinearEnabledOnStart = function() return true end
        f.values.ResampleAlwaysSharpen, f.values.ResampleSharpness, f.values.bloomUserMult = "0", "1.0", "0.4"
        click(f, "Light")
        return f
    end
    local function visible(f, label)
        for _, node in ipairs(f.mock.nodes) do
            if node.kind == "FontString" and node:IsVisible() and node:GetText() == label then return node end
        end
    end
    local function drag(f, key, value)
        local track = assert(f.ui.sliders[key])
        track.scripts.OnMouseDown(track); track:SetValue(value)
        return track
    end
    test("WL01 lighting pages fit both panel sizes with the appropriate standalone controls", function()
        local f=start()
        for _, size in ipairs({{1280,800},{600,400}}) do
            f.env.UIParent:SetSize(unpack(size)); f.c.Show()
            for _, page in ipairs({"Tone","Detail","Originals"}) do
                click(f,page); eq(f.ui.scrollbar.maximum,0); eq(f.ui.scrollbar:IsShown(),false)
                eq(f.ui.sliders.Brightness ~= nil,page=="Tone"); eq(f.ui.sliders.ResampleSharpness ~= nil,page=="Detail")
                assert(visible(f,"Restore lighting")); eq(visible(f,"Reset photo look"),nil)
            end
        end
        click(f,"Portrait Stage"); f.flush(); click(f,"Light"); assert(visible(f,"Rig")); eq(visible(f,"Restore lighting"),nil)
        click(f,"World Photo"); click(f,"Light"); eq(f.ui.worldLightPage,"Originals"); assert(visible(f,"Game setting"))
        click(f,"Look"); assert(visible(f,"Reset photo look")); eq(visible(f,"Restore lighting"),nil)
        eq(#f.calls,0); eq(f.env.Narci,nil)
    end)
    test("WL02 each illustrated strip applies multiple verified values with the pointer still held", function()
        local f=start()
        for _, item in ipairs({{"Tone","Brightness",65,"65",71,"71"},{"Tone","Contrast",74,"74",68,"68"},
            {"Detail","ResampleSharpness",75,"0.5",90,"0.2"},{"Detail","bloomUserMult",.6,"0.6",.8,"0.8"}}) do
            local page,key=item[1],item[2]; click(f,page)
            local track=drag(f,key,item[3]); f.flush(); eq(f.values[key],item[4])
            eq(track:GetHeight(),34); eq(f.ui.dragging,track); eq(f.ui.sliders[key],track)
            track:SetValue(item[5]); f.flush(); eq(f.values[key],item[6]); eq(f.ui.dragging,track)
            track.scripts.OnMouseUp(track); eq(f.ui.dragging,nil)
        end
        eq(f.values.ResampleAlwaysSharpen,"1")
    end)
    test("WL03 switching lighting pages during a pending gesture retains the latest requested endpoint", function()
        local f=start(); local s=drag(f,"Brightness",71); f.tick()
        s:SetValue(83); click(f,"Detail"); click(f,"Tone")
        eq(f.ui.dragging,nil); eq(f.ui.sliders.Brightness:GetValue(),83)
        f.flush(); eq(f.values.Brightness,"83"); eq(f.ui.sliders.Brightness:GetValue(),83)
    end)
    test("WL04 restore from any light page drains edits and returns exact originals without clearing the filter", function()
        local f=start(); f.values.Brightness="045.00"; f.ui.Build()
        assert(f.r.photoEditor.Recipe("ember"))
        local s=drag(f,"Brightness",72); s.scripts.OnMouseUp(s); f.flush()
        click(f,"Originals"); assert(visible(f,"045.00")); assert(visible(f,"72"))
        click(f,"Detail"); s=drag(f,"ResampleSharpness",85); s.scripts.OnMouseUp(s)
        click(f,"Restore lighting"); f.flush()
        eq(f.values.Brightness,"045.00"); eq(f.values.ResampleSharpness,"1.0"); eq(f.values.ResampleAlwaysSharpen,"0")
        eq(f.r.db.camera.editor.session,nil); eq(f.r.db.camera.editor.look.warmth,.55)
    end)
    test("WL05 blocked native detail controls leave Tone available and never write on navigation", function()
        local f=start(); f.values.ResampleAlwaysSharpen=nil; f.env.C_VideoOptions.IsLinearEnabledOnStart=nil
        click(f,"Detail"); eq(f.ui.sliders.ResampleSharpness,nil); eq(f.ui.sliders.bloomUserMult,nil)
        eq(f.ui.scrollbar.maximum,0); click(f,"Originals"); eq(#f.calls,0); eq(#f.mock.timers,0)
        click(f,"Tone"); local s=drag(f,"Brightness",67); f.flush()
        eq(f.values.Brightness,"67"); s.scripts.OnMouseUp(s)
    end)
    test("WL06 verification preserves the next typed input until Enter", function()
        local f=start(); local s=drag(f,"Brightness",72); s.scripts.OnMouseUp(s)
        local field=f.ui.sliders.Contrast.edit; field:SetFocus(); field:SetText("64")
        f.flush(); eq(f.mock.focus,field); eq(field:GetText(),"64")
        field.scripts.OnEnterPressed(field); f.flush(); eq(f.values.Contrast,"64")
    end)
    test("WL07 restore preserves an external lighting edit and offers its captured original for recovery", function()
        local f=start(); local s=drag(f,"Brightness",70); f.flush(); s.scripts.OnMouseUp(s)
        s=drag(f,"Contrast",77); f.flush(); s.scripts.OnMouseUp(s)
        f.values.Brightness="61"; f.r.photoEditor.Observe()
        click(f,"Restore lighting"); f.flush(); eq(f.values.Brightness,"61"); eq(f.values.Contrast,"60")
        eq(f.r.db.camera.editor.session.state,"recovery"); click(f,"Originals")
        assert(visible(f,"52")); assert(visible(f,"61"))
    end)
end
