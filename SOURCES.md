# SOURCES — Jelly Hop: Fork From Above

Credits, models, tools, and terms for this project. The generation-by-generation record is in ASSET-LOG.md.

## Starting point

- Not decided yet: an empty Godot 4 project or the walker-jumpman structure. No Godot project exists in this repository yet. Whichever I start from will be credited here.

## Generative models

| Model | Version | Where it ran | License or terms | Used for |
|-------|---------|--------------|------------------|----------|
| Stable Diffusion XL Base, by Stability AI | 1.0 (`sd_xl_base_1.0_f16.ckpt`, with `sdxl_vae_v1.0_f16.ckpt`) | Locally on my MacBook Pro (Apple M4, 16 GB) in Draw Things 26.0924.0 | CreativeML Open RAIL++-M License, dated July 26, 2023: use and redistribution allowed, subject to its use-based restrictions | CHAR-REF, the 12 gameplay poses (Batch 1), and the six environment assets (Batch 2); see ASSET-LOG.md |

- Audio and music models: not chosen yet.

## Tools

- **Draw Things** 26.0924.0 (260924.0), free macOS app. Local generation only; no Draw Things+ subscription, cloud compute, or in-app purchases used.
- **Python scripts in `tools/`,** written by Claude at my request and run by me: `make_storyboard_svgs.py` (storyboard sketches), `make_character_svgs.py` (character sheet images), `check_64px.py` (readability check at game size), `remove_specks.py` (the logged speck cleanups), `make_pose_guide.py` and `make_pose_guides.py` (pose guides warped from CHAR-REF), `make_env_guides.py` (the four environment guides), `process_env.py` (magenta cut-outs, the dome transparency edit, the table seam, the room resize, guide comparison), `batch2_review.py` (Batch 2 review images and contrast numbers). Shell scripts `batch1_*.sh` and `batch2_*.sh` run each batch's steps.
- **macOS built-ins:** `qlmanage` (SVG to PNG), `sips` (thumbnails), `shasum` (checksums).

## Collaborators and AI assistance

- **Claude** (Anthropic, used through the claude.ai chat): checked the design against the assignment, asked design questions, drafted documents and prompts from my decisions, wrote the scripts above, and pointed out issues in outputs. Claude does not generate images or audio; its SVG drawings are design references, not generated assets. The environment guides drawn by Claude's script were inputs to SDXL at 50% strength, and the accepted plate, sauce, fork, and dome stay close to them (measured in ASSET-LOG.md, Batch 2).
- **Me (Kiran):** every design decision and reason, every accept and reject decision, all generation runs, edits, and commits.
- No other collaborators so far.

## Rights and responsible use

- No prompt or reference names a living artist, a copyrighted character, or a brand, and no existing music or recordings are used.
- Images fed to the model: my approved design (`gen-inputs/char-ref-guide.png`); pose guides built from the accepted CHAR-REF (`gen-inputs/pose-guide-*.png`); and four environment guides drawn by Claude's script `tools/make_env_guides.py` (`gen-inputs/ENV-*-guide.png`). No outside images.
- No real person's voice is cloned or imitated.
- No API keys or account credentials are stored in this repository.
