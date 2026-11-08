I built Effect B and its configuration test. The test passed when I ran it through `./scripts/run-test.sh` at 60: **`DOME GLINTS CONFIG: 45 checks / 0 failures`**. The full output is above. The wrapper exited 0 and there was no `SCRIPT ERROR` or `SHADER ERROR` line.

## What I added (four new files, nothing else touched)

**`godot/effects/dome_glints.tscn`**: the effect. The root is one `GPUParticles2D` named `DomeGlints` with no children, because the brief uses a single emitter. All settings are in the scene file: the node, a `GradientTexture2D` 32 × 32 radial texture, a `CanvasItemMaterial` with `blend_mode = 1` (add), and a `ParticleProcessMaterial` with `emission_shape = 3` (box). Every value is the brief's. Every property name is one CLAUDE.md lists as confirmed in 4.7.2, so I had no name I was unsure of. The file has no fixed seed. Two choices were mine:
- The four scale-curve points are joined by straight lines, as in Effect A. The brief gives the points but not the curve shape between them.
- Integers stand in for named constants in the scene file (`3` for box, `1` for add, `1` for radial). The test compares each one against the named constant, so a wrong number would fail.

**`godot/tests/test_dome_glints_config.gd`**: a copy of Effect A's test structure. It reads every value back from the loaded resources and compares it with the brief's value. The box emission shape has its own group, `process.box.emission_shape` and `process.box.emission_box_extents`. The test also checks:
- the additive material and its blend mode;
- both gradients;
- the scale curve's points;
- `use_fixed_seed == false`.

Each run writes `evidence/dome-glints-config-<time>.json`.

**`godot/previews/dome_glints_preview.tscn` + `.gd`**: the preview, at the game's real coordinates and scale:
- **Camera:** at (2013.8412, 360), where the intro pan starts.
- **Background:** the room, table tiles, plate 6, the dome at (2311.8912, 521), and a still `CHAR-IDLE` jelly in the bare gap beside the dome. Plate 6 is my addition: it is on screen in that camera view in the game, though the brief doesn't name it.
- **Glints:** at (2311.8912, 450), which is the dome centre and `TABLE_TOP − 70`. On this instance only: `emitting = false`, `use_fixed_seed = true`, `seed = 2001`.
- **Timing:** the script calls `restart()` at frame 10 and sets `emitting = false` at frame 70. It does nothing else.

I didn't wire anything into gameplay, and I didn't touch `effects_driver.gd`, `session.gd`, Effect A or its tests, or any `.gdshader` file. Nothing is committed.

## Capture command (yours to run, windowed)

Run these from the repository root, one at a time:

```sh
mkdir -p captures/dome_glints/r0
```
```sh
godot --path godot --write-movie "$PWD/captures/dome_glints/r0/frame.png" --fixed-fps 30 --quit-after 150 res://previews/dome_glints_preview.tscn
```

- `--write-movie …/frame.png` turns on Movie Maker, which saves every frame as a numbered PNG. Strip frame N is `frameNNNNNNNN.png`, counted from 0.
- `--fixed-fps 30` makes each frame exactly 1/30 s of game time.
- `--quit-after 150` stops after 150 frames, the number the brief gives.

The strip frames to keep are 10, 12, 40, 70, 85 and 145.

**Still unchecked:** whether `restart()` re-applies preprocess, so the dome is already full at frame 10 (predicted failure 5). Only the strip will show that, because the headless test reads settings and draws nothing.