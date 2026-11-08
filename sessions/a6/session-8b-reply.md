I updated `godot/tests/cost_effects.gd` and changed no other file. I ran the wrapper once and the run passed (exit 0); the frees did happen. Nothing is committed.

**What changed:**
1. The old `effect_a` case is now `effect_a_restart`, otherwise unchanged.
2. New case `effect_a_lifecycle`: on a 24-tick cycle, at tick 0 and tick 10, the test creates a new `land_puff.tscn` puff, using the driver's steps in the driver's order (`effects_driver.gd` lines 22–26). It counts puffs created during the measured frames, and counts frees with each puff's `tree_exited` signal. It prints both counts for each round and in total, and puts them in the JSON.
3. The comparison wording is now "not distinguishable within spread", in the printout, the closing warning and the JSON. The JSON key is now `not_distinguishable_within_spread`, and a new `comparisons` list gives each pair's result in the same words.
4. The header now says the effects driver is removed from every game case, so its own per-frame work is in no case, and that `effect_a_lifecycle` copies the driver's spawn code inside the test. It also notes one difference: the test spawns after `process_frame`, while the driver spawns in `_physics_process`.

The empty control, `game_off`, `effect_b`, 5 rounds, 60 warm-up frames and 300 measured frames are unchanged.

**Real output** (`./scripts/run-test.sh cost_effects.gd 60 300`, exit 0):
```
COST display server: headless
COST rendering method: gl_compatibility
COST rendering driver: opengl3
COST physics ticks/s: 60  max_fps: 0
COST effect_a_lifecycle round: puffs created 25, freed 24 during 300 measured frames
COST effect_a_lifecycle round: puffs created 25, freed 24 during 300 measured frames
COST effect_a_lifecycle round: puffs created 25, freed 24 during 300 measured frames
COST effect_a_lifecycle round: puffs created 25, freed 24 during 300 measured frames
COST effect_a_lifecycle round: puffs created 25, freed 24 during 300 measured frames
COST empty              wall 0.0033 ms (sd 0.0006, min 0.0020, p95 0.0040, max 0.0150; round means 0.0032-0.0033) | engine process 97.5130 ms (sd 51.5274) | engine physics 0.6248 ms (sd 0.3886)
COST game_off           wall 0.2142 ms (sd 0.0733, min 0.0850, p95 0.3580, max 0.5240; round means 0.2121-0.2159) | engine process 97.3926 ms (sd 51.4955) | engine physics 0.6248 ms (sd 0.3886)
COST effect_a_restart   wall 0.2127 ms (sd 0.0734, min 0.0800, p95 0.3550, max 0.5090; round means 0.1972-0.2183) | engine process 105.9324 ms (sd 56.4140) | engine physics 0.7440 ms (sd 0.4578)
COST effect_a_lifecycle wall 0.2160 ms (sd 0.0730, min 0.0940, p95 0.3570, max 0.5450; round means 0.2144-0.2176) | engine process 97.6448 ms (sd 51.5620) | engine physics 0.6228 ms (sd 0.3885)
COST effect_b           wall 0.2161 ms (sd 0.0729, min 0.0740, p95 0.3580, max 0.5560; round means 0.2150-0.2168) | engine process 114.0494 ms (sd 41.2753) | engine physics 0.7566 ms (sd 0.3616)
COST effect_a_lifecycle total: puffs created 125, freed 120 during 1500 measured frames (5 rounds)
COST compare game_off           vs empty             : diff +0.2109 ms, larger round-mean spread 0.0038 ms -> differ
COST compare effect_a_restart   vs empty             : diff +0.2094 ms, larger round-mean spread 0.0211 ms -> differ
COST compare effect_a_lifecycle vs empty             : diff +0.2127 ms, larger round-mean spread 0.0032 ms -> differ
COST compare effect_b           vs empty             : diff +0.2128 ms, larger round-mean spread 0.0018 ms -> differ
COST compare effect_a_restart   vs game_off          : diff -0.0015 ms, larger round-mean spread 0.0211 ms -> not distinguishable within spread
COST compare effect_a_lifecycle vs game_off          : diff +0.0018 ms, larger round-mean spread 0.0038 ms -> not distinguishable within spread
COST compare effect_b           vs game_off          : diff +0.0019 ms, larger round-mean spread 0.0038 ms -> not distinguishable within spread
COST compare effect_a_lifecycle vs effect_a_restart  : diff +0.0033 ms, larger round-mean spread 0.0211 ms -> not distinguishable within spread
COST compare effect_b           vs effect_a_restart  : diff +0.0034 ms, larger round-mean spread 0.0211 ms -> not distinguishable within spread
COST compare effect_b           vs effect_a_lifecycle: diff +0.0001 ms, larger round-mean spread 0.0032 ms -> not distinguishable within spread
COST EFFECTS: 5 cases x 5 rounds x 300 frames; control separates: true
WARNING: 8 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
ERROR: 4 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:822)
```

**What the output shows:**
- **The frees happened:** 125 puffs created and 120 freed in the measured frames. Each puff freed itself through `finished` → `queue_free`, so `finished` fires in a headless run.
- **Why created and freed differ by one per round:** the free count includes puffs created during warm-up and freed in the measured window. Puffs created late in the window are still alive when it ends. So the two counts are not a one-to-one match within a window.
- **One `effect_a_restart` round ran fast** (round means 0.1972–0.2183 ms). That widened its spread to 0.0211 ms, about five times the other game cases' spread, so its comparisons are weaker than the rest.
- **The engine-process and engine-physics columns are still not usable.** The `empty` and `game_off` physics values are identical (0.6248, sd 0.3886). I left them in because you didn't ask for them to change.
- **One header line still needs a decision.** It says "Headless the renderer is a dummy", but this run reports `opengl3`, so that line is not confirmed. I left it as it was.

As you asked, I stopped after the one run.