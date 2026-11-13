# Native dev.6 evidence and warning-only compatibility

Recorded 2026-11-07. This supersedes docs/27's version/interface lock and historical-recovery restriction. It does not revise earlier evidence retroactively.

## Owner evidence: verified in-client, bounded to the report

Arctic supplied a complete diagnostic export from **0.2.0-dev.6**, source `ac6a2827e95d5014e04725d97228373e1c8851d3`, on Forever **1.60.1:70862:16001**, d3d12, 1920×1080. The report records completed setup, enabled controls, repeated accepted Brightness setters and matching immediate/follow-up reads for **45 → 75 → 45**. It records zero WARN/ERROR events. The owner's accompanying observation was that switching looked functional. We do not need another launcher/version verification.

Examples: events 469–475 end a restoration at 45/BASELINE; 481–487 subsequently activate 75/ACTIVE. The export ends with Night Vision active at 75 and original 45 retained. This is successful native evidence for that dev.6 path, not universal acceptance of every mode or setting. Sound API acceptance appears in the report; audible quality is not thereby proven. No quality-profile or Contrast round trip is shown. Raw reports/chat/private file paths are not committed.

The report also exposed two diagnostic problems: hundreds of slider-edit events displaced useful operations, and the summary still said native writes were NOT TESTED despite recording them. Dev.7 coalesces consecutive slider edits and retains session setter/verified-Brightness counters beyond event-ring eviction. Natural commits identify restoration instead of logging the mode schema's unused placeholder Brightness. Setter rejection produces WARN in the native-call summary.

## Owner policy: mismatch warns, it does not disable controls

Well-formed client version/build/interface differences now produce one nonblocking warning per login/reload. No acknowledgement or manual unlock is added. The reference identity and observed identities are evidence metadata, not a future-build allowlist. Reports distinguish WARN from BLOCKED; BUILD.json describes this policy.

Missing/malformed identity, unavailable APIs, inaccessible values, restricted flags, combat and unresolved ownership remain actual operation failures with specific reasons. This is not a claim that other game flavors are verified or supported for publication. Forever remains the product target and TOC 16001 remains based on observed evidence. Blizzard's own AddOns out-of-date checkbox is separate from the addon and cannot be bypassed by this policy.

An explicit release-only recovery may reconcile an original captured on a prior client version using the current descriptors, domains, flags and fresh observations. The historical record's source signature remains unchanged until verified release. New targets cannot use that reconciliation path. A client identity changing during an active transaction still invalidates the pending operation rather than retagging it.

## Validation

K19–K24 cover warn-once behavior, warning display failure, real API refusal, cross-version recovery failure, independent historical layers, no-setter release and reconciliation misuse. D39 covers log coalescing and counters surviving eviction. All are simulated Lua 5.1 tests. Dev.7's broader feature/test matrix is in [29](29-QUALITY-PROFILES-AND-NATIVE-TRIALS.md) and [30](30-CAMERA-MODE.md); no agent-operated native game changes were made.
