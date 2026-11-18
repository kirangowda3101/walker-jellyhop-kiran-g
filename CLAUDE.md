@AGENTS.md

# CLAUDE.md — Assignment 7 (animation)

## Project context

- **Engine:** Godot 4.7.2.stable.official.ed1daf0bf (README.md line 13; CHANGE-BRIEF.md line 5; `evidence/a7-baseline/import.txt` line 1). `godot/project.godot` line 15: `config/features=PackedStringArray("4.7", "GL Compatibility")`.
- **Renderer:** Compatibility: `renderer/rendering_method="gl_compatibility"` and `.mobile` the same (`godot/project.godot` lines 32–33). Viewport 1280 × 720, stretch `canvas_items` (lines 19–21).
- **Clip `scoot`** (looping): Sprite2D cell route. `FacingPivot/Scoot/ScootSprite` (Sprite2D, `hframes = 2`, `vframes = 1`) shows `godot/assets/art/CHAR-SCOOT-SHEET.png`, packed from CHAR-SCOOT-A/B by `godot/tools/make_scoot_sheet.gd`. One discrete track on `:frame`. Resource `godot/animations/scoot.tres` (CHANGE-BRIEF.md lines 11, 25, 27, 45, 64, 68; `player_visuals.tscn` lines 20–29).
- **Clip `land`** (one-shot): native cutout rig. Two Sprite2D slices of `CHAR-IDLE.png`: `FacingPivot/LandRig/LowerPivot/LowerSprite` and `FacingPivot/LandRig/UpperPivot/UpperSprite`. Three continuous tracks: `LowerPivot:scale`, `UpperPivot:position`, `UpperPivot:scale`. Resource `godot/animations/land.tres`; r1 keys (CHANGE-BRIEF.md Revision 3, `9ada865`) (brief lines 12, 41–49, 64, 69–71; `player_visuals.tscn` lines 31–59).
- **Both clips play on one `AnimationPlayer`**, a sibling of `FacingPivot` in `godot/features/player/player_visuals.tscn` (root `PlayerVisuals`, Node2D), with `root_node = NodePath("..")`, one embedded AnimationLibrary referencing both `.tres` files, `callback_mode_process = 0` (PHYSICS) and empty autoplay (`player_visuals.tscn` lines 4, 6, 8–12, 61–67; brief lines 64, 98).
- **Built** (glob, 2026-11-17): `godot/animations/{scoot,land}.tres`, `player_visuals.tscn`, the sheet PNG with `.import` and `CHAR-SCOOT-SHEET.ATTRIBUTION.md`, `make_scoot_sheet.gd`, `godot/previews/{land,scoot}_preview.{tscn,gd}`, and the A7 tests below.
- **Sheet import settings match:** the `[params]` block of `CHAR-SCOOT-SHEET.png.import` (lines 16–40) is line-for-line identical to `CHAR-SCOOT-A.png.import` (lines 16–40), including `compress/mode=0`, `mipmaps/generate=true`, `mipmaps/limit=-1`, `process/fix_alpha_border=true`, `process/premult_alpha=false`, `process/size_limit=0`. CHAR-SCOOT-A and -B `[params]` are identical (only `uid`, `path`, `source_file`, `dest_files` differ).
- **The player's state machine is `godot/features/player/player.gd`:**
  - `choose_pose()` (lines 147–163): override → airborne ANTIC/RISE/FALL → LAND while `land_ticks > 0` → SCOOT-A/B when `absf(velocity.x) > 8.0` → WORRY → BORED → IDLE.
  - `_update_pose()` (lines 165–171) sets `sprite.texture` and `sprite.flip_h`, and swaps the box: LOW 52 × 44 for LAND and BORED, else STANDING 52 × 58 (lines 11–13). Line 172 then calls `_update_visuals()`.
  - **Hosting:** `_update_visuals()` (lines 193–236) instantiates `player_visuals.tscn` as a child on first call (lines 194–200; preload line 180), sets the `FacingPivot` mirror (line 201), maps pose → clip via `POSE_CLIPS` (line 182) and shows exactly one of `Scoot`, `LandRig` or the original sprite (lines 203–205). Playback: stop on exit (206–212), pause while disabled (213–221), synced entry via `_clip_time()` (238–242), the Revision 2 LAND → SCOOT seek (228–232). Structure test 29/0 checks the hosting (TEST-REPORT.md line 746).
  - The original sprite is built in code in `_ready()` (lines 53–61): textures `CHAR-<POSE>.png`, `centered = false`, `offset = -T.JELLY_ANCHOR` (512, 812), scale `T.JELLY_SCALE` 0.106 (`godot/game/slice_tuning.gd` lines 14–15), `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`. The player has no `.tscn`.
  - Landing: `just_landed` is cleared at line 95 and set with `land_ticks = T.LAND_TICKS` (8; slice_tuning line 57) at lines 136–138; it counts down at lines 140–141. `tick` advances only while `enabled` (lines 97–100).
  - Scoot phase: `(tick / T.ticks(T.SCOOT_FRAME)) % 2` (line 158). `SCOOT_FRAME` is 0.12 s (slice_tuning line 58) and `ticks()` is `int(round(s * 60))` (lines 116–117): 7 ticks per cell, 14 per cycle.
  - Jump: buffer and coyote are 6 ticks (`godot/features/player/tuning.gd` lines 11–12). Eligibility (player.gd line 124) is checked before `move_and_slide()` and floor detection (lines 134–137).
  - The session writes `worried` and `override_pose` (SPLAT/RESPAWN/CELEBRATE) (`godot/game/session.gd` lines 391–392), and also `enabled`, `velocity`, `position` and `reset_at()` (lines 209, 239–240, 248–252, 267–268, 280–282, 345, 354).
- **Tick order:** player uses the default physics priority 0 (player.gd sets none); session 10 (session.gd line 40); effects driver 20 (`godot/effects/effects_driver.gd` line 12).
- **Same-tick order (probe A1, confirmed):** the AnimationPlayer's physics-callback update runs *after* its parent's `_physics_process` in the same tick: `A1SUM ... before_parent=0` for every route at 30, 60 and 144 (`logs/probe_a7_entry_order_{30,60,144}fps.log` lines 5486–5495). A fresh `play()` + `seek(t, true)` shows `t` on the entry tick with no extra advance (`ENTRYADV R1 ... {"0.000000":19}`, line 5496; `SELECT R1 ... meets_rule_at_this_rate=yes`, line 5512). A `play()` while already playing adds 1/60 (`fd4d855`); fixed for LAND → SCOOT by H3 (`H3VERDICT ... pass=yes`, line 5528; `5c0fb9a`; CHANGE-BRIEF.md Revision 2).
- **Scenes the clips appear in:**
  - The game: `res://game/main.tscn` (project.godot line 14) runs `session.gd`, which builds the level in code (`_build_level()`, session.gd line 87) and the player with `Player.new()` + `add_child` (lines 48–50). `player.gd` hosts `player_visuals.tscn` (Hosting, above); the original sprite stays outside it (brief lines 73, 102).
  - Fixtures: `res://previews/land_preview.tscn` (LAND, starting plate, real table and room) and `res://previews/scoot_preview.tscn`, with their `.gd` scripts. Both reuse the live visual scene (brief line 115). The other previews in `godot/previews/` are A6 particle fixtures.
- **How tests load the game:** every `godot/tests/test_*.gd` extends `SceneTree` (grep, 2026-11-16). `test_slice.gd` sets up the game with `Game.new()`, `test_mode = true` and `root.add_child(game)` (lines 29–31); other suites do not all load the game that way. Existing tests drive input through `player.test_control`/`test_axis`/`test_jump_*` (player.gd lines 39–42) or real events via `Input.parse_input_event` (test_slice.gd line 126).
- **Input in new A7 tests:** inject input only with `Input.parse_input_event`, through the real game loop (CHANGE-BRIEF.md line 110). Never `Input.action_press`, which never reaches `_input` or `_unhandled_input` (A7 handout, Step 2), never `test_control`, and never a direct call to a transition function.
- **Tests that read the original sprite:** `p.textures["IDLE"]` (test_slice.gd line 75), `p.sprite.flip_h` (test_slice.gd line 100; `godot/tests/capture_poses.gd` line 64). Pose sequence `["ANTIC","RISE","FALL","LAND","IDLE"]` (test_slice.gd line 109).
- **The wrapper (`scripts/run-test.sh`, replaced with the A7 handout version in commit `cb0e5e9`; agents never edit it):** `scripts/run-test.sh <test-file.gd> <fps|realtime> [timeout-seconds]` (line 2).
  - It runs `godot --headless [--fixed-fps <fps>] --path godot --script res://tests/<file>` under `timeout ${3:-120}` (line 11).
  - `realtime` drops `--fixed-fps` (lines 5–6). The log goes to `logs/<name>_<fps>fps.log` or `logs/<name>_realtime.log` (lines 6, 8, 10).
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
  # A7 suites (summary line: log file and line). With the 14 above: 26 counted runs, 5 supplemental (commit 6fcf833 message)
  scripts/run-test.sh test_a7_pins.gd 30           # A7 PINS: 31 / 0; also 60 and 144 (logs/test_a7_pins_*fps.log:3727)
  scripts/run-test.sh test_a7_scoot_readback.gd 60 # A7 SCOOT READBACK: 62 / 0     (logs/test_a7_scoot_readback_60fps.log:67)
  scripts/run-test.sh test_a7_land_readback.gd 60  # A7 LAND READBACK: 135 / 0     (logs/test_a7_land_readback_60fps.log:144)
  scripts/run-test.sh test_a7_visual_structure.gd 60 # A7 VISUAL STRUCTURE: 29 / 0 (logs/test_a7_visual_structure_60fps.log:33)
  scripts/run-test.sh test_a7_visual_state.gd 30   # A7 VISUAL STATE: 132 / 0; also 60 and 144 (logs/test_a7_visual_state_*fps.log:6162)
  scripts/run-test.sh test_a7_edges.gd 30          # A7 EDGES: 397 / 0; also 60 and 144 (logs/test_a7_edges_*fps.log:4612)
  scripts/run-test.sh probe_a7_entry_order.gd 30   # supplemental, not counted; also 60 and 144 (A7 PROBE: 96 runs, line 5532)
  ```
  Fresh-clone verification of `41297a2` passed all 26 counted runs, including the 14 baseline runs after r1 (TEST-REPORT.md, A7 Baseline).
- **Headless facts:** `--fixed-fps N` gives N frames per game second with physics at 60 ticks/s (`logs/probe_headless_{30,60,144}fps.log`, 2026-10-27, as recorded in the A6 CLAUDE.md; again `RATE` lines 5485 in `logs/probe_a7_entry_order_{30,60,144}fps.log`: 0.5, 1.0, 2.4 frames per tick). Some suites print `ObjectDB instances were leaked` and `resources still in use` at exit (8 of the 14 A7 baseline logs; `TEST-REPORT.md`, "A7 baseline"); these lines match none of the wrapper's error patterns.
  - Frame strips come from a windowed Movie Maker run, which Kiran starts (confirmed 2026-11-16 with `landing-r0`, a windowed `--write-movie` run at 60 fps).
  - Saved key times are 32-bit floats, so they are compared with a tolerance: `godot/animations/scoot.tres` line 15 and `land.tres` lines 15, 27, 39 store `"times": PackedFloat32Array(...)`; `KEYTIME stored 0.116666667163 exact 7.0/60.0 0.116666666667 diff 0.000000000497` (`logs/test_a7_scoot_readback_60fps.log` line 60).
  - `value_track_get_update_mode` applies only to value tracks. This project has only 2D value tracks, so the non-value case did not arise; both read-backs call it only after a `TYPE_VALUE` check (`test_a7_scoot_readback.gd` lines 159–162; `test_a7_land_readback.gd` lines 202–205; logged as `track ... type TYPE_VALUE` PASS lines).
  - Animation API names exist on the installed 4.7.2 build: ClassDB checks pass for `loop_mode`, `step`, `length`, `callback_mode_process`, `root_node`, `LOOP_LINEAR`/`LOOP_NONE`, `UPDATE_DISCRETE`/`UPDATE_CONTINUOUS`, `TYPE_VALUE`, `ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS`, `value_track_get_update_mode`, `track_get_key_time`, `track_get_key_transition` and others (`logs/test_a7_scoot_readback_60fps.log` lines 4–23; `logs/test_a7_land_readback_60fps.log` lines 4–21). `seek(t, true)` and `current_animation_position` are used by the probe and tests and pass there (probe line 5512; state 132/0), but have no ClassDB line.
  - The embedded library referencing external `.tres` clips reloads from an empty import cache: fresh-cache worktree M4, land 135/0 and scoot 62/0 (TEST-REPORT.md line 740; `evidence/a7-mutations/M4_*`; `c19f966`).
  - Behaviour pins committed before wiring: `test_a7_pins.gd`, 31/0 at 30, 60 and 144 in `fe9a1f0`; PINDIGESTs unchanged after `74fe4b5`, `5c0fb9a`, `167f3ab`, `9ada865` per those commit messages (TEST-REPORT.md lines 705–707). Pinned physics timing: touchdown 892, LAND and low box 892–899, IDLE 900 (line 705).

## Current change

@CHANGE-BRIEF.md

## Ownership

- Every file in `godot/shaders/` is hand-written by Kiran, except `standard_generated.gdshader` and `particles_generated.gdshader` (both generated by Godot, saved by Kiran exactly as generated; `particles_generated.gdshader` is a copy of LandPuff's process material converted for A6 Step 6 and is not used by the game). No agent creates, edits, reformats or "fixes" any file there. If a shader has an error, report the error text and the line, and stop.
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
| AnimationPlayer playback (`play`, `seek`, `stop`, `pause`) | `player.gd` in the game; in a preview, its own preview script, and nothing else there. The supplemental timing probe `godot/tests/probe_a7_entry_order.gd` plays only its own instance of `player_visuals.tscn`, never the game's (CHANGE-BRIEF.md, Revision 1) |
| Original pose sprite: `texture`, `flip_h`, visibility | `player.gd` |
| Collision box (`set_box`) | `player.gd`, unchanged |
| `LowerPivot.position`, sprite offsets and regions | Nobody at runtime; the saved scene value |

The new visual layer only reads gameplay state (`pose`, `land_ticks`, `just_landed`, `tick`, `velocity`, `facing`); it never writes it. The existing pose assignment and collision updates in `_update_pose()` stay unchanged (player.gd lines 165–171).

## Godot 4 names

- Use Godot 4.7.2 names: `AnimationPlayer`, `AnimationMixer`, `AnimationLibrary`, `Animation`, `Sprite2D` (`hframes`, `vframes`, `frame`, `region_enabled`, `region_rect`), `Node2D`.
- Loop: `Animation.loop_mode` with `Animation.LOOP_NONE` / `LOOP_LINEAR`, never a boolean `loop`. Speed: `speed_scale`, never `playback_speed`. Callback: `callback_mode_process` with `AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS`, never `playback_process_mode`.
- Update modes: `Animation.UPDATE_DISCRETE` / `UPDATE_CONTINUOUS` via `value_track_set_update_mode()`. Frame sprites are `Sprite2D`; never `AnimatedSprite` (Godot 3), and `AnimatedSprite2D`/`SpriteFrames` are excluded by the brief (line 83).
- Checked against the Godot 4.7 class reference and probed with ClassDB on the installed 4.7.2 build (see Headless facts). If unsure a property, constant or method exists in 4.7.2, say so and check the 4.7 class reference or ClassDB before using it.

## Out of scope

- Gameplay: movement, input, jump buffer and coyote, collision boxes and layers, `choose_pose()` (its order, conditions and return values), `LAND_TICKS`, `SCOOT_FRAME` and every other value in `slice_tuning.gd` and `tuning.gd`.
- In `player.gd`, everything except the visual setup and the pose-to-visual mapping (brief line 102). `session.gd`, `fork.gd`, the HUD, sound and music, other level objects.
- The A5 shaders and materials, the A6 effects and driver, all source art and `.import` files other than the new sheet's, every existing test and its expected counts, and `scripts/run-test.sh`.
- Anything the brief does not name: no extra clips, AnimationTree, blend or state machine, bones or Skeleton2D, rotation, lag, overshoot, new gameplay windows, or keys on gameplay values.

## Unconfirmed

- **A headless run draws nothing:** not shown by any file in the repository. Headless runs do advance clips and read their structure (the A7 logs above). The A6 cost run reported the driver as `opengl3` (TEST-REPORT.md line 589); `logs/probe_headless_*fps.log` line 21 shows a `servers/rendering/dummy` frame in a stack trace. Neither shows whether anything is drawn.
- **Pause, then SCOOT on the first enabled tick after LAND:** keeps the plain seek; no test covers it (CHANGE-BRIEF.md Revision 2, third paragraph).
- **`landing-r0` frame count:** the folder had 516 PNGs while Godot reported 356; unexplained (FRICTIONAL.md line 945). The full capture stays outside the repository (`~/Documents/a7-reference/landing-r0/`); Kiran's eight-frame LAND reading (292–299) matches the pins' eight LAND ticks (892–899, a separate replay; TEST-REPORT.md line 705).
- **Realtime runs:** `baseline-14.txt` lists fixed-fps runs only. No realtime run of the suites is recorded for A7 (no `logs/*a7*realtime*`, glob 2026-11-17).
- **Check runners:** README.md line 33 names `tools/run_slice_checks.sh`; AGENTS.md requires `scripts/run-test.sh`. I did not read `run_slice_checks.sh`.
- **A6 open items:** GPU timing, puff overlap, gameplay peak and others are listed in the A6 version of this file in git history. None was rechecked for A7.
