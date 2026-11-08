# WoW graphics: native controls, Lua, console and external rendering

Research date: **2026-11-07**. This investigation deliberately includes supported, hidden, experimental and external/client-modifying techniques. Technical capability, addon accessibility, actual Forever compatibility and publisher permission are separate questions. Inclusion here is not an implementation, compatibility pass or permission claim.

Repository verified: ProfessorMinty/LumenShift, `feat/beta-integration`. Runtime remains **0.2.0-dev.12 / adf7763f**. This delivery changes research documentation and reference data only. No game, driver, operating-system setting, native CVar, installed addon or external renderer was operated or modified.

## What the wider research changes

The earlier [mode audit](38-MODE-AUDIT-AND-OPTICS.md) describes the addon boundary, not the limit of graphics software generally. **Actual dark-edge filters, monochrome conversion, color grading and additional sharpening are technically available through external shaders.** Some need only the completed color image, not depth. Other effects need depth/normal data or engine integration. That distinction matters more than whether a setting is visible in WoW's Options screen.

For LumenShift itself, there are worthwhile native controls beyond brightness: CMAA2 detail behavior, resampling, texture filtering, AO internals, supported lighting/water tiers, camera FOV and composition, and capability-aware display/performance information. Native HDR, dynamic resolution, VRS and latency settings also exist in the inspected sources, but they are different systems with different dependencies. They should not all become side effects of clicking Night Vision.

This is a broad map with an explicit source boundary, not a claim to know every private engine switch or future build. The source/API inventory is substantial; actual visual and restoration testing remains narrower.

## Sources, builds and inventory method

Rechecked the remote `forever` branches during this research:

- **F1:** Gethe/wow-ui-source at `9dc84f0d3bbae1768ac3405b3716000bd93eda06`, commit message **1.60.1 (70862)**, dated 2026-11-07 UTC. The mirrored Blizzard-authored UI/API files are source evidence for this branch; a shared file's existence alone does not establish that every conditional feature is available.
- **F2:** Ketho/BlizzardInterfaceResources at `d1ee569878094270c0ad8d8b00de0762158fd578`, commit message **1.60.1 (70532)**, dated 2026-10-21. Historical native console metadata, not the owner's current configuration. This branch was still older than F1 when checked.
- **Owner evidence:** the existing dev.10 export on **1.60.1:70862:16001**, and the earlier accepted Brightness visual/readback round trip. No repeated launcher verification is requested.
- **External sources:** manufacturers' documentation, tool authors' repositories and project descriptions, and Blizzard's own announcements. Forum anecdotes surfaced during discovery but are not used to establish current compatibility or ban safety.

The reference files are searchable data, not executable tweak packs:

- [701 graphics and related CVars](reference/FOREVER-70532-GRAPHICS-CVARS.csv): **all 280 category-1 Graphics CVars** parsed from F2's main `CVars.var`, plus **421 camera/nameplate/name/accessibility and related entries** selected by explicit name families. Columns retain the captured default as a string, native category, captured server-storage/secure flags and a source-line link. Defaults are not recommendations. Read-only/locked/current flags are not inferred from this older table.
- [25 graphics-category console commands](reference/FOREVER-70532-GRAPHICS-COMMANDS.csv): F2's main `CVars.command` category 1. Commands are not CVars and do not share a generic restore model.

Extraction used a text parser, not execution of downloaded Lua. The main section yielded **1,785 CVar records**; the separately labeled PTR block's ten records were excluded. Related selection was category 1 or a case-insensitive prefix/exact match for camera, test_camera, UnitName, nameplate, findYourself, Outline, colorblindMode, useHighResTextures, graphicsQuality, raidGraphicsQuality, screenEdgeFlash, Shake or MotionSickness. This broad selection includes many HUD controls; it does not mean 701 independent image-quality effects. Raw help prose and third-party implementation code were not republished in the CSVs.

F1 also has conditional controls absent from that older category inventory, including secondary lighting/PBR selectors. Therefore the CSV is a reproducible **70532 snapshot**, not a complete current-build allowlist. Category and default data can change. Source presence, successful reading, accepted setting, effective rendering, exact restoration and acceptable performance are six different levels of evidence.

## Five places where the image can change

| Control surface | What it can affect | What it does not establish |
| --- | --- | --- |
| **WoW native renderer** | Geometry detail, textures, shadows, water, AO, selected post-processing, resolution and display behavior. | A hidden CVar is not necessarily active, public, unrestricted or useful on every renderer. |
| **WoW Lua/UI** | Native exposed settings, camera/HUD behavior, addon textures/animations and separately rendered UI model scenes. | No general scene-buffer/custom-shader interface was found. A UI texture is not the world framebuffer. |
| **GPU driver / OS / monitor** | Output color/HDR, scaling/sharpening, synchronization, frame caps, some filters and generated frames. | Ordinary addon Lua cannot directly configure these tools. A driver feature is not a native WoW CVar. |
| **External post-processing / hooks** | Color-image filters; sometimes depth-based effects, swapchain changes and HDR retrofit. | Author-described capability does not prove Forever loading, depth availability, permission or compatibility. |
| **Asset/engine modification or offline rendering** | Different materials, meshes, world data, lights or rendering algorithms in an appropriate modified/offline environment. | Not an ordinary addon feature or an authorized change to the official online client. Offline rendering is not a live gameplay screenshot. |

## Native settings: what the sources actually expose

The table combines F1's UI mappings with F2's captured names/help. **F2-only** entries are historical research candidates. The exact original must remain separate from the native default and from the desired preset. No suggested maximum below is an authorization to set it.

| Area | Native controls / evidence | Practical meaning and limits |
| --- | --- | --- |
| Brightness, contrast, gamma | F1: `Brightness`, `Contrast` 0–100; `Gamma` .3–2.8. | Useful broad image controls. They are not selective shadow recovery, local contrast or a programmable tone curve. Changing all three together obscures what helped. |
| Independent sharpening | F1: `ResampleSharpness` 0–2, reversed UI direction. F2: `ResampleAlwaysSharpen`. | Lower raw strength is stronger. Sharpening can operate separately from lowering render resolution. Avoid stacking native, driver and monitor sharpening without a comparison. |
| Anti-aliasing | F1: `ffxAntiAliasingMode` none/FXAA low/FXAA high/CMAA/CMAA2, conditional support; `MSAAQuality`, `MSAAAlphaTest`; `AntiAliasingSupported()` and `MultiSampleAntiAliasingSupported()`. | MSAA uses a compound representation, not a single arbitrary level. AA and sharpening solve different problems; stronger sharpen can expose aliasing. Do not import Retail/TAA/DLSS assumptions into this menu. |
| Hidden CMAA2 tuning | F2: `CMAA2ExtraSharpness`, `CMAA2Quality`, `CMAA2HalfFloat`. | ExtraSharpness is documented as preserving more text/shape detail at the expense of AA. Quality is a separate 0–3 algorithm setting in the capture. Only relevant if that AA path actually uses these fields; read/write/effect on the owner client is not established. HalfFloat is arithmetic precision, not a user sharpness knob. |
| Resolution and resampling | F1: `RenderScale`, native min/max queries; `ResampleQuality` 0 point, 1 bilinear, 2 bicubic, 3 FSR. | Render scale changes scene sampling work; at twice each dimension there are four times as many pixels, not a guaranteed fourfold frame-time change. FSR option value 3 does **not** mean FSR version 3 or frame generation. |
| Dynamic resolution | F2: `DynamicRenderScale`, `DynamicRenderScaleMin`, `targetFPS`, `useTargetFPS`. | Metadata describes reducing scale when GPU-bound; it also labels the feature beta and warns of hitching/vsync problems. It cannot be presented as a CPU-bound raid fix or a universally best automatic setting. |
| Texture filtering | F1: `textureFilteringMode`: bilinear, trilinear, 2x/4x/8x/16x anisotropic. | Relevant to oblique ground/wall texture readability. It does not replace AA or create higher-resolution source artwork. |
| Texture resolution/assets | F1: `graphicsTextureResolution`; conditional `useHighResTextures` with `AreHighResTexturesAvailable/Installed` checks and a possible client-restart commit. F2: `worldBaseMip`, `terrainMipLevel`, component/cache fields. | High-resolution asset availability, installed packages, memory use and quality level are distinct. Do not promise downloadable HD art merely by changing a bit. |
| Shadows | F1 native shadow tier; F2 `shadowMode`, `shadowTextureSize`, `shadowNumCascades`, `shadowSoft`, `shadowBlendCascades`, `entityShadowFadeScale`, raid variants. | Resolution, coverage and softness interact. Captured help has bounded examples; popular 8192/16384 tweak lists do not prove engine support or improvement. Tier changes can overwrite custom leaves. |
| Ray-traced shadows | F2 `shadowRt` 0–3; F1 support results include RT/DX12 requirements. | A ray-traced-shadow path is not full path tracing, ray-traced reflections or global illumination. Hardware/client support and effective behavior must be checked. |
| Ambient occlusion | F1 `graphicsSSAO`; F2 `SSAO`, `assaoRadius`, `assaoShadowMult`, `assaoShadowPower`, `assaoDetailShadowStrength`, blur/edge/fade parameters. | Contact-depth shaping is relevant to darker creases. Detail strength metadata warns about temporal instability. `assaoSharpness` controls AO edge bleeding rather than texture sharpness. Historical internal ranges are not good preset targets. |
| Lighting/material response | F1 conditional `graphicsLightMode`; F2 `clusteredShading`, `maxLightCount`, `maxLightDist`, `specular`, `componentSpecular`, `componentEmissive`. | Controls existing rendering paths/material response. No world-positioned lantern/light-creation API was found. Disabling specular can remove material information rather than simply remove glare. |
| Bloom and special effects | F1 `bloomUserMult` shown only with `C_VideoOptions.IsLinearEnabledOnStart()`. F2 `bloomEnable`, `ffxGlow`, `ffxDeath`, `ffxNether`, `ffxVenari`, `ffxLingeringVenari`. | These are not interchangeable. An effect toggle can gate a game-triggered effect without activating it at will. `ffxDeath` metadata mentions death desaturation; that is not evidence of an always-on monochrome mode while alive. |
| Water/reflections/refraction | F1 liquid/PBR-liquid tiers gated by PBR support; F2 `waterDetail`, `reflectionMode`, `reflectionDownscale`, `refraction`, `rippleDetail`, raid variants. | Surface quality, reflected scene detail and distortion are different effects. A water-quality switch is not a general reflection shader for all materials. |
| Fog, weather and sky | F2 `volumeFog`, `volumeFogInterior`, `volumeFogLevel`, `weatherDensity`, `sunShafts`, `SkyCloudLOD`, horizon fields. | Potential atmosphere/performance changes, subject to active paths and game-authored scenes. Removing fog changes composition; it does not increase the source detail of distant geometry or authorize world-time/weather control. |
| Foliage and distance | F1 view/environment/clutter selectors; F2 `groundEffectDensity/Dist/Fade`, `farclip`, `terrainLodDist`, `lodObject*`, `entityLodDist`, `wmoLodDist`, `doodadLodScale`. | Different geometry systems have separate draw/cull/fade behavior. Longer distances may add CPU work and memory pressure. Culling size and fade controls do not necessarily increase quality when their numbers increase. |
| Particles and encounter cues | F1 spell/particle/projected-texture controls; F2 `particleDensity`, `particleMTDensity`, `spellClutter`, `particulatesEnabled`, `DepthBasedOpacity`. | Some visual density can be reduced, but removing projected effects can remove useful ground information. Preserve gameplay legibility when defining quality profiles. |
| Variable-rate shading | F1 `vrsValar` disabled/standard/aggressive with capability checks. F2 `vrsWorldGeo`, `vrsParticles` and internal VALAR parameters. | Shading work can vary across pixels without simply changing display resolution. This is a performance/quality tradeoff, not a universal detail enhancement; internal formats may be strings such as `1x1`. |
| Native HDR | F2 `HDROutput`, `HDRBrightness`, `HDRPeakBrightness`, `HDRFactor`, `useHDRBrightness`, `useHDRPeakBrightness`, `RenderFormat`, `linear`. | Output mode, renderer precision, reference brightness and display peak are different. Captured nits/defaults are not monitor calibration. Working HDR requires an appropriate renderer/OS/display chain; raw CVar acceptance alone cannot prove HDR output. |
| Presentation and latency | F1 `LowLatencyMode`: Auto, disabled, built-in, Reflex, Reflex+Boost, XeLL through support checks; F2 `GxMaxFrameLatency`, `vsync`, foreground/background/loading caps. | Latency and smoothness are different from scene quality. Avoid contradictory native/driver caps and assuming Reflex applies to every GPU. |
| Renderer/backend internals | F1 graphics API/adapter selection and commit handling; F2 `GxApi`, `GxAdapter`, `GxPrismEnabled`, `gxMT*`, caches, job limits, streaming settings. | Usually driver/engine troubleshooting, not mode styling. Some metadata explicitly mentions artifacts; blindly enabling every threading flag is not an optimization strategy. Renderer/window/restart settings need a different workflow from reversible per-mode leaves. |
| Screenshots | F2 `screenshotFormat`, `screenshotQuality`, `screenshotSizeOverride`; native `Screenshot()` and completion events. | Capture format/size is not the same as ordinary render scale. Oversized capture needs separate memory/output validation. Avoid asserting an internal screenshot includes every external/monitor effect. |

### Native presets and raid settings are separate systems

F1 supports normal and raid/battleground component recipes, displayed levels 1–10 versus raw selectors 0–9, and native per-key recommendation/default mapping. Recommendation is not a newly run benchmark. It can differ per component; reading one tier is not a complete description of customized leaves. See [35](35-GRAPHICS-SELECTION-AND-RECOMMENDATIONS.md) and [37](37-NATIVE-GRAPHICS-BANKS.md).

Forever also has **Classic/Enhanced experience presets** and HD/SD model choices. Blizzard describes these as presentation/UI/player-choice features. F1's `Preset.lua` calls `C_GameRules.SetForeverExperiencePresetPostLogin` and separate HD/SD APIs. Those presets can affect more than graphics, including interface choices; they must not be used as a shortcut for LumenShift's quality profile or Original mode. [Blizzard launch overview][B1], [native preset source][F3].

Blizzard's Forever GPU announcement explicitly identifies an updated rendering requirement, RGBA16F UAV support in compute shaders. This is concrete evidence against treating Forever as the original 2004 renderer. It is not evidence that a particular GPU meets all minimum requirements or that all shader features are accessible to addons. [B2]

## Lua and console: actual interfaces, not magic alternate permissions

The inspected source defines `C_CVar` getters and the wrapper `SetCVar`, which forwards to `C_CVar.SetCVar`. Writing through `/console`, `/run` or a Settings wrapper does not manufacture a new rendering effect and is not evidence of bypassing a restriction. `ConsoleGetAllCommands()` is a **global function** in F1's Console documentation; do not guess a `C_Console` namespace. It returns command metadata including type/category/help and potentially script content. A research collector should retain only intended names/metadata, not indiscriminately export arbitrary scripts. [F4], [F5]

Useful reference calls, shown for understanding rather than as another requested owner checklist:

```lua
-- Reads. Missing/restricted APIs or values still need guarded handling.
C_CVar.AreCVarsLoaded()
C_CVar.GetCVar("ResampleSharpness")
C_CVar.GetCVarDefault("ResampleSharpness")
C_CVar.GetCVarInfo("ResampleSharpness")
GetCameraFOVDefaults()
C_VideoOptions.IsLinearEnabledOnStart()
IsGraphicsSettingValueSupported("graphicsSSAO", 4, false)
```

The support result is an enum: **0 means Supported**, not a boolean true. The native FOV query returns the default and player min/max; do not hardcode a widely circulated limit. Getter/default values are strings or nil where documented. `GetCVarInfo` exposes storage/security/read-only/lock information; current restrictions must be checked, not copied from historical CSVs.

The ordinary write mechanisms are `C_CVar.SetCVar(name, value)`, the forwarding `SetCVar` wrapper, and `/console <name> <value>` for an actual public variable. `/run` executes Lua rather than being a different renderer. LumenShift must continue routing its operations through its single boundary, preserving originals and checking results; these examples do not add a second writer. A console command's boolean return is not equivalent to an effective setting or completed renderer restart.

F2 also captures standalone commands. `GxCurrentAPI`, `GxCurrentGPU`, `GxFrameStats`, `GxListGPUs`, size/memory queries and `LogFps` are useful research leads; some diagnostics write logs. `GxRestart`, `D3D11`, `D3D12`, `SetGraphicsQuality`, `SetGraphicsQualityRAID`, `ToggleWindowMode` and `reloadUI` are not harmless getters. `DefragmentGPU` is an engine action, not a persistent quality value. Their current access/effect is untested. The captured `enable` help describes `/console enable` and the `-console` launch option; enabling a console does not unlock private engine powers.

Config-file edits can set persisted values outside Lua, but they do not create an unimplemented shader or a missing server feature. Configuration persistence, caches, restart requirements and game overwrites matter. A full reset also destroys unrelated preferences and is not an adequate substitute for per-key restoration. No configuration file or launch argument was changed in this investigation.

## Camera, HUD, accessibility and addon-rendered scenes

**Camera:** F1 exposes a native `cameraFov` slider with dynamic bounds, and F2/API captures include zoom/view functions and camera follow, smoothing, shoulder offset, dynamic pitch, head movement and target-focus settings. The DynamicCam author's code demonstrates real use of these native facilities, including competing motion-sickness settings. This is useful implementation precedent, not a Forever validation result or license to copy its code. A camera-composition feature should respect the owner's motion/centering preferences and other camera addons. [F6], [A1]

**Viewport versus bars:** Sunn's author describes resizing the rendered world area, which is different from covering its edges with black textures. That makes a true viewport feature worth investigating rather than claiming it is categorically impossible. Its behavior, frame restrictions, aspect/FOV, cursor targeting and interaction with modern UI need **Forever-specific** tests. Current LumenShift only draws optional bars. [A2]

**Names and HUD:** native UI visibility, friendly/enemy/player/pet name settings, nameplate density/distance and player/target/quest highlighting are separate systems. Selection-outline options do not create arbitrary terrain/object contours. LumenShift currently owns only the two approved friendly-name keys. The CSV records other names as research; it does not broaden runtime ownership.

**Accessibility color controls:** F1 exposes three named color-vision filters and strength. F2 marks `colorblindSimulator`, `colorblindWeaknessFactor` and `daltonize` **secure**. A trusted native menu's ability to change them does not prove ordinary addon access. The inspected UI does not offer a generic grayscale/LUT setting. Preserve genuine accessibility choices rather than repurposing them as a fantasy-mode color preset. [F7]

**UI ModelScene:** F1's model-scene API exposes local light direction/position/color, fog, camera composition and actor desaturation. This could support a polished character-preview/portrait/photo-stage tool **inside an addon-owned model scene**. It cannot be assumed to relight the outdoor world or attach a real lamp to the player. Texture desaturation similarly acts on an addon texture. [F8]

**Special screenshot APIs:** the generated PhotoSharing API has a screenshot-preview texture and authorization/upload flow. Its existence is not a general real-time scene sampler or shader API, and it has no place in an automatic graphics-mode operation. No authorization or upload was attempted. [F9]

## External techniques, including unsupported ones

This section is intentionally broader than the planned public addon. Tool-specific support, client compatibility, operating-system requirements and publisher policy remain separate.

| Technique | Technically available capabilities | Forever/LumenShift implications |
| --- | --- | --- |
| **ReShade / SweetFX color-buffer shaders** | Sharpen, monochrome, levels/curves, color balance, LUTs, vignette, simulated grain, bloom and color-based edge darkening. | External GPU code, not Lua. These can often operate without depth, but may also affect HUD/text and require compatible loading. Current Forever compatibility was not demonstrated. |
| **Depth-based external effects** | Depth of field, screen-space AO and depth-aware edges; some tools synthesize additional lighting from screen information. | Need usable depth and sometimes reconstructed normals. Offscreen/hidden geometry and actual material/light data are missing; these are not automatically full scene ray tracing. ReShade's own public description says multiplayer depth access is restricted. No restriction bypass was attempted. |
| **NVIDIA Freestyle / RTX filters** | Driver/app filters, sharpening, vibrance and RTX HDR, subject to GPU/OS/game support. | NVIDIA lists WoW and Classic in search-visible supported-game content, but its dynamic table did not establish the Forever executable's exact filter features in this research. A Forever Game Ready driver announcement is not a Freestyle certification. No addon control bridge was found. [E3], [E4] |
| **NVIDIA NIS / DSR / DLDSR** | Spatial scaling/sharpening or rendering above display resolution and downsampling. | Distinct from native FSR and from DLSS integration. Higher-resolution rendering costs work; SDK availability does not mean Lua can install it into WoW. [E5], [E6] |
| **AMD RIS / VSR / RSR** | Driver sharpening; supersampling/downsampling; driver spatial upscaling. | AMD recommends native FSR where supported rather than blindly stacking RSR. Some driver features disable others. Hardware/display-mode requirements apply. [E7], [E8] |
| **Windows Auto HDR / display calibration** | SDR-to-HDR presentation on supported games/displays, calibrated dark/bright endpoints and output appearance. | Separate from native WoW HDR and RTX HDR. Avoid multiple conversions being unintentionally enabled together. Monitor controls can alter what the player sees without changing an in-game screenshot. [E9], [E10] |
| **Driver/capture frame generation** | AFMF and Lossless Scaling can add displayed/interpolated frames in supported configurations. | Generated frames are not new server/game simulation updates and do not automatically reduce input latency. Extra GPU work and artifacts/HUD handling matter. Not a native LumenShift graphics mode. [E11], [E12] |
| **Special K and similar rendering hooks** | Author-documented swapchain/display control, performance tools and HDR retrofit in supported games. | Process-integrated external rendering tooling; no verified Forever support or permission. Capability is included here without recommending installation into the owner's client. [E13] |
| **Asset extraction / offline editing** | wow.export previews/exports models, textures and map data for separate tools. Noggit-family projects author terrain/object/world data; a modern fork claims Forever support. | Can produce materially different offline art/worlds, not a Lua upgrade to the official game's assets. Author claims need independent format/build validation. Access to extracted artwork does not grant redistribution rights. [E14], [E15] |
| **Memory patching, injected unlockers, modified clients** | In principle can change client behavior beyond the public API, depending on the executable and tool. | No particular Forever tool, bypass or behavior is validated here. These are executable/security-boundary modifications, not console settings. Server-authoritative state and information never sent to the client are not made available by a visual preset. Blizzard explicitly prohibits unauthorized client-modifying/security-bypassing software. [P1] |

### The dark-lines effect is real outside the addon API

The inspected SweetFX **Cartoon** shader samples the color backbuffer, compares neighboring luminance values and subtracts a strength-controlled edge term from the color. It does not sample depth. Therefore a **dark contour-like image treatment is technically feasible with color-only post-processing**. It can also outline texture markings or text and miss edges with similar brightness; it does not know which pixels are enemies, stone joints or the sky. That limitation follows directly from the sampled inputs. [E1]

The same author's **Monochrome** shader converts the sampled image using color coefficients and a saturation control. A real monochrome/phosphor-inspired output is therefore achievable externally; an ordinary green UI overlay is not equivalent. Pairing luminance conversion, controlled gain/contrast, sharpening and modest edge darkening is a plausible visual design for external goggles. It is **not thermal sensing**, and no specific Forever integration is established by the shader's existence. [E2]

Depth-based outlining is a different algorithm and requires depth access; it is not necessary to claim every outline shader needs depth. Likewise, a screenshot editor or video filter could produce these looks offline without affecting gameplay at all. Research imagery made that way must be labeled as a concept, not native addon output.

### Permission and compatibility findings

The request's “legal or not” scope is treated as a request to include techniques rather than filter the research to approved addon features. Blizzard's Terms of Service and account-enforcement policy are not synonymous with criminal law. The official 2025 statement prohibits unauthorized client modification and security bypass; community “it worked” or “I was never banned” posts do not establish permission. Manufacturer driver support also does not authorize an unrelated injector. [P1]

No blanket claim that all external overlays are prohibited, or that a named injector is universally safe, is made here. Ordinary driver/display features, Lua APIs, injected shader programs and executable patches are materially different mechanisms. The current public-addon design remains native Lua/UI plus admitted CVar operations. External research does not silently authorize bundling an injector, adding an executable companion or operating the owner's game.

## Claims this research does not support

- “Set `ResampleQuality` to 3 to enable FSR3/frame generation.” It is the menu's numeric option for FSR, not a technology version.
- “An updated NVIDIA driver adds DLSS to Forever.” The Forever driver article also discusses DLSS in other games; its Forever section does not announce native DLSS integration. [E4]
- “Any CVar found by enumeration is writable.” Historical secure flags, runtime restrictions, support predicates and unused paths contradict that assumption.
- “A custom `RegisterCVar` name creates a renderer feature.” Registration does not provide the missing native implementation.
- “Set every range to its maximum.” Some controls run backward, some are enums/strings, some are internal precision/job counts and some have explicit artifact warnings.
- “`ffxDeath` gives a selectable white-phosphor filter.” Its metadata describes a game-state effect; forcing ordinary always-on grayscale is unproven.
- “Higher brightness, less fog and fewer particles always improve visibility.” These can reduce useful contrast, atmosphere or encounter cues.
- “A model-scene light can illuminate the game world.” Those are different rendering contexts.
- “A screenshot-size override is free supersampling during normal play.” Capture dimensions, runtime rendering and external output scaling are separate.
- “A driver-generated 120 FPS means the game now processes input/simulation at 120 FPS.” Displayed/generated and application-produced frames are different measures.

## What this means for the next LumenShift work

The owner's recorded dev.10 scene had **RenderScale 1**, **CMAA2 selected (`ffxAntiAliasingMode=4`)**, **sharpening enabled at raw strength 1**, **16x filtering** and **AO tier 4**. Those past observations make this a more useful priority list than a generic “enable high quality” preset:

1. **Native sharpness per mode**, with explicit before/after comparison and correct shared-key restoration. The [mode audit](38-MODE-AUDIT-AND-OPTICS.md) specifies the ownership model.
2. **CMAA2 ExtraSharpness as an isolated research candidate**, since that AA path was selected. Read its current/default/flags, compare motion and thin geometry, and restore precisely before considering an ordinary control. Do not assume stronger AA plus stronger sharpening is automatically better.
3. **AO contact-detail experiments** after confirming the active implementation. Raising the already-maximal tier does not answer the user's request for darker definition. Keep native tier choice independent of modes and preserve frame time.
4. **Bloom/glow path investigation**, with the linear capability and actual visual observation; do not collapse several similarly named toggles into one uncontrolled “disable bloom” macro.
5. **Camera FOV/composition and optional viewport exploration**, with dynamic native bounds, camera-addon coexistence and the existing HUD/effects issue fixed first. A separate UI model-scene photo stage is another legitimate creative direction.
6. **Capability-aware display/performance information**, explaining native HDR, dynamic scale, VRS, latency and normal/raid choices. Route restart/display/driver operations to the appropriate native UI or external tool rather than ordinary mode switches.
7. **External-look concepts**, if wanted later, can demonstrate monochrome or dark contours accurately labeled as externally rendered. Keep them distinct from features promised in the public Lua addon.

These priorities extend the research, not a new write allowlist. No new runtime features were implemented in this delivery.

## How to establish the actual best quality

Use controlled comparisons rather than a universal max-settings script. Preserve the chosen baseline and observe current capabilities. Change one feature at a time while holding resolution, render scale, AA, time/weather, camera, scene and external filters constant as far as possible. Test a dark torch-lit interior, oblique ground textures, distant foliage, water, moving thin edges and representative combat cues. Inspect both still images and motion; disclose uncontrollable differences.

Record accepted/effective raw values, dependency changes, restoration, visible preference and repeatable performance observations. A standard FPS getter or a short UI sampling loop is not a complete frame-time or GPU bottleneck analysis. PresentMon's author documents application/display timing and GPU-busy metrics for deeper external analysis; it is a separate measurement tool, not a required addon dependency. [M1]

No FPS percentage, universal optimal value, external-tool compatibility or new native visual pass was established here. The previous 268 Lua mock/9 packaging results remain the runtime baseline; those tests were not rerun or represented as proof of this research's new possibilities. This documentation delivery instead validates inventory counts/uniqueness/schema/source links, local document links and the documentation-only diff.

## Source ledger

Inspected 2026-11-07 unless a publication date is stated. Native mirrors contain Blizzard-authored source/captured metadata; third-party project pages establish their authors' functionality/claims, not approval for WoW Forever.

- **F1:** [70862 Graphics.lua][F1], [conditional graphics overrides][F1b], [Video API and support-result enums][F1c].
- **F2:** [70532 CVars and console commands][F2], [API-name capture][F2b]. All CSV source links point to this pinned commit; none is a link to a changing default branch.
- **F3:** [Forever experience presets and HD/SD options][F3].
- **F4:** [CVar getters/metadata][F4], [SetCVar forwarding and cache helpers][F4b].
- **F5:** [Console functions, command types and categories][F5].
- **F6:** [Native camera FOV bounds][F6]; F1 also implements the user-facing slider.
- **F7:** [Native colorblind controls][F7].
- **F8:** [ModelScene light/fog/camera methods][F8], [actor desaturation/model methods][F8b].
- **F9:** [PhotoSharing UI API][F9], including special-purpose screenshot preview.
- **B1:** [Blizzard Forever launch overview][B1], published 2026-11-04.
- **B2:** [Blizzard Forever GPU/rendering requirements][B2], published 2026-09-17.
- **A1:** [DynamicCam author README][A1] and [camera implementation][A1b], inspected as precedent, not copied or installed.
- **A2:** [Sunn Viewport Art author description][A2]; different supported-client history, not Forever verification.
- **E1/E2:** SweetFX commit `93ddf39b357f5da534ed6d34ba4ec8cc7dcfa361`: [Cartoon.fx][E1] (file blob `25acc4c7ae88d8f1a7b3b4b5777aa634dd60c1d6`), [Monochrome.fx][E2] (file blob `3b4ede49180773307274cb9cb1e858a2a4f37cba`). Inspected source; no shaders redistributed or installed.
- **E0:** [ReShade author README][E0], commit `7bf9de8b33bcc76c3177007e65d73c72dd0f34c0`; [project site][E0b]. Site direct fetching was rate-limited; the source README and indexed official description were available. No forum workaround was used.
- **E3:** [NVIDIA App features and RTX HDR requirements][E3]. Its [supported-games page][E3b] uses dynamic content; feature-level Forever confirmation was not obtained.
- **E4:** [NVIDIA Forever Game Ready announcement][E4], published 2026-11-04. Its other-game DLSS sections must not be attributed to Forever.
- **E5/E6:** [NVIDIA NIS developer requirements][E5], [driver scaling/sharpening reference][E5b], [DSR/DLDSR support reference][E6].
- **E7/E8:** [AMD VSR/RIS documentation][E7], [RSR requirements and feature interactions][E8].
- **E9/E10:** [Microsoft Auto HDR][E9], [Windows HDR calibration][E10].
- **E11/E12:** [AMD AFMF capabilities/requirements][E11], [Lossless Scaling publisher description][E12]. Tool claims are not Forever benchmarks.
- **E13:** [Special K author video/HDR documentation][E13]. Search-indexed text was readable; the direct page returned no readable lines. No claimed Forever result.
- **E14/E15:** [wow.export author README][E14], [modern Noggit fork author description][E15]. Offline capabilities/client-format claims, not game-client modifications performed here.
- **P1:** [Blizzard: Prohibitions on Third-party Software][P1], official Kaivax post 2025-08-05. Used for publisher policy, not a jurisdiction-specific legal conclusion or community ban anecdotes.
- **M1:** [PresentMon Capture Application metric definitions][M1].

[F1]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua
[F1b]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Settings_Shared/Mainline/GraphicsOverrides.lua
[F1c]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/VideoDocumentation.lua
[F2]: https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua
[F2b]: https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/GlobalAPI.lua
[F3]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Preset.lua
[F4]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua
[F4b]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXMLBase/CvarUtil.lua
[F5]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ConsoleDocumentation.lua
[F6]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CameraDocumentation.lua
[F7]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Colorblind.lua
[F8]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameDocumentation.lua
[F8b]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua
[F9]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/PhotoSharingUIDocumentation.lua
[B1]: https://worldofwarcraft.blizzard.com/en-us/news/24315820/world-of-warcraft-forever-now-live
[B2]: https://worldofwarcraft.blizzard.com/en-us/news/24301512/
[A1]: https://github.com/mpstark/DynamicCam/blob/master/README.md
[A1b]: https://github.com/mpstark/DynamicCam/blob/master/Core.lua
[A2]: https://www.curseforge.com/wow/addons/sunn-viewport-art
[E0]: https://github.com/crosire/reshade/blob/7bf9de8b33bcc76c3177007e65d73c72dd0f34c0/README.md
[E0b]: https://reshade.me/
[E1]: https://github.com/CeeJayDK/SweetFX/blob/93ddf39b357f5da534ed6d34ba4ec8cc7dcfa361/Shaders/SweetFX/Cartoon.fx
[E2]: https://github.com/CeeJayDK/SweetFX/blob/93ddf39b357f5da534ed6d34ba4ec8cc7dcfa361/Shaders/SweetFX/Monochrome.fx
[E3]: https://nvidia.custhelp.com/app/answers/detail/a_id/5521
[E3b]: https://www.nvidia.com/en-us/software/nvidia-app/supported-games-apps/
[E4]: https://www.nvidia.com/en-us/geforce/news/world-of-warcraft-forever-geforce-rtx-spark-game-ready-driver/
[E5]: https://developer.nvidia.com/rtx/image-scaling
[E5b]: https://www.nvidia.com/content/Control-Panel-Help/vLatest/en-us/mergedProjects/nv3d/Manage_3D_Settings_%28Reference%29.htm
[E6]: https://nvidia.custhelp.com/app/answers/detail/a_id/3597/kw/game%20drivers/related/1
[E7]: https://www.amd.com/en/resources/support-articles/faqs/DH-010.html
[E8]: https://www.amd.com/en/resources/support-articles/faqs/DH3-040.html
[E9]: https://support.microsoft.com/en-us/windows/hardware/display-graphics/use-auto-hdr-for-better-gaming-in-windows
[E10]: https://support.microsoft.com/en-us/windows/hardware/display-graphics/calibrate-your-hdr-display-using-the-windows-hdr-calibration-app
[E11]: https://www.amd.com/en/products/software/adrenalin/afmf.html
[E12]: https://store.steampowered.com/app/993090/Lossless_Scaling/
[E13]: https://wiki.special-k.info/en/Advanced/Video
[E14]: https://github.com/Kruithne/wow.export/blob/main/README.md
[E15]: https://github.com/Jedert-ShadowWorld/ShadowWorld-Noggit-Red-Modern
[P1]: https://us.forums.blizzard.com/en/wow/t/prohibitions-on-third-party-software/2142972/1
[M1]: https://github.com/GameTechDev/PresentMon/blob/main/README-CaptureApplication.md
