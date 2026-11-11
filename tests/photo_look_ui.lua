-- Exercise the visible standalone editor, including the narrow layout shown by the owner.
return function(make,eq,test)
    local function button(f,label)
        for _,b in ipairs(f.mock.nodes) do
            if b.kind=="Button" and b:IsVisible() and b.label and b.label:GetText()==label then return b end
        end
    end
    local function click(f,label)
        f.mock.Click(label)
        assert(not f.ui.building,"panel build interrupted")
    end
    test("LSUI01 all six illustrative filters apply through the gallery and reflect undo",function()
        local f=make(); click(f,"Look"); eq(button(f,"Undo"):IsEnabled(),false)
        for _,pair in ipairs({{"Warm Ember","ember"},{"Cool Night","night"},{"Soft Portrait","portrait"},
            {"Sun Flare","sunflare"},{"Blue Hour","bluehour"},{"Neutral","neutral"}}) do
            click(f,pair[1]); assert(button(f,pair[1]).selected)
            eq(f.ns.PhotoConfig.Export(f.r.db.camera.editor.look),f.ns.PhotoConfig.Export(f.ns.PhotoConfig.Recipe(pair[2])))
        end
        click(f,"Undo"); assert(button(f,"Blue Hour").selected)
        click(f,"Redo"); assert(button(f,"Neutral").selected); eq(#f.calls,0)
    end)
    test("LSUI02 every Look page fits without wheel scrolling at both panel densities",function()
        local f=make(); click(f,"Look")
        for _,size in ipairs({{1280,800},{600,400},{1280,800}}) do
            f.env.UIParent:SetSize(unpack(size)); f.r.composition.Show()
            for _,page in ipairs({"Color","Vignette","Glow","Film"}) do
                click(f,page); eq(f.ui.scrollbar.maximum,0); eq(f.ui.scrollbar:IsShown(),false)
                assert(f.ui.contentHeight<=f.ui.scroll:GetHeight()+.01)
            end
            click(f,"Glow"); click(f,"Color mix"); eq(f.ui.scrollbar.maximum,0); click(f,"Shape")
        end
        eq(#f.calls,0)
    end)
    test("LSUI03 live percentage drag keeps one history entry and typed edits keep undo current",function()
        local f=make();click(f,"Look");local s=f.ui.sliders.warmth
        s.scripts.OnMouseDown(s);s:SetValue(30);s:SetValue(55);eq(f.r.db.camera.editor.look.warmth,.55)
        eq(f.ui.sliders.warmth,s);s.scripts.OnMouseUp(s);eq(#f.r.photoEditor.undo,1)
        click(f,"Undo");eq(f.r.db.camera.editor.look.warmth,0)
        s=f.ui.sliders.tint;s.edit:SetText("-32");s.edit.scripts.OnEnterPressed(s.edit)
        eq(f.r.db.camera.editor.look.tint,-.32);assert(button(f,"Undo"):IsEnabled())
        eq(button(f,"Neutral").selected,false);eq(#f.calls,0)
    end)
    test("LSUI04 placement maps use scaled cursor coordinates and undo both axes together",function()
        local f=make();click(f,"Look")
        for _,group in ipairs({{"Vignette","centerX","centerY"},{"Glow","glowX","glowY"}}) do
            click(f,group[1]);local pad=assert(button(f,"Place effect center"))
            pad.GetLeft=function() return 20 end;pad.GetTop=function() return 100 end
            pad.GetEffectiveScale=function() return 2 end
            f.env.GetCursorPosition=function() return 108,104 end
            click(f,"Place effect center")
            local look=f.r.db.camera.editor.look;eq(look[group[2]],.25);eq(look[group[3]],.75)
            click(f,"Undo");look=f.r.db.camera.editor.look;eq(look[group[2]],.5);eq(look[group[3]],.5)
        end
        eq(#f.calls,0)
    end)
    test("LSUI05 glow marker belongs to Shape and color controls apply live in combat",function()
        local f=make();click(f,"Look");click(f,"Glow");f.ui.sliders.glow:SetValue(80)
        eq(f.ui.marker:IsVisible(),true);click(f,"Color mix");eq(f.ui.marker:IsVisible(),false)
        f.env.InCombatLockdown=function() return true end
        click(f,"Ice");eq(f.r.db.camera.editor.look.glowB,1);eq(f.r.db.camera.editor.look.glowR,.3)
        f.ui.sliders.glowG:SetValue(40);eq(f.r.db.camera.editor.look.glowG,.4)
        click(f,"Film");eq(f.ui.sliders.glowG,nil);f.ui.sliders.grain:SetValue(3.5)
        eq(f.r.db.camera.editor.look.grain,.035);eq(#f.calls,0)
    end)
    test("LSUI06 capture and library show only actions for the selected task in either mode",function()
        local f=make();click(f,"Capture");assert(button(f,"Start timer"));eq(button(f,"Keep filters during combat"),nil)
        click(f,"Combat");assert(button(f,"Keep filters during combat"));eq(button(f,"Start timer"),nil)
        click(f,"Output");eq(button(f,"Start timer"),nil)
        click(f,"Saved");assert(button(f,"Save current"));click(f,"Share");assert(button(f,"Import pasted photo look"))
        click(f,"Compositions");assert(button(f,"Save current"));eq(button(f,"Apply look"),nil)
        click(f,"Portrait Stage");f.flush();click(f,"Capture");click(f,"Pair");assert(button(f,"Capture background + cast"))
        click(f,"Saved");click(f,"Save current");assert(button(f,"Save scene"))
        click(f,"Lights");click(f,"Save current");assert(button(f,"Save lighting setup"))
        click(f,"World Photo");click(f,"Capture");assert(button(f,"Start timer"));eq(button(f,"Pair"),nil)
        eq(f.env.Narci,nil);eq(#f.calls,0)
    end)
    test("LSUI07 coordinate entry retains typing during refresh and rejects out-of-range values",function()
        local f=make();click(f,"Look");click(f,"Glow")
        local fields={}
        for _,node in ipairs(f.mock.nodes) do
            if node.kind=="EditBox" and node:IsVisible() and node:GetWidth()==53 then fields[#fields+1]=node end
        end
        eq(#fields,2)
        table.sort(fields,function(a,b) return a.points[1][5]>b.points[1][5] end)
        for i,key in ipairs({"glowX","glowY"}) do
            local field=fields[i];field:SetFocus();field:SetText(tostring(20*i));f.ui.Refresh()
            eq(field:GetText(),tostring(20*i));field.scripts.OnEnterPressed(field)
            eq(f.r.db.camera.editor.look[key],.2*i)
            field:SetFocus();field:SetText("120");field.scripts.OnEnterPressed(field)
            eq(field:GetText(),tostring(20*i));eq(f.r.db.camera.editor.look[key],.2*i)
        end
        eq(#f.calls,0)
    end)
end
