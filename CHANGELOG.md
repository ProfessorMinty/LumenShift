# Changelog


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
