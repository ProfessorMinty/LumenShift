local _, ns = ...
local A = {}
ns.Audio = A
function A.New(reader)
    local env, handle = reader.env
    local self = { lastError = nil }
    function self.Stop()
        if handle and type(env.StopSound) == "function" then pcall(env.StopSound, handle) end
        handle = nil
    end
    function self.Play(cue, config)
        self.Stop()
        if not config.preferences.sound then return true end
        if cue ~= "on" and cue ~= "off" then return nil, "INVALID_CUE" end
        local suffix = config.studio.audioLevel == "normal" and "normal" or "soft"
        local result, code = ns.ReadOnly.Call(reader, env.PlaySoundFile,
            "Interface/AddOns/LumenShift/Media/night-" .. cue .. "-" .. suffix .. ".wav", "SFX")
        if not result or result.n ~= 2 or result[1] ~= true or not ns.Value.Finite(result[2]) then
            self.lastError = code or "AUDIO_UNAVAILABLE_OR_MUTED"; return nil, self.lastError
        end
        handle, self.lastError = result[2], nil
        return true
    end
    function self.Transition(previous, current, config)
        if current == "nightVision" and previous ~= current then return self.Play("on", config) end
        if previous == "nightVision" and current ~= previous then return self.Play("off", config) end
        return true
    end
    return self
end
