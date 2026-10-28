All eight steps are done, and the final run passes everywhere. The new test has 29 checks with 0 failures at 30, 60 and 144 fps. The four existing suites still pass at 60 fps.

## Final run

| Test | fps | Result | Exit |
|---|---|---|---|
| `test_game.gd` | 60 | 25 checks / 0 failures | 0 |
| `test_slice.gd` | 60 | 61 checks / 0 failures | 0 |
| `test_keyboard.gd` | 60 | 12 checks / 0 failures | 0 |
| `test_a3_assets.gd` | 60 | 36 checks / 0 failures | 0 |
| `test_fork_warning.gd` | 30 | 29 checks / 0 failures | 0 |
| `test_fork_warning.gd` | 60 | 29 checks / 0 failures | 0 |
| `test_fork_warning.gd` | 144 | 29 checks / 0 failures | 0 |

- **Error lines:** no log has a `SHADER ERROR`, `SCRIPT ERROR` or a `"FAIL"` line. The only other output is the `ObjectDB instances were leaked` warning and `resources still in use` error at exit, which CLAUDE.md records as already there before A5.
- **Per-tick MD5s:** 30 fps `35385bc4a519009a685ec285b3ba7529`, 60 fps the same, 144 fps the same. So the 601-tick `warning` sequence for all five forks is identical at all three rates.
- **Evidence:** `evidence/fork-warning-30fps-1793145719.json`, `-60fps-1793145721.json` and `-144fps-1793145723.json`, named with the measured fps.

## Fixes made under the standing approval

None. The only ordering fix in this run is the one you approved explicitly: `await wait_ticks(5)` in `time_scale_checks()`, after `Engine.time_scale = 1.0`. When I wrote step 7, I put a `wait_ticks(3)` before each read of sampler rows from the start. That was design, not a fix: no check failed for that reason.

There is one thing you should judge. My first step 7 run (30 fps) didn't run at all, because of a GDScript parse error in the code I'd just written: `var ok := ...` at line 589 can't infer a type from Dictionary reads. I changed it to `var ok: bool = ...`, which changes no assertion, and I treated it as part of writing the step rather than as a check failure. If you wanted a parse error to stop the run too, I went past that rule.

## Steps 6 and 7 at all three rates

- **10, a real Esc press mid-SHADOW:** plate 2 held 0.25–0.26 on every paused tick and frame (difference 0.0), and no fork's `t` moved. The first tick after the second Esc rose by exactly 1/96.
- **10b, tree paused (fixture):** plate 3 held 0.25 for 120 ticks (difference 0.0), then rose by exactly 1/84.
- **11, time scale 0.5:** the ramp took 96 ticks, against 96 and 96 at 1.0. It lasted 0.8 s of scaled game time (0.7986 s at 144 fps) and 1.6 s of real time. Your rule 5 prediction holds under `--fixed-fps`.
- **12, sauce splat mid-SHADOW (real D and Space):** the tick before the splat read 0.375 at 30 fps and 0.385 at 60 and 144. The splat tick read 0.0, with `held = true` and `t = 0`.
- **13, after the re-form:** every tick through SPLAT and REFORM read 0.0, and so did the `restart_at_safe()` tick. The next SHADOW started at exactly 1/96, 132 ticks later, not at the interrupted 0.375.
- **14, fork splat (the `hold_pending` path, fork in HOLD on the hit tick):** after release, the next SHADOW again started at exactly 1/96.

## What the test proves

All of this is headless, through the real session loop, at 30, 60 and 144 fps:
- **Shader:** it parses, with exactly `warning`, `warn_color` and `strength`, the right types and range hints. The defaults, the modes and the colour line are in the source.
- **Materials:** each fork has its own material, none is the base `.tres` object, and all share one `Shader`.
- **Values:** `warning` is exactly `(p − safe + 1)/shadow` during SHADOW and 0 otherwise, on every tick, at every rate, with no one-tick lag.
- **Rules:** the frame-rate-independent duration (rule 2), the starting values (rule 4), pause and time scale (rule 5), the zero on the hold tick (rule 6), the restart from 1/n (rule 3) and the per-fork independence (rule 7).
- **The checks can fail:** a one-tick-late sequence fails check 7, and a ramp counted in frames fails rule 2 at 30 and 144.

## What it cannot prove headlessly

- **Anything drawn.** It can't show that the sprite really renders with the material, the colour or pixel values, what `source_color` does in a non-HDR 2D canvas, or whether the GPU clamps a value outside `hint_range`.
- **The values the GPU uses for `strength` and `warn_color`.** They read back `null` because they're unset, so check 4 only shows that no fork has an override.
- **Behaviour without `--fixed-fps`** (real-time frame pacing).
- **WON holding its value.** It's out of scope here, and you planned to watch it by eye.

## Human checks left for you

1. **Captures at `warning` 0.0, 0.5 and 1.0** (`strength` 0.65), sampling P1 (168, 300) and P2 (298, 850) against the §6 table.
2. **`source_color` in 2D:** whether it changes `warn_color` in a non-HDR canvas, from the same captures.
3. **The `warning = 2.0` capture:** whether `hint_range` clamps it on the GPU (§10.7).
4. **Normal play:** several warnings on the real background. Is the glow readable, and does the fork still read as a fork?
5. **Glow on and off, side by side:** the silhouette, the shadow ellipse, the jelly, plates, sauce and HUD unchanged.
6. **The intro pan in a windowed run:** the plate 5 and 6 forks visibly half amber.
7. **Contrast against the real room pixel** behind the fork (§6).
8. **WON:** that `warning` holds its value when the jelly reaches the dome (Revision 1).

## State of the tree

- **Commits:** you committed steps 1–5 and the first part of step 6 between turns (0b5934f, ffe81f0).
- **Uncommitted:** the check-11 wait and the step 7 code in `godot/tests/test_fork_warning.gd` (+78 lines), plus the refreshed logs.
- **Untouched:** I didn't commit, didn't create `test_fork_warning.gd.uid`, didn't run the editor, and didn't touch any shader or the dark-wood `.import` files.