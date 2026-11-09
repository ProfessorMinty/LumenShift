local _, ns = ...
local P = {}; ns.PhotoCompatibility = P
-- Optional UI coordination only. Never call another addon's graphics restore,
-- change its saved preferences, or use it to provide a photo feature.
function P.New(runtime)
    local env, reader = runtime.reader.env, runtime.reader
    local self = { state = "STANDALONE", active = false }
    local function shown(frame)
        local r = ns.ReadOnly.Call(reader, frame and frame.IsShown, frame)
        return r and r[1] == true
    end
    local function studio()
        local bar = env.NarciScreenshotToolbar
        return shown(env.Narci_Character) or shown(bar) and (bar.layout == "PhotoMode" or bar.layout == "Narcissus")
    end
    function self.Prepare()
        if studio() then self.state = "OTHER_PHOTO_STUDIO_ACTIVE"; return nil, self.state end
        self.frame, self.suppressed = nil, false
        self.active = true
        self.state = env.NarciScreenshotToolbar and "COEXISTING" or "STANDALONE"
        return true
    end
    function self.Clean()
        if not self.active then return true end
        if studio() then self.state = "OTHER_PHOTO_STUDIO_ACTIVE"; return nil, self.state end
        local bar = env.NarciScreenshotToolbar
        if not bar or bar.layout ~= "Blizzard" then return true end
        if shown(bar) then
            local ok = ns.ReadOnly.Call(reader, bar.Hide, bar)
            if not ok or shown(bar) then self.state = "OTHER_TOOLBAR_VISIBLE"; return nil, self.state end
            self.frame, self.suppressed, self.state = bar, true, "PASSIVE_TOOLBAR_HIDDEN"
        end
        return true
    end
    function self.AfterHide()
        self.Clean()
        local bar = env.NarciScreenshotToolbar
        if bar and type(bar.HookScript) == "function" and self.hooked ~= bar then
            local ok = ns.ReadOnly.Call(reader, bar.HookScript, bar, "OnShow", function() if self.active then self.Clean() end end)
            if ok then self.hooked = bar end
        end
        -- Native HUD hooks may have changed names even when their toolbar is hidden.
        runtime.names.Observe()
    end
    function self.BeforeShow()
        self.active = false
        -- Let the native HUD-show hook run the foreign session's ordinary cleanup.
        -- Raw Show does not invoke ShowUI or its graphics initialization.
        if self.suppressed and self.frame == env.NarciScreenshotToolbar and self.frame.layout == "Blizzard" then
            ns.ReadOnly.Call(reader, self.frame.Show, self.frame)
        end
        self.suppressed, self.frame = false, nil
    end
    function self.AfterShow()
        if not env.NarciScreenshotToolbar then return end
        runtime.names.Observe(); runtime.framing.Observe()
        -- Observe a possible delayed foreign restore; never fight or retry it.
        ns.ReadOnly.Call(reader, env.C_Timer and env.C_Timer.After, 0.8, function()
            runtime.names.Observe(); runtime.framing.Observe()
        end)
    end
    return self
end
