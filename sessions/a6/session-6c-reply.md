I added `godot/tests/test_dome_glints_state.gd` and ran it once at 60 (fixed-fps; it doesn't wait on audio). **Result: 27 checks, 0 failures, exit 0.** The command was `./scripts/run-test.sh test_dome_glints_state.gd 60`, and it printed `DOME GLINTS STATE TESTS: 27 checks / 0 failures`. The full output is above. The test exposed no gameplay or driver issue, so there was nothing to stop and report.

The log (`logs/test_dome_glints_state_60fps.log`) has no SCRIPT or SHADER ERROR and no "busy setting up children" error. Its only other lines are the "ObjectDB instances were leaked" and "resources still in use" exit messages that every suite already prints.

This step adds only that one new file (diff above). The driver change from Step 1 is your commit `2ab1d9b`. I left the driver, the effect scenes, the previews, the shaders and every existing test unchanged. The run also wrote an evidence file, `evidence/dome-glints-state-<timestamp>.json`, as every suite does. Nothing is committed.

**How it drives the game:** only key events through `Input.parse_input_event`. It reuses `route_driver.gd`'s jump marks and its read-only `plan()`, and turns each decision into D and Space key presses instead of using `test_control`. The test never calls `restart()`, sets `emitting` or touches the driver. The only things it writes are `get_tree().paused` (B5) and the emitter's `visible` (B6).

**What each check proves, with the run's own numbers:**
- **B1:** before any tick, there is exactly one `DomeGlints`. Its parent is the session, `emitting` is `true`, and it sits at `(2341.891, 450.0)`, exactly the brief's point. It stays on through 60 ticks of the intro.
- **B4, Esc pause:** the state is `PAUSED` for 60 ticks, and `emitting` and `can_process()` stay `true`.
- **B5, tree pause:** for 60 ticks `emitting` stays `true` and `can_process()` is `false`. Both are `true` again after unpausing.
- **B6, hidden:** for 60 ticks `emitting` stays `true` and `visible` stays `false`, so the driver never touched it. After showing it again it is still emitting.
- **B2:** both runs reached `WON` by keys with 0 splats (762 and 499 ticks). On each win tick (frames 1033 and 1600), `emitting` is `false`, and on the tick before it was `true`. The node stays in the tree, and `emitting` stays `false` for all 66 `WON` ticks of each run.
- **B3:** on the first tick after each replay (frames 1099 and 1666), the state is `PLAYING` and `emitting` is `true`.
- **B7, as you asked:** the emitter is the same object on every one of the 1,667 ticks and after both replays (instance ID `74440510978` throughout). Only one was ever created.
- **A2 while WON, as you asked:**
  - On each win tick, the puff count, the `SFX-LAND` count and `just_landed` were unchanged (5 → 5, then 10 → 10; `just_landed` false).
  - Through every `WON` tick, including Space and a held D before the prompt (which the session ignored), no new puff appeared.
  - Over the whole test, the 10 puff frames equal the 10 `SFX-LAND` frames.
- **Every tick:** `emitting == (state != WON)` held on all 1,667 ticks. `amount` stayed 24 and `amount_ratio` stayed 1.0, so the driver changes neither.

**What it can't prove headlessly:** the dummy renderer draws nothing and runs no particle process, so the test shows only node state, not the look. These stay for you in the game window:
- that glints are visible at steady density on the first intro frame;
- that after the win the live glints rise and fade, and the dome is empty about 2.4 s later;
- that `restart()` re-applies preprocess on replay (predicted failure 5). The test can't even tell `restart()` apart from `emitting = true`; only the driver code shows which is used;
- whether `restart()` visibly clears glints left over from the win when you replay quickly;
- that glints visibly drift during Esc pause;
- that glints visibly freeze under tree pause and carry on from the same state. `can_process() == false` is the switch that pauses them, not the freeze itself;
- that glints are present when shown again;
- the `visibility_rect` at the screen edge (predicted failure 6), contrast and scale.

I haven't run the existing suites in this step. That's Step 3 when you approve it, though your commit message for `2ab1d9b` records your own 13 runs against the driver, all with 0 failures.