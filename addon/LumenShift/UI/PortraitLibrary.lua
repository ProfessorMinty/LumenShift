local _, ns = ...
local U,W,L = {},ns.Widgets,ns.PortraitLibrary; ns.PortraitLibraryUI=U
function U.Build(runtime,env,parent,ui,y,selected)
    local stage=runtime.portrait
    if ui.actorTab=="Effects" then
        W.Text(parent,"Select a model spell effect.",0,y,310,12,W.colors.muted); y=y-32
        if not stage.backend.Supports(stage.backend.models[selected.front],"spellKit") then
            W.Text(parent,"This renderer does not support replaceable model spell effects. Other portrait tools remain available.",0,y,310,12,W.colors.muted); return y-66
        end
        for i,entry in ipairs(L.Kits) do
            local id=entry[1]
            local b=W.Button(env,parent,entry[2],(i-1)%2*156,y-math.floor((i-1)/2)*32,153,function() stage.SetActor("spellKit",id) end)
            b.SetSelected(selected.spec.spellKit==id)
        end
        y=y-math.ceil(#L.Kits/2)*32
    elseif ui.actorTab=="Outfits" then
        return ns.StageOutfitsUI.Build(runtime,env,parent,ui,y,selected)
    end
    return y
end
