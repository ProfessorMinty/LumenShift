# Graphics CVar evidence register

**Investigated:** 2026-11-06. **Target:** owner-reported 1.60.1.70790; matching mirrored UI source. **Approved write whitelist: empty.** This is a research inventory, never a preset to paste into the game.

Evidence labels and pinned links are in [07](07-EVIDENCE-AND-DECISIONS.md). S70790 means source declaration/UI use on that build, not a live result. S-third-party proves what an author wrote; C is a report/preference; H a hypothesis; U unknown; X excluded. No row is Verified in-client.

## Register conventions

For **every row**, these target-client fields are explicitly **U**: existence/readability; current raw value; native default; native accepted range; observed accepted range; setter acceptance; visible effect; reload/restart requirement; persistence; user-lock/secure/read-only flags; combat restrictions; measured performance. Restore outcome is **NOT RUN**, screenshots/measurements **none**. Exact spelling is source-confirmed only where S70790 explicitly uses that name; all other names remain candidates. These shared fields apply to every row, rather than being omitted from a very wide table.

Source slider bounds are a **UI domain**, not the complete native accepted/effective range. Numeric/boolean types below are proposed validation types; getters return strings. Defaults must be read separately from captured originals. Readback does not prove a rendered effect. Risk labels are design judgments: M = visibility/conflict risk; H = costly/interdependent renderer risk; Q = quarantine. No measured FPS claim is made. Tests are defined in [05](05-TEST-PLAN.md) and [10](10-CLIENT-VALIDATION.md).

## Owner priorities and original candidates

| ID / candidate key | Purpose / proposed type | Candidate, never a default | Source evidence | Risk / layer | Collision or dependency; test |
|---|---|---|---|---|---|
| C01 `Brightness` | Exposure/readability; number | Owner 45 baseline / 75 NV | S70790 UI 0–100 step 1 (SRC-11); C beta default 50 and write observations (SRC-04) | M / visual | Graphics Brightness, Contrast/Gamma/HDR, Dynamic Ambiance; R, W1–W4, V1; first candidate only |
| C02 `Contrast` | Tone separation; number | Owner 60 | S70790 UI 0–100 step 1; C beta default 50 | M / visual | Graphics Contrast, Brightness/Gamma; R, W1–W4, V1 after C01 |
| C03 `Gamma` | Tone curve; number | Untouched | S70790 UI 0.3–2.8 step 0.1; C beta author reports effective 0.3–3.0 on 69977 and default 1; do not merge ranges | M / reserved, no preset writes | Graphics Gamma/display pipeline; R, separate range/effect review |
| C04 `ResampleAlwaysSharpen` | Sharpen pass; proposed 0/1 | Owner 1 | S-third-party FG slider 0–1, authored reset 0, suggestion 1; not native bounds | H / quality | Sharpness, upscaler, RenderScale; R/W/B at native and scaled resolution |
| C05 `groundEffectDensity` | Foliage density; number | Owner 256 | FG slider 16–256, authored reset 16 | H / quality | Ground Clutter, Dist/Fade, raid bank; R/W/B forest |
| C06 `farclip` | Terrain visibility distance; number | Owner 5000 | C owner guide; native contract not established here | H / quality | View Distance, terrain LOD, fog; R/W/B vista |
| C07 `lodObjectCullSize` | Object cull threshold; number | Owner 8 | FG slider 1–100, authored reset 15; author says lower draws more objects | H / quality | Environment Detail/FadeScale; R/W/B city-vista; verify direction |
| C08 `lodObjectFadeScale` | Object LOD fade; number | Owner 200 | FG slider 50–300, authored reset 100 | H / quality | Environment Detail, CullSize, doodad LOD; R/W/B vista |
| C09 `groundEffectDist` | Foliage distance; number | Seed 500 | FG slider 40–500, authored reset 70 | H / quality | Ground Clutter, Density/Fade; R/W/B forest |
| C10 `groundEffectFade` | Foliage fade; number | Seed 370 | FG slider 0–500, authored reset 70 | H / quality | Dist/Density; ordering U; R/W/B forest |
| C11 `terrainLodDist` | Terrain LOD; number | Seed 1000 | FG slider 100–2000, authored reset 400; author's note mentions possible native 500 | H / quality | farclip/View Distance; R/W/B vista |
| C12 `reflectionMode` | Reflection method; enum candidate | Seed 3 | FG slider 0–3, authored reset 3; not a native enumeration | H / quality | Liquid/PBR detail, reflection resolution, renderer; R/W/B water |

FG means Forever Graphics 1.1.4 at `fc3f8ad4…` (2026-10-09), declaring interface 16001 without a native build measurement. Its eight sliders are evidence leads, not safe limits. Source inspection does not authorize code/asset reuse.

## Expanded inventory

| ID / key or unresolved setting | Role / candidate | Source evidence (not live validation) | Disposition and dependency tests |
|---|---|---|---|
| C13 `doodadLodScale` | Object detail, seed 200 | C original forum command (SRC-05), build/range U | H, later quality; Environment Detail; R/W/B city-vista |
| C14 `textureFilteringMode` | Filtering, candidate 5 | S70790 UI 0 bilinear, 1 trilinear, 2/3/4/5 = 2x/4x/8x/16x, capability validation | H, later quality; Graphics dropdown; R/W/B angled terrain |
| C15 `ResampleSharpness` | Sharpen strength, seed 0 | S70790 UI 0–2 step 0.1 with reversed mapping | H, later quality; C04/upscaler/RenderScale; R/W/B detail/halos |
| C16 `graphicsViewDistance` | View Distance tier, seed 9 | S70790 UI 0–9 displayed 1–10 (SRC-11/12) | H; indirect farclip/LOD writes must be mapped with W2 |
| C17 `graphicsLightMode` | Secondary lighting, seed 3 | S70790 UI 0–3, gated by `IsSecondaryLightingSupported()` | H, later quality; hardware/lighting; R/W/B interior |
| C18 `sunshafts` | Rays, seed 2 | H; native name/bounds not established here | Q; lighting/renderer; R before any proposed W |
| C19 `shadowNumCascades` | Shadow partitions, seed 4 | H; native bounds U | Q; shadow tier/distance/VRAM; R then separate W/B review |
| C20 `ssaoType` | Occlusion method, seed 0/1 | H; not equivalent to `graphicsSSAO` | Q; SSAO tier/renderer; native enum research before W |
| C21 `giQuality` | Global illumination | U; community crash/darkness reports are risk leads | Q, all values excluded; no claim that values at or below 5 are safe |
| C22 `volumeFog` | Fog, seed 0/1 | H; existence/effect U | Q; visibility/lighting; R, no fog-removal promise |
| C23 `weatherDensity` | Weather, seed 3 | C forum spells `weatherdensity`; canonical case U | H, later quality; R canonical name, W/B actual weather |
| C24 `horizonStart` | Horizon, seed 4000 | H; starter guide labels needs testing | Q; farclip/fog/terrain; R first |
| C25 `cameraDistanceMaxZoomFactor` | Camera zoom, seed 4.0 | C forum command only | X for v1, separate camera scope; range/protection U |
| C26 `RenderScale` | Resolution scaling, no target | S70790 exact key, bounds queried dynamically, Apply flag | Q for v1; upscaler/resolution/GPU; no universal range |
| C27 dynamic resolution | Runtime scaling, key unresolved | U | Q for v1; do not invent a CVar name |
| C28 colorblind/accessibility controls | User accessibility choices | U; excluded from delta sets | X for ownership; never repurpose for NV tint |
| C29 `graphicsShadowQuality` | Shadow menu tier | S70790 UI options 0–5 with validation | H, later quality; cascades/lighting/raid variants; R/W2/B |
| C30 `graphicsLiquidDetail`, `graphicsPBRLiquidDetail` | Water menu tiers | S70790 names, PBR capability gate (SRC-12) | H, later quality; no enum target selected; R/W2/B water |
| C31 `waterDetail` | Low-level water | U; unconfirmed crash-report lead | Q, no writes; not interchangeable with C30 |
| C32 `graphicsGroundClutter`, `graphicsEnvironmentDetail` | Menu tiers | S70790 UI 0–9 displayed 1–10 | H, later quality; indirect effects; R/W2 before admission |
| C33 `graphicsQuality`, `raidGraphicsQuality`, `RAIDsettingsEnabled`, `raidGraphics*` | Overall presets and alternate bank | S70790 child-update callbacks and raid bank (SRC-11/12) | Q, observe only; broad fan-out, no overall-preset shortcut |
| C34 `HDRBrightness`, `HDRPeakBrightness`, `useHDRBrightness`, `useHDRPeakBrightness` | HDR pipeline | C beta author's enumeration (SRC-04) | Q; units/display/enable flags; separate HDR investigation |
| C35 backend/shaders: `gxapi`, `renderFormat`, `HDROutput` | Renderer/format | S70790 UI references `gxapi`; other native contracts U | Q; restart/display risk; native menu only for now |
| C36 `bloomUserMult` | Bloom amount | S70790 conditional linear-pipeline UI 0–1 step 0.2 | H, later lab; no target; R/W/V |

Missing from inspected UI files does not mean absent in the native engine. The UI is not a complete registry. SRC-06 was read for lead triage; its recommendations are not adopted as technical authority.

## Per-key admission and restore record

Every tested key needs: ID; canonical name; exact build/interface; source; API used; current raw string; default raw string; flags; UI bounds; accepted values; visually effective values; persistence; reload/restart effect; combat result; menu/raid/addon collisions; indirect keys; hardware; metrics/screenshots; restore result; tester; approval; open questions.

**Restore rule for every admitted key:** retain the original raw string before the first owned write; restore through the validated API only while current still matches the last owned value; verify immediately and after the tested settle interval. Never substitute FG reset values, 45, or engine defaults. If a safe before-value cannot be read or restored, reject admission. No reset-all command.

**Admission rule:** R probes + reviewed source + explicit write-test approval + W1 round trip/effect + W2 collision/side-effect mapping + W3 lifecycle + W4 restrictions + relevant V/B tests. Unknown or reload-dependent controls remain disabled. Brightness is the first recommended experiment, not approved. Menu tiers require a complete known side-effect closure; unmapped fan-out disqualifies them.
