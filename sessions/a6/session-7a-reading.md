The r0 strip matches the intent at frames 10, 12, 70 and 145. Frames 40 and 85 miss it, which agrees with what you saw. I read the six frames at full size (1280 × 720). The command to crop and enlarge the dome area wasn't approved, so the dot counts below are approximate, made by eye on the full frame.

## r0 compared with the intent, frame by frame

From the scene and the brief: the emission box is centred at y = 520 − 70 = 450 and runs from y 405 to 495. The dome's glass runs from about y 410 (top) to 515 (base), so almost the whole box sits inside the glass.

| Frame | Intent | What r0 shows | Match? |
|---|---|---|---|
| 10 | Already at full steady-state density (preprocess on restart) | About 14 small gold dots on the upper glass and just above the knob, from about y 370 to 470 | **Yes for "no fill-in"**: predicted failure 5 did not happen. But it is far fewer than 24 |
| 12 | Same density, drifting up | Almost the same as 10 | Yes |
| 40 | About 24 glints, mostly above the glass | About 9 dots, fainter. Most are still over the glass or around the knob. The cloud is about 120 px wide and reaches about 45 px above the glass | **No**: fewer than at frame 10 (as you saw), well under 24, and mostly over the glass, not above it |
| 70 | Stop frame, still full | About 14 dots, a few above the knob | Yes, apart from the low count |
| 85 | Fewer near the glass; upper glints still rising | Looks almost the same as 70 | **No**: no visible thinning (as you saw) |
| 145 | Empty | Empty | Yes |

**Why frame 85 can't thin with the current ramp.** The `color_ramp` alpha climbs from 0 to 0.85 over the first 0.2 of life, which is 0.48 s. The scale climbs from 0 over the same stretch. Emission is 24 ÷ 2.4 s = 10 glints per second, so stopping at frame 70 removes about 5 births by frame 85. Those 5 would all be younger than 0.5 s, still faint and tiny, low in the box. Leaving them out changes almost nothing you can see. So the brief's phase 2 ("fades in over about 0.5 s") and its frame-85 row ("fewer near the glass") contradict each other. The glints that are missing 0.5 s after the stop are exactly the ones that would still be fading in.

**Why there are fewer than 24.** I see two reasons. Neither was tested on this machine; both come from my reading of how Godot's particle process works:
- `lifetime_randomness = 0.3` only shortens lives, to between 1.68 and 2.4 s. It doesn't give the brief's ± 30 %. A slot whose glint dies early stays empty until its next turn, so on average about 20 are alive.
- Each glint is faint or tiny for its first and last fifth of life, so only about 12 to 14 read as dots at any moment.

The random early deaths are also my best guess for why frame 40 shows fewer than frame 10.

**One limit of the design itself.** Over a third of its life (0.8 s), a glint rises only about 12 to 26 px. Only glints born near the top of the box can clear the glass that soon, so "mostly above the glass at frame 40" can't happen with this box placement. The box is also 140 px wide, against the intent's cloud of about 180 px. One setting can't fix either of these.

## Proposed change: `color_ramp` (`Gradient_life` in `godot/effects/dome_glints.tscn`)

| | Offsets | Colours |
|---|---|---|
| **Old** | `[0.0, 0.2, 0.75, 1.0]` | unchanged: `(1, 0.95, 0.82, 0)`, `(1, 0.95, 0.82, 0.85)`, `(1, 0.82, 0.55, 0.6)`, `(1, 0.82, 0.55, 0)` |
| **New** | `[0.0, 0.08, 0.75, 1.0]` | same four colours |

Only the second offset moves. Each glint reaches full brightness after 0.08 of its life (about 0.13 to 0.19 s) instead of 0.2 (0.34 to 0.48 s). The fade-out and the colours stay the same. The `scale_curve` is not touched, so new glints still grow from zero over the first fifth of life. They are now bright but small while they grow.

This departs from the intent's "fades in over about 0.5 s" and "alpha fades in and out with [size]". If you keep it, the brief needs a dated revision, as Effect A got.

I chose this over `lifetime_randomness = 0` because that would remove a variation the brief names, and wouldn't help frame 85.

## What each strip frame should show after the change

The seed (2001), positions and motion don't change, because the ramp only sets colour and alpha.

| Frame | Expected |
|---|---|
| 10 | Same glints in the same places as r0, plus a few more small, bright dots low in the glass (the young ones). About 16 to 18 visible |
| 12 | Same as 10, drifting up |
| 40 | More than r0's 9, about 12 to 14. **Still well under 24, and still mostly over the upper glass, not above it.** This change doesn't fix that, and frame 40 may still show fewer than frame 10 |
| 70 | Full, with small dots spread through the lower glass |
| 85 | **The lower glass visibly emptier than at 70**, with about 3 to 5 fewer dots. The upper glints are the same as r0's, still rising |
| 145 | Empty (2.5 s after the stop is longer than the longest life, 2.4 s) |

Colour: the shift toward gold now starts a little earlier in each glint's life. I expect that to be hard to notice.

## After you approve

1. In `godot/effects/dome_glints.tscn`, change `Gradient_life`'s `offsets` from `PackedFloat32Array(0, 0.2, 0.75, 1)` to `PackedFloat32Array(0, 0.08, 0.75, 1)`.
2. In `godot/tests/test_dome_glints_config.gd` line 49, change `RAMP_OFFSETS` from `[0.0, 0.2, 0.75, 1.0]` to `[0.0, 0.08, 0.75, 1.0]`.
3. Run `./scripts/run-test.sh test_dome_glints_config.gd 60`. It should still report 45 checks and 0 failures, exit 0.

Then I'll stop so you can recapture. I won't commit.

Nothing has been edited yet.