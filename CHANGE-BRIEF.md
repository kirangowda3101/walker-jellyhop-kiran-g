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
