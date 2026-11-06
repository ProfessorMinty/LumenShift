# Graphics CVar investigation register
**This is a research inventory, not a verified whitelist or a ready-to-apply preset.** Values are supplied by Arctic or suggested by community sources, not claimed to be safe maxima or actual in-game defaults. Codex must validate each setting against the current Forever build.

## Evidence levels
- U = user-reported preference/guide (not directly game-tested here)
- T = implemented in inspected third-party Forever addon; availability still needs user-client readback
- C = community-reported in a WoW discussion/guide; may be build-dependent
- ? = hypothesis needing explicit check
- V = verified in the user's current client with captured test (NONE yet)

## Source links
- User-supplied guide in project conversation (no permanent public URL)
- Forever Graphics: https://github.com/drengalis/foreverGraphics (source/README, version 1.1.4 when first reviewed)
- Community advanced graphics post (Oct 2026): https://us.forums.blizzard.com/en/wow/t/ive-managed-to-find-the-perfect-advanced-settings/2378746
- Forever graphics guide: https://undying.app/guides/graphics (some entries explicitly labeled NEEDS TESTING)
- Dynamic Ambiance Forever: https://github.com/imperial64/dynamic-ambiance-forever
- Blizzard UI source mirror: https://github.com/Gethe/wow-ui-source

## Priority: user baseline
| CVar | Candidate | Intended effect | Evidence | Open verification |
|---|---:|---|---|---|
| Brightness | 45 (baseline) / 75 (night) | Visual exposure/readability | U, third-party CVar addon T | Exact range/type/readback, reset, contrast interactions, persistence |
| Contrast | 60 (baseline) | Contrast/moody look | U, T | Exact range and value interpretation |
| Gamma | untouched | Gamma affects look; do not change by default | T | Identify current value, valid range and interactions |
| ResampleAlwaysSharpen | 1 | Image sharpening | U, T, C | Verify real behavior at chosen resolution and upscaling |
| groundEffectDensity | 256 | Denser ground clutter | U, T, C | Client accept/clamp, actual FPS cost |
| farclip | 5000 | Terrain draw distance | U, C | Range, interaction with graphicsViewDistance and graphics menu |
| lodObjectCullSize | 8 | Keep small objects visible farther | U, T, C | Inverted relationship and impact |
| lodObjectFadeScale | 200 | More distant object LOD | U, T, C | Whether current build honors value |
| groundEffectDist | 500 | Draw foliage farther | T, C | Range, density interaction and performance |
| groundEffectFade | 370 | Longer ground-clutter fade | T, C | Range and interaction with Dist |
| terrainLodDist | 1000 | Terrain detail at distance | T, C | Current-client default may differ from 3rd-party list |
| reflectionMode | 3 | Reflection quality | T, C | Does it alter visible reflection in this renderer/build? |

## Candidate expansion (none approved for automatic application)
| CVar or setting | Candidate / concern | Evidence | Proposed treatment |
|---|---|---|---|
| doodadLodScale | 200 from community post | C | Test visuals + FPS |
| textureFilteringMode | 5 suggested as a high anisotropy tier | ? | Verify enumeration from client UI source |
| ResampleSharpness | 0 proposed as sharpest by guide (counterintuitive slider) | C | Verify actual range, inversion and ResampleAlwaysSharpen interaction |
| graphicsViewDistance | 9 suggested max-range graphics-menu tier | ? | Map preset dependencies before exposing |
| graphicsLightMode | 3 suggested quality tier | ? | Check existence/meaning |
| sunshafts | 2 candidate | ? | Verify range and capture consistent lighting |
| shadowNumCascades | 4 candidate | ? | Verify ranges, VRAM/performance cost |
| ssaoType | 0/1 candidate | ? | Verify methods/range, avoid assumptions |
| giQuality | reports of very dark visuals or stutters | C | Advanced lab only; NEVER automatic without risk review |
| volumeFog | 0/1 candidate | ? | Verify client availability |
| weatherDensity | 3 community command | C | Verify actual CVar capitalization/effect, weather test |
| horizonStart | 4000 from third-party guide; NEEDS TESTING | C | Exploratory only |
| cameraDistanceMaxZoomFactor | 4.0 community report | C | Separate camera-profile feature; possibly protected/restricted |
| render scale / dynamic resolution | varies by client and GPU | ? | No writes in v1 without strong evidence |
| colorblind modes | accessibility, not true NV | ? | Do not hijack user's accessibility choices |
| shadows, water, shaders / HDR | variable | ? | High-risk; prefer graphics-menu or explicit advanced-only controls |

## Required columns for Codex's reconciled inventory
Name | client build | purpose | origin/source URL | source classification | exists? | GetCVar current | documented default | documented accepted range | observed accepted range | SetCVar effective? | reload needed? | persists? | protected/in-combat? | performance | graphics menu collisions | restore behavior | quality tier | screenshots/measurements | open questions.

## Read-only initial probe guidance
- Client info: /dump GetBuildInfo()
- Example inspect: /dump GetCVar("Brightness")
- Example inspect: /dump GetCVar("groundEffectDensity")
- Check for availability of the intended inspection API before calling it. Do not ask the player to run a dozen unreviewed console SET commands.
- Preserve original values and have rollback procedure ready BEFORE any write experiment.
- Reset a CVar to its client default only if that is specifically the user's choice; restoring captured original is the normal mode exit.

## Source caveats
A third-party addon listing 'reset defaults' does not prove the user's live game default. Some resources explicitly warn particular modern-client settings might not exist in Forever. No FPS gains/costs or safety can be inferred without measurements. Specific numeric candidates must not be shipped as universally recommended settings.
