# Camera name eligibility — beta.8

**2026-11-09 · Northern Lights Labs**

## Reported failure and evidence

The owner's beta.7 diagnostic export identifies source `dadde59cf30acda7a7d8d71a62e3066d798f66db` and client `1.60.1:70862:16001`. Two wheel attempts reach `names.CanApply`, then return `UNSAFE_OBSERVATION:UnitNameFriendlyPetName`. Camera remains inactive, the HUD remains visible and the names journal is empty. The export reports both friendly-name values as 1, their secure/read-only/locked flags false, and `SetUIVisibility` available. An intervening Cinematic operation verifies Brightness 42 with original 45; the Camera refusal is in its separate name preflight.

**Verified from owner export:** Camera entry stopped before hiding the HUD or recording a name write. **Reproduced source defect:** the shared observation predicate requires both server-storage flags to be false. With a writable, server-stored friendly-pet-name observation, it reproduces this refusal. **Unconfirmed exact live cause:** beta.7 omitted those storage flags and the flag-read result for names. Its export cannot establish their exact values at the failed click, or exclude a transient read/metadata problem. Beta.8 adds those details rather than claiming a native pass.

## Named-build source check

Reviewed 2026-11-09 against the existing Forever 70862 UI-source pin `9dc84f0d3bbae1768ac3405b3716000bd93eda06`:

- [Generated CVar API, GetCVarInfo and SetCVar](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua#L78): the two server-storage booleans are distinct from locked, secure and read-only flags. The setter's listed predicates require a valid/public, non-read-only, non-secure CVar; server storage is not listed as a restriction. This confirms the metadata distinction, not the current pet-name flag values or a native setter result.
- [Native friendly-player-name checkbox](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Nameplates.lua#L404): the client UI registers `UnitNameFriendlyPlayerName` as a CVar checkbox. The existing two-key Camera scope comes from the owner's requested player/pet macro and [Camera design](30-CAMERA-MODE.md); this source is not evidence of a pet-name control in that file.

## Change

`Planner.ObservationError(observation, key)` separates read/numeric/flag failures from actual restrictions and storage policy. Only the two keys already listed in `NamePolicy` may have true server-account or server-character storage flags. Both flags must still be known booleans; secure, locked and read-only must all be false. Graphics and unkeyed checks retain their client-local policy. Descriptor admission and 0/1 name bounds still run independently.

The operation key follows the observation through the pure planner, returned-original checks, recovery/continuation, preparation, immediate/delayed verification, rollback and conflict observation. The manual Names toggle uses the same policy. No observation flags are rewritten or fabricated, and no planner/writer bypass is added. Capture-before-write, raw-string originals and independent visual/quality/manual-name state are preserved.

Diagnostic scans now check name eligibility separately from successful reads. The export includes `serverAccount`, `serverCharacter`, `flags`, `nameCheck`, and the last Camera error. All are allowlisted codes/booleans; no raw native error, personal identifier or chat is included. Scans call no setter.

Schema 12, NamePolicy descriptor version 4, existing saved settings, assets and the single native writer remain unchanged. Updating does not reset setup or operate the installed game.

## Validation

Eleven new simulated Lua 5.1 regressions cover character/account/both storage flags, wheel mouse/keyboard entry and visible exit, exact differently formatted mixed originals, explicit recovery after reload with no startup writes, external conflicts, second-setter failure and bounded compensation, real restrictions/unknown flags/invalid values, new restrictions after a write, read-only report detail, graphics-policy isolation, active Cinematic independence, and manual Names intent across Camera entry/exit.

Before the fix, nine of the first ten focused cases failed; the restrictions case passed. The first post-fix run exposed one test expecting asynchronous acceptance when the controller correctly returned a synchronous compensation failure; that assertion was corrected. All eleven focused cases then passed. Final validation: **441/441 Lua 5.1 mock tests**, **66 Lua files + four binding bodies** for syntax, **45 runtime modules** for TOC/version/single-writer checks, **10/10 packaging tests**, **112 current local documentation links** and whitespace checks passed. **No native beta.8 pass is claimed.**

## Install and retry

1. Fully exit WoW. Extract the beta.8 ZIP and replace the whole `LumenShift` folder under Forever's `Interface/AddOns`. Keep SavedVariables; do not reset setup.
2. Log in and open the LumenShift wheel. Click **Camera** (or press **7** while the wheel is open). With the existing Hide friendly names option enabled, the HUD and friendly-player/pet names should disappear; the Camera exit control should remain visible.
3. Click **Exit Camera Mode**. The HUD and previous independent name choices should return. A selected visual mode should remain unchanged.
4. If entry still fails, use **Studio > Diagnostic Center > Export**. The new name flags/check result and last Camera error distinguish a real restriction or unavailable read from storage metadata. Do not reset saved data to troubleshoot this refusal.

Native Alt+Z can bring the HUD back, but does not by itself restore Camera's name settings. Use the Camera exit control for the complete return. Full instructions: [21](21-BETA-USER-GUIDE.md); remaining integrated acceptance: [22](22-BETA-RELEASE-QA.md). No merge or public release is part of this update.
