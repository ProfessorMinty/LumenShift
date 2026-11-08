# Beta acceptance and eventual distribution

> Current dev.15 scope, Delivery 2 audit, simulated results and button-based checks are in [44](44-DEV15-DISTINCT-MODES.md), with earlier deliveries retained in [43](43-DEV14-SHARED-OPTICS.md) and [42](42-DEV13-RELIABILITY.md); use the updated [installation guide](21-BETA-USER-GUIDE.md). Native acceptance of the new integration remains separate from the owner's successful dev.6 Brightness observations. The older tables below preserve beta.1 history. No repeated approval/unlock ceremony is required for ordinary use, and no CurseForge publication is authorized. Earlier evidence is retained in [28](28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md), [29](29-QUALITY-PROFILES-AND-NATIVE-TRIALS.md) and [30](30-CAMERA-MODE.md).

**Historical beta.1 publication plan, not the current development priority.** The owner never installed/tested beta.1. Current work is the interactive diagnostic build in [23](23-INTERACTIVE-DIAGNOSTICS.md), with [one exploration/report workflow](21-BETA-USER-GUIDE.md). That document supersedes the old Brightness-only scope, schema/module counts and packaging detail below. Publication remains unapproved; no release-polish work is required before owner exploration.

The code and local archive are development deliverables. **Recommendation: owner acceptance testing next; no feature-complete beta sign-off or CurseForge publication yet.** Existing build identity is accepted; do not ask Arctic to reconfirm the launcher. Preserve previous Phase 00/01 evidence and mark only tests actually observed in this integrated build as passed.

## Owner test record

Use [21-BETA-USER-GUIDE.md](21-BETA-USER-GUIDE.md) for exact installation and the initial read-only / Brightness-only acceptance sequence. Record the ZIP filename, SHA-256 and `BUILD.json` source commit. The following remain **NOT RUN IN-CLIENT** for 0.2.0-beta.1:

| Gate | Acceptance criterion |
|---|---|
| Installation / startup | Complete ZIP loads without errors; both slash aliases and Studio/Settings entry work; actual Brightness and Contrast unchanged at startup |
| Initial switching | Explicit setup writes nothing; one Night Vision toggle reaches 75; Natural restores the exact captured original, clears effects and releases ownership; no repeated token ritual |
| UI / input | Six icons readable; cursor edge correction, keyboard cancel/select, bindings, launcher drag, every scroll page and numeric edit work; opening UI cannot steal gameplay input after close |
| Presentation / audio | Original media decode correctly; tint/vignette strengths are comfortable; sound previews/mute/levels work; effects off, reduced motion, high contrast and scale work |
| Combat / HUD | No mode changes queued in combat; effects/bars disappear; essential HUD remains accessible; custom-frame layering and EllesmereUI coexistence tested |
| Experimental modes | Separately approve non-75 target testing, save the original externally, test each chosen target/mode and full return to Natural; do not infer all 0–100 values safe from one pass |
| Conflict / recovery | Separately approve adverse tests; external edit preserved without fight, explicit restore card matches intent; readback failure retains original and does not retry |
| Reload / migration | Separately approve reload while owned; no startup reapply/restore, original retained if SavedVariables persisted, explicit recovery works; schema-1 migration and unsupported-downgrade behavior observed |
| Accessibility / screens | Test native 1080p/1440p/ultrawide and UI scale as available, labels/focus/color contrast, keyboard alternative, combat handling; actual frame/memory/CPU cost acceptable |
| Quality / Contrast | Native domains, dependent keys, restrictions, effects and exact restoration established before enabling; profile targets reviewed together, performance claims backed by measurements |

Do not induce crashes as an initial test. Crash/disk-loss safety has an inherent limitation: no addon can guarantee immediate SavedVariables durability. A read-only diagnostic success is not a native write test. A mock screenshot is not an authentic game screenshot. Redact other players' chat and private paths from evidence.

## Reproducible local packaging

After committing a clean working tree:

```text
python tools/package.py --output PATH_OUTSIDE_REPOSITORY
```

The packager reads recorded Git blobs from HEAD, requires clean source, checks the complete runtime list and asset hashes, and writes two in-memory archives which must be byte-identical. Sorted ZIP_STORED entries, a fixed 1980 timestamp and regular-file permissions avoid timestamp/compression-library variance. Every archive has one `LumenShift/` root with the 21 Lua modules, TOC, Bindings.xml, 12 runtime assets, both license notices, user guide, changelog, provenance, asset manifest and BUILD.json. It excludes research, tests, tool dependencies, VCS data, creative masters, local paths, account state and secrets. The receipt contains the full source commit and all payload hashes; the adjacent `.zip.sha256` identifies the exact artifact. This is a local builder with no installation, network, upload, credentials or publish operation.

Asset generation is a separate creative-source operation, never an implicit package step. The manifest binds the committed creative output. An archive's deterministic structure is compatible with the documented WoW installation convention; the current Forever uploader/flavor identifiers and actual client install still require native/dashboard validation. No uploaded project, file ID, moderation outcome or CurseForge approval exists.

## Draft description for later review (not published)

LumenShift by Northern Lights Labs brings reversible brightness modes, a compact icon wheel and a configurable Visual Studio to World of Warcraft: Forever. Night Vision starts at Brightness 75 and returns to your own captured original. Optional tint, vignette, screenshot framing and original electronic cues can be adjusted or disabled. Personal mode presets, keyboard controls, accessibility settings and explicit recovery diagnostics keep the experience under your control.

This development candidate supports a Brightness-only native writer on Forever 1.60.1.70790. Other brightness targets are experimental; Contrast and graphics-quality profiles are unavailable pending validation. UI textures are overlays, not shaders or engine color grading. Nothing automatically reapplies on login. SavedVariables can lag behind disk; restore and verify before disabling or uninstalling. Do not advertise unavailable quality tuning or claim measured performance benefits.

Original code and technical documentation use MIT, copyright 2026 Northern Lights Labs. Original artwork, icons, textures, sounds, logo and branding are All Rights Reserved; installation/use as part of LumenShift is allowed, independent reuse or redistribution in other projects requires permission. Third-party components retain their own licenses. Link LICENSE, ASSET-LICENSE.md and the source repository together; never select or describe the full package as MIT-only.

## Publication gates

1. Resolve the material quality/Contrast feature gaps or obtain an explicit product-scope decision; pass native acceptance and review remaining risks with the owner.
2. Review the exact consolidated diff/merge strategy. PRs #2–4 remain unmerged; no automatic main changes. Issue #1 remains open for incomplete validation.
3. Approve branding, authentic game screenshots, version/channel, changelog, compatibility claims and exact archive checksum. The proposed 400×400 original logo is in assets, not an assertion of approved branding.
4. Recheck current Blizzard/CurseForge policies and the live author dashboard's Forever flavor/version and license options. Choose a custom/split terms field if supported, otherwise have the owner select a truthful available representation; the full description must link both terms. No guessed project/category/game IDs or MIT-only project label.
5. Obtain final explicit owner approval before creating a CurseForge project, configuring publisher credentials or uploading. Verify moderation/publication afterward; an upload alone is not publication. No automatic publication workflow is installed.

The Phase 00 [release plan](08-CURSEFORGE-RELEASE.md) remains historical/source context; the current license and local packaging authorization supersede its earlier undecided-license/no-packaging stage. Uninstall safety, third-party terms, visible/free code and truthful feature descriptions remain applicable.
