# Usable setup and direct controls — dev.5

Observed and implemented 2026-11-07. Schema 4 unchanged. This supersedes the dev.3/dev.4 interaction requirements in docs/23–25; their source and native evidence remain historical records.

## Reference video and why the previous setup felt wrong

Arctic supplied a 1:34 recording of EllesmereUI and ElvUI startup. The recording was watched in Snagit; no game interaction or installed-addon modification was performed. Timestamps are approximate.

| Recording | Observed interaction | Lesson for LumenShift |
| --- | --- | --- |
| 00:00–00:02 EllesmereUI | Compact central window, grouped feature checkboxes, useful defaults and a Reload UI button | Ask about features the player wants, not permission to unlock the addon |
| 00:56 ElvUI, CVars 2/9 | Setup CVars button and visible “CVars Set” feedback | A deliberate action should do useful work and report its outcome |
| 01:04 profile settings 4/9 | Shared/new profile choices with a short purpose statement | Steps should represent real configuration decisions |
| 01:08 layout 5/9; 01:14 theme 6/9 | Role/theme choices with “Layout Set” / “Theme Set” feedback | Let players choose and see progress; keep diagnostics out of ordinary setup |
| 01:30–01:34 completion | Finished button followed by a loading screen | Finish should leave a configured addon ready to use |

The old LumenShift sequence spent three pages on compatibility, consent and recovery review. It used large ON/OFF cards where familiar checkboxes sufficed, made enabling the feature an additional choice, and still required an experimental unlock or repeated session tests afterward. That made completion feel disconnected from actually using the addon. The failure was not merely the number of pages: ElvUI had more pages, but those pages performed useful setup tasks.

The reference is interaction evidence only. It does not prove other addons' persistence or Forever CVar behavior. No video, screenshot, code, branding or assets from those addons is copied into the repository/package.

## What persisted in the installed dev.4 build

**Local read-only evidence:** the installed TOC was 0.2.0-dev.4 and its Build.lua matched `0c587a46911caae182929127158825b4111c2e4e`. A narrowly filtered inspection of saved addon data found schema 4, completed onboarding, effects/sound/animation enabled, reduced motion/high contrast disabled, but `studio.enabled=false` and the non-75 experimental flag false. No raw saved-data file or account path is committed.

This establishes that completion and several choices reached disk; it does not establish that every choice matched the owner's intent. It also confirms the unusable outcome: completed setup with visual controls still off. The old draft default depended on `CanEnable()` at the moment setup opened. Temporary readiness failure could become a saved disabled preference, even after the client became ready. The exact trigger in the owner's session is not recoverable from that saved snapshot.

## Implementation

- One 640×440 preference window: screen effects, sounds, animations, reduced motion, high contrast and launcher; Later/X, Save & Close, Finish & Reload UI. Familiar checkboxes and short text replace three pages and acknowledgement controls.
- Save validates an atomic config copy, enables ordinary controls and marks onboarding complete **before** requesting reload. Graphics readiness is not a condition for saving preferences. Combat, active ownership or unavailable/failed reload leaves choices saved with an explanation; no delayed automatic reload is scheduled.
- A direct mode click can enable controls left off by dev.4. Non-75 Brightness targets within the existing policy range no longer require `experimentalBrightness`; the legacy field remains validated/stored only for schema compatibility. Preferences do not automatically activate graphics at startup.
- Ordinary mode operations are quiet: no recovery-card chat ritual. Current values and operation state remain in Studio; failures have readable messages and machine codes remain in diagnostics.
- Optional per-mode Contrast and saved quality Apply use the planner and fresh native checks directly. Session test certificates remain observations, **not permissions**. Persisted quality target sets do not require recertification after each login.
- Advanced Graphics adds **Test & Restore**, combining the existing preview and confirmation engine behind the single deliberate button. Its immediate/delayed readbacks and restoration remain unchanged. Optional preview/export and explicit uncertain recovery are retained.
- Quality capability rows now distinguish implemented experimental controls, unavailable observations and genuinely unimplemented controls instead of labeling everything read-only.

No new CVar, wider target domain, wildcard client identity or second writer was introduced. The existing source basis in docs/23 and docs/25 remains unchanged. Named quality bounds derive from the current original or captured original; they are addon test-size limits, not proven engine safe ranges. No stock Balanced/Vista/Performance targets were invented.

## Internal invariants that remain

WriteBoundary owns the one private native setter. Both paths still require admitted descriptors, current safe reads/flags, known client identity, planner validation, capture-before-write, per-key ownership, readback and conflict checks. Unknown identities and genuinely unavailable/restricted controls cannot write. Composite visual operations preflight Contrast before Brightness; a later failure can retain partial recovery. Current Baseline and Natural remain independent.

Startup/setup/reload do not change graphics. Saved preferences are distinct from active ownership. Reloaded or uncertain journals require explicit reconciliation; no startup restore or reapply is attempted. SavedVariables is not immediately durable or crash-proof. Normal users do not need to export a report before each mode click.

## Validation and remaining native work

**Simulated:** 157/157 tests under actual Lua 5.1; 29 runtime modules, six Lua test files and three binding bodies compile. Structural checks enforce TOC/module/asset/version consistency, prohibited APIs and the single graphics call. Seven Python packaging tests pass. Whitespace checks pass. These are off-client results.

Regression coverage includes preferences saved before reload, missing/failed reload, combat and owned recovery, interrupted-readiness setup, the dev.4 completed-but-disabled upgrade, fresh-fixture serialization/reload, unknown-build preferences versus blocked writes, direct Test & Restore, quality profiles after reload without session certificates, restricted Contrast before any Brightness write, and saving profiles independently of combat while Apply still checks it. Existing restoration, setter/clamping/error/rollback/conflict tests remain.

The compact setup's mock frame geometry was rendered and visually inspected with approximate desktop fonts. It has six readable checkboxes in three rows and two columns and unobstructed footer actions. This is not an in-game screenshot or native font/texture certification.

**Not yet verified in-client for dev.5:** layout/font scale, chosen preferences surviving native Finish/reload, all mode/Contrast/quality actions, audio/effects, input and EllesmereUI coexistence. Arctic's earlier native Brightness success and dev.3 report are preserved, not relabeled as dev.5 tests. The owner can now exercise the actual controls using [the concise guide](21-BETA-USER-GUIDE.md); another read-only-only test handoff would not address the problem.

The final local ZIP is built from committed source, stamped with that commit, compared byte-for-byte across two builds and accompanied by a manifest/checksum. Artifact identity is recorded in the PR and local verification receipt. No installed game modification, agent-operated native test, merge or CurseForge publication occurs in this task. Issue #1 remains open.
