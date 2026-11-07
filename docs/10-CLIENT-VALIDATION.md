# Client validation worksheet — not executed

**Target reported by Arctic:** 1.60.1.70790. **Date:** 2026-11-06. Every result below is **NOT RUN / Unknown**. These are human-run read-only commands and future test instructions, not addon implementation. Do not change settings, install files, reload/relog, benchmark, or run write experiments under the Phase 00 authorization.

## Immediate handoff — identity, getters and Brightness only

The architecture is accepted in principle. Actual client identity and separate Phase 01A implementation authorization are still required. In an already open Forever session, run each line separately, following these checks. If `/dump` or script execution is refused, stop and report the message; do not change a setting to enable it.

1. Check the function, then capture the complete build tuple only if the first line returns `function`:

```text
/dump type(GetBuildInfo)
/dump GetBuildInfo()
```

2. Check getter availability without invoking any writer:

```text
/dump C_CVar and type(C_CVar.GetCVar), C_CVar and type(C_CVar.GetCVarInfo)
/dump C_CVar and type(C_CVar.GetCVarDefault), C_CVar and type(C_CVar.AreCVarsLoaded)
```

3. Only if the functions above exist, check load readiness. If false, wait for ordinary login completion. If absent or refused, report it and stop this shortlist:

```text
/dump C_CVar.AreCVarsLoaded()
```

4. Once ready, read Brightness and its metadata:

```text
/dump pcall(C_CVar.GetCVar, "Brightness")
/dump pcall(C_CVar.GetCVarInfo, "Brightness")
/dump pcall(C_CVar.GetCVarDefault, "Brightness")
```

Return the exact outputs in this order, including nil/error results, plus the launcher's product label (no account name or full installation path). GetBuildInfo must include version, build, date and interface. The GetCVarInfo output after the initial pcall success flag is: current value, default, account-storage flag, character-storage flag, user-lock flag, secure flag, read-only flag. A successful read does not prove write permission or visible effect.

This shortlist makes no graphics writes, installs nothing and performs no reload/relog. The broader R1–R4 worksheet below remains available for later investigation; no future write experiment is authorized by this handoff.

## R1 — Identify the actual client

In an already open Forever session, run these individual chat commands. They read values and print locally; they do not send a chat message or change CVars. If script execution is refused, stop and record the refusal; do not enable a setting or bypass it. Do not assume `/dump` exists on every client.

```text
/dump type(GetBuildInfo)
/dump GetBuildInfo()
/dump WOW_PROJECT_ID, WOW_PROJECT_MAINLINE
```

Run the second command only if the first reports `function`. Record all returned version/build/date/interface fields verbatim. The expected build is 70790; **16001 is a candidate interface value**, not an observed result here. A numeric project ID by itself does not identify Forever. Privately inspect the launcher's product label and installation folder; report only the product and final folder name, not a personal absolute path. `_forever_` is the source-confirmed live-folder convention (SRC-14).

| Field | Result |
|---|---|
| Launcher product / executable basename | Unknown |
| Version / build / build date / interface tuple | Unknown; owner separately reports 1.60.1.70790 |
| Project ID / Mainline constant | Unknown |
| Addon loading enabled / out-of-date handling | Unknown |
| OS, GPU/driver, resolution, render scale, HDR state | Unknown; optional non-sensitive summary |

## R2 — Check APIs without calling mutators

```text
/dump C_CVar and type(C_CVar.GetCVar), C_CVar and type(C_CVar.GetCVarInfo)
/dump C_CVar and type(C_CVar.GetCVarDefault), C_CVar and type(C_CVar.AreCVarsLoaded)
/dump C_CVar and type(C_CVar.SetCVar), type(GetCVar), type(GetCVarInfo), type(SetCVar)
/dump type(InCombatLockdown), type(issecretvalue), type(canaccessvalue)
/dump type(CreateFrame), type(GetCursorPosition), type(PlaySoundFile), type(StopSound)
/dump Settings and type(Settings.RegisterCanvasLayoutCategory), Settings and type(Settings.RegisterAddOnCategory)
/dump C_VideoOptions and type(C_VideoOptions.IsSecondaryLightingSupported)
```

`type(SetCVar)` checks existence; it does not call it. If `AreCVarsLoaded` is a function, inspect it:

```text
/dump C_CVar.AreCVarsLoaded()
```

If false, wait for ordinary login completion; do not manufacture/register missing CVars. If the namespaced getters are absent, record that result and inspect available globals separately before any fallback. Do not treat nil as zero. A function's existence does not establish addon permissions.

## R3 — Read one CVar at a time

After R2 confirms these getter functions and CVars are loaded:

```text
/dump pcall(C_CVar.GetCVar, "Brightness")
/dump pcall(C_CVar.GetCVarInfo, "Brightness")
/dump pcall(C_CVar.GetCVarDefault, "Brightness")
```

Repeat the same three read commands, replacing only the quoted name, for C01–C26 and each explicit named key in C29–C36 of [02](02-CVAR-REGISTER.md). Start with the seven owner priorities; the longer inventory can be split into sessions. For C23 inspect both exact spellings without concluding case-insensitivity from a single successful read. C27/C28 and wildcard groups must first resolve specific public names; never query or dump unrelated configuration wholesale.

`pcall` adds an initial success boolean; for GetCVarInfo, the source lists the subsequent results in this order: value, defaultValue, isStoredServerAccount, isStoredServerCharacter, isLockedFromUser, isSecure, isReadOnly (SRC-10). Preserve nil positions and errors. A true pcall result with no value is not supported/writable evidence. Do not compare/stringify/export inaccessible or secret values; record them as inaccessible and stop that row.

If canonical spelling remains uncertain and `ConsoleGetAllCommands` is present, a separately reviewed read-only filter can enumerate just that name and help text. No enumeration harness is provided or executed in this phase. Do not use ConsoleExec as a fallback writer.

| Key | Getter result | Current raw string | Default raw string | Account/character flags | User-lock/secure/read-only | Build | Evidence |
|---|---|---|---|---|---|---|---|
| Each tested key | NOT RUN | U | U | U | U | U | None |

## R4 — Read-only observations and source reconciliation

Without moving sliders or pressing Apply/Defaults, inspect existing Graphics controls: brightness, contrast, gamma, sharpening, view distance, clutter, lighting and the raid-settings checkbox. Record displayed values, bounds if visible, disabled options and whether menu labels match readbacks. Do not infer native min/max or indirect behavior from the UI.

Record only relevant addon names/versions if an existing UI addon or brightness automation is enabled, particularly EllesmereUI and Dynamic Ambiance. Do not change their configuration. If values drift during ordinary use, note time/context and reread; do not attribute a writer without evidence. No combat or zone-change experiment is necessary for the Phase 00 read-only worksheet.

## Future experiments — separate approval required

No concrete write command is supplied here. Before W1, the reviewer must approve exact keys, targets, duration, environment and recovery instructions. The test runner must have a recovery card **outside volatile addon memory** containing the original raw value and exact key. Keep any full personal settings backup private and outside this repository.

1. **W1, one-key round trip:** outside combat, capture stable original; confirm flags; apply only the approved Brightness target; record setter result, immediate and settled readback, and a human visual comparison; restore exact original; verify again. If original already equals target, do not claim a meaningful round trip. Choose an alternative only after approval. Repeat actual-baseline 45 and non-45 cases when available, never manufacture a baseline silently.
2. **W2, conflicts and side effects:** after separate permission for menu/other-addon changes, compare a bounded set of related keys before/after. Change one menu control or one conflicting addon at a time. Exercise external drift before write, between writes, after verification and before restore. Verify that LumenShift yields and does not repeatedly enforce. Map raid/normal banks and known tier fan-out before admitting any quality tier.
3. **W3, persistence:** with explicit reload/relog/restart permission, use an authorized minimal future harness to test saved marker restoration at ADDON_LOADED, then CVar persistence and journal reconciliation. Test ordinary logout and full restart; do not deliberately crash the user's client in Phase 01. Crash loss is simulated off-client first. Record saved/loaded timing instead of assuming beta behavior.
4. **W4, restrictions:** initially test refusal/defer without calling setters in combat. Validate binding/focus safety and taint errors under an approved plan. Only separately approved experiments may investigate actual combat setter permissions; unrestricted flags do not prove combat eligibility.
5. **V1, UX/audio:** future original asset loading, OGG/WAV format trials, path/case, cold restart vs reload, playback handle, channel/mute behavior; overlay strata and UI visibility; scale/aspect ratios; click/Escape/keyboard; hold/release and gamepad only after separate API testing. No game sound is played in Phase 00.
6. **B1, performance:** see [05](05-TEST-PLAN.md); opt-in, one key at a time, matched scene and rollback. No invented safe maximum or FPS gain.

## Emergency recovery and evidence hygiene

Stop on unexpected values, blocked actions, inaccessible readbacks, major stutter, visual discomfort, or failed restoration. Stop competing writers only through an approved user action. Recover the single key from its captured card through the approved client method; never guess 45 or reset all graphics. If that fails, retain the failed record and stop the test series. A disabled addon cannot repair it later.

Return only build tuple, allowlisted CVar values/flags, test steps, observations and sanitized error text. Crop names/chat from any later screenshots before committing. Never publish account folders, Config.wtf, saved account data, machine usernames or credentials. Read-only results can upgrade existence/default/flag fields; only measured write/effect/restore tests can upgrade those separate fields.
