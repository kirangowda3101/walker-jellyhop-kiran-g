# COMPONENTS — A5 film

`gamedev-evidence.json` inventories every file under `godot/` at revision `77a6d10` (`.godot/` and `.uid` excluded): 34 in components, 74 excluded. The exclusions are Assignment 2 and 3 files that A5 did not change, explained in the earlier films. `fork.gd` (changed by A5) is in `a5-fork-warning`. `./art godot-gamedev --check` passes; it verifies hashes, line ranges and associations, not whether the explanations are right.

| Component | Files | Beats |
|---|---|---|
| a5-fork-warning | `shaders/fork_warning.gdshader`, `materials/fork_warning.tres`, `features/fork/fork.gd` | B02–B07 |
| a5-fork-test | `tests/test_fork_warning.gd`, `tests/probe_headless.gd` | B08–B10 |
| a5-table-wood | `shaders/table_wood.gdshader`, both wood `.tres`, `showcase/a5_materials.tscn`, Dark Wood PNGs, `.import` files, ATTRIBUTION.md | B02, B11, B12, B15, B16, B18 |
| a5-hint-experiment | `shaders/hint_experiment.gdshader`, both hint `.tres`, `showcase/hint_experiment.tscn`, hint strip PNG and `.import`, `tools/make_hint_strip.gd`, `project.godot` | B13, B14 |
| a5-generated | `shaders/standard_generated.gdshader`, `scratch/standard_scratch.tscn` | B17, B19 |
| a5-material-checks | `MATERIALS.md`, `tests/test_materials.gd`, `tests/normal_map_check.gd`, `tests/calibrate_normal_check.gd` | B10, B16 |
| a5-captures | `tools/capture_a5.gd`, `tools/capture_shared.gd` | B05, B12, B14, B18 |

Code → result pairs: B04 (fork shader 1–10) → B05 (controlled captures); B06 (fork.gd 221–231) → B07 (scripted in-play capture); B08 (test 134–147) → B09 (headless logs); B11 (board material 8–18) → B12 (shared captures); B13 (hint shader 1–15) → B14 (hint captures, both renderers); B15 (table shader 3–14) → B16 (wood capture and data checks).
