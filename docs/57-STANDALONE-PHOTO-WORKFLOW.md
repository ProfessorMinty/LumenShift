# Standalone photo workflow — beta.12

2026-11-09 · Northern Lights Labs. Implements Delivery A of [the photo expansion plan](56-NARCISSUS-PHOTO-ARCHITECTURE.md). LumenShift supplies its own photo controls through native WoW APIs. **Narcissus is not required, loaded, imported or used as a provider.** Portrait/model staging and the later zoom/shoulder/AA expansion remain outside this delivery.

## Player-facing changes

Photo Studio now has six tabs arranged in two rows: Look, Light, Frame, Pose, Capture and Saved. The movable panel retains its scrolling content and fixed action/status footer. Capture screenshot, Hide controls and Exit remain on the separate bottom bar.

- **Pose:** twelve curated world emotes, pinned favorites, Stop pose and optional capture after a pose. This animates the actual player using WoW's emote API; it does not freeze the world or create a separate model. World emotes may be visible/audible to nearby players. Auto capture takes one shot using the configured delay, regardless of the burst count.
- **Capture:** delay 0–10 seconds, 1–5 shots, interval 1–5 seconds, Start and Cancel. The bottom bar shows countdown/progress and a Cancel action. Every shot hides the complete editor, countdown, guides, handles and applicable passive foreign toolbar before requesting WoW's screenshot. Artistic effects remain. The next shot waits for native completion before the configured interval; this is not an exact-FPS image sequence.
- **Frame:** retain the friendly-player/pet preference and add separate all-player, all-pet, NPC and chat-bubble choices. Checked groups are hidden after **Apply name choices now**, or on the next Camera entry. Missing/restricted/invalid optional keys are skipped with an unavailable count; no setting is guessed. Prior manually selected name intent and exact captured originals remain distinct. Exit returns the pre-session intent. A conflict retains recovery information rather than overwriting another addon or the player.
- **Look:** Undo look and Redo look, bounded to 32 session history entries. A slider drag, glow placement or RGB swatch is a single edit. Recipes, loaded looks and imports are undoable. History contains styling only; it never rewinds native graphics, saved presets or ownership records.

The existing native live sliders, Before/After, saved looks, filters, vignette, glow, grain and letterboxing remain. Reset photo look, Restore photo lighting and Restore field of view have separate meanings. Normal operation uses buttons. No new setup, data wipe, token or approval card is required.

## Lifecycle and architecture

`Core/PhotoTools.lua` validates preferences and curated emote actions. Modern `C_ChatInfo.PerformEmote` must return success; an absent modern function can use legacy `DoEmote`, but an errored/rejected modern action never retries through another API. Stop uses native CancelEmote when present, otherwise an explicit Stand request. Nothing performs an emote at startup or on a timer.

`Core/CaptureSequence.lua` manages a finite, generation-tagged sequence. It drains outstanding `PhotoPreview` changes before starting, waits for each screenshot result and stops on failure/timeout. Cancel, Escape, combat and leaving the world invalidate unissued work. A screenshot already requested cannot be recalled; its result drains without starting another shot. Missing screenshot/timer APIs affect capture locally. Native screenshot events contain no LumenShift request identifier, so simultaneous screenshot requests from another tool cannot be attributed with certainty.

`UI/Composition.lua` retains the actual screenshot call, render delay, keyboard behavior and clean view. External screenshot programs use H/Hide controls; LumenShift neither intercepts their keys nor claims their capture succeeded. `UI/PhotoTools.lua` builds the new sections. `PhotoEditor` keeps look history separate from the canonical graphics journal. All native CVar calls still pass through the existing `Core/WriteBoundary.lua` planner, checks and readbacks.

`NamePolicy` expands only explicitly listed boolean name/bubble keys. Each is checked at runtime for accessible numeric 0/1 and security flags; server storage is allowed for these scoped preferences, not treated as write protection. Targeting/soft-target behavior, floating combat text and tracking preferences are excluded. Name operations capture before writing and preserve raw original strings. No startup/reload graphics or name writes are added.

Schema **14** adds `camera.tools` and `camera.nameGroups`. Migration retains the previous friendly-name preference, setup completion, looks, presets and recovery records. New broader groups default off, and auto-pose capture defaults off. Invalid new data is quarantined through the existing store policy. Runtime capture/history state is not persisted or resumed automatically. SavedVariables is still not immediately durable or crash-proof.

## Optional coexistence

`Core/PhotoCompatibility.lua` is inert when Narcissus is absent. If it is present, the adapter recognizes only its passive `Blizzard` screenshot-toolbar layout and temporarily hides that frame during LumenShift Camera. It never calls Narcissus's feature APIs, HideUI/restore routines, changes its saved preferences or copies its assets. A known active full Narcissus studio requests a visible handoff rather than starting competing photo sessions.

On HUD return, a toolbar suppressed by LumenShift is made available for its normal native HUD-hook cleanup. This is presentation coordination, not a guarantee that another addon cannot write CVars. Narcissus can automatically change names on HUD hide and schedule action-camera changes on HUD show, as documented in [56](56-NARCISSUS-PHOTO-ARCHITECTURE.md). LumenShift observes its owned name/framing records and preserves conflicts; it does not repeatedly overwrite foreign changes. Simulated coverage includes both entry orders, late addon availability and automatic foreign-name behavior on/off. Actual coexistence remains an owner test on the installed version.

## Evidence and validation

Source checks were refreshed against the named Forever **70862** UI-source pin on 2026-11-09:

- [ChatInfo API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua#L451) declares restricted PerformEmote and its boolean result; CancelEmote is declared at line 36. Declaration does not guarantee every animation works for every race/form/context.
- [Native name settings](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Nameplates.lua#L351) confirms player and NPC name controls, including the literal `UnitNameHostleNPC` spelling and the grouped NPC choice.
- [Native bubble settings](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Interface.lua#L100) confirms boolean chat-bubble controls. Friendly/pet keys also have the owner's original macro and the inspected author implementation as evidence; current accessibility still comes from native reads.

Verification completed on 2026-11-09:

- **519/519 Lua 5.1 mock tests passed**, including 26 new WF workflow scenarios and the complete prior suite. Coverage includes no Narcissus globals, pose rejection/absence, one-shot auto capture, finite bursts, cancellation/failure/timeout, preview draining, exact name restoration, conflicts, migration, history, optional foreign auto-name behavior and delayed foreign changes.
- **10/10 Python packaging tests passed**. Syntax: **79 Lua files + four binding bodies**. Structure: **54 runtime modules**, exact TOC/version/asset paths and one centralized native CVar call site.
- Five off-client views (Look, Pose, Capture, countdown and scrolled names) rendered and inspected for fit. These do not establish native font/input/taint behavior. No new art or external runtime dependency is bundled.
- The initial full run identified three old assertions that required optional name failures to block Camera. Updated tests now assert the intended skip behavior, no write to the affected key and preserved diagnostics. One new test initially assumed a 45 baseline while its fixture used 52; it now verifies the actual captured value. The final full run has zero failures.
- Candidate packaging builds twice from committed source, requires identical bytes, validates its single install root and all manifest hashes, and pins bundled guide links to the source commit. The artifact receipt and PR record its final commit and SHA-256. Mock pose, capture, names, graphics and widget results are simulated. No game was operated, no actual screenshot was captured, and no installed addon or WTF file was modified by development tools. Native animation appearance, timing, input priority, screenshot contents and coexistence require owner acceptance.

## Installation and owner test

1. Exit Camera Mode normally before updating, then fully close WoW. Extract the new ZIP and replace the installed **LumenShift folder** with its complete LumenShift folder. Keep SavedVariables; do not reset setup. The TOC must sit directly inside `Interface/AddOns/LumenShift/`, with Core, UI and Media alongside it.
2. For the first test, disable Narcissus and its modules on the character-selection AddOns screen. Enable LumenShift, log in, and enter Camera from the LumenShift wheel. All six Photo Studio tabs must appear without Narcissus.
3. On Look, change warmth/vignette while dragging; click Undo and Redo. Change a native Light slider, then undo a look edit: the native value must stay independent.
4. On Pose, click Wave or Kneel. Pin a pose. Click Stop pose. Enable Capture after a pose, choose a two-second delay on Capture, and perform another pose: expect one clean screenshot. Race/form/context can limit individual animations; rejection should be readable without disabling other tools.
5. On Capture, choose three shots with a short delay and interval. Start; verify countdown and three files in WoW's Screenshots folder. Repeat and Cancel before the first shot, then between shots: no remaining shot should occur. Escape exits and cancels the rest.
6. On Frame, choose the groups to hide and click Apply name choices now. Compare names/bubbles before and after. Exit Camera and check the previous settings return. Do not use another addon or macro to change the same names during the normal restoration test; test that separately to confirm external changes are preserved and reported.
7. Use H for clean view and take an external screenshot. Confirm no Photo Studio, countdown, guide or glow handle appears; intended effects remain. H brings controls back; Escape returns to the game.
8. Optionally enable Narcissus again and repeat entry, clean view, capture and exit. Its passive toolbar should not remain over the shot. Finish its active studio before entering LumenShift. If a conflict occurs, export LumenShift's complete diagnostic report; no settings reset is needed.

Development branch/PR remain `feat/beta-integration` / #5. No merge, public release, CurseForge upload, new art dependency or model-stage implementation is part of this delivery.
