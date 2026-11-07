I've written and run the landing-puff state test. The final run passes 24 checks with 0 failures at 60 (`./scripts/run-test.sh test_land_puff_state.gd 60`, exit 0), and the measured plate-edge gap is **10 ticks (0.167 s)**, inside the brief's 9–12. The first run failed one check because of my own route, which I fixed (details below). Cleanup worked, so no fallback timer was needed. I didn't change the driver, the effect settings, the existing tests or any `.gdshader` file, and I didn't commit.

## The diff

The only change is one new, untracked file: `godot/tests/test_land_puff_state.gd`, 293 lines (shown in full above). Step 1 is already in HEAD as your commits 852f6b0 and 9f6a1ef, and the driver and `session.gd` don't differ from HEAD.

## First run: 23 checks pass, 1 fails, and it was my route

- **What failed:** `A4-gap-in-brief-range-9-12` measured **23 ticks**.
- **Why:** the puff log showed my run-up target (`RUN_LEFT_TO_X = 120`) was past plate 1's left edge (x 135.5). The jelly walked off onto the table. Running back right, it pressed against plate 1's side (`hop_x` 135.49) and hopped from a standstill, landing 75 px short of the edge.
- **The fix:** `RUN_LEFT_TO_X` went from 120 to 170, so the run-up stays on the plate, and the run-up start is now logged. I didn't change the brief's 9–12 range or any check.
- **The rerun:** the jelly started its run at x 154.75 and hopped at 161.86. It landed on plate 1 at x 382.66, 2 px inside the edge (384.5), still running. It dropped and landed on the table at x 436.00, 10 ticks later.

## Final results

| Check | Rule | Observed |
|---|---|---|
| A2-none-on-load-and-intro | A2 | 0 puffs, state INTRO, after 60 ticks |
| A2-none-on-intro-skip-respawn | A2 | 0 puffs after Enter (`reset_at`) |
| A1-solo-hop-puff, A6-solo-finished-and-freed | A1, A6 | `finished` fired 24 ticks after spawn; freed |
| A4-route-plate-then-table | A4 setup | first puff at y 497.88 (plate), second at 519.93 (table) |
| A4-gap-inside-one-lifetime / -in-brief-range-9-12 | A4 | gap 10 ticks |
| A4-two-separate-instances, -first-alive-when-second-spawns | A4 | puffs 1 and 2 both alive when puff 2 spawned |
| A4-first-not-restarted, -second-finishes-on-own-schedule | A4 | each finished 24 ticks after its own spawn, same as the solo puff |
| A6-none-left-1s-after-last-landing | A6 | 0 alive, 60 ticks after the last landing |
| A2-none-on-sauce-splat-splat-reform-respawn | A2 | cause `sauce`; 0 puffs through SPLAT, REFORM and the respawn on plate 2 |
| A8-esc-live-puff-finishes, A2-none-while-paused, A8-esc-resumes | A8, A2 | Esc after a puff spawned: puff finished at 24 ticks, no new puff with D and Space held, then PLAYING |
| A8-tree-pause-freezes, -tree-unpause-finishes | A8 | tree paused after a puff spawned: still in the tree, `emitting` true, no `finished` for 60 ticks; finished 84 ticks after spawn (60 paused + 24) |
| A1-one-puff-per-SFX-LAND-every-tick | A1 | puff ticks = SFX-LAND ticks = [116, 263, 273, 372, 543, 687]; 0 mismatching ticks |
| A1-A2-spawned-only-while-playing-and-emitting | A1, A2 | all 6 puffs |
| A3-at-the-jelly-feet | A3 | max distance 0.0 px |
| A7-parent-is-session-never-jelly | A7 (structure) | all 6 puffs |
| A6-none-left-at-end | A6 | 0 alive |

The existing suites all match the baseline with 0 failures and exit 0:
- test_game 25, test_slice 61, test_keyboard 12, test_a3_assets 36, all at 60;
- test_fork_warning 29 and test_materials 108, each at 30, 60 and 144.

No log has a SCRIPT ERROR or SHADER ERROR. The only extra lines are the leak warnings that were already there before A6.

## What happened, for you to record

- **`finished` fires headless.** Your A6 prediction was that it might not. Every puff's `finished` fired exactly 24 ticks (0.40 s) after spawn, and the puff was freed on that tick, so the brief's fallback timer isn't needed headless. This doesn't show what happens in the windowed game.
- **The sauce splat came before touchdown.** `just_landed` was false on the splat tick. So the test covers no puff on a real walk-into-sauce splat. It doesn't cover a landing tick that becomes a splat; that case is covered only because the driver uses the same condition as SFX-LAND.
- **Most puffs alive at once on this route: 2.** That reflects my route, not the game's real A5 peak.

## What the test proves and what it can't

- **It proves**, through the real `main.tscn`, real key events and the real game loop, with the driver never called:
  - one puff per SFX-LAND, on the same tick, every tick;
  - none on load, during the intro, on respawn, on the sauce splat, during SPLAT or REFORM, or while PAUSED;
  - each puff exactly at the jelly's feet;
  - two landings 10 ticks apart make two separate instances, the first neither cut off nor restarted;
  - cleanup within one second;
  - the two pause behaviours, and the session as each puff's parent.
- **It can't prove headlessly:**
  - that crumbs are drawn, whether all 16 appear, or that the two puffs visibly overlap;
  - timing phases, scale, contrast, colour change and variation;
  - the `visibility_rect` and the draw order near the sauce and fork shadows;
  - the real A5 peak, and `finished` in the windowed game.
- **Not tested:** A7 with the jelly actually freed.
- **Still pending:** A2 in WON, for Effect B's real-input run.

## Files changed by the runs

- **Tracked logs:** the wrapper rewrote committed logs, and `git diff` shows changes in `logs/test_game_60fps.log` (the leak lines now appear) and the three `test_fork_warning` logs. Whether to keep or restore them is your call.
- **New untracked files:**
  - `logs/test_land_puff_state_60fps.log`;
  - new `evidence/*.json` files from both state-test runs and the suites;
  - `evidence/land-puff-state-*.json`: the first one is from the failed run, the later one from the passing run.