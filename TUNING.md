# TUNING — Assignment 6

Every revision records Claude's prediction, the strips before and after, Claude's comparison and my verdict in the running game (CHANGE-BRIEF.md; assignment Step 4). Strips are **fixture captures** of the preview scenes in `godot/previews/`, rendered by Movie Maker at 30 fps (`--fixed-fps 30`) with fixed seeds on the preview instances only. Files are numbered from 0, so strip frame N is `frameNNNNNNNN.png`.

## Effect A — Landing crumb puff

### 2026-11-07 — Effect A, r0: my first verdict, before Claude read anything
Strip: `captures/land_puff/r0/` (fixture capture; `land_puff_preview.tscn` with `retrigger` off; seeds 1001 and 1002; frames 10, 12, 15, 20, 30, 50). Effect settings: CHANGE-BRIEF.md Version 1, as built in commit `2bb6ebc`.
Where I looked: the running preview at the project's window size (1280 × 720), several runs, and the six strip frames.

What I saw (my words): In the live preview, I saw a quick puff that looked like white smoke under both jellies. At frame 12, it was easy to see on both the pale plate and the dark table. At frame 15, most of the crumbs were still under the jellies, so I didn't see the wide sideways fan I expected. The crumbs were gone by frame 20 and stayed gone in frames 30 and 50.

Claude's reading of r0: not yet requested.

### 2026-11-07 — Effect A, revision r1
What I saw (preview fixture and running game, 1280 × 720): my r0 verdict above. At frame 15 most crumbs were still under the jellies, with no wide sideways fan. In the running game a puff appeared at the jelly's feet on every landing, and the puffs all looked the same to me. On my r0 plate-edge attempt in the running game, I didn't see the two puffs overlap. That helped motivate trying a more visible sideways spread. I haven't verified overlap in r1.

Claude's reading of r0 (`sessions/a6/session-4a-reading.md`): frames 10, 30 and 50 match the intent; frame 12 does not have crumbs "out from behind both sides"; frame 15 fails, with a few crumbs just outside one edge and nothing near a jelly width out; frame 20 is empty. Its explanation: the LAND sprite is about 78 px wide, wider than the 52 px collision box the brief was sized to, and the push is too weak to carry crumbs past the visible edge. It read the frames unzoomed, because its three image-crop commands were denied.

Change: `radial_accel_curve` (`CurveTexture`) `(0, 1), (0.2, 0)` → `(0, 1), (0.18, 1), (0.2, 0)`, linear, approved by me. `radial_accel_min` / `radial_accel_max` unchanged at 4000 / 6500. Claude first proposed doubling the radial range to 8000 / 13000; I chose its curve-only alternative instead (`sessions/a6/prompt-4b.txt`). The agent made the edit and updated the configuration test's expected curve points (`sessions/a6/session-4c-reply.md`). My config run: 51 checks / 0 failures, exit 0.

Claude's prediction for r1 (`sessions/a6/session-4b-prediction.md`): frame 10 unchanged; frame 12 crumbs still mostly behind the jelly, no crumb centre clearing the visible edge, so still short of the brief; frame 15 about 60–75 % of crumbs clear the edge, mostly by 5–35 px, at most about 40 px, low, short of one jelly width; frame 20 empty or a few faint specks; frames 30 and 50 empty. Risk named: about one stray crumb per puff kicked upward. A cross-check simulation by Claude in chat (not Claude Code) used the same timing assumption and also predicted almost nothing past the edge at frame 12.

Claude's comparison of r1 with its prediction (`sessions/a6/session-4d-comparison.md`): frames 10, 20, 30 and 50 match. Frame 12 does **not** match: crumbs show about 5–15 px past both edges of both jellies, about 10 px further than predicted. Frame 15 partly matches: low fans on both sides of both jellies, near crumbs and height as predicted, but the farthest reach about 36–49 px beyond the visible edges, about 10 px beyond its predicted maximum; no stray high crumb seen. Its explanation: its model was one frame off, because the preview starts emission in `_process()` on frame 10 and frame 10 already shows crumbs, so frame 10 + n shows crumbs (n + 1)/30 s old. Inferred from the frames, not checked in Godot's source. Against the brief: frame 12 roughly meets "out from behind both sides"; frame 15 reaches about 0.7–0.95 of a jelly width beyond the edge, a little short of "about one jelly width".

My verdict (running game, 1280 × 720): **kept**, because the puff was easy to see when the jelly landed in the running game. In the frame comparison, r1 was already wider at frame 12 and spread farther past both sides by frame 15.

Strips: `captures/land_puff/r0/`, `captures/land_puff/r1/` (fixture captures, seeds 1001 and 1002, same preview).
Commits: the curve change (agent, approved by me), then strip r1, then this verdict with the brief revision, in that order.

## Effect B — Dome sugar glints

### 2026-11-07 — Effect B, r0: my first verdict, before Claude read anything
Strip: `captures/dome_glints/r0/` (fixture capture; `dome_glints_preview.tscn`; seed 2001 on the preview instance only; `restart()` at frame 10, `emitting = false` at frame 70; Movie Maker at 30 fps, 150 frames; strip frames 10, 12, 40, 70, 85, 145). Effect settings: CHANGE-BRIEF.md Version 1, as built in commit `f2e5b26`.
Where I looked: the running preview at the project's window size (1280 × 720) and the r0 capture.

What I saw (my words): I ran the live preview and checked the Effect B r0 capture myself. The glints were already visible around the dome at frame 10, and I saw more of them there than at frame 40. I didn't notice them thinning out by frame 85. By frame 145, no glints were visible.

Claude's reading of r0: not yet requested.

### 2026-11-07 — Effect B, revision r1
What I saw (preview fixture and running game, 1280 × 720): my r0 verdict above. The glints were already visible at frame 10, with more there than at frame 40, and no thinning by frame 85. In the running game they were visible when the dome first appeared in the intro, faded gradually after I won, and were easy to see against both the dark wall and the glass.

Claude's reading of r0 (`sessions/a6/session-7a-reading.md`): frames 10, 12, 70 and 145 match the intent; 40 and 85 miss it. It counted about 14 visible dots at frame 10 and about 9 at 40, mostly over the glass, and no thinning from 70 to 85. Its explanation: alpha and size both climb over the first 0.2 of life (about 0.48 s), so the glints missing after the stop are the ones still fading in, and the brief's "fades in over about 0.5 s" contradicts its frame-85 "fewer near the glass". It also inferred, untested, that `lifetime_randomness = 0.3` only shortens lives (1.68–2.4 s), so fewer than 24 are alive on average. It read the frames unzoomed, because its two image-crop commands were denied.

Change: `color_ramp` (`Gradient_life`) offsets `(0, 0.2, 0.75, 1)` → `(0, 0.08, 0.75, 1)`, colours unchanged, approved by me. `scale_curve` unchanged. The agent made the edit and updated the configuration test's `RAMP_OFFSETS` (`sessions/a6/session-7b-reply.md`). My config run: 45 checks / 0 failures, exit 0.

Claude's prediction for r1 (`sessions/a6/session-7a-reading.md`): same positions as r0; frame 10 a few more small bright dots low in the glass, about 16 to 18 visible; frame 40 about 12 to 14, still well under 24 and mostly over the glass; frame 70 full; frame 85 the lower glass visibly emptier than at 70, 3 to 5 fewer dots; frame 145 empty.

My byte comparison (Terminal, `cmp` on each r0/r1 strip-frame pair): frames 10, 12, 40, 70 and 85 differ between r0 and r1, and frame 145 is identical, so the change took effect in the render.

Claude's comparison of r1 with its prediction (`sessions/a6/session-7c-comparison.md`): its `shasum` command was denied, so it compared file sizes instead. Its visual review found the same positions and motion as r0, but no extra visible dots at 10 or 40 (about 9 at 40), and no clearer thinning from 70 to 85 than in r0 (the file shrinks by 543 bytes in r1 and 539 in r0). Its explanation: young glints are still tiny while `scale_curve` grows them, so size, not alpha, limits how visible they are; it called its count prediction its own mistake.

My own look at the strips: the two frame-40 images looked nearly identical. A pair of screenshots looked slightly less crowded inside the glass at frame 85 than at frame 70, but Preview didn't show which capture folder that pair came from, so I don't count it as a confirmed r1 result.

Where Claude and I disagree: at full frame size Claude saw no visible difference between r0 and r1, while in the running game I found the glints noticeably easier to see in the intro. My verdict in the running game decides.

My verdict (running game, 1280 × 720): **kept**. I watched the intro in the running game, and the glints were noticeably easier to see. I couldn't tell whether they were brighter or whether more were visible. The frame comparison didn't show clearer thinning from frame 70 to 85, so I'm keeping r1 for how it looks in the intro.

Strips: `captures/dome_glints/r0/`, `captures/dome_glints/r1/` (fixture captures, seed 2001, same preview).
Commits: the ramp change (agent, approved by me), then strip r1 with Claude's comparison, then this verdict with the brief revision, in that order.

---

## A7 — landing, r0 (first verdict, mine, written before any Claude reading)

Capture: `captures/land/r0/clean/` and `captures/land/r0/overlay/` (fixture frames from `res://previews/land_preview.tscn`, Movie Maker at 30 fps, run by me with `sessions/a7/capture_strips.sh`; full sequences outside the repo). I also played the preview windowed at normal speed and at `--time-scale 0.25`.

- **Impact, hold, and rise:** Yes. The landing looked smooth at normal speed. In the clean frames, Jelly compresses on contact in 105, reaches its deepest squash in 106, holds it in 107, then rises in 108. The hold was easier to see frame by frame.
- **Seam:** I didn't see an obvious gap, overlap, or line where the two pieces meet during the squash or rise.
- **Feet:** Yes. At quarter speed, Jelly's bottom edge stayed planted on the plate as it squashed and rose.
- **Return to IDLE:** I didn't notice a pop. Between frames 108 and 109, Jelly gets a little taller while its bottom edge stays in the same spot relative to the plate.

## A7 — landing, r1: Claude's reading of r0 (agent)

Written by the agent (Claude Code, Step 7 r1 session) after Kiran's r0 verdict above. Frames read: the six clean frames in `captures/land/r0/clean/` (process frames 104–109) and the six overlay frames in `captures/land/r0/overlay/` (145–150), with their `STRIP` and `FRAME` lines in `land_clean.log` and `land_overlay.log`. The logs match the strip plan: `TRIGGER aligned=true`, 2 ticks per frame, rel ticks 0/2/4/6/8, every `STRIP` line `ok=true`, `problems=0` in both runs. I read the frames at full size only (1280 × 720, unzoomed), because my crop-and-enlarge command was denied. Every size below is my estimate from the full frame, about ±2 px, not a measurement. The jelly is about 64 px tall on screen, so 1 game px looks like about 1 screen px here.

| Kept frame | Phase table / strip plan | What the frame shows | Agree? |
| --- | --- | --- | --- |
| 104 / 145, trigger − 1, FALL | Airborne FALL before contact | The FALL drawing (dot eyes, flat mouth), upright, about 70 × 60 px, its bottom edge a few px above the plate rim. | Agrees |
| 105 / 146, rig 0, impact | Partial squash, planted feet | The drawing has changed to the IDLE face (smile). The bottom edge now sits on the rim. The top is about 14 px lower than in 104: roughly 55 px tall and slightly wider. Small feet show at the base. | Agrees |
| 106 / 147, rig 2, deepest squash | About the height of the low box (44 px) | The flattest silhouette: roughly 43–44 px tall and about 75 px wide, a slab with the whole face near the top. The bottom edge is in the same place on the rim. The A6 crumbs appear on both sides of the feet. | Agrees |
| 107 / 148, rig 4, same squash | Same squash, recovery begins | To my eye the jelly is the same as in 106: same top, same width, same bottom. The only visible change is the crumbs, which have moved further out. | Agrees on the shape. "Recovery begins" can't be seen in this frame: frame 4 is the start key of the rise, so the first recovered pose is tick 5, which a 30 fps strip does not capture. |
| 108 / 149, rig 6, eased rise | Eased rise, joined cut, fixed feet | Nearly upright again: about 57 px tall, width back near IDLE. The bottom edge is unchanged. I see no line, gap or overlap across the body where the two pieces meet. | Agrees. The 0.5 ease-out puts frame 6 three quarters of the way back (lower height 0.90), so most of the rise (about 14 px) happens between 107 and 108. |
| 109 / 150, tick 8, IDLE hand-off | No pop, seam or anchor shift | The original IDLE sprite, about 63 px tall, roughly 6 px taller than 108, with the bottom edge in the same place. The step continues the direction of the rise. | Agrees, as far as an unzoomed still can show |

Overlay frames: in all six, the plates, table and forks carry their collision tint, and the jelly silhouettes match the clean frames at the same strip positions. At full-frame size I could not make out the player's own collision box outline. So I could not compare the 52 × 44 box with the frame-2 silhouette from these stills; the "about the low box" agreement rests on my height estimate, not on the overlay.

Where the motion and the phase table differ, in visual terms: the table puts Active at 2–3 and Recovery at 4–7. On screen the squash is held at ticks 2, 3 and 4, because keys 2 and 4 are identical, so the hold lasts about 3 ticks (50 ms). Then the rise is front-loaded: about three quarters of it is done by tick 6. In the strip, the hold appears as two identical stills in a row (106 and 107), each shown for 1/30 s, so it is easy to see. At normal speed the same hold lasts only 50 ms and can blend into the rise. That fits Kiran's note that the hold was easier to see frame by frame.

What I cannot judge from stills:
- Smoothness and the feel of the easing. The 2.0 ease-in into frame 2 and the 0.5 ease-out after frame 4 act on ticks 1, 3, 5 and 7, and none of those ticks is in a 30 fps strip.
- Whether the feet stay planted and the cut stays joined on those odd ticks.
- Any one-pixel filtering line at the cut, which needs a zoomed view.
- Whether the rig's frame-8 rest is pixel-identical to the original IDLE sprite. The strip shows the original sprite at tick 8, not the rig at rest.
- How long the hold feels at normal speed. Only Kiran's playtest can decide that.

## A7 — landing, r1: Claude's prediction (agent)

Written by the agent before any r1 capture exists. The change is Kiran's choice: lower height scale 0.60 → 0.55 at keys 2 and 4, with UpperPivot y −12.084 → −11.077 (= −20.14 × 0.55). Timing (2/2/4), transitions, widths, UpperPivot scale and the keys at 0 and 8 are unchanged. The land read-back of the edited clip passes 135/0, with the frame-6 sample at lower 0.8875 and upper y −17.874. The headless land preview at 30 fps still shows TRIGGER frame 146, then rig 0, 2, 4, 6 and IDLE at tick 8.

How I get the sizes: the lower piece's part above the feet is 190 source rows × 0.106 = 20.14 game px at rest. Only that part changes height, and the upper piece keeps its shape and sits on top of it. So the whole jelly above the cut moves down by 20.14 × (old − new lower height scale). The brief's "about 44 game px" for r0's deepest squash is my starting point, not a new measurement.

| Kept frame | r1 compared with r0 |
| --- | --- |
| trigger − 1, FALL | Same as r0. The jelly pixels should be identical; the clip is not playing. |
| rig 0, impact | Same as r0, because the frame-0 key is unchanged. |
| rig 2, deepest squash | About 1 game px flatter: 20.14 × 0.05 = 1.007 px. The **deepest height is about 43 game px** (r0: about 44), now about 1 px under the 44 px low box. Same width (1.15). The face and top piece have the same shape as r0, sitting about 1 px lower; the band between the cut and the feet is about 11.1 px instead of 12.1 px. Feet in the same place. |
| rig 4, same squash | Identical to r1's rig 2, as in r0: the same ~43 px slab. |
| rig 6, eased rise | About 0.25 px lower than r0 (20.14 × 0.0125). I don't expect this to be visible. |
| tick 8, IDLE hand-off | Same as r0 (the original IDLE sprite). The step from rig 6 to IDLE grows by about 0.25 px, which I don't expect to see. |

The A6 crumbs may differ between r0 and r1 in any frame; I have not checked whether this preview seeds the puff.

What I expect Kiran to see: the r1 strip will look almost the same as r0. The only difference should be about 1 screen px at the top of the jelly in the two squash frames, close to the limit of what an unzoomed full frame shows. The off-strip ticks change by similar small amounts: about 0.25 px at tick 1 and about 0.57 px at tick 5. The hold still lasts ticks 2–4 (50 ms), so I predict the hold will not be noticeably easier to see at normal speed than in r0. A deeper squash makes the squash a little stronger; it does not make the hold longer.
