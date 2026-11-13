# Live native photo sliders — beta.11

2026-11-09 · Northern Lights Labs. The owner reports that a native effect appears only after releasing the slider and asks for live dragging. That was beta.10's implementation choice, not a claim of a client requirement. This update implements live preview for Brightness, Contrast, Sharpness, supported Bloom and FOV. Styling sliders (filter, vignette, glow, grain and letterbox) already update directly and remain unchanged.

## User behavior

Drag and keep holding a Light or FOV slider: the scene now updates during the drag. Native changes are paced, rather than emitted at every mouse event. The numeric draft follows the pointer immediately, and the latest requested value is retained for the next verified update. Releasing the mouse leaves that endpoint queued; the last intermediate value cannot replace it. Typing a new value and pressing Enter uses the same path.

Capture screenshot, Hide controls/H, Before/After and the in-editor restore buttons finish the latest pending preview before acting. This prevents an external/native capture from taking an earlier intermediate setting. Escape/Exit and combat instead discard unissued input; an already-issued operation finishes its existing verification and normal restoration policy. A failed preview cancels a waiting capture, leaves Exit visible, and stops the current gesture without automatic retry. A new deliberate drag can retry where existing native/recovery checks permit it. FOV stays independent of the lighting Before/After comparison.

The native Light page says **Live preview as you drag**. The grabbed slider is not rebuilt by intermediate verification callbacks, so it retains pointer capture and its current draft. Closing/clean view clears only the editor's focus as before. Missing native features affect their own control. No unlock, token, settings reset or renewed setup is added.

## Engineering

`Core/PhotoPreview.lua` is a session-only, event-driven coalescing queue. It contains no native setter and no permanent polling/update handler. Known controls are dispatched through `PhotoEditor.Native` or `Camera.ApplyFOV`, which now accept an optional completion callback. Both still use the existing single write boundary, planner, captured originals, fresh checks and immediate/delayed readback.

- At most one queued value per control; newer input replaces that value without allocating a timer per movement.
- One native transaction in flight. A 50 ms queue delay combines events and leaves the preceding writer's callback before another operation starts. Combined with the existing 150 ms scheduled verification, continuous native writes target roughly five updates per second under normal timer scheduling. This is not a measured client latency/FPS guarantee; slow frames can lower the rate.
- FIFO between controls preserves changes to multiple sliders. There is no idle timer after input finishes.
- Generation checks invalidate cancelled timers. Failures clear pending values/actions and halt the current gesture. New input cannot make an old callback consume the new queue.
- Native return snapshots and canonical originals are captured by existing controllers, never by the queue. Schema **13** and saved preferences remain unchanged. Startup/reload does not schedule a preview or reapply graphics.
- Capture/clean-view/comparison actions wait at most for already requested work, rather than silently dropping the last pointer value. Exit/combat cancel that work. Camera's existing deferred Exit behavior now covers FOV verification as well as photo lighting.
- Diagnostics add the preview state, pending control count, busy flag and error code. No mouse coordinates, user text or new personal data are exported.

Directly sending every pointer event would overlap this addon's verification transactions and could add unnecessary CVar/renderer work. Coalescing and serialized verification address that implementation problem while retaining exact restoration. Actual rendering cost, smoothness and coexistence with other addons still need an owner-run check; no universal performance guarantee is made.

## Owner check

1. With WoW closed, replace the whole addon folder using the beta.11 ZIP. Keep SavedVariables; no reset is needed.
2. Open the launcher → Camera → Light. Drag Brightness slowly and **keep the mouse held**. The scene should update several times before release. Repeat for Contrast and available Sharpness/Bloom.
3. Drag quickly, stop at a recognizable number and release. The scene/readback should finish at that endpoint, without the knob jumping back during the drag.
4. Try FOV on Frame. Then try Capture or Hide controls immediately after a drag; the endpoint should finish before the image/clean view appears. H reveals controls again.
5. Press Escape while dragging or immediately afterward. The HUD returns, unissued values are discarded, and existing matching Camera-owned values restore. Verify the original values and appearance. Do not induce a crash to test persistence.
6. If dragging hitches, loses mouse capture, settles at the wrong value or fails to restore, export diagnostics and describe the control/visible result. Actual graphics performance is not established by mocks.

## Validation

Sixteen LIVE regressions cover input bursts, final endpoints, simultaneous controls, canonical originals, live FOV/Escape, capture/clean-view ordering, exit/combat cancellation, failed setters and external drift, comparison ordering, missing timers, numeric entry, stable controls, failed capture cancellation and stale callback isolation. The earlier PE drag regression now asserts application while the mouse remains held. **493/493 Lua 5.1 mocks**, **10/10 Python packaging tests**, syntax for **74 Lua files + four binding bodies**, structural checks for **50 runtime modules**, the existing asset hashes and whitespace checks passed. These are simulated results, not new native acceptance. The broader [photo editor implementation and limits](54-IN-SCENE-PHOTO-EDITOR.md) remain applicable.

Current local documentation link validation: **128 links passed**. The development ZIP is built reproducibly from the recorded commit; its identity and digest are in the PR and local receipt. No installed game files/settings, merges or publication were performed.
