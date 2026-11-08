# LumenShift

**Northern Lights Labs · Visual modes for World of Warcraft: Forever**

**0.2.0-dev.13** provides six editable visual modes, an icon wheel, Studio, optional screen effects and original Night Vision sounds, personal presets, independent graphics profiles and diagnostics. This is a development build, not the accepted feature-complete beta.

Dev.13 completes the first reliability delivery: coordinated Brightness/Contrast switching and recovery, a saved Camera effects preference, cosmetic resume after combat, viewport-aware edges and a local bloom capability check. [Changes, validation and button-based test](docs/42-DEV13-RELIABILITY.md).

Dev.12 added native **1–10 graphics levels**, **WoW recommendation**, **Keep current**, separate **raid/battleground settings**, previews and per-bank Restore controls in Setup and Studio. Recommendations come from the game's defaults, not a hardware benchmark. Native recipes now control shadows, lighting, water, textures, particles and other source-defined components where available. [Implementation and limits](docs/37-NATIVE-GRAPHICS-BANKS.md).

The dev.11 reload/mode-continuation, movable-window and wheel-spacing fixes remain included. [Regression details](docs/36-DEV11-RELOAD-AND-UI-FIXES.md).

Version/build/interface differences now show one warning instead of locking controls. Actual APIs, values and ownership are still checked. Schema 8 preserves prior preferences, completion, graphics banks and recovery while adding the Camera effects preference. Dev.7 added Camera Mode, built-in quality recipes and native tier trials. Dev.8 redesigns Studio with grouped navigation, mode/profile cards, aligned settings, a fixed primary action and the approved aurora logo. [UI architecture and validation](docs/31-STUDIO-REDESIGN.md). Dev.9 integrates the supplied Core icons, mesh panels and Lumen Loops accents, with a fitted wheel and bundled third-party credits. [Asset integration](docs/32-ASSET-INTEGRATION.md).

Setup offers **Original** (your captured Brightness/Contrast) or **Game Defaults** (the values reported by WoW). The selected name replaces Natural in the interface; graphics quality stays independent. This is a visual baseline choice, not a reset of all game settings. [Baseline behavior](docs/34-BASELINE-CHOICE.md).

The [Forever graphics investigation](docs/33-FOREVER-GRAPHICS-DEEP-DIVE.md) covers native/hidden image-quality, lighting, water and detail controls, their evidence and the plan for more substantial modes. Dev.10 also fixes built-in sharpening recipes and adds read-only research observations; the proposed rendering features are not all implemented yet.

The [mode and optics audit](docs/38-MODE-AUDIT-AND-OPTICS.md) records what every mode actually does, the owner's existing sharpening/AO observations, stronger Night Vision options, real night-vision design context and the remaining implementation work. It distinguishes native sharpening/contact depth from unsupported world-outline shaders and identifies Camera presentation and composite-mode gaps. Its Delivery 1 reliability findings are addressed in dev.13; the remaining proposed optical effects are not certified or implemented by that fix.

The broader [graphics control research](docs/39-GRAPHICS-CONTROL-LANDSCAPE.md) covers native settings, hidden CVars, Lua/console APIs, camera/viewport tools, HDR, drivers and external shaders/client modifications. It includes a searchable historical inventory of 701 graphics/related CVars and 25 graphics console commands, with source/default/security provenance. External dark-edge and monochrome shaders are technically real; their existence does not make them Lua-addon features or establish Forever compatibility.

The [community visual research](docs/40-COMMUNITY-VISUAL-RESEARCH.md) compares firsthand Forever experiments and creator approaches to sharpening, atmosphere, camera composition and sustainable performance. It checks popular recipes against native metadata and proposes concrete improvements and comparisons for each mode. Community preferences and proposed effects remain separate from verified client behavior.

The [implementation plan](docs/41-IMPLEMENTATION-PLAN.md) turns that research into five usable deliveries: reliability fixes, shared optics and sharper modes, distinct mode treatments, Camera/graphics selection, and beta polish. Routine development proceeds under existing authorization; unavailable optional features affect their own controls, without adding global locks or repeated setup approvals.

Setup separates Appearance from Graphics. Save & Close saves choices without applying them; Apply & Reload explicitly applies selected graphics banks before reload. Ordinary mode use remains enabled; it cannot silently leave controls disabled because graphics were still loading. The previous completed-but-disabled setup also works with a direct mode click. No acknowledgement checkbox, non-75 Brightness unlock or repeated calibration requirement stands between a normal click and its action.

## Install and use

Install the **whole extracted LumenShift folder**, not the ZIP or TOC alone, under Forever's `Interface/AddOns`. Follow the [installation and testing guide](docs/21-BETA-USER-GUIDE.md).

1. Choose **Original** or **Game Defaults** on Appearance, then **Next: Graphics**. Keep current is the initial default. Choose a recommendation or level only if desired. **Save & Close** saves without applying; **Apply & Reload UI** applies the selected banks. With both kept, **Finish & Reload UI** saves/reloads only.
2. Left-click the LumenShift launcher or minimap button for modes; right-click for Studio.
3. Select **Night Vision** to try it. Select **Original** or **Game Defaults** to return to the baseline chosen in setup.
4. Use Studio's Visual Modes editor to customize Brightness and optional Contrast. Edit preferences freely, then click **Apply**.
5. In **Graphics Quality**, use native normal/raid choices or **Detail profiles** for Balanced/Vista/Performance. Scroll to per-bank Restore controls when originals exist. In **Advanced Graphics**, select a named setting and value, then **Test & Restore** for a temporary trial. Balanced/Vista/Performance have built-in bounded recipes; saved custom values take precedence; **Current Baseline** restores quality independently.
6. In **Camera**, hide/show the interface using the native Alt+Z API, optionally hide friendly player/pet names, or toggle names separately. The optional Camera keybind exits and restores names; native Alt+Z only brings the HUD back. **Keep visual effects in Camera** controls whether the selected effects stay visible while the HUD is hidden.

Normal use requires no commands. Settings → AddOns → LumenShift also opens setup, Studio and diagnostics. Opening setup, startup and reload do not activate graphics or play sounds. The explicit **Apply & Reload UI** action applies selected graphics before reloading. Saved choices remain available without automatically reapplying a mode on login.

## What works and what is unfinished

Night Vision starts at Brightness 75; other modes have editable authored settings. Every activation captures the actual original before writing, verifies readback and preserves external changes instead of fighting them. The return mode uses the chosen visual snapshot. Diagnostic recovery restores exact pre-change originals, which can differ from Game Defaults. Effects are optional UI textures, not world shaders. Audio begins muted and can be enabled in setup or Studio.

Optional Contrast and named sharpening, foliage, distance, LOD, bloom and weather controls are **experimental**. Apply checks the current client, values, bounds and flags. Test & Restore is optional, not an unlock. Saved quality profiles remain usable after reload without repeating tests. Balanced/Vista/Performance now have bounded built-ins with explicit unavailable-member reporting; existing nonempty custom profiles keep exactly their own keys. Shadow/light/water tiers have real temporary native trials which restore the tier and check captured named settings. Dev.12 also includes supported tiers in persistent native normal/raid recipes with captured known-value restoration. Complete native dependencies and live acceptance remain unverified. HDR/renderer controls remain in the game settings.

The single native graphics call remains in WriteBoundary. Planner, per-key originals, ownership, conflict detection and readback remain internal requirements. An interrupted session or unresolved conflict needs an explicit recovery decision; startup never guesses a restore. SavedVariables is not immediately durable or crash-proof. Restore before updating or removing the addon.

The owner supplied successful **dev.6 Brightness 45 → 75 → 45** native readbacks on **Forever 1.60.1:70862:16001**, with no report warnings/errors. [Evidence and compatibility policy](docs/28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md) distinguish that success from dev.7's new simulated paths. See the [quality feature/evidence matrix](docs/29-QUALITY-PROFILES-AND-NATIVE-TRIALS.md) and [Camera architecture](docs/30-CAMERA-MODE.md). **Dev.13 is an expanded interactive build, not an accepted feature-complete beta.** New native graphics controls have mock coverage; full dependency restoration and owner in-game acceptance remain unverified.

## Diagnostics

Studio → Diagnostic Center → Export Complete Diagnostic Report produces one copyable report of current capabilities, values, operations, originals and recent errors. It excludes names, chat, accounts, local paths and raw native exception text. Nothing uploads automatically. Reports are useful when something fails; exporting one is not a prerequisite for ordinary use.

## Development

Authoritative repository: [ProfessorMinty/LumenShift](https://github.com/ProfessorMinty/LumenShift). Existing branch `feat/beta-integration`, draft PR #5. Main and prior PRs are not merged automatically; [Issue #1](https://github.com/ProfessorMinty/LumenShift/issues/1) remains open.

```text
python tools/check.py --mocks --lua-runtime PATH_TO_ISOLATED_LUPA
python -m unittest discover -s tests -p test_package.py -v
python tools/package.py --output PATH_OUTSIDE_REPOSITORY
```

The optional Lupa 2.6 runner uses actual Lua 5.1 and is not shipped. System Lua 5.1 can run `lua tests/run.lua`. The builder reads clean committed source, stamps its commit into Core/Build.lua, hashes the payload and compares two archives byte-for-byte. It cannot install or upload.

## Licensing

Original source/technical documentation: [MIT](LICENSE), copyright 2026 Northern Lights Labs. Original creative assets: [All Rights Reserved](ASSET-LICENSE.md), permitted for installation/use as part of LumenShift; no independent reuse/redistribution in other projects without permission. Third-party terms remain independent. See [provenance](assets/PROVENANCE.md). The complete distribution is not MIT-only.

No CurseForge project, upload or publication is authorized. Publication requires native QA and final owner approval.
