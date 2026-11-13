# Dev.7 quality profiles and native tier trials

Recorded 2026-11-07. Current user guide: [21](21-BETA-USER-GUIDE.md). Existing Phase 00 research and all prior regressions remain intact.

## Functional profiles

Balanced, Vista and Performance now work without first authoring a custom profile. Current Baseline restores quality originals independently of the visual mode. Existing nonempty custom profiles keep exactly their saved keys/values; built-ins never append to them silently. Empty profiles select the built-in recipe again.

- **Balanced:** enable always-sharpen and use source-UI sharpness midpoint 1; preserve/restore original scene detail.
- **Vista:** sharpen plus bounded increases in foliage density/distance, view distance, terrain LOD and object fade; reduce object cull size within the existing relative test envelope.
- **Performance:** sharpen plus bounded reductions in those scene-detail settings and increased object cull size.

These are authored experimental recipes, not native defaults, benchmark results or a guarantee of improvement. Distance/detail bounds remain the smaller of the existing per-key cap and a 10% step (minimum step 1), relative to each **captured original**, not the active target. Repeated switching cannot ratchet the baseline. Unsupported built-in members are listed as omitted in Studio and logged; required custom members fail the whole custom operation instead of silently disappearing. The source UI's reversed sharpening mapping is documented in the existing register. Render scale, combat cue settings, overall/raid quality, HDR and renderer are not changed.

## Native shadow, lighting and water trials

Advanced Graphics now has actual **Try selected level & restore** controls for:

| Key | Native UI choices | Additional live capability |
|---|---|---|
| graphicsShadowQuality | 0–5 | IsGraphicsSettingValueSupported(key, value, false) == 0 |
| graphicsLightMode | 0–3 | Same; IsSecondaryLightingSupported() == true |
| graphicsLiquidDetail | 0–3 | Same validation result |
| graphicsPBRLiquidDetail | 0–2 | Same; IsPBRWaterSupported() == true |

Source-confirmed choices are not claims of observed rendering or complete dependencies. Missing/error/unexpected capability results remain explicit unavailability; a client-version mismatch alone is not a refusal. The original tier must also be valid for restoration. One click captures the current tier and readable named-watch values before the native call, applies only the chosen tier through Planner/Recovery/WriteBoundary, verifies, waits two seconds, restores the exact tier, then checks every captured watch value again. No unknown child setter is invented. No persistent tier profile is offered yet.

Successful restoration requires the original tier and all captured named values to match. The tier journal (descriptor version 3) and `experiments.sideEffects` snapshot persist in schema 5 as recovery data; a reload does nothing automatically. A failed setter, clamping, combat, late drift, missing readback or external watched change stops automatic work and retains originals. **Restore interrupted quality trial** is a separate explicit action. When the tier is already original but a dependent value differs, a no-setter check retains the unresolved snapshot rather than claiming success. Ordinary graphics/name operations cannot run through an occupied trial.

**Material limitation:** the named watch list is not a complete native dependency enumeration. The mirrored UI source shows tier setters, choices and hardware checks but not the engine's full tier-to-child mapping. A tier can leave a custom child override changed even after its own value returns. The trial detects differences only in captured named values; it never guesses a child repair. This is why these are temporary experimental trials, not advertised as reliable persistent quality-tier presets. Native trial reports are needed to establish actual dependency/restoration behavior. This is a remaining full-beta acceptance gate, not a blanket read-only lock on all quality controls.

## Primary-source artifacts

All retrieved 2026-11-07 from the Blizzard UI source mirror at Gethe commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06` (70862). This is mirrored Blizzard code, not an official guarantee about every client or hardware configuration.

- [Graphics.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua): lines 134–177 define shadow/light/liquid/PBR options; validated options use IsGraphicsSettingValueSupported. Lines 1197–1247 show the overall-quality callback cascading into component settings. LumenShift does not write the overall tier.
- [GraphicsOverrides.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Settings_Shared/Mainline/GraphicsOverrides.lua): conditional native setting registration.
- [VideoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/VideoDocumentation.lua): hardware capability functions and GraphicsValidationResult.Supported = 0.
- [CvarUtil.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXMLBase/CvarUtil.lua): native UI CVar accessors use the normal CVar setter. They do not expose the underlying tier dependency graph.

ConsoleGetAllCommands was investigated read-only in the API source, but is not used to grant arbitrary setting-write access. Console help/categories do not prove reversible dependency mappings.

## Feature and evidence matrix

| Feature | Implementation | Native evidence |
|---|---|---|
| Six customizable modes; Brightness and optional Contrast | Functional, explicit clicks | Dev.6 Night Vision 45/75/45 confirmed; other paths remain experimental |
| Radial/Studio/setup/launchers, personal presets, overlays/audio/accessibility | Functional, preserved | Owner setup/switching report; full render/input/audio evaluation incomplete |
| Current Baseline/Balanced/Vista/Performance | Functional built-ins and exact custom profiles | New dev.7 profile combinations untested in-client |
| Named sharpening/foliage/distance/LOD/bloom/weather controls | Direct Apply and optional reversible trial | Per-setting native visual/dependency/performance results pending |
| Shadow/lighting/water/PBR | Functional temporary native tier trials | Actual native dependency/restoration results pending; persistent tier profiles incomplete |
| Camera/HUD and friendly names | Functional, independent originals | Source API plus owner macro; new integrated behavior pending, see [30](30-CAMERA-MODE.md) |
| HDR/renderer/overall quality/camera lens or motion | Not controlled | Use native game settings; restart and dependency contracts not implemented |

Q01–Q14 simulate usable built-ins, custom preservation, missing members, independent modes, four tier trials, native capability rejection, dependency differences, external changes, reload, setter/readback/restore failures, combat/timers, UI, reentrancy, missing watch provenance and pre-write snapshot drift. K/D/C regressions cover adjacent paths. Simulated tests are not native acceptance. The development archive is for consolidated exploration; **do not label it accepted feature-complete beta or publish it yet**.

Final source validation: **199 passed, 0 failed under Lua 5.1**; syntax checked for 32 runtime modules, eight test Lua files and four binding bodies; structural TOC/version/single-native-CVar-call checks passed; eight Python packaging tests passed. Exact committed-archive hashes and reproducibility results accompany the local ZIP. No installed-game modification or new native test occurred during this development turn.
