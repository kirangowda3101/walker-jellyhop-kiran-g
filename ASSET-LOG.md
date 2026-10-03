# ASSET-LOG — Jelly Hop: Fork From Above

One row per generation kept or seriously considered, plus every edit. Raw full-size outputs are kept outside the repo in `~/Documents/jellyhop-generations/`; the repo holds accepted assets, a thumbnail of each source or rejected output, and evidence images. Checksums are SHA-256.

## Shared setup for the CHAR-REF rows

- **Model:** SDXL Base (v1.0), Stability AI. License: CreativeML Open RAIL++-M (July 26, 2023). See SOURCES.md.
- **Model files:** `sd_xl_base_1.0_f16.ckpt`, `sdxl_vae_v1.0_f16.ckpt`, `clip_vit_l14_f16.ckpt`, `open_clip_vit_bigg14_f16.ckpt`
- **Where it ran:** locally on my MacBook Pro (Apple M4, 16 GB) in Draw Things 26.0924.0 (260924.0). No cloud compute, no LoRA, no Control.
- **Prompt:** `cute cartoon jelly cube character, rounded cube shape, glossy turquoise gelatin body, two small round dark eyes, small simple smile, thick dark teal outline, one soft white highlight on the top center, slightly darker band near the bottom, smooth clean cartoon shapes, soft shading, front view, centered, single character, game sprite, flat solid magenta background`
- **Negative prompt:** `text, watermark, logo, signature, photo, realistic, 3d render, gradient background, shadow, floor, table, plate, multiple characters, arms, legs, hands, nose, teeth, extra eyes, checkerboard, transparent background, blurry, noisy`
- **Settings:** 1024 × 1024 · seed 7270 · 30 steps · text guidance 7.0 · sampler DPM++ 2M AYS · shift 1.00
- **Guide image (rows B and C):** `gen-inputs/char-ref-guide.png` (commit `904b22a`, checksum `89c7a49fe7eb4273077e5830c5904c00d7fe777a17e1ea23fc5a5942be709d1b`): the approved front view from CHARACTER-SHEET.md, 1024 × 1024 on flat `#FF00FF`
- **64 px check:** `tools/check_64px.py` crops each image to its own character bounds and scales it to 64 px tall. Results: `evidence/char-ref-64px-check.png`.

## CHAR-REF-A — text to image

- **Settings:** shared setup · strength 100% (text to image) · no guide image
- **Raw output:** `CHAR-REF-A-seed7270.png` (checksum `2e7443d7461779debf13167e29d24954dd85880c2ffaa1e30a9bb840a1391126`) · thumbnail `art/rejected/CHAR-REF-A-seed7270-thumb.png`
- **Observed against the sheet:** a turquoise glossy cube, but in a three-quarter 3D view with legs (despite "legs" in the negative prompt); large glossy eyes with magenta irises, eyebrows, and an open mouth with a tongue; no dark outline; no bottom band; several edge highlights instead of one top-center highlight; a purple-pink gradient background with a white margin and a cast shadow. Its pink-magenta irises and tongue would risk being removed along with the magenta background. Character box 737 × 794 px, shown at 59 × 64 px.
- **Outcome:** rejected. B stays readable at 64 px and matches the character sheet most closely.
- **Edits:** none

## CHAR-REF-B — image to image, 60% (source before cleanup)

- **Settings:** shared setup · image to image · strength 60% · guide image on the canvas
- **Raw output:** `CHAR-REF-B-seed7270-s60.png` (checksum `2c0f71a7f4eba5a56c116b8ca648b2ed15c3fe6ada8887eab7e5ddb6d410a763`) · thumbnail `art/source/CHAR-REF-B-raw-seed7270-s60-thumb.png`
- **Observed against the sheet:** the cube shape, dark outline, bottom band, and top-center highlight were preserved. Character box 604 × 601 px, shown at 64 × 64 px.
- **What the model changed from the guide (measured):** background `#F424E1` instead of `#FF00FF`, with faint grain; body about `#3DD1BD` instead of `#3CCFC4`, with faint grain; band about `#1A9590` instead of `#1F8E92`, with a softer edge; eyes slightly taller ovals; a fuller smile with curled ends; two stray dots added above the right eye (black at x 667–689, y 340–366; teal at x 566–596, y 352–383).
- **Outcome:** source for the accepted CHAR-REF, after cleanup (next row). Not a rejected candidate.

## CHAR-REF-B edit — stray dot removal

- **Input:** CHAR-REF-B raw (checksum `2c0f71a7…a763`)
- **Tool:** `tools/remove_specks.py`, run as `python3 tools/remove_specks.py CHAR-REF-B-seed7270-s60.png CHAR-REF-B-seed7270-s60-edited.png 660 334 696 373 559 345 603 390`
- **What changed:** two small boxes only. Box x 660–696, y 334–373: 777 of 1,404 pixels filled with `#3AD2BB`. Box x 559–603, y 345–390: 1,177 of 1,980 pixels filled with `#3BD2BC`. 1,954 pixels in total; nothing outside the boxes changed. Fill colors come from the untouched body pixels around each dot.
- **Verification:** output pixel fingerprint `5fbc3cce005d71c8`, matching the approved preview. The raw file's checksum was identical before and after the edit. Before-and-after at 64 px: `evidence/char-ref-B-cleanup-64px.png`. At 3× zoom the filled spots look slightly smoother than the grainy body; at full size and at 64 px they are not visible.
- **Output:** `art/reference/CHAR-REF.png` (checksum `440dbd342e99544c45f0fb3ad37f1f678858dc0501cafd75204dd6cfd7a7e84b`)
- **Outcome:** **accepted as CHAR-REF.** At 64 px, the face and silhouette read clearly, the stray dots are gone, and the cube shape, outline, highlight, and bottom band remain consistent with the character sheet.
- **Where used:** the single reference every pose will be derived from. Not placed in the slice directly.

## CHAR-REF-C — image to image, 75%

- **Settings:** shared setup · image to image · strength 75% · guide image reloaded fresh on a cleared canvas
- **Raw output:** `CHAR-REF-C-seed7270-s75.png` (checksum `ef89b2addc7c85794fb79ba6b7f42cc11bb0396cbe18e5b259b15390631f7dc4`) · thumbnail `art/rejected/CHAR-REF-C-seed7270-s75-thumb.png`
- **Observed against the sheet:** the cube shape and thick outline held. The model added softer jelly shading, mainly a wavy bottom band, and a slightly more vivid body. It changed the face: taller oval eyes, small eyebrow strokes, and an open smiling mouth with a tongue, which breaks the sheet's "small mouth" rule. The highlight became a long horizontal bar. No stray dots. Character box 605 × 598 px, shown at 65 × 64 px.
- **Outcome:** rejected. I'd rather keep the simple face and consistent silhouette than change the design for extra detail.
- **Edits:** none


## Tool updates (used from CHAR-SCOOT-B on)

- `tools/check_64px.py` now takes an optional `TARGET_H` (default 64), so each pose is checked at its own height; with no setting it works exactly as before.
- `tools/remove_specks.py` now takes optional `THRESH` (default 40), `GROW` (default 3), and `FILL` (`flat` by default, or `smooth`, which blends a speck area in from its surroundings). Re-running the CHAR-REF edit with the updated script and its defaults gave the same fingerprint, `5fbc3cce005d71c8`.
- `tools/make_pose_guide.py` (commit `85e7786`): warps CHAR-REF into a pose's shape. CHAR-REF's measured bounds (604 × 601 px) count as the 64 × 64 cube; the face is lifted, kept unscaled, and placed with the eyes' center 38% down from the pose's top.

## CHAR-SCOOT-B — scoot: stretch and lean

- **Sheet target:** 56 × 72 game px, lean 10° toward the facing side, neutral face (CHARACTER-SHEET.md pose 5).
- **Guide:** `gen-inputs/pose-guide-CHAR-SCOOT-B.png` (commit `85e7786`, pixel fingerprint `c6bf091cea15ed12`), made with `python3 tools/make_pose_guide.py art/reference/CHAR-REF.png gen-inputs/pose-guide-CHAR-SCOOT-B.png 56 72 10`. Measured 71.9 × 55.8 game px. Known issue: a small notch in the outline at the bottom right.
- **Settings for both tries:** the same prompt, negative prompt, model, and settings as the CHAR-REF rows (seed 7270, 30 steps, text guidance 7.0, DPM++ 2M AYS, shift 1.00, 1024 × 1024) · image to image from the guide · strength as listed per try.

### CHAR-SCOOT-B try 1 — strength 60%

- **Raw output:** `CHAR-SCOOT-B-try1-seed7270-s60.png` (checksum `94dc59b8db62093face28da8a08ea195b635e4685e199ec4e1b2e30c5d75220d`) · thumbnail `art/rejected/CHAR-SCOOT-B-try1-seed7270-s60-thumb.png`
- **Observed:** the stretch and lean were kept (character box 606 × 674 px versus the guide's 603 × 675). The notch was smoothed. The model added glossy side shading and a wavy band. It also enlarged and deepened the smile and added pinkish-lilac blush spots under both eyes, visible at 72 px; the blush breaks the four-color rule and is close to the magenta background.
- **Outcome:** rejected. Face and palette consistency matter more to me than the extra glossy shading.
- **Edits:** none

### CHAR-SCOOT-B try 2 — strength 50% (source before cleanup)

- **Raw output:** `CHAR-SCOOT-B-try2-seed7270-s50.png` (checksum `e5c6ebc6a393d1d5ff48f6780681a6f4281192f13abb7af67f6a0fc570c4a1df`) · thumbnail `art/source/CHAR-SCOOT-B-try2-raw-seed7270-s50-thumb.png`
- **Observed:** the stretch and lean were kept (character box 604 × 674 px, within 1 px of the guide). The face is close to CHAR-REF, with the small smile kept and no blush. There is less gloss than in try 1, and the notch is gone. New: four faint round dots in the bottom band (at x 369–401, 474–506, 581–613, and 665–692; y 671–708), visible at 72 px, plus faint pale marks above the left eye, right of the right eye, and left of the mouth, which are barely noticeable at 72 px. Comparison: `evidence/char-scoot-b-72px-compare.png`.
- **Outcome:** source for the accepted CHAR-SCOOT-B, after cleanup (next row).

### CHAR-SCOOT-B try 2 edit — band dot removal

- **Input:** CHAR-SCOOT-B try 2 raw (checksum `e5c6ebc6…a1df`)
- **Tool and settings:** `THRESH=15 GROW=6 FILL=smooth python3 tools/remove_specks.py CHAR-SCOOT-B-try2-seed7270-s50.png CHAR-SCOOT-B-try2-seed7270-s50-edited.png 356 664 414 721 461 659 519 716 568 658 626 710 652 668 705 719`
- **Why these settings:** the dots are fainter than CHAR-REF's specks (threshold 15 instead of 40), and each has a soft darker halo (6 px margin instead of 3). A flat fill left visible square patches in the shaded band, so that version was rejected and the smooth fill used instead.
- **What changed:** four boxes only, 6,354 pixels in total (1,622 + 1,786 + 1,617 + 1,329), with every change inside the boxes. The faint face marks were left unedited, by choice.
- **Verification:** output pixel fingerprint `023e9bea89d15c77`, matching the approved preview. The raw file's checksum was unchanged after the edit. Character box unchanged (604 × 674 px). At 72 px the band reads clean (`evidence/char-scoot-b-cleanup-72px.png`). At 2× zoom, faint soft smudges remain where the halos were.
- **Output:** `art/poses/CHAR-SCOOT-B.png` (checksum `4c0b08c6923f76e2c1363b415b34c4a86a08ae141aaa678a0decec160c261234`)
- **Outcome:** **accepted as CHAR-SCOOT-B.** It preserves the sheet's stretch and lean, keeps the face close to CHAR-REF, and has a clean band at 72 px, with the faint face marks recorded as a minor remaining limitation.
- **Where used:** the scoot loop's key pose B, drawn facing right and flipped at runtime.

## Batch 1 — remaining poses (BORED, SCOOT-A, ANTIC, RISE, FALL, LAND, WORRY, CELEBRATE, SPLAT, RESPAWN)

- **Guides:** `tools/make_pose_guides.py` (commit `d0199e8`, committed before any batch generation). Shapes and faces follow CHARACTER-SHEET.md; every body pixel comes from CHAR-REF. Neutral faces reuse CHAR-REF's face; expression poses reuse CHAR-REF's eye pixels where the sheet keeps dot eyes and draw the sheet's brows, mouths, lids, closed eyes, or X eyes in CHAR-REF's face color `#0F3236` at its smile's stroke width (23 px). Splat and re-form reshape CHAR-REF column by column ("9-slice") to the sheet's outline; splat droplets are the whole CHAR-REF body scaled down; re-form drip marks are left out.
- **Guide pixel fingerprints (as built on my Mac):** BORED `e71b217d8e64d2ae`, SCOOT-A `a1d43047a1576b80`, ANTIC `81e27d52c8d9f4f8`, RISE `3817ab9dac3b451e`, FALL `59130cf7272c3808`, LAND `8be9f7560d5b5741`, WORRY `4c1b50993c5d6cae`, CELEBRATE `e2db31c27e3b736a`, SPLAT `246f33971f69869f`, RESPAWN `d095f24919a5030c`. Nine match Claude's preview build; SCOOT-A differs from the preview (`c89367734f6e8970`) only in 2,008 outline-edge pixels, each by at most 2 of 255 levels, with the face in the identical position (likely slightly different edge blending in the two machines' image libraries).
- **Settings for every try 1:** the CHAR-REF prompt and negative prompt, SDXL Base (v1.0) in Draw Things 26.0924.0, 1024 × 1024, seed 7270, 30 steps, text guidance 7.0, DPM++ 2M AYS, shift 1.00, image to image at 50% from the pose's guide.
- **CHAR-IDLE:** CHAR-REF itself (the sheet's idle pose is the resting cube); `art/poses/CHAR-IDLE.png` is a copy of `art/reference/CHAR-REF.png`. No new generation.
- **Shapes:** every try 1 result's outer box is within 1 game px of its guide's.
- **Edit tool:** `tools/remove_specks.py`, now also with `SELECT=pink` (only pinkish pixels) and a stop if a box leaves no untouched pixels around a mark. Re-running the CHAR-REF and CHAR-SCOOT-B edits with it gave their original fingerprints (`5fbc3cce005d71c8`, `023e9bea89d15c77`).
- **Raw output checksums (SHA-256):** see the table. File checksums of every accepted pose: `evidence/batch1-checksums.txt`. Before-and-after at each pose's height: `evidence/char-<pose>-cleanup.png`. Batch review sheet: `evidence/batch1-review.png`.

| Pose | Raw output (checksum) | Observed in raw output | Edit (tool settings and boxes) | Edit fingerprint | Outcome |
|------|-----------------------|------------------------|--------------------------------|------------------|---------|
| CHAR-BORED | `CHAR-BORED-try1-seed7270-s50.png` (`7dd8bb87…039a`) | Matches the guide; a faint smudge left of the left eye | None (a test cleanup left a visible rectangle in the low-contrast area and was dropped) | — | Accepted as-is; smudge documented |
| CHAR-SCOOT-A | `CHAR-SCOOT-A-try1-seed7270-s50.png` (`0b41486d…3f2b`) | Shape matches; the mouth became a wavy "w"; two large soft patches beside the eyes | None | — | Rejected; retried with seed 7271 (next section) |
| CHAR-ANTIC | `CHAR-ANTIC-try1-seed7270-s50.png` (`f9a3786b…d143`) | Brows and eyes match; a pink tongue under the mouth (off-palette, close to magenta) | `SELECT=pink GROW=2 FILL=smooth`, box 515 643 571 669 | `83396e0809c00898` | Accepted after edit; a soft dark shadow remains under the mouth |
| CHAR-RISE | `CHAR-RISE-try1-seed7270-s50.png` (`bf1f0c49…52db5`) | Shape and face match; a teardrop "nose" between the eyes and two drips under the highlight | `THRESH=15 GROW=6 FILL=smooth`, boxes 559 334 607 390 · 514 166 549 223 · 582 166 613 234 | `187179dc273b9474` | Accepted after edit; faint drip tops remain at the highlight's edge |
| CHAR-FALL | `CHAR-FALL-try1-seed7270-s50.png` (`3ca186a8…83d6`) | Shape and face match; seven raised bubbles on the face | `THRESH=15 GROW=6 FILL=smooth`, boxes 336 410 410 483 · 653 395 719 465 · 550 337 610 398 · 287 487 348 542 · 266 381 322 436 · 711 410 765 462 · 659 555 710 601 | `54b4e53be8c9de4f` | Accepted after edit |
| CHAR-LAND | `CHAR-LAND-try1-seed7270-s50.png` (`279b34ca…ec88`) | Matches the guide | None | — | Accepted as-is |
| CHAR-WORRY | `CHAR-WORRY-try1-seed7270-s50.png` (`7fc03689…b19b`) | Shape and face match; two light bubbles near the top right; faint dots at the band's corners | `THRESH=30 GROW=5 FILL=smooth`, boxes 598 248 674 309 · 578 282 634 319 (a first, larger box clipped the right brow and was redone) | `309ac423825dd995` | Accepted after edit; band corner dots documented |
| CHAR-CELEBRATE | `CHAR-CELEBRATE-try1-seed7270-s50.png` (`5cacef9b…4534`) | Matches the guide; faint dots in the band, barely visible at game size | None | — | Accepted as-is; band dots documented |
| CHAR-SPLAT | `CHAR-SPLAT-try1-seed7270-s50.png` (`2e37f99e…b52d`) | Matches the guide's outline and X eyes; droplets rendered as tiny rounded cubes | None | — | Accepted as-is |
| CHAR-RESPAWN | `CHAR-RESPAWN-try1-seed7270-s50.png` (`26805d1c…6db5`) | Shape and eyes match; a small mouth-like mark (the sheet shows eyes only); the thin puddle reads mostly as outline | `THRESH=15 GROW=6 FILL=smooth`, box 498 598 565 667 | `71af26165dcead5f` | Accepted after edit |

- **Where used:** `art/poses/<POSE>.png`, each pose's in-game frame, drawn facing right and flipped at runtime.

### CHAR-SCOOT-A try 2 — seed 7271

- **Settings:** the same as try 1 except seed 7271; guide `gen-inputs/pose-guide-CHAR-SCOOT-A.png` (commit `d0199e8`).
- **First export, set aside:** pixel-identical to try 1 (the seed change had not taken effect, or an older history entry was exported). Kept outside the repo as `CHAR-SCOOT-A-try2-INVALID-identical-to-try1.png`; not used.
- **Raw output:** `CHAR-SCOOT-A-try2-seed7271-s50.png` (checksum `c4d6026d1d60f3db549cf1f3e27575304ab0c83a766f7b9be5c6ab55c1585d82`), confirmed different from try 1 · thumbnail `art/source/CHAR-SCOOT-A-try2-raw-seed7271-s50-thumb.png`
- **Observed:** shape matches (character box 721 × 524 px; guide 723 × 525). The mouth matches the guide's (CHAR-REF's small smile); no side patches. New: a curved stroke extending from the outer bottom edge of each eye (x 440–470, y 501–520 and x 702–736, y 499–513).
- **Edit:** `GROW=3 FILL=smooth python3 tools/remove_specks.py … 430 491 468 530 704 489 746 523`; 1,165 pixels in the two boxes; output pixel fingerprint `cb0e787580f8e49e`; raw checksum unchanged. Small stubs remain where the strokes met the eyes, visible at 2× zoom but not at game size.
- **Output:** `art/poses/CHAR-SCOOT-A.png` (file checksum in `evidence/batch1-checksums.txt`); comparison of guide, try 1, try 2, and the edit at 56 px: `evidence/char-scoot-a-56px-compare.png`.
- **Outcome:** accepted after the edit in my review: at game size it matches the guide's shape, eyes, and mouth.
- **Where used:** the scoot loop's key pose A, drawn facing right and flipped at runtime.

## Batch 2 — environment art (ROOM, TABLE, PLATE, SAUCE, FORK, DOME)

- **Model and settings:** SDXL Base (v1.0) in Draw Things 26.0924.0, locally on my Mac; seed 7270, 30 steps, text guidance 7.0, DPM++ 2M AYS, shift 1.00; no LoRA, no Control. Text to image (100%) unless a row says guided; guided rows are image to image at 50% from a guide on a cleared canvas.
- **Exact prompts and negatives for every try:** `gen-inputs/batch2-env-prompts.md`. That file was **restored after generation**: the version planned before generation was never committed (the commit commands ran, but the file was not found in `~/Downloads`, so nothing was committed; see its first paragraph), so this batch has no committed-before-generation prompt record.
- **Guides (method change during the batch):** `tools/make_env_guides.py` (written by Claude) draws all four on flat `#FF00FF`; pixel fingerprints PLATE `7846989018675fd5`, SAUCE `2a1429c50e039a4e`, FORK `154de43fcf77afec`, DOME `1aa8a963c3740455`, identical when rebuilt on my Mac. These are drawn by a script, not generated.
- **How much SDXL changed each guide** (`tools/process_env.py compare`, measured inside the guide's drawn object): plate 8.6% of pixels changed by more than 32 levels (mean change 14–15 per channel), sauce 11.6% (9–19), fork 4.4% (8–10), dome 19.3% (18–24). Object boxes are within 11 px of the guides. **The guided outputs stay close to the drawn guides:** SDXL restyled the shading, outline, background, and small details but kept the drawn shapes. I reviewed this and chose to accept the four as they are and document it here.
- **Raw output checksums (SHA-256):** all 16 tries in `evidence/batch2-checksums.txt`. Thumbnails: rejected tries in `art/rejected/ENV-<ASSET>-try<N>-seed7270-thumb.png`; accepted sources in `art/source/ENV-<ASSET>-try<N>-raw-seed7270-thumb.png`.

### Tries

| Asset | Try | Mode, size | Change from the try before | Observed | Outcome |
|-------|-----|------------|----------------------------|----------|---------|
| ENV-ROOM | 1 | text, 1344 × 768 | planned prompt | A busy dining room with a white table, chairs, windows, lamps, a picture frame, and strong perspective; too bright and busy | Rejected |
| ENV-ROOM | 2 | text, 1344 × 768 | "close-up of a plain … wall of a dining room"; furniture, lamps, frames, floor, perspective added to the negative; "clean dark outline" dropped | Still a table, chairs, frames, and a hanging lamp | Rejected |
| ENV-ROOM | 3 | text, 1344 × 768 | "dining room" removed: a plain dark warm brown painted wall with glow from the left | A plain dark wall with a diagonal glow from the upper left; a light floor or baseboard strip along the bottom | **Accepted** (processing below) |
| ENV-TABLE | 1 | text, 1536 × 640 | planned prompt | A top-down set table with plates, cutlery, napkins, food, and glasses; color right | Rejected |
| ENV-TABLE | 2 | text, 1536 × 640 | front-view "ledge with cloth hanging below"; place settings and top-down views added to the negative | Nothing on top and a true front view, but a thin shelf floating on a light pinkish wall, with one V-shaped swag in the center and bare sides | Rejected |
| ENV-TABLE | 3 | text, 1536 × 640 | fabric "filling the entire image", "uniform repeating pattern"; wall, shelf, swag added to the negative | Full width, but a busy pattern of horizontal bands with swirl motifs, no vertical folds, faint vertical seam lines | Rejected |
| ENV-TABLE | 4 | text, 1536 × 640 | "plain … cloth", "a few large soft vertical folds", "no pattern"; pattern words added to the negative | A horizontal wood-grain plank, lighter and redder than the table color; no folds; a dark strip at the bottom | Rejected |
| ENV-TABLE | 5 | text, 1536 × 640 | "velvet curtain", wood strip removed; wood and curtain hardware added to the negative | Full-width vertical velvet folds edge to edge; brighter and pinker than needed, glossy highlights, a dark band along the bottom | **Accepted** (processing below) |
| ENV-PLATE | 1 | text, 1344 × 768 | planned prompt | A realistic 3D-rendered plate seen from above at an angle, apparently two stacked; purple-to-magenta gradient with a pink floor strip | Rejected |
| ENV-PLATE | 2 | text, 1344 × 768 | "flat 2D cartoon drawing … exactly from the side at eye level"; stacked plates, top view, 3d render, floor added to the negative | One plate with a dark outline, but the same angled view; gradient background, a white floor strip, and a shadow | Rejected |
| ENV-PLATE | 3 | **guided**, 1344 × 768 | the plate guide at 50% (my decision, below); prompts as try 2 | Edge-on plate with outline, a flat top surface, foot ring, one highlight; flat magenta | **Accepted** (processing below) |
| ENV-SAUCE | 1 | text, 1344 × 768 | planned prompt; top view, angled view, 3d render, surface, purple added to the negative | Sauce sitting on a plate, seen from above at an angle, with a shadow, on dusty pink | Rejected |
| ENV-SAUCE | 2 | **guided**, 1344 × 768 | the sauce guide at 50% | A low flat puddle seen from the side with an outline; browner than the guide; the small highlight came out pink, close to the background | **Accepted** (processing below) |
| ENV-FORK | 1 | text, **1344 × 768** (the portrait size had not been applied) | planned prompt; pointing up, angled view, 3d render, surface, purple added to the negative | A row of about ten utensils (forks, knives, spoons) pointing up, on dusty pink | Rejected |
| ENV-FORK | 2 | **guided**, 768 × 1344 | the fork guide at 50% | A fork pointing straight down, four pointed tines, handle off the top, outline, steel gradient, one highlight; flat magenta | **Accepted** (processing below) |
| ENV-DOME | 1 | **guided**, 1024 × 1024 (no text-only try) | the dome guide at 50%; angled view, perspective, 3d render, surface, purple added to the negative | Side-view dome with outline, knob, base rim, and highlights; interior flat magenta like the background; a slight mint tint on the knob and rim; a ragged, partly purple inner glass edge (visible at 2×) | **Accepted** (processing below) |

- **Plate try 2 export:** first missed; exported later from Draw Things' version history (its default file name began with the try 2 prompt). The processing script confirmed every retry differs from the try before it.
- **Accepted raw checksums:** ROOM try 3 `10a0f348…ce87d`, TABLE try 5 `51244fc3…6a32c`, PLATE try 3 `31d63df5…ef8a2`, SAUCE try 2 `28036cb7…183c8`, FORK try 2 `21998829…db7cb`, DOME try 1 `470c3758…3f001` (full values in `evidence/batch2-checksums.txt`).

### Processing edits (tool: `tools/process_env.py`, run by `tools/batch2_process.sh`)

Every edit reads the raw file without changing it. Pixel fingerprints are the first 16 hex characters of SHA-256 over the output's pixel bytes; they matched between Claude's dry run and my Mac.

- **Magenta cut-out (`cutout`), used for the four sprites and the 12 poses:** the background color is the median of the image's 3 px border (`#ED29E7` to `#F31FE8` across files). Pixels within 150 RGB levels of it that connect to the border are background; within 40 levels they become fully transparent. Edge pixels (between 40 and 150, plus a 2 px ring outside the keyed area) get their alpha and color by matching each to the solid pixel within 4 px that best explains it as a mix with the background, then un-mixing; remaining magenta spill is pulled out. Visible islands under 20 px (1–6 stray pixels per file, mostly at image corners) are dropped. Fringe check: magenta-like pixels remaining.
- **ENV-PLATE:** `cutout --crop 8` → `art/game/ENV-PLATE.png`, 1023 × 152; fringe 0; fingerprint `bdf417a0b57a3afa`.
- **ENV-SAUCE:** `cutout --crop 8 --pink-to 244,184,160` → `art/game/ENV-SAUCE.png`, 940 × 162. The pink highlight (1,958 px, close to the magenta key color and off the sauce's colors) was recolored to `#F4B8A0`, keeping its relative brightness, and 328 pinkish pixels around it were blended toward that color; box x 546–685, y 339–358 of the raw. Fringe 0; fingerprint `5e0806cbbf0a6519`.
- **ENV-FORK:** `cutout --crop 8` → `art/game/ENV-FORK.png`, 335 × 1267 (the handle runs off the top edge); fringe 0; fingerprint `e5b50c5e1a064c51`.
- **ENV-DOME (transparency edit):** `cutout --interior --crop 8` → `art/game/ENV-DOME.png`, 750 × 536. The magenta inside the dome (183,190 px, enclosed by the outline and rim) was keyed like the background, so the glass is see-through; the outline, knob, rim, and highlights stay opaque, and highlight edges are un-mixed from the magenta. 59 magenta-like pixels remain (opaque), in the model's ragged inner glass edge; not visible at game size, and I decided no extra generation was needed for it. Check image: the dome over the jelly, with the jelly visible inside (`evidence/batch2-sprites.png`). Fingerprint `b8b20794d0b874ab`.
- **ENV-TABLE:** `table --bottom 48 --blend 160 --gain 0.5 --sat 0.75` → `art/game/ENV-TABLE.png`, 1376 × 592. The dark band at the bottom (48 rows) was dropped; colors were desaturated to 75% and darkened to 50% (mean RGB 52, 24, 25); the last 160 columns were crossfaded into the first 160 so the strip repeats. Seam difference after blending 5.1, against 3.7 between neighbouring columns elsewhere (16.7 before blending). Tiled 3× in `evidence/batch2-table-seam.png`. Fingerprint `fa0928189d852264`.
- **ENV-ROOM:** `room --size 1280x720` → `art/game/ENV-ROOM.png`; center crop 1344 × 756, resized to 1280 × 720; no color change; the light strip at the bottom sits behind the 200 px table strip in the mock scene. Fingerprint `c674cced52b04d0f`.
- **Poses:** `cutout` (canvas kept at 1024 × 1024) → `art/game/CHAR-<POSE>.png` for all 12; fringe 0 in every pose; every pose's bottom edge is at y 811–812, so the frames share one baseline. Fingerprints: ANTIC `baa296f2dda432c9`, BORED `8e079ea2174160e9`, CELEBRATE `52a4a55499ef863a`, FALL `8acf874f9c32d317`, IDLE `2b451f0fc38bd284`, LAND `38efcb2616a63fd0`, RESPAWN `c6e76489c6d16d8f`, RISE `30b16a3463034f6e`, SCOOT-A `7debfac52fe909ae`, SCOOT-B `0931271333ff00a1`, SPLAT `4b0de8682eb7972b`, WORRY `3bf41741d7baef7b`. The magenta originals in `art/poses/` are unchanged.

### Checks (`tools/batch2_review.py`)

- **Mock scene at the proposed game sizes** (`evidence/batch2-mock-scene.png`, layout only; the fork handle is stretched and the shadow is a placeholder, since the real shadow is code-drawn): table strip 200 px tall (repeat every 465 px), plate 200 × 27, sauce 120 × 19, fork head 70 wide, dome 180 × 128, jelly 64 × 64.
- **Luminance contrast (WCAG ratio):** jelly body vs room mean 4.37, vs table mean 8.46; plate vs table 7.06, vs room 3.65; fork vs room 2.75; sauce vs table 2.03; room vs table 1.94; jelly body vs plate 1.20 (the jelly's dark outline separates them). Room luminance: mean 78, 95th percentile 125 of 255.
- **Review sheet:** `evidence/batch2-review.png` (mock scene, table seam, sprites on two backgrounds and at 3×, all poses). Run log: `evidence/batch2-process-log.txt`.
- **Outcome:** in my batch review I accepted the six assets with this processing, asked for the prompts file to be restored with the prompts and settings actually used, and decided no extra generation was needed for the dome's minor edge.
- **Where used:** `art/game/` holds the game-ready files for the Godot slice: ENV-ROOM (background), ENV-TABLE (repeating table front), ENV-PLATE (platforms), ENV-SAUCE (hazard between plates), ENV-FORK (striking fork), ENV-DOME (goal), and the 12 pose sprites. Final in-game sizes are set in Godot.

## Batch 3 — sound effects and music (HOP, LAND, WARN, SPLAT-FORK, SPLAT-SAUCE, WIN, MUS-LOOP)

- **Prompts and settings:** `gen-inputs/batch3-audio-prompts.md`, committed before any generation (`5fc8efb`, together with AUDIO-BRIEF.md). Two dated notes were appended later; the committed text is unchanged:
  - a torchsde workaround (no prompt or setting change);
  - leveling by perceived loudness, which changes the planned edits.
- **Prediction,** written before generating: `evidence/batch3-prediction.md`.
- **Models:**
  - Stable Audio Open 1.0 (`stabilityai/stable-audio-open-1.0`, revision `f21265c1e2710b3bd2386596943f0007f55f802e`) for the six sound effects. 100 steps, CFG 7.0, the library's default sampler (`CosineDPMSolverMultistepScheduler`), float32, 44.1 kHz stereo.
  - MusicGen-small (`facebook/musicgen-small`, revision `4c8334b02c6ec4e8664a91979669a501ec497792`) for MUS-LOOP. 1,500 tokens (30 s), sampling, top-k 250, temperature 1.0, guidance 3.0, 32 kHz mono.
  - Both ran locally on Kiran's MacBook Pro (Apple M4, 16 GB) on the GPU (MPS), in a separate Python environment (`~/Documents/jellyhop-audio-env`): Python 3.13.5, torch 2.14.1, diffusers 0.40.0, transformers 5.18.0, torchsde 0.2.6. Script: `tools/batch3_generate.py`.
- **torchsde workaround:** the default sampler's final step recursed forever in torchsde (on MPS and CPU). Noise-time values within 1e-6 of the sampler bounds are snapped onto the bound. Prompts, seeds, steps, CFG and sampler are unchanged. Details: the prompts file's first note and `evidence/batch3-setup-log.txt`.
- **Takes:** 3 per sound, seeds 7270, 7271, 7272; 21 takes in all.
- **Raw WAVs:** 32-bit float, kept outside the repository in `~/Documents/jellyhop-generations/audio/`. The SHA-256 of every take is in `evidence/batch3-generation-log.txt` (and `.json`).
- **Thumbnail for every take,** including the takes not selected: the waveform contact sheet `evidence/batch3-takes-waveforms.png`. Measurements: `evidence/batch3-listening.md`.

### Prompts (the same for all three takes of a sound)

| ID | Length | Prompt | Negative prompt |
|----|--------|--------|-----------------|
| SFX-HOP | 1 s | `short soft squishy jelly bounce, springy wet boing as a small gelatin cube jumps, cartoon jump sound effect, single sound, close microphone, clean` | `music, melody, vocals, speech, voice, singing, background noise, hum, hiss, long reverb, low quality, distorted, clipping` |
| SFX-LAND | 1 s | `soft wet jelly squish landing on a ceramic plate with a tiny clink, cartoon landing sound effect, single short impact, close microphone, clean` | `music, melody, vocals, speech, voice, singing, background noise, hum, hiss, long reverb, low quality, distorted, clipping` |
| SFX-WARN | 1.5 s | `slow tense metallic scrape of a steel fork dragging across a ceramic plate, short warning sound, single sound, close microphone, clean` | `music, melody, vocals, speech, voice, singing, background noise, hum, hiss, long reverb, low quality, distorted, clipping` |
| SFX-SPLAT-FORK | 1.2 s | `heavy wet jelly squish splat with a brief sharp metallic clank of a steel fork hitting a plate, cartoon impact, single sound, close microphone, clean` | `music, melody, vocals, speech, voice, singing, background noise, hum, hiss, long reverb, low quality, distorted, clipping` |
| SFX-SPLAT-SAUCE | 1 s | `soft sloppy wet splat into thick sauce, gooey squelch, cartoon, single short sound, no metal, close microphone, clean` | `music, melody, vocals, speech, voice, singing, background noise, hum, hiss, long reverb, low quality, distorted, clipping` |
| SFX-WIN | 2 s | `short bright cheerful glass chime jingle, three rising bell notes, cartoon success sound, single sound, clean` | `vocals, speech, voice, singing, drums, background noise, hum, hiss, low quality, distorted, clipping` |
| MUS-LOOP | 30 s | `playful slightly tense instrumental loop for a cartoon platformer game, pizzicato strings and soft marimba, light ticking percussion, steady 100 bpm, minor key, no vocals` | none (MusicGen) |

### Takes

| Take | Seed | Model | Raw length, peak | Run time (MPS) | Raw SHA-256 (first 16) | Outcome | Edits | Where used |
|------|------|-------|------------------|----------------|------------------------|---------|-------|------------|
| SFX-HOP-take1 | 7270 | Stable Audio Open 1.0 | 1.00 s, +2.0 dBFS | 190 s | `2408a5370eadc416` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-HOP-take2 | 7271 | Stable Audio Open 1.0 | 1.00 s, +3.2 dBFS | 237 s | `2f5414a52b06d358` | not selected | processed once by Claude Code to test the swap tool (same settings), then swapped back to take 3 (`evidence/batch3-swaps.txt`) | briefly in the game during that test only |
| SFX-HOP-take3 | 7272 | Stable Audio Open 1.0 | 1.00 s, +0.9 dBFS | 240 s | `68f5fad91ab11009` | selected; design purpose: "intended to give each hop a clear takeoff cue."; listening judgment pending | lead trim 39.07 ms at −50 dBFS + 60.0 ms at the delivered level, no fade-in; tail trim 763.15 ms, 15.01 ms linear fade-out; kept 137.78 ms; gain -16.96 dB to -30.1 LUFS (max momentary); OGG Vorbis; decoded peak -15.97 dBFS, leading silence 0.0 ms; game file SHA-256 `5866c925b87436b4` | `audio/game/SFX-HOP.ogg` → `godot/assets/audio/SFX-HOP.ogg` |
| SFX-LAND-take1 | 7270 | Stable Audio Open 1.0 | 1.00 s, +2.1 dBFS | 253 s | `a852bec7e85b5785` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-LAND-take2 | 7271 | Stable Audio Open 1.0 | 1.00 s, -3.1 dBFS | 254 s | `51e31b9b5c75b7de` | selected; design purpose: "intended to distinguish landing safely from jumping."; listening judgment pending | lead trim 76.51 ms at −50 dBFS + 0.18 ms at the delivered level, no fade-in; tail trim 777.12 ms, 15.01 ms linear fade-out; kept 146.19 ms; gain -7.55 dB to -30.1 LUFS (max momentary); OGG Vorbis; decoded peak -10.66 dBFS, leading silence 0.0 ms; game file SHA-256 `ec29f67ea388988a` | `audio/game/SFX-LAND.ogg` → `godot/assets/audio/SFX-LAND.ogg` |
| SFX-LAND-take3 | 7272 | Stable Audio Open 1.0 | 1.00 s, -3.9 dBFS | 253 s | `ef3fb3fe8fb1f66a` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-WARN-take1 | 7270 | Stable Audio Open 1.0 | 1.50 s, -2.0 dBFS | 249 s | `54758a63ed4e886e` | selected; Kiran's confirmed listening judgment (fork timing): "the scrape now feels connected to the fork descending, which is what I wanted." | lead trim 98.3 ms at −50 dBFS + 244.31 ms at the delivered level, no fade-in; tail trim 790.07 ms, 15.01 ms linear fade-out; kept 367.32 ms; gain -15.15 dB to -30.1 LUFS (max momentary); OGG Vorbis; decoded peak -17.08 dBFS, leading silence 0.0 ms; game file SHA-256 `73f73611c94a1453` | `audio/game/SFX-WARN.ogg` → `godot/assets/audio/SFX-WARN.ogg` |
| SFX-WARN-take2 | 7271 | Stable Audio Open 1.0 | 1.50 s, +4.3 dBFS | 249 s | `220588d67271c77c` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-WARN-take3 | 7272 | Stable Audio Open 1.0 | 1.50 s, -2.9 dBFS | 252 s | `d2918e3df19adfd0` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-SPLAT-FORK-take1 | 7270 | Stable Audio Open 1.0 | 1.20 s, +6.2 dBFS | 261 s | `d0fe8bc7c64eb75d` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-SPLAT-FORK-take2 | 7271 | Stable Audio Open 1.0 | 1.20 s, +4.7 dBFS | 254 s | `676d9dc6d81acdfb` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-SPLAT-FORK-take3 | 7272 | Stable Audio Open 1.0 | 1.20 s, +1.8 dBFS | 255 s | `1d67642777496240` | selected; design purpose: "intended to identify a fork failure."; listening judgment pending | lead trim 5.49 ms at −50 dBFS + 0.77 ms at the delivered level, no fade-in; tail trim 1040.43 ms, 15.01 ms linear fade-out; kept 153.31 ms; gain -10.69 dB to -30.1 LUFS (max momentary); OGG Vorbis; decoded peak -8.90 dBFS, leading silence 0.0 ms; game file SHA-256 `83452335c5ac2f29` | `audio/game/SFX-SPLAT-FORK.ogg` → `godot/assets/audio/SFX-SPLAT-FORK.ogg` |
| SFX-SPLAT-SAUCE-take1 | 7270 | Stable Audio Open 1.0 | 1.00 s, +4.7 dBFS | 262 s | `f1b8abd9c90e9782` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-SPLAT-SAUCE-take2 | 7271 | Stable Audio Open 1.0 | 1.00 s, +1.6 dBFS | 262 s | `a2dc0af444c5b368` | selected; design purpose: "intended to distinguish a sauce failure from a fork hit."; listening judgment pending | lead trim 6.71 ms at −50 dBFS + 5.78 ms at the delivered level, no fade-in; tail trim 758.3 ms, 15.01 ms linear fade-out; kept 229.21 ms; gain -7.67 dB to -30.1 LUFS (max momentary); OGG Vorbis; decoded peak -6.07 dBFS, leading silence 0.0 ms; game file SHA-256 `3a763e0eb42a9392` | `audio/game/SFX-SPLAT-SAUCE.ogg` → `godot/assets/audio/SFX-SPLAT-SAUCE.ogg` |
| SFX-SPLAT-SAUCE-take3 | 7272 | Stable Audio Open 1.0 | 1.00 s, +7.1 dBFS | 259 s | `227d5fa15e3fccfe` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-WIN-take1 | 7270 | Stable Audio Open 1.0 | 2.00 s, +0.3 dBFS | 253 s | `d1f8659628cfd39f` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-WIN-take2 | 7271 | Stable Audio Open 1.0 | 2.00 s, -12.6 dBFS | 262 s | `cc29c9f289e4f2bd` | not selected | none (comparison copy only, outside the repo) | not used |
| SFX-WIN-take3 | 7272 | Stable Audio Open 1.0 | 2.00 s, -7.0 dBFS | 252 s | `8d80957a659f2e64` | selected; design purpose: "intended to mark reaching the dome."; listening judgment pending | lead trim 0.0 ms at −50 dBFS + 0.02 ms at the delivered level, no fade-in; tail trim 385.03 ms, 15.01 ms linear fade-out; kept 1614.94 ms; gain -7.57 dB to -30.1 LUFS (max momentary); OGG Vorbis; decoded peak -14.54 dBFS, leading silence 0.0 ms; game file SHA-256 `f8031458a1746f40` | `audio/game/SFX-WIN.ogg` → `godot/assets/audio/SFX-WIN.ogg` |
| MUS-LOOP-take1 | 7270 | MusicGen-small | 29.94 s, -2.8 dBFS | 109 s | `72b1cc76b9d5426d` | selected: "keep the current music; I haven't separately confirmed whether the seam is audible."; listening judgment pending | loop 16.88–26.48 s (4 bars at 101.35 bpm, beat-tracked, 4/4 assumed), crossfade 2 ms; gain -20.66 dB to -40.1 LUFS integrated; OGG Vorbis; decoded peak -23.51 dBFS; game file SHA-256 `39f6a5fe7b24bad4` | `audio/game/MUS-LOOP.ogg` → `godot/assets/audio/MUS-LOOP.ogg`; imported with looping on |
| MUS-LOOP-take2 | 7271 | MusicGen-small | 29.94 s, -5.5 dBFS | 100 s | `64f682ea780629b9` | not selected | none (comparison copy only, outside the repo) | not used |
| MUS-LOOP-take3 | 7272 | MusicGen-small | 29.94 s, -3.6 dBFS | 96 s | `c358154060f78823` | not selected | processed as an alternative only: loop 5.712–14.72 s (5 bars at 133.93 bpm), crossfade 2 ms, -40.1 LUFS; kept outside the repo (`~/Documents/jellyhop-generations/audio-game-alt/`) | not used |

### How the takes were selected

1. **Listening sheet:** `evidence/batch3-listening.md`, with every take's length, peak, RMS and leading silence, plus the waveform contact sheet.
2. **Kiran's provisional technical selections,** made from the measurements before listening and recorded word for word in the listening sheet.
3. **Comparison copies of all 21 takes,** for Kiran's listening only, kept outside the repo in `~/Documents/jellyhop-generations/audio-compare/` (`tools/batch3_compare.py`, `evidence/batch3-compare-log.txt`):
   - leading silence trimmed at −50 dBFS with no fade-in, and a 15 ms fade-out;
   - perceived loudness matched with gain only: sound effects to −30.1 LUFS maximum momentary, music to −21.5 LUFS integrated;
   - each music take's candidate loop played three times.
4. **Kiran's provisional technical shortlist for an in-game audition** (same takes), recorded as not being a completed listening review.
5. **Three in-game auditions** (`evidence/batch3-audition.md`).
6. **Final selections, with Kiran's design purposes,** recorded word for word in `evidence/batch3-audition.md` and in the table above. The only confirmed listening judgment is about the fork timing; the other listening judgments are pending.

### Edits for the game (step 4), and the change to the planned edits

- **Leveling (Kiran's decision; the prompts file's second note):** match perceived loudness with gain only (no compression or limiting), every file at or below −1 dBFS peak. This replaces "level to a common peak (−1 dBFS)".
  - **Sound effects:** a fixed −30.1 LUFS maximum momentary, the highest level at which all 18 takes stay at or below −1 dBFS. It is set by SFX-SPLAT-SAUCE take 3, and later swaps use the same target.
  - **Music:** −40.1 LUFS integrated, 10 LU below the sound effects (Claude Code's proposal). Kiran: "Volume: leave it unchanged for now."
- **Leading trim (Claude Code, found by the 10 ms start check):** the −50 dBFS leading trim is repeated at the delivered level (after the gain). On the raw level alone, SFX-WARN started after 244 ms and SFX-HOP after 60 ms in the game files. Every sound effect now starts at 0 ms. The first run is kept, marked superseded, in `evidence/batch3-process-log.txt`.
- **Music loop:** whole bars by beat tracking (4/4 assumed), at least 8 s. The crossfade is the shortest that passes the seam measurement; that measurement passes any crossfade of 2 ms or more, so it rules out only a hard cut. **The seam has not been confirmed by listening.**
- **Delivery:** OGG Vorbis (libsndfile 1.2.2, compression level 0.1) in `audio/game/`, copied byte-identical into `godot/assets/audio/` (`tools/copy_game_audio.sh`, `evidence/batch3-audio-copy.txt`). Scripts: `tools/batch3_process.py`, `tools/check_game_audio.py`, `tools/batch3_swap.sh`.
- **Re-encoding the same take** gives a file differing only in the Ogg serial number and page CRCs; the decoded audio is identical (checked).

### When the sounds play (game logic; Kiran's decisions after the auditions)

1. **After audition 1,** SFX-WARN was limited to the fork over the jelly's current or next plate.
2. **After audition 2,** SFX-WARN was moved from the start of the shadow phase to the moment that fork starts descending, if it is on screen then. Nothing plays as a shadow grows.

- Both are differences from CHANGE-BRIEF.md, recorded in `evidence/batch3-review.md`. The music behavior is unchanged.
- **Verification traces** (real game, scripted input; `godot/tests/trace_audio.gd`) on the route plates 1 → 2 → 3 → 2 → 1:
  - before: 22 scrapes, 16 while no fork was down (`evidence/batch3-audio-trace-before.txt`);
  - after the first decision: 9 (`-after.txt`);
  - after the second: 8, all in the same tick as their fork's descent (`-after2.txt`).

### Checks

- `bash tools/run_slice_checks.sh`: art and audio copies byte-identical; game audio 8/0; mechanics 25/0; keyboard 12/0; slice 61/0; 7 screenshots; launch with no errors.
- Results: `evidence/batch3-checks.txt`, `evidence/batch3-review.md`.
- None of these checks replaces Kiran's listening.

### Takes not selected

- 14 takes are "not selected". Kiran gave no per-take reasons.
- Their thumbnail is the waveform contact sheet `evidence/batch3-takes-waveforms.png`.
- Their raw files stay outside the repository; their SHA-256 values are in `evidence/batch3-generation-log.txt`.
