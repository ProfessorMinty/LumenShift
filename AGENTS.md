# Codex working agreement — LumenShift

Repository: https://github.com/ProfessorMinty/LumenShift (clone URL: https://github.com/ProfessorMinty/LumenShift.git). Northern Lights Labs owns this project. Read README.md, CODEX-START-HERE.md and docs/00 through docs/08 before doing work. Confirm you are in this exact repo, not a similarly named project.

## Distribution requirement
LumenShift is intended for public publication on **CurseForge for World of Warcraft: Forever**, after explicit owner approval. Plan for transparent, free and unobfuscated Lua code, Blizzard addon-policy compliance, original/licensed assets, proper Forever-specific TOC and CurseForge-compatible ZIP, game-version tagging, consistent license, release notes, QA, and a human-gated publication process. Read docs/08-CURSEFORGE-RELEASE.md. No CurseForge setup, API tokens, uploads or release publishing during Phase 00. Do not decide the license or claim CurseForge approval.

## Current authorization
**PHASE 00: RESEARCH + ARCHITECTURE ONLY.** You may create/edit Markdown research reports, evidence records and architectural proposals. Do NOT implement the Lua addon, import an untested alpha as production code, install/deploy files to the game, change graphics settings, publish releases, or advance to another phase without explicit approval. Do not silently change unrelated files.

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
Make small auditable documentation changes. Don't overwrite others' work. Clearly separate proposal from fact. No license until selected by maintainer. No 'passed in-game' claim without build, steps, observation and result. This public repository is not a waiver of intellectual property.
