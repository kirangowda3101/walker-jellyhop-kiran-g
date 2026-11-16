@AGENTS.md

# CLAUDE.md — Assignment 7 (animation)

## Project context

- **Engine:** Godot 4.7.2.stable.official.ed1daf0bf (README.md line 13; CHANGE-BRIEF.md line 5; `evidence/a7-baseline/import.txt` line 1). `godot/project.godot` line 15: `config/features=PackedStringArray("4.7", "GL Compatibility")`.
- **Renderer:** Compatibility: `renderer/rendering_method="gl_compatibility"` and `.mobile` the same (`godot/project.godot` lines 32–33). Viewport 1280 × 720, stretch `canvas_items` (lines 19–21).
- **Clip `scoot`** (looping): Sprite2D cell route. `FacingPivot/Scoot/ScootSprite` (Sprite2D, `hframes = 2`, `vframes = 1`) shows `godot/assets/art/CHAR-SCOOT-SHEET.png`, packed from CHAR-SCOOT-A/B by `godot/tools/make_scoot_sheet.gd`. One discrete track on `:frame`. Resource `godot/animations/scoot.tres` (CHANGE-BRIEF.md lines 11, 25, 27, 45, 64, 68).
- **Clip `land`** (one-shot): native cutout rig. Two Sprite2D slices of `CHAR-IDLE.png`: `FacingPivot/LandRig/LowerPivot/LowerSprite` and `FacingPivot/LandRig/UpperPivot/UpperSprite`. Three continuous tracks: `LowerPivot:scale`, `UpperPivot:position`, `UpperPivot:scale`. Resource `godot/animations/land.tres` (brief lines 12, 41–49, 64, 69–71).
- **Both clips play on one `AnimationPlayer`**, a sibling of `FacingPivot` in `godot/features/player/player_visuals.tscn` (root `PlayerVisuals`, Node2D), with `root_node = ".."`, one embedded AnimationLibrary, and `callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS` (brief lines 64, 98).
- **Not built yet** (glob, 2026-11-16): `godot/animations/`, `player_visuals.tscn`, the sheet PNG, `make_scoot_sheet.gd` and both A7 previews. No file under `godot/` mentions `AnimationPlayer`, `AnimationLibrary`, `AnimationTree`, `AnimatedSprite` or `SpriteFrames`.
- **The player's state machine is `godot/features/player/player.gd`:**
  - `choose_pose()` (lines 147–163): override → airborne ANTIC/RISE/FALL → LAND while `land_ticks > 0` → SCOOT-A/B when `absf(velocity.x) > 8.0` → WORRY → BORED → IDLE.
  - `_update_pose()` (lines 165–171) sets `sprite.texture` and `sprite.flip_h`, and swaps the box: LOW 52 × 44 for LAND and BORED, else STANDING 52 × 58 (lines 11–13).
  - The original sprite is built in code in `_ready()` (lines 53–61): textures `CHAR-<POSE>.png`, `centered = false`, `offset = -T.JELLY_ANCHOR` (512, 812), scale `T.JELLY_SCALE` 0.106 (`godot/game/slice_tuning.gd` lines 14–15), `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`. The player has no `.tscn`.
  - Landing: `just_landed` is cleared at line 95 and set with `land_ticks = T.LAND_TICKS` (8; slice_tuning line 57) at lines 136–138; it counts down at lines 140–141. `tick` advances only while `enabled` (lines 97–100).
  - Scoot phase: `(tick / T.ticks(T.SCOOT_FRAME)) % 2` (line 158). `SCOOT_FRAME` is 0.12 s (slice_tuning line 58) and `ticks()` is `int(round(s * 60))` (lines 116–117): 7 ticks per cell, 14 per cycle.
  - Jump: buffer and coyote are 6 ticks (`godot/features/player/tuning.gd` lines 11–12). Eligibility (player.gd line 124) is checked before `move_and_slide()` and floor detection (lines 134–137).
  - The session writes `worried` and `override_pose` (SPLAT/RESPAWN/CELEBRATE) (`godot/game/session.gd` lines 391–392), and also `enabled`, `velocity`, `position` and `reset_at()` (lines 209, 239–240, 248–252, 267–268, 280–282, 345, 354).
- **Tick order:** player uses the default physics priority 0 (player.gd sets none); session 10 (session.gd line 40); effects driver 20 (`godot/effects/effects_driver.gd` line 12).
- **Scenes the clips appear in:**
  - The game: `res://game/main.tscn` (project.godot line 14) runs `session.gd`, which builds the level in code (`_build_level()`, session.gd line 87) and the player with `Player.new()` + `add_child` (lines 48–50). `player.gd` will host `player_visuals.tscn`; the original sprite stays outside it (brief lines 73, 102).
  - Fixtures: `res://previews/land_preview.tscn` (LAND, starting plate, real table and room) and `res://previews/scoot_preview.tscn`. Both reuse the live visual scene (brief line 115). Existing previews in `godot/previews/` are A6 particle fixtures.
- **How tests load the game:** every test `extends SceneTree`. They use `Game.new()`, `test_mode = true` and `root.add_child(game)` (`godot/tests/test_slice.gd` lines 29–31). Input comes from `player.test_control`/`test_axis`/`test_jump_*` (player.gd lines 39–42) or real events via `Input.parse_input_event` (test_slice.gd line 126).
- **Tests that read the original sprite:** `p.textures["IDLE"]` (test_slice.gd line 75), `p.sprite.flip_h` (test_slice.gd line 100; `godot/tests/capture_poses.gd` line 64). Pose sequence `["ANTIC","RISE","FALL","LAND","IDLE"]` (test_slice.gd line 109).
- **The wrapper (`scripts/run-test.sh`, never edited):** `scripts/run-test.sh <test-file.gd> <fps|realtime> [timeout-seconds]` (line 2).
  - It runs `godot --headless [--fixed-fps <fps>] --path godot --script res://tests/<file>` under `timeout ${3:-120}` (line 11).
  - `realtime` drops `--fixed-fps` (lines 5–6). The log goes to `logs/<name>_<fps>fps.log` or `logs/<name>_realtime.log` (lines 8, 10).
  - It exits 1 if the log contains `SHADER ERROR`, `SCRIPT ERROR` or `Failed loading resource` (line 13). Godot's own exit 0 alone is not a pass.
- **Test commands** (repository root). These are the 14 counted A7 baseline runs, all exit 0 (`evidence/a7-baseline/baseline-14.txt`); summary `print` lines are in each test file:
  ```sh
  scripts/run-test.sh test_game.gd 60              # WALKER TESTS: 25 / 0          (test_game.gd line 173)
  scripts/run-test.sh test_slice.gd 60             # SLICE TESTS: 61 / 0           (test_slice.gd line 60)
  scripts/run-test.sh test_keyboard.gd 60          # KEYBOARD TESTS: 12 / 0        (test_keyboard.gd line 99)
  scripts/run-test.sh test_a3_assets.gd 60         # A3 ASSET CHECKS: 36 / 0       (test_a3_assets.gd line 125)
  scripts/run-test.sh test_fork_warning.gd 30      # FORK WARNING TESTS: 29 / 0; also 60 and 144 (line 167)
  scripts/run-test.sh test_materials.gd 30         # MATERIAL CHECKS: 108 / 0; also 60 and 144 (line 456)
  scripts/run-test.sh test_land_puff_config.gd 60  # LAND PUFF CONFIG: 51 / 0      (line 167)
  scripts/run-test.sh test_land_puff_state.gd 60   # LAND PUFF STATE TESTS: 24 / 0 (line 288)
  scripts/run-test.sh test_dome_glints_config.gd 60 # DOME GLINTS CONFIG: 45 / 0   (line 170)
  scripts/run-test.sh test_dome_glints_state.gd 60 # DOME GLINTS STATE TESTS: 27 / 0 (line 257)
  scripts/run-test.sh cost_effects.gd 60 300       # supplemental, not counted (README.md line 269)
  scripts/run-test.sh check_lifecycle_peak.gd 60   # supplemental, not counted (README.md line 270)
  scripts/run-test.sh <test>.gd realtime 300       # real clock, no --fixed-fps; 3rd arg = timeout s
  ```
  The brief names no A7 test files. Its state and timing checks run at 30, 60 and 144 render fps (brief line 110).
- **Headless:** `--fixed-fps N` gives N frames per game second with physics at 60 ticks/s (`logs/probe_headless_{30,60,144}fps.log`, 2026-10-27, as recorded in the A6 CLAUDE.md). Existing suites print `ObjectDB instances were leaked` and `resources still in use` at exit; these lines are not SCRIPT/SHADER ERRORs.

## Current change

@CHANGE-BRIEF.md

## Ownership

- Every file in `godot/shaders/` is hand-written by Kiran, except `standard_generated.gdshader` and `particles_generated.gdshader` (both generated by Godot and saved by Kiran exactly as generated). No agent creates, edits, reformats or "fixes" any file there. If a shader has an error, report the error text and the line, and stop.
- Clips live as saved resources in `godot/animations/` (`scoot.tres`, `land.tres`) or in the scene that owns them (`player_visuals.tscn`). Keys, tracks, length, step and loop mode are authored in those files. They are never built, keyed or modified in code at runtime: no `Animation.new()`, `track_insert_key()` or `add_animation_library()` in game or preview scripts. Read-only checks may load and inspect them.
- Static rig and sprite settings (texture, `hframes`, `region_rect`, `offset`, scale, filter, rest positions) live in `player_visuals.tscn`, not in code.
- `CHAR-SCOOT-SHEET.png` is produced only by `godot/tools/make_scoot_sheet.gd`, which Kiran reviews and runs (brief line 25). Source PNGs never change (AGENTS.md).
- A6 effect settings stay in `godot/effects/*.tscn`. `effects_driver.gd` stays as it is.

## One authority

Exactly one writer per animated node and property. Never add a second writer to a node that already has one: no script assignment, Tween, second AnimationPlayer, AnimationTree, method track or `RESET` clip on these targets (brief lines 49–51, 73, 83, 141).

| Node and property | The only writer |
| --- | --- |
| `ScootSprite.frame` | The AnimationPlayer (`scoot`) |
| `LowerPivot.scale`, `UpperPivot.position`, `UpperPivot.scale` | The AnimationPlayer (`land`) |
| `FacingPivot.transform` (mirror ±1 on X) | `player.gd` |
| `Scoot.visible`, `LandRig.visible` | `player.gd` |
| AnimationPlayer playback (`play`, `seek`, `stop`) | `player.gd` in the game; in a preview, its own preview script, and nothing else there |
| Original pose sprite: `texture`, `flip_h`, visibility | `player.gd` |
| Collision box (`set_box`) | `player.gd`, unchanged |
| `LowerPivot.position`, sprite offsets and regions | Nobody at runtime; the saved scene value |

Presentation reads gameplay state (`pose`, `land_ticks`, `just_landed`, `tick`, `velocity`, `facing`) and never writes it.

## Godot 4 names

- Use Godot 4.7.2 names: `AnimationPlayer`, `AnimationMixer`, `AnimationLibrary`, `Animation`, `Sprite2D` (`hframes`, `vframes`, `frame`, `region_enabled`, `region_rect`), `Node2D`.
- Loop: `Animation.loop_mode` with `Animation.LOOP_NONE` / `LOOP_LINEAR`, never a boolean `loop`. Speed: `speed_scale`, never `playback_speed`. Callback: `callback_mode_process` with `AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS`, never `playback_process_mode`.
- Update modes: `Animation.UPDATE_DISCRETE` / `UPDATE_CONTINUOUS` via `value_track_set_update_mode()`. Frame sprites are `Sprite2D`; never `AnimatedSprite` (Godot 3), and `AnimatedSprite2D`/`SpriteFrames` are excluded by the brief (line 83).
- Not probed on this machine for A7. Unlike A6, no ClassDB probe was run, so these names come from the brief and general Godot 4 knowledge (see Unconfirmed). If unsure a property, constant or method exists in 4.7.2, say so and check the 4.7 class reference or ClassDB before using it.

## Out of scope

- Gameplay: movement, input, jump buffer and coyote, collision boxes and layers, `choose_pose()` (its order, conditions and return values), `LAND_TICKS`, `SCOOT_FRAME` and every other value in `slice_tuning.gd` and `tuning.gd`.
- In `player.gd`, everything except the visual setup and the pose-to-visual mapping (brief line 102). `session.gd`, `fork.gd`, the HUD, sound and music, other level objects.
- The A5 shaders and materials, the A6 effects and driver, all source art and `.import` files other than the new sheet's, every existing test and its expected counts, and `scripts/run-test.sh`.
- Anything the brief does not name: no extra clips, AnimationTree, blend or state machine, bones or Skeleton2D, rotation, lag, overshoot, new gameplay windows, or keys on gameplay values.

## Unconfirmed

- **Animation API names in 4.7.2:** not checked by a probe or the class reference in this session. Includes `loop_mode`, `step`, `value_track_set_update_mode`, the key `transition` argument, `seek()`'s `update` argument, `current_animation_position` and `callback_mode_process`.
- **Same-tick ordering:** whether the AnimationPlayer's physics-callback update runs before or after `player.gd`'s `_physics_process` in one tick. Also whether a `play()` + `seek()` from player.gd shows the synced frame on that tick or the next. This decides the "no extra advance on entry" check (brief line 100).
- **`landing-r0`:** I found no file or folder with that name in the repo. It appears only in CHANGE-BRIEF.md and `sessions/a7/session-1b.jsonl`, which I did not read. The 291/292/299/300 frame reading is unverified by me.
- **Behaviour pins:** none exist yet. The brief requires them committed before wiring (line 111).
- **Hosting:** how `player.gd` attaches `player_visuals.tscn`, and how the original sprite is hidden, is not specified. It needs a plan Kiran approves.
- **Saved library format:** whether an embedded AnimationLibrary that references external `.tres` clips saves and reloads as intended, including from an empty import cache.
- **Import settings:** I did not read the CHAR-SCOOT-A/B `.import` `[params]` that the sheet must match.
- **Realtime runs:** `baseline-14.txt` lists fixed-fps runs only. No realtime run of the suites is recorded for A7.
- **Check runners:** README.md line 33 names `tools/run_slice_checks.sh`; AGENTS.md requires `scripts/run-test.sh`. I did not read `run_slice_checks.sh`.
- **A6 open items:** GPU timing, puff overlap, gameplay peak and others are listed in the A6 version of this file in git history. None was rechecked for A7.
