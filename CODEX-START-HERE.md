# Paste this into Codex Desktop: LumenShift Phase 00

You are working inside the Northern Lights Labs repository **ProfessorMinty/LumenShift**. This is a research-first project to develop LumenShift, a World of Warcraft: Forever visual-mode and graphics-quality addon.

**FIRST:** Read AGENTS.md, README.md, and docs/00 through docs/07 completely. Respect the Phase 00 stage gate. DO NOT start coding an addon, import the alpha prototype, mutate live WoW settings, modify repository configuration or ship anything. The current repository exists to establish the verified architecture and product requirements.

**YOUR ASSIGNMENT:**
1. Verify the game's actual build/interface/API model and identify the authoritative Forever-specific UI source. Separate live client observations from beta or Retail documentation.
2. Deep dive all CVars in docs/02-CVAR-REGISTER.md, starting with the seven values from Arctic's graphics guide. Research exact effects, presence, usable ranges, defaults, persistence, performance, dependencies, reload/relog needs, restrictions, and reset behavior; do not claim the owner's currently active values are known.
3. Research in-game graphics mode feasibility: exposure and contrast, foliage/LOD/world detail, lighting, fog, water, sound playback, animation, UI color overlay/vignette/scanlines/letterbox, cursor radial wheel, keybindings and Settings API.
4. Design a SAFE CVar owner/state machine: capture-before-write, effective-value readback, partial failure, manual/external modifications, restoring exact baseline, reload/logout/crash recovery and combat restrictions.
5. Design independent **Visual Modes** (Natural, Night Vision, Cinema, Lantern, Clarity, Moonlight) and **Quality Profiles** (Baseline, Balanced, Ultra/Vista, Performance) using delta-based state rather than global all-or-nothing settings.
6. Define an efficient modular Lua architecture, clear UX flows, acceptance tests, benchmarking methodology and packaging assumptions.
7. Populate reviewable research/decision documents with primary sources, exact file references and client/build specificity. Label VERIFIED/SOURCE-CONFIRMED/COMMUNITY/HYPOTHESIS/UNKNOWN/UNSUPPORTED.

**DELIVER:**
- Research executive summary with which claims are verified, uncertain, blocked.
- Evidence-backed API/CVar matrix and flags requiring in-game user tests.
- Mode and graphics profile recommendation with user-friendly trade-offs.
- Safe architecture/restoration state machine and initial UX proposal.
- Reproducible manual testing plan with no unapproved graphics changes.
- Priority implementation plan for Phase 01 (not implementation itself).
- A short list of important decisions for Arctic.

**QUALITY BAR:** Do not blindly trust community CVar defaults, unverified shortcuts, or outdated client assumptions. Cite facts; separate proposals; preserve the user's settings. You must NOT claim in-game tests passed unless you ran them on the actual game with recorded evidence. Stop at Phase 00 handoff and wait for approval.

The older v0.1.0-alpha prototype exists separately as a reference, not as approved architecture or a validated release. Ask before importing or rebuilding it.
