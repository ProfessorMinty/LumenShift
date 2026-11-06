# Arctic's first controlled Brightness test

**Build:** LumenShift `0.1.0-dev.2`, branch `feat/phase-01b-brightness-engine`. **Target already confirmed:** Forever `1.60.1.70790`, interface `16001`. No launcher reconfirmation is needed.

This is an unreleased test build. The owner has authorized implementation; **actual graphics testing still needs explicit owner approval**. Installing/loading and previews never enable the writer. Do not run a confirmation command until the controlled live test is approved. The agent has not installed this build into the game or executed any live writes.

## Install the complete folder

1. Close WoW before replacing addon files. Keep a copy of the existing diagnostic `LumenShift` folder outside `AddOns` if you want to return to dev.1. Do not delete SavedVariables, `WTF` or `Config.wtf`.
2. Obtain the reviewed branch/commit, then copy the **entire `addon/LumenShift` folder**, including `Core` and `LumenShift.toc`, into the existing Forever `Interface/AddOns` directory. A supplied local test folder contains this same `LumenShift` directory. Copy it unzipped; the TOC alone is insufficient. A GitHub repository ZIP, if used, must first be extracted and only its `addon/LumenShift` subfolder copied.
3. The result must be exactly:

```text
World of Warcraft/
  _forever_/
    Interface/
      AddOns/
        LumenShift/
          LumenShift.toc
          Core/
            Bootstrap.lua
            ...the other 12 Lua modules...
```

4. Start Forever, enable LumenShift in AddOns, and enter the game. Use a safe location outside combat. Do not begin with an unresolved recovery record or another addon actively changing brightness.
5. Type `/ls`, then `/lumenshift`. Both should show `0.1.0-dev.2`, the known client identity, current Brightness and Contrast with flags, the writer API's availability, original/recovery state and commands. Initial state should be `BASELINE`, original `not captured`, and no confirmation token. If the state is `RECOVERY` or data is quarantined, stop the normal round trip and preserve the report.

The previous observation was Brightness 45 and Contrast 60. **Whatever is actually read now is authoritative.** The engine must not restore a hardcoded 45. Note both current values before continuing. Confirm that loading and bare diagnostics did not visibly change the scene; this observation alone is not a complete native setter trace.

## Read-only preparation

1. Type `/ls on`.
2. Read the `RECOVERY CARD`: original Brightness, current Brightness, proposed `75`, exact build and confirmation number.
3. Save that card outside the game (for example, a screenshot or a text note). The in-memory journal and chat history are **not guaranteed to survive a crash**. SavedVariables is not immediately durable.
4. Brightness must still be the original and the scene unchanged. `/ls cancel` can revoke the preview without a write. Do not confirm a stale or unexpected card.

If current Brightness is already 75, refusal `ALREADY_AT_TARGET_NO_OWNERSHIP_CHANGE` is expected. There is nothing to activate or restore. Do not change graphics merely to manufacture a baseline under this procedure.

## Approved live round trip only

After explicit live-test approval, use each newly displayed token. `N` and `M` below are placeholders, not literal commands to paste.

1. With a saved, current `/ls on` card, type `/ls confirm N`. This authorizes the displayed Brightness operation and at most one compensating write on a normal on/off failure. It does not grant persistent permission.
2. Expect `Immediate readback matched`, state `AWAITING_VERIFICATION`, current Brightness numerically 75 and the exact original retained. Observe whether visibility changes as intended and whether anything unexpected occurs. Do not change graphics options, reload, relog or activate another mode during this round trip.
3. After observing the scene, type `/ls verify`, then `/ls`. Expect `ACTIVE`, current Brightness 75 and the original unchanged. Record the elapsed time between confirmation and verification; no validated settling interval is claimed.
4. Type `/ls off`. Save/review its new card: target must be the **exact original from step 1**, current must still match the owned value.
5. Type `/ls confirm M`, using this new token. Expect `AWAITING_VERIFICATION` and the original still retained.
6. Observe the scene, type `/ls verify`, then `/ls`. Expect the original raw Brightness, `BASELINE`, original `not captured`, zero recovery records and Contrast unchanged throughout. Record visual restoration and any Lua errors separately from readback results.

Both aliases support the same subcommands. Do not use repeated confirmations as a retry loop. A failed command consumes its token. `cancel` never restores an active brightness value.

## If anything fails or conflicts

- Stop the normal sequence and capture `/ls` output plus the external recovery card. Do not restart/reload to try to clear the error. The engine makes no background retries.
- If normal activation/deactivation fails, one permitted compensation may already have attempted to return to the operation's before-value. `AWAITING_VERIFICATION` after failure means `/ls verify` is still needed to confirm that compensation; it is not successful Night Vision activation.
- `CONFLICT` means a current value was changed or could not be trusted. The engine preserves that current value. Decide whether the saved original is still the setting you want before any recovery write.
- **Restore My Brightness:** `/ls restore` is a read-only preview. It explicitly displays the current value that would be replaced by the retained original. Only after approving that recovery, save the card and use the new `/ls confirm N`, then `/ls verify`. If current already exactly equals the original, this only releases bookkeeping; no setter runs.
- A restore after reload, conflict or uncertain pending state never automatically reapplies the uncertain prior value on failure. A restriction, changed build, invalid baseline or missing API may make automatic recovery unavailable. Preserve the card, stop testing and report the exact diagnostic code. If necessary, manually return Brightness through the game's own graphics controls using the saved original; do not reset all graphics or guess 45.
- If the journal was lost in a crash, the addon cannot know the original. Use the external card. Deleting the addon or SavedVariables does not undo a persistent CVar change.

Before disabling, replacing or removing this write-capable addon, restore Brightness and verify it. Keep the external card until a separately approved restart/persistence check confirms the setting. Reload, cold-start, combat and deliberate external-conflict experiments need their own controlled acceptance steps and approval; they are not automatically included in the first round trip.

## Record results without overstating them

```text
Source commit / folder supplied:
Addon version displayed:
Test date and live-test approval:
Renderer / display setup (if known; do not change it):
Before: Brightness raw=        Contrast raw=
Preview: original=             target=75; card saved externally=yes/no
Confirm result / immediate readback:
Visual change observed:
Elapsed time before /ls verify:
Activation verify/state:
Off preview target / confirm result:
Restoration verify/state / final Brightness raw:
Final Contrast raw:
Recovery record count:
Errors / conflicts / compensation / other observations:
```

Report only the addon output needed for the test; omit unrelated chat, character/account names and private paths. A full successful round trip establishes this tested commit/setup only. The 64 automated mock passes do not fill in this native result sheet.
