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
