# LumenShift

**Northern Lights Labs · Visual modes for World of Warcraft: Forever**

**0.2.0-dev.7** provides six editable visual modes, an icon wheel, Studio, optional screen effects and original Night Vision sounds, personal presets, independent graphics profiles and diagnostics. This is a usable development build, not the accepted feature-complete beta.

Version/build/interface differences now show one warning instead of locking controls. Actual APIs, values and ownership are still checked. Completed dev.6 setup stays completed; schema 5 keeps existing preferences and recovery. Dev.7 adds Camera Mode, built-in quality recipes and native tier trials.

Setup is one compact preferences screen. Finish saves your choices and enables ordinary mode use; it cannot silently leave controls disabled because graphics were still loading. The previous completed-but-disabled setup also works with a direct mode click. No acknowledgement checkbox, non-75 Brightness unlock or repeated calibration requirement stands between a normal click and its action.

## Install and use

Install the **whole extracted LumenShift folder**, not the ZIP or TOC alone, under Forever's `Interface/AddOns`. Follow the [installation and testing guide](docs/21-BETA-USER-GUIDE.md).

1. On first install, choose defaults in setup, then **Finish & Reload UI** or **Save & Close**. Completed dev.6 setup stays saved.
2. Left-click the LumenShift launcher or minimap button for modes; right-click for Studio.
3. Select **Night Vision** to try it. Select **Natural** to restore the actual captured original settings.
4. Use Studio's Visual Modes editor to customize Brightness and optional Contrast. Edit preferences freely, then click **Apply**.
5. In **Advanced Graphics**, select a named setting and value, then **Test & Restore** for a temporary trial. Balanced/Vista/Performance have built-in bounded recipes; saved custom values take precedence; **Current Baseline** restores quality independently.
6. In **Camera**, hide/show the interface using the native Alt+Z API, optionally hide friendly player/pet names, or toggle names separately. The optional Camera keybind exits and restores names; native Alt+Z only brings the HUD back.

Normal use requires no commands. Settings → AddOns → LumenShift also opens setup, Studio and diagnostics. Setup/startup/reload do not activate graphics or play sounds. Saved choices remain available without automatically reapplying a mode on login.

## What works and what is unfinished

Night Vision starts at Brightness 75; other modes have editable authored settings. Every activation captures the actual original before writing, verifies readback and preserves external changes instead of fighting them. Natural restores owned visual values. Effects are optional UI textures, not world shaders. Audio begins muted and can be enabled in setup or Studio.

Optional Contrast and named sharpening, foliage, distance, LOD, bloom and weather controls are **experimental**. Apply checks the current client, values, bounds and flags. Test & Restore is optional, not an unlock. Saved quality profiles remain usable after reload without repeating tests. Balanced/Vista/Performance now have bounded built-ins with explicit unavailable-member reporting; existing nonempty custom profiles keep exactly their own keys. Shadow/light/water tiers have real temporary native trials which restore the tier and check captured named settings. Their complete dependency map is still unknown, so persistent tier profiles remain unfinished. HDR/renderer controls remain in the game settings.

The single native graphics call remains in WriteBoundary. Planner, per-key originals, ownership, conflict detection and readback remain internal requirements. An interrupted session or unresolved conflict needs an explicit recovery decision; startup never guesses a restore. SavedVariables is not immediately durable or crash-proof. Restore before updating or removing the addon.

The owner supplied successful **dev.6 Brightness 45 → 75 → 45** native readbacks on **Forever 1.60.1:70862:16001**, with no report warnings/errors. [Evidence and compatibility policy](docs/28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md) distinguish that success from dev.7's new simulated paths. See the [quality feature/evidence matrix](docs/29-QUALITY-PROFILES-AND-NATIVE-TRIALS.md) and [Camera architecture](docs/30-CAMERA-MODE.md). **Dev.7 is an expanded interactive build, not an accepted feature-complete beta.**

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
