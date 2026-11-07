@AGENTS.md

# CLAUDE.md — Assignment 6 (particle effects)

## Project context

- **Engine:** Godot 4.7.2.stable.official.ed1daf0bf (README.md line 13; CHANGE-BRIEF.md line 5). `godot/project.godot` line 15: `config/features=PackedStringArray("4.7", "GL Compatibility")`. I did not run `godot --version` in this session.
- **Renderer:** Compatibility: `renderer/rendering_method="gl_compatibility"` and `.mobile` the same (`godot/project.godot` lines 32–33). Viewport 1280 × 720, stretch `canvas_items` (lines 19–21).
- **Effect nodes:** both effects are `GPUParticles2D` with a `ParticleProcessMaterial`; each texture is a `GradientTexture2D` sub-resource in the scene file, not an image (CHANGE-BRIEF.md lines 7, 42, 164).
  - Effect A, `LandPuff`: `godot/effects/land_puff.tscn` (brief line 42).
  - Effect B, `DomeGlints`: `godot/effects/dome_glints.tscn`, with an additive `CanvasItemMaterial` (brief lines 164, 179).
  - Driver: `godot/effects/effects_driver.gd` (brief line 241). `godot/effects/` and `godot/previews/` do not exist yet. The project has no particle node today (no `GPUParticles`, `CPUParticles` or `ParticleProcessMaterial` in any `.gd`, `.tscn` or `.tres` under `godot/`).
- **No signals:** no `.gd` file under `godot/` declares a `signal`. Both effects are driven by per-tick state.
- **Effect A event: a landing.** The event is the per-tick flag `player.just_landed`.
  - It is declared at `godot/features/player/player.gd` line 26, cleared at the start of every jelly tick (line 95), and set when grounded and not `was_grounded` (lines 136–137).
  - The session reads it in `godot/game/session.gd` `_physics_process()`: `if state == State.PLAYING and player.just_landed:` (line 372), then `sound.play("SFX-LAND")` (line 374).
  - That check comes after `resolve_contacts()` (line 371), so a landing into sauce has already become `SPLAT` and plays no LAND sound.
  - A respawn is not a landing: `reset_at()` sets `was_grounded = true` and `just_landed = false` (player.gd lines 69–81).
  - `sound.count(id)` counts recorded calls (`godot/audio/sound_events.gd` lines 39–44; every `play()` is logged at line 35).
  - The jelly's position is its feet, bottom centre: the collider sits above the origin (player.gd lines 64–67) and the sprite is anchored at its bottom centre (lines 55–58).
- **Effect B condition: `state != State.WON`.**
  - `enum State { INTRO, PLAYING, PAUSED, SPLAT, REFORM, WON }`, `var state` (session.gd lines 12, 15).
  - INTRO is set by `_start_intro()` from `_ready()` (lines 63, 204–210).
  - WON is set in `resolve_contacts()` (lines 275–284).
  - Replay is `start_session()` from WON (lines 212–218), called by any key once `prompt_shown` (lines 404–406).
  - PAUSED comes from `set_paused()` (lines 244–251), called by Esc (lines 407–408) and by focus loss unless `test_mode` (lines 253–255). The game never sets `get_tree().paused`.
- **Tick order:** the session sets `process_physics_priority = 10` (session.gd line 40). `player.gd` does not set one (default 0), so the jelly ticks before the session. The driver must use a priority above 10 (brief line 241).
- **The scenes the effects appear in:**
  - The game: `res://game/main.tscn` (`godot/project.godot` line 14) is one `Node2D` `JellyHop` with `session.gd` (`main.tscn` lines 3–6).
  - The level is built in code by `_build_level()` (session.gd lines 86–153). There is no level `.tscn`.
  - Draw order: room on `CanvasLayer` −10 (lines 89–95); table `z_index` −5 (line 103); plates −2 (line 119); sauce −1 (line 142); jelly 0 (not set in player.gd); dome 5 (line 151); HUD on its own `CanvasLayer` (lines 57–61).
  - The dome sprite is at `(T.dome_left() + T.dome_width() / 2, T.TABLE_TOP + 1)` (session.gd line 150). `TABLE_TOP` = 520 (`godot/game/slice_tuning.gd` line 9); `dome_left()` and `dome_width()` are at lines 107–111.
  - Preview fixtures (to be built): `godot/previews/land_puff_preview.tscn` and `dome_glints_preview.tscn` (brief lines 116, 224).
- **How tests load the game:**
  - Every test is `extends SceneTree`.
  - Game tests build the session with `Game.new()`, set `test_mode = true`, then `root.add_child(game)`, not via `main.tscn` (`test_game.gd` lines 30–32; `test_slice.gd` 29–31; `test_keyboard.gd` 53–55; `test_fork_warning.gd` 152–154).
  - Scripted input comes either through `player.test_control` / `test_axis` / `test_jump_*` (player.gd lines 39–42) or as real key events through `Input.parse_input_event` (`test_keyboard.gd` line 24; `test_slice.gd` line 126). `godot/tests/route_driver.gd` drives routes.
- **The wrapper (`scripts/run-test.sh`, never edited):** usage is `scripts/run-test.sh <test-file.gd> <fps|realtime> [timeout-seconds]` (line 2).
  - It runs `godot --headless [--fixed-fps <fps>] --path godot --script res://tests/<file>` under `timeout ${3:-120}` (line 11).
  - `realtime` drops `--fixed-fps` (lines 5–6).
  - The log is `logs/<name>_<fps>fps.log` or `logs/<name>_realtime.log` (lines 8, 10).
  - It forces exit 1 if the log contains `SHADER ERROR` or `SCRIPT ERROR` (line 13). Godot's own exit 0 alone does not mean no errors.
- **Test commands** (from the repository root; each test exits 1 on any failed check):
  ```sh
  scripts/run-test.sh test_game.gd 60            # "WALKER TESTS: N checks / F failures"   (test_game.gd line 173)
  scripts/run-test.sh test_slice.gd 60           # "SLICE TESTS: ..."                      (test_slice.gd line 60)
  scripts/run-test.sh test_keyboard.gd 60        # "KEYBOARD TESTS: ..."                   (test_keyboard.gd line 99)
  scripts/run-test.sh test_a3_assets.gd 60       # "A3 ASSET CHECKS: ..."                  (test_a3_assets.gd line 125)
  scripts/run-test.sh test_fork_warning.gd 30    # "FORK WARNING TESTS: ..." (test_fork_warning.gd line 167); also 60, 144
  scripts/run-test.sh test_materials.gd 60       # "MATERIAL CHECKS: ..."  (test_materials.gd line 456); also 30, 144
  scripts/run-test.sh <test>.gd realtime         # real-time clock, no --fixed-fps; optional 3rd arg = timeout seconds
  ```
  - Baseline before A6 (commit `068ede4` message): 25, 61, 12, 36 at 60; 29 and 108 at 30, 60 and 144; all 0 failures.
  - New A6 tests named by the brief: `test_land_puff_config.gd` and `test_dome_glints_config.gd` (lines 105, 215), plus a state test for A1–A8 and B1–B7 (not yet named).
- **Headless limits:**
  - A headless run uses a dummy renderer and draws nothing (course statement; brief Answers 4). Look, contrast, scale and timing are judged by Kiran's eyes in the running game.
  - `--fixed-fps N` gives N frames per game second with physics at 60 ticks/s (`logs/probe_headless_{30,60,144}fps.log`, 2026-10-27).
  - Existing suites print `ObjectDB instances were leaked` and `resources still in use` at exit. These are pre-existing and are not SCRIPT/SHADER ERRORs.

## Current change

@CHANGE-BRIEF.md

## Ownership

- Every file in `godot/shaders/` is hand-written by Kiran, except `standard_generated.gdshader` (generated by Godot, saved by Kiran exactly as generated). No agent creates, edits, reformats or "fixes" any file there. If a shader has an error, report the error text and the line, and stop.
- Effect settings live in the scene files in `godot/effects/` (`land_puff.tscn`, `dome_glints.tscn`), never in code. `effects_driver.gd` only instances scenes, places them, and sets `emitting` or calls `restart()`. It never assigns particle, material or texture properties.

## Godot 4 names

- Use Godot 4 class and property names for 4.7.2: `GPUParticles2D`, `ParticleProcessMaterial`, `GradientTexture2D`, `GradientTexture1D`, `CurveTexture`, `CanvasItemMaterial`. Never use Godot 3 names: `Particles2D`, `ParticlesMaterial`, `initial_velocity` (4 uses `_min`/`_max`), `scale`/`scale_random` on the material (4 uses `scale_min`/`scale_max`).
- Write property names exactly as in the brief's tables. A misspelled property in a `.tscn` loads silently at its default (brief predicted failure 1), so the config tests must read every property back.
- If unsure a property, constant or signal exists in 4.7.2, say so and check the class reference or ClassDB before using it. Do not guess. See Unconfirmed for the names not yet checked.

## Out of scope

- Gameplay: movement, input mapping, collision shapes and layers, fork hit areas, plates, sauce and the goal.
- The session's state machine and timings; the fork cycle and `fork.gd`; every value in `slice_tuning.gd` and `features/player/tuning.gd`.
- Presentation code may read `state`, `player.just_landed` and `player.global_position`. It never writes any game, player, fork or session state.
- Changes to `session.gd` beyond the single `_ready()` line that adds the driver. That line is proposed in the Step 3 plan and needs Kiran's approval.
- Sound and music (`godot/audio/`); the HUD; the look of everything other than the two effects.
- `godot/shaders/`, `godot/materials/`, the showcase scenes, all source art, every existing test and its expected counts, and `scripts/run-test.sh`.
- Effects or behaviour the brief does not name: no extra emitters, sub-emitters, trails, collision, turbulence, screen shake or sound.

## Unconfirmed

- **Property names in 4.7.2:** I could not confirm them in this session. A ClassDB probe in a scratch project under `/tmp` needed approval and did not run. Unchecked:
  - every `GPUParticles2D` and `ParticleProcessMaterial` property in the brief's tables;
  - the constants `EMISSION_SHAPE_RING`, `EMISSION_SHAPE_BOX`, `FILL_RADIAL` and `BLEND_MODE_ADD`;
  - the `finished` signal, `restart()` and `use_fixed_seed`. The brief itself says "if 4.7 has it" for `use_fixed_seed` (line 120).
- **Engine version:** taken from README.md and the brief. I did not run `godot --version`.
- **Kiran's predictions in the brief, not yet tested:**
  - `finished` fires headless (A6);
  - `restart()` re-applies preprocess (B3);
  - glints are present when shown again (B6);
  - at most 2 bursts alive (A5);
  - the hand-set `visibility_rect`s;
  - Visual Profiler GPU time under Compatibility on macOS (failure 9);
  - the 2D collision/SDF claim (Answers 1).
- **Ring with axis Y collapsing to a line** with `particle_flag_disable_z` (predicted failure 2): unverified.
- **Draw order of the land puff:** sauce is also `z_index` −1 (session.gd line 142), the same as `LandPuff`. The brief names only plates and the jelly, so puff vs sauce order is undecided.
- **Two check runners:** README.md line 33 names `tools/run_slice_checks.sh`, while AGENTS.md requires `scripts/run-test.sh`. I did not read `run_slice_checks.sh`.
- **Existing suites in realtime mode:** never run. I ran no test in this session.
