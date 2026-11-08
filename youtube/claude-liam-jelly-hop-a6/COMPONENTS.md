# COMPONENTS — A6 film

`gamedev-evidence.json` inventories every file under the snapshot's `godot/` at revision `8004dea` (`.godot/` and `.uid` excluded): 17 in components, 105 excluded. The exclusions are files from Assignments 2–5 that A6 did not change (`git diff a5 8004dea -- godot` lists the A6 files), explained in the earlier films. `game/session.gd` is included because A6 added line 63; `tests/route_driver.gd` and `project.godot` are included because the film's capture and price beats use them. `./art godot-gamedev --check` passes; it verifies hashes, line ranges and associations, not whether the explanations are right.

| Component | Files | Beats |
|---|---|---|
| a6-land-puff | `effects/land_puff.tscn`, `previews/land_puff_preview.tscn`, `previews/land_puff_preview.gd` | B02, B03, B05–B09, B11 |
| a6-dome-glints | `effects/dome_glints.tscn`, `previews/dome_glints_preview.tscn`, `previews/dome_glints_preview.gd` | B02, B12–B16, B18, B19 |
| a6-driver | `effects/effects_driver.gd`, `game/session.gd` | B10, B11, B17, B18 |
| a6-process-shader | `shaders/particles_generated.gdshader` | B03, B04, B20 |
| a6-tests | the two config tests, the two state tests, `tests/route_driver.gd` | B19, B21, B22 |
| a6-price | `tests/cost_effects.gd`, `tests/check_lifecycle_peak.gd`, `project.godot` | B04, B23 |

Code → result pairs: B06 (land_puff.tscn 61–73) → B07 (strip r0); B08 (land_puff.tscn 15–20) → B09 (r1 strips and comparison); B10 (effects_driver.gd 21–26) → B11 (scripted capture, Effect A); B13 (dome_glints.tscn 32–40) → B14 (strip r0); B15 (dome_glints.tscn 25–30) → B16 (r1 strips and comparison); B17 (effects_driver.gd 27–34) → B18 (scripted capture, Effect B).
