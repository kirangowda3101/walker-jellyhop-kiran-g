@AGENTS.md

# CLAUDE.md — Assignment 5 (shaders and materials)

## Project context

- **Engine:** Godot 4.7.2.stable.official.ed1daf0bf (`godot --version` on this machine, 2026-10-27; README.md line 13 agrees). `godot/project.godot` line 15: `config/features=PackedStringArray("4.7", "GL Compatibility")`.
- **Renderer:** Compatibility, `renderer/rendering_method="gl_compatibility"` and `.mobile` the same (`godot/project.godot` lines 32–33). No `rendering/viewport/hdr_2d` line, so HDR 2D is off (`godot/project.godot` lines 30–34).
- **Viewport:** 1280 × 720, stretch mode `canvas_items` (`godot/project.godot` lines 19–21).
- **Main scene:** `res://game/main.tscn` (`godot/project.godot` line 14). It is a single `Node2D` named `JellyHop` with `res://game/session.gd` attached (`godot/game/main.tscn` lines 3–6). The whole level is built in code by `session.gd` `_build_level()` (`godot/game/session.gd` lines 86–153).
- **The shaded object (the fork sprite):**
  - Forks are created in code, one per plate with a cycle: `Fork.new()`, `add_child(fork)`, `fork.setup(i, cycle)` (`godot/game/session.gd` lines 124–132). Plate 1 has no fork (`godot/game/slice_tuning.gd` line 43), so there are five forks.
  - Each fork is a `Node2D` (`godot/features/fork/fork.gd` line 1). `setup()` makes a child `head` (`Node2D`) and under it a `Sprite2D` with texture `res://assets/art/ENV-FORK.png`, `centered = false`, `offset = (-167.5, -1258)`, scale `T.fork_scale()`, filter `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` (`fork.gd` lines 39–48). The sprite is held in `var sprite` (`fork.gd` line 28).
  - The sprite has no material today: nothing in `fork.gd` sets `material` (`fork.gd` lines 42–48).
  - `ENV-FORK.png` is 335 × 1267, 8-bit RGBA (`file` output recorded in `sessions/session-1.jsonl`).
  - The shadow ellipse is a separate thing, drawn by the fork node's own `_draw()` (`fork.gd` lines 224–236), not by the sprite.
  - The hit area is the tine outlines traced from the texture alpha (`fork.gd` lines 49–59, 62–109).
- **Game state that drives the effect:**
  - Phase: `enum Phase { SAFE, SHADOW, DOWN, HOLD, UP }` (`fork.gd` line 9). `phase()` comes from `t`, `safe_ticks` and `shadow_ticks` (`fork.gd` lines 119–135).
  - `shadow_amount()` in SHADOW is `(p - safe_ticks + 1) / shadow_ticks` (`fork.gd` lines 198–203).
  - Tick advance: `fork.advance()` (`fork.gd` lines 144–162). Held forks do not advance (line 147).
  - Holding and restarting: `hold_raised()` (lines 164–173), `restart_at_safe()` (lines 175–181), `reset_cycle()` (lines 111–117).
  - Owner of when forks advance: `session.gd` `_physics_process()` calls `_advance_forks()` only in PLAYING, SPLAT or REFORM (`godot/game/session.gd` lines 328–330, 292–301). The session sets `process_physics_priority = 10` (`session.gd` line 40).
  - Session states: `enum State { INTRO, PLAYING, PAUSED, SPLAT, REFORM, WON }` (`session.gd` line 12).
  - Cycle lengths: `FORK_CYCLES` (`godot/game/slice_tuning.gd` lines 42–49). Seconds become ticks through `ticks(s) = int(round(s * 60.0))` (`slice_tuning.gd` lines 116–117).
- **3D object for the textured shader:**
  - `Floor`, a `MeshInstance3D` (`godot/showcase/a3_assets.tscn` lines 23–25).
  - Its mesh is `BoxMesh_floor`, size 8 × 0.1 × 4 (lines 10–12).
  - Its material today is the `StandardMaterial3D` sub-resource `Mat_floor`, `albedo_color = Color(0.35, 0.33, 0.3, 1)`. It is set on the mesh (`material = SubResource("Mat_floor")`), not as a node override (lines 7–8, 11).
  - Light: `Sun` (`DirectionalLight3D`, shadows on) (lines 39–41).
  - Camera: `Camera3D` (lines 43–46).
  - The plan in CHANGE-BRIEF.md §7 is a new scene `godot/showcase/a5_materials.tscn` that instances this scene rather than editing it.
- **Textures present:** `godot/assets/textures/dark_wood/` holds `dark_wood_diff_2k.png`, `dark_wood_rough_2k.png`, `dark_wood_nor_gl_2k.png` and `dark_wood_nor_dx_2k.png` (CHANGE-BRIEF.md §7).
- **How the tests load the game:**
  - Every test is a `SceneTree` script (`extends SceneTree`, `_initialize()`).
  - The game tests build the session directly with `Game.new()` / `root.add_child(game)`, not through `main.tscn` (`godot/tests/test_game.gd` lines 5, 30–32; `test_slice.gd` lines 29–31; `test_keyboard.gd` lines 53–55).
  - `test_a3_assets.gd` tests `res://showcase/a3_assets.tscn`, named in its `SHOWCASE` constant (`test_a3_assets.gd` line 6).
- **Test commands:** run from the repository root, always through the wrapper (`scripts/run-test.sh`, executable). The wrapper:
  - runs `godot --headless --path godot --script res://tests/<file> --fixed-fps <fps>` under `timeout 120`;
  - tees the output to `logs/<name>_<fps>fps.log`;
  - forces exit 1 if the log contains `SHADER ERROR` or `SCRIPT ERROR` (`scripts/run-test.sh` lines 5–9).

  ```sh
  scripts/run-test.sh test_game.gd 60       # prints "WALKER TESTS: N checks / F failures"   (test_game.gd line 173)
  scripts/run-test.sh test_slice.gd 60      # prints "SLICE TESTS: N checks / F failures"    (test_slice.gd line 60)
  scripts/run-test.sh test_keyboard.gd 60   # prints "KEYBOARD TESTS: N checks / F failures" (test_keyboard.gd line 99)
  scripts/run-test.sh test_a3_assets.gd 60  # prints "A3 ASSET CHECKS: N checks / F failures" (test_a3_assets.gd line 125)
  ```

  Each test exits 1 if any check fails (`quit(1 if failures else 0)`; same files, lines 177, 64, 103, 126). The expected counts before A5 are 25, 61, 12 and 36 checks (CHANGE-BRIEF.md §4). New A5 tests run the same way at 30, 60 and 144: `scripts/run-test.sh <test>.gd 30`, then `60`, then `144`.

## Headless facts

Confirmed on this machine on 2026-10-27 with `godot/tests/probe_headless.gd` (logs: `logs/probe_headless_30fps.log`, `_60fps.log`, `_144fps.log`) unless marked otherwise.

- A headless run uses a dummy renderer and draws nothing (course statement, not probed), so no headless test can judge a colour, texture or material. Every visual rule ends in a human check.
- `Shader.get_shader_uniform_list()` reports each uniform's name, type and hint headlessly (probe: `w`, type 3, hint 1, `"0.0,1.0,0.001"`) but not its default; `RenderingServer.shader_get_parameter_default()` returns `null`. Tests read defaults from the shader source text.
- A shader that fails to parse prints `SHADER ERROR` and returns an empty uniform list (probe: size 0). The wrapper turns that into exit 1; Godot's own exit code 0 does not mean no errors.
- `set_shader_parameter()` with an undeclared name raises no error and `get_shader_parameter()` returns the stored value (probe: 1.0), so only a uniform-list assertion catches a renamed uniform. A value outside `hint_range` set from code is stored unclamped (probe: 2.0); whether the GPU clamps it is checked by a capture.
- `--fixed-fps N` gives N frames per game second while physics stays at 60 ticks per second: 2 ticks per frame at 30 fps (119–120 per 60 frames), 1 at 60, and 25 per 60 frames at 144. `Engine.time_scale = 0.5` halves the physics `delta` but leaves the tick count unchanged at all three.
- The existing suites print `ObjectDB instances were leaked` (WARNING) and `resources still in use` (ERROR) at exit. These are pre-existing (baseline logs, 2026-10-27) and are not `SHADER ERROR` or `SCRIPT ERROR`.

## Current change

@CHANGE-BRIEF.md

## Ownership

- Every file in `godot/shaders/` is hand-written by Kiran. That includes `fork_warning.gdshader`, `table_wood.gdshader` and the hint-experiment shader. `standard_generated.gdshader` is generated by Godot and saved by Kiran exactly as generated.
- No agent creates, edits, reformats or "fixes" any file in `godot/shaders/`. If a shader has an error, report the error text and the line, and stop.

## Out of scope

- Gameplay: the jelly's movement and input, collision shapes and layers, the fork hit polygons, plates, sauce, the goal.
- The fork cycle and the session:
  - the phase logic in `fork.gd`;
  - the state machine in `session.gd`;
  - every value in `slice_tuning.gd` and `features/player/tuning.gd`.
- Presentation code may read a fork's `phase()`, `t` and the tick values. It must never write `t`, `held`, `hold_pending`, `announced` or any session state.
- Sound and music behaviour (`godot/audio/`).
- The look of everything except the fork sprite in 2D: the code-drawn shadow, the jelly, plates, sauce, dome, room, table and HUD.
- `godot/showcase/a3_assets.tscn` and `test_a3_assets.gd`. The A5 3D work goes in a new scene that instances the A3 scene.
- Existing tests and their expectations. Source art and models: `ENV-FORK.png`, the `.glb` files and the dark-wood PNGs. Their `.import` files may change only as CHANGE-BRIEF.md §7 specifies.
- The colour line, the uniforms and their defaults are fixed by the brief. Agents do not invent other effects such as fade-outs, pulses or brightness changes.

## Unconfirmed

- **Dark-wood import settings:** resolved. `.import` files exist with the CHANGE-BRIEF.md Revision 2 values, confirmed by name in the Import dock (MATERIALS.md). The Poly Haven source and licence are in `godot/assets/textures/dark_wood/ATTRIBUTION.md`.
- **A5 files:** resolved. `godot/shaders/`, `godot/materials/`, `godot/showcase/a5_materials.tscn`, `godot/showcase/hint_experiment.tscn`, `test_fork_warning.gd` and `test_materials.gd` now exist.
- **Driver:** resolved in CHANGE-BRIEF.md Revision 1: `fork.gd` `_apply()` sets `warning`; each fork's sprite gets a duplicate of `godot/materials/fork_warning.tres`.
- **Floor material:** resolved: a surface material override on the instanced `Floor` in `a5_materials.tscn` (`a3_assets.tscn` unchanged).
- **Existing suites at 30 and 144 fps:** the brief records them passing at 60 fps only. I have not run any test in this session.
- **Brief statements that are Kiran's predictions:** the `Engine.time_scale` behaviour (rule 5), `source_color` in 2D and spatial shaders (§6, §7), the hint-experiment values on Compatibility (§8) and whether `hint_range` clamps values set from code (§10.7). These are unverified.
- **Two ways of running checks:** README.md line 33 names `tools/run_slice_checks.sh`. AGENTS.md requires `scripts/run-test.sh` for every Godot test. I did not read `run_slice_checks.sh`.
