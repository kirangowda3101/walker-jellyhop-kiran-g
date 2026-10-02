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
