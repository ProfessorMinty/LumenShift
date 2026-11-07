# Codex working agreement — LumenShift

Repository: https://github.com/ProfessorMinty/LumenShift (clone URL: https://github.com/ProfessorMinty/LumenShift.git). Northern Lights Labs owns this project. Read README.md, CODEX-START-HERE.md and docs/00 through docs/08 before doing work. Confirm you are in this exact repo, not a similarly named project.

## Distribution requirement
LumenShift is intended for public publication on **CurseForge for World of Warcraft: Forever**, after explicit owner approval. Plan for transparent, free and unobfuscated Lua code, Blizzard addon-policy compliance, original/licensed assets, proper Forever-specific TOC and CurseForge-compatible ZIP, game-version tagging, consistent license, release notes, QA, and a human-gated publication process. Read docs/08-CURSEFORGE-RELEASE.md. No CurseForge setup, API tokens, uploads or release publishing during Phase 00. Do not decide the license or claim CurseForge approval.

## Current authorization
**Normal use must not require commands.** The owner requires a first-run setup wizard for default preferences ending with a deliberate Finish & Reload UI action. Use visible launcher/minimap buttons and native Settings as primary entry points, including diagnostics/export/recovery. Commands are optional shortcuts. Read docs/24-GUIDED-SETUP.md. This authorizes implementing the final user-clicked reload, not executing it in the owner's game through development tools.

**Current directive: self-diagnosing interactive development build.** Continue the existing branch/PR #5. Read docs/23-INTERACTIVE-DIAGNOSTICS.md and the current docs/21 guide. Arctic has **not installed or tested 0.2.0-beta.1**; older native Brightness evidence does not certify the integration. Prioritize connected features, bounded explicit calibration, automatic read-only diagnostics and a complete privacy-conscious export. The newer authorization extends the single boundary to named experimental leaf settings, never arbitrary writers or inferred production admission. No installed-game changes, agent-operated live graphics tests, automatic merges or publication.

**FULL PRODUCT DEVELOPMENT / BETA INTEGRATION.** Arctic authorized the remaining mode system, optional effects/audio, UI, data-only presets, tests and reproducible development ZIP on 2026-11-06. Work on `feat/beta-integration`, preserving PRs #2–4 and their history. Read docs/19-BETA-INTEGRATION.md for decisions and current evidence gates. Docs/00–18 retain prior phase history. The native identity and one successful Brightness 45 → 75 → 45 visual/readback round trip are accepted evidence in docs/14 and docs/18; do not request launcher reconfirmation.

Core/WriteBoundary.lua remains the sole native graphics-writing boundary; every graphics operation must use the planner and recovery model. Initial setup may authorize ordinary user-triggered switching without repeated confirmation, but startup/reload/notifications must never reapply or restore uncertain state. Keep unverified/risky quality controls disabled or clearly experimental; no invented native evidence, ranges or dependencies. Do not modify the owner's installed game, execute live graphics tests without owner authorization, merge automatically, change main or publish/upload to CurseForge. Continue internally through routine implementation decisions. Stop only for irreversible actions, meaningful scope changes, owner-operated live changes, credentials, licensing decisions or significant unresolved compatibility/security risk. Keep Issue #1 open while validation is incomplete.

The owner selected MIT for original code/technical documentation, copyright 2026 Northern Lights Labs, and All Rights Reserved for original creative assets with permission to install/use as part of LumenShift. See LICENSE and ASSET-LICENSE.md. Third-party terms remain independent. Do not label the complete distribution MIT-only or choose new licensing terms silently.

## Sacred truth and verification
- Classify claims as **Verified in-client**, **Source-confirmed for a named build**, **Community-reported**, **Hypothesis**, **Unknown**, or **Unsupported**.
- Cite URL, file/line where possible, observation date and client build. Third-party source code proves what that author wrote, not universal client compatibility or safety.
- Never infer WoW Forever behavior solely from Classic Era or Retail. Confirm against the current live client and record its actual version.
- User-provided CVar values are preferences; never label them Blizzard defaults, safe maxima, or measured performance.
- Prefer read-only probes first. Game-setting writes, reload tests, FPS benchmarking and profile modifications require explicit separate approval.
- If the client cannot be accessed, provide a safe human-run test protocol and leave all in-game results UNKNOWN.
- Distinguish what the Lua addon API supports from shader injection, driver color filters and other unavailable approaches.
- No unverifiable promise of automatic darkness detection, film LUTs, monochrome phosphor shaders, or guaranteed performance.

## User baseline (preferences, NOT confirmed active)
Brightness 45; Contrast 60; ResampleAlwaysSharpen 1; groundEffectDensity 256; farclip 5000; lodObjectCullSize 8; lodObjectFadeScale 200. Night-goggle target Brightness 75.

## Safety and product boundaries
- Capture before-state per changed CVar, read back writes, provide rollback, and protect unrelated settings.
- Separate VISUAL MODES from GRAPHICS QUALITY profiles; switching a visual mode must not implicitly destroy quality preferences.
- Never change settings at startup without user opt-in. No automatic indoor switching in v1.
- Address combat, protected CVars, reload/relog, rejected values, external addon conflicts and failures.
- Do not hide action bars/critical combat UI with overlays or cinematic bars by default.
- Provide sound/animation/tint OFF options, keyboard alternative, legible icon labels, and accessible settings.
- Use WoW-supported UI, Lua, and game audio APIs only. No DLL injection, hardware overlays, input automation, memory inspection, or circumvention of game restrictions.
- External visual references and code are not licensed assets. Record reuse license before borrowing anything.
- Keep personal information, local paths exposing identities, account data and credentials out of commits.

## Phase 00 exit package
1. Current Forever build/API/TOC compatibility evidence.
2. CVar register: existence, naming, type, range, effective value, default, persistence, conflict, restrictions, reload, risk and test.
3. Sound, overlay, blend, animation, radial menu and advanced settings feasibility.
4. State machine and restoration/conflict design.
5. Visual modes and independent quality profile proposals with explicit delta sets.
6. Manual game test protocol and off-client mock tests.
7. Risks, unknowns, source links and decisions required from Arctic.
8. Concise handoff proposing Phase 01 scope and acceptance criteria, then STOP for approval.

## Working style
Make auditable changes within the authorized phase. Don't overwrite others' work. Clearly separate proposal from fact and mocks from native observations. Run tools/check.py and tests/run.lua as described in docs/12 for runtime changes. No license until selected by maintainer. No 'passed in-game' claim without build, steps, observation and result. This public repository is not a waiver of intellectual property.
