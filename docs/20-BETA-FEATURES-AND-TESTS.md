# Candidate scope, architecture and evidence

**Historical 0.2.0-beta.1 snapshot, never installed/tested by Arctic.** The current [0.2.0-dev.2 architecture and tests](23-INTERACTIVE-DIAGNOSTICS.md) supersede its disabled Contrast/quality scope, schema/module counts and writer description. Preserve these earlier decisions as history; do not treat either integration as natively accepted.

**Build:** 0.2.0-beta.1, schema 2, Forever 1.60.1:70790:16001. **Status:** integrated development candidate; feature-complete beta acceptance is blocked. This is not an inference that the game's API makes quality/Contrast impossible. The missing evidence is native domains, effects, dependencies and reversible behavior. The strongest currently justified implementation combines a working Brightness transaction path, experimental alternative targets, optional UI presentation, and diagnostic-only quality controls.

## Feature and evidence matrix

| Feature | Implemented behavior | Evidence / remaining gate |
|---|---|---|
| Natural / Night Vision | Captured exact original ↔ 75, setup once, user-triggered toggle, baseline retained until verification | Earlier owner-operated dev2 round trip verified (docs/18); integrated controls simulated, require acceptance |
| Cinematic / Lantern / Clarity / Moonlight | Distinct authored Brightness and tint/vignette settings; adjustable settings; common restoration path | Simulated; non-75 native targets explicitly experimental and disabled by default |
| Contrast | Reserved per-mode data field and honest disabled display | Readable in-client; no native write/restoration evidence, no writer admitted |
| Independent quality | Four named profiles, read-only 14-key catalog, dependency/source context, detailed scan | Current Baseline is an actual no-change choice; three profiles deliberately unavailable, no fake application or performance claim |
| Wheel / launcher / bindings | Cursor wheel, six original icons/labels, mouse/keyboard, edge clamp, movable launcher, configurable native bindings, Studio entry | Simulated handlers/geometry; real focus, screen scaling and key binding UI need native checks |
| Seven-page Studio | Sliders, numeric entry, toggles, reset, tips, current/original/status, scroll, personal presets and recovery | Mock widget coverage; native text layout, rendering and Settings entry need acceptance |
| Tint / vignette / bars | Noninteractive background UI overlays; optional screenshot bars below ordinary HUD; clear on combat/Natural | Source-based UI design + mocks; not engine grading; custom-UI overlap still unverified |
| Audio / artwork | Original procedural icons/logo, original on/off PCM cues, mute/soft/normal, no global volume changes | Provenance and format/hash checks; native texture/WAV decoding and subjective quality pending |
| User presets | 24 bounded, named, copied data-only mode variations; rename/delete/reset; no CVar-name injection | Mock validated; quality selection isolated |
| Accessibility | Labels, keyboard alternative, numeric input, scale, high contrast, reduced motion, audio/effects off | Simulated; native readability, focus and interaction with EllesmereUI not established |
| Recovery / persistence | Single writer; exact per-key originals; conflicts preserved; explicit reconciliation; schema 1 → 2 copied migration | Prior core mocks preserved; one successful native path only; no crash-proof/durable-save promise |
| Distribution engineering | Split terms, source/asset provenance, clean-commit allowlist ZIP, hash manifest and deterministic bytes | Automated local packaging; no dashboard/project/upload/moderation or public release |

No automatic indoor detection, shader injection, world-viewport resizing, global key reassignment, tier graphics writes or hold/release wheel selection are implemented. Hold selection is optional in the directive and deferred for input reliability. The absence of Contrast and operational quality profiles is a material product gap, not completed functionality.

## Module boundaries and state

The TOC loads 21 readable Lua modules without runtime libraries. `ReadOnly` checks accessibility, signatures and return shapes before using native getter data. `Compatibility` is an exact client-signature gate; renderer remains unverified. `Catalog` keeps production admission closed. Its legacy `BRIGHTNESS_75_ROUNDTRIP`/`CONTROLLED_TEST_01B` identifiers are retained as internal policy identifiers for the existing Brightness-only experimental descriptor, not claims that all target numbers passed in-client.

`Planner` and `Recovery` remain pure. `WriteBoundary` contains the sole native graphics call, hardcoded to Brightness. Ordinary `Switch` requires enabled validated configuration; non-75 targets require the additional experimental grant. It uses the existing prepare/replan/confirm path, capture-before-write, fresh security/combat checks and conflict model. It is not a raw setter API. `Profiles.Definitions()` retains closed production catalog metadata; operational experimental mode configuration is separate in `StudioConfig`.

`Product` coordinates a visual selection, copies its validated settings and commits effects only after the native boundary's immediate read and a separate timer read pass. The 0.15-second timer is a UX scheduling choice, not a measured settling guarantee. The callback carries the transaction identity and cannot verify/commit a later manual recovery. Timer failure preserves the journal and requires explicit recovery. Synchronous notifications cannot recursively write. Audio/presentation failure does not misreport a successful graphics transaction as a successful media effect; it has a separate diagnostic status.

Typical states: `BASELINE → AWAITING_VERIFICATION → ACTIVE → AWAITING_VERIFICATION → BASELINE`. Refusal does not start a write. Rejected writes may enter bounded compensation; uncertain recovery enters `RECOVERY`/`CONFLICT`. External values remain untouched until a fresh, explicit restoration preview is confirmed. Reopening UI, startup, CVAR_UPDATE, entering world and ending combat only observe; they do not apply graphics. Combat clears optional presentation and closes menus without auto-return.

`StudioConfig` validates numbers, strict fields, names and bounded preset storage. `Store` first validates/copies schema 1 and its journal, then adds disabled schema-2 Studio defaults. Unknown, cyclic, executable or oversized data remains untouched/quarantined. No immediately durable save API is claimed. Selected mode metadata never proves an active owned setting after startup.

`Quality` supplies read-only evidence rows only. There is no generic native writer exposed through it. Future admission needs a complete per-profile target closure, conflict map, renderer/domain evidence and per-key native round trips before broadening the one boundary. Multiple CVars must use the existing pure transaction/rollback model, not independent UI setters.

`Widgets` pools frames and regions because native WoW frames cannot be destroyed. Navigation reuses bounded pools; slider changes do not rebuild the whole panel. `Radial`, `Studio`, `Presentation` and `Audio` each have one UI responsibility. No `OnUpdate`, global hooks, hidden polling loop or third-party runtime dependency is introduced. Performance remains unmeasured in the native client.

## Off-client verification

Run from repository root:

```text
python tools/check.py --mocks --lua-runtime PATH_TO_ISOLATED_LUPA
python -m unittest discover -s tests -p test_package.py -v
```

The Lua runner uses Lupa 2.6's actual Lua 5.1 runtime, only as a development dependency. A system Lua 5.1 can also run `lua tests/run.lua`. `tools/check.py` verifies exact TOC paths/casing, version alignment, asset hashes, binding names, one hardcoded writer, no writers in other modules and no per-frame loop. Static token checks are useful guardrails, not a proof against every possible dynamic alias; review remains necessary.

The original 64 cases are retained. P01–P27 add migration isolation; setup/no-write page loads; all six mode/restoration paths; explicit experimental policy; quality refusal; bounded presets; frame reuse; keyboard/cursor fallback; full bootstrap/bindings; external conflicts; timer failure and stale transactions; no startup reapply; optional media; UI opt-outs and corner anchors; reduced motion; unavailable setter/build gates; read-only evidence export; and presentation cleanup through legacy slash recovery. Their widget model does not reproduce protected native behavior, taint, rendering, GPU cost, disk persistence or sound decoding.

Python packaging cases verify byte identity independent of map insertion order, a single install root, complete content hashes/commit receipt, path/case rejection, TGA/WAV structure and bounded audio, and detection of missing/changed ZIP members. The final recorded results and artifact receipt are in the PR and local delivery. Asset regeneration is checked separately; committed runtime assets, not regenerated platform-dependent math output, are packaged.

Optional `LUMENSHIFT_UI_MODEL_PATH` emits TSV widget geometry from the mocks. `tools/render_ui_model.py` can convert it to an off-client HTML preview. It is never native evidence. Browser policy blocked the local file preview during this work, so no browser rendering pass is claimed. Native layout remains required.

## Admission requirements for the remaining engine features

For Contrast and each quality key, collect the exact getter/security results first using existing diagnostics. Then separately authorize a controlled experiment recording source commit, original raw value, chosen documented value, effective readback, screenshot/observable change, dependent-key snapshots before/after, exact restoration and repeated reads. Test graphics-menu interactions, unsupported renderer/capabilities, reload requirements and performance where relevant. Reading a key or seeing a third-party addon set it does not meet this gate.

Tier settings such as shadow/water quality are especially unsuitable for blind admission: they can modify child settings. Define and capture the full closure or leave the tier unavailable. Sharpening has source mapping caveats; display source UI units rather than presenting a guessed numeric domain. Profile labels are design intentions until complete native target maps are reviewed. Do not ship a partial profile silently skipping unavailable required keys.
