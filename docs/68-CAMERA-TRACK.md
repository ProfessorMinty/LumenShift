# Camera track and foreground focus in beta.36

Arctic wants to keep a posed character in place while sliding the lens past foreground flames, lifting it for a high angle or lowering it for a shot from below. Occlusion is the visual test. Moving sideways should reveal a different part of the character through the foreground. This refines the earlier [FFXIV framing discussion](67-FFXIV-CAMERA-FRAMING.md).

## Portrait Stage

Open **Camera → Track** with the ModelScene renderer. Click the track map to place the lens or drag the two sliders for continuous preview. The horizontal rail runs across the current orbit heading. Lift moves along stage vertical. The lens keeps its orientation during a straight move by default. Enable **Keep aim on stage center** to look back at the stage origin at the configured Lens aim height. Moving a cast member does not move that aim point. Horizon roll is independent of the rails. **Center track** zeros lateral and vertical displacement while preserving the orbit and lens. **Overhead** and **From below** center the rails and put the camera directly above or below its aim point at the current distance.

The staged renderer owns its models and lens. An outdoor backdrop is still drawn from the normal WoW camera. A staged camera move creates parallax between staged actors, but cannot change which side of a real campfire the world draws. The actor-widget fallback preserves track data in a saved scene for a capable renderer. Scene format 5 and SavedVariables schema 23 give older scenes zero translation and preserve their angles. [Forever ModelScene camera API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameDocumentation.lua) · [Blizzard orbit conventions](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/Shared/ModelSceneCameras/OrbitCameraMixin.lua)

## World Photo

Open **Camera → Track** at the fire. Adjust **Side offset** while watching a gap between the flames and the character. **Tilt up/down** uses the normal player-centered vertical orbit. **Closer/Farther** sets camera distance, and Precision movement reduces both orbit speed and the distance step. Camera comfort settings can be paused with the existing temporary override. Exit restores owned shoulder offset, zoom and comfort settings using existing restoration paths. World orbit angles stay where you leave them. Collision and the client determine attainable real-world angles.

The Forever global API capture has ordinary orbit and zoom calls. Absolute world camera positioning belongs to the spectator interface. The publicly described OnlyCams height adjustment and native footroom CVar concern screen framing. Neither establishes an independent straight vertical rail through a live scene. [Forever global inventory](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/GlobalAPI.lua) · [OnlyCams author’s control descriptions](https://www.curseforge.com/wow/addons/only-cams)

## Depth of field

An aperture and a focus plane would let a near flame spread into a soft shape while details farther away stay sharp even at the same screen coordinates. The examined Forever camera API, model-scene API and CVar inventory do not establish a public focus distance, near-blur control or readable world depth buffer. Ambient-occlusion blur affects shading, and the Depth Effects graphics setting controls effect quality. Neither supplies the image and depth information needed to isolate the flames. [Forever camera API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CameraDocumentation.lua) · [Captured CVars](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua)

For a real campfire, take a clean World Photo screenshot. In an image editor, mask the close flames and soften that layer. A single screenshot cannot recover detail already hidden by an opaque flame. For a composite with a staged character, **Portrait Stage → Capture → Timer → Pair** supplies a background and a cast-on-green shot. Composite the sharp cast over the background and put a softened foreground-flame cutout in front. Pair does not generate a depth map.

## Field check

1. In Portrait Stage with a solid backdrop, arrange two actors at different depths, with the nearer actor partly covering the farther one. Slide sideways. The overlap should change while their poses and the lens angle hold.
2. Lift and lower the camera. Try both vertical views, then move off-axis with Keep aim on stage center enabled. Save the scene, reset the camera and reload the scene. Inspect a clean screenshot.
3. At a real campfire, try Side offset, a short vertical orbit and a quarter-step in distance. Check flame overlap, camera collision, and the shoulder offset and distance after exit. These visual results require the installed client.
