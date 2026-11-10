# Collection and floating-name audit — beta.19

2026-11-10 · Northern Lights Labs. Repository and remote verified as `ProfessorMinty/LumenShift`; existing `feat/beta-integration` branch and PR #5. The owner requested verification of the transmog collection browser, a photo completion checklist, and investigation of names remaining visible. Two screenshots show ordinary NPC labels first, then Marshal Dughan's label surviving while other labels disappear. The owner identifies him as a quest giver. The screenshots do not contain CVar readbacks, target/interaction state or a build identity; no new version confirmation is required.

## Findings and changes

### Floating names

**Owner-observed:** Marshal Dughan's floating name remains with the old hide switches on. This is not proof of a nameplate or a failed setter. The NPC group already included `UnitNameFriendlySpecialNPCName` and `UnitNameInteractiveNPC`; claiming those keys were missing would be incorrect.

**Source-confirmed:** the existing switches were ambiguously labeled and only saved preferences until a separate Apply action. Their explanation and unavailable-setting feedback sat below the visible viewport. The footer could say READY without conveying the name operation's result.

Beta.19 changes that flow:

- Every switch explicitly says **Hide** and applies on click. **Hide all names** enables player, pet/minion, NPC and focused-name groups in one transaction. Chat bubbles remain a separate choice. **Restore names** clears those photo requests and returns their exact pre-photo values or pre-photo manual LumenShift name intent; it does not force every value to 1.
- Add a separate `UnitNameFocused` choice. Its existence/default is confirmed in the Forever 70532 capture; its ability to suppress this particular surviving quest-giver label is a **hypothesis pending native verification**. It is off by default, preserving earlier choices, and participates in the explicit Hide all action. Missing/restricted keys are reported locally.
- Pet coverage now includes the source-registered friendly/enemy minion, guardian and totem name settings. Individual unavailable keys do not disable available controls.
- Show applying/readback/error feedback near the bulk buttons, plus current ordinary/special/interactive/focused NPC setting values farther down the section. Successful CVar readback is labeled as such, not as proof that every world label vanished. Retry is optional after a reported failure; ordinary switches need no second Apply.
- The same controls are available in World Photo **Frame** and Portrait Stage **Scene**, including world-backed stages. Diagnostic exports include all admitted name-key values/flags and the latest operation result, without unit names or identities.

All changes pass through `Camera → names controller → WriteBoundary`, its planner, capture-before-write journal, immediate/follow-up reads and conflict handling. No second native writer, nameplate frame manipulation, target-clearing automation, soft-target configuration change or quest tracking change was added. The addon never repeatedly forces a surviving name off. Cosmetic filters and staged models remain independent of name edits; unavailable/combat name actions are not queued for later.

Schema **19** adds the focused preference without resetting setup, looks, source outfits, journals or previous group choices. Existing name descriptor version 4 remains valid for old records; the original keys and Boolean domain are unchanged. SavedVariables are still not immediately durable storage.

### Collection browser

Rechecked the exact-source/string TryOn path, category/hand mapping, atomic set preview, source descriptors in saved outfits/scenes, fallback renderer, class/display-filter boundaries, missing API behavior and multi-actor isolation. All functionality remains standalone; no Narcissus API, copied code/art, real equipment change or application of transmog is introduced.

Four regression cases reproduce three defects against the previous collection implementation:

| Reproduction | Previous result | Corrected result |
|---|---|---|
| Initial or subsequent timer queues a callback, then throws | Failed job can later complete or append more rows | Invalidate the generation immediately; stale callbacks cannot revive it |
| Leave a loading collection and explicitly return | Attempt marker prevents reading again until Refresh | Cancellation clears the attempt marker; re-entry resumes reads. Ordinary redraws do not retry native failures |
| One source is invalid, or a visual has more than 1,024 source records | A partial list can look complete | Disclose incomplete source details while keeping usable records |

Native source availability and actual rendered source variants still need owner acceptance. Existing ceilings remain 25,000 appearances/category, 1,024 sources/visual and 20,000 native sets. This is a bounded native browser, not a guarantee of access to everything in the game database.

## Primary sources checked

Observed 2026-11-10. These are source observations, not new live game results:

1. [Forever/Camelot 70862 Nameplates.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Nameplates.lua): Blizzard's NPC name selector separately sets `UnitNameNPC`, `UnitNameFriendlySpecialNPCName`, `UnitNameInteractiveNPC` and the literally spelled `UnitNameHostleNPC`. Its None option sets those four to 0. Quest circles are a separate setting and are not changed here. Player/minion display settings are separate too.
2. [Forever 70532 CVar capture, name keys](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua#L1665): registers `UnitNameFocused` and friendly/enemy guardian/minion/totem keys, with Boolean-looking 0/1 control usage and captured default 1. `UnitNameFocused` has no explanatory help string in this capture. Registration does not establish target/interaction precedence or visual effectiveness on the owner's current client. Every requested key still needs a present numeric 0/1 value and passing native flags/readbacks.
3. [Actor API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua), [collection API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogItemsDocumentation.lua) and [sets API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogSetsDocumentation.lua): source/item identifiers remain distinct; TryOn's source/link argument is a string; collection/set readers are optional. The further pinned wardrobe examples and Forever filter override remain documented in [63](63-TRANSMOG-COLLECTION.md#source-evidence).

## Verification

- Baseline: **662/662 Lua 5.1 mocks** passed before edits.
- Updated suite: **681/681 Lua 5.1 mocks**, including **19 new regressions** (NA01–NA19).
- **10/10 Python packaging tests**; **99 Lua files and four binding bodies** pass Lua 5.1 syntax checks; **67 runtime modules** pass TOC, assets, version and single-writer structural checks.
- The four collection regressions NA12–NA15 were also run with the previous committed collection module substituted in memory: all four failed. They pass against the correction. No tracked source was rolled back for that comparison.
- New tests cover immediate NPC/special/focused edits, expanded groups, unavailable/restricted CVars, exact originals, manual intent, separate bubbles, conflicts, failure recovery, migration, pooled controls, capture/combat refusal with no deferred writes, collection scheduling/cancellation/partial data and actor isolation. They run with Narcissus absent.
- An initial integration run exposed a stale schema assertion and a misplaced toggle-refresh assignment; both were corrected. New fixture expectations were corrected to distinguish successful compensation from unresolved recovery and to find source rows by ID rather than sort position. No failed test is described as passing.
- Three off-client geometry previews (World Photo names, lower value readout and world-backed Portrait Stage names) were inspected; they are approximate layout checks, not native font, model or game screenshots. Native name visibility, native transmog appearances and real screenshot files remain unverified for this build.

Commands: `python tools/check.py --mocks --lua-runtime ../lua-test-runtime`; `python -m unittest discover -s tests -p test_package.py -v`; `git -c core.safecrlf=false diff --check`; deterministic `tools/package.py` build from the recorded commit.

## Installation and focused owner test

1. Fully exit WoW. Extract the beta.19 ZIP and replace only the complete `Interface/AddOns/LumenShift` folder. Verify `Interface/AddOns/LumenShift/LumenShift.toc` exists, with Core, UI and Media beside it. Keep WTF/SavedVariables; do not reset setup. Disable Narcissus for the standalone test.
2. Open the wheel → **Camera → World Photo → Frame**. Scroll to **Names & Bubbles** near the bottom. Near Marshal Dughan, click **Hide all names**. The changes apply immediately; wait for the displayed operation result. Do this outside combat so native name edits are available.
3. Check the visible name. If it remains, scroll to the four displayed values: **NPC, Special, Interactive, Focused**. Record those and the operation message (or export Diagnostics). This distinguishes an unavailable/refused write from a visible label that remains even when its settings read back as 0.
4. If the name remains with all four values at 0, manually deselect him and move the pointer away as a comparison. Record whether his label then disappears. LumenShift does not clear targets or change interaction controls automatically. This comparison is an investigation, not a claimed fix or extra setup requirement.
5. Click **Restore names**, then test an individual Hide NPC switch, H/Hide controls, screenshot, Escape and re-entry. Confirm previous name behavior returns. Chat bubbles have their own toggle. Repeat the name test in Portrait Stage → Scene if using the world background.
6. In **Portrait Stage → Actors → Outfits → Collection**, exercise a category/source variant, sets, search/filter, alternate hands, two actors, save/load and leaving during loading. Use the broader [collection procedure](63-TRANSMOG-COLLECTION.md#installation-and-owner-test) for exact-source visual acceptance. Real gear must stay unchanged.

## What remains before photo mode is complete

All three agreed photo deliveries, the larger libraries and collection browser are implemented. Completion still requires native acceptance and resulting repairs, rather than another hidden enablement phase:

1. Resolve the surviving quest-giver name using the new values/result and target/interaction comparison. Confirm exact name restoration on the native client. Do not declare this fixed from mock readbacks alone.
2. With Narcissus disabled, visually verify representative models, poses, spell kits, exact appearance sources/sets, hand slots and saved scenes/outfits. Mocks cannot certify what native models render.
3. Inspect real ordinary/timed/burst/compositing screenshots and external captures with controls hidden. Check H/Escape, combat choices, reload/world transitions, exact return values and external-addon conflicts without deferred writes.
4. Check native performance, scrolling/text/layout at common UI scales and three actors with effects; fix issues found. Optional broader addon coexistence is separate from standalone operation.

Exact snapshots of every currently worn enchant/bonus/transmog component, richer item comparison and additional artistic assets are future extensions. True world-buffer shader grading, depth blur, transparent layered exports and world time freeze are not provided by these tools. Public release additionally needs the existing release QA and final owner approval. No installed-game operation, merge or publication occurred in this audit.
