I read the whole spec and found nothing in `fork_warning.gdshader` that conflicts with it. Nothing has been edited and no tests have been run. My only shell command was read-only: it read the player tuning, searched for priority and pause code, and printed the existing probe logs.

## What I read and found

- **Your shader** (`godot/shaders/fork_warning.gdshader`, lines 1–10): `canvas_item` and `unshaded`; the three uniforms with the hints and defaults in §2; the colour line written exactly as in §2. I see nothing wrong with it.
- **Timing facts the plan relies on:**
  - The player's `_physics_process` runs at priority 0 and the session's at 10.
  - Nothing sets `process_priority`.
  - Nothing pauses the scene tree. PAUSED is only a session state.
- **One trap for the test:** code in a `SceneTree` test that resumes after `await physics_frame` runs *before* the nodes' `_physics_process` in that tick. So the test cannot read values from its own loop. The samplers have to be nodes with a high priority, as §5 says.
- **`fork.gd` already funnels every change through one function.** Each change to `t` or `held` ends in `_apply()`: `advance()` line 161, `hold_raised()` 173, `restart_at_safe()` 181, `reset_cycle()` 117. That makes `_apply()` the natural place to set `warning`.

## Driver: my recommendation (needs your decision; CLAUDE.md lists it as open)

Put it in `fork.gd`. It adds about 10 lines, reads fork state only, and leaves the phase logic alone:

```gdscript
const WARNING_SHADER = preload("res://shaders/fork_warning.gdshader")
# setup(), after the sprite's texture_filter line:
	var warning_material := ShaderMaterial.new()   # one per fork, so each holds its own `warning` (rule 7)
	warning_material.shader = WARNING_SHADER
	sprite.material = warning_material

func warning() -> float:
	## Shader `warning` (CHANGE-BRIEF.md §2): the shadow growth during SHADOW; 0 in other phases or when held.
	if held or phase() != Phase.SHADOW:
		return 0.0
	return shadow_amount()

func _apply() -> void:   # existing; one line added
	...
	if sprite:
		sprite.material.set_shader_parameter("warning", warning())
```

**Why here:** `warning` changes in the same call that changes `t`, so it cannot lag by a tick (failure 3). It goes to 0 inside `hold_raised()` on the tick of the hold (rule 6, failure 4). It is also right after `reset_cycle()` runs from a key press during the intro, which happens outside physics. I'm not recommending a separate driver node at a high physics priority because its result would depend on update order, and it would still have to be attached from `fork.gd` or `session.gd`.

**Three things to decide:**
1. **"Every physics tick":** a held fork doesn't advance, so its `warning` isn't rewritten each tick. It stays at the `0.0` that `hold_raised()` wrote. In INTRO, PAUSED and WON nothing is written, so the value holds (rule 5). Is that acceptable against the §2 wording?
2. **`strength` and `warn_color`:** the driver never sets them, so they keep the shader defaults. A material created in code has no saved resource you could tune in the Inspector. You could tune it only live in the Remote tree, or by changing your shader's default. Do you want a `.tres` base material that each fork duplicates instead?
3. **Exact values:** the driver uses `shadow_amount()`, so `warning` is exactly `(p − safe_ticks + 1) / shadow_ticks` in SHADOW.

## New test: `godot/tests/test_fork_warning.gd`

It is a `SceneTree` script built like `test_slice.gd`. It creates the game with `Game.new()` and sets `test_mode = true` so losing window focus doesn't pause it. It ends with `FORK WARNING TESTS: N checks / F failures`, writes a JSON file to `evidence/`, and calls `quit(1 if failures else 0)`.

It uses two sampler nodes, defined as classes inside the test and added to `root`:
- **Per-tick sampler:** `process_physics_priority = 1000`, which runs after the session's 10. Every physics tick it records each fork's `warning`, `t`, `held`, `phase()`, the session state and `Engine.get_physics_frames()`.
- **Per-frame sampler:** `process_priority = 1000`. Every rendered frame it records each fork's `warning` and adds up `_process` delta as game time.

Both use `process_mode = ALWAYS`.

Only two things are fixtures rather than the game loop: setting `Engine.time_scale` in check 11, and pausing the tree in check 10b. Neither touches fork or session state. Everything else is the real game loop and real key events through `Input.parse_input_event`. The test never writes `t`, `held` or session state.

| # | Assertion | Rule |
|---|---|---|
| 1 | The shader loads and `get_shader_uniform_list()` returns exactly `warning`, `warn_color` and `strength`. `warning` and `strength` are type 3 (float) with a range hint of `0.0,1.0`. I expect `warn_color` to be type 20 (Color); I'll confirm that on the first run and report it rather than adjust it | Parses; names and types |
| 2 | Defaults read from the source text with a regex: `0.0`, `vec4(1.0, 0.702, 0.278, 1.0)`, `0.65`. Also checks for `shader_type canvas_item`, `render_mode unshaded` and the exact colour line | Defaults (§2) |
| 3 | Five forks, five `ShaderMaterial`s with distinct instance IDs, all using the same `Shader` object. Plate 1 has no fork | 7, failure 1 |
| 4 | No fork's material holds an override for `strength` or `warn_color`. I still need to check what an unset parameter reads back headlessly | §2 "Nobody at runtime" |
| 5 | On the first sampled frame in INTRO, forks 5 and 6 read `37/72` and `31/60` and forks 2–4 read `0.0`. Every frame and tick of the natural pan (no skip, about 240 ticks) shows the same values | 4; 5 (INTRO holds) |
| 6 | After the pan ends on its own, the jelly stays idle on plate 1 for 600 ticks, enough for at least two SHADOW phases of every fork. On every tick, every fork's `warning` equals a value the test computes from its own tick count since play started: `offset + k`, then phase from `slice_tuning.gd`. It does not use the fork's `t`. The test prints an MD5 of the sequence so the 30, 60 and 144 logs can be compared | 1 (per tick, all fps) |
| 7 | For each complete SHADOW of each fork: the last SAFE tick reads 0, the first SHADOW tick reads `1/n`, each tick rises by `1/n`, the last SHADOW tick reads exactly `1.0`, the first DOWN tick reads 0 | 1, failure 3; 3 (each new SHADOW in the cycle starts at `1/n`) |
| 8 | At least one tick has one fork in SHADOW reading above 0 while another fork in SAFE reads `0.0` (shows check 3's condition actually occurs) | 7 |
| 9 | Per frame, for each complete ramp: game time from the first frame with `warning > 0` to the first frame back at `0.0` equals the SHADOW length within `1/fps`. At 60 fps the first frame also reads `1/n` and the last reads `1.0` | 2, failure 2 |
| 9c | Controls: shifting the recorded sequence by one tick must fail check 7, and a ramp counted in frames must fail check 9 at 30 and 144 | Shows 7 and 9 can fail |
| 10 | A real Esc press while a fork is mid-SHADOW. Every frame and tick reads the same value until a second Esc, then the next tick rises by `1/n` | 5 (pause) |
| 10b | Optional fixture: `paused = true` on the tree; the value holds | 5 (tree paused) |
| 11 | With `Engine.time_scale = 0.5`, one full ramp lasts the same `n` ticks as at 1.0. The scaled game time is about 0.8 s for the 1.6 s fork, which checks your prediction. Time scale is reset to 1.0 afterwards | 5 (time scale) |
| 12 | Real input: hold D and press Space at plate 1's edge to hop to plate 2 (asserts `checkpoint == 1`). Wait for fork 2's SHADOW, then hold D to walk into the sauce in gap 2 while it is mid-SHADOW. Ticks: `warning > 0` on the tick before the splat, `0.0` on the splat tick (`hold_raised()`) | 6, failure 4 |
| 13 | After the re-form: `warning` is `0.0` on the `restart_at_safe()` tick, and fork 2's next SHADOW starts at `1/96`, not at the interrupted value | 3; 6 (`restart_at_safe`) |
| 14 | The jelly then stands still and fork 2 hits it (a real fork splat, which takes the `hold_pending` path). After release, its next SHADOW again starts at `1/96` | 3 (the §5 retrigger route) |

The route in 12 is feasible on paper: speed 320, jump −640 and gravity 1920 give a jump of about 213 px against a 120 px gap. Each step has a step limit and a named failure, so a missed hop fails clearly instead of hanging the test.

**What a headless pass proves:** the material wiring and the exact value of the `warning` uniform per tick and per frame. That holds under `--fixed-fps` 30, 60 and 144, through the real loop and real keys, including the pause, hold, restart and time-scale paths.

**What it cannot prove:**
- Any colour on screen. The dummy renderer draws nothing, so it can't show that the sprite really draws with the material, what `source_color` does in 2D, or whether the GPU clamps values.
- Readability or the silhouette.
- Real-time behaviour without `--fixed-fps`. In particular, the time-scale result is shown only under fixed fps.
- WON holding its value; no check covers it.

## Checks that need your eyes

1. Captures at `warning` 0.0, 0.5 and 1.0 (strength 0.65), sampling P1 (168, 300) and P2 (298, 850) against the §6 table.
2. Whether `source_color` changes `warn_color` in a non-HDR 2D canvas (the same captures).
3. The `warning = 2.0` capture: does `hint_range` clamp it on the GPU (§10.7)?
4. In normal play, several warnings on the real background: is the glow readable, and does the fork still read as a fork?
5. Side-by-side captures with the glow on and off: the silhouette and every other object (shadow ellipse, jelly, plates, sauce, HUD) unchanged.
6. A windowed run of the intro pan: forks 5 and 6 visibly half-amber.
7. The contrast against the real room pixel behind the fork (§6).

## Steps to approve by number

1. **Driver:** add the material creation in `setup()`, plus `warning()` and the one line in `_apply()`, to `godot/features/fork/fork.gd`. No other file changes. Show the diff.
2. **Regression run:** run the existing four suites at 60 fps and show the output. Expect 25, 61, 12 and 36 checks with 0 failures, and no `SHADER ERROR` or `SCRIPT ERROR`.
3. **Test skeleton:** create the test file with the two samplers, the summary line, the evidence JSON, and checks 1–4. Run at 30, 60 and 144.
4. **Intro:** add check 5. Run at 30, 60 and 144.
5. **Idle play:** add the 600-tick run with checks 6–9 and the controls in 9c. Run at 30, 60 and 144 and compare the three MD5s.
6. **Pause and time scale:** add checks 10 and 11, plus 10b if you want the tree-pause fixture. Run at 30, 60 and 144.
7. **Real-input splats:** add checks 12–14. Run at 30, 60 and 144.
8. **Final run:** the existing four at 60 and the new test at 30, 60 and 144, with the full output and any error lines. Then a written summary of what passed, what it proves, and what is left for your visual checks. No commit.