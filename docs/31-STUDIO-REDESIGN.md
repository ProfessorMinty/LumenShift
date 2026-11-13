# Studio redesign — 0.2.0-dev.8

Date: 2026-11-07. Scope: native addon UI and off-client layout tooling on `feat/beta-integration`, draft PR #5. No installed-game changes, native graphics tests, merge or publication.

## Design and interaction

The owner's EllesmereUI screenshot establishes the desired hierarchy, spacing and restrained use of accent color. No source code, textures, fonts or logos were copied from that addon. LumenShift uses its approved owner-supplied aurora logo, existing original placeholder mode icons, native game fonts and code-drawn textures. Replacement mode artwork is still pending.

Studio is a 1120 × 740 logical-pixel window with a 220-pixel sidebar. Workspace, Personalize and Tools group the navigation. A large page title and short subtitle lead into a quieter current-state strip, followed by the scrollable page. A fixed footer holds guidance/errors and the page's primary action. The selected navigation row has both a tinted background and an accent edge. Mode/profile cards separate selection from application. The radial wheel remains a direct-selection shortcut.

Visual Modes uses a six-card grid and two aligned light/contrast columns. Graphics Quality uses four profile cards and selected-profile details. Effects, Audio and Accessibility share compact switches, sliders and restrained secondary actions. Personal Presets uses an editable name and two-column saved-preset list. Diagnostic Center groups health and recovery; individual checks expand on request, and export remains in the fixed footer. Advanced Graphics separates direct controls from native-tier trials. Camera groups interface visibility and name controls with return instructions visible before entry.

The small setup screen adopts the same colors, switches and emphasized Finish action. This UI update does not reset onboarding completion or save a draft before Save/Finish. Schema remains 5.

## Boundaries and API choices

- `UI/Widgets.lua`: shared palette, rules/borders, text, cards, switches, inputs and sliders. Uses existing native Frame/Button/Texture/FontString/Slider/EditBox APIs, no library or external runtime dependency. Font files come from the native font object; no bundled third-party font.
- `UI/Studio.lua`: navigation, page layout and fixed action routing. Mode selection changes the editor only; Apply calls the existing Product controller. Quality card selection changes only the UI selection; Apply calls the existing calibration/profile controller.
- `UI/Calibration.lua`: compact experiment form and native-tier layout using the existing trial, preview, confirm, restore and profile APIs. Unsupported tier choices remain visibly muted and disabled; pooled buttons are enabled again before reuse.
- `UI/Setup.lua`: visual treatment only; the existing validated preference-save and explicit reload behavior remain intact.
- All native graphics/name operations still pass through the same planner and single WriteBoundary call site. No new writers, startup activation, automatic recovery or schema migration.
- Frame/region pools are reused across navigation and edits. Reused textures restore their requested draw layer. No polling or per-frame layout handler was added.
- Studio compensates for `UIParent:GetEffectiveScale()` to keep the intended readable size, then caps its scale to available parent dimensions. User scale still applies within that fit. High contrast changes panel backgrounds without removing labels/selection markers.

## Verification

**Simulated / off-client only:**

- `python tools/check.py --mocks --lua-runtime ../lua-test-runtime`: 205 passed, 0 failed under Lua 5.1. The earlier 199 cases remain, including exact restoration, conflicts, failure recovery, warning-only version handling, camera/name behavior and setup persistence.
- U01–U06 add card-selection versus Apply behavior, independent quality routing, persisted switches without scene changes, effective-scale/small-screen fit, disabled-button pool reuse, selected navigation and footer separation from scrolling.
- Existing P02/P07 now exercise all nine Studio pages for zero writes/sounds and bounded widget allocation. Existing wizard diagnostics coverage follows the shorter Run Diagnostics label.
- Structural checks cover exact TOC paths, version consistency, asset hashes and one native CVar call site. Syntax checks compile 32 runtime modules, 8 test Lua files and 4 binding bodies.
- `python -m unittest discover -s tests -p test_package.py -v`: 8 packaging tests.
- The optional Lua UI model exports actual widget positions, visibility, values and text. `tools/render_ui_model.py` renders these as HTML for layout inspection. All nine Studio pages, setup and tier-trial layout were visually reviewed. The renderer now quotes its CSS font correctly, keeps edit-box text above backgrounds, preserves line breaks and avoids browser theme-extension recoloring. Mock slider thumb positioning is an approximation of native behavior.

This is **not native rendering evidence**. Browser font metrics, texture stacking, input, frame strata, scaling and clipping can differ in WoW. Sample values and unavailable capability counts in model screenshots belong to the mock fixture. They are not Arctic's game diagnostics. Native dev.6 Brightness evidence remains documented in [28](28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md); no new live result was added by this change.

## Owner check when the game is available

Install the complete extracted dev.8 folder as described in [21](21-BETA-USER-GUIDE.md), retaining SavedVariables. Right-click the launcher/minimap icon for Studio. Confirm readable titles, one highlighted navigation row, correct logo transparency and a visible bottom-right primary action at your normal UI scale. Check Accessibility scale/high contrast, wheel and setup entry points. Completed setup should stay completed.

Selecting a mode/profile card should update the editor without changing the scene. Apply should perform its named action; Natural / Current Baseline should retain the established restoration behavior. Longer advanced/recovery content should scroll without hiding the main action. Check switches and numeric fields with mouse and keyboard, and make sure Camera's return instructions remain visible before hiding the interface. An ordinary diagnostic export can accompany any overlap, input or behavior problem; no extra confirmation workflow was added.

Unresolved full-beta gates remain native camera/profile/tier/UI/effects/audio evaluation and complete native tier dependency/restoration mapping. Remaining assets do not block this UI iteration. This is a development ZIP with MIT code/docs and reserved-rights creative assets, not a CurseForge release.
