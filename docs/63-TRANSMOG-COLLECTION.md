# Native transmog collection browser — beta.18

2026-11-10 · Northern Lights Labs. The owner requested full transmog collection browsing in the existing outfit browser, standalone operation without Narcissus, and an updated test ZIP. Repository/remote verified as `ProfessorMinty/LumenShift`, branch `feat/beta-integration`, PR #5. No installed-game, WTF, real equipment, graphics-setting, merge or publication action was performed.

## Delivered behavior

Open **Camera → Portrait Stage → Actors**, select an actor, then **Outfits → Collection**. The view scrolls to the collection controls; its top Back button returns to outfit tools. Previous inventory, equipment-set, saved-outfit, pose, effect, filter and capture tools remain available. Equipment sets and Saved outfits have distinct labels from collection sets and saved scenes.

| Control | Behavior |
|---|---|
| Appearances / category | Enumerates the categories the native API supplies, covering armor/clothing and weapon types. Weapon categories expose applicable main/off/ranged preview slots. No inventory ownership is required for a source preview if the native model API accepts it. |
| Search | Local plain-text name search in the selected category, including source names; exact appearance/source/item ID search. For sets, searches native set name/variant label or set ID. Search does not change WoW's wardrobe search. |
| Filters | All / Collected / Uncollected, native favorites and acquisition source. These filter the returned list locally. Advanced controls collapse to keep results accessible. |
| Click appearance / Sources | Preview a preferred collected source, or select an exact source variant. Tooltips expose source/item IDs; native icons are used when returned. Long names stay inside their buttons, with the full label in the tooltip. |
| Collection sets | Browse native set records and their variant labels; preview their primary appearance sources together. An unavailable or ambiguous source refuses the set before any actor replacement. Hidden-until-collected records stay hidden. |
| WoW collection class | Explicitly changes the native shared wardrobe class filter where the client provides that API. It does not change the player class or equipment. |
| Reset WoW wardrobe filters | Explicitly resets native display filters and clears the native appearance search, requesting collected/uncollected visibility. Refreshes immediately when the native search completes; reports pending search otherwise. The tooltip explains the shared wardrobe effect. |
| Saved outfits / saved scenes | Retain each explicitly selected exact appearance source. Numeric base-item outfits and explicit empty slots from previous versions remain valid. |

Collection data is loaded on demand, in cancellable batches of 24 appearances, with eight result rows per page. Category changes, leaving the collection browser, hiding controls, stage exit and the existing combat-exit option cancel pending reads. Completed lists remain transient. A completed scan cannot erase a focused, unsubmitted search field. Nothing queries the collection or loads a staged model at addon startup.

The browser respects the native data returned. **Forever's wardrobe code explicitly hides uncollected appearances by default.** The explicit filter controls request broader native results; LumenShift does not claim to reveal unavailable/hidden assets, bypass client restrictions, or enumerate arbitrary item IDs. Categories, class filtering and sets can have different client support. Missing collection APIs are reported inside this browser; inventory previews, poses, effects and the rest of Photo Studio remain usable.

## Architecture and saved data

- `Core/TransmogCollection.lua` owns native collection discovery, cleaned transient records, local filtering, cancellable category jobs, class/filter actions and pure set-to-preview conversion. Native results pass the existing accessibility/error wrapper before use. Names and native item metadata are not copied to SavedVariables or diagnostic exports.
- `UI/TransmogCollection.lua` supplies the existing pooled Photo Studio controls. It uses the native collection and LumenShift's existing staged actor; no copied Narcissus source, assets or item database, and no Narcissus API, load-order or TOC dependency.
- `Portrait.TrySource` validates the live source/category/slot and passes the request to existing identity-checked, buffered `SetOutfit`. Native `TryOn` receives the exact source ID as a string. Ordinary item previews retain their `item:<id>` path. Failure preserves the displayed actor and saved selection; it never falls back silently to a base item.
- Schema **18**, portrait/scene schema **3**, extends an outfit slot from numeric item ID (or `0` for hidden) to also accept a strict `{ sourceID = positiveInteger }` descriptor. Migrations retain older choices, scenes, outfits, onboarding and recovery originals. Full supported save banks still fit the existing 8,192-node copy budget. Invalid data is rejected without overwriting the input.
- No native graphics writer was added. Collection browsing never equips gear, applies real transmog, casts world spells or changes collection ownership. Explicit class/reset actions alter only shared collection display filters. Their prior search text cannot be read through a documented getter, so it is not silently cleared or falsely promised to be restored.
- Default combat continuity remains: filters and the active stage stay available. Native model restrictions can reject a particular preview locally. Existing optional HUD/filter choices, native graphics restrictions and cancellation behavior remain unchanged; no post-combat write queue is added.
- Defensive category/set limits are 25,000 appearances and 20,000 sets; oversized data produces a local error rather than silent list truncation. Source processing is bounded to 1,024 source records per appearance, with no more than 64 primary source records per set. These are addon resource limits, not claims about native collection sizes. No collection cache is persisted between sessions.

Saving an explicitly chosen source preserves that appearance. Capturing unspecified currently worn slots still uses the previous base-item readers; this is not a new exact snapshot of all worn enchants, bonus IDs or transmog components. Collection ownership is native metadata, not proof that every race/form/model can render an appearance. Source details which are uncached or unavailable require Refresh; there is no delayed automatic outfit mutation.

## Source evidence

Reviewed 2026-11-10 against pinned Forever (`Camelot`) UI/API mirror commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06`. **Source-confirmed declarations/examples**, not a new live-client acceptance result:

1. [TransmogItemsDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogItemsDocumentation.lua): category info has six returns including allowed weapon slots; appearance/source readers are optional; class/filter/search APIs belong to the shared collection system. `ClearSearch` reports completion.
2. [AppearanceSourceDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/AppearanceSourceDocumentation.lua) and [TransmogSharedDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogSharedDocumentation.lua): separate visual/source/item IDs, collection state, source metadata and category enum. A base item ID cannot substitute for an exact appearance source.
3. [TransmogSetsDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogSetsDocumentation.lua) and [Blizzard_TransmogShared.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_TransmogShared/Blizzard_TransmogShared.lua): native set records/variants; primary entries' field named `appearanceID` is passed to `GetSourceInfo` as a **source ID** by Blizzard's utility.
4. [Native wardrobe implementation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Collections/Mainline/Blizzard_Wardrobe.lua) demonstrates source-ID `TryOn`, category reads and class filters. [Actor API documentation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua) types the item-link/source argument as a cstring; LumenShift passes a string source identifier. These examples do not certify all native renderer paths.
5. [Forever wardrobe override](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Collections/Camelot/Blizzard_Wardrobe.lua) explicitly enables collected and disables uncollected appearances. That is why complete native enumeration and uncollected availability are separate claims.

## Verification

Final validation:

- **662/662 Lua 5.1 mock tests pass**, including all 633 previous cases and 29 collection regressions.
- **10/10 Python packaging tests pass**.
- **98 Lua files + four binding bodies** pass Lua 5.1 syntax checks; **67 runtime modules** pass TOC/version/assets/single-writer checks.
- Changed-document relative links, whitespace and the new modules' dependency/equipment/transmog-writer scans pass.
- Four off-client geometry previews inspected: collection entry, result rows, expanded filters and native sets. Fonts/textures are approximate; these previews do not render native models.
- Commands: `python tools/check.py --mocks --lua-runtime ../lua-test-runtime`, `python -m unittest discover -s tests -p test_package.py -v`, and `git -c core.safecrlf=false diff --check`.

During development, one UI test exposed the ambiguous Saved tab label; the outfit control is now named Saved outfits. Another test expected the wrong existing Ember warmth (.6 rather than .55); its expectation was corrected without changing the filter. Review also caught a pooled-label wrapping-state leak, now reset and covered by TC29. The final run is fully passing.

All automated checks are **simulated/off-client**. Native collection coverage, exact-source visuals, model-specific restrictions, native performance and actual input/capture remain **unverified for this new build**.

The TC01–TC29 cases cover lazy startup/no writes, categories/source variants, local filters, exact IDs, hand selection, buffered failures, native sets, atomic refusal, saved-source round trips, schema 17 migration, malformed/secret data, optional API failures, batched cancellation, explicit native filter changes/failures, GUI routing, fallback renderer, combat continuity, maximum save banks, source buttons, focused-search preservation, privacy-limited diagnostics and wrapping-style reset when pooled controls are reused. Prior restoration, graphics, capture, effects and combat tests remain in the full suite.

## Installation and owner test

1. Fully exit WoW. Extract the updated beta.18 ZIP. Replace only the existing **`Interface/AddOns/LumenShift` folder** with the complete extracted **`LumenShift` folder**. The final path must be `Interface/AddOns/LumenShift/LumenShift.toc`, with `Core`, `UI`, `Media` and the other packaged files beside it. Do not place the ZIP itself in AddOns, nest another LumenShift directory, or delete SavedVariables/WTF. No setup reset is needed.
2. Disable Narcissus for this standalone test and launch WoW. Open LumenShift's wheel → **Camera → Portrait Stage → Actors → Outfits → Collection**. The stage starts with your player copy; select another staged actor if desired.
3. Choose Head, Chest, Back and a weapon category. Search a known collected item; click its row, then try an alternate **Sources** entry. Confirm the staged model changes while your actual equipped gear remains unchanged. For a dual-hand weapon category, try both hand controls.
4. Expand **Filters** and try Collected, Uncollected, favorites and acquisition sources. If a known entry is absent, use **Reset WoW wardrobe filters** deliberately; this also changes the normal wardrobe's display filters/search. If WoW reports a pending search, use Refresh when ready. An empty uncollected list can be a client-data limitation, not a feature unlock requirement.
5. Open **Collection sets** and preview a native set/variant where available. Use the top **Outfits / back to outfit tools** button → **Saved outfits** to save it; switch an appearance, then load that outfit and confirm its exact variant returns. Save a scene too; after a normal reload, explicitly load it and compare.
6. Keep both combat options on, enter ordinary combat and check that the look stays constant and collection previews remain usable where native model APIs allow them. Test H/Hide controls, a screenshot, Escape and re-entry. Your prior combat opt-outs are preserved if already selected; no settings reset is required.
7. Report any missing category/API message, incorrect appearance or input issue with LumenShift's diagnostic export. Exports now include collection counts/loading state without outfit names or a collection dump. No version reconfirmation is requested.

The remaining photo work is native acceptance and fixes found by those checks, as described in [62](62-PHOTO-LIBRARIES-AUDIT.md). Public CurseForge distribution still requires release QA and separate owner approval.
