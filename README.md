# LumenShift

**Northern Lights Labs · Visual modes for World of Warcraft: Forever**

LumenShift combines reversible brightness controls, a six-mode icon wheel and a seven-page Visual Studio. It keeps visual modes separate from graphics-quality preferences, captures the actual original before taking ownership and never changes graphics at startup.

**0.2.0-beta.1 is a local development candidate, not an accepted feature-complete beta or a published release.** The earlier owner-operated Brightness 45 → 75 → 45 test passed readback and visual inspection on Forever 1.60.1.70790 / interface 16001. The new integrated UI, effects, audio and alternative brightness targets still require native acceptance. Contrast and quality-profile writes remain unavailable because their native ranges, dependencies and exact restoration have not been validated.

## Use the candidate

Install the whole extracted `LumenShift` folder under the existing Forever `Interface/AddOns` folder; the TOC alone is not the addon. Follow the [installation, controlled test and recovery guide](docs/21-BETA-USER-GUIDE.md).

- `/ls` or `/lumenshift`: read-only diagnostics.
- `/ls studio`: Visual Modes, Graphics Quality, Colors and Effects, Audio, Personal Presets, Accessibility, Diagnostics and Recovery.
- `/ls wheel`: labeled mouse/keyboard wheel; left-click the draggable launcher for the same menu, right-click for Studio.
- `/ls toggle`: Night Vision/Natural after explicit initial setup. Natural restores the exact captured original and removes effects.
- Set optional keys in the game's Key Bindings → LumenShift. No key assignments are changed automatically.

Night Vision defaults to Brightness 75 with optional green tint/vignette and original electronic cues. Cinematic, Lantern, Clarity and Moonlight have distinct editable brightness and presentation settings; non-75 native targets need a separate experimental opt-in. UI overlays are not world shaders. Audio starts muted, screenshot bars are off, and optional presentation clears in combat. Personal presets contain only bounded validated data.

No graphics-quality profile silently applies a partial/guessed target set. Current Baseline leaves quality unchanged; Balanced/Vista/Performance report their validation requirement. Read-only capability scans help collect evidence. See the [feature/evidence matrix and architecture](docs/20-BETA-FEATURES-AND-TESTS.md).

## Safety and evidence

`Core/WriteBoundary.lua` is the sole native graphics writer and only writes Brightness. Every operation uses planner preflight, exact baseline ownership and readback. Ordinary switching requires setup; uncertain reload/conflict recovery requires a fresh explicit preview and confirmation. External changes are preserved rather than repeatedly overwritten. SavedVariables are not immediately durable or crash-proof: save the recovery note outside the game and restore/verify before updating or removing the addon.

Read [prior native results](docs/18-BRIGHTNESS-CLIENT-RESULTS.md), [current integration decisions](docs/19-BETA-INTEGRATION.md) and [acceptance/publication gates](docs/22-BETA-RELEASE-QA.md). Automated mocks do not establish native rendering, audio, taint, disk persistence, addon coexistence or performance. EllesmereUI compatibility remains unverified.

## Develop and package

Authoritative repository: [ProfessorMinty/LumenShift](https://github.com/ProfessorMinty/LumenShift). Read [AGENTS.md](AGENTS.md) and [CODEX-START-HERE.md](CODEX-START-HERE.md). Current development branch: `feat/beta-integration`, preserving PRs #2–4; main is unchanged and merging requires owner approval. [Issue #1](https://github.com/ProfessorMinty/LumenShift/issues/1) remains open while validation is incomplete.

```text
python tools/check.py --mocks --lua-runtime PATH_TO_ISOLATED_LUPA
python -m unittest discover -s tests -p test_package.py -v
python tools/package.py --output PATH_OUTSIDE_REPOSITORY
```

The optional isolated development runner uses Lupa 2.6 / Lua 5.1; no library is shipped in the addon. `lua tests/run.lua` also works with Lua 5.1. Packaging requires a clean committed tree and reads recorded Git blobs. The ZIP has one install root, explicit runtime/legal files, a source/hash manifest and fixed metadata; it is built twice and compared. No publishing credentials, install operation or upload workflow exists.

## Licensing and eventual distribution

Original code and technical documentation: [MIT](LICENSE), copyright 2026 Northern Lights Labs. Original artwork, icons, textures, sound effects, logo and branding: [All Rights Reserved](ASSET-LICENSE.md), permitted for installation/use as part of LumenShift, not independent reuse or redistribution in other projects without permission. Third-party components retain their own terms. [Asset provenance](assets/PROVENANCE.md) and reproducible source recipes are included in the repository; no third-party media is bundled.

The whole addon must not be described as MIT-only. The eventual CurseForge description/license metadata must reflect both terms. No CurseForge project, upload, release or moderation approval has been created here. Public distribution requires completed QA and final owner approval.
