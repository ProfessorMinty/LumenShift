# Guided setup and button-first access

> **Interaction update, dev.5 (2026-11-07):** [Usable setup and direct controls](26-USABLE-SETUP-AND-CONTROLS.md) supersedes the wizard/unlock/session-calibration requirements below. Historical observations remain valid for their recorded build. Use the [current guide](21-BETA-USER-GUIDE.md).

**Historical dev.3 implementation record · schema 4.** Dev.4 supersedes its wizard design and single-build policy; see [70840 evidence, revised flow and scope](25-BUILD-70840-AND-SETUP-REVIEW.md).

The owner corrected the interaction model: a complete addon must introduce itself with a setup wizard and use buttons for normal operation. The earlier command-first handoff was inadequate. Existing diagnostics, calibration and graphics safety remain; this change does not expand graphics-writing scope.

## Interaction and lifecycle

First PLAYER_ENTERING_WORLD opens a three-step wizard outside combat: introduction; effects/sound/animation/accessibility/launcher preferences; visual-control permission and recovery acknowledgement. Back/Next retain draft choices; closing discards them without touching saved preferences. The final **Finish & Reload UI** button validates and saves preferences/completion, then calls native ReloadUI directly from that user action. It never selects a mode or changes graphics/audio globals. Combat, missing reload capability or unresolved owned settings refuse; a native reload exception is logged without exposing raw exception text, and no automatic retry occurs.

The completion flag persists in schema 4. Schemas 1/2/3 migrate by validated copy, retaining all modes, presets and captured originals. Unknown/malformed input is quarantined. Never downgrade over a newer schema or clear recovery data. Completion is written to the in-memory SavedVariables table before requesting reload; no immediate durable-disk or crash-proof promise is made. Startup never reloads itself and never reapplies graphics. Combat may defer the first wizard display only, not a queued graphics or reload operation. Completed setup does not reopen on later logins. Settings can reopen it; existing disabled controls remain disabled unless selected explicitly.

`UI/Setup.lua` owns the wizard and final reload action. `UI/EntryPoints.lua` creates the minimap button (labeled screen fallback when absent) and native Settings entry independently of Studio initialization. A separate labeled movable launcher opens the wheel/setup on left-click and Studio on right-click. Hiding that movable launcher leaves the independent entry available. Settings contains Studio, setup, Run Diagnostics and Export Complete Diagnostic Report buttons. Studio includes persistent wheel/export buttons and displays the exact pending Brightness card values before confirmation. The old slash interface remains for optional shortcuts, without being the normal instruction path.

Recovery is entirely clickable: Diagnostic Center → Restore My Brightness preview → review original/current/target → Confirm displayed recovery card → Verify pending recovery. The read-only engine status exposes a copied preview, so display/export cannot change the proposal. Calibration recovery retains its existing preview/export/confirm controls. Failures in Studio initialization still leave an independent report button when native frame creation is available. Failures before any UI can be created remain outside addon self-reporting.

## Source and native evidence

The pinned Blizzard UI mirror for 70790 uses ReloadUI in an accepted popup callback: [AddOnPerformance.lua, lines 5–8](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_AddOnPerformance/AddOnPerformance.lua#L5). Its [Minimap.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_Minimap/Mainline/Minimap.lua) references the Minimap frame. These are source observations, not native verification of LumenShift's callback, positioning, copying or persistence. Availability is checked and missing APIs have explicit fallback/reasons. No existing minimap scripts, global keys or game settings are replaced.

At dev.3 implementation time, native wizard/reload/Settings/minimap acceptance was **NOT TESTED**. Subsequent owner evidence confirms loading, wizard display/navigation and report export on 70840, but Finish was blocked before native reload. Full acceptance remains incomplete; see docs/25. The older successful Brightness round trip does not validate this build; no game installation or live action was performed by the development agent.

## Offline checks

The prior 125 cases remain; 13 wizard/access tests cover automatic first display, no startup writes/audio/reload, selected settings saved before explicit reload, no later reapply, cancel/back/draft behavior, combat deferral, missing/failed reload, recovery before setup, a complete button-only setup/mode-on/mode-off/diagnostic/export journey, minimap/fallback access with hidden launcher or missing Settings, Studio initialization failure, schema-3 migration/quarantine, unsupported-build read-only setup, Settings reopening, preserved disabled preference and immutable exact preview values.

Historical dev.3 recorded result: **138 passed, 0 failed under actual Lua 5.1**, with **six Python packaging tests passed**. Runtime is 29 Lua modules; syntax checks also passed for all five test files and three binding snippets. Structural checks and git diff whitespace checks passed. The final local ZIP is generated from committed source and verified against its source/hash manifest. There is no automatic merge, installed-game modification or CurseForge publication.

Use the [button-first user guide](21-BETA-USER-GUIDE.md). The normal owner handoff is: install the extracted folder, log in, complete the wizard, click Finish & Reload UI, then explore the launcher/Studio and send its report if anything breaks.
