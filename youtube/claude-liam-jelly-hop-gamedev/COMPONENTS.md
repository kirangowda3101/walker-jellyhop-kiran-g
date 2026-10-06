# COMPONENTS — what the film explains, and what it leaves out

`gamedev-evidence.json` hashes every file under `godot/` (68 files; `.godot/` and `.uid` are excluded by the checker): 66 in components, 2 excluded with reasons. `./art godot-gamedev --check` passes. It verifies hashes, line ranges and associations, not whether the explanations are right.

| Component | What the film says about it | Beats | Files |
|---|---|---|---|
| `jelly-poses` | 12 generated pose textures loaded by name (`player.gd:54`); `choose_pose()` (`player.gd:147–163`) ranks session override → airborne → landing → scoot → worry → bored → idle, and the first true test wins | B03, B04, B05 (code), B06 (result) | `features/player/player.gd`, `assets/art/CHAR-*.png` + `.import` |
| `fork-warning` | each fork runs a fixed cycle; `advance()` reports `"shadow"` and `"down"`; `_advance_forks()` (`session.gd:292–304`; lines 294–301 on screen) plays SFX-WARN only on `"down"`, for the fork over the jelly's current or next plate, if on screen — changed in `23ae39c` after Kiran's audition notes | B07 (code), B08 (result) | `features/fork/fork.gd`, `game/session.gd`, `audio/sound_events.gd`, `assets/art/ENV-FORK.png`, `assets/audio/SFX-WARN.ogg` (+ `.import`) |
| `sound-events` | one entry point (`sound_events.gd`), each event called only from the code that represents it, every call recorded with its tick; music bus with its own controller | B08, B10, BVDT | `audio/sound_events.gd`, `audio/music_controller.gd`, `assets/audio/*.ogg` + `.import` |
| `level` | six plates, sauce in three gaps, the dome, the intro pan, HUD, project settings | B02, BVDT | `project.godot`, `game/main.tscn`, `game/session.gd`, `game/slice_tuning.gd`, `ui/hud.gd`, `assets/art/ENV-{PLATE,SAUCE,DOME,ROOM,TABLE}.png` + `.import` |
| `tests` | headless suites (25 / 12 / 61 checks), the scripted route planner the capture driver reuses, screenshot and audio-trace tools; scripted input and fixtures prove logic, not feel | B10 | `tests/*.gd` |

## Excluded

- `.gitignore`: ignores `.godot/`; it has no runtime role.
- `features/player/tuning.gd`: the movement constants from the walker-jumpman starter, unchanged. This 5-minute film does not explain them; the starter is credited in SOURCES.md.

## Known simplifications in the narration

- B05 says "a crouch for the first few ticks". The code shows ANTIC while `0 <= hop_ticks <= T.ANTIC_TICKS` (4), which is 5 ticks counting tick 0.
- B02 says a hit "costs about a second and a quarter": `SPLAT_TIME` 0.6 s + `REFORM_TIME` 0.7 s = 1.3 s before control returns.
- The film doesn't explain how the fork's hit shape is traced from the tine pixels (`fork.gd:62–110`). It is listed under `fork-warning` because the capture's first attempt depended on it (CAPTURE.md).
