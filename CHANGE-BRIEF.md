# CHANGE-BRIEF — Jelly Hop: Fork From Above

Version 1 · 2026-10-01 · written before image or audio asset generation. Later revisions are added as new dated sections; this version is not rewritten.

This is the plan for the asset slice and my predictions of what will go wrong.

## Changes from earlier documents

These refine STORYBOARD.md v1 and CONCEPT.md v1, which stay as committed:

- **Music dip:** the music is quieter and muffled only while an **on-screen** shadow is growing. This replaces the earlier "any shadow" rule.
- **Splat sound:** SFX-SPLAT is split into **SFX-SPLAT-FORK** and **SFX-SPLAT-SAUCE**.
- **Background:** a new **ENV-ROOM** layer sits behind a repeating **ENV-TABLE** strip.
- **Shadow:** **ENV-SHADOW** is code-drawn in Godot, not generated.

## Asset list

| ID | Asset | Made by | Storyboard panels |
|----|-------|---------|-------------------|
| CHAR-IDLE | Idle wobble | Image model, from the approved reference | 1, 6 |
| CHAR-BORED | Bored slump | Image model, from the approved reference | none (character sheet pose) |
| CHAR-SCOOT-A | Scoot: squash and lean | Image model, from the approved reference | none (character sheet pose) |
| CHAR-SCOOT-B | Scoot: stretch and lean | Image model, from the approved reference | none (character sheet pose) |
| CHAR-ANTIC | Crouch | Image model, from the approved reference | 2 |
| CHAR-RISE | Stretched, rising | Image model, from the approved reference | 2 |
| CHAR-FALL | Widened, falling | Image model, from the approved reference | none (character sheet pose) |
| CHAR-LAND | Landing squash | Image model, from the approved reference | 4 |
| CHAR-WORRY | Worried, eyes up | Image model, from the approved reference | 3 |
| CHAR-SPLAT | Splat | Image model, from the approved reference | 5 |
| CHAR-RESPAWN | Re-forming | Image model, from the approved reference | 6 |
| CHAR-CELEBRATE | Relief stretch | Image model, from the approved reference | 7 |
| ENV-ROOM | Dim room layer (new) | Image model | all (new; not in STORYBOARD.md v1) |
| ENV-TABLE | Tablecloth strip that repeats seamlessly | Image model | 1–7 |
| ENV-PLATE | Plate | Image model | 1–7 |
| ENV-SAUCE | Spilled sauce | Image model | 1, 2, 4, 5, 6 |
| ENV-FORK | Fork | Image model | 1–6 |
| ENV-DOME | Glass dessert dome | Image model | 1, 7 |
| ENV-SHADOW | Growing fork shadow | Code-drawn in Godot (not a generated asset) | 1, 3, 6 |
| SFX-HOP | Hop | Audio model | 2 |
| SFX-LAND | Landing | Audio model | 4 |
| SFX-WARN | Metallic warning scrape | Audio model | 3 |
| SFX-SPLAT-FORK | Heavier squish with a brief metallic impact | Audio model | 5 |
| SFX-SPLAT-SAUCE | Softer, wet splat | Audio model | 5 |
| SFX-WIN | Win sound | Audio model | 7 |
| MUS-LOOP | Playful, slightly tense music loop | Music model | 1–7 |

- All 12 gameplay poses are generated. Each is derived from the approved reference and checked against CHARACTER-SHEET.md for shape, palette, facing, and collision fit before it is accepted.
- No left-facing frames are generated; the jelly is flipped at runtime.
- No sound for scooting and no respawn sound.

## Event-to-sound map

General rule: each sound plays only from the code that already represents its game event, at the moment the game changes state. Sounds never decide game state, and muting a sound changes nothing about what happens.

| Sound | Exact trigger | How double triggers are prevented |
|-------|---------------|-----------------------------------|
| SFX-HOP | The jelly changes from grounded to airborne after a fresh jump press | Only that state change plays it. Presses that skip the intro, restart the slice, or happen during the splat lock never start a hop. |
| SFX-LAND | The jelly changes from airborne to grounded on a plate | Once per landing. Respawning on a plate is not a landing and stays silent. |
| SFX-WARN | A fork enters its shadow phase while its shadow is on screen | Once per fork cycle, at the start of that phase. A shadow that starts off screen stays silent even after it scrolls into view. |
| SFX-SPLAT-FORK | The jelly enters the splat state from a fork hit | Hits are off through the splat and re-form, so the splat state can't be entered again until control returns. |
| SFX-SPLAT-SAUCE | The jelly enters the splat state from landing in sauce | Same as SFX-SPLAT-FORK: one splat sound per failure. |
| SFX-WIN | The jelly first reaches the dome in a run | A one-time flag blocks repeats; restarting the slice resets it. |

## Music behavior

- **Intro pan:** MUS-LOOP starts quieter, then rises to normal volume when play begins, whether the pan ends or is skipped.
- **Normal play:** the playful loop at normal volume.
- **Warning:** quieter and muffled while an on-screen shadow is growing; fades back when none is.
- **Failure (either splat):** a short dip, back to normal on respawn, unless an on-screen shadow is still growing.
- **Pause:** very quiet and muffled; back on unpause.
- **Success (dome reached):** the loop fades out and SFX-WIN plays.
- **End of the slice:** quiet while the "press any key to play again" prompt waits. On restart, the music starts again from the top.
- **Mute:** the slice will have mute controls, as the assignment requires; the keys are decided during the build.

## Predicted failure cases and how I will check them

| # | Prediction | Check |
|---|-----------|-------|
| 1 | Generated poses drift from the sheet (eye line, eye spacing, mouth, outline weight, highlight position) | Compare each frame at game size against `poses.svg` and the consistency rules before accepting it |
| 2 | The face is unreadable at 64 px | View the in-engine jelly at 1280 × 720, 100% zoom |
| 3 | The jelly disappears against a plate, the fork, or the table | In-engine screenshots on each surface; confirm the outline holds |
| 4 | The generated room or table is too bright or busy, hiding the shadows or the sauce | In-engine screenshot with sound muted |
| 5 | A sound fires twice for one event (held jump, rapid hops, a splat) | Automated scripted input that counts triggers per event |
| 6 | The skip key or the restart key also triggers a hop | Automated test that SFX-HOP and movement don't occur |
| 7 | A jump held through a splat fires a hop when control returns | Automated test: zero SFX-HOP until a fresh press |
| 8 | An off-screen shadow plays the scrape or dips the music | Scripted camera position test, plus listening |
| 9 | The music flickers or stays dipped with overlapping on-screen shadows | Listen during an overlap and log the music volume changes |
| 10 | The music loop clicks or gaps at the seam | Listen to at least three repetitions; inspect the loop point |
| 11 | A fork's shadow starts off screen because the camera trails the jelly | Playtest the camera look-ahead on every plate |
| 12 | The checkpoint fork doesn't restart at its safe window on respawn | Scripted respawn test |
| 13 | The camera shakes on a sauce splat | Playtest both failure types |
| 14 | Scoot A's 2 px box mismatch feels unfair | Playtest near fork strikes while scooting |
| 15 | The slice is hard to understand with sound muted | A full muted playtest |

---

## Assignment 3 — Three 3D assets (Blender MCP → Godot)

Version 1 · 2026-10-12 · written before any 3D asset was built. Added as a new dated section; the Assignment 2 sections above are unchanged. Later A3 revisions are added as new dated sections at the end of this file; this version is not rewritten.

### Scale reference

The jelly cube (the player) is **0.5 m** on each side. All asset sizes below are justified against it. Blender units are metres and Godot 3D units are metres, so no conversion is needed.

### Measurements that informed this brief

Taken in my own Blender 5.2.2 "Learn the window" session:

- Default cube: 2 m × 2 m × 2 m, 12 triangles.
- Default UV Sphere: 960 triangles (scene total went from 12 to 972).
- UV Sphere at 12 segments and 6 rings: about 120 triangles (scene total 132).

### Asset 1: Fork

- **Role:** The hazard the jelly avoids.
  - *Planned placement (to be confirmed against the Assignment 2 project):* stabbing down from above at selected spots along the jumping route, so the jelly has to time its jumps.
- **Size:** 0.5 m wide × 0.05 m deep × 1.5 m tall. That's 3 jellies tall, 1 jelly wide at the prongs, and a tenth of a jelly thick, so it looks threatening beside the jelly without being oversized, and stays fairly flat while still showing visible depth.
- **Origin:** At the centre point between the prong tips. The fork points down, with the handle extending upward. Placed at floor level in Godot, the tips should touch the floor, which is easy to check.
- **Look:** 4 prongs, a wider head, and a narrow handle, using 6 basic shapes in total, all box-shaped. The whole fork is silver-grey with a simple flat-colour material, so it's easy to recognise.
- **Budget:** 100 triangles. Six box parts use about 72, which leaves a little room for adjustments while keeping the fork simple.

### Asset 2: Dessert dome

- **Role:** The goal.
  - *Planned placement (to be confirmed against the Assignment 2 project):* at the end of the level, on the final platform, as the finish point.
- **Size:** 1 m wide × 1 m deep × 0.75 m tall, including the base and top knob. That's 2 jellies wide and 1.5 jellies tall, so it stands out as the goal and looks like a rounded dessert cover.
- **Origin:** At the centre of the underside of the base, so the dome sits on the floor when placed at floor level in Godot.
- **Look:** Three low-poly shapes with solid colours: a flat cream-coloured cylinder for the base, a pale pink half-sphere for the cover, and a small red sphere for the top knob, like a cherry.
- **Budget:** 300 triangles. The cover, base, and cherry are all rounded, so they need more triangles than the fork's boxes. Low segment counts should keep them recognisable and leave some room for adjustments.

### Asset 3: Biscuit platform

- **Role:** Something for the jelly to jump onto.
  - *Planned for future levels, not implemented in Assignment 2:* stepping stones along the route, with forks over some of them and the dome on the final one.
- **Size:** 2 m wide × 1.5 m deep × 0.25 m thick. That's 4 jellies wide, 3 deep, and half a jelly thick, giving the jelly room to land and leaving space around the dome on the final platform.
- **Origin:** At the centre of the underside, consistent with the dome and easy to floor-check. The landing surface is 0.25 m above the origin.
- **Look:** A sandwich biscuit made of three flattened boxes: golden-brown biscuit layers on the top and bottom, with a thinner cream-coloured filling between them. Total thickness stays 0.25 m, all in solid colours.
- **Budget:** 60 triangles. Three boxes use about 36, which leaves a little room for adjustments while keeping it simple and low-poly.

### Summary

| Asset | Width (X) | Depth (Y) | Height (Z) | Origin | Shapes | Triangle budget |
|---|---|---|---|---|---|---|
| Fork | 0.5 m | 0.05 m | 1.5 m | Centre between prong tips (fork points down) | 6 boxes | 100 |
| Dessert dome | 1 m | 1 m | 0.75 m | Centre of base underside | 3 (cylinder, half-sphere, sphere) | 300 |
| Biscuit platform | 2 m | 1.5 m | 0.25 m | Centre of underside | 3 boxes | 60 |

### Predicted failure cases and checks

1. **Fork arrives sideways or upside down.** The fork might import into Godot sideways, or with its prongs pointing up.
   *Check:* In the 3D scene, make sure the handle extends upward and all four prong tips point down and touch the floor when the asset is placed at floor level.
2. **Dome arrives at the wrong size.** The dessert dome might import at the wrong size.
   *Check:* Compare its dimensions in Blender and its bounding-box size in Godot with the brief (1 m wide, 1 m deep, 0.75 m tall), and confirm its node scale in Godot is 1, 1, 1.
3. **Platform origin in the wrong place.** The biscuit platform's origin might end up in its centre instead of the underside, making it sink into the floor.
   *Check:* Place it at floor level in Godot and check from the side that its underside touches the floor and its top is 0.25 m above it.
4. **The MCP doesn't connect to Blender.**
   *Check:* Check the server status in Blender and ask Claude Code to read the scene with `get_scene_info`. If it fails, record the exact errors and steps tried. After about two hours of unsuccessful attempts, use the permitted script-route fallback.
5. **Claude exceeds a triangle budget**, especially with the dome's rounded shapes.
   *Check:* Check each asset's triangle count in Blender against its budget: 100 for the fork, 300 for the dome, and 60 for the platform.

### Open items

- Check the Assignment 2 project to confirm where the fork and dome currently appear. Record the result as a later dated revision rather than editing this text.
