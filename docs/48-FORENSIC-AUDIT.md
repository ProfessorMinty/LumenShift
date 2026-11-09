# Whole-addon forensic audit — beta.4

**2026-11-08 · Northern Lights Labs · ProfessorMinty/LumenShift**

The audit found **five reproducible defect classes** in the integrated addon and corrected them in **0.2.0-beta.4**. The architecture remains intact: one native CVar call site, explicit user actions, exact captured originals, separate visual/quality/Camera intent, read-only startup and recovery after reload. No new renderer capability, automatic setting application or approval ceremony was added.

This is a source, research, adversarial mock and artifact audit. It is not native certification or a guarantee that no defects remain. The complete beta still needs integrated owner-operated testing, particularly native dependency changes, keyboard routing, image quality and addon coexistence.

## Scope and evidence identity

- Verified origin: `https://github.com/ProfessorMinty/LumenShift.git`; branch `feat/beta-integration`; starting clean commit `51cfa147e26e1d805ba7c4d96a45648b0b5ebc81`, matching the fetched head of draft [PR #5](https://github.com/ProfessorMinty/LumenShift/pull/5). No unrelated local changes were present.
- Inspected all **44 runtime Lua modules**, TOC, four binding bodies, test harness/fixtures, packaging and structural tools, asset manifests/provenance and split licensing. The final artifact records its own exact source commit in `BUILD.json`; this document's starting SHA is the pre-fix baseline.
- Reconciled the Phase 00 requirements in docs/00–10, implementation and native evidence in docs/11–30, UI/assets/baseline/quality research in docs/31–37, optical/external/community investigations in docs/38–40, and the five-delivery plan/results in docs/41–47. Historical restrictions and numerical defaults are not current runtime requirements.
- Accepted owner evidence remains the recorded Brightness visual/readback round trip and named diagnostic observations. In particular, the dev.10 70862 observations of native graphics/defaults do not prove whole-bank restoration. No launcher-version reconfirmation is needed.
- Fresh source lookup still resolved Gethe's `forever` branch to **1.60.1 (70862)**, commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06`. Extracted Blizzard UI/API code is source evidence, not the native renderer implementation. The older 70532 console inventory remains historical.
- No installed game, driver, graphics settings or other addon was operated or changed. No merge, CurseForge project, upload or release was performed. Issue #1 remains open.

Evidence terms: **reproduced in mocks** means an executable off-client failure; **source-confirmed** identifies the exact inspected source; **verified in-client** is reserved for existing recorded owner observations. A proposed visual benefit is a hypothesis until observed.

## Confirmed findings and corrections

Priority describes impact within this addon, not a security vulnerability score. All five rows are fixed in the audited source and covered by regressions.

| ID / priority | Reproduction and cause | Correction and verification |
|---|---|---|
| FA-01 / P1 | A synchronous callback inside the Brightness setter can enter the names controller before Brightness finishes. A visual preflight getter can enter a native quality trial. Several gates checked pending state but missed another controller's executing/preflight state. This permits overlapping writes and can leave the outer operation awaiting recovery. | Add missing executing/busy cross-controller checks inside `WriteBoundary.lua`. F04/F05 reproduce the original failures. F06 exercises all 56 ordered pairs of eight controllers at both a getter/preflight and a setter callback: **112 scenarios**. The nested operation must return an explicit refusal, make zero writes, and let the outer operation proceed. Existing same-controller/lifecycle tests remain. |
| FA-02 / P2 | Select Night Vision, edit its opacity, then click Effects → Apply. The button passes itself into `RefreshPresentation(resume)`, making `resume` truthy and reusing the old applied snapshot. The button appears to ignore the edit. | Bind a zero-argument closure. F02 exercises the actual button script, checks the edited alpha and confirms zero additional CVar writes. Setup's intentional snapshot-only refresh remains unchanged. |
| FA-03 / P2 | Opening the wheel turns off keyboard propagation for every key. Chat focus is not consulted, and no paired key-up handler protects release of an unrelated held movement key. | Reuse the focus-aware keyboard helper with wheel-specific shortcuts. Unrelated keys pass through, chat/edit focus wins, only handled actions consume input, and key-up consumption matches that key's own down event. F03/F10 cover focus, release, mode selection, closing and API failure; existing P22 verifies the Studio fallback. This does not establish native input event ordering. |
| FA-04 / P2 | A normal or photo recipe whose requested values already match issues no setter but still acquires the entire bank and creates a recovery record. Untouched settings become owned and can block later operations. | After fresh preflight/snapshot checks, finish a matching recipe without new ownership. Retain any existing record unchanged, and still finish the callback chain for the other bank/setup. F07/F08 cover both controllers, previous exact originals, later restore and mixed no-change/change banks. No-change success is not reported as an error. |
| FA-05 / P2 | Camera exports omit the framing controller/journal details, photo controller state, photo bank error/source and photo watched side effects. Once session history is lost after reload, the export no longer explains some retained recovery records. | Include these numeric/allowlisted records in the existing report. F09 injects FOV setter failure and a photo operation that changes Brightness, reloads from saved data and verifies the exported recovery evidence with zero writes. No raw native exception, private names or arbitrary data was added. |

The full-library suspicion was **not confirmed**: F01 successfully reopens 24 personal presets together with independent normal/raid and temporary normal/raid photo recovery records. It also checks exact raw originals. This is a supported-capacity example, not proof that every possible hostile/oversized saved table is accepted; rejecting such tables is intentional.

During correction, the full suite caught the no-change success being exposed as an error and a changed wheel fallback. Both were corrected before final validation. Test fixtures also now request a genuinely different photo level when testing retained photo ownership; an identical level should correctly create none.

## Subsystem audit

All filenames below are under `addon/LumenShift/`. Existing regression suites were retained; the new forensic cases supplement them rather than replace them.

| Area / inspected modules | Audit result | Remaining practical limit |
|---|---|---|
| Load/lifecycle: `Namespace`, `Build`, `Bootstrap`, `Controller`, TOC, bindings | Explicit module order; schema/version identity; optional commands plus visible entry points; startup, diagnostics and lifecycle observation do not replay graphics. Client changes warn instead of reinstating a blanket build lock. | Actual client patch/load behavior and protected API restrictions require native observation. Syntax failure before bootstrap cannot be self-reported. |
| Observation/admission: `ReadOnly`, `Compatibility`, `Catalog`, `ExperimentPolicy`, `NamePolicy`, `Framing`, `QualityTrial` | Named keys, native flags, finite typed values, capability checks, current signatures and dynamic FOV bounds remain. Unknown/restricted values do not become guessed defaults. Trial admission is distinct from a fully validated production catalog. | Readable/existing does not mean writable, visually effective or fully restored; source presence does not establish public-addon permission in every context. |
| Transactions: `Value`, `Planner`, `Recovery`, `WriteBoundary` | Single native setter call, capture-before-write, numeric validation, exact raw restore, no-setter releases, fresh conflict checks, bounded compensation and retained failed/pending recovery. FA-01/04 corrected here. | Lua cannot make several native writes atomic or force SavedVariables immediately to disk. A same-value external write cannot be attributed from value comparison alone. |
| Configuration: `Store`, `StudioConfig`, `Profiles`, `Baseline` | Schema **12 unchanged**. Copy/validate migration preserves completion, presets, chosen return look and recovery originals. Data-only import; limits on count, depth, strings and finite values; unknown schemas/corrupt records are quarantined, not silently reset. | Quarantine needs user recovery if data is corrupt; saved preferences and recovered intent do not mean the scene has been reapplied. |
| Mode/quality composition: `Optics`, `Modes`, `Product`, `Quality` | Mode, quality, optional return optics and captured original resolve in a defined order. One physical recovery owner for each shared optical key. Mode intensity and styling do not silently change resolution/AA or expensive native tiers. | Authored starting looks and stronger sharpening are not measured optimal settings. Optional omission is preflight disclosure, not permission to ignore a failure after writing begins. |
| Native banks: `NativeGraphics` and boundary controllers | Separate normal/raid recipes, source-backed 1–10 mapping, hardware checks, captures of known bank members, foreign-bank/visual watchers, verification, compensation and explicit restore. FA-04 removes unnecessary ownership. | Complete renderer dependency closure is unknown. Explicit everyday/raid **Restore** intentionally replaces the displayed captured bank, including intervening edits; it is not an automatic conflict-preserving undo. Photo exit instead refuses mismatching owned values. |
| Camera: `Camera`, `Framing`, `NamePolicy`, `UI/Camera`, `UI/Composition` | Separate HUD, two friendly-name fields, native FOV, guides, native screenshot and opt-in temporary photo quality. Exit shows HUD before restoration; combat reveals HUD without graphics replay. Session names intent preserves independent manual toggles. | Other UI/camera addons, native screenshot timing, delayed/external screenshot events and effective FOV need actual testing. No motion automation or new world camera shader. |
| Performance: `Performance`, `UI/Graphics` | User-started bounded observation; two-second settle, ten readings, two stored results, current setting snapshots, cancellation on changes, no automatic tuning or permanent frame loop. | This is mean/min/max sampled FPS, not frame-time percentiles, GPU profiling, wattage measurement or a predictor of raid performance. |
| UI/input: `UI/Widgets`, `Keyboard`, `Optics`, `Graphics`, `Camera`, `Presets`, `Studio`, `Setup`, `Radial`, `EntryPoints` | Pooled controls, display fitting, scroll, title dragging/top-level strata, focus-aware keyboard and distinct save/apply actions. FA-02/03 fixed. Mouse entry points and existing restrictions/fallbacks retained. | Mock geometry cannot establish native font wrapping, taint, keyboard routing, other-addon strata or readability at every scale. |
| Presentation/audio: `UI/Presentation`, `Audio` | Addon-owned overlays; comfort settings, clear styling, combat suspension/cosmetic resume, reduced motion and optional original SFX. No CVar animation, full-scene postprocess or copied game sounds. | Texture decoding, layering, audio balance and perceptual quality remain native checks. UI overlays do not change world lighting. |
| Diagnostics: `Log`, `Diagnostics`, `Report`, `UI/DiagnosticWindow`, `Calibration` | Bounded events/issues, coalesced edits, numeric/allowlisted export, no automatic upload or character/account/chat/path collection. FA-05 restores omitted Camera evidence. | Readback passes remain distinct from visible-effect, input, audio, dependency and persistence acceptance. Truncated reports cannot guarantee all session history. |
| Distribution: `tools/check.py`, `tools/package.py`, manifests/licenses | Exact runtime allowlist, one root folder, clean-commit source, matching versions, deterministic ZIP, per-file hashes, four bindings, no runtime dependencies or bundled raw asset packs. | A local archive and passing tests are not a CurseForge moderation decision or native install/update/uninstall pass. |

## Fresh research and its application

Sources below were checked on **2026-11-08**. The fixed SHA links identify the build inspected; mutable policy pages are review-date evidence. No third-party implementation code was copied into this patch.

| Source | What was established | Applied audit decision |
|---|---|---|
| [CVar API, 70862](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua#L82) | `GetCVarInfo` flags and setter restrictions/return contract are declared. | Keep exact flag/value validation and native result plus readback checks; no bypass or broad fallback. |
| [Console events, 70862](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ConsoleDocumentation.lua#L176) | `CVAR_UPDATE` is marked synchronous. | Reentry is a realistic boundary concern; add the complete ordered-pair matrix, not just a delayed timer test. Source declaration does not prove every hypothetical hook occurs in-game. |
| [Frame API, 70862](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua#L1426), [UI schema](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/UI.xsd#L442) | Keyboard propagation has restrictions; both key-down and key-up scripts are declared. | Handle failures locally, preserve unrelated releases/text focus and retain mouse/Studio fallback. Do not claim the mock routes native keyboard events. |
| [Graphics settings, 70862](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1197), [Forever overrides](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Settings_Shared/Mainline/GraphicsOverrides.lua) | Recipes map per child; normal/raid and conditional hardware capabilities differ. Numeric support result 0 denotes supported. | Preserve native mappings, particle/combat cues and separate bank capture. Never substitute internet maxima or a guessed hardware tier. |
| [Sharpness/bloom UI, 70862](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1551), [Video API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/VideoDocumentation.lua) | Sharpness is reversed over 0–2; bloom UI is conditional on the linear-renderer capability. | Keep intuitive detail strength and local bloom checks; neither readback nor source bounds establish a superior image. |
| [Camera API, 70862](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CameraDocumentation.lua#L10) | Native FOV defaults/min/max are returned dynamically. | Keep current bounds and exact captured FOV; the addon's 0.1 step is an authored control choice, not the native UI's step. |
| [Blizzard addon policy](https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642/1) | Free, visible code and restrictions on in-game advertising/donation requests and harmful interference remain relevant. | Keep readable source, no paywall/in-game donation UI, and no external client modification. This inspection is not Blizzard endorsement. |
| [CurseForge moderation](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies), [project submission](https://support.curseforge.com/support/solutions/articles/9000197241), [Forever migration](https://blog.curseforge.com/wow-forever-migrate-addons-beta-to-live/) | Moderation includes functional descriptions, rights/credits, changelogs and accurate visual presentation; Forever live installation differs from beta. | Keep one `_forever_/Interface/AddOns/LumenShift` root. Prepare authentic gameplay screenshots and a 400×400 project avatar for final submission. Label any misleading AI-modified showcase imagery. Dashboard flavor/version/license IDs still require actual verification; no upload implied. |
| [Craftwork license](https://craftwork.design/license), [Streamline Core](https://blog.streamlinehq.com/core/), [Streamline free guidance](https://help.streamlinehq.com/en/articles/5354376-streamline-free-license) | Integrated use and standalone asset redistribution are distinct; Core Line explicitly identifies CC BY 4.0, and Streamline requires checking each set's terms. | Retain existing attribution, per-file source hashes, selected exports and separate third-party notices. Raw packs stay excluded. Owner acquisition terms and the exact final distribution remain release-review items; repository visibility is not a license grant. |

## Reconciliation with the graphics and mode research

The broad [701-CVar / 25-command inventory](39-GRAPHICS-CONTROL-LANDSCAPE.md) remains research data, not an executable allowlist. No new arbitrary console execution, unsupported alias, private native writer or external shader was introduced.

| Experience | What the implementation now offers | What still needs evidence |
|---|---|---|
| Original / Game Defaults | Chosen visual reference, optional return optics, separate actual recovery originals | Expected appearance after returning; exact values on the final native build |
| Night Vision | Brightness target, adjustable native detail, optional Contrast/bloom, Clear/Goggles styling and original cue | Useful darkness detail without halos/shimmer/highlight clipping, particularly while moving |
| Clarity | Neutral starting appearance, inherited exposure, adjustable detail and optional glare control | Neutral color/readability in everyday motion; no claim that brighter equals sharper |
| Cinematic | Editable light/contrast, optional bloom/style/framing, independent companion quality and Camera | Shadow detail, composition and acceptable cost rather than forced maximum quality |
| Lantern | Moderate customizable exposure/detail and optional warm styling | Indoor readability around existing lights; this does not spawn a world light |
| Moonlight | Modest customizable visibility and cool optional styling | Useful night atmosphere without haze or crushed detail; no time/weather replacement |
| Camera / Quality | HUD/names, FOV, guides, capture, temporary photo quality; everyday/raid recipes and FPS observations | Native coexistence, effective bank switching, screenshots and exact known-member restoration |

Real night vision, AO/contact detail and external edge shaders remain distinct, as researched in [38](38-MODE-AUDIT-AND-OPTICS.md), [39](39-GRAPHICS-CONTROL-LANDSCAPE.md) and [40](40-COMMUNITY-VISUAL-RESEARCH.md). The isolated contact-depth trial is not a scene-wide black-outline effect or thermal sensor. Community recipes such as extreme AO values have not become preset defaults. The current research gives no basis to claim a universal best graphics configuration or an addon-callable hardware benchmark.

## Residual risks and completion work

1. **Native dependency closure:** source-visible bank members and foreign watchers are a finite set. Native selectors may change additional engine state. Within one setter call, another addon changing a watched same-bank leaf cannot always be distinguished from the engine's intended fan-out. Fresh readback is not attribution or an atomic transaction. Test native normal/raid/photo transitions and external conflicts before a broad restoration guarantee.
2. **Durability and reload:** SavedVariables writes follow the game's save lifecycle. Recovery cannot be crash-proof or immediately durable. Persisted pending/failed/conflicting state remains inspectable; startup never restores uncertain values automatically. No destructive crash test is required.
3. **Visual and performance acceptance:** none of this audit measures a rendered frame, motion shimmer, bloom effectiveness, AO method, sound level, GPU cost or raid workload. Use matched scene/viewpoint comparisons and the existing finite FPS observations; tune from results.
4. **Native UI and coexistence:** verify chat/movement releases, wheel shortcuts, scale/wrapping/drag/strata, Alt+Z/combat, screenshot timing and coexistence with the owner's UI/camera addons. Source and mock acceptance are narrower.
5. **Release and artwork:** the five planned deliveries are implemented. Remaining work is integrated testing and resulting fixes, final creative choices, then review/merge/release preparation and explicit publication approval. Existing original code is MIT; original artwork/audio/branding is reserved-rights; third-party terms remain separate. Final custom mode icons are optional unfinished polish, not a reason to freeze working controls. No new license decision is requested.

Asset inspection retains **37 runtime assets**, output hashes, original logo/audio provenance and selected third-party export mappings. No assets or licenses were changed by this audit. No runtime download, injected shader, external dependency or background telemetry was found in the inspected source. This is a bounded code finding, not a guarantee against every future addition.

## Validation and reproduction

Before changes, the full baseline suite passed **393 Lua 5.1 tests**. Targeted adversarial tests then reproduced the new defects. Final results are recorded below after the full rerun; all Lua/native APIs and UI events in these tests are simulated.

- **403 Lua 5.1 tests passed, 0 failed**: all 393 baseline cases plus ten forensic cases. F06 contains 112 ordered cross-controller scenarios; they are not inflated into 112 additional top-level test counts.
- **61 Lua files and four binding bodies** passed Lua 5.1 syntax checks.
- Structural checks passed for **44 runtime modules**, exact TOC/version paths, the single native CVar call and unchanged asset hashes.
- **10 Python packaging tests passed**, including allowlists, deterministic output, manifests, licensing and pinned guide links.
- Current documentation-link and whitespace checks passed. The local beta.4 archive is built from the clean recorded commit and verified byte-for-byte by the packager; its adjacent receipt records the SHA-256.
- **No new in-game test result** is claimed. The artifact is a corrected candidate for the owner to test, not a certified public release.

The ten cases in `tests/forensic.lua` cover capacity/reload, actual button argument behavior, input focus/key releases, two original reentry failures, the 112-scenario controller matrix, no-change ownership/chaining, Camera export after reload and keyboard fallback. Existing suites retain restoration, errors, conflicts, migration, optional capabilities, combat, presentation, presets and packaging coverage. Tests do not measure an actual game scene.

Reproduce from the repository root:

```text
python tools/check.py --mocks --lua-runtime ../lua-test-runtime
python -m unittest discover -s tests -p test_package.py -v
git diff --check
python tools/package.py --output ../../outputs
```

The isolated Lua 5.1 runtime is a development dependency, not shipped with the addon. The package command requires a clean committed tree and builds/verifies deterministic output. The resulting ZIP, SHA-256 receipt and `BUILD.json` are the artifact identity; no game install is performed.

## Focused owner check

Extract the beta.4 ZIP and replace the **whole `LumenShift` folder** under Forever's `Interface/AddOns`, keeping existing SavedVariables. Start the game normally; completed setup should remain completed. No reset or slash command is required.

1. Open the wheel and Studio from the launcher. Check chat, movement-key release, Escape and 1–6 selection. Check ordinary mouse use and the existing draggable windows.
2. Apply Night Vision, edit opacity in Effects, then click **Apply effects to active mode**. The visible overlay should change; the graphics values should remain at the active mode's values. Setup Save & Close still refreshes comfort preferences without applying an edited mode.
3. In a deliberate graphics test, applying a recipe already matching all its target values should finish without creating a new bank recovery record. Changing a recipe should still capture originals and restore explicitly. Existing records are retained when reapplying the same recipe.
4. Use Diagnostic Center → Export Complete Diagnostic Report. Camera framing/photo recovery, when present, should appear after reload as well as during the current session. Do not intentionally create failure or a crash just to check these lines.
5. Continue the [integrated beta checklist](22-BETA-RELEASE-QA.md) for every mode, optical inheritance, quality banks, Camera, effects/audio, upgrade and removal. Record actual visible results separately from numeric readback.

Normal use remains available. These acceptance checks identify what is still unobserved; they do not add a global read-only mode or a new unlock workflow.
