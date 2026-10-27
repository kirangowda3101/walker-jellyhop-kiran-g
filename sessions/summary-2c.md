I stopped at step 6, as you asked: one check failed at 30 fps (25 checks, 1 failure, exit 1). I haven't run step 6 at 60 or 144, and step 7 (real-input splats) and step 8 (final run and summary) are not started. As far as I can tell this is a bug in my test, not in the driver, and I've changed nothing to get past it.

## Step 5 (done): both approved fixes

- **Window start:** the search for the first PLAYING frame now runs after the 600-tick wait.
- **Frame period:** `measure_fps()` takes the median `_process` delta of the INTRO frames and sets `fps = round(1/delta)`. The broken `fixed_fps()` command-line lookup is gone. The evidence JSON now records `measured_fps`, `measured_frame_delta_s` and the INTRO delta min/max, and the files are named with the measured rate (`fork-warning-30fps-…`, `-60fps-…`, `-144fps-…`).
- **Unchanged:** no assertion, tolerance or expected value. If no PLAYING frame is found, the frame window is empty and check 9 still fails on its existing `frames > 0` condition.

| fps | Result | Per-tick MD5 |
|---|---|---|
| 30 | 21 checks / 0 failures | `35385bc4a519009a685ec285b3ba7529` |
| 60 | 21 checks / 0 failures | `35385bc4a519009a685ec285b3ba7529` |
| 144 | 21 checks / 0 failures | `35385bc4a519009a685ec285b3ba7529` |

The three MD5s are identical, so the 601-tick sequence for all five forks is the same at all three rates. Per frame, every ramp's duration is within one frame period. At 60 fps every ramp's first frame reads 1/n and its last reads exactly 1.0. At 30 fps the last frame reads (n−1)/n, because each frame spans two ticks (rule 1 says this can happen).

## Step 6: what I added and what it showed at 30 fps

**Added:** a `key()`/`tap()` helper that sends real key events like `test_keyboard.gd`, a `hold_report()` helper, `pause_checks()` (10), `tree_pause_checks()` (10b) and `time_scale_checks()` (11). The 1.0 baseline for check 11 comes from the idle window only.

| Check | Result | What it showed |
|---|---|---|
| 10, real Esc pause | PASS | Plate 2 held 0.2604 for 128 ticks and 64 frames, max difference 0.0, no fork's `t` moved. The first tick after the second Esc rose by exactly 1/96. |
| 10b, tree paused | PASS | Plate 3 held 0.25 for 120 ticks and 60 frames, difference 0.0. The first tick after unpausing rose by exactly 1/84. |
| 11, same tick count at 0.5 | PASS | Plate 2 ramp: 96 ticks at time scale 0.5; 96 and 96 at 1.0. |
| **11, game time halved** | **FAIL** | `scaled_game_seconds: -1.0`: no per-frame ramp end was found. |

**Why 11 failed:** it's the same ordering problem I fixed in step 5. `wait_until()` returns at `process_frame`, which is before the frame sampler records that frame. So when the tick ramp had ended, the frame that shows `warning` back at 0 had not been recorded yet. I then searched the frame rows straight away, found no end frame, and the check got −1.

The one frame delta it did record supports your prediction: 0.016667 s at time scale 0.5, which is half of 1/30 s. That's only an observation, though, because the check failed.

**Proposed fix (needs your approval):** in `time_scale_checks()`, add `await wait_ticks(5)` after `Engine.time_scale = 1.0` and before reading the frame rows, so the sampler has recorded the end frame. No assertion, tolerance or expected value would change. If you approve, I'll make that one change, rerun step 6 at 30, 60 and 144, and then continue with steps 7 and 8.

Nothing is committed, no `.uid` was created, the editor wasn't run, and the dark-wood `.import` files are untouched.