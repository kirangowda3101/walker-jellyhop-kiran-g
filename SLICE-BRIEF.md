# SLICE-BRIEF — Jelly Hop: Fork From Above

Build brief for the playable slice, written 2026-10-02 **before any slice code**. It gathers what the approved design documents already decide, the facts of the accepted assets, and the build-only choices still open. **CONCEPT.md, STORYBOARD.md, CHARACTER-SHEET.md and CHANGE-BRIEF.md are the authority.** If this brief seems to disagree with them, follow them and report the mismatch. Exact wording of each rule lives there; this brief points to it.

## 1. How the slice is built

- **Tool and loop:** Claude Code in this repository, following Walker's **brief → build → playtest → inspect → revise** loop. Read this brief, CLAUDE.md and the four design documents, inspect the imported starter, and **propose a plan before editing**. After I approve the plan, the setup batch is built as one complete batch with one review at the end (see §10).
- **Film later:** the required explainer film is made after the slice, with the course-provided Brutalist `godot-gamedev` skill and the `walker` modifier, from this project's real code, scenes, assets, tests and history. Keep development evidence (plans, test receipts, screenshots) in `evidence/` so it can be shown.
- **Starting point:** the walker-jumpman starter (nikbearbrown/walker-jumpman), imported **unchanged** into `godot/` in its own commit (see SOURCES.md for the commit). Its movement model, session/state machine, camera, level format, HUD and test runner are the base. Change them where the design requires; do not delete starter tests to make a run pass. Where a starter test no longer applies to this game, replace it with an equivalent check for the new behavior and say what changed.
- **Engine:** the Godot version recorded in SOURCES.md by the setup script (the starter's tested engine is 4.7.2). Typed GDScript.
- **Physics rule (from the Assignment 1 brief):** do not change jump strength or remove collision checks simply to make a layout pass. Fit the plate spacing to the jump first; if tuning must change, say so and why.

## 2. Screen, scale, camera

- **Viewport:** 1280 × 720 base (CHARACTER-SHEET.md).
- **Side view, eye level** in all gameplay (STORYBOARD.md panels 2, 4, 5, 6).
- **Camera:** follows the jelly to the right and looks slightly ahead, so a fork's shadow never starts off screen because the camera trails (CHANGE-BRIEF.md failure #11). Glides back to the jelly on respawn; no snap (panel 6).
- **Camera shake:** short, camera only, **fork splat only**; never on a sauce splat; never moves the jelly or collision shapes (panel 5, failure #13).
- **Intro pan:** eye-level side-view pan from the dome back to the jelly; **always skippable** with any key; movement locked during the pan; the skip key never hops; play starts when the pan ends or is skipped (panel 1).

## 3. Accepted art (game-ready files in `art/game/`)

All files are transparent PNGs from Batch 2 (ASSET-LOG.md, Batch 2). Godot can only load files inside `godot/`, so **copy** them into `godot/assets/art/` and add a check that every copy is byte-identical to its `art/game/` original. Never edit the originals, `art/poses/`, or `art/reference/`.

| File | What | Proposed game size (from the Batch 2 review; adjustable) |
|------|------|----------------------------------------------------------|
| `ENV-ROOM.png` 1280 × 720 | background room | full screen; static unless parallax is approved |
| `ENV-TABLE.png` 1376 × 592 | table front; repeats seamlessly left-right | 200 px tall (scale 0.3378; repeats every 465 px), along the bottom; its top edge is the table top the plates sit on |
| `ENV-PLATE.png` 1023 × 152 | plate, edge-on; flat top surface | 200 px wide (scale 0.1986 of the drawn plate, 1007 px); about 27 px tall; landing surface about 5 px below its top |
| `ENV-SAUCE.png` 940 × 162 | spilled sauce puddle | 120 × 19 (scale 0.1299) in some gaps, on the table top |
| `ENV-FORK.png` 335 × 1267 | fork pointing down; handle runs off the top edge | head 70 px wide (scale 0.2194; 276 px long). The handle must reach above the screen: extend it (e.g., stretch or repeat the straight handle section); how is a build choice |
| `ENV-DOME.png` 750 × 536 | glass dome, see-through interior | 180 × 128 (scale 0.2452), at the far end; the jelly must stay visible inside it |
| `CHAR-<POSE>.png` ×12, 1024 × 1024 each | jelly poses, facing right | scale 0.1060 (the resting cube = 64 × 64). Every pose's bottom edge is at y 811–812 of its canvas, so anchor all frames at the canvas's **bottom center (512, 812)** |

- **Shadow (ENV-SHADOW):** code-drawn: a soft dark ellipse on the plate that grows during the shadow phase (CHANGE-BRIEF.md).
- **Filtering:** the art is smooth, not pixel art. Downscaling a 1024 px pose to 64 px needs mipmaps or pre-scaled copies to avoid shimmer; check readability at 1280 × 720, 100% zoom (failure #2).
- **Flip:** drawn facing right, flipped at runtime; keeps facing the way it last moved; highlight stays top-center (CHARACTER-SHEET.md).
- **Minor known marks** (documented, not to be "fixed" in engine): dome's ragged inner edge, mint tint on the dome's knob and rim, and the pose marks listed in ASSET-LOG.md.

## 4. Jelly states, poses, collision (CHARACTER-SHEET.md)

| State | Pose file | Box |
|-------|-----------|-----|
| standing still | CHAR-IDLE | standing 52 × 58 |
| no input for a few seconds | CHAR-BORED | low 52 × 44 |
| moving on a plate | CHAR-SCOOT-A / CHAR-SCOOT-B loop | standing |
| hop anticipation | CHAR-ANTIC | low |
| rising | CHAR-RISE | standing |
| falling | CHAR-FALL | standing |
| landing | CHAR-LAND | low |
| a shadow growing over its plate | CHAR-WORRY (overrides bored) | standing |
| fork or sauce failure | CHAR-SPLAT | hits off |
| respawn | CHAR-RESPAWN | hits off |
| reached the dome | CHAR-CELEBRATE | standing |

- Boxes are bottom-aligned and centered; the bottom is flush with the art.
- **Hits off during splat and re-form**; input locked through both; presses or holds during the lock are ignored; the next hop needs a **fresh** jump press (panels 5–6; failure #7).

## 5. Level and rules

- **About six plates** in a short scrolling stretch, with sauce in some gaps; landing short in sauce is a failure. Plate spacing and fork timing vary to create new timing challenges (CONCEPT.md).
- **Forks:** one per plate that has one; each follows a **fixed, learnable cycle**: shadow grows → strike → safe window.
- **Respawn:** on the last safe plate. That plate's fork cycle **restarts at its safe window, which begins when control returns**; other forks keep their rhythm (panel 6, failure #12).
- **End:** reaching the dome shows the relief pose, "SAFE!" and "press any key to play again". Any key restarts on the first plate with **no intro pan**; every fork cycle and checkpoint resets; music restarts; the restart key never hops (panel 7).
- **Cups:** not in this slice (not in the storyboard; still unresolved in the design).

## 6. Controls (decided 2026-10-02)

- Move: **← / →** or **A / D**
- Jump: **Space**, **↑** or **W**
- Pause: **Esc** (resume with Esc)
- Mute all: **M**; mute music only: **N** (toggles)
- Skip intro / restart at the end: any key, which never also hops

## 7. Sound: silent placeholders now, real audio later

No audio files exist yet. Build the full sound and music behavior now with **silent placeholders**, so that adding audio later changes no game logic.

- **One sound-event entry point** (for example an autoload) with a call per approved event ID: `SFX-HOP`, `SFX-LAND`, `SFX-WARN`, `SFX-SPLAT-FORK`, `SFX-SPLAT-SAUCE`, `SFX-WIN`. Each is called **only** from the code that already represents its event, at the state change listed in CHANGE-BRIEF.md's event-to-sound map, including its double-trigger rule. Sounds never decide game state.
- **Placeholder mode:** play nothing, but **record every call** (event ID, physics frame, game state) so tests can count triggers. Later, mapping an ID to an audio file is the only change.
- **SFX-WARN** only when the fork enters its shadow phase **with its shadow on screen**; a shadow that starts off screen stays silent even after it scrolls in (failure #8).
- **No scoot sound, no respawn sound.**
- **Music (MUS-LOOP) placeholder:** a music controller with the states in CHANGE-BRIEF.md's music behavior (intro quieter → normal; quieter and muffled while **an on-screen** shadow grows; short dip on either splat, back on respawn unless a shadow still grows; very quiet and muffled on pause; fade out at the dome; quiet at the end prompt; restart from the top on replay). Drive real audio buses now (Master, Music, SFX), with volume and a low-pass for "muffled", and **log each change** of target volume or muffle so overlap behavior can be checked (failure #9).
- **Mute:** M mutes Master; N mutes Music only. Muting never changes game state.

## 8. Automated checks (required: at least one; these cover the predicted failures)

Use the starter's headless test runner. Record each command and its result in `evidence/`.

1. Trigger counts per event from scripted input: rapid hops, a held jump, a landing, a fork splat, a sauce splat, a win: each sound fires **once per event** (failure #5).
2. The skip key and the restart key produce **zero** SFX-HOP and no movement (failure #6).
3. A jump held through a splat produces **zero** SFX-HOP until a fresh press (failure #7).
4. A fork whose shadow phase starts off screen produces **no** SFX-WARN and no music dip (failure #8).
5. After a respawn, the checkpoint plate's fork is in its safe window when control returns (failure #12).
6. A sauce splat causes **no** camera shake; a fork splat does (failure #13).
7. Overlapping on-screen shadows: the music log shows no flicker and no stuck dip (failure #9).

Keep the starter's own checks passing or replace them with equivalents, explained.

## 9. Open values: build defaults to tune in playtesting

Pick sensible defaults, list them in one place (one tuning file), and mark them as defaults: fork cycle timings per plate, bored delay, splat and re-form durations, pan length, plate spacing, look-ahead distance, shake size, music dip and muffle amounts. Also open (keep the simplest version and flag it for review): room parallax, any change to the room's brightness.

## 10. End of the setup batch: what I review

- The game runs from the Godot editor and from the command line.
- Screenshots at 1280 × 720 of each storyboard moment (intro pan, hop, warning, safe landing, splat, respawn, dome), saved in `evidence/`.
- All automated checks run, with commands and results.
- A short list of every default chosen (§9) and anything that differs from the design documents.
- **No commit until I review.** After my review: one commit, pushed and verified (CLAUDE.md).
- Not in this batch: generated audio, TEST-REPORT.md's human playtests, README, the film.
