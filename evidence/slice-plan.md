# Setup batch plan — Jelly Hop slice (SLICE-BRIEF.md §10)

## Context
The walker-jumpman starter is in `godot/` unchanged (commit `d7f0c97`). This batch turns it into the playable Jelly Hop slice described by the design documents and SLICE-BRIEF.md. That means six plates, forks, sauce, the dome, the 12 poses, the intro pan, respawn and restart, plus silent sound and music placeholders that log their calls. The batch ends with screenshots, automated checks and a list of defaults for your one review. No commit happens until you have reviewed it.

Your decisions from this session:
- **Units:** the world becomes 1280×720 and the starter's movement values are multiplied by 2. The jump looks and feels the same on screen.
- **Fork:** the fork gets bigger so its tines span the plate's full width (head about 200 px). There is no standing position on a forked plate outside the tines' hit zone, and the hit zone equals the visible tines. (Revised 2026-10-03, after your review of the first draft.)
- **Traceability:** the approved plan is saved as `evidence/slice-plan.md` in step 0.

## 1. What the starter is (inspected)
- **Run:** `walker-jumpman.command` runs `/Applications/Godot.app/Contents/MacOS/Godot --path godot`. There is no README inside `godot/`. The main scene is `game/main.tscn`, a single Node2D that runs `game/session.gd`. Everything else is built in code.
- **Display:** a 640×360 viewport stretched to a 1280×720 window (`canvas_items`), GL Compatibility renderer, 60 physics ticks per second.
- **Player:** `features/player/player.gd` is a CharacterBody2D with an 18×28 box. Values come from `features/player/tuning.gd`: speed 160, accel 1280, decel 1920, jump −320, gravity 960, terminal 480, coyote 6 ticks, buffer 6 ticks. It reads its input from test fields (`test_control`, `test_axis`, `test_jump_pressed/held`) or from `Input`. A fresh press is enforced through `require_jump_release` (a held jump never re-jumps). It is drawn with `_draw` rectangles.
- **Session:** `session.gd` has the states MENU, PLAYING, PAUSED, DYING, COMPLETE. It loads `levels/first_steps.json` (solids, hazards, finish, spawn, fall_y) and builds StaticBody2D and Area2D nodes from it. Hazards use real overlap (`overlaps_body`). `contact_settle_ticks` blocks a phantom second death after a teleport. Retry comes 0.55 s after a death. Losing window focus pauses the game.
- **Camera:** a Camera2D at `player.x + 100`, clamped to the level. There is no smoothing and no shake.
- **HUD:** `ui/hud.gd` is a Control on a CanvasLayer, drawn with `_draw` and the helpers `text_at` and `centered`.
- **Input:** set up in code (`_setup_input`): A/D or arrows move, Space jumps, Esc or P pauses, R retries, Enter confirms, M opens the menu.
- **Tests:** SceneTree scripts that create `session.gd` directly. Each check is printed as a JSON line, a report is written to `evidence/`, and the script exits with 1 if any check fails.
  - `test_game.gd`: 26 mechanics checks (speed cap, stop, wall, jump height 53.3, no double jump, coyote and buffer at 5/6/7 ticks, low ceiling, pause, focus loss, spike collision, duplicate death, respawn, 20 retries, fall boundary, a full route run by `route_driver.gd`, replay).
  - `test_keyboard.gd`: 9 checks using synthetic key events.
  - `capture_game.gd`: 4 screenshots. It renders, so it needs a window.

### Exact commands for the existing tests
```
G=/Applications/Godot.app/Contents/MacOS/Godot
$G --headless --path godot --import                                # builds the .godot import cache (first run)
$G --headless --path godot --script res://tests/test_game.gd       # mechanics; exit 0 = pass; writes evidence/mechanics-<unix>.json
$G --headless --path godot --script res://tests/test_keyboard.gd   # keyboard; exit 0 = pass; writes evidence/keyboard-<unix>.json
$G --path godot --script res://tests/capture_game.gd               # screenshots (opens a window, not headless) → evidence/screens/
```
`--headless` runs without a window or GPU. `--path godot` picks the project. `--script` runs a test script as the main loop instead of the game. Check the result with `echo $?`. I have not run these yet, because plan mode allows read-only actions only. Step 0 runs them as the baseline.

## 2. What I keep, change, add

**Kept:**
- The CharacterBody2D movement model, including the coyote and buffer logic, `require_jump_release`, and the test-control fields.
- The session state-machine pattern and `contact_settle_ticks`.
- Real Area2D overlap for hazards.
- Pause on focus loss.
- The HUD's `_draw` helpers.
- The SceneTree test-runner pattern (`check()`, JSON report, exit code).
- The route-driver idea: the route uses input only and never edits positions.

**Changed:**
| File | Change |
|---|---|
| `godot/project.godot` | Viewport 1280×720 with no override, name "Jelly Hop: Fork From Above", dark clear color, physics layers kept |
| `features/player/tuning.gd` | Starter values ×2 for the unit change (speed 320, accel 2560, decel 3840, jump −640, gravity 1920, terminal 960). Ticks unchanged. A comment states it is a unit conversion, not retuning |
| `features/player/player.gd` | Box 52×58 standing or 52×44 low, bottom-aligned. Pose selection and the Sprite2D jelly replace `_draw`. Landing detection. SFX-HOP and SFX-LAND calls at the existing jump and landing points. `facing` drives `flip_h` |
| `game/session.gd` | States INTRO, PLAYING, PAUSED, SPLAT, REFORM, WON (replacing MENU and DYING, COMPLETE becomes WON). Builds the table level, forks, sauce, dome and camera. Handles checkpoints, any-key skip and restart, mute keys |
| `ui/hud.gd` | Title and "any key skips the intro", pause card, "SAFE!" and "press any key to play again", mute indicators. Rescaled to 1280 |
| `tests/test_game.gd`, `test_keyboard.gd`, `route_driver.gd`, `capture_game.gd` | Ported to the new level and keys. Every replaced check is listed with its equivalent (table below) |
| `levels/first_steps.json` | Scaled ×2 in step 2 to prove the unit conversion, then removed once the table level replaces it (git keeps the original) |

**New:**
| File / node | Purpose |
|---|---|
| `tools/copy_game_art.sh` | Copies `art/game/*.png` to `godot/assets/art/` and verifies every copy with `cmp` and SHA-256 (a stop with a message if any differs). Writes `evidence/slice-art-copy.txt`. Uses `set -Eeuo pipefail` and an ERR trap |
| `godot/assets/art/*.png` (+ Godot `.import` files) | The 18 copies. Poses, fork, dome, plate and sauce import with mipmaps. Nodes use `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` |
| `game/slice_tuning.gd` | **The one tuning file for §9.** Every value is marked `## DEFAULT — tune in playtesting`. It holds plate gaps, sauce gaps, fork cycles, durations, camera, shake and music levels |
| `features/fork/fork.gd` | Node2D: fork sprite plus a stretched handle section going off the top of the screen, a code-drawn shadow ellipse, and a tines Area2D that is active only while the fork is down. Its cycle is SAFE → SHADOW → STRIKE (down, hold, up) → SAFE, driven by physics ticks so it is deterministic. Also `hold_raised()` and `restart_at_safe()` for respawn |
| `audio/sound_events.gd` | The one SFX entry point, a child of the session so every test starts with a clean log. `play(id)` accepts only the six approved IDs. Placeholder mode plays nothing and appends `{id, physics_frame, state}` to `log` |
| `audio/music_controller.gd` | Makes sure the Master, Music and SFX buses exist, with a low-pass filter on Music. It takes the game state plus the number of on-screen shadows that are growing and picks one target: end-quiet > win-fade > pause > splat-dip > warning > intro > normal. It tweens bus volume and cutoff, logs only when the target changes, and plays a silent AudioStreamPlayer on Music that is restarted from the top on replay. M toggles the Master mute and N toggles the Music mute |
| `tests/test_slice.gd` | The seven §8 checks, plus checks for poses and boxes, art copies and mute. The **fork-edge-band** check uses real physics on every forked plate with the fork held down. It moves the jelly in 1 px steps across every x where the plate holds it up, with both the standing and the low box, and **asserts the safe band is 0 px**. Two further assertions: the hit shape is no wider than the measured visible tines, and it is at least as wide as the plate's landing surface |
| `tests/capture_slice.gd` | Seven 1280×720 screenshots driven by scripted input → `evidence/slice-screens/` |
| `tools/run_slice_checks.sh` | Runs the art check, import, the three headless suites and the capture. Each log goes to `evidence/slice-checks/` and is printed. It stops on the first failure |
| `evidence/slice-batch-review.md` | Commands, results, defaults, differences, and what still needs a human |
| `FRICTIONAL.md` | A new dated entry only, drafted for your review |

**Scene tree (built in code, as in the starter):**
```
Session (Node2D)
├─ RoomLayer (CanvasLayer -10) → Room (Sprite2D, static)
├─ Table ×N (Sprite2D, every 465 px)
├─ Plate ×6 (StaticBody2D: sprite plus a box at the landing surface)
├─ Sauce ×3 (Area2D on the table top)
├─ Fork ×5 (fork.gd; plate 1 has none)
├─ Player (CharacterBody2D → Sprite2D jelly, CollisionShape2D)
├─ Dome (Sprite2D drawn above the player, plus a goal Area2D)
├─ Camera2D   ├─ SoundEvents   ├─ MusicController
└─ HudLayer (CanvasLayer) → Hud
```
The table top is at y 520, since the table strip is 200 px tall. The plate landing surface is about y 498. Bare table between plates is safe floor.

## 3. Defaults for §9 (all in `slice_tuning.gd`, all marked DEFAULT)
| Value | Default |
|---|---|
| Plate gaps (edge to edge) | 120, 140, 150, 160, 170 px. The jump covers ~213 px in the air at full speed. The route test proves every gap can be crossed |
| Sauce | in gaps 2, 4 and 5 |
| Fork cycles (shadow / safe s, offset s) | P1 has no fork. P2 1.6/2.2/0.0 · P3 1.4/1.9/1.0 · P4 1.3/1.6/0.4 · P5 1.2/1.4/1.6 · P6 1.0/1.2/0.8. The strike is down 0.12 + hold 0.30 + up 0.28 s. No fork is in its shadow phase at t = 0 |
| Fork size | **your decision, not a default:** visible tine span ≥ the plate's landing-surface width (head about 200 px, scale about 0.63, fork about 794 px tall). The scale is computed from the tines' measured span in ENV-FORK.png, not guessed |
| Bored delay | 4.0 s |
| Splat / re-form | 0.6 s / 0.7 s |
| Intro pan | 4.0 s, ease in-out, dome → start |
| Look-ahead | 240 px to the right, camera smoothing speed 4 (this gives the glide on respawn) |
| Shake | 8 px, 0.25 s, decaying, `Camera2D.offset` only |
| Music (dB / low-pass) | normal 0 / off · intro −8 · warning −9 / 900 Hz · splat dip −12 · pause −20 / 500 Hz · win fade to −40 over 1.5 s · end quiet −40 · changes ramp over 0.25 s |
| Pose timing | ANTIC 4 ticks, LAND 8 ticks, scoot frame 0.12 s, end-prompt delay 1.0 s |
| Room | static (no parallax), brightness unchanged. Flagged for review |

## 4. Differences from the design or starter (listed for your review)
1. ×2 unit conversion of the movement values (your choice). The feel is unchanged.
2. The fork is much larger than the Batch 2 proposal of a 70 px head (your choice): its tines span the full plate. The hit zone is a shape matched to the visible tines in the down position. It is measured from the art's alpha, so it is no wider than the tines you see. Its width is at least the plate's landing-surface width, and it reaches low enough to overlap the 44 px low box. Any position where the jelly is held up by the plate, including hanging up to 26 px over an edge, overlaps the tines. Safe band: 0 px. The other side of this decision: a raised fork about 800 px tall dominates the frame above the next plate. The screenshots will show it.
3. Starter keys R (retry), Enter, P and M-menu are removed, and so is the MENU card. The decided controls replace them, with the intro pan as the opening.
4. ANTIC is visual only: shown for the first 4 ticks of takeoff, with no input delay, so the jump timing is unchanged.
5. M and N only toggle mute. They never skip the intro or restart the game (Muting never changes game state). Every other key skips or restarts.
6. SFX-LAND also fires on a landing on the bare table. The map says "on a plate", but there is no other landing sound for the table.
7. During the intro the forks are frozen at their t = 0 pose. Their cycles start when play starts, so every run is identical. No WARN fires during the intro.
8. On a win, the jelly slides to the dome's center in 0.3 s so it is visibly inside the glass.
9. The starter's retry and timer HUD line is removed (it is not in the design).
10. The buses are created in code rather than in a `.tres` file, so they also exist under `--script` test runs.

## 5. Order of internal steps (each: a diff, then a check run, logged)
0. **Plan and baseline:** save this approved plan as `evidence/slice-plan.md` (the content of the plan file, unchanged). Then run the starter's `--import`, `test_game` and `test_keyboard`, unchanged, and record the results.
1. **Art:** `copy_game_art.sh`, then import. Set mipmaps in the `.import` files and re-import. Check: byte-identical copies (run again after the import, to show that importing leaves the PNGs untouched).
2. **Units:** viewport 1280×720, tuning ×2, `first_steps.json` coordinates ×2, test constants ×2 (for example rise 53.3 → 106.7). Check: the full starter suite passes, which shows the conversion keeps behavior the same.
3. **Table level:** `slice_tuning.gd`, room, table, plates, sauce areas, dome goal, and 52×58 / 52×44 boxes. Port the mechanics checks and the route driver to the plates. Check: test_game passes, including the route to the dome.
4. **Jelly:** sprite anchored at (512, 812) at scale 0.1060, pose selection per §4, flip, worried overrides bored. Check: a pose-and-box table test.
5. **Forks and failure:** measure the tine span from the fork art, then set the fork scale from it. Fork cycle, a shadow covering the full plate, the tines area, sauce splat, SPLAT and REFORM with hits off, checkpoint, `restart_at_safe` when control returns, fresh-press rule. Checks §8 #3 and #5, the fork-edge-band check (0 px), plus the duplicate-splat and twenty-retries equivalents.
6. **Camera and flow:** look-ahead, glide, shake on a fork splat only, intro pan with any-key skip, win and any-key restart (no pan, everything reset). Checks §8 #2 and #6, plus the keyboard suite ported.
7. **Audio placeholders:** SoundEvents, MusicController, buses, mute. Checks §8 #1, #4 and #7, plus "mute changes no state".
8. **HUD:** the text for each state. Check: all suites again.
9. **Screenshots:** `capture_slice.gd` (windowed): intro pan, hop, warning, safe landing, splat, respawn, dome. I check each PNG is 1280×720 and look at it.
10. **Wrap-up:** `run_slice_checks.sh` end to end, `slice-batch-review.md`, a FRICTIONAL draft entry. Then stop for your review. No staging or commit before that.

### Starter checks → equivalents (explained in the review file)
- jump rise 53.3 → 106.7
- speed cap 160 → 320
- left wall x 10 → the level's left bound
- ledge fixtures for coyote and buffer → the plate 1 edge
- spike collision → sauce and fork collision
- respawn at the spawn point → respawn on the checkpoint plate
- twenty retries ≤ 60 ticks → ≤ splat + re-form + 2 ticks
- Enter start, R retry, P/M menu → any-key skip and restart, Esc pause and resume
- complete-real-route → route to the dome with 0 splats

## 6. Verification at the end of the batch
- `tools/run_slice_checks.sh`: art check, `--import`, `test_game`, `test_keyboard` and `test_slice` headless (each exits 0), then `capture_slice` windowed. Logs and JSON reports go to `evidence/`.
- The game runs from the command line with `./walker-jumpman.command` (or `$G --path godot`); I confirm it launches with no errors in the log. You confirm it **from the editor**: open `godot/project.godot` in Godot and press F5. I can't press the editor's Play button for you.

## 7. What still needs a human playtest or listening (not covered by automated checks)
- **Feel and difficulty:** jump feel at the new scale, whether every gap is fair, fork timings, how the full-plate fork reads and feels (#2), the bored delay, the pan length, the ANTIC read, splat and re-form length.
- **Failure #2** (face readable at 64 px, 100% zoom) and **#3** (jelly visible on plate, fork and table). The screenshots help, but judging them takes your eyes.
- **#4:** room brightness and busyness against the shadows and sauce (muted screenshot plus play).
- **#11:** look-ahead on every plate. The automated check covers shadow-on-screen; whether it feels right is a playtest question.
- **#13:** the shake feel. Automated checks prove sauce gives none and fork gives some.
- **#14:** Scoot A's 2 px box near strikes. **#15:** a full muted playtest.
- **All listening** (#8 and #9 by ear, #10 loop seam) waits for the audio batch. This batch only proves the call and log logic, with silent placeholders.
- None of the scripted-input runs counts as a human playtest, and the review file says so.
