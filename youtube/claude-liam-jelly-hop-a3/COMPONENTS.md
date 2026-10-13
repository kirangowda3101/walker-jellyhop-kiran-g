# COMPONENTS — A3 film

`gamedev-evidence.json` inventories every file under `godot/` at revision `948ab6a` (`.godot/` and `.uid` excluded by the checker): 13 in components, 63 excluded. The exclusions are the Assignment 2 slice files, unchanged since `7a48ea8` and explained in the A2 film; they are listed with that reason. `./art godot-gamedev --check` passes; it verifies hashes, line ranges and associations, not whether the explanations are right.

| Component | Files | Beats |
|---|---|---|
| a3-models | `assets/models/{fork,dome,platform}.glb` and `.import` | B02, B04, B05, B07, B09 |
| a3-showcase | `showcase/a3_assets.tscn` | B06 → B07 (code → result) |
| a3-check | `tests/test_a3_assets.gd` | B08 → B09 (code → result) |
| a2-placement | `project.godot`, `game/main.tscn`, `game/session.gd`, `game/slice_tuning.gd`, `features/fork/fork.gd` (read only, for the placement question) | B10 |

Code → result pairs: B06 (scene lines 27–37) → B07 (Kiran's screenshot 19); B08 (check lines 7–12) → B09 (headless log numbers beside the brief).
