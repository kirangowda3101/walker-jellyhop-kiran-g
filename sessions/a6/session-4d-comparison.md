r1 matches my prediction at frames 10, 20, 30 and 50. At frames 12 and 15 the crumbs went **further than I predicted**, and my frame 12 claim, that no crumb would clear the jelly's edge, was wrong.

The likely cause is a one-frame timing offset in my calculation. Re-run with that offset, the numbers fit what r1 shows.

**How I read the frames:**
- I read all six frames in both strips at full 1280 × 720. Zooming was denied earlier, so my positions are about ±3–5 px.
- Puff centres in the fixture are x = 260 on the plate and x = 420 on the table. I take each jelly's visible edge as about ±39 px from its centre: about 221–299 and 381–459 px.
- `git status` shows only the two files I edited, and the preview sets fixed seeds 1001 and 1002 on these puffs. So r0 and r1 use the same random draws, and the only difference between the strips is the curve.

## Frame by frame

| Frame | My prediction | r0 | r1 | Prediction vs r1 |
|---|---|---|---|---|
| 10 | Crumbs moved 2–3 px, behind the sprite, specks between the feet | Specks at the base of both jellies | Specks at the base of both jellies, about the same as r0 (the files differ slightly) | **Matches** |
| 12 | No crumb centre clears the edge; only a few px peek out | Specks under the jellies, none clearly past the edges | Crumbs visible past **both** edges of **both** jellies, about 5–15 px beyond: plate about 205–218 left and up to about 310 right; table about 367 left and up to about 470 right | **Doesn't match**: about 10 px further than predicted |
| 15 | 60–75 % clear the edge, mostly by 5–35 px, at most about 40; low | A few crumbs just outside the left edges; mostly under | Low fans on both sides of both jellies. The farthest crumbs are about 48–49 px beyond the left edges (x about 172 and 333) and about 36 px beyond the right edges (about 335 and 495). They sit within a few px of the surface, with no stray high crumb that I could see | **Partly**: the near crumbs and the height match; the far reach is about 10 px beyond my maximum |
| 20 | Empty, or a few faint specks | Nothing visible | Nothing visible. The file differs from the empty frame 21 (`cmp`), so a few faint pixels remain somewhere | **Matches** |
| 30 | Nothing | Empty background | Empty background, byte-identical to r0's frame 30 | **Matches** |
| 50 | Nothing | Empty background | Byte-identical to r0's frame 50 | **Matches** |

Compared with r0, the change did what you wanted at frame 15: a fan on both sides instead of a few crumbs just past one edge. It also helped frame 12 more than I said it would.

## What explains the difference

**My frame timing was off by one frame.**
- I assumed the particles' age at frame 10 + n would be n/30 s, and noted that this could be off by one frame.
- `godot/previews/land_puff_preview.gd` sets `emitting = true` in `_process()` on frame 10. Frame 10 already shows crumbs in both strips, so the particles take one simulation step before frame 10 is drawn.
- So frame 10 + n shows crumbs that are (n + 1)/30 s old: frame 12 is 0.10 s, not 0.067 s, and frame 15 is 0.20 s, not 0.167 s.
- I'm inferring this from the crumbs visible at frame 10. I didn't check it in Godot's source.

Re-running my hand model with ages one frame older:

| Frame | Age | Outward travel | Farthest beyond the visible edge | Observed in r1 |
|---|---|---|---|---|
| 12 | 0.10 s | 14–28 px | about 13 px | about 10–15 px |
| 15 | 0.20 s | 37–68 px | about 53 px | about 36–49 px |
| 20 | 0.367 s | About two thirds of crumbs dead; survivors at most about 12 % size and 14 % opacity | Not visible | Not visible |

The far reach is longer on the left than on the right of both jellies. With fixed seeds, that is most likely just the particular random draws, so I wouldn't read anything into it.

## Against the brief's intent

- **Frame 12:** crumbs now show past both sides. They are out by a few px to about 15 px, not far out, but "clearly out from behind both sides" is roughly met.
- **Frame 15:** the farthest crumbs reach about 0.7–0.95 of a jelly width (52 px) beyond the visible edge. Many crumbs are still close to the edge, so the fan is a bit short of "about one jelly width beyond each side", more so on the right.
- **Frame 20:** the crumbs had faded out by frame 20, so whether they are "nearly stopped" can't be judged from the strip.
- **Contrast and the ring risk:** I can't judge contrast at this resolution, and I saw no crumb pushed upward, so the ring risk didn't show. Judging both on screen in the running game is yours.

I edited nothing in this step.