# Prior alpha reference (NOT part of current implementation)
A proof-of-concept called **LumenShift v0.1.0-alpha** was created earlier in this conversation, before the user decided Codex should lead engineering.

## What's known about that artifact
- A ZIP exists as a conversation download, **not currently tracked in this repository**.
- Six initial visual modes: Natural, Night Vision, Cinema, Lantern, Clarity and Moonlight.
- One large Lua file (approximately 25 KB) plus a TOC, Bindings.xml, README and two original short OGG sound cues.
- Uses brightness/contrast CVars and simple color UI overlays, a clickable cursor-near wheel, an advanced panel and command/keybind ideas.
- It was syntax-checked and mock-tested outside the live game. No evidence the live game successfully rendered the UI.
- Packaging was targeted toward Forever interface 16001, with an experimental Retail interface line. Do not assume that proves cross-client compatibility.

## Codex usage policy
Treat it as **historical prototype/reference**, not authorized code to import on Phase 00. Its implementation, security assumptions, event handling, keybinds, sound paths, CVar restoration and wheel interaction require a fresh audit. If provided as a local ZIP in a future step, Codex may inspect it read-only during research; copying any prototype module to production requires explicit user approval.

## What to keep conceptually
- Fast night-goggle toggle with original activation/deactivation cue.
- Discrete visual modes and a compact radial selector.
- Full advanced settings workspace.
- Reversible baseline design.

## What to reconsider
- Monolithic Lua and shared state.
- No proof of live Forever UI input/rendering.
- Unverified CVar ranges and direct writes.
- Mode/quality coupling and restore semantics.
- Sound level controls, overlay ordering and combat behavior.

The codebase must be built from validated design and tests rather than treating the earlier alpha as a finished dependency.
