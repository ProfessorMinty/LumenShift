-- Owner's fallback macro returns Brightness to its captured original. Simulated.
return function(make, eq, test)
    local function savedLook(composite)
        local f = make(nil, { Brightness = "45", Contrast = "60" })
        assert(f.r.setup.Open()); assert(f.r.setup.SaveAndClose())
        if not composite then f.r.db.baseline.values.Contrast = nil end -- exercise legacy Brightness-only mode path
        if composite then
            f.r.db.config.studio.modes.cinematic.useContrast = true
            f.r.db.config.studio.modes.cinematic.contrast = 65
        end
        assert(f.r.product.Select("cinematic")); f.flush()
        eq(f.r.db.journal.entries.Brightness.originalRaw, "45")
        return f
    end
    test("OR01 saved Cinematic plus restored original permits the next explicit mode click", function()
        local f = savedLook(false)
        local g = make(f.r.db, { Brightness = "45", Contrast = "60" })
        g.frame.OnEvent(g.frame, "PLAYER_ENTERING_WORLD"); g.flush()
        eq(#g.calls, 0); eq(g.r.db.journal.entries.Brightness.lastVerifiedRaw, "42")
        assert(not g.r.setup.window or not g.r.setup.window:IsShown())
        assert(g.r.product.Select("nightVision")); g.flush(); eq(g.values.Brightness, "75")
        eq(g.r.db.journal.entries.Brightness.originalRaw, "45")
        assert(g.r.product.Select("natural")); g.flush(); eq(g.values.Brightness, "45")
        eq(next(g.r.db.journal.entries), nil); eq(#g.calls, 2)
    end)
    test("OR02 choosing Original after fallback only releases the stale record", function()
        local f = savedLook(false); local g = make(f.r.db, { Brightness = "45", Contrast = "60" })
        assert(g.r.product.Select("natural")); g.flush()
        eq(#g.calls, 0); eq(next(g.r.db.journal.entries), nil)
        eq(g.r.product.lastError, nil)
    end)
    test("OR03 fallback during the login can reconcile an exact original without restoring first", function()
        local f = savedLook(false); f.values.Brightness = "45"
        f.r.product.Observe(); eq(f.r.engine.Status().state, "CONFLICT")
        local count = #f.calls
        assert(f.r.product.Select("nightVision")); f.flush()
        eq(#f.calls, count + 1); eq(f.r.db.journal.entries.Brightness.originalRaw, "45")
    end)
    test("OR04 composite fallback reconciles both members without changing other quality settings", function()
        local f = savedLook(true); local g = make(f.r.db, { Brightness = "45", Contrast = "60", farclip = "5000" })
        assert(g.r.product.Select("nightVision")); g.flush()
        eq(g.values.Brightness, "75"); eq(g.values.Contrast, "60"); eq(g.values.farclip, "5000")
        eq(#g.calls, 1); eq(g.r.db.experiments.journal.entries.Contrast, nil)
        assert(g.r.product.Select("natural")); g.flush(); eq(g.values.Brightness, "45")
    end)
    test("OR05 uncertain failed pending and changed-build originals remain preserved", function()
        for _, fault in ipairs({ "pending", "failed", "signature", "descriptor", "different", "restricted" }) do
            local f = savedLook(false); local db = f.ns.Value.Copy(f.r.db)
            local entry = db.journal.entries.Brightness
            if fault == "pending" or fault == "failed" then entry.state = fault
            elseif fault == "signature" then entry.signature = "1.60.1:70790:16001"
            elseif fault == "descriptor" then entry.descriptorVersion = 999 end
            local g = make(db, { Brightness = fault == "different" and "55" or "45", Contrast = "60" })
            if fault == "restricted" then g.restricted = "Brightness" end
            eq(g.r.product.Select("nightVision"), nil); g.flush(); eq(#g.calls, 0)
            eq(g.r.db.journal.entries.Brightness.originalRaw, "45")
        end
    end)
    test("OR06 fresh setup opens and completed setup remains user-reopenable without writes", function()
        local f = make(); f.frame.OnEvent(f.frame, "PLAYER_ENTERING_WORLD"); f.flush()
        eq(f.r.setup.window:IsShown(), true); eq(#f.calls, 0)
        assert(f.r.setup.SaveAndClose())
        local g = make(f.r.db); g.frame.OnEvent(g.frame, "PLAYER_ENTERING_WORLD"); g.flush()
        assert(not g.r.setup.window or not g.r.setup.window:IsShown()); assert(g.r.setup.Open()); eq(g.r.setup.window:IsShown(), true)
        eq(#g.calls, 0)
    end)
    test("OR07 fresh preflight drift after the original match prevents the setter", function()
        local f = savedLook(false); local g = make(f.r.db, { Brightness = "45", Contrast = "60" })
        local get, reads = g.env.C_CVar.GetCVar, 0
        g.env.C_CVar.GetCVar = function(key)
            if key == "Brightness" then
                reads = reads + 1
                if reads >= 3 then g.values.Brightness = "55" end
            end
            return get(key)
        end
        eq(g.r.product.Select("nightVision"), nil); g.flush()
        eq(#g.calls, 0); eq(g.values.Brightness, "55")
        eq(g.r.db.journal.entries.Brightness.originalRaw, "45")
    end)
    test("OR08 byte-exact originals remain required and failed completed records are not silently cleared", function()
        for _, fault in ipairs({ "format", "failure" }) do
            local f = savedLook(false); local db = f.ns.Value.Copy(f.r.db)
            if fault == "failure" then db.journal.entries.Brightness.failure = "UNVERIFIED_FAILURE" end
            local g = make(db, { Brightness = fault == "format" and "045.00" or "45", Contrast = "60" })
            eq(g.r.product.Select("nightVision"), nil); g.flush(); eq(#g.calls, 0)
            eq(g.r.db.journal.entries.Brightness.originalRaw, "45")
        end
    end)
end
