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
