local _, ns = ...
local L, W = {}, ns.Widgets
ns.WorldLightUI = L

local tone = {
    {key="Brightness", label="Brightness", image="light-brightness", low="Darker", high="Brighter", maximum=100, step=1},
    {key="Contrast", label="Contrast", image="light-contrast", low="Flatter", high="Stronger", maximum=100, step=1},
}
local detail = {
    {key="ResampleSharpness", label="Sharpness", image="light-sharpness", low="Softer", high="Sharper", maximum=100, step=5},
    {key="bloomUserMult", label="World bloom", image="light-bloom", low="Less glow", high="More glow", maximum=1, step=.2},
}

local function originals(runtime, parent)
    local session = runtime.db.camera.editor.session
    local columns = {{0, 138, "Game setting"}, {142, 78, "Original"}, {226, 84, "Current"}}
    for i, col in ipairs(columns) do
        local heading = W.Text(parent, col[3], col[1], 0, col[2], 12, W.colors.muted)
        if i > 1 then heading:SetJustifyH("RIGHT") end
    end
    W.Rule(parent, 0, -22, 310)
    local y = -31
    for _, item in ipairs({{"Brightness","Brightness"}, {"Contrast","Contrast"},
        {"ResampleAlwaysSharpen","Sharpening switch"}, {"ResampleSharpness","Sharpness (native)"}, {"bloomUserMult","World bloom"}}) do
        local key = item[1]
        local original = session and session.before[key]
        local observation = ns.ReadOnly.Read(runtime.reader, key)
        local raw = observation.code == "OK" and ns.Value.Number(observation.raw) and observation.raw
        W.Text(parent, item[2], 0, y, 138, 13)
        W.Text(parent, original or "—", 142, y, 78, 13, W.colors.accent):SetJustifyH("RIGHT")
        W.Text(parent, raw or "Unavailable", 226, y, 84, 13):SetJustifyH("RIGHT")
        y = y - 29
    end
    W.Text(parent, "Originals are captured on first edit and restored on exit.", 0, y-4, 310, 12, W.colors.muted)
    return y - 44
end

function L.Build(runtime, parent, page, liveSlider)
    if page == "Originals" then return originals(runtime, parent) end
    local editor = runtime.photoEditor
    W.Text(parent, editor.before and "Showing Before. Choose Show After to edit." or "Drag a strip to preview the change in the world.",
        0, 0, 310, 12, W.colors.muted)
    local y = -28
    for _, spec in ipairs(page == "Detail" and detail or tone) do
        local value, why = editor.Read(spec.key)
        if value and spec.key == "ResampleSharpness" then
            local enabled, reason = editor.Read("ResampleAlwaysSharpen")
            if enabled == nil then value, why = nil, reason
            else value = 100 - value*50 end
        end
        if value then
            liveSlider(spec, value, y)
            W.Text(parent, spec.low, 0, y-75, 145, 11, W.colors.muted)
            W.Text(parent, spec.high, 165, y-75, 145, 11, W.colors.muted):SetJustifyH("RIGHT")
        else
            W.Text(parent, spec.label, 0, y-5, 310, 14)
            W.Text(parent, why or "Unavailable on this client.", 0, y-33, 310, 12, W.colors.muted)
        end
        y = y - 101
    end
    return y
end
