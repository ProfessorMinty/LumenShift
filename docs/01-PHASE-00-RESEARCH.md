# Phase 00 research assignment for Codex
**Authorization: documentation and research only. No code implementation, game installation or settings changes.**

## Goal
Turn LumenShift's concept into a **client-grounded technical specification** for World of Warcraft: Forever. Separate fact from unverified candidate settings. Supply all evidence needed to approve a safe implementation phase.

## 1. Confirm client truth
- Identify installed game executable/product, version/build, interface number, game-type identification and folder layout.
- Map Forever vs Mainline vs Classic behavior using Blizzard UI source, live-client API inspection when available, and build-tagged third-party implementations.
- Establish whether GetCVar, SetCVar, GetCVarInfo, C_CVar, supported UI texture blend modes, sound playback, keybinds, cursor-positioned menus and Settings UI work on this build.
- Investigate protected/restricted calls, combat restrictions, scene/UI layering, event APIs, saved variables and how addon enable/disable behaves.
- If the game client is unavailable, provide precise **read-only player-run probes** and mark any test result not observed as Unknown.

## 2. Verify the user guide first
Priority values supplied by the maintainer:
- ResampleAlwaysSharpen = 1
- groundEffectDensity = 256
- farclip = 5000
- lodObjectCullSize = 8
- lodObjectFadeScale = 200
- Brightness = 45, Contrast = 60
- Night Vision brightness target = 75

For EACH: does CVar exist, exact spelling, purpose, read-only state, accept/range, engine default, current value, persistence, graphics-menu interactions, runtime effect, performance burden, reload requirement and reset method? Never infer exact defaults/ranges from one community addon.

## 3. Expand CVar candidates
Inspect groundEffectDist, groundEffectFade, terrainLodDist, doodadLodScale, textureFilteringMode, ResampleSharpness, graphicsViewDistance, graphicsLightMode, sunshafts, shadowNumCascades, ssaoType, giQuality, volumeFog, reflectionMode, weatherDensity, horizonStart, render scale and other relevant graphical controls. Identify settings that collide with graphics presets or can crash/stutter. Favor high-impact, low-risk candidates for launch.

## 4. Research visual/audio/UI feasibility
- Compare plain alpha overlays and documented blend modes; distinguish UI tint from true shader color grading.
- Assess vignette/scanline textures, cinema black bars, UI layering, readability and action-bar obstruction.
- Investigate original OGG/WAV playback, channel and volume, packaging and reload/restart semantics.
- Validate clickable radial wheel, cursor position and keyboard/gamepad fallback. Research key-up/release mode, secure actions and combat limitations rather than assuming they work.
- Compare standard game Settings registration against a custom advanced UI.
- Investigate coexistence with EllesmereUI, other HUD addons, and any independent brightness automation.

## 5. Restoration state machine
Propose and diagram Baseline → Preview → Active → Restoring → Baseline, plus Deferred/Failed states. Detail per-CVar ownership, readback mismatch, partial application, manual user changes, other addon writes, reload, logout, crash, SavedVariables schema, disabling/uninstalling and late graphics-menu updates. Select clear policies for reverting only what LumenShift owns.

## 6. Performance & safety experiments
Design **opt-in** before/after tests in a dense wooded area, interior, city and distant vista. Capture hardware, build, precise CVar values, FPS frametimes/stutter, same camera/lighting, test length, screenshots, revert steps and any missing evidence. No invented benchmark numbers or unapproved settings writes.

## 7. Outputs
Produce: executive summary; verified client/API matrix; CVar table with evidence status; mode vs quality recommendations expressed as **delta keys**; UX feasibility grid; state machine; test suite proposal; risk register and recommended Phase 01 acceptance criteria. Update the evidence log with URLs and build tags. End with a short 'Decision required from Arctic' section and **do not continue implementing**.

## Acceptance gate
No write-capable CVar enters Phase 01 without a risk classification and a reversible test. Every uncertain/unsupported claim visibly remains uncertain. No core architecture or mode count is silently decided. Stop for review.
