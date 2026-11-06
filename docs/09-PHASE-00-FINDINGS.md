# Phase 00 findings — review package

**Date:** 2026-11-06. **Status:** source investigation and architecture proposal complete for review; live-client acceptance NOT complete. **Authority:** [Issue #1](https://github.com/ProfessorMinty/LumenShift/issues/1). No Phase 01 implementation is authorized.

## Executive finding

LumenShift has a credible path to a small, reversible brightness addon, then a richer visual interface and independently validated graphics controls. The first implementation should manage **Brightness only**, after explicit approval and client checks. There is no verified launch whitelist yet. Source availability, an accepted CVar string, and a visible rendering change are three different things.

Arctic reported **1.60.1.70790** during this investigation. The `forever` branch of the Blizzard UI mirror is labeled **1.60.1 (70790)**, committed 2026-11-04 at `eac30af597e5aaa43a60f6675ef5fdcea100375f`. This is a matching source baseline, not direct observation of the installed client. Interface **16001** has beta capture and third-party TOC evidence; a current `GetBuildInfo()` tuple and fresh-load test are still required. See [evidence ledger](07-EVIDENCE-AND-DECISIONS.md), SRC-01/02/03/09.

No running WoW process was found by the limited process-name check, and two standard installation paths yielded no executable. That does not establish that the game is absent. No game session, account configuration, or live setting was accessed. All in-game results in this package are **Unknown / NOT RUN**.

## Repository and scope verification

- Exact origin verified locally with `git remote -v`: `https://github.com/ProfessorMinty/LumenShift.git`, for fetch and push.
- Branch: `main`, initially clean and tracking `origin/main`; starting HEAD `363adecb2cd4c68a684b41b3be943b631a2b6859`, matching the GitHub branch API.
- Read in full: `AGENTS.md`, `README.md`, `CODEX-START-HERE.md`, all nine original `docs/00–08` documents, and `reference/ALPHA-PROTOTYPE.md`. Read Issue #1 and its empty comment collection.
- The starting chat directory was not a Git repository. A checkout of the exact authorized remote was cloned; no new GitHub repository or unrelated project was created.
- Changes are Markdown only. No addon Lua, runtime assets, TOC, executable test harness, workflow, license, package, token, webhook, CurseForge project, issue comment, or release was created. The old alpha was not imported.

## What the evidence establishes

| Level | Finding | Engineering consequence |
|---|---|---|
| Source-confirmed for 70790 | Blizzard's mirrored graphics UI uses `Brightness` and `Contrast`, each with a 0–100 UI slider; Gamma uses 0.3–2.8 | 45/75 and 60 fit the source UI domains. They remain preferences, not observed values/defaults or proof of writable/effective behavior |
| Source-confirmed for 70790 | `C_CVar.GetCVarInfo` returns lock/security/read-only flags, but no range or reload metadata; setter preconditions can return nothing | Feature checks and readback are mandatory; a non-throwing call alone is not success |
| Source-confirmed for 70790 | Texture filtering maps 5 to 16x anisotropy; ResampleSharpness has a reversed 0–2 UI domain; secondary lighting is capability-gated | These are useful later candidates, not universal hardware recommendations |
| Source-confirmed for 70790 | Overall graphics quality changes child settings, and separate raid settings exist | Avoid overall preset writes; map indirect effects before quality controls are admitted |
| Community-reported, named beta builds | Early SavedVariables failures are followed by a report of successful reload/cold-start persistence on 70009 | Do not ship beta workarounds or assume the old bug persists; test persistence on 70790 |
| Source-confirmed API surface; runtime Unknown | Texture, animation, Settings registration and key-up binding examples exist | Click wheel and optional overlays are plausible. Layering, addon restrictions, sound files and input behavior need game QA |
| Source-confirmed platform guidance | CurseForge documents Forever live's `_forever_` folder and publication requirements | Packaging can be designed now; exact author-dashboard flavor/version choices remain unverified |
| Unsupported / excluded | True scene LUTs, world monochrome phosphor processing, framebuffer light sensing, injection and crash-time Lua recovery | Describe effects as UI overlays and brightness adjustments; make no shader or guaranteed recovery promises |

Full citations and limitations: [07](07-EVIDENCE-AND-DECISIONS.md). CVar-by-CVar findings: [02](02-CVAR-REGISTER.md). Nothing is classified Verified in-client.

## Client/API compatibility matrix

| Surface | Source status | 70790 installed-client status / required gate |
|---|---|---|
| Version/build | Owner reports 1.60.1.70790; matching pinned source | Raw GetBuildInfo tuple still needed, R1 |
| TOC/interface and flavor | Beta capture/third-party TOC say 16001; source has Camelot game-type selection | Current interface, executable/product and fresh-load recognition U |
| GetBuildInfo / WOW_PROJECT_ID | Beta capture names function and project 1; source analysis distinguishes family/game type | Actual tuple/project constant U; no numeric version shortcut |
| C_CVar.GetCVar / GetCVarDefault / GetCVarInfo | S70790 public declarations, nullable/missing-value handling and flags | API existence, per-key output and accessible values U; R2/R3 |
| C_CVar.SetCVar | S70790 guarded setter with bool result and possible no-return preconditions | Actual write eligibility, effect and restrictions U; W1/W4 after approval |
| Legacy GetCVar / SetCVar / GetCVarInfo | Some global calls used by Blizzard UI; beta capture includes GetCVar/SetCVar, not proof for every legacy alias | Probe individually; do not require or manufacture global GetCVarInfo |
| CVAR_UPDATE and lifecycle events | S70790 declares synchronous CVar event; beta reports warn unknown event registration may error | Delivery completeness, registration and addon load/save timing U |
| Textures / blend / animation | S70790 methods and animation templates | Layering, blend enums, texture loading and motion/readability U; V1 |
| PlaySoundFile / StopSound | Beta capture contains both; 70790 authored StopSound use | Custom-file playback/signature/codecs/channel behavior U; V1 |
| Cursor/frame/binding input | Beta cursor/frame APIs; 70790 Camelot key-up bindings and restricted focus method | Click/keyboard/gamepad/combat behavior U; V1/W4 |
| Settings registration | S70790 registration functions | Load timing/canvas behavior U; V1 |
| SavedVariables / reload / logout | Conflicting beta reports reconciled by build; 70009 author reports success | 70790 persistence and orderly-exit restore U; W3; no automatic reload |

Presence of native or trusted-UI code does not establish permission for tainted addon calls. LumenShift needs no combat-log, secret unit-state or protected gameplay automation APIs. Feature detection must be narrow and fail closed for writers while preserving read-only diagnostics.

## Recommended architecture and scope

Adopt one CVar writer behind a pure planner, build-scoped catalog, per-key ownership journal and readback adapter. Treat visual modes and quality profiles as disjoint key sets. Preserve the original before-value through mode changes. Before every write or restore, compare the actual value with the last value owned by LumenShift; external edits suspend ownership rather than trigger a write fight.

Distinguish a transaction's before-values from the longer-lived baseline. A failed switch rolls back to the previous active mode, not necessarily Natural. Rollback itself can fail, so retain unresolved records and show a recovery state. Startup and restart recovery are read-only until the user acts. SavedVariables is a recovery aid, not an immediately durable write-ahead log. See [03](03-ARCHITECTURE.md).

Keep all six visual concepts in the design, but validate Natural/Night Vision first. Natural releases only visual ownership; Quality Baseline releases only quality ownership; Restore All releases both. Do not equate any of these with engine defaults. Only Night Vision has an owner-provided numeric target. The other modes' numeric values remain unset pending visual review. Proposed exact key sets and quality alternatives are in [04](04-UX-DESIGN.md).

## Principal risks and open questions

1. **Persistent changes and lost baseline:** CVar persistence can outlive the addon, while a crash can precede a SavedVariables flush. Require a readable recovery card before the first approved write and a tested persistence lifecycle. A deleted addon cannot repair settings.
2. **External changes and races:** Graphics menus and other addons may touch the same keys. Value comparison cannot identify who wrote an identical value or provide atomic compare-and-set. Respect conflicts, bound retries, and acknowledge this limit.
3. **Unproven rendering behavior:** Most low-level foliage/LOD/fog/lighting candidates lack a current native range/default/effect contract. Keep them disabled until separate existence, effect, restore and collision tests pass.
4. **Performance and accessibility:** No benchmark or overlay readability test has run. Do not promise FPS gains, label a profile universally safe, or enable obstructing tint/bars by default.
5. **Security and lifecycle:** The source exposes restrictions; Blizzard UI code is not proof that tainted addon code has identical permissions. Combat writes, reload behavior, current SavedVariables persistence and current interface number remain test gates.
6. **Distribution:** License, asset ownership records, actual Forever flavor/version identifiers, metadata acceptance and moderation are pending. Source review is not CurseForge approval.

## CurseForge readiness

The release plan is feasible but **not ready for submission**. Recommend a Forever-only artifact built from an explicit runtime allowlist, with one `LumenShift/` folder and a verified matching TOC. Validation/build should be separate from a manually approved upload. Do not trigger publishing on `main` pushes. See [08](08-CURSEFORGE-RELEASE.md) for metadata, asset provenance, licensing, deterministic archive checks, updates, uninstall and moderation gates.

The latest inspected moderation guidance is dated 2026-10-22. Plan an original **400×400 PNG**, functional English description, real game screenshots, clear changelog, correct tags and rights documentation. The public multi-TOC article predates Forever; it does not supply Forever's current dashboard IDs or prove `_Camelot.toc` acceptance. Leave those unknown until a later authorized dashboard review. No dashboard action occurred here.

## Issue #1 disposition

| Issue requirement | Evidence/deliverable | Status |
|---|---|---|
| Current build/interface/API restrictions | 07, 10; owner build report + pinned 70790 source | Build corroborated; installed tuple/interface/runtime gates open |
| Baseline CVars and expanded graphics | 02 | Source/candidate inventory complete; live validation open |
| Per-write readback/range/reset/persistence/collisions/combat | 02, 05, 10 | Unknowns explicit and tests defined; no writes approved |
| Overlays/sound/radial inputs | 04, 07, 10 | Feasibility assessed; client experiments pending |
| Ownership/rollback state machine | 03 | Proposal ready for review |
| Independent delta sets | 04 | Proposal ready; non-NV targets intentionally unset |
| Read-only and future opt-in tests | 05, 10 | Protocols prepared, NOT RUN |
| Architecture/Phase 01 acceptance | 03, 06 | Proposed; not approved or implemented |
| CurseForge flavor/TOC/ZIP/metadata/CI | 08 | Requirements researched; dashboard, legal and QA gates open |
| Present findings and stop | This review package | Awaiting Arctic's decisions; Issue #1 left open |

## Decisions required from Arctic

1. Approve the proposed architecture and **Phase 01A diagnostic/core scope**, with **Phase 01B writes separately gated** on the read-only results and a specific test plan. Proposed first writer: Brightness only, target 75, restoring the captured value even when it is not 45.
2. Approve external-edit-wins conflict handling, no startup reapply/recovery writes, no automatic combat retry, and best-effort orderly-exit restoration only after it has been tested and explicitly enabled.
3. Confirm `Cinematic` as the display name (older docs use `Cinema`), six eventual concepts, optional effects off initially, and quality profiles deferred to Phase 04.
4. Defer or choose a license and asset policy before distribution; confirm eventual Northern Lights Labs credit. No license has been selected.
5. Later, approve an exact client test matrix and separate CurseForge setup/upload steps. Approval of this research is not approval to change live settings or publish.

This is the Phase 00 stopping point. The sourced report can be reviewed now; client-verification checkboxes must stay open until evidence exists.
