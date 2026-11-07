# TUNING — Assignment 6

Every revision records Claude's prediction, the strips before and after, Claude's comparison and my verdict in the running game (CHANGE-BRIEF.md; assignment Step 4). Strips are **fixture captures** of the preview scenes in `godot/previews/`, rendered by Movie Maker at 30 fps (`--fixed-fps 30`) with fixed seeds on the preview instances only. Files are numbered from 0, so strip frame N is `frameNNNNNNNN.png`.

## Effect A — Landing crumb puff

### 2026-11-07 — Effect A, r0: my first verdict, before Claude read anything
Strip: `captures/land_puff/r0/` (fixture capture; `land_puff_preview.tscn` with `retrigger` off; seeds 1001 and 1002; frames 10, 12, 15, 20, 30, 50). Effect settings: CHANGE-BRIEF.md Version 1, as built in commit `2bb6ebc`.
Where I looked: the running preview at the project's window size (1280 × 720), several runs, and the six strip frames.

What I saw (my words): In the live preview, I saw a quick puff that looked like white smoke under both jellies. At frame 12, it was easy to see on both the pale plate and the dark table. At frame 15, most of the crumbs were still under the jellies, so I didn't see the wide sideways fan I expected. The crumbs were gone by frame 20 and stayed gone in frames 30 and 50.

Claude's reading of r0: not yet requested.
