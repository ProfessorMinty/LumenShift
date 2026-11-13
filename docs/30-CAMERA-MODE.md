# Camera Mode and friendly-name controls

Authorized by Arctic on 2026-11-07: provide Alt+Z behavior and the two friendly-name toggles from the supplied macro. No camera movement, zoom, enemy names or nameplate controls are included in that request.

## Interaction

Studio → Camera has Enter/Exit Camera Mode, a saved **Hide friendly player and pet names in Camera Mode** option, a separate name toggle and **Restore original name settings**. Key Bindings → LumenShift offers **Enter / exit Camera Mode**; no key is automatically assigned/replaced. Normal operation needs no command or acknowledgement.

Enter uses the native SetUIVisibility(false), after successful name verification if that option is on. Exit first attempts to show the interface, then restores any names hidden by Camera Mode. The LumenShift keybind handles both steps. Native Alt+Z itself can reveal the HUD, but is not hooked: the user then clicks Exit Camera Mode to restore names. The page says this before entering. Existing UI overlays are UI objects and follow native HUD visibility; no claim of retaining them as world shaders is made.

The separate toggle hides friendly player/pet names when either is visible, or shows both when both started hidden. Its next click restores each captured original independently. For original player=1/pet=0, the return is 1/0, not 1/1. This deliberately improves on deriving both return values from the player setting alone.

## Architecture

- `Core/Camera.lua` manages explicit native HUD visibility and interaction, never CVar writes. A visibility failure is reported; captured name recovery remains available. No arbitrary simulated keypress, macro execution or frame hooks.
- `Core/NamePolicy.lua` permits only `UnitNameFriendlyPlayerName` and `UnitNameFriendlyPetName`, boolean 0/1, fresh native flags and readbacks. User macro evidence establishes intended scope; presence/effect still get checked in the actual client.
- `WriteBoundary.NewExperiments(runtime, true)` reuses the existing transaction engine with the narrow name policy, a separate camera journal/layer and observations. This adds no native CVar call site. Native setters, capture, planner, immediate/follow-up reads, compensation, conflicts and explicit recovery are shared with existing tested logic.
- Schema **5** adds `camera = {journal, sideEffects, hideWithUI}`. Valid schema-4 data migrates as a copy, keeping setup completion, all preferences and both previous journals. Schema-1/2/3 migrations continue through 5. Unknown/corrupt data remains quarantined and untouched. Old versions do not silently load newer data; restore before downgrading.
- Camera names do not enter visual-mode or quality plans. Their operations are serialized against other active transactions. Ordinary exit/toggle respects external changes; only the clearly labeled explicit original-name restore reconciles an interrupted/conflicting record. Startup/reload does not hide UI or write names. SavedVariables remains non-durable until normal game persistence.

## Sources and verification

Retrieved 2026-11-07 from the pinned 70862 Blizzard UI mirror:

- [Bindings_Camelot.xml lines 1310–1318](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_FrameXML/Bindings_Camelot.xml#L1310): TOGGLEUI uses UIParent:IsShown and SetUIVisibility(false/true). LumenShift uses the same visibility API, not a synthetic Alt+Z.
- [GameUIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/GameUIDocumentation.lua): SetUIVisibility takes one boolean and no return value. A protected call plus the observed UIParent state determines success.
- Owner-supplied macro: the exact friendly-player/pet CVar names and intended boolean behavior. This is owner evidence, not a claim that every game build exposes them.

C01–C15 simulate no startup/diagnostic mutations, mixed originals, initially hidden names, mode independence, native HUD API calls, optional name hiding, second-setter compensation, conflicts, reload recovery, absent/invalid/protected values, HUD failures, combat, native Alt+Z interaction, schema migration, clickable UI/keybinding behavior, arbitrary-key rejection and native callback reentrancy. New Camera Mode still requires owner testing in-game; no agent-operated UI or name changes were performed.
