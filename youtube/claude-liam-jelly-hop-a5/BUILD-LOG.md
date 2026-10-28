# BUILD-LOG — Jelly Hop A5 film (godot-gamedev + walker)

What was run for this film, with results as observed. Claude Code ran every command on Kiran's Mac on 2026-10-28 (about 02:57–05:15 EDT) under `claude -p`, from Kiran's committed request `prompts/prompt-4-film.txt`. **Every choice here is Claude Code's** unless quoted from that request.

## Setup
- Skill: `~/Documents/brutalist.art/skills/make/godot-gamedev/SKILL.md` with `walker` (toolkit commit 6a8380a, not modified), its evidence reference, ai-explainer's bookend laws and OUTRO-LOCK.md.
- Pipeline as the A3 film: Anaconda Python, local Kokoro `am_onyx`, Remotion via `runtime/scripts/remotion_scenes.py`, `./art final`. No paid service, no install.
- `./art scenes "Godot editor code scene tree inspector assets"` → GodotDevWorkbench and GodotDesignFigure (used).
- Revision shown: `77a6d10`. HEAD was `b0112a1` (adds only the film prompt). All 44 repository inputs to the figures matched their copies at 77a6d10 byte for byte.

## In-play capture (CAPTURE.md)
- `capture/run_captures.sh` on a `git archive` snapshot of 77a6d10 outside the repo, Movie Maker, windowed, 4K: **CAPTURE OK** (fork splat tick 476, WON tick 1091). Nothing in `godot/` was added or changed: the capture scripts live in this folder.

## Files written before rendering
`tools/make_clips.py`, `tools/make_images.py`, `tools/make_reel.py` → `beat_sheet.json`, `gamedev-evidence.json`, `SCRIPT.md`; `PROMPTS.md`, `BUILD-PROMPT.md`, `FACTCHECK.md`, `COMPONENTS.md`, `SHOTLIST.md`, `RIFF.md`, `CAPTURE.md`, `FILM-SOURCES.md`.
- **SOURCES.md:** this run's permission rules deny writing any file named `SOURCES.md` (they protect the repository's own). I did not work around the rule; the film's source record is `FILM-SOURCES.md`.

## Checks and renders, in order
1. Figure review before rendering: B09's MD5 lines ran off the edge, B12's value lines nearly touched, and the B18 sweep's third column overflowed. All three were fixed by changing the layout. I also removed a phrase I had invented in B09's Rule 1 row ("on the frame before = 0"), which the log does not say.
2. `./art godot-gamedev --check` → **PASS** (34 files, 74 exclusions, 7 components, 6 exact excerpts, 6 code → result pairs).
3. Kokoro: 25 beats, $0.00. `make_master.py`: 518.567 s; B07's narration (11.50 s) fits its 12.5 s clip.
4. Pilots B04, B05 and B20 were inspected; they were readable and nothing was clipped. All beats were then rendered.
5. Frame inspection: **B08** clipped lines 144–147, including the highlighted formula line, so the excerpt became lines 141–147. **B13** clipped its closing braces, so it now shows lines 4–15. **My mistake while fixing this:** I re-ran `make_reel.py`, which drops the `audio_file` fields Kokoro had written, so `make_master.py` crashed. A `| tail -1` pipe hid the crash, and B08 and B13 were re-rendered with untimed props. I fixed `make_master.py` to fall back to the existing `mp3/beat-<id>.mp3` (and stop if it is missing), re-timed (same 518.567 s), re-rendered both beats, and stopped using pipes that hide exit codes.
6. GATE T (`~/Documents/jellyhop-audio-env/bin/python runtime/scripts/type_check.py`): **FAIL, 5** (`_qc/gate-t-2.log`):
   - B02, B12, B14 and B18: `contrast-local §8.3b` on regions inside engine captures (curtain folds, dark wood, the hint strip's black margin).
   - B20: a 13-word output line.
   - The fixes were crops and layout only, with no retouching: B02's held frame was cropped above the curtain (labelled); B12's captures were cropped tighter and enlarged; B14 shows each quad without the black surround; B18's thumbnails show the worn table only (the sweep changes only the table's material); B20's line was shortened.
   - GATE T then **FAIL, 2** (B12, B18). B12 was restacked larger and B18 cropped above the serving board. GATE T: **PASS, 0 FAIL** (`_qc/gate-t-4.log`).
7. `./art final REEL --height 2160 --fps 30 --out REEL/exports/landscape --audio REEL/audio/master.wav` → written, receipt **ready**; **GATE V 50 frames, 0 BLOCKER, 0 MAJOR** (B07's label regions tested). GATE T inside the wrapper printed "skipped — missing deps" (Anaconda's scipy/NumPy mismatch, as in A2 and A3), so it was re-run directly after the export: **PASS** (`_qc/gate-t-5.log`).
8. `./art godot-gamedev --check` at handoff: **PASS** (same counts).

## Final
- `exports/landscape/claude-liam-jelly-hop-a5.mp4`, 518.567 s, 51,639,549 bytes, SHA-256 `240e7409d3974cd49357e429564657ec6f6743fb5a9ad4daefb4aa547e34b237` (MEDIA.md). My QC: `_qc/REPORT.md` (bottom section).
- Toolkit side effect: `remotion_scenes.py` updates `brutalist.art/runtime/remotion/_bench/consumers.json` (gitignored there).
- **Not done:** a human viewing with sound; Kiran's script review. Nothing committed.
