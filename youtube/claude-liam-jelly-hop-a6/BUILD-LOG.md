# BUILD-LOG — Jelly Hop A6 film (godot-gamedev + walker)

What was run for this film, with results as observed. Claude Code ran every command on Kiran's Mac on 2026-11-08 (about 02:53–04:25 EST) under `claude -p`, from Kiran's committed request `sessions/a6/prompt-9-film.txt` and its launch note. **Every choice here is Claude Code's** unless quoted from that request.

## Setup
- Skill: `~/Documents/brutalist.art/skills/make/godot-gamedev/SKILL.md` with `walker` (toolkit commit 6a8380a, not modified; its pre-existing uncommitted `runtime/remotion/package-lock.json` change was left alone), its evidence reference, ai-explainer's bookend laws, riff, OUTRO-LOCK.md, RENDER-TARGETS.md, PIPELINE-SAFETY.md, godot-waikthrough's capture contract.
- Pipeline as the A5 film: Anaconda Python, local Kokoro `am_onyx`, Remotion via `runtime/scripts/remotion_scenes.py`, `./art final`. No paid service, no install.
- `./art scenes "Godot editor code scene tree inspector assets"` → GodotDevWorkbench, GodotDesignFigure (used).
- Revision shown: `8004dea`. Evidence and code read from the read-only snapshot; every figure input (29 files) matched `git show 8004dea:<path>` byte for byte.

## In-play capture (CAPTURE.md)
- `capture/run_captures.sh` in the disposable run copy, Movie Maker, windowed, 4K: **CAPTURE OK** on the first take (scoot gap 9 ticks, Esc pause, WON tick 1233, replay tick 1384, 0 puff/SFX-LAND mismatches, 0 splats). Nothing was added to the snapshot or the repository.

## Files written before rendering
`tools/make_clips.py`, `tools/make_images.py`, `tools/make_reel.py`, `tools/make_master.py` → `beat_sheet.json`, `gamedev-evidence.json`, `SCRIPT.md`; `PROMPTS.md`, `BUILD-PROMPT.md`, `FACTCHECK.md`, `COMPONENTS.md`, `SHOTLIST.md`, `RIFF.md`, `CAPTURE.md`, `SOURCES.md` (this film's own record, in the film folder).

## Checks, fixes and renders, in order
1. Clip review: the first crops spent 40% of the frame on the curtain and cut the game's PAUSED/SAFE HUD text. Effect A and the intro crop were moved up; the pause/win excerpt became the full native frame.
2. Figure review: Mutation 2's FAIL line overlapped Mutation 1's (an unwrapped JSON line); the cost compare lines ran off the canvas edge; most figures left a third of the canvas empty with small type. Fixed by character-wrapping the verbatim lines, a 3200 × 1250 canvas to match the figure box, and larger type. **Caught in my own code before running it:** a replacement of the log's `->` with `→`, which would have made a "verbatim" line not verbatim; removed.
3. `./art godot-gamedev --check` → **PASS** (17 files, 105 exclusions, 6 components, 6 exact excerpts, 6 code → result pairs).
4. Kokoro: 30 beats, $0.00. B18's narration (11.6 s) did not fit its 8.8 s clip: excerpt 2 now starts at the plate-6 landing (real footage) plus a 2.5 s labelled held frame of the replay. No hold was placed inside the pause.
5. Pilots B06, B09, B25, BVDT inspected: readable, nothing clipped. Then all beats.
6. Frame inspection of every beat at 85%: **three defects.**
   - **B01:** the hesitant writer never made its correction. `BrutalistHesitantWriter` matches single words only, and I had given it the phrase "times the GPU". Changed to trigger `GPU` → `CPU only` ("A headless run times the CPU only."), narration aligned, B01 audio regenerated; the correction is on screen by 75% of the beat.
   - **B10:** wrapped comment lines pushed line 26 (a highlighted cue) out of the panel. The excerpt is now lines 21–26.
   - **B18 held frame:** a fragment of the previous label showed beside the "Held frame" label. My bug: uncropped frames were labelled in place. `view()` now copies.
7. GATE T (`~/Documents/jellyhop-audio-env/bin/python runtime/scripts/type_check.py`): **PASS, 0 FAIL** (`_qc/gate-t-2.log`).
8. First `./art final`: **REFUSED** by GATE V, 2 MAJOR on B11 (`low-contrast`, regional separation 0.02). My one declared region was the union of all three label lines over all frames, mixing dark label boxes, cream labels and bare wall. Replaced by one region per label line (that line's box in every frame), as the A5 film did. No pixels changed in B11; B18 changed only by its held-frame label size (40 → 44 px, missed in an earlier edit).
9. Second `./art final REEL --height 2160 --fps 30 --out REEL/exports/landscape --audio REEL/audio/master.wav` → written, receipt **ready**; **GATE V 60 frames, 0 BLOCKER, 0 MAJOR**. GATE T inside the wrapper printed "skipped — missing deps" (Anaconda, as in A2–A5), so it was re-run directly after the export: **PASS** (`_qc/gate-t-final.log`).
10. `./art godot-gamedev --check` at handoff: **PASS** (same counts).

## Isolation
- Snapshot: all 843 files byte-identical to `snapshot-manifest-before.txt` after the build.
- Kiran's repository: no file created or changed. Only read-only git commands were run (`log`, `show`, `diff`, `rev-parse`, `status`); `git status` refreshed `.git/index`'s stat cache (mtime 04:19). Nothing committed.
- Run copy: received the capture driver, `override.cfg` and Godot's import cache, as the launch note allows.

## Final
- `exports/landscape/claude-liam-jelly-hop-a6.mp4`, 647.700 s, 67,876,087 bytes, SHA-256 `7c094ecaebacabaa84d2c93928b60dc8955f6cde2ef169983c23b8532197b0db` (MEDIA.md). My QC: `_qc/REPORT.md` (bottom section).
- Toolkit side effect: `remotion_scenes.py` updates `brutalist.art/runtime/remotion/_bench/consumers.json` (gitignored there).
- **Not done:** a human viewing with sound; Kiran's script review; no transcript check of the narration. Nothing committed.
