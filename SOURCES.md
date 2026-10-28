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
| Kokoro-82M, by hexgrad (https://huggingface.co/hexgrad/Kokoro-82M) | v1.0, run through kokoro-onnx 0.6.1 with `kokoro-v1.0.onnx` and `voices-v1.0.bin` from the brutalist.art toolkit; voice `am_onyx` ("Liam, in for Bear") | Locally on my MacBook Pro (Apple M4), inside the brutalist.art toolkit (Claude Code ran it for the film) | Model weights: Apache License 2.0 (model card tag "license: apache-2.0"); kokoro-onnx runtime: MIT | The explainer film's narration only (`youtube/claude-liam-jelly-hop-gamedev/`). A named synthetic voice, not a clone of a real person |

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

---

## Assignment 3 — 3D assets

Added 2026-10-13. The Assignment 2 sections above are unchanged.

### Starting point

The same Jelly Hop repository (`walker-jellyhop-kiran-g`) and Godot project as Assignment 2. Assignment 3 adds three 3D assets, their Blender sources and build scripts, a 3D showcase scene and a headless check.

### Tools and versions

| Tool | Version | Used for |
|---|---|---|
| Blender | 5.2.2 LTS, macOS arm64 | Building the three assets; my hand edit |
| Khronos glTF Blender I/O (built into Blender) | v5.2.40 | Exporting `.glb` files (+Y Up, default) |
| MCP for Blender server (`mcp-for-blender`) | 2.1.9, run with `uvx` | Letting Claude Code drive my open Blender session |
| MCP for Blender add-on (`blender_mcp.py`) | 1.8 | The Blender side of the MCP connection, on 127.0.0.1:9876 |
| uv | 0.13.0 (Homebrew) | Running the MCP server |
| Homebrew | 7.0.6 | Installing uv and coreutils |
| GNU coreutils | 9.12 (Homebrew) | `timeout` for the headless check |
| Godot | 4.7.2.stable.official.ed1daf0bf | Import, showcase scene, headless check |
| Claude Code | 2.1.288 (Opus 5.5) | Writing and running the Blender code, scene and check |

The MCP project is the community "MCP for Blender" named in the syllabus (website mcp-for-blender.com; add-on maintainer listed as Siddharth Ahuja). I installed it with the assignment's manual steps, not the one-line installer. `DISABLE_TELEMETRY=true` was set for the server, "Allow Telemetry" was left unticked in the add-on, and I declined the server's "Contribute session data" request. Note: the add-on's own text says that with telemetry off it still sends minimal anonymous usage data (tool names, success/failure, duration; no prompts or code); I could not verify whether the server setting stops that.

Claude Code access: I logged in with `/login` using my Northeastern premium Claude access. (The session header showed "Opus 5.5 · API Usage Billing".)

### Geometry, materials and rights

- All geometry was built inside my own Blender session from Blender's basic shapes (cubes, a cylinder, UV spheres), by Python that Claude Code ran through the MCP's `execute_blender_code`, after I approved each plan and each call. The exact code is in `tools/blender/build_fork.py`, `build_dome.py` and `build_platform.py`.
- No downloaded models and no AI-generated meshes. Poly Haven, Sketchfab, Poly Pizza, Hyper3D Rodin, Hunyuan3D and Tripo were all off (the add-on's API-key fields were left empty, and `get_addon_status` reported every library and generator off), and `generate_3d`, `search_assets` and `import_asset` were never called.
- Colours: Fork_Silver and the original dome colours were chosen by Claude Code; I changed all three dome colours by hand (TEST-REPORT A3.10). Platform_Biscuit #B8752A was chosen by Claude Code and approved by me; Platform_Cream reuses my hand-edited dome cream, #F9DEA2. No external colour or material sources.
- Nothing paid was used. No credentials are in the repository; the MCP registration lives in `~/.claude.json`, outside the repo.

### AI assistance and my contributions

- **Claude Code** proposed each asset's part sizes, segment counts and materials, wrote and ran all `execute_blender_code` calls, wrote `godot/showcase/a3_assets.tscn` and `godot/tests/test_a3_assets.gd`, and ran the check.
- **Claude (claude.ai chat)** guided me step by step, checked plans and numbers with me, and organised my notes and reports into these documents. It did not run anything on my machine.
- **Me:** chose the three assets, the jelly scale and every size, origin, look and budget in the brief; wrote the interface notes; ran every install, export, import and git command; approved, modified or rejected each plan and call (details in FRICTIONAL.md); made the hand edit to the dome colours; and did all the human checks in Blender and Godot.

### Collaborators

None.

### The A3 explainer film

- **Workflow:** the course-provided Brutalist `godot-gamedev` skill with the `walker` modifier (local brutalist.art checkout at commit 6a8380a, not modified), with Remotion scenes.
- **Narration:** Kokoro-82M (kokoro-onnx, Apache-2.0), voice `am_onyx` ("Liam, in for Bear"), run locally at no cost. A local faster-whisper model was used only to check the corrected B05 narration.
- **Pictures:** my own session screenshots from `evidence/a3/screenshots/` (some cropped, none retouched), code excerpts from my repository, and the headless check log. No downloaded or generated images or video.
- **Made by:** Claude Code (2.1.296, logged in with my Northeastern Claude Enterprise access) in an unattended run on 2026-10-13, then rebuilt after my script review. Script, beat sheet, figures and narration are AI-made; my contributions are the rules for the run, the script review and correction, and watching the final export. Details: FRICTIONAL.md (2026-10-13, the explainer film) and `youtube/claude-liam-jelly-hop-a3/BUILD-LOG.md`.
- **Final film:** `claude-liam-jelly-hop-a3.mp4`, SHA-256 `10adb47d931ffa23d500f409658eee709397dcc48303ae61805a62aadfe599fc`, on YouTube, unlisted: https://youtu.be/RBnJpG0Cnjc (not in git).

## Assignment 5 — sources, tools and AI contributions

**Textures**
- **Dark Wood**, Poly Haven, https://polyhaven.com/a/dark_wood. Authors: Dario Barresi (baking), Dimitrios Savva (photography), Rico Cilliers (tiling). Licence CC0, checked 2026-10-27. 2K PNG, unmodified; full credits and SHA-256s in `godot/assets/textures/dark_wood/ATTRIBUTION.md`. Normal convention used: OpenGL (`_nor_gl`); `_nor_dx` kept only to calibrate the curl check.
- **Hint strip** (`godot/assets/textures/hint_strip/hint_strip_3x1.png`, greys 64/128/192): written by code, `godot/tools/make_hint_strip.gd`. No generative image model was used in A5.

**Tools**
- Godot 4.7.2.stable.official.ed1daf0bf (Compatibility renderer; one Forward+ comparison run by command-line override).
- Claude Code 2.1.309 through my Northeastern access, run with `claude -p`, scoped tools and kept transcripts in `sessions/`. Nothing paid.
- Claude (claude.ai chat), used as a step-by-step guide throughout A5.
- Python 3 with Pillow for pixel measurements; macOS screenshot for the one OS-screenshot comparison.

**Written by me (hand-written)**
- `godot/shaders/fork_warning.gdshader`, `table_wood.gdshader`, `hint_experiment.gdshader`. No agent edited them (`git diff godot/shaders/` empty after every session).
- LANGUAGE-NOTES.md answers; CHANGE-BRIEF.md decisions and revisions; the materials and scenes made in the editor; every human check.

**Generated by Godot**
- `godot/shaders/standard_generated.gdshader`: the editor's Convert to ShaderMaterial output, saved unedited.

**Written by Claude Code (agent), reviewed by me**
- CLAUDE.md draft (session 1; my review in dda6bd9).
- The driver in `godot/features/fork/fork.gd`, `godot/materials/fork_warning.tres`, `godot/tests/test_fork_warning.gd` (sessions 2b–2d, from my approved plan).
- `godot/MATERIALS.md` and `godot/tests/test_materials.gd` (session 3; my corrections in 07106ef).

**Written by Claude (chat), run and checked by me**
- `godot/tests/probe_headless.gd`, `godot/tests/calibrate_normal_check.gd`, `godot/tools/make_hint_strip.gd`, `godot/tools/capture_a5.gd`, `godot/tools/capture_shared.gd`.
- File text of `godot/showcase/hint_experiment.tscn` and `godot/scratch/standard_scratch.tscn`, opened and saved by me in the editor.
- Wording drafts of AGENTS.md, CHANGE-BRIEF.md, TEST-REPORT.md and FRICTIONAL.md from my decisions and our record; the blend options and strength table I chose from.

**Copied verbatim from the course handout**
- `godot/tests/normal_map_check.gd` (the curl check); prompts 1, 2 and 3 in `prompts/` (with my additions labelled).
