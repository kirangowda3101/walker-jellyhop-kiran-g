The curve-only change should get most crumbs out from behind the jelly by frame 15, but it will **not** meet the brief at frame 12. Even at frame 15, the fan stays short of one jelly width beyond each side. No edits yet.

## The setting

| | Old | New |
|---|---|---|
| `radial_accel_curve` (`CurveTexture`) | `(0, 1)` → `(0.2, 0)`, linear | `(0, 1)` → `(0.18, 1)` → `(0.2, 0)`, linear |

`radial_accel_min` / `radial_accel_max` stay at 4000 / 6500. The push still ends at 0.2 of life (60–80 ms), but it stays at full strength until 0.18 instead of fading from the start. That gives about 1.9× the outward speed at the end of the push.

## What the numbers rest on

These are hand calculations, not measurements:
- **Where the ring puts crumbs.** The ring lies flat in X–Z. Once Z is zeroed, a crumb's start point along the base is `x₀ = r·cos θ`, with r between 18 and 24 px and θ anywhere around the ring.
  - So crumbs start **anywhere from −24 to +24 px along the base, including near the centre**, not only at 18–24 px.
  - Starts bunch toward the ends: about 35–45 % start more than 18 px out, and about 15 % within 5 px of the centre.
- **Which way the push points.** Each crumb is pushed away from the emitter's origin, so a crumb on the left goes left and one on the right goes right.
- **Lifetime.** `lifetime_randomness` 0.25 gives each crumb 0.30–0.40 s of life. The push is timed by each crumb's own life, so short-lived crumbs get a shorter push.
- **Slow-down.** Damping removes 600 px/s every second, applied to the whole speed.
- **The jelly's visible edges.** About ±39 px from centre. I read the LAND sprite as about 78 px wide in the r0 frames (about 221–299 px for the plate jelly), from unzoomed frames. The rounded bottom corners may put the visible edge at the base closer to ±35 px.
- **Crumb size.** Each crumb is about 3–6 px in radius, so its outer half shows about 3–6 px before its centre reaches the edge.
- **Frame timing.** I take frame +n as n/30 s after the trigger. This could be off by one frame depending on when the preview sets `emitting`.

| Frame | Outward travel (new) | Distance from centre (adding `x₀`) | Visible edge cleared by |
|---|---|---|---|
| 12 (+2) | 7.5–13 px (r0 was about 5–9) | 7–37 px | **No crumb centre clears it.** The outermost centres are 2–4 px inside the edge, so only their outer halves show, a few px past each side |
| 15 (+5) | 23–55 px (r0 was about 14–28 for 0.40 s crumbs) | 23–79 px | About 60–75 % of crumbs fully clear, typically by 5–35 px and at most about 40 px. The rest, which started near the centre or got a weak push, are still at or behind the edge |

## Frame by frame afterward

- **10 (+0):** about the same as r0. Crumbs have moved only 2–3 px, so they sit along the base out to about 27 px, behind the sprite, and show only through the gaps at its feet. Matches the intent.
- **12 (+2):** crumbs still mostly behind the jelly. On both sides, the outermost crumbs peek out by a few pixels. They are full size, near white-cream and fully opaque, low on the surface. **Still short of "clearly out from behind both sides".** The change helps this frame only slightly, which is the weakness I flagged.
- **15 (+5):** a low fan beyond both edges, mostly 5–35 px past the visible edge (up to about 79 px from centre). Crumbs are 70–90 % size, nearly opaque, cream turning tan, within about 3–4 px of the surface.
  - That is **about 0.1–0.75 of a jelly width beyond the visible edge**, short of the brief's "about one jelly width" (52 px).
  - Measured from the 26 px collision edge the brief used, the farthest crumbs just reach one jelly width.
- **20 (+10):** about a third of the crumbs have already died (lives under 0.33 s). The rest are at 83–100 % of life, at most about 3 px across and at most about 30 % opaque.
  - They are still moving (up to about 300 px/s), so this is not "nearly stopped". It should look empty or show a few faint specks far out.
  - Some may be beyond the ±120 px `visibility_rect`. That only matters for culling at the screen edge.
- **30 (+20) and 50 (+40):** nothing. Every crumb is dead by 0.40 s.

**One risk to look for at frames 12–15:** this is my reading of how the push direction is computed, and I haven't verified it.
- For a crumb that starts within about 2 px of the centre, the small upward lift is a large part of its offset from the origin, so its push can point diagonally upward instead of sideways.
- That should happen to about one crumb per puff.
- It would look like a stray crumb 10–20 px above the surface beside the jelly. That is predicted failure 2 territory, and the stronger push makes it more likely.

## The edit after you approve

I will:
1. Change `Curve_radial` in `godot/effects/land_puff.tscn` (lines 16–17) to three linear points. The tangents are −50 between 0.18 and 0.2, and `point_count = 3`.
2. Change the `RADIAL_CURVE` expected points in `godot/tests/test_land_puff_config.gd` to match.
3. Run `./scripts/run-test.sh test_land_puff_config.gd 60`, show you the diff and output, and stop so you can recapture. No commit.