# One launcher and a clearer wheel — beta.7

**2026-11-09 · Northern Lights Labs**

The owner's screenshots show two simultaneous entry buttons: the floating rectangular launcher and the minimap logo. This was caused by separate visibility logic, not duplicate addon installation. The wheel also crowded labels/keyboard hints around the center and lacked a direct Camera action. This update addresses navigation/layout before further individual-mode tuning.

## Behavior

- **One launcher:** fresh setup uses the minimap button. Enabling **Floating launcher** replaces it with the movable launcher. Existing saved choices/positions are preserved: a prior floating choice now shows only the floating button. Studio > Accessibility labels this **Floating launcher instead of minimap**. Switching is immediate and survives reload.
- **Fallback:** the minimap/fallback entry remains available if Studio cannot initialize, regardless of the floating preference. Without a native Minimap frame, that entry uses its existing visible screen fallback. Camera intentionally hides normal UI while its independent Exit Camera Mode control remains available.
- **Wheel:** the circle is 420 layout units, with a separate hint strip inside the overall frame. Mode names no longer include shortcut prefixes; shortcuts have their own small badges. Labels are single-line, larger, and placed to clear central controls. Active-mode marks remain independent of hover/keyboard selection. The whole frame scales/clamps to screen dimensions and UI scale when opened.
- **One primary view:** opening Studio, Setup or the wheel closes the other primary LumenShift views, so they do not stack over one another.
- **Camera:** a labeled camera icon/button in the center invokes the existing Camera controller. Its existing preferences determine HUD/name/photo behavior, and its existing **Exit Camera Mode** button returns the interface. The adjacent Studio button provides access to the Camera settings page.
- **Keyboard:** 1–6 retain mode switching; 7 activates Camera, 8 opens Studio. Arrows/Tab traverse all eight actions, Enter/Space activates the selected action, Escape closes the wheel. Existing chat-focus, combat and paired-key propagation handling remains intact. Tooltips close with the wheel.

No new CVar, camera engine, mode preset, asset, dependency or SavedVariables field is added. Schema 12 remains unchanged. No settings reset is required. This task does not install the addon, operate the game, merge the PR or publish anything.

## Architecture

`EntryPoints.Refresh` owns the mutually exclusive launcher visibility; `Radial.Refresh` delegates to it. The prior always-visible minimap and independent floating decision are removed. The saved `launcher.visible` field remains compatible: true selects floating, false selects minimap/fallback. Only fresh default data changes to false.

The radial texture/hit policy retains its existing 352-unit coordinate system. A separate 420-unit circular surface scales native cursor coordinates back into that policy; the footer's extra height does not move the hit-test center. Mode targets and Camera/Studio controls have separate rectangles. Camera remains a utility action, not a seventh visual mode, so visual-mode/quality configuration remains independent.

## Verification

Nine new simulated tests cover exclusive launcher choice, upgrade/position preservation, Studio initialization failure, Camera icon/exit, keyboard/text-focus/combat, non-overlapping geometry and independent shortcuts, small-display/UI-scale fitting, eight-action navigation/tooltips, and exclusive primary views. Existing wheel geometry and setup round-trip tests are updated to assert the new interface.

Focused tests and off-client layout review pass. The layout model was rendered and visually inspected, including the longer Game Defaults label and both center icons. The HTML preview's CSS mask issue was bypassed only in the local preview using the existing PNG icons; runtime assets are unchanged. This model checks positioning, not WoW rendering, font substitution, native input or other-addon coexistence. Final frozen-source validation: **430/430 Lua 5.1 tests**, **65 Lua files + four binding bodies** for syntax, **45 runtime modules** for structural/TOC/version checks, **10/10 packaging tests**, **104 current local documentation links** and whitespace checks passed. The first full run found three old test selectors still using numbered mode labels; they were updated to the separate label/badge UI and the complete suite rerun. The final suite also includes the additional primary-view exclusivity regression. **Native beta.7 acceptance is not yet run.**

## Owner check

1. With WoW closed, replace the complete LumenShift addon folder from the beta.7 ZIP. Keep SavedVariables.
2. At login, expect one launcher. If the previous floating preference was enabled, that is the one retained. Toggle **Studio > Accessibility > Floating launcher instead of minimap** and verify one disappears as the other appears.
3. Open the wheel near a screen edge. Check all labels and the hint strip are readable, without overlapping the center controls.
4. Click the center **Camera** button. Expect the existing Camera behavior and visible **Exit Camera Mode** button. Exit, reopen the wheel and use **Studio** to access Camera options.
5. Test 7/8 with chat closed, then verify typing those digits into chat does not activate wheel actions. Ordinary mode behavior is unchanged by this UI update.

Current installation guide: [21](21-BETA-USER-GUIDE.md). Integrated acceptance checklist: [22](22-BETA-RELEASE-QA.md). Earlier reset: [50](50-RESET-AND-RESTART-SETUP.md).
