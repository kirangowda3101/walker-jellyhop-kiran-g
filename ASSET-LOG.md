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
