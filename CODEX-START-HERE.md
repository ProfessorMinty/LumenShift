# LumenShift — Codex onboarding and first assignment

## Identity and source of truth

**Current dev.10:** [Graphics investigation](docs/33-FOREVER-GRAPHICS-DEEP-DIVE.md) and [baseline architecture](docs/34-BASELINE-CHOICE.md). Setup now offers Original / Game Defaults for Brightness and Contrast; schema 6 preserves older preferences and originals and requests this new choice once. Quality remains independent. The roadmap addresses native image quality, lighting, water and hidden controls; proposals are not already implemented or live-verified. Keep normal interaction usable, use the existing branch/PR #5 and do not merge, install in the owner's game or publish.

**Asset direction (dev.9, 2026-11-07):** The owner supplied downloaded artwork for use across the UI. Read [32](docs/32-ASSET-INTEGRATION.md) and THIRD-PARTY-NOTICES.md. Integrate only selected runtime exports, preserve each third-party license and source hash, and keep raw packs out of the public repo. The six custom mode icons and missing Fractal Haze remain pending. No installed-game changes, merge or publication.

**UI direction (dev.8, 2026-11-07):** The owner requested cleaner visual hierarchy using the supplied EllesmereUI screenshot as a layout reference, while replacement assets are still being created. Read [31](docs/31-STUDIO-REDESIGN.md). Use the approved logo and original/code-drawn controls; do not copy reference artwork. Studio uses grouped navigation, cards, aligned settings and a fixed primary action. Existing preferences and controllers are preserved. Dev.8 UI verification is simulated/off-client, not a live game result.

**Continuing product direction (dev.7, 2026-11-07):** Read [28](docs/28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md), [29](docs/29-QUALITY-PROFILES-AND-NATIVE-TRIALS.md) and [30](docs/30-CAMERA-MODE.md). The owner supplied successful dev.6 Brightness 45/75/45 readbacks on 70862 and says switching works. Accept that bounded native evidence; do not ask for version reconfirmation. Version/build/interface differences now warn once, without blocking controls. Current API/value/conflict checks remain. Continue the full interactive product: built-in bounded quality profiles, native shadow/light/water round-trip trials, and newly authorized Camera Mode using native UI visibility plus the two friendly-name settings from the owner's macro. Schema 5 preserves old preferences/completion/recovery and adds a separate name journal. No startup writes; one native CVar call site. Persistent quality tiers still have an unresolved dependency/restoration gate; do not claim complete beta acceptance. Same branch/PR #5, no game installation/operation, merge or publication.


Current interaction requirement: automatic first-run setup wizard → chosen preferences → **Finish & Reload UI**. Afterward, use launcher/minimap/Settings buttons; commands are optional. See [guided setup](docs/24-GUIDED-SETUP.md). No automatic graphics activation on startup or reload.
- **Project:** LumenShift
- **Owner / creative direction:** Northern Lights Labs (Arctic)
- **GitHub repository:** https://github.com/ProfessorMinty/LumenShift
- **Clone URL:** https://github.com/ProfessorMinty/LumenShift.git
- **Primary branch:** main
- **Current tracking issue:** https://github.com/ProfessorMinty/LumenShift/issues/1
- **Target game:** World of Warcraft: Forever, live client (NOT assumed identical to Classic Era or Retail)
- **Intended distribution:** CurseForge for World of Warcraft, Forever game flavor after approval, compatibility tests and moderation.
- **Current authorization:** Full product development / beta integration, explicitly approved 2026-11-06. See [integration decisions](docs/19-BETA-INTEGRATION.md), [architecture/features/tests](docs/20-BETA-FEATURES-AND-TESTS.md), [local acceptance guide](docs/21-BETA-USER-GUIDE.md) and [release gates](docs/22-BETA-RELEASE-QA.md).

The current priority is the [self-diagnosing interactive development build](docs/23-INTERACTIVE-DIAGNOSTICS.md), on the existing integration branch and PR #5. Arctic has not installed/tested 0.2.0-beta.1. The older native Brightness round trip does not certify any integrated build. Connect features, provide explicit bounded calibration for selected leaf settings, and make the addon collect/export its own diagnostics. One private native setter remains in WriteBoundary; all operations use planner/recovery checks. Production admission remains closed; named experimental controls use fresh native/planner checks on Apply. Session test results are observations, not permissions, and arbitrary keys remain forbidden. Follow the current [exploration guide](docs/21-BETA-USER-GUIDE.md).

The Phase 00 work order below is preserved as history; later implementation approvals supersede its hold. Do not modify the installed game, execute owner-only native changes, merge automatically, modify main or publish/upload. Keep Issue #1 open. Native identity and one successful visual/readback round trip are already recorded in docs/14 and docs/18; do not request another launcher verification. The approved license is MIT for original source/technical documentation and reserved rights for creative assets; follow both root notices.

If Codex is not working in a clone of **ProfessorMinty/LumenShift**, STOP and open/clone that repository. Don't create a parallel LumenShift workspace or choose another repository by similar name. Verify origin with a local Git read-only command. Do not clone or mutate other projects without authorization.

## What we are building
LumenShift is a polished, end-user friendly World of Warcraft addon for switching **visual atmosphere** and **graphics quality** independently.

It began as a joke that solved a real accessibility problem: the player likes an atmospheric Brightness 45 / Contrast 60 look, but cannot see in dark interiors. A one-press Night Vision macro toggles brightness from about 45 to 75; the user then proposed an optional phosphor-green tint and activation/deactivation audio. A friend liked the idea, so now the goal is a **publicly distributable addon**, not an isolated macro.

Product experience:
- A compact radial icon menu near the cursor plus a draggable quick-launch orb and keybindings for one-click selection.
- A more complete advanced-settings window with per-mode sliders, effects, high-quality graphics controls, diagnostic readbacks, restore and personal presets.
- **Visual modes (concepts, subject to user approval):** Natural/Baseline, Night Vision (brightness + optional green overlay + original electronic goggle cue), Cinematic (mood, cinematic framing without obstructing combat), Lantern (warm, readable interiors), Clarity (neutral high readability), Moonlight (cool atmosphere).
- **Graphics quality profiles (separate):** Current Baseline, Balanced, Ultra/Vista, Performance. Enhanced world detail explores sharpen, foliage density/distance, terrain and object LOD, draw distance, lighting, fog, sunshafts, shadows and reflections only where supported and proven safe.
- Modes may be combined, e.g. Night Vision + Ultra or Cinema + Performance. Selecting a visual mode must NEVER silently override the separate quality profile.
- Quick restore is a first-class safety requirement; save the user's actual baseline before writes, read back changes and report mismatches.
- User-provided graphics guide candidates include ResampleAlwaysSharpen 1, groundEffectDensity 256, farclip 5000, lodObjectCullSize 8, lodObjectFadeScale 200, Brightness 45 and Contrast 60. These are proposed values/preferences, NOT confirmed engine defaults/ranges.
- Visual overlays are UI techniques, not real GPU shaders or true monochrome night-vision processing.
- UI should feel sleek, fast, unobtrusive, accessible, low-overhead and fully configurable; original icons and sound only.

## Why CurseForge matters from the beginning
We are not just creating a private proof of concept. The intended result is a clean, well-documented, free, publicly viewable and non-obfuscated Lua addon that can pass CurseForge moderation. Design for:
- Forever game flavor and verified interface number/TOC structure;
- correct addon directory layout and ZIP artifact;
- versioning, changelogs, semantic release channels and game-version tagging;
- policy-compliant features, sources and assets, consistent repository/CurseForge licensing;
- safe SavedVariables, profile migration, precise rollback and uninstall documentation;
- release QA with tested compatibility, fresh installation and authentic screenshots;
- automated build/lint tests with manual verification and deliberate upload approval.
**CurseForge is not yet configured and nothing is approved for publication.** Read docs/08-CURSEFORGE-RELEASE.md for source-linked requirements. Do not configure token/webhook, make a CurseForge project or publish anything.

## Historical Phase 00 stage gate and first assignment
Read **AGENTS.md**, **README.md**, **docs/00 through docs/08**, and **reference/ALPHA-PROTOTYPE.md**. Then work through **GitHub Issue #1**.

### Phase 00 research tasks
1. Establish actual live Forever build, UI interface, addon flavor, supported APIs and protected restrictions (do not assume old beta documentation stays true).
2. Verify the guide's exact CVars and all candidates in docs/02: name, existence, type, allowed range, default, effective changes, persistence, FPS risk, graphics-menu conflicts, reload/relog needs and rollback.
3. Examine possible sound, tint/vignette/letterbox effects, animation, radial selection input behavior, keybindings and Settings integration without suggesting external shader injection.
4. Design a modular, testable architecture with a baseline journal, CVar ownership, diff application, readback, partial failure, external-edit conflict policy and predictable reload/logout behavior.
5. Propose distinct visual modes and quality profiles with tested/untested labels, risk classifications and independent delta sets.
6. Define future CurseForge-aware packaging, TOC/asset conventions, CI checks, license/attribution review, QA, versioning and release gates.
7. Update Markdown research docs with primary evidence, game build, URLs, scope, source classifications and unanswered questions. Report your findings and **STOP for Arctic's approval** before coding.

### Do not do during Phase 00
Do NOT write addon Lua or package a release, import the old untested alpha into production, modify Blizzard graphics CVars, deploy to the user's game directory, change repository visibility/settings or automation, select a license, upload to CurseForge, or claim in-game tests without evidence.

### Deliver to Arctic
- A plain-language executive briefing: confirmed, community-reported, unknown and unsupported.
- Evidence-backed CVar/API compatibility table and proposed in-game verification tasks.
- Clear mode/quality matrices and UX/architecture alternatives with tradeoffs.
- Baseline/restoration state-machine design plus testing and troubleshooting plan.
- CurseForge release-compliance checklist and unanswered items.
- An actionable Phase 01 proposal with acceptance criteria, not Phase 01 code.

## Previous alpha
A separate v0.1.0-alpha was generated earlier outside this repo. It is a rough concept with an icon wheel, six modes, a settings panel and original synthesized sound. Its live-game behavior is unverified. Treat it as an optional historical reference, not code to inherit without review.

## Operating principle
**Source of truth over certainty theater.** A credible unknown is better than an invented CVar capability or fake 'tested' claim. Document discoveries and next tests. This is intended for other WoW players, so safety, compatibility and reliable uninstall matter every bit as much as the cool green goggles.
