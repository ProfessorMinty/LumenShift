# LumenShift

**Northern Lights Labs · Visual modes for World of Warcraft: Forever**

**0.2.0-dev.4** connects six visual modes, an icon wheel, eight-page Studio, optional effects/audio, personal presets, experimental Contrast/quality calibration and a Diagnostic Center with one copyable report.

This is **more than a brightness toggle, but not the finished product**. Contrast and selected quality controls remain experimental; Balanced/Vista/Performance start empty and need tested user-configured targets. Advanced shadow/light/water and other unmapped controls are read-only. See the [honest feature matrix](docs/25-BUILD-70840-AND-SETUP-REVIEW.md#does-this-include-the-whole-requested-product).

Arctic loaded dev.3 on **Forever 1.60.1.70840 / interface 16001** and exported its report. Finish was rejected by the outdated 70790-only check before reload; no graphics writes were recorded. Dev.4 corrects that check, redesigns setup and refreshes stale diagnostics. **Dev.4 native acceptance is pending.** The older 70790 Brightness 45 → 75 → 45 round trip does not validate the integration. This is not a published release or an accepted feature-complete beta.

## Install, explore, report

Install the **whole extracted LumenShift folder**, not the ZIP or TOC alone, under the existing Forever `Interface/AddOns` folder. Follow the [consolidated user guide](docs/21-BETA-USER-GUIDE.md).

1. Log in: the setup wizard opens automatically. Review compatibility, choose preferences, review your choices, then click **Finish & Reload UI**.
2. After reload, click the labeled launcher or minimap button for modes; right-click for Studio.
3. **Settings → AddOns → LumenShift** provides Studio, the setup wizard, diagnostics and export.
4. In Studio, click **Diagnostic Center → Run Diagnostics**, or **Export Complete Diagnostic Report → Select All → Ctrl+C**.

Normal use requires no slash commands. They remain optional shortcuts. Setup saves preferences without applying a graphics mode; its final button reloads the interface only after your click. Read-only startup checks never change graphics or play sounds.

Reports include actual client/build/UI/API observations, graphics flags and values, operations/readbacks, recovery, module/UI/media failures and bounded session history. Names, chat, accounts, paths, credentials, preset names and raw native error text are excluded. No upload, clipboard API or arbitrary game-side file access.

Night Vision starts at Brightness 75 and restores the exact captured original. Other modes have editable authored settings; non-75 targets require an experimental opt-in. Effects are optional UI textures, not shaders. Audio starts muted; previews require user action. Nothing automatically reapplies at login.

## Experimental graphics and safety

Calibration Lab lets you read capabilities, choose an exact bounded target, preview/export originals and changes, then deliberately confirm an apply/readback/restore/readback cycle. Successful numeric round trips permit **that exact experimental target for this login**. They do not prove a visible effect, universal safe range or complete dependency closure.

Calibrated Contrast is optional per visual mode. Balanced/Vista/Performance are independent user-configured target sets, with no guessed defaults or FPS claims. Every required target must be calibrated; partial profiles are refused. Shadow/light/water tiers, HDR, renderer and unmapped settings remain observation-only with reasons.

WriteBoundary contains the single private native graphics call. The preserved Brightness engine and leaf experiments use planner preflight, capture-before-write, exact ownership, readback and conflict protection. Reload, conflict or late failure never triggers an uncertain automatic restore. Composite Brightness+Contrast failures can leave a partial operation with originals retained and reported. SavedVariables are not immediately durable or crash-proof; save recovery reports externally and restore before updating/removing the addon.

Read [setup and button-first access](docs/24-GUIDED-SETUP.md) and [diagnostic architecture, limits and sources](docs/23-INTERACTIVE-DIAGNOSTICS.md). Historical research and [native results](docs/18-BRIGHTNESS-CLIENT-RESULTS.md) are preserved. Dev.3 load/setup-display/export observations are recorded in [the 70840 report review](docs/25-BUILD-70840-AND-SETUP-REVIEW.md). Dev.4 native UI, media, reload/persistence, graphics and EllesmereUI coexistence acceptance remain pending.

## Development

Authoritative repo: [ProfessorMinty/LumenShift](https://github.com/ProfessorMinty/LumenShift). Existing branch `feat/beta-integration`, draft PR #5. Main and prior PRs are not merged automatically; [Issue #1](https://github.com/ProfessorMinty/LumenShift/issues/1) stays open.

```text
python tools/check.py --mocks --lua-runtime PATH_TO_ISOLATED_LUPA
python -m unittest discover -s tests -p test_package.py -v
python tools/package.py --output PATH_OUTSIDE_REPOSITORY
```

The optional Lupa 2.6 runner uses actual Lua 5.1 and is not shipped. System Lua 5.1 can run `lua tests/run.lua`. The builder reads clean committed source, stamps its commit into Core/Build.lua for reports, hashes the payload and compares two archives byte-for-byte. No install/upload operation.

## Licensing

Original source/technical documentation: [MIT](LICENSE), copyright 2026 Northern Lights Labs. Original creative assets: [All Rights Reserved](ASSET-LICENSE.md), permitted for installation/use as part of LumenShift; no independent reuse/redistribution in other projects without permission. Third-party terms remain independent. See [provenance](assets/PROVENANCE.md). The complete distribution is not MIT-only.

No CurseForge project, upload or publication is authorized. Current work prioritizes interactive evaluation; publication requires native QA and final owner approval.
