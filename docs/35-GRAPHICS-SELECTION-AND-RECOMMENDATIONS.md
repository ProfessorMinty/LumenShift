# Forever quality selection and native recommendations

Observed/source research date: 2026-11-07. This extends [33](33-FOREVER-GRAPHICS-DEEP-DIVE.md); it is the implementation design for native quality selection, not a claim that dev.11 already implements a 1–10 selector.

## What the evidence establishes

**Source-confirmed for Forever 1.60.1 (70862):** normal and raid overall sliders, separate component recipes, per-option recommendations, capability checks and the native graphics-bank shortcut. Source is Blizzard UI extracted into Gethe's Forever branch, pinned to commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06`. The extraction is a primary code artifact, not a guarantee of every native function's implementation.

**Verified in the owner's dev.10 export:** client 1.60.1:70862:16001, native getters/defaults available, `graphicsQuality=9`, `raidGraphicsQuality=6`, `RAIDsettingsEnabled=0`, with default 6 for both quality CVars in that session. Individual quality settings differ from defaults. This is read-only evidence; it does not certify a whole native preset, FPS, automatic bank switching or tier restoration. Do not request another launcher verification.

| Topic | Evidence and implication |
| --- | --- |
| Display 1–10 | [Graphics.lua, lines 47–49 and 440–449](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L440): internal minimum 0, maximum 9; formatter adds one. Displayed 10 means raw 9. |
| Native recipe lookup | [Graphics.lua, lines 1197–1247](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1197) calls `GetGraphicsCVarValueForQualityLevel(cvar, rawLevel, raid)` for each registered child, clamping to that setting's native minimum. This is the relevant mapping API; setting only the overall CVar does not reproduce the Lua callback. Actual returned vectors still require client observation. |
| Separate raid bank | [GraphicsOverrides.lua, lines 1–62](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Settings_Shared/Mainline/GraphicsOverrides.lua#L1) declares base and raid tables. The folder name Mainline is part of this Forever source tree, not an assumption that Retail is equivalent. |
| Native recommendation | [Graphics.lua, lines 90–106](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L90) marks options recommended when they match the native default. [CvarUtil.lua, lines 37–38 and 101–103](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXMLBase/CvarUtil.lua#L37) obtains defaults through `C_CVar.GetCVarDefault`. An addon can read those values. The detection algorithm and maximum sustainable quality are not established. |
| Hardware support | The same Graphics.lua uses `IsGraphicsSettingValueSupported(cvar,value,raid)`; result **0** means supported. Treating a nonzero Lua number as a true boolean would be a bug. Conditional PBR/secondary lighting controls require their corresponding capability checks. |
| Active bank is not quality level | [Bindings_Camelot.xml, lines 1327–1340](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_FrameXML/Bindings_Camelot.xml#L1327) toggles `GetCurrentGraphicsSetting()` / `SetCurrentGraphicsSetting(0 or 1)` between Normal and Raid when raid settings are enabled. These are not 1–10 quality APIs. |
| GPU Auto Detect | [Graphics.lua, lines 1432–1457](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1432) uses `gxAdapter=""` for Auto Detect. `gxapi="auto"` separately selects a rendering backend. Both are restart-related choices, not a quality benchmark. |

The [70532 native API capture](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/GlobalAPI.lua) lists `AutoChooseCurrentGraphicsSetting`, recipe mapping, support checks, `GetFramerate` and `IsCpuBound`. Listing a name does not establish a callable benchmark contract. No verified one-call “find the highest sustainable graphics quality for this computer” API was found. Do not wire the similarly named AutoChoose function to an Optimize button on that assumption. The capture did not list GetRecommendedGraphicsQuality, GetDefaultGraphicsQuality or SetDefaultVideoOptions; absence in one capture is not proof about every build.

The [older captured CVar defaults](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua) differ from the owner's current values. Never hardcode a universal recommended level. The capture uses uppercase RAID in some names while UI code uses raid; confirm aliases and canonical ownership keys so one CVar cannot acquire two journals.

## What the raid option covers

Base/raid pairs include shadows, liquid/PBR liquid, particles, SSAO, depth/compute effects, outline, textures, spell density, projected textures, lighting, view distance, environment detail and ground clutter. Some entries are conditional. The base particle setting has a native minimum of 1; blindly applying a raw recipe or copying all minima from the raid table could remove important combat cues.

This is not a duplicate of every video option. Resolution, renderer, GPU selection, anti-aliasing, resampling and several advanced settings are shared or separately handled. Exact native bank activation across raids, battlegrounds and other instances must be observed; do not promise every dungeon/group automatically uses raid settings or add a competing zone-based writer.

## Proposed setup flow

Keep the existing Original / Game Defaults visual choice independent. Add a dedicated Graphics page:

1. **Keep my current settings** — default selection; preserves custom normal/raid values and the current raid checkbox.
2. **Use WoW's recommendation** — the “I'm not sure” route; read native per-option defaults and support results, show the resulting settings before Apply. Describe it as WoW's recommendation, not a measured benchmark.
3. **Choose a level** — Everyday graphics slider, displayed 1–10. Read the native recipe for the selected level and show component changes.

Below that: **Use different settings in raids and battlegrounds**, with an independent raid recommendation/level choice. Start from the user's existing option, not an invented “normal minus two” rule. If the current component vector differs from the native level recipe, label it **Custom**. If recommended defaults do not exactly match one native recipe, label that vector **Recommended / Custom** rather than rounding it to a tier and discarding individual defaults.

Users need not name their GPU, CPU or RAM. A later optional preference for smoother gameplay versus detail can guide a user-started performance comparison. A target FPS choice is a preference, not a guarantee or permission to change game FPS caps. Standing in a quiet town cannot predict raid performance.

Keep Back, Keep Current, and Apply & Continue understandable; no recovery cards for normal healthy operations. The explicit Apply must explain whether it changes both banks and the raid option. Missing recommendation/mapping APIs disable that specific automatic option with a concise reason; existing modes, manual controls and native Graphics access remain usable.

A native Graphics shortcut should use a discovered registered category and [Settings.OpenToCategory](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua#L144) from a user click, with actual availability/restrictions checked. Do not guess category IDs. The underlying [SettingsUtil API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SettingsUtilDocumentation.lua) declares restrictions.

## Implementation sequence and acceptance

First add read-only bank/recipe/default discovery with strict result validation. Then implement schema-versioned bank preferences, explicit preview/Apply, complete ownership capture and restoration tests. Keep Balanced/Vista/Performance refinements separate from the native base/raid levels; never silently overwrite custom profiles.

All native mutations must remain behind WriteBoundary. Native Settings proxy setters, automatic selection functions, UI button simulation and broad reset functions are not shortcuts around it. [SettingsPanel commit ordering](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingsPanel.lua#L28) commits children before overall quality; its Apply/Defaults paths can also commit unrelated settings/bindings and restart actions. Calling those paths wholesale is inappropriate here.

Capture the participating parent/children and known induced values before Apply; verify actual dependency effects before claiming exact whole-preset restoration. Renderer, GPU, resolution and driver/HDR changes remain outside this flow. Preserve combat-critical projected textures/spell readability; no maximization of undocumented console values.

Acceptance requires:
- Display/raw endpoints 1↔0 and 10↔9; independent normal/raid selections; custom vectors not mislabeled as an overall level.
- Missing/error/secret/noninteger/out-of-domain native results handled without guessed recipes or startup writes.
- Native default vectors and support codes inspected on the current client; lower particle bound honored; aliases deduplicated.
- Complete original vectors captured; partial failure, clamping, external edits, reload and reverse restoration covered with mocks and then owner-operated tests.
- Read-only diagnostics and setup do not call graphics setters or broad native reset/apply paths.
- Actual bank switching observed separately in relevant content; FPS comparisons report their conditions rather than promise a universal gain.

Dev.11 fixes the reported reload/UI regressions. This native 1–10/raid setup remains planned work, and persistent tier dependency/restoration remains an open engineering gate.

## Implementation follow-up

Dev.12 implements the proposed controls and bounded known-value bank capture/restore. See [37](37-NATIVE-GRAPHICS-BANKS.md). The historical proposal above is retained; native acceptance and complete dependency closure are still open.
