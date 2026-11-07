# Hotfix compatibility and setup upgrade — dev.6

2026-11-07. Version 0.2.0-dev.6; schema 4 unchanged. This supersedes the exact-hotfix allowlist and completed-setup upgrade behavior documented in docs/25–26.

## Actual owner report

**Verified in-client through the owner-provided export:** dev.5, commit `5704257ff2f7d8e2a5dd02102b302c65dc0dafdf`, loaded on **Forever 1.60.1:70862:16001**, build date Nov 6 2026. Brightness 45 and Contrast 60 were readable; secure/read-only/locked/server flags were false. Native getter, setter-availability, timer and reload checks passed. Studio, wheel and diagnostic export initialized. Onboarding was already complete, saved controls remained off, and there were no ownership/recovery records.

A wheel click logged `product.operation UNSUPPORTED_BUILD` before any graphics write. The addon itself rejected the newer hotfix because its allowed list stopped at 70840. The absence of setup was a separate upgrade flaw: dev.5 respected the older completed marker and did not automatically display the redesigned setup. No dev.5 setup Save/Finish event appears in the report. This does not establish lost preferences or a native ReloadUI failure.

The diagnostic headings also confused a read-only diagnostic snapshot with control availability, and the legacy brief report still referred to production admission and mandatory calibration. Those descriptions were stale.

## Source comparison and policy decision

**Named UI source mirror:** [70840 → 70862 comparison](https://github.com/Gethe/wow-ui-source/compare/5987a8e2304c1331346dc861d5ccacf4c510cf0f...9dc84f0d3bbae1768ac3405b3716000bd93eda06), inspected 2026-11-07. Commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06` is labeled 1.60.1 (70862). Its five changed files are Barbershop Lua/XML, FrameControlsManager.lua, SmartNavigation.lua and version.txt. The CVar declarations and graphics definitions have no changes in that diff. This mirror comparison is not an engine-binary comparison or universal compatibility guarantee.

**Engineering decision:** explicit development controls use the supported Forever **1.60.1 / interface 16001**, starting at build **70790**, with fresh API/value/flag checks and readbacks on each operation. Numeric hotfix numbers are recorded rather than individually unlocked. This is a deliberate correction of the earlier exact-build policy so routine hotfixes do not repeatedly disable the product. It does not establish native test results for unknown hotfixes. A different version/interface, an older build or malformed identity remains unsupported; there is no Retail/Classic cross-flavor inference.

`Compatibility.Policy()` exposes a copy of the private contract. `ObservedSignatures()` lists the three identities with recorded evidence, separately from permitted development controls. The package manifest reflects both the actual family policy and observed identities; it no longer presents a list of observed builds as the whole supported set. Production catalog admission and native acceptance remain separate from this explicit development path.

Pending operations and recovery records still carry the **exact session signature**. A changing identity cannot finish an old transaction or retag historical originals. Cross-build recovery remains explicit review work; startup never automatically restores an uncertain value. Bounds, single writer, capture, planner, readback, ownership and conflict checks are unchanged.

## One-time setup upgrade

When opening a validated copy of schema-4 data written by dev.1–dev.5 (or beta.1), an old completed marker becomes incomplete for the updated setup. All configuration, profiles and both journals are preserved. The new addon version is recorded on that copy, so saving the new setup prevents repetition on the next reload. No schema field is added and no account data is deleted or reset.

The window says **LumenShift setup updated** and shows the existing choices. Save & Close and Finish both save completion; Later/X does not. Finish requests reload only after saving, and retains choices if combat, ownership or a missing/failed reload prevents it. First login after upgrade makes no graphics changes. A completed current-version setup stays closed on ordinary reloads.

## Diagnostics and visible status

Reports now say **Mode controls: AVAILABLE** when the current mode path has the required capabilities, or give its actual blocking reason. This considers active operation/recovery, combat, native setter/timer and fresh Brightness flags as well as identity. It is a preflight status, not a promise that the following setter will succeed.

Current graphics values are labeled a snapshot; diagnostic checks state that the scan itself applies no settings. Raw security flags remain accurate (`readOnly=no` is not removed). Mandatory-calibration and production-admission messages were removed from the brief diagnostics. Unimplemented graphics tiers are identified as unimplemented rather than implying all controls are read-only. Successful native operations still need current readbacks and remain recorded in the session history.

## Validation

- **163/163 simulated tests under Lua 5.1**, including six added regressions: owner-report setup/70862/button workflow, supported-family hotfixes, malformed identities and policy-copy isolation, unavailable/restricted APIs on 70862, setup upgrade with preserved originals, and pending transaction identity changes.
- Existing invalid versions/interfaces, historical cross-build recovery, failure/rollback/conflict, direct Contrast/quality, saved preference and no-startup-write tests remain. Earlier exact-hotfix rejection expectations were updated to test the supported version/interface/minimum-build contract.
- Syntax: 29 runtime modules, six Lua test files and three binding bodies. Structural and whitespace checks pass.
- **8/8 Python packaging tests**, including manifest policy/evidence consistency and rejection of missing or contradictory contracts.
- Local package is built from committed Git blobs, compared across two byte-identical builds and checked against its manifest. Archive identity is recorded in the PR/local receipt.

**Dev.6 native results remain unknown.** The supplied dev.5 report establishes a loading/control-block failure, not a successful write or dev.6 acceptance. No installed addon was changed, no game graphics/reload action was executed by development tools, and nothing was merged or published. The [current guide](21-BETA-USER-GUIDE.md) goes directly from the automatically reopened setup to Night Vision/Natural testing. No version reconfirmation or manual data reset is needed.
