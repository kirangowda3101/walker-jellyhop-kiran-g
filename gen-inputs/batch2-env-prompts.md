# Batch 2 — environment art: prompts and settings (restored after generation)

**About this file.** A first version of this file (the plan below, "Planned before generation") was written in the earlier working chat, before any Batch 2 generation, with steps to commit it first. I ran those steps in Terminal right after the Batch 1 push, but the first one failed: `mv ~/Downloads/batch2-env-prompts.md gen-inputs/` reported "No such file or directory", so `git add` matched nothing, `git commit` reported "nothing to commit, working tree clean", and `git push` reported "Everything up-to-date". The failure went unnoticed, and in that chat I reported the step as done. It came to light during Batch 2 processing, when the script found no prompts file in the repository (still at `136721b`) or in `~/Downloads`. This file was **restored on 2026-10-02, after generation**, from the earlier chat's text plus the prompts and settings actually used for every try; the planned prompts and negatives below match, word for word, the copy of the original file in the earlier chat's file export. It does not show that the prompts were committed before generating.

Shared settings for every try: SDXL Base (v1.0) in Draw Things 26.0924.0, local only · seed 7270 · 30 steps · text guidance 7.0 · sampler DPM++ 2M AYS · shift 1.00 · no LoRA, no Control. These were not changed during the batch. **Mode** is text to image (strength 100%, empty canvas) unless a try lists a guide; guided tries are image to image at 50% from the guide on a cleared canvas.

Raw outputs are named `ENV-<ASSET>-try<N>-seed7270.png` and kept outside the repo in `~/Documents/jellyhop-generations/` (checksums: `evidence/batch2-checksums.txt`).

---

## Planned before generation (text of the earlier file)

| Asset | Size | Prompt | Negative |
|-------|------|--------|----------|
| ENV-ROOM | 1344 × 768 | `dim dining room at night after a party, dark warm brown wall, soft warm lamp glow from the left side, deep shadows, empty room, quiet calm mood, wide background, smooth clean cartoon shapes, soft shading, clean dark outline, simple game art` | `text, watermark, logo, signature, people, person, faces, characters, food, table, plates, bright colors, cluttered, photo, realistic, blurry, noisy` |
| ENV-TABLE | 1536 × 640 | `front edge of a dark wooden dinner table with a dark warm red-brown tablecloth draped over it, straight horizontal edge, even lighting, simple repeating fabric texture, wide horizontal strip, smooth clean cartoon shapes, soft shading, clean dark outline, simple game art` | `text, watermark, logo, signature, plates, cups, food, cutlery, people, objects on the table, strong highlights, vignette, perspective, photo, realistic, blurry, noisy` |
| ENV-PLATE | 1344 × 768 | `side view of a shallow round white ceramic dinner plate, seen almost edge on, thin raised rim, single object, centered, smooth clean cartoon shapes, soft shading, clean dark outline, simple game art, flat solid magenta background` | `text, watermark, logo, signature, food, cutlery, table, tablecloth, multiple objects, shadow, floor, gradient background, checkerboard, transparent background, photo, realistic, blurry, noisy` |
| ENV-SAUCE | 1344 × 768 | `side view of a small low flat puddle of spilled warm red-brown sauce, glossy surface with one small highlight, single object, centered, smooth clean cartoon shapes, soft shading, clean dark outline, simple game art, flat solid magenta background` | `text, watermark, logo, signature, plate, bowl, food, table, multiple objects, shadow, floor, gradient background, checkerboard, transparent background, photo, realistic, blurry, noisy` |
| ENV-FORK | 768 × 1344 | `giant stainless steel dinner fork pointing straight down, vertical, four sharp tines at the bottom, long handle reaching the top of the image, cold grey brushed steel, single object, centered, smooth clean cartoon shapes, soft shading, clean dark outline, simple game art, flat solid magenta background` | `text, watermark, logo, signature, hand, person, food, knife, spoon, plate, multiple objects, tilted, shadow, floor, gradient background, checkerboard, transparent background, photo, realistic, blurry, noisy` |
| ENV-DOME | 1024 × 1024 | `side view of an empty clear glass dessert dome cloche with a small round knob on top, thin dark outline around the glass rim and base, a few soft white highlights on the glass, nothing inside, single object, centered, smooth clean cartoon shapes, simple game art, flat solid magenta background` | `text, watermark, logo, signature, cake, food, dessert inside, plate, table, multiple objects, frosted, colored glass, shadow, floor, gradient background, checkerboard, transparent background, photo, realistic, blurry, noisy` |

The plan was text to image for all six, with the dome's interior made transparent as a logged edit after generation.

---

## Actually used, try by try

Prompts and negatives are exactly as given in the chats and pasted into Draw Things. "Planned" means the text in the table above.

### ENV-ROOM — 1344 × 768, text to image

- **try 1:** planned prompt and negative.
- **try 2:** prompt `close-up of a plain dark warm brown wall of a dining room at night, soft warm lamp glow on the wall from the left side, deep shadows toward the right, very simple, no furniture, empty flat background, smooth clean cartoon shapes, soft shading, simple game art` · negative `text, watermark, logo, signature, people, person, faces, characters, food, furniture, table, chairs, windows, doors, floor, lamps, picture frame, paintings, perspective, bright, cluttered, detailed, photo, realistic, blurry, noisy`
- **try 3:** prompt `plain dark warm brown painted wall at night, soft warm light glow on the wall from the left side, fading into deep shadow toward the right, very simple empty flat background, smooth clean cartoon shapes, soft shading, simple game art` · negative: same as try 2.

### ENV-TABLE — 1536 × 640, text to image

- **try 1:** planned prompt and negative.
- **try 2:** prompt `flat front view of a long plain dark wooden ledge with a dark warm red-brown cloth hanging down below it in soft vertical folds, side view, nothing on top, simple horizontal band, smooth clean cartoon shapes, soft shading, simple game art` · negative `text, watermark, logo, signature, plates, dishes, cups, glasses, food, cutlery, forks, knives, napkins, place setting, objects, top-down view, overhead view, perspective, people, strong highlights, vignette, photo, realistic, blurry, noisy`
- **try 3:** prompt `flat front view of dark warm red-brown fabric filling the entire image from left edge to right edge, soft even vertical folds repeating evenly across the full width, a thin dark wooden strip along the very top edge, uniform repeating pattern, no empty space, smooth clean cartoon shapes, soft shading, simple game art` · negative `text, watermark, logo, signature, plates, dishes, cups, glasses, food, cutlery, forks, knives, napkins, place setting, objects, top-down view, overhead view, perspective, people, strong highlights, vignette, wall, background, empty space, shelf, swag, bunting, valance, single object, centered object, bright, light colors, photo, realistic, blurry, noisy`
- **try 4:** prompt `flat front view of a plain dark warm red-brown cloth filling the entire image from left edge to right edge, a few large soft vertical folds, solid plain color with no pattern, a thin dark wooden strip along the very top edge, smooth clean cartoon shapes, soft shading, simple game art` · negative `text, watermark, logo, signature, plates, dishes, cups, glasses, food, cutlery, forks, knives, napkins, place setting, objects, top-down view, overhead view, perspective, people, strong highlights, vignette, wall, background, empty space, shelf, swag, bunting, valance, single object, centered object, bright, light colors, pattern, ornament, damask, floral, swirls, stripes, horizontal lines, tiles, bricks, photo, realistic, blurry, noisy`
- **try 5:** prompt `flat front view of a dark warm red-brown velvet curtain, heavy soft vertical folds from top to bottom across the entire image from left edge to right edge, plain solid color, smooth clean cartoon shapes, soft shading, simple game art` · negative `text, watermark, logo, signature, plates, dishes, cups, glasses, food, cutlery, forks, knives, napkins, place setting, objects, top-down view, overhead view, perspective, people, strong highlights, vignette, wall, background, empty space, shelf, swag, bunting, valance, single object, centered object, bright, light colors, pattern, ornament, damask, floral, swirls, horizontal stripes, horizontal lines, tiles, bricks, wood, wood grain, planks, curtain rod, rings, window, stage, photo, realistic, blurry, noisy`

### ENV-PLATE — 1344 × 768

- **try 1 (text to image):** planned prompt and negative.
- **try 2 (text to image):** prompt `flat 2D cartoon drawing of one empty white ceramic plate seen exactly from the side at eye level, very thin flat profile, slightly raised rim, single object, centered, smooth clean cartoon shapes, soft shading, clean dark outline, simple game art, flat solid magenta background` · negative `text, watermark, logo, signature, food, cutlery, table, tablecloth, multiple objects, stacked plates, two plates, saucer, top view, angled view, perspective, 3d render, shadow, floor, surface, gradient background, purple, checkerboard, transparent background, photo, realistic, blurry, noisy`
- **try 3 (guided, image to image 50%):** same prompt and negative as try 2 · guide `gen-inputs/ENV-PLATE-guide.png` (pixel fingerprint `7846989018675fd5`).

### ENV-SAUCE — 1344 × 768

- **try 1 (text to image):** planned prompt · negative `text, watermark, logo, signature, plate, bowl, food, table, multiple objects, top view, angled view, perspective, 3d render, shadow, floor, surface, gradient background, purple, checkerboard, transparent background, photo, realistic, blurry, noisy`
- **try 2 (guided, image to image 50%):** same prompt and negative as try 1 · guide `gen-inputs/ENV-SAUCE-guide.png` (`2a1429c50e039a4e`).

### ENV-FORK

- **try 1 (text to image), generated at 1344 × 768** (the planned 768 × 1344 had not been applied): planned prompt · negative `text, watermark, logo, signature, hand, person, food, knife, spoon, plate, multiple objects, tilted, pointing up, angled view, perspective, 3d render, shadow, floor, surface, gradient background, purple, checkerboard, transparent background, photo, realistic, blurry, noisy`
- **try 2 (guided, image to image 50%), 768 × 1344:** same prompt and negative as try 1 · guide `gen-inputs/ENV-FORK-guide.png` (`154de43fcf77afec`).

### ENV-DOME — 1024 × 1024

- **try 1 (guided, image to image 50%; no text-only try was run):** planned prompt · negative `text, watermark, logo, signature, cake, food, dessert inside, plate, table, multiple objects, frosted, colored glass, angled view, perspective, 3d render, shadow, floor, surface, gradient background, purple, checkerboard, transparent background, photo, realistic, blurry, noisy` · guide `gen-inputs/ENV-DOME-guide.png` (`1aa8a963c3740455`).

---

## Guides

All four guides are drawn by `tools/make_env_guides.py` (written by Claude), not by a model, on flat `#FF00FF`: an edge-on plate with a thin top ellipse as the landing surface; a low flat sauce puddle with one highlight; a fork pointing down with the handle off the top edge; a side-view glass dome whose interior is left flat magenta for the transparency edit. The script is deterministic; the guides rebuilt on my Mac have the same pixel fingerprints as the copies used in Draw Things. The downloaded copies carried an extra metadata chunk, so file checksums differ while pixels match.
