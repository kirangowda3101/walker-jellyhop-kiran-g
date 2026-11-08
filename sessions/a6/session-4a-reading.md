I compared the r0 strip with the brief's intent and recommend doubling the radial acceleration range (the outward push). I haven't edited anything.

My image crop commands were denied, so I read the frames at full 1280 × 720 without zooming. Crumbs are only a few pixels across at that size, so my reading of small details is rough. Your description and mine agree.

## Frame by frame against the intent

| Frame | Intent (brief) | What r0 shows | Verdict |
|---|---|---|---|
| 10 (+0) | crumbs at most just appearing at the base edges | Faint light specks at the base of both jellies, between the feet | Matches |
| 12 (+2) | clearly out from behind both sides, full size, bright, low | Light specks at the base of both jellies, mostly under the sprite. You saw them clearly on both the plate and the table | Contrast and height match. **"Out from behind both sides" does not** |
| 15 (+5) | a flat fan about one jelly width beyond each side, within ~6 px of the surface | A few tan crumbs just outside each jelly's edge, mostly on the left side. Nothing near a jelly width out | **Fails**: this is the main miss |
| 20 (+10) | nearly stopped, under half size, mostly faded | Nothing visible | Close enough: they are faded and tiny by this point |
| 30, 50 | nothing | Empty. The two files are byte-identical (`cmp`) | Matches |

**Why the crumbs stay under the jelly.**
- **The jelly looks wider than its box.** In these frames the jelly sprite is about 78 px wide (about 221–299 px for the plate jelly), so its visible edge is about 39 px from its centre. The brief sized the effect against the 52 px collision box, which ends 26 px from centre.
- **The ring starts deep under the sprite.** Crumbs are born 18–24 px from the centre.
- **The push is too weak.** Push (`radial_accel_min` / `radial_accel_max`) 4000/6500, fading to 0 by 0.2 of life (80 ms), with damping (the slow-down) at 600 px/s².
  - The push gives the crumbs only about 110–210 px/s of outward speed.
  - My hand calculation puts them 32–52 px from centre at frame +5, and the farthest stop at about 73 px.
  - So most crumbs never clear the 39 px sprite edge. That matches what you saw.

## Proposed change: one setting

| | Old | New |
|---|---|---|
| `radial_accel_min` / `radial_accel_max` (one row in the brief's table) | `4000.0` / `6500.0` | `8000.0` / `13000.0` |

The push curve stays the same shape, so the kick still happens only in the first 80 ms. It just pushes twice as hard.

If you count the min/max pair as two settings, the single-setting alternative is `radial_accel_curve`: `(0, 1), (0.2, 0)` → `(0, 1), (0.18, 1), (0.2, 0)`. That keeps full strength through the same 80 ms and gives about 1.9× the speed, but it is slightly weaker at frame 12.

**What each frame should show after the change** (from my hand calculation, not measured):
- **10 (+0):** unchanged. The specks are just appearing at the base.
- **12 (+2):** crumbs about 30–44 px from centre. The outer ones show past both edges of the sprite, bright, full size and low. The inner ones are still partly hidden.
- **15 (+5):** crumbs about 54–89 px from centre, a flat fan roughly one jelly width beyond the visible edge on each side. Height should not change, because the lift, gravity and spread are untouched.
- **20 (+10):** about 83–150 px out, but small (about a quarter of full size) and mostly transparent. Crumbs will **still be moving**, not nearly stopped, because damping 600 can't stop a faster crumb within its life. That is the cost of changing one setting. If it shows, the next candidate is damping.
- **30 and 50:** nothing.

**Two consequences to check:**
- **Spread vs the brief and `visibility_rect`.** The brief's estimate that the farthest crumb reaches about ±106 px stops being true: the faint tail can travel past the hand-set `visibility_rect` of ±120. That rect only decides when the whole puff is skipped off-screen, so it isn't changing now. It's worth watching at the screen edge (predicted failure 6).
- **Brief revision.** The brief's settings table will then disagree with the scene, so it needs a dated revision from you.

After you approve, I will:
1. Edit lines 48–49 of `godot/effects/land_puff.tscn`.
2. Update lines 34–35 of `godot/tests/test_land_puff_config.gd`.
3. Run `./scripts/run-test.sh test_land_puff_config.gd 60`, show you the diff and output, and stop so you can recapture. I won't commit.