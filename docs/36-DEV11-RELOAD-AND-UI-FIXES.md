# Dev.11 reload, recovery and window fixes

2026-11-07. Owner evidence: dev.10 bb3d6b23 on Forever **1.60.1:70862:16001**, supplied diagnostic export and screenshots. This document records the faults honestly; native dev.11 verification is still pending.

## Observed faults and causes

The owner export reports current Brightness **42**, original **45**, last verified/intended **42**, saved record state **owned**, and no setter attempt in the new login. Both Night Vision clicks fail RECOVERY_REQUIRED; applying Original fails USE_EXPLICIT_RESTORE; clicking Verify yields NO_PENDING_VERIFICATION. Native APIs and flags were available. This was a LumenShift state-machine lock after reload, not missing API support or an unconfirmed game version.

The setup screenshot separately shows Finish & Reload refusing because a journal exists. Its preference save had already succeeded, but the addon deliberately prevented the native reload. The prior tests required that behavior; dev.11 replaces those expectations.

Other screenshots show interleaved addon windows and cramped wheel labels. Those are owner-observed rendering/input faults. Off-client mocks cannot reproduce or certify native strata behavior.

## Changed behavior

- Finish saves choices and invokes native ReloadUI from the user's click even with active or interrupted graphics records. It does not clear originals, finish pending transactions or restore/reapply graphics. Combat and unavailable/failed native reload still give a specific message and retain saved choices.
- Startup remains read-only. A completed saved record is not automatically reactivated. The **next explicit mode/Apply click** can proceed if a fresh safe read exactly matches the saved last-verified value, provenance matches, and the record is owned with no failure. Planner, descriptor, baseline-domain, dependency and immediate/follow-up checks still apply.
- An already-matching mode can resume presentation without a redundant setter. Original can be the first post-reload click and restores the exact captured raw string.
- Brightness and bounded leaf settings retain their first originals across this transition. Contrast and quality remain separate layers. Pending, failed, externally changed, restricted or historically incompatible records require explicit recovery; they are not recaptured as a new baseline or replayed.
- Merely observing the same value is not proof no external writer acted (the same-value/ABA limitation remains). Continuing is a new user request based on current matching data, not a claim of uninterrupted ownership.
- Setup, Studio and export use a shared clamped, movable top-level window helper on FULLSCREEN_DIALOG, raised as a family. Drag the title bar; close/controls remain outside its hit area. Existing OnHide cleanup is chained. No foreign addon frames are enumerated, moved or reparented.
- Wheel icon/text groups move outward consistently; labels use fixed one-line width, smaller type, and a separate active underline instead of a variable-width star prefix. Center content is spaced separately. The ring geometry and keyboard selection remain.
- Verify pending recovery is disabled when no transaction awaits verification, preventing the misleading no-pending error from an irrelevant button.

[Native frame API source for 70862](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) declares SetToplevel, Raise, SetFrameStrata, RegisterForDrag, StartMoving and StopMovingOrSizing. [FontString source](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua) declares wrapping controls. API presence does not certify coexistence with every addon.

## Validation and handoff

Results: **238/238 Lua 5.1 mocks pass**, including 10 new regressions; **9/9 Python packaging tests pass**. Structural checks pass for 33 runtime modules, TOC/version/asset consistency and the single centralized native CVar call. Syntax checks pass for 42 Lua files plus four binding bodies. Setup, Studio and the Game Defaults wheel were inspected using the recorded off-client Lua geometry rendered in a browser. This checks layout in the approximation, not native font metrics, frame strata or real game input.

Automated regression coverage reproduces the owner's 45→42→reload→75→45 sequence, an exact raw original, same-target no-setter continuation, startup/export non-mutation, continuation after migration, pending/failed/conflicting records, invalid baselines, restrictions, setter failure and fresh pre-write drift. Leaf coverage checks Contrast/quality separation and retained originals. Window mocks exercise title-bar handlers, top-level flags, OnHide cleanup and lack of foreign-frame mutation. Reload tests include an interrupted write whose record survives intact.

Install the entire extracted dev.11 LumenShift folder, preserving SavedVariables. The old active Cinematic value need not be reset just to install this fix. After login, no automatic graphics change should occur. Click Night Vision and then Original; with the supplied healthy record these should produce 75 and 45. Reopen setup through native Settings or Studio → Accessibility, then Finish & Reload. The reload should occur and the setup should stay completed. Drag setup/Studio/export by their headers and check overlap with the previously interleaved addon. Check the wheel with Original and the longer Game Defaults label. Export if a failure remains.

SavedVariables is still not immediately durable or crash-proof. No live game was operated or installed files changed by the agent. Native font metrics, strata/input with the owner's addons, reload persistence and visible mode behavior require this owner retest. No merge or publication is authorized by this hotfix.
