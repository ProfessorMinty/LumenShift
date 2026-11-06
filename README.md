# LumenShift 🌙

**A Northern Lights Labs project: visual modes and advanced graphics controls for World of Warcraft: Forever.**

> **Status: Phase 01A — diagnostic foundation, unreleased.** The addon source provides read-only diagnostics and pure planning/recovery models. Graphics writes and preset activation are disabled. **Intended release channel: CurseForge (World of Warcraft: Forever), pending compliance, native testing and approval.**

Read the [implementation architecture](docs/11-PHASE-01A-FOUNDATION.md) and [test results / local diagnostic installation guide](docs/12-PHASE-01A-VALIDATION.md). Source is in [addon/LumenShift](addon/LumenShift). `/lumenshift` and `/ls` display diagnostics only. Arctic's [in-game smoke-test reports](docs/14-CLIENT-SMOKE-RESULTS.md) now confirm loading and readable diagnostics on **1.60.1, build 70790, interface 16001**. Persistence, graphics writes and restoration remain untested; this is not a general compatibility or release certification.

LumenShift is a proposed, accessible visual-preset addon combining a fast radial mode wheel, a full configuration panel, immersive audiovisual effects, and carefully validated graphics-console-variable (CVar) management.

## The idea
One keybind should let players select an atmospheric visual mode without digging through multiple graphics menus. Two independent layers keep the system predictable:

- **Visual mode:** Night Vision, Cinematic, Lantern, Clarity, Moonlight and Natural, with optional UI overlays, sounds and color/exposure adjustments.
- **Graphics-quality profile:** Baseline, Balanced, Ultra/Vista and Performance, controlling verified engine detail settings independently of the visual mode.

The user's existing graphics preferences are the **baseline**. Switching modes should not silently destroy them.

## Current decisions
- **Primary target:** World of Warcraft: Forever. Do not assume untested Retail parity.
- **Stage gate:** Phase 01A is authorized. Phase 01B, graphics writes and publication require separate approval.
- **No hidden or magical shaders:** addon UI textures are overlays, not post-processing LUTs or true night vision.
- **Safety first:** opt-in changes; capture original CVar state; verify readback; reversible restoration; respect protected/reload-only settings and combat restrictions.
- **No automatic quality downgrade** merely because a color/exposure mode was selected.
- **No automatic indoor detection** in the initial release.
- **Original or properly licensed** audio, icons and visual assets only.

## Where Codex should work
- **Phase 00 review:** [Findings, open gates and approval decisions](docs/09-PHASE-00-FINDINGS.md) · [Read-only client checks](docs/10-CLIENT-VALIDATION.md). Preserved research; Phase 01A authorization is recorded in [11](docs/11-PHASE-01A-FOUNDATION.md). Live-client validation is still open.
- **Repository:** https://github.com/ProfessorMinty/LumenShift
- **Clone:** https://github.com/ProfessorMinty/LumenShift.git
- **Kickoff:** [CODEX-START-HERE.md](CODEX-START-HERE.md)
- **Research tracker:** https://github.com/ProfessorMinty/LumenShift/issues/1

## Start here (for Codex)
1. Read [AGENTS.md](AGENTS.md) completely.
2. Read [docs/00-PROJECT-BRIEF.md](docs/00-PROJECT-BRIEF.md).
3. Read the historical work order in [docs/01-PHASE-00-RESEARCH.md](docs/01-PHASE-00-RESEARCH.md), then follow the current Phase 01A scope in [docs/11-PHASE-01A-FOUNDATION.md](docs/11-PHASE-01A-FOUNDATION.md).
4. Use [docs/02-CVAR-REGISTER.md](docs/02-CVAR-REGISTER.md) as a hypothesis register, **not** a list of confirmed safe settings.
5. Follow [docs/03-ARCHITECTURE.md](docs/03-ARCHITECTURE.md), [docs/04-UX-DESIGN.md](docs/04-UX-DESIGN.md), [docs/05-TEST-PLAN.md](docs/05-TEST-PLAN.md) and [docs/06-ROADMAP.md](docs/06-ROADMAP.md).
6. Record sourced findings and unresolved questions in [docs/07-EVIDENCE-AND-DECISIONS.md](docs/07-EVIDENCE-AND-DECISIONS.md).
7. Follow [docs/08-CURSEFORGE-RELEASE.md](docs/08-CURSEFORGE-RELEASE.md) for packaging, policy, licensing, QA and publication rules, even during architectural planning.

## Intended public distribution
We plan to distribute a **free, unobfuscated, policy-compliant addon via CurseForge**. Proper version/flavor tagging, license selection, asset provenance, accurate screenshots, tested restoration and archive validation are release requirements, not optional polish. No CurseForge project has been created or submission made here. Refer to the [release engineering plan](docs/08-CURSEFORGE-RELEASE.md).

## Starter prototype
An earlier **v0.1.0-alpha** demonstration exists outside this repository. It had six modes, a clickable wheel, a settings pane and synthesized sound effects; it was **not tested inside WoW**. Treat it as a UX and behavior reference, not authoritative, production-ready code. Do not claim it is already in this repo or rebuild it without approval.

## Development workflow
Work on a dedicated implementation branch based on the Phase 00 research. Validate source/TOC structure and Lua 5.1 mocks before review; see [12](docs/12-PHASE-01A-VALIDATION.md). Keep simulated and live results separate. Do not install into a game folder, enable graphics writes, merge automatically or publish a release as part of Phase 01A.

## Source starting points
- [Blizzard UI Add-On Development Policy (official forum post)](https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642/1)
- [WoW Forever beta API observations](https://github.com/Thunderz96/forever-addon-kit)
- [Blizzard UI source mirror](https://github.com/Gethe/wow-ui-source)
- [Forever Graphics addon (third-party example)](https://github.com/drengalis/foreverGraphics)
- [Dynamic Ambiance Forever (third-party example)](https://github.com/imperial64/dynamic-ambiance-forever)

These references are evidence leads. Codex must compare their dates/builds with the user's installed client.

---
**Maintainer:** Northern Lights Labs · **Product name:** LumenShift · **Stage:** Phase 01A, diagnostic-only source.
