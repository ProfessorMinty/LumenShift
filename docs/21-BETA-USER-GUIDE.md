# LumenShift 0.2.0-dev.5 — install and try it

Northern Lights Labs · World of Warcraft: Forever · interface 16001. The already-reported 1.60.1 builds 70840 and 70790 are recognized; no launcher reconfirmation is needed.

This update replaces the awkward setup flow and removes extra unlocks from mode and graphics testing. It includes six visual modes, editable Brightness/optional Contrast, effects, sounds, wheel, Studio and custom quality profiles. Some advanced graphics tiers are still unfinished. Dev.5's automated checks are not a native game test.

## Install

1. In the old addon, select **Natural** and **Current Baseline** if settings are active. Keep unresolved recovery data rather than deleting it.
2. Exit WoW. Keep a backup of your existing LumenShift addon folder.
3. Extract `LumenShift-0.2.0-dev.5-<commit>.zip`. Replace only the old **LumenShift** folder in `_forever_/Interface/AddOns` with the entire extracted folder. Keep your SavedVariables so your preferences carry forward.
4. Check that `.../_forever_/Interface/AddOns/LumenShift/LumenShift.toc` has **Core**, **UI**, **Media** and **Bindings.xml** beside it. Do not install the ZIP or TOC alone, and avoid `LumenShift/LumenShift` nesting.
5. Start WoW, enable LumenShift in AddOns and log in.

## Setup and preferences

New setups open automatically. If yours was already completed, open **Settings → AddOns → LumenShift → Setup wizard** to see the replacement.

Choose screen effects, Night Vision sounds, menu animations, reduced motion, high contrast and the on-screen launcher. Click **Finish & Reload UI**. Your choices and completion are saved before reload is requested. **Save & Close** saves without reloading; **Later** or X leaves the draft unsaved. Reduced motion takes precedence over menu animation.

Setup does not change graphics. If reload cannot run, the preferences stay saved and the window explains why. A temporary unreadable graphics value no longer silently saves controls as disabled. A previously completed dev.4 setup can select a mode immediately; rerunning setup is optional.

After reload, reopen setup to check your choices, then close it. Completed setup should not automatically appear again.

## Try the actual modes

Outside combat, use a stationary scene where brightness changes are visible.

1. **Left-click** the LumenShift launcher or minimap button to open the wheel. Choose **Night Vision**. It applies Brightness 75 and checks the result automatically. No confirmation command or exported card is required.
2. Choose **Natural** to return to your actual original value. It does not assume the original was 45.
3. Try **Lantern**, then **Natural**. Other mode Brightness targets no longer require a separate unlock. Effects and sounds follow your saved preferences.
4. **Right-click** the launcher/minimap button for Studio. In **Visual Modes**, choose a mode, adjust its Brightness, then click **Apply**. Sliders save preferences; Apply changes the scene.
5. To try Contrast, set its value in the same editor and turn on **Adjust Contrast with this mode**, then Apply. Natural restores the owned Brightness and Contrast originals.

Quality and modes are independent. No mode automatically reapplies after login or reload. The wheel also supports labeled keyboard selection, arrows/Tab, Enter and Escape; optional bindings are in Key Bindings → LumenShift. Commands are shortcuts only.

## Advanced Graphics

Use **Studio → Advanced Graphics** for the named experimental controls.

- Choose a setting, enter a value inside its displayed test range, and click **Test & Restore**. The addon tries it for about two seconds, checks readback, restores the captured original and checks again. Start from Natural with previous experiments restored. If a conflict or failure prevents restoration, the status shows recovery instead of pretending success.
- To keep a quality change active, save its value into **Balanced**, **Vista** or **Performance**, then click **Apply … profile**. These start as empty custom profiles; no guessed optimization values are assigned. **Current Baseline — restore owned quality** restores them separately from visual modes.
- Saved profiles remain available after reload. A prior test or same-login calibration certificate is not required. Each Apply still checks actual current availability, flags and values.

Preview/export remain optional tools. These test ranges are addon policy limits, not universal safe maxima or performance promises. Shadow/light/water tiers, HDR, renderer and unmapped controls remain observation-only. They are not secretly implemented behind an unlock.

## If something fails

Open **Diagnostic Center → Export Complete Diagnostic Report → Select All → Ctrl+C**, then paste the report with a short description of what you saw. It collects the details; you do not need to paste chat or run a list of commands. Reports exclude names, chat, accounts, local paths and raw native exception text; nothing uploads automatically.

An external change is preserved rather than repeatedly overwritten. A partial Brightness/Contrast operation retains the originals. Use Diagnostic Center's Brightness recovery buttons, or Advanced Graphics' visual/quality recovery buttons, to review and explicitly restore them. A recovery preview requires confirmation because it may replace a newer external value. This is separate from normal Natural/Current Baseline use.

Restore before disabling, updating or removing LumenShift. SavedVariables is written by WoW during normal persistence events, not immediately after every click; an external report is useful for unresolved recovery. Deleting addon files or SavedVariables does not undo graphics changes.

## Build status and terms

Automated validation and the interaction investigation are recorded in [dev.5 notes](https://github.com/ProfessorMinty/LumenShift/blob/feat/beta-integration/docs/26-USABLE-SETUP-AND-CONTROLS.md). Native rendering, preference persistence, audio/effects and the new direct control paths still need evaluation in this build. It is not the accepted feature-complete beta or a CurseForge release.

Original code/technical documentation: MIT, copyright 2026 Northern Lights Labs. Original creative assets: All Rights Reserved, with permission to install/use as part of LumenShift. See both included licenses; third-party terms remain independent.
