# Evidence ledger, risks and decisions
**Updated:** 2026-11-06. Initial research seeds below; NOT a claim of full current-client verification.

## Evidence classifications
- **V — Verified in-game:** reproduced on current user client; build, steps and observed result recorded.
- **S — Source-confirmed:** exact source with build/date and scoped claim; may not prove current client behavior.
- **C — Community report:** user or community testimony without independent current-client check.
- **H — Hypothesis:** plausible technical approach needing validation.
- **X — Unsupported/blocked:** not available through normal game addon API or explicitly excluded.
- **U — Unknown:** missing evidence, investigation queued.

## Initial references for Codex
| ID | Source | Classification | What it establishes | Limitations |
|---|---|---|---|---|
| SRC-01 | https://github.com/Thunderz96/forever-addon-kit | S (beta builds) | Observed Forever beta interface 16001, Mainline-family UI behavior, modern API caveats | Early beta data; recheck launch client |
| SRC-02 | https://github.com/Gethe/wow-ui-source | S (when correct branch/build pinned) | UI source for API implementations and game types | Mirror, not player's installed executable |
| SRC-03 | https://github.com/drengalis/foreverGraphics | S | Another addon implements read/write controls for eight advanced graphics CVars and documents reset expectations | Third-party suggested/default numbers not authoritative |
| SRC-04 | https://github.com/imperial64/dynamic-ambiance-forever | S | Another addon implements Brightness/Contrast/Gamma transitions and documents zone logic | Not proof that all techniques suit LumenShift; conflicts need testing |
| SRC-05 | https://us.forums.blizzard.com/en/wow/t/ive-managed-to-find-the-perfect-advanced-settings/2378746 | C | Community reports aggressive draw distance, grass and lighting commands | Anecdotal effect, risks and build variance |
| SRC-06 | https://undying.app/guides/graphics | C | Catalogs visual CVar candidates; labels some NEEDS TESTING and flags community crash reports | Should not turn candidates into guaranteed-safe values |
| SRC-07 | https://github.com/Osso/wow-ui-sim/blob/master/docs/wowforever-1.60.1-ui-api-deltas.md | S (specified build) | Research on differences in Forever UI API schema | Need exact installed client check |
| SRC-08 | https://us.battle.net/support/en/article/135677 | S (policy link to verify) | Blizzard UI addon policy starting point | Link accessibility/current terms require recheck |
| SRC-09 | User's in-chat advanced graphics guide and 45/60 settings | C (first-party preference) | Desired aesthetic baseline and specific experimental values | No measured local client state supplied |
| SRC-10 | Earlier LumenShift v0.1.0-alpha prototype supplied in a prior chat | S (local artifact only) | A conceptual wheel, six modes, Lua/CVar experiments and original sounds exist | Not yet imported; NOT in-game tested; not production architecture |

## Known useful distinctions
- Forever beta build reports generally describe Mainline-family UI APIs but with its own interface number (SRC-01). Current live build must be recorded.
- Sample graphics-addon code confirms approaches to applying candidate CVars (SRC-03), not values or universal safe ranges.
- Brightness, contrast and gamma can be targeted by existing experimental Forever addons (SRC-04); exact current behavior still needs measured user-client readback.
- WoW addon UI textures may approximate screen tint, but this is not a genuine GPU post-processing shader (research implementation limits).
- Alpha source was mocked/syntax-tested only; no evidence of successful live UI rendering exists.

## Risks to resolve
| Risk | Initial severity | Mitigation/research |
|---|---|---|
| Addon changes CVars that persist after uninstall | High | Precise baseline journal, restore-first instructions and in-client readback |
| Client/graphics menu overwrites linked CVars | High | Detect interaction, apply only diffs, conflict policy |
| Another addon writes same brightness/contrast | High | Ownership/conflict decisions; test with Dynamic Ambiance or similar |
| High-cost foliage/LOD/lighting settings damage FPS | High | Independent quality profiles, opt-in, measured benchmarking |
| Unsupported/unsafe CVar causes instability | High | Whitelist only observed safe controls; stage experimental settings separately |
| Camera/CVar changes disallowed during combat | Medium/High | Feature detection, deferred behavior; no protected bypasses |
| Overlay hides critical HUD or makes accessibility worse | High | Z-order and viewport tests, max opacity, mute/reduce-motion switches |
| Restart/relog needed for effective changes | Medium | Pending flag, honest UI and rollback tests |
| User assumes Cinema/NV are true GPU shaders | Medium | Accurate documentation and mode labels |
| Prototype code is treated as battle-tested architecture | Medium | Mark reference-only and require code review |

## Open decisions (do not assume consent)
- Is the repo to remain public? It currently is. Do not change visibility automatically.
- Final product branding and preferred icon style.
- Which modes are core v1, which modes are experiments.
- Default conflict policy after an external or user change.
- User's tolerance for screen tint and cinematic bars over interface elements.
- Licensing and external assets policy before release.
- Whether old alpha should be imported into a clearly labeled experimental/reference location.
- Whether optional automatic location-based suggestions are desired after v1.
- Whether performance presets should affect frame quality when in combat.

## Evidence record template
Finding ID / Date / Game build / CVar or API / Link or local command / Source class / Expected / Observed / Reproduction steps / Screenshot or log reference / Restore method / Tester / Decision / Open questions.

## Decisions log
| Date | Decision | Authority | Reason |
|---|---|---|---|
| 2026-11-06 | Begin with research-only Phase 00 documentation | Arctic's project direction | User requested Codex lead engineering and verify CVar claims before coding |
| 2026-11-06 | Keep visual modes separate from graphics quality profiles in proposed architecture | Research/design recommendation, not final approval | Prevent surprising changes to FPS or world detail |
| 2026-11-06 | Do not claim current live-client verification from older beta source | Verification policy | Source and build validity matter |
