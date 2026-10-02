# SOURCES — Jelly Hop: Fork From Above

Credits, models, tools, and terms for this project. The generation-by-generation record is in ASSET-LOG.md.

## Starting point

- Not decided yet: an empty Godot 4 project or the walker-jumpman structure. No Godot project exists in this repository yet. Whichever I start from will be credited here.

## Generative models

| Model | Version | Where it ran | License or terms | Used for |
|-------|---------|--------------|------------------|----------|
| Stable Diffusion XL Base, by Stability AI | 1.0 (`sd_xl_base_1.0_f16.ckpt`, with `sdxl_vae_v1.0_f16.ckpt`) | Locally on my MacBook Pro (Apple M4, 16 GB) in Draw Things 26.0924.0 | CreativeML Open RAIL++-M License, dated July 26, 2023: use and redistribution allowed, subject to its use-based restrictions | CHAR-REF (see ASSET-LOG.md) |

- Audio and music models: not chosen yet.

## Tools

- **Draw Things** 26.0924.0 (260924.0), free macOS app. Local generation only; no Draw Things+ subscription, cloud compute, or in-app purchases used.
- **Python scripts in `tools/`,** written by Claude at my request and run by me: `make_storyboard_svgs.py` (storyboard sketches), `make_character_svgs.py` (character sheet images), `check_64px.py` (readability check at game size), `remove_specks.py` (the logged CHAR-REF cleanup).
- **macOS built-ins:** `qlmanage` (SVG to PNG), `sips` (thumbnails), `shasum` (checksums).

## Collaborators and AI assistance

- **Claude** (Anthropic, used through the claude.ai chat): checked the design against the assignment, asked design questions, drafted documents and prompts from my decisions, wrote the scripts above, and pointed out issues in outputs. Claude does not generate images or audio; its SVG drawings are design references, not generated assets.
- **Me (Kiran):** every design decision and reason, every accept and reject decision, all generation runs, edits, and commits.
- No other collaborators so far.

## Rights and responsible use

- No prompt or reference names a living artist, a copyrighted character, or a brand, and no existing music or recordings are used.
- The only reference image fed to a model is my own approved design (`gen-inputs/char-ref-guide.png`).
- No real person's voice is cloned or imitated.
- No API keys or account credentials are stored in this repository.
