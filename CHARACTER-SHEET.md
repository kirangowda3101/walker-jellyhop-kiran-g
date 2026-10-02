# Character sheet — Jelly (the jelly cube)

Version 1 · 2026-10-01 · written before image or audio asset generation. Later revisions are added as new dated sections; this version is not rewritten.

- **Concept in one sentence:** a small, wobbly turquoise jelly cube with eyes and a small mouth, left on a dinner table after a party, hopping between plates to reach a glass dessert dome.
- **Images:** `design/character/`, drawn by Claude at my request with `tools/make_character_svgs.py`. I set every size, shape, color, and collision rule below and approved the images. These are planning references; generated sprites will be judged against them.
- **Viewport:** 1280 × 720 base.

## Size and silhouette

- **On-screen size:** the resting cube is **64 × 64 px** at the 1280 × 720 base.
- **Silhouette test:** `design/character/silhouette.svg` shows all 13 poses filled solid black at actual size. Every pose reads as its own shape. Bored (lower, wider slump) and relief (taller stretch, wider at the top) were redrawn after the first test showed them too close to falling and idle.

## Facing and orientation

- **Drawn facing right; flipped at runtime for left.** No left-facing frames are generated.
- The face always looks toward the camera so expressions stay visible. Direction shows through the **eyes and mouth shifted 3 px toward the facing side** and a **slight lean** in moving poses.
- The jelly keeps facing the way it last moved, so the cue stays readable when idle.
- The highlight sits **top-center**, so a flip never makes the lighting jump sides.

## Reference

- `design/character/turnaround.svg`: front (game view), three-quarter, side, and back at the same height, with a 64 px height bar and the eye line.

## Poses

All 13 in `design/character/poses.svg`, drawn at 2.5×, facing right.

| # | Pose | Game state | Plays | Asset ID |
|---|------|-----------|-------|----------|
| 1 | Turnaround | Reference (counts as one pose) | — | CHAR-REF |
| 2 | Idle wobble | Standing still | Loop | CHAR-IDLE |
| 3 | Bored slump | No input for a few seconds (delay tuned in playtesting) | Loop | CHAR-BORED |
| 4 | Scoot A: squash and lean | Moving on a plate | Loop (key pose A) | CHAR-SCOOT-A |
| 5 | Scoot B: stretch and lean | Moving on a plate | Loop (key pose B) | CHAR-SCOOT-B |
| 6 | Crouch | Hop anticipation | Once | CHAR-ANTIC |
| 7 | Stretched | Rising | Once, holds | CHAR-RISE |
| 8 | Widened, eyes down | Falling | Once, holds | CHAR-FALL |
| 9 | Squash | Landing | Once | CHAR-LAND |
| 10 | Worried, eyes up | A shadow is growing over its plate | Loop | CHAR-WORRY |
| 11 | Splat | Fork or sauce failure | Once | CHAR-SPLAT |
| 12 | Re-forming | Respawn | Once | CHAR-RESPAWN |
| 13 | Relief stretch | Reached the dome | Loop | CHAR-CELEBRATE |

- **Priority:** worried always overrides bored. Danger shows first; boredom only appears during a quiet wait.
- CHAR-SCOOT-A, CHAR-SCOOT-B, CHAR-FALL, CHAR-BORED, and CHAR-REF are new IDs defined here; STORYBOARD.md v1 stays as committed.

## Collision

`design/character/collision.svg` draws the active box over every pose at the same 2.5× scale.

- **Standing box:** 52 × 58 px, bottom-aligned, centered. Used by idle, scoot A and B, rising, falling, worried, and relief.
- **Low box:** 52 × 44 px, bottom-aligned, centered. Used by crouch, landing squash, and bored slump.
- **Hits off during splat and re-forming:** hazards ignore the jelly until control returns and the checkpoint's safe window begins, so one failure can never produce a second splat or a second splat sound.
- **Art beyond the box, and why it is fair:** about 6 px of soft jelly edge sits outside the standing box on each side and 6 px on top at rest, and stretched poses reach further above it. A fork tine grazing that soft edge does not count as a hit, which forgives near-misses. The bottom is always flush with the art, so landings line up with the plate exactly.
- **Low poses:** with the low box, the art sits 2 to 6 px above the box, so the jelly cannot be hit above where it visibly is.
- **Watch item for playtesting:** in Scoot A, the standing box sits 2 px above the art. Kept as is and noted.

## Palette

`design/character/palette.svg` shows the swatches, the jelly at actual size in a sample scene, and contrast ratios.

| Role | Hex |
|------|-----|
| Jelly body | `#3CCFC4` |
| Shade (bottom band) | `#1F8E92` |
| Highlight (top-center) | `#E8FFFA` |
| Outline, eyes, and mouth | `#0F3440` |

- **Checked against placeholder environment colors:** table `#2A2320`, room `#1B1716`, plate `#E9E4DA`, fork `#9AA2A9`, sauce `#B4472A`. The final environment palette is not decided yet.
- **Result:** the jelly body stands out on the dark table and room (8.0 : 1 and 9.2 : 1). On pale plates and next to the steel fork, the dark outline carries it (10.5 : 1 and 5.1 : 1). The sauce differs from the jelly mainly by hue, warm red against cool aqua.

## Consistency rules

Every generated frame is judged against these. They are measured from the approved reference drawings.

- **Proportions:** the resting cube is 64 × 64. Squash and stretch change the width and height, but the jelly never loses its rounded-cube identity.
- **Outline:** a 3 px dark outline (`#0F3440`) on every frame. It is never dropped or thinned, because it carries visibility on pale plates and against the fork.
- **Eyes:** two dots of 4 px radius, 18 px apart center to center, on an eye line 24 px below the top at rest (38% down from the top in squashed or stretched poses).
- **Mouth:** small and centered under the eyes.
- **Facing:** the eyes and mouth sit 3 px toward the facing side; the lean goes toward the facing side, except worried, which leans back.
- **Highlight:** one top-center highlight in `#E8FFFA`; no side highlights.
- **Shade:** one darker band (`#1F8E92`) near the bottom.
- **Colors:** only the four palette colors on the jelly.
- **Silhouette:** each pose keeps the shape shown in `silhouette.svg`, so states read before any face detail.
