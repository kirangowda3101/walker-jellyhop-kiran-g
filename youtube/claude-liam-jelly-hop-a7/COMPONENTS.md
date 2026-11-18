# COMPONENTS — A7 film

`gamedev-evidence.json` inventories every file under the snapshot's `godot/` at revision `c1bbb13` (`.godot/` and `.uid` excluded): 22 in components, 118 excluded. The exclusions are files from Assignments 2–6 that A7 did not change (`git diff a6 c1bbb13 -- godot` lists the A7 files), explained in the earlier films. `CHAR-SCOOT-A.png`, `CHAR-SCOOT-B.png` (the sheet's sources) and `CHAR-IDLE.png` (the rig's source) are included though unchanged, because the clips are built from them. `./art godot-gamedev --check` passes; it verifies hashes, line ranges and associations, not whether the explanations are right.

| Component | Files | Beats |
|---|---|---|
| a7-scoot | the sheet, its `.import` and ATTRIBUTION.md, CHAR-SCOOT-A/B.png, `animations/scoot.tres`, `tools/make_scoot_sheet.gd`, `previews/scoot_preview.*` | B02, B04, B05, B06 |
| a7-land | `animations/land.tres`, `assets/art/CHAR-IDLE.png`, `previews/land_preview.*` | B02, B18–B21 |
| a7-visuals-scene | `features/player/player_visuals.tscn` | B03, B14, B15 |
| a7-state-machine | `features/player/player.gd` (the appended visual layer) | B10–B13, B16, B17 |
| a7-tests | the six `test_a7_*.gd` and `probe_a7_entry_order.gd` | B07, B08, B15, B22–B24 |

Code → result pairs: B03 (player_visuals.tscn 20–29) → B04 (the sheet); B05 (scoot.tres 5–17) → B06 (scoot fixture strip); B07 (land read-back 166–172) → B08 (M1); B10 (player.gd 200–212) → B11 (scripted capture); B12 (player.gd 215–227) → B13 (scripted capture, interrupts); B14 (player_visuals.tscn 61–67) → B15 (the one-tick error and fix, from logs); B16 (player.gd 227–236) → B17 (scripted capture, hand-off); B19 (land.tres 8–19) → B20 (land strips r0, r1).
