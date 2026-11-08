I made the change and the configuration test passes: **45 checks, 0 failures**, exit 0.

**The diff:** two one-line edits.
- `godot/effects/dome_glints.tscn` line 26: `Gradient_life` offsets changed from `(0, 0.2, 0.75, 1)` to `(0, 0.08, 0.75, 1)`. The colours line is unchanged.
- `godot/tests/test_dome_glints_config.gd` line 49: `RAMP_OFFSETS` changed from `[0.0, 0.2, 0.75, 1.0]` to `[0.0, 0.08, 0.75, 1.0]`. `RAMP_COLORS` and every other expectation are unchanged.

**The test run:** `./scripts/run-test.sh test_dome_glints_config.gd 60`
- Last line: `DOME GLINTS CONFIG: 45 checks / 0 failures`.
- `process.color_ramp.gradient.offsets` read back as `[0.0, 0.08, 0.75, 1.0]`. The colours read back unchanged.
- The output had no SCRIPT or SHADER ERROR.

**Files the test run changed:**
- `logs/test_dome_glints_config_60fps.log` is tracked, and the wrapper rewrote it. It appears in `git diff`, but only the `color_ramp` offsets line changed.
- The test may also have written a new untracked `evidence/dome-glints-config-*.json`, as earlier runs did. I haven't checked for one.

Nothing else was touched: not the r0 captures, the preview, gameplay code, the brief, other settings or tests, or any `.gdshader` file. Nothing is committed. It's ready for you to recapture.