# Build 70840 report, setup correction and actual product scope

> **Interaction update, dev.5 (2026-11-07):** [Usable setup and direct controls](26-USABLE-SETUP-AND-CONTROLS.md) supersedes the wizard/unlock/session-calibration requirements below. Historical observations remain valid for their recorded build. Use the [current guide](21-BETA-USER-GUIDE.md).

Observed 2026-11-06. Development version 0.2.0-dev.4; schema 4 unchanged.

## What Arctic actually tested

**Verified in-client, owner-provided diagnostic report:** addon 0.2.0-dev.3, source `6e88d1887a2721c15fb36ee6fd7c1dc1c715cfea`, on Forever **1.60.1:70840:16001**, build date Nov 5 2026, renderer d3d12. Brightness was 45 and Contrast 60. The report's fresh watched CVar reads returned OK with secure, read-only, locked, server-account and server-character flags false. Named native getter/readiness functions, the setter availability check, timer and ReloadUI functions were present. Function availability does not prove successful native execution.

The addon initialized Studio, radial menu, minimap entry and native Settings registration. Arctic saw and advanced the setup wizard and successfully exported/copied the report. Arctic described its layout/readability, controls/wording and step sequence as strange. Frame initialization and texture API acceptance do not certify visible quality, layering or input behavior.

Clicking Finish reached `product.operation UNSUPPORTED_BUILD` before requesting reload. The allowlist only contained 70790. Setup remained incomplete and controls disabled. Both engines reported BASELINE, with no ownership/recovery records and no graphics writes in the session history. This report supports **a setup compatibility failure**, not a failed native ReloadUI operation. No owner version reconfirmation is needed.

The report also contained stale startup checks: ADDON_LOADED ran before CVars were ready, producing CVARS_NOT_LOADED and downstream NONNUMERIC_ORIGINAL results. Fresh export observations were already readable, but the old summary remained blocked. Dev.4 refreshes read-only checks at PLAYER_ENTERING_WORLD and immediately before export. Transient startup observations remain in bounded history; current results are identified separately. An unreadable calibration observation reports its actual read error before numeric validation.

## Exact-build decision and sources

**Source-confirmed in a named UI mirror, inspected 2026-11-06:** Gethe's Blizzard UI source [commit 5987a8e2304c1331346dc861d5ccacf4c510cf0f](https://github.com/Gethe/wow-ui-source/commit/5987a8e2304c1331346dc861d5ccacf4c510cf0f) is labeled 1.60.1 (70840), directly following 70790 commit `eac30af597e5aaa43a60f6675ef5fdcea100375f`. Its complete five-file diff changes CharacterSelect.lua, SocialToast.lua, SubscriptionInterstitialUI Lua/XML, and version.txt. The relevant [CVar declarations](https://github.com/Gethe/wow-ui-source/blob/5987a8e2304c1331346dc861d5ccacf4c510cf0f/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua), [graphics settings definitions](https://github.com/Gethe/wow-ui-source/blob/5987a8e2304c1331346dc861d5ccacf4c510cf0f/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua), ReloadUI example and minimap source are unchanged in this mirror. This is not a native engine binary comparison or Blizzard compatibility guarantee.

**Engineering decision/inference:** combine that source comparison with the owner's actual 70840 identity, readable values and unrestricted flags to permit the existing **explicit experimental** controls on the exact `1.60.1:70840:16001` tuple. Keep the previously reviewed `1.60.1:70790:16001` tuple. No wildcard, minimum-build rule, new CVar, wider numeric range, production promotion or inferred write test is introduced.

`Compatibility.lua` is the single private exact-signature registry. Catalog, Product, reports and both writing paths consult it. The build manifest derives its experimental targets from this registry. `futureWrites` and the shipped production catalog remain false/unadmitted; those legacy fields refer to production admission, not explicit experimental actions. Existing Brightness descriptor policy IDs refer to the earlier test design; they do **not** grant 70840 that earlier native test's evidence.

Each engine captures its session signature. A changed identity invalidates proposals and follow-up verification, even when both identities are reviewed. Historical journals keep their original signature; cross-build restoration is refused without retagging, clearing or overwriting originals. Unknown builds/interfaces/versions remain read-only. A client patch with unresolved ownership therefore needs review of the recorded original; it cannot silently authorize recovery on the new client. Setter availability, flags, fresh reads, combat, planner, ownership, conflict and recovery checks remain in force.

## Revised wizard

1. **Welcome:** explain actual development scope and show compatibility/readiness before preferences. No raw UNSUPPORTED_BUILD surprise at Finish.
2. **Preferences:** six larger cards with a plain label, explanatory sentence and separate ON/OFF state. Effects, sound, menu animation, reduced motion, contrast and launcher remain independent choices. Reduced motion's precedence is explained.
3. **Review:** summarize choices, show current Brightness, explain restoration in plain language, and offer the explicit Finish & Reload UI action. Back retains drafts; Close/Set up later discard them. No mode is selected during setup/reload.

The window uses larger text, consistent spacing and a scale calculated against inherited UI scale and available space. Unsupported/unready clients start with switching off, explain why, and can still save read-only preferences and deliberately reload. Trying to enable an unavailable capability gives a readable reason. Finish rechecks readiness; it never silently grants permission or schedules a later write. Existing completed setups are preserved; reopen via Settings if desired.

This is an implementation and simulated layout/flow correction. Three pages of exported mock frame geometry were rendered and visually inspected with approximate desktop fonts; card/background contrast was corrected during that review. **Dev.4 native rendering, Finish/reload and preference persistence are not yet verified.** Off-client frame geometry is not a game screenshot or proof of native font metrics, texture decoding or addon coexistence.

## Does this include the whole requested product?

**No. It does more than Brightness, but it is not the accepted feature-complete beta.**

| Area | Current implementation | Remaining limit |
| --- | --- | --- |
| Night Vision | Brightness target 75; capture actual original; readback; exact restoration; recovery/conflict handling | Earlier 70790 round trip verified in-client; dev.4/70840 writes not yet tested |
| Six visual modes | Natural, Night Vision, Cinematic, Lantern, Clarity, Moonlight; editable settings and optional UI tint/vignette/letterbox | Authored appearances and non-75 Brightness targets need explicit experimental opt-in and native evaluation; no world shader/LUT processing |
| Access/configuration | Setup, launcher, minimap/Settings, icon wheel, keybindings, eight-page Studio, accessibility and personal presets | Native polish, wheel/input/layering and coexistence acceptance incomplete; no hold-and-release wheel |
| Audio | Original Night Vision activation/deactivation cues, volume/preferences, explicit preview | Defaults muted; native playback and mix acceptance incomplete |
| Contrast | Optional per-mode exact target after explicit calibration | Calibration must pass in the current login; no automatic admission from readable values |
| Sharpening, foliage, view distance, LOD, bloom/weather leaves | Named bounded experiments with capture/readback/restore; exact-target session certificates | Experimental, no blanket safe-domain or dependency guarantee; no native performance claims |
| Quality profiles | Independent Current Baseline, Balanced, Vista, Performance model and user-configured tested target sets | Balanced/Vista/Performance start **empty**; no ready-made optimized profiles yet |
| Advanced shadows, lighting/water tiers, reflections, HDR/renderer and unmapped controls | Read-only observations/reasons where supported | Complete writable controls and dependency/restart/hardware validation unfinished |
| Public distribution | Folder/TOC, split licensing, original assets/provenance, deterministic local ZIP and manifests | Native release QA, final acceptance and CurseForge approval/publication still pending |

Readability alone is not evidence for safe writes or visible benefits. Automatic indoor detection, injected shaders and driver filters are not implemented addon capabilities. No completed-beta claim should be made while these gaps remain.

## Verification and next owner check

**Simulated:** 150 Lua 5.1 tests passed, zero failed; all 138 prior cases retained and 12 new regression cases added. New coverage includes reported 70840 setup/reload with zero writes, both reviewed build round trips preserving raw originals, Contrast/quality independence on 70840, startup/export readiness refresh, no export-driven calibration, unknown-build read-only setup, cross-build preview/verification/recovery refusal, missing/restricted APIs, descriptor isolation and wizard draft/scale/frame-pool behavior.

**Offline structural/syntax:** 29 runtime modules, six test Lua files and three binding bodies compile under actual Lua 5.1. The exact TOC, version alignment, assets, forbidden APIs and single native graphics call pass structural checks. Seven Python package tests pass, including manifest/runtime identity consistency. Package generation requires clean committed source and compares two archives byte-for-byte; final artifact/source verification is recorded in the delivery receipt.

**Next native check, read-only setup:** follow the updated [installation guide](21-BETA-USER-GUIDE.md), replace the entire extracted addon folder while WoW is closed, keep SavedVariables, log in, finish the wizard and let its button reload the interface. Current graphics should remain unchanged. Confirm launcher/Studio access and export one report. If setup was completed earlier, reopen it through Settings. Do not delete saved data to force it. Choosing an actual mode or confirming a calibration is a separate deliberate graphics action; none is required to verify this fix.

No installed game was modified or operated by development tools. Main and PRs remain unmerged, Issue #1 remains open, and nothing was published to CurseForge.
