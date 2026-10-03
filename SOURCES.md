# SOURCES — Jelly Hop: Fork From Above

Credits, models, tools, and terms for this project. The generation-by-generation record is in ASSET-LOG.md.

## Starting point

- **walker-jumpman** "First Steps" starter by Nik Bear Brown (https://github.com/nikbearbrown/walker-jumpman), commit `9387542`, imported unchanged into `godot/` (with its launcher, if present) in this repository's commit `d7f0c97`, so every later change to it is a visible diff. The starter's other documents were not imported. License file in the starter: none in the starter repository.

## Generative models

| Model | Version | Where it ran | License or terms | Used for |
|-------|---------|--------------|------------------|----------|
| Stable Diffusion XL Base, by Stability AI | 1.0 (`sd_xl_base_1.0_f16.ckpt`, with `sdxl_vae_v1.0_f16.ckpt`) | Locally on my MacBook Pro (Apple M4, 16 GB) in Draw Things 26.0924.0 | CreativeML Open RAIL++-M License, dated July 26, 2023: use and redistribution allowed, subject to its use-based restrictions | CHAR-REF, the 12 gameplay poses (Batch 1), and the six environment assets (Batch 2); see ASSET-LOG.md |
| Stable Audio Open 1.0, by Stability AI (`stabilityai/stable-audio-open-1.0`) | Hugging Face revision `f21265c1e2710b3bd2386596943f0007f55f802e`, run through diffusers 0.40.0 (`StableAudioPipeline`) | Locally on my MacBook Pro (Apple M4, 16 GB), on its GPU (MPS) | Stability AI Community License: free for research and non-commercial use; limited commercial use under US $1M annual revenue with registration. Gated download; I accepted the license on Hugging Face | The six sound effects (Batch 3); see ASSET-LOG.md |
| MusicGen-small, by Meta (`facebook/musicgen-small`, 300M parameters) | Hugging Face revision `4c8334b02c6ec4e8664a91979669a501ec497792`, run through transformers 5.18.0 | Locally on the same Mac, on its GPU (MPS) | Model weights CC-BY-NC 4.0 (non-commercial only); code MIT. Acceptable for coursework | MUS-LOOP (Batch 3); see ASSET-LOG.md |

## Tools

- **Godot** `4.7.2.stable.official.ed1daf0bf` (engine for the slice).
- **Draw Things** 26.0924.0 (260924.0), free macOS app. Local generation only; no Draw Things+ subscription, cloud compute, or in-app purchases used.
- **Python scripts in `tools/`,** written by Claude at my request and run by me: `make_storyboard_svgs.py` (storyboard sketches), `make_character_svgs.py` (character sheet images), `check_64px.py` (readability check at game size), `remove_specks.py` (the logged speck cleanups), `make_pose_guide.py` and `make_pose_guides.py` (pose guides warped from CHAR-REF), `make_env_guides.py` (the four environment guides), `process_env.py` (magenta cut-outs, the dome transparency edit, the table seam, the room resize, guide comparison), `batch2_review.py` (Batch 2 review images and contrast numbers). Shell scripts `batch1_*.sh` and `batch2_*.sh` run each batch's steps.
- **macOS built-ins:** `qlmanage` (SVG to PNG), `sips` (thumbnails), `shasum` (checksums).
- **Audio environment (Batch 3):** a Python 3.13.5 virtual environment outside the repository (`~/Documents/jellyhop-audio-env`, from Homebrew's Python).
  - **Libraries:** torch 2.14.1, torchaudio, diffusers 0.40.0, transformers 5.18.0, accelerate 1.15.0, torchsde 0.2.6 (needed by Stable Audio Open's default sampler), huggingface_hub 1.33.0, soundfile 0.14.0 with libsndfile 1.2.2 (WAV and OGG Vorbis), numpy 2.5.3, pyloudnorm 0.2.0 (ITU-R BS.1770 loudness), librosa 1.0.0 (beat tracking), matplotlib (waveform sheet).
  - **Licenses:** each library's is as published by its project.
  - **Downloads:** model files were downloaded to the Hugging Face cache (`~/.cache/huggingface`), not to the repository. The Hugging Face login is mine; the token is not in the repository or any log.
- **Batch 3 scripts in `tools/`,** written by Claude Code at my request:
  - `batch3_generate.py` (generation and the generation log, including the torchsde workaround);
  - `batch3_listening.py` (listening sheet and waveform contact sheet);
  - `batch3_compare.py` (loudness-matched comparison copies, outside the repo);
  - `batch3_process.py` (the planned edits for the game);
  - `check_game_audio.py`, `copy_game_audio.sh` and `batch3_swap.sh` (game audio checks, the byte-identical copy, one-command take swap);
  - `godot/tests/trace_audio.gd` (sound-call traces).

## Collaborators and AI assistance

- **Claude** (Anthropic, used through the claude.ai chat): checked the design against the assignment, asked design questions, drafted documents and prompts from my decisions, wrote the scripts above, and pointed out issues in outputs. Claude does not generate images or audio; its SVG drawings are design references, not generated assets. The environment guides drawn by Claude's script were inputs to SDXL at 50% strength, and the accepted plate, sauce, fork, and dome stay close to them (measured in ASSET-LOG.md, Batch 2).
- **Claude Code** (Anthropic): builds the slice in this repository from SLICE-BRIEF.md under the rules in CLAUDE.md (from 2026-10-02).
  - In Batch 3 (from AUDIO-BRIEF.md) it set up the audio environment, found and worked around the torchsde failure, and ran both models.
  - It wrote the Batch 3 scripts and checks, made the listening sheet and comparison copies, processed and wired in my selections, and traced the sound calls.
  - It drafted the Batch 3 logs from my decisions. It does not choose takes: every selection is mine.
- **Claude chat (claude.ai) in Batch 3:** recommended Stable Audio Open 1.0 for the sound effects and MusicGen-small for the music after checking their licenses (I chose them); drafted gen-inputs/batch3-audio-prompts.md (prompts, seeds, settings, planned edits), AUDIO-BRIEF.md and tools/audio_prompts_commit.sh, which I reviewed and committed before generation; guided the Hugging Face license and login steps; made one mistake: an unpinned install upgraded huggingface_hub to 2.1.1 in my conda base environment, which it then restored to 0.36.2 (outside the repository and the audio environment); recommended processing all 21 takes for an equal-loudness comparison, and offered the in-game leveling and SFX-WARN trigger options, which I decided; drafted the Claude Code prompts I pasted, carrying my decisions and notes word for word.
- **Me (Kiran):** every design decision and reason, every accept and reject decision, all generation runs, edits, and commits.
  - Batch 3 exception: Claude Code ran the audio generation and processing on my Mac, after my go-ahead. The selections, the leveling and trigger decisions, and the commits are mine.
- No other collaborators so far.

## Rights and responsible use

- No prompt or reference names a living artist, a copyrighted character, or a brand, and no existing music or recordings are used.
- Images fed to the model: my approved design (`gen-inputs/char-ref-guide.png`); pose guides built from the accepted CHAR-REF (`gen-inputs/pose-guide-*.png`); and four environment guides drawn by Claude's script `tools/make_env_guides.py` (`gen-inputs/ENV-*-guide.png`). No outside images.
- No real person's voice is cloned or imitated.
- Batch 3: no audio prompt names an artist, a band, a song, a brand, or a real person's voice (`gen-inputs/batch3-audio-prompts.md`). No existing recordings or music were used as inputs. Both audio models ran from text prompts only.
- No API keys or account credentials are stored in this repository.
