# SOURCES — Jelly Hop: Fork From Above

## The game shown

- **Repository:** walker-jellyhop-kiran-g, revision `7a48ea8cb29c04dfafa3e6df6fe491e1807c8409`. Godot `4.7.2.stable.official.ed1daf0bf`.
- **Snapshot build_id** (SHA-256 of `capture/source-manifest.txt`): `c71c049161eed3b05b224458078085533e2da516b179d6da69b966395d57b0ba`.
- **Starting point:** walker-jumpman "First Steps" starter by Nik Bear Brown (https://github.com/nikbearbrown/walker-jumpman), commit `9387542`, imported in `d7f0c97` (the project's SOURCES.md).
- **Code excerpts on screen** are read by line range from the files and checked by `./art godot-gamedev --check`:
  - `godot/features/player/player.gd` lines 149–162
  - `godot/game/session.gd` lines 294–301
  - the "before" line in B07 comes from `git show 23ae39c -- godot/game/session.gd`

## Native engine captures

| File | SHA-256 | Method |
|---|---|---|
| run-01.avi (outside git) | `885d6be57b2b23bc6163de2a511779644b0b00361ce04449b01bcf9f408b84f6` | scripted input, Movie Maker, 3840×2160 at 60 fps + PCM audio |
| run-02.avi (outside git) | `62fe1f141a8dcae4b0214f67bc9e0efbc14a864c6ee80487be4bc4914a11f6fd` | same |
| capture/run-01-inputs.jsonl | `75a929aac8d940391bfa1a2f6e3f773d3e5c9acdd6e35fe337497734c8a10666` | driver log |
| capture/run-02-inputs.jsonl | `34656a34656114889e8afe6923054975bfe2815d6ae3bb577212d66001cf5641` | driver log |

Derived media hashes are in `media/media.sha256` and `images/images.sha256`. Method and disclosures: CAPTURE.md.

## Project files shown or quoted

CONCEPT.md (pillars, two-sentence concept), CHARACTER-SHEET.md (via `gen-inputs/char-ref-guide.png`), ASSET-LOG.md (CHAR-REF prompt, settings, cleanup; Batch 2 guide-change percentages; restored prompts file), FRICTIONAL.md (audition notes; Batch 2 prompts-file correction), TEST-REPORT.md (Kiran's playtest notes; §9 limitations), `evidence/batch3-audition.md`, `evidence/batch3-review.md`, `evidence/batch3-audio-trace-{before,after,after2}.txt`.

Raw generation read (not copied into git): `~/Documents/jellyhop-generations/CHAR-REF-B-seed7270-s60.png` (SHA-256 `2c0f71a7f4eba5a56c116b8ca648b2ed15c3fe6ada8887eab7e5ddb6d410a763`), shown scaled inside `images/B03-design-prompt-raw.png` and zoomed inside `images/B04-edits-to-engine.png`.

## Which model produced which asset (from the project's SOURCES.md and ASSET-LOG.md)

| Asset | Model | Where |
|---|---|---|
| Jelly (12 poses), plate, sauce, fork, dome, room, table | Stable Diffusion XL Base 1.0 (Stability AI), CreativeML Open RAIL++-M | locally in Draw Things 26.0924.0 |
| SFX-HOP, -LAND, -WARN, -SPLAT-FORK, -SPLAT-SAUCE, -WIN | Stable Audio Open 1.0 (Stability AI), Stability AI Community License | locally (MPS), `tools/batch3_generate.py` |
| MUS-LOOP | MusicGen-small (Meta), CC-BY-NC 4.0 | locally (MPS) |
| Fork shadow, HUD text | drawn in code (`fork.gd` `_draw`, `ui/hud.gd`) | — |

## This film

- **Toolkit:** brutalist.art, `skills/make/godot-gamedev` with the `walker` modifier; bookends from `ai-explainer`; outro per OUTRO-LOCK.md. Not edited.
- **Narration:** Kokoro (kokoro-onnx, model `kokoro-v1.0.onnx`), voice `am_onyx` ("Liam, in for Bear"), local, free, no key. It is a named synthetic voice, not a clone.
- **Scenes:** Remotion `ClaudeComposerAsk`, `BrutalistHesitantWriter`, `GodotDesignFigure`, `GodotDevWorkbench` (labeled "Godot editor reconstruction · source-backed teaching view"), `ClaudeVerdictArtifact`, `ClaudeTitleOutro`.
- **Who did what:** Claude Code (Claude Opus 5.5) wrote the capture driver, the scripts in `tools/`, the figures, the beat sheet and the draft narration, and ran every command, on Kiran's Mac. Kiran approves the script, the next-step line and the final film.
- No paid service, API key or upload.
