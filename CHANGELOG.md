# Changelog

## 0.2.0-beta.14 — Portrait Stage

- Standalone staged models, poses, model lighting, backdrops, saved scenes and compositing capture.
- Fix interrupted zoom exit completion. Schema 16 keeps preferences, saved looks and originals. No startup stage/reapply or Narcissus dependency.
- Native stage rendering still needs owner acceptance. See [controls and exact owner test](docs/59-PORTRAIT-STAGE.md).

## 0.2.0-beta.13 — Photo composition and output

- Audit standalone photo lifecycle; add reversible framing, zoom/orbit, native AA/ray-shadow/JPEG controls, light leaks and separate saved compositions.
- Schema 15 preserves settings, recovery and earlier photo looks; no Narcissus dependency. See [implementation, evidence and owner test](docs/58-PHOTO-COMPOSITION-AND-OUTPUT.md).

## 0.2.0-beta.12 — standalone photo workflow

- Add native pose buttons/favorites, timed captures and bounded bursts, expanded name/bubble choices and look undo/redo.
- Keep photo tools standalone; optional Narcissus toolbar coordination does not provide functionality.
- Preserve saved looks and originals with schema 14. Validation: 519 Lua 5.1 mocks, 10 packaging tests, syntax/structural checks and off-client layout review pass. Native owner testing remains pending.


## 0.2.0-beta.11 — Live photo slider preview (2026-11-09)

- Preview native Brightness, Contrast, Sharpness, Bloom and FOV while dragging. Coalesce input, verify one transaction at a time and preserve the final requested value.
- Keep the grabbed slider stable during verification. Capture, clean view and comparison finish the latest preview first; Exit/combat cancel unissued work. Failures halt the current gesture without automatic retries.
- Preserve schema 13, exact originals, existing restoration and the single native write boundary. Filters/vignette/glow/grain remain immediate visual previews.

## 0.2.0-beta.10 — In-scene photo editor (2026-11-09)

- Add live photo filters, vignette, draggable glow, grain, letterbox and saved looks in Camera Mode.
- Add native lighting sliders, comparison and pre-photo restoration through the canonical writer.
- Preserve clean capture, H and Escape; schema 13 migrates existing preferences without startup writes.
- Add 26 photo-editor regressions, numeric recovery export, original compact textures and the owner test guide in docs/54-IN-SCENE-PHOTO-EDITOR.md. All 477 Lua 5.1 mocks and 10 packaging tests pass; actual in-game visuals/input remain unverified.

## 0.2.0-beta.9 — Clean photo capture and Escape (2026-11-09)

- Add Hide controls/H for a clean external screenshot or recording view; retain the selected scene effects while hiding guides, toolbar and tooltip. H reveals controls again.
- Escape exits Camera through existing HUD/name/FOV/photo restoration, including during queued or issued screenshots. Ordinary keys pass through; chat focus and combat remain respected. Keyboard failure reveals clickable Exit controls.
- Keep clean view session-only, retain it across capture completion/display refresh, and reset it on exit/re-entry. Fit the three-button toolbar to smaller displays and export clean-view/input status.
- Add ten input/lifecycle regressions and source-backed Narcissus/Forever photo-feature research in docs/53-PHOTO-MODE-RESEARCH-AND-CONTROLS.md. The planned in-scene editor, new filters and optional model stage are not implemented by this update. Schema 12 and graphics policy remain unchanged.

## 0.2.0-beta.8 — Camera name eligibility (2026-11-09)

- Correct a reproducible Camera refusal: server-account/character storage flags describe persistence, not a write restriction. Allow those flags only for the existing friendly-player/pet-name controls, including planning, readback, conflict observation, compensation and explicit recovery.
- Preserve actual secure/read-only/locked checks, readable numeric values, exact originals, independent manual names and visual modes. No new CVar, startup write, migration or settings reset.
- Export the previously omitted name storage flags, flag-read result, precise name-preflight check and last Camera error. Diagnostic scans remain read-only.
- Add eleven Lua 5.1 regressions for the storage variants, entry/exit, recovery, failures, conflicts and scope isolation. The supplied beta.7 report confirms name preflight refused before HUD hiding; its missing storage flags mean this explanation still requires a native retry. See docs/52-CAMERA-NAME-STORAGE-FIX.md.

## 0.2.0-beta.7 — One launcher and a clearer wheel (2026-11-09)

- Show either the minimap button or the floating launcher, never both. Fresh setup defaults to minimap; existing floating choices and positions are preserved. Setup/Accessibility now explain the choice; failed Studio initialization retains a fallback button.
- Make Studio, Setup and the wheel close one another when opened. Rework wheel spacing with larger single-line labels, separate shortcut badges and active indicators, non-overlapping pointer targets, and a dedicated hint strip. Fit the entire wheel and hints to the screen at different UI scales.
- Put a labeled Camera icon/button directly in the wheel center beside the Studio action. Keys 7/8 and arrow/Tab navigation reach Camera/Studio; mode keys 1–6 remain unchanged. Camera uses its existing controller and visible exit.
- Add launcher, geometry, Camera navigation, focus/combat and display-fit regressions. Keep schema 12, saved preferences, mode/graphics behavior, assets and the single writer unchanged. No settings reset, game installation, merge or publication.

## 0.2.0-beta.6 — Reset and restart setup (2026-11-09)

- Add **Reset LumenShift & Restart Setup** in Studio > Accessibility and WoW Settings > AddOns > LumenShift, with a fallback in the diagnostic export window.
- One confirmation clears only LumenShift's account-wide preferences, presets, baseline choices and recovery history, then requests a UI reload into fresh setup. It forgets old originals without restoring or changing current graphics, names, camera CVars or another addon's data.
- Cancellation preserves everything. Missing/failed reload keeps the previous save target; an active operation or combat defers reset without clearing anything. Historical conflicts, failed journals and quarantined data do not require a restore before intentionally resetting.
- Keep old controllers separate from the fresh save target until reload, and fence owned handlers and the single writer during reload. Ordinary upgrades still preserve saved settings; schema 12 and all assets remain unchanged.
- Add focused reset/lifecycle regressions and a native acceptance procedure in docs/50-RESET-AND-RESTART-SETUP.md. No installed-game operation, merge or publication.

## 0.2.0-beta.5 — Fallback macro recovery (2026-11-09)

- Fix the owner-reported refusal after a fallback macro returned Brightness from a completed mode to its exact captured original. A new explicit mode click may continue; choosing Original releases the old record without a setter.
- Preserve originals and fresh preflight checks across Brightness-only and composite visual paths. Pending/failed records, different external values, changed signatures/descriptors and restricted observations remain intact. No startup reapply or new unlock step.
- Add eight regressions for the reported 45/42/45 sequence, fresh/completed setup, no-setter release, multi-setting fallback, same-session conflict, unsafe records and preflight drift. Schema 12 and artwork remain unchanged.
- Document verified installed-file identity, the distinction between launcher and wheel, and the owner-requested backed-up clean setup in docs/49-RETURNED-ORIGINAL-AND-CLEAN-SETUP.md. No live graphics tests, merge or publication.

## 0.2.0-beta.4 — Whole-addon forensic audit (2026-11-08)

- Reject cross-controller operations during preflight and synchronous setter callbacks; retain the single native write boundary and existing exact-original recovery.
- Apply edited cosmetic settings from the Effects button; prevent native click arguments from selecting the previous appearance snapshot. No graphics write is added.
- Give the wheel focus-aware keyboard shortcuts, paired key releases and ordinary key pass-through, with the existing Studio fallback when propagation is unavailable.
- Skip native recipes that already match without acquiring new bank ownership; preserve earlier originals and complete multi-bank/setup callbacks.
- Export framing recovery, photo controller state, bank failure/source and watched side effects even after session history is lost on reload.
- Add ten forensic regressions, including a 112-case controller matrix, full-library recovery reload, no-change chaining and input failures. Schema 12 and all assets remain unchanged. Audit, evidence and exact validation results: docs/48-FORENSIC-AUDIT.md.
- No game installation, live test, merge or publication.

## 0.2.0-beta.3 — Phase 5 audit fixes (2026-11-08)

- Release keyboard capture when focus, modifier or propagation APIs fail; consume activation before running its action, preserve unrelated held-key releases, and retain mouse controls. Redact native exception details in diagnostic logging.
- Saving setup now refreshes the already-applied effects and stops a muted cue without applying mode-editor changes or writing graphics CVars. Existing completion, presets and schema-12 recovery data remain intact.
- Add ten adversarial keyboard, setup-comfort and preset-capacity regressions. All 393 Lua 5.1 tests and 10 packaging tests pass; syntax covers 60 Lua files plus four bindings, with 44 runtime modules. Current completion audit and remaining work: docs/47-PHASE5-AUDIT-AND-COMPLETION.md.
- No game installation, live test, merge or publication.

## 0.2.0-beta.2 — Delivery 5 candidate (2026-11-08)

- Audit Camera: preserve independent names choices on exit and cancel pending screenshots across Camera sessions. Schema 12 keeps session return intent separate from exact originals.
- Add saved-preset Edit, Update from mode editor, Reset editor, rename feedback and Undo deletion; retain draft text and data-only import/export. Editing never applies graphics.
- Scroll expanded setup graphics, keep final actions fixed, and prevent edits/reopening during Apply verification. Preserve completion and preferences across upgrades.
- Add Studio/setup Tab and Shift+Tab navigation, visible focus, keyboard activation, focus scrolling/cleanup, and live window resize fitting. Native text fields retain editing behavior.
- Stop in-progress menu fades for reduced motion; clarify Night Vision audio and human-readable operation/FPS status. Keep diagnostics available through visible controls.
- Validation: 383 Lua 5.1 mocks and 10 packaging tests passed; 44 runtime modules, 59 syntax files and four bindings. Bundled guide links resolve to the exact packaged source commit. Native acceptance limitations: docs/46-BETA2-POLISH-AND-AUDIT.md. No game installation, merge or publication.

## 0.2.0-dev.16 — Camera composition and graphics observations

- Camera thirds/aspect composition guides, guide-free native screenshot capture and a HUD-independent exit/capture bar.
- Manual field of view uses current native bounds, exact originals and conflict-aware restoration; no camera tracking or guessed fallback.
- Optional temporary photo-quality recipes preserve everyday/raid choices and restore captured banks independently. Names, framing and photo entry/exit serialize through the single write boundary.
- Practical graphics goals and a bounded user-started 10-second FPS observation; session A/B results include actual elapsed time, combat counts, requested choices and observed settings. No auto-tuning or hardware benchmark claims.
- Schema 11 preserves previous customization/completion/recovery. No startup writes, new assets, game installation, merge or publication.
- Validation: 366 Lua 5.1 mocks / 9 packaging tests passed; 42 runtime modules / 56 syntax files plus four bindings. Native acceptance remains unobserved; steps in docs/45-DEV16-CAMERA-AND-PERFORMANCE.md.

## 0.2.0-dev.15 — Distinct starting looks and return optics (2026-11-08)

- Audit Delivery 2: reverify 314 existing tests, add no-setter bloom recovery when renderer support becomes unavailable, and prevent unrelated quality recovery from vetoing or relabelling a valid composite visual mode. Original recovery records remain intact.
- Add two authored starting variations per active mode, light/style intensity anchored to the chosen return look, and independent detail/bloom/framing controls. Variations are deliberate saved-editor changes, not automatic replacements or claims of optimal native settings.
- Let Setup explicitly include available sharpening/bloom in Original or Game Defaults. Effective priority is mode, quality, opted-in reference, then captured original; keep one canonical optical recovery record and exact restoration.
- Disclose unavailable unowned optional optics before Apply and after success. Preserve owned unavailable records and fail/compensate actual write failures instead of silently skipping them.
- Add a separate bounded Contact depth Test & Restore experiment with AO-context/dependency observations and exact captured restoration. It is not applied by modes or saved profiles; visible effect and motion stability remain unverified.
- Schema 10 preserves completion, customizations and originals; LSMODE3 exports include intensity and old LSMODE2 imports remain accepted. Startup/reload stays free of graphics writes.
- **340 Lua 5.1 tests pass, 0 fail; 9 packaging tests pass.** Syntax covers 51 Lua files and four bindings; structural checks cover 38 runtime modules and one native CVar call site. Offline layout review covers starting looks, Setup and the contact-depth trial. [Details, evidence and installation](docs/44-DEV15-DISTINCT-MODES.md). No new native acceptance or publication.

## 0.2.0-dev.14 — Shared optics and mode detail (2026-11-08)

- Reverify Delivery 1 and retain its transaction, Camera, combat-presentation and local bloom fixes.
- Resolve independent mode/quality optical requests against one canonical original per shared key. Changing quality beneath a mode override preserves the new underlying preference; mode release reveals it and full recovery restores exact raw originals.
- Add Inherit / Off (extra) / Custom sharpening, weak-to-strong detail, Clear/Goggles styling and optional capability-checked bloom. New/reset Clarity inherits return-look brightness and uses Clear styling; existing customizations remain intact.
- Add real sequential Before/After through the same native writer, conflict-aware Finish, pending/reload recovery, and retained Studio scroll position. No startup replay, animated graphics writes or resolution/AA changes.
- Add bounded data-only preset import/export through the existing mode planner, with complete copyable payloads and import-without-apply.
- Migrate to schema 9 without overwriting completion, saved edits or exact originals. Diagnostic recovery explicitly includes shared sharpening/bloom originals; other quality settings stay independent.
- **314 Lua 5.1 mocks pass, 0 fail; 9 packaging tests pass.** Syntax covers 49 Lua files and four bindings; structural checks cover 37 runtime modules and one native CVar call site. UI review is off-client; new native acceptance is pending. [Delivery details and testing](docs/43-DEV14-SHARED-OPTICS.md).

## 0.2.0-dev.13 — Reliable mode transactions and presentation (2026-11-08)

- Apply Brightness/Contrast as one planned transaction, preserve both originals, compensate verified attempts in reverse and report partial recovery accurately.
- Keep visual effects visible with the HUD hidden through an optional Camera preference; resume permitted cosmetics after combat without graphics writes.
- Size vignette edges relative to the viewport and check the native linear-renderer capability for bloom only.
- Schema 8 preserves existing settings/journals and adds the Camera effects preference. Native visual acceptance remains pending.
- Direct captured-visual restoration and current/original Contrast display in Diagnostic Center; preserve the last applied appearance after compensation.
- **284 Lua 5.1 mocks pass, 0 fail; 9 packaging tests pass.** Syntax/structural checks cover 35 runtime modules, 11 test files and four bindings. UI review is off-client; no new native acceptance. [Delivery details and test steps](docs/42-DEV13-RELIABILITY.md).

## 0.2.0-dev.12 — Native graphics selection (2026-11-07)

- Add normal/raid graphics choices using native 1–10 recipes and recommended per-key defaults, independent of visual modes and detail profiles. Keep Current is the initial choice; no hardware benchmark or universal best-quality claim.
- Add captured known parent/leaf originals, fresh expected-state checks, one bounded compensation pass, explicit per-bank restoration and failure/conflict records through the existing planner/recovery and sole native setter.
- Split Setup into Appearance/Graphics, preserving saved choices. Preview and Save & Close never write. Apply & Reload waits for selected banks to verify; a failure saves preferences but does not reload.
- Add Studio previews, direct Apply/Restore, a separate Detail profiles view, native recipe/API diagnostics and captured/uncaptured setting export. Schema 7 preserves earlier completion/preferences/journals.
- Preserve dev.11 reload, mode continuation, movable-window and wheel fixes. No startup/reload graphics activation or new build lock.
- **268 Lua 5.1 mocks pass, 0 fail** (30 new native-graphics cases); **9 packaging tests pass**. Syntax/structural checks cover 35 runtime modules, 10 Lua test files and 4 bindings; one native setter. UI review is off-client. Native preset dependencies, appearance/performance and owner acceptance remain unverified; no installed-game changes or publication.

## 0.2.0-dev.11 — Reload, recovery and window fixes (2026-11-07)

- Fix normal mode/Apply clicks after reload when completed saved ownership still matches fresh readback. Keep exact originals, planner checks and zero startup writes; interrupted or conflicting records remain recoverable.
- Let Finish & Reload save and reload with active/pending journals intact. Remove the forced detour to Diagnostics.
- Add movable title bars, top-level window raising and consistent foreground strata to setup, Studio and reports; keep other addons' frames untouched.
- Reposition wheel icon/label groups, prevent unwanted label wrapping, and separate the active marker from label text. Disable Verify when no recovery verification is pending.
- Document native normal/raid 1–10 quality recipes, recommendation/default APIs and proposed setup. A hardware benchmark or full quality selector is not claimed as implemented.
- 238 Lua 5.1 mocks and 9 packaging tests pass, including 10 new regressions for the owner's 45→42→reload→75→45 report, exact raw restoration, interrupted reloads, conflicts, errors, independent leaf layers and window handlers. Structural/syntax checks pass. Browser review uses off-client geometry; native dev.11 retest remains pending.

## 0.2.0-dev.10 — Baseline choice and graphics investigation (2026-11-07)

- Add an Original / Game Defaults setup choice with read-only capture and separate recovery originals.
- Rename the baseline mode throughout the interface; preserve saved modes and quality independence.
- Document the Forever graphics investigation and mode-development strategy.
- Preserve captured sharpening strength in built-in quality profiles instead of forcing a potentially softer value; explain the reversed scale in Advanced Graphics.
- Add 36 named numeric research observations to export without enabling new writers or claiming complete tier dependency coverage.
- Migrate schemas 1–5 to 6 without overwriting preferences, custom profiles or journals; request the new baseline choice once.
- 228 Lua 5.1 mock tests and 9 packaging tests pass, including 19 new baseline/research/sharpening cases. Setup and baseline editor were inspected through the off-client Lua geometry model; native dev.10 graphics and UI behavior remain untested.

## 0.2.0-dev.9 — Enchanted optics artwork (2026-11-07)

- Integrate supplied Streamline Core utility icons, Steel/Midnight mesh panels and restrained teal Lumen Loops accents across Studio, setup, reports and navigation.
- Add original fitted wheel segments and matching selection geometry, a central logo/halo, rounded switch tracks and knobs, and keyboard-focus outlines. Visible sector clicks use matching pure hit geometry; keyboard and labeled buttons remain available.
- Keep high-contrast decoration suppression, text labels, saved preferences, independent mode/quality controllers and zero startup writes. No new animations or runtime dependencies.
- Bundle third-party credits and exact source/export mapping. Do not relicense third-party textures as original Northern Lights Labs artwork; omit source packs, Figma files and videos.
- Keep original mode icons pending custom replacements. Fractal Haze was not present in the supplied directory and is not included.
- 209 Lua 5.1 mock tests and 9 packaging tests pass, including texture pool reset, focus, high contrast, sector geometry, asset notices and bounded media size. Layout previews remain off-client evidence, not native game verification.

## 0.2.0-dev.8 — Studio hierarchy and approved logo (2026-11-07)

- Redesign Studio with a charcoal sidebar, grouped navigation, larger page titles, clear selected states, mode/profile cards, two-column settings and a fixed teal primary action.
- Selecting a Studio mode/profile card previews the selection; the explicit Apply action uses existing controllers. Wheel shortcuts remain one-click actions.
- Replace text toggles with compact switches, align slider value fields, shorten guidance and group diagnostics/recovery and advanced controls. Restyle the compact setup without resetting saved completion.
- Include the owner's approved aurora logo from the earlier artwork commit; remaining mode icons await replacement assets.
- Respect parent UI scale while fitting smaller viewports. Reenable pooled buttons and restore texture draw layers on reuse.
- Preserve schema 5, existing preferences, independent visual/quality layers, native writers, capture/restore/conflict behavior and zero startup writes.
- 205 Lua 5.1 mock tests and 8 packaging tests pass; syntax/structural checks pass. Review all nine Studio pages, setup and native-tier layout via an offline model. No new in-game result is claimed.

## Earlier artwork update — approved LumenShift logo (2026-11-07)

- Preserve the owner's supplied metal-ring/aurora PNG as the approved source master and replace the runtime logo used by the launcher, minimap entry, Studio and setup.
- Add a mechanical TGA/PNG export script and prevent the older geometry generator from overwriting the approved logo. Record source/export hashes and honest owner-supplied provenance.
- Existing dev.7 ZIPs remain unchanged; dev.8 is the first packaged build with this logo. No game installation or graphics behavior changes.


## 0.2.0-dev.7 — Camera Mode, usable quality profiles and warning-only compatibility (2026-11-07)

- Version, build and interface differences produce one nonblocking warning per login/reload. No acknowledgement, update requirement or version-based control lock. Missing/malformed identity and actual API/value/recovery failures still have distinct diagnostics.
- Explicit recovery can restore originals recorded before a game update, using current flags/domains and fresh readbacks. Historical source identity stays intact until successful restoration; no automatic startup recovery or retagging of originals.
- Diagnostics distinguish WARN from BLOCKED. Package metadata separates reference evidence from warning-only version policy.
- Keep zero startup graphics writes, single writer, per-key capture, exact restoration, conflict handling and saved preferences. Completed dev.6 setup stays completed; older setup refresh still applies.
- Add Camera Mode with native Alt+Z-style UI visibility, an optional keybinding, friendly-player/pet name toggle, separate captured originals and explicit recovery. Enemy names/nameplates and lens/movement settings are unchanged.
- Schema 5 adds the independent camera-name journal and saved preference; migrations retain old setup completion, preferences and recovery records.
- Make Balanced/Vista/Performance usable bounded recipes; preserve existing custom profiles exactly. Profile targets derive from original values without compounding.
- Add native enum/hardware-checked shadow/light/water/PBR temporary trials with captured named-watch restoration checks. Persistent tier profiles remain incomplete pending real dependency evidence; no guessed child repair writes.
- Coalesce slider-edit logs, retain native-operation counters, and label Natural restoration accurately. Record successful native dev.6 Brightness cycles without claiming dev.7 in-game acceptance.
- Automated tests remain simulated; native dev.7 acceptance is pending.


## 0.2.0-dev.6 — hotfix compatibility and automatic updated setup (2026-11-07)

- Fix dev.5 refusing the owner's actual Forever build 70862. Explicit development controls now use the Forever 1.60.1/interface 16001 contract from build 70790 onward, with fresh API/flag/value checks on each operation. Hotfix numbers remain recorded; version/interface changes still require review.
- Reopen the updated setup once for users upgrading from dev.1–dev.5, preserving all preferences, profiles and recovery records. Finish prevents another setup popup on the next reload; closing leaves it available next login. Schema 4 unchanged.
- Show actual mode-control availability in diagnostics. Replace stale production-admission/calibration-lock wording and distinguish a diagnostic snapshot from disabled controls.
- Keep exact session/build binding for pending operations and historical recovery; no automatic graphics application on upgrade, startup or reload.
- Native evidence: dev.5 loaded and exported on 70862, but a mode click was refused before any write. Dev.6 fixes are simulated until owner testing.


## 0.2.0-dev.5 — usable setup and direct controls (2026-11-07)

- Replace the three-page consent-heavy wizard with a compact preference screen: six familiar checkboxes, Save & Close, and Finish & Reload UI. No restore acknowledgement or enable-switching checkbox.
- Save choices and completion before requesting reload, independently of temporary graphics readiness. Retain them if reload is unavailable, fails, or must wait. Existing completed-but-disabled dev.4 setups can use a mode directly.
- Ordinary mode selection needs no extra unlock for non-75 Brightness. Optional per-mode Contrast and saved quality profiles use fresh native checks on Apply; a same-login calibration certificate is no longer a permission requirement.
- Add one-click Test & Restore to Advanced Graphics, keeping optional preview/export and recovery available. Successful test observations remain session history, not universal compatibility claims.
- Keep capture-before-write, exact restoration, readback, conflicts, restricted/unavailable API handling and the single native write boundary. Setup/startup/reload still make no graphics changes.
- Add preference serialization/reload, temporary-readiness, upgrade interaction, direct test, quality reload and restricted Contrast regressions. Schema 4 is unchanged; the old experimentalBrightness flag is retained only for data compatibility.
- Review EllesmereUI/ElvUI reference recording for interaction design only; no third-party code or assets copied. Dev.5 native visual, persistence and graphics acceptance remains pending.

## 0.2.0-dev.4 — build 70840 and revised setup, unreleased

- Accept the exact 1.60.1:70840:16001 identity for experimental controls, using the owner's read-only report and the pinned UI-source comparison. Preserve 70790, all restrictions, and empty production admission.
- Bind previews, writes and follow-up checks to the session build; refuse cross-build recovery without changing originals.
- Rework setup into compatibility/scope, labeled preference cards, then review and explicit reload. Show unsupported builds early and allow read-only setup. Size text independently of small inherited UI scale.
- Refresh read-only checks at world entry and export; preserve transient startup history without presenting it as the current result.
- The owner loaded dev.3 on 70840 and exported its report; Finish was blocked before reload and no graphics writes were recorded. Dev.4 native acceptance remains pending.

## 0.2.0-dev.3 — guided setup and button-first access, unreleased

- Open a three-step setup wizard on first login: appearance, sound, accessibility and controls, followed by an explicit Finish & Reload UI button. Draft choices stay local until Finish; setup/reload never apply graphics.
- Add a persistent minimap entry (labeled screen fallback when unavailable), a labeled movable launcher and Settings buttons for Studio, setup, diagnostics and export. Commands are optional shortcuts.
- Show exact Brightness recovery values in Studio and provide direct wheel/export buttons. Keep report access independent of Studio initialization.
- Migrate schemas 1/2/3 to schema 4 with a persisted wizard-completion flag and preserved configuration/originals. Never reload with unresolved owned settings.
- Native wizard/reload/minimap behavior still requires owner testing; no in-game operations were executed by development tools.

## 0.2.0-dev.2 — self-diagnosing interactive development build, unreleased

- Add bounded session event history, addon-owned error guards, automatic read-only checks, Diagnostic Center and a complete selectable report via `/ls report`.
- Add explicit bounded calibration for Contrast and selected leaf graphics settings, watched changes, exact restoration and session-only experimental target permissions. Connect optional calibrated Contrast to modes and user-configured quality profiles without assigning speculative targets.
- Preserve the previous Brightness engine and its regression coverage. Keep all native writes at one call site; startup, reports and diagnostics do not write or play audio.
- Migrate saved schemas 1/2 to schema 3 without discarding originals; retain separate disjoint Brightness/experimental journals. Stamp the packaged source commit into reports.
- Arctic has not installed or tested 0.2.0-beta.1 or this integrated development build. The earlier native round trip belongs to the older development version. No native acceptance or publication is claimed.

## 0.2.0-beta.1 — integrated development candidate, unreleased

- Add six mode editors, user-triggered switching after initial setup, optional tint/vignette/screenshot bars, original electronic cues, radial menu, launcher and Studio pages.
- Preserve exact Brightness ownership/recovery and the single graphics write boundary. Non-75 targets are labeled experimental; Contrast and quality writes remain gated by missing native evidence.
- Add schema-1 migration, bounded personal presets, accessibility controls, split code/asset licenses and reproducible development packaging.
- Native acceptance of this integrated build is pending. The earlier 45/75/45 test does not certify the new UI, effects, audio or other targets.

## 0.1.0-dev.2 — Phase 01B source, unreleased

- Add a Brightness-only controlled test engine behind the single native write boundary. Writes remain locked until a preview's one-use confirmation; login/reload never arms it.
- Add recovery-card previews, Night Vision 75, exact original restoration, explicit recovery, manual follow-up readback, conflict preservation and bounded compensation.
- Keep production write admission empty and all other graphics controls read-only. Arctic's owner-operated Forever 70790 test passed Brightness 45 → 75 → 45, readback/ownership release and visual restoration; persistence and native adverse-path tests remain unrun. See docs/18 for evidence and limits.
- Preserve the 38 foundation tests and add 26 native-boundary integration mock scenarios: 64 simulated tests pass under Lua 5.1, plus syntax and structural checks. Add the controlled acceptance procedure and owner-gated merge sequence.

## 0.1.0-dev.1 — Phase 01A source, unreleased

- Add diagnostic-only bootstrap, capability reads, slash commands and metadata for independent visual/quality presets.
- Add bounded schema validation, ownership/recovery models, pure planning and an inactive future writing boundary.
- Add off-client Lua mocks and source/TOC validation. No native game compatibility pass yet.
- Preserve Phase 00 research. No graphics writes, active presets, effects, assets or release package.
- No released predecessor schema exists; unknown schemas are preserved and refused, never reset.
- Address Aurora's review: independently validate numeric/restorable planner baselines and release exact-original ownership through verified observations without a setter result.
- Add eight regressions (38 total simulated tests) and a focused diagnostic-only installation/smoke-test handoff for the owner-confirmed Forever build.
