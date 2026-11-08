I changed the push curve and its expected value in the config test, and the config test passes: **51 checks, 0 failures** at 60 fps. Nothing is committed.

## Diff

```diff
--- a/godot/effects/land_puff.tscn
+++ b/godot/effects/land_puff.tscn
 [sub_resource type="Curve" id="Curve_radial"]
-_data = [Vector2(0, 1), 0.0, -5.0, 0, 1, Vector2(0.2, 0), -5.0, 0.0, 1, 0]
-point_count = 2
+_data = [Vector2(0, 1), 0.0, 0.0, 0, 1, Vector2(0.18, 1), 0.0, -50.0, 1, 1, Vector2(0.2, 0), -50.0, 0.0, 1, 0]
+point_count = 3

--- a/godot/tests/test_land_puff_config.gd
+++ b/godot/tests/test_land_puff_config.gd
-const RADIAL_CURVE := [Vector2(0.0, 1.0), Vector2(0.2, 0.0)]
+const RADIAL_CURVE := [Vector2(0.0, 1.0), Vector2(0.18, 1.0), Vector2(0.2, 0.0)]
```

**How to read `_data`:** Godot stores each curve point as five values: the position, the slope going in, the slope going out, and the in and out modes (1 = linear). The new curve is flat at 1.0 from 0 to 0.18 of life. It then drops linearly to 0 at 0.2, a slope of −1 / 0.02 = −50. I followed the same format as the existing scale curve on line 23.

**What the test checks:** it reads back only the curve's point positions, not the slopes. So the test confirms the three points but not that the segments are linear. The slopes are as shown in the diff.

## Real output of `./scripts/run-test.sh test_land_puff_config.gd 60`

All 51 lines are `PASS`. The two relevant ones and the summary:

```
{"id":"process.radial_accel_curve.points","observed":{"expected":"[Vector2(0, 1), Vector2(0.18, 1), Vector2(0.2, 0)]","got":"[Vector2(0, 1), Vector2(0.18, 1), Vector2(0.2, 0)]"},"status":"PASS"}
{"id":"process.radial_accel_min","observed":{"expected":"4000.0","got":"4000.0"},"status":"PASS"}
{"id":"process.radial_accel_max","observed":{"expected":"6500.0","got":"6500.0"},"status":"PASS"}
LAND PUFF CONFIG: 51 checks / 0 failures
```

- The tool did not report a non-zero exit, and the wrapper forces exit 1 if the log contains a SCRIPT or SHADER ERROR.
- I didn't print the exit code itself, because the extra `echo "EXIT=$?"` was denied.
- The log is in `logs/test_land_puff_config_60fps.log`.

## What I didn't touch

Every other effect setting, the brief, the preview, the driver, every other test and every `.gdshader` file are unchanged. I ran no other suite.

**The brief is now out of date:** its settings table still lists the old curve, `1.0` at 0.0 → `0.0` at 0.2, so it needs a dated revision from you.

Ready for your recapture. If my estimates hold, frame 15 should show a fan mostly 5–35 px beyond the jelly's visible edges, and frame 12 should still show crumbs mostly behind the jelly.