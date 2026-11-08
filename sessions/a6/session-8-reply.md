I wrote `godot/tests/cost_effects.gd` (new file, nothing else changed, nothing committed) and ran it. The script works and the effects come out as predicted, but one set of its columns is wrong: the engine-monitor columns repeat the same values across cases, and you should ignore them.

**Example 09 is not in this repository.** No file outside `sessions/` contains it; the only "chapter" mentions are about the Blender MCP command. I based the script on this repo's own tests instead: loading `main.tscn` and skipping the intro with a real Enter key event comes from `test_land_puff_state.gd`, and reporting the renderer comes from `probe_headless.gd`. Timing uses Godot's `Time.get_ticks_usec()` and `Performance` monitors.

**How the cases are set up:**
- **Empty scene:** a bare `Node2D`.
- **Game, both effects off:** `main.tscn` in `PLAYING`, with the effects driver and its `DomeGlints` removed by the test after loading.
- **Effect A:** the effects-off game plus two `LandPuff` instances from the unchanged scene at the jelly's feet, 10 ticks apart. Each is `restart()`ed every 24 ticks, so 2 bursts (the brief's A5 limit) are always alive.
- **Effect B:** the effects-off game but keeping the driver's `DomeGlints`, emitting at steady state.
- **Measurement:** 5 rounds, with the case order rotated each round, of 300 frames per case after 60 warm-up frames.

**Real output** (`./scripts/run-test.sh cost_effects.gd 60 300`, exit 0):
```
COST display server: headless
COST rendering method: gl_compatibility
COST rendering driver: opengl3
COST physics ticks/s: 60  max_fps: 0
COST empty     wall 0.0033 ms (sd 0.0005, min 0.0030, p95 0.0040, max 0.0070; round means 0.0031-0.0034) | engine process 107.4364 ms (sd 57.5007) | engine physics 0.7552 ms (sd 0.4660)
COST game_off  wall 0.2119 ms (sd 0.0729, min 0.0790, p95 0.3530, max 0.5560; round means 0.2102-0.2139) | engine process 85.0139 ms (sd 64.0156) | engine physics 0.5770 ms (sd 0.4816)
COST effect_a  wall 0.2144 ms (sd 0.0728, min 0.0800, p95 0.3550, max 0.5550; round means 0.2125-0.2165) | engine process 107.4364 ms (sd 57.5007) | engine physics 0.7552 ms (sd 0.4660)
COST effect_b  wall 0.2142 ms (sd 0.0743, min 0.0870, p95 0.3620, max 0.5280; round means 0.2122-0.2162) | engine process 107.3504 ms (sd 57.4950) | engine physics 0.7566 ms (sd 0.4656)
COST compare game_off  vs empty    : diff +0.2086 ms, larger round-mean spread 0.0037 ms -> differ
COST compare effect_a  vs empty    : diff +0.2111 ms, larger round-mean spread 0.0040 ms -> differ
COST compare effect_b  vs empty    : diff +0.2109 ms, larger round-mean spread 0.0041 ms -> differ
COST compare effect_a  vs game_off : diff +0.0024 ms, larger round-mean spread 0.0040 ms -> SAME within spread
COST compare effect_b  vs game_off : diff +0.0023 ms, larger round-mean spread 0.0041 ms -> SAME within spread
COST compare effect_b  vs effect_a : diff -0.0002 ms, larger round-mean spread 0.0041 ms -> SAME within spread
COST EFFECTS: 4 cases x 5 rounds x 300 frames; control separates: true
WARNING: 8 ObjectDB instances were leaked at exit ...
ERROR: 4 resources still in use at exit ...
```
The last two lines are the leak messages every suite already prints at exit. They are not SCRIPT or SHADER errors. The script also wrote `evidence/cost-effects-<time>.json`.

**What it shows:**
- **The engine-monitor columns are wrong, so ignore them.** Empty and Effect A report exactly the same values (107.4364 ms, sd 57.5007; physics 0.7552, sd 0.4660), and an empty scene cannot cost 107 ms per frame when frames arrive every 0.003 ms. My understanding, which I have not checked in the engine source, is that `TIME_PROCESS` and `TIME_PHYSICS_PROCESS` update about once per real second and hold the worst frame of that second. The whole run lasts only a few seconds, so these columns mostly capture scene loading, not the cases. I recommend removing them from the script; I haven't done that yet.
- **The wall-time column is measuring the game, not the script.** The empty scene (0.0033 ms) and the effects-off game (0.2119 ms) differ by 0.21 ms, about 56 times the larger round-to-round spread. With `--fixed-fps` headless, frames run uncapped (`max_fps: 0`), so wall time per frame is real CPU work.
- **Effects A and B each match the effects-off game within its spread.** They add +0.0024 and +0.0023 ms, against a round-to-round spread of 0.0040 ms. This agrees with the brief's prediction (under 0.02 ms for A, under 0.01 ms for B). Here, two cases reporting the same value is the predicted result, not a sign that the script is measuring itself.

**Limits of this run:**
- The Effect A case reuses its two puffs with `restart()`. It does not include the cost of creating and freeing a puff on each landing, which the brief names as A's only CPU work.
- The driver is removed in every game case, so its own per-tick cost isn't measured.
- The renderer is reported as `opengl3`, not a dummy, so this run does not confirm the "dummy renderer" fact in CLAUDE.md's Unconfirmed list. The name may just reflect the project setting.

I ran each command on its own; no compound commands.