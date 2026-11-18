# BUILD-LOG — Jelly Hop A7 film (godot-gamedev + walker)

What was run for this film, with results as observed. Claude Code ran every command on Kiran's Mac on 2026-11-17 (about 14:40–16:55 EST), from Kiran's film request (`sessions/a7/prompt-10-film.txt` with its launch note, given to the session directly). **Every choice here is Claude Code's** unless quoted from that request.

## Setup
- Skill: `~/Documents/brutalist.art/skills/make/godot-gamedev/SKILL.md` with `walker` (toolkit commit 6a8380a, not modified; its pre-existing uncommitted `runtime/remotion/package-lock.json` change left alone), its evidence reference, and the A6 film's tools as the pipeline template (read from the snapshot).
- Pipeline as the A6 film: Anaconda Python, local Kokoro `am_onyx`, Remotion via `runtime/scripts/remotion_scenes.py`, `./art final`. No paid service, no install.
- `./art scenes "Godot editor code scene tree inspector assets"` → GodotDevWorkbench (used), GodotDesignBoard (GodotDesignFigure used, as A6).
- Revision shown: `c1bbb13`. Evidence and code read from the read-only snapshot; every figure input (41 files) matched `git show c1bbb13:<path>` byte for byte.

## In-play capture (CAPTURE.md)
- Headless dry run of the driver in the run copy: first failed on a relative log path, then on my own check bug (it searched for the hop and second landing before those ticks had run); fixed; then CAPTURE OK.
- `capture/run_captures.sh` first stopped: the dry-run import had created 9 `.gd.uid` sidecars in the run copy. The check now requires every snapshot file byte-identical and allows only import-generated `.gd.uid` extras (listed, disclosed).
- Windowed Movie Maker take, 4K: **CAPTURE OK**, 859 per-tick checks, 0 failures; same ticks as the headless dry run.

## Files written before rendering
`tools/make_clips.py`, `make_images.py`, `make_reel.py`, `make_master.py` → `beat_sheet.json`, `gamedev-evidence.json`, `SCRIPT.md`; `PROMPTS.md`, `BUILD-PROMPT.md`, `FACTCHECK.md`, `COMPONENTS.md`, `SHOTLIST.md`, `RIFF.md`, `CAPTURE.md`, `SOURCES.md`.

## Checks, fixes and renders, in order
1. Figure review: B18's land.tres line overflowed its column (stopped by the script's overflow guard) → moved to a full-width row. B20's verdict line overlapped its source line → smaller frames.
2. `./art godot-gamedev --check` → **PASS** (22 files, 118 exclusions, 5 components, 8 exact excerpts, 8 code → result pairs).
3. Kokoro: 30 beats, $0.00. B11's narration (12.05 s) did not fit its 8.3 s clip and B13's (13.08 s) its 12.7 s: B11's two replays slowed from 1/12 to 1/16 speed, and labelled held frames added at the clips' ends (B11 3.0 s, B13 1.2 s, B17 0.5 s). No hold inside a landing or an interrupt.
4. Pilots B01, B05, B15, B26 inspected. **Defect found:** GodotDevWorkbench does not scroll, and at 28 px it shows 12 lines, so B05's cued lines 15 and 17 were never on screen. B05 cut to lines 5–17, B12 to 215–227, five excerpts set to 24 px; every code beat then inspected at its deepest cue: all cued lines visible. B14 and B16 note panels overflowed → notes shortened; B16 now 227–236 so its last line shows.
5. All beats rendered, every beat inspected at 85%.
6. GATE T: **FAIL**, 2 beats. B24 output line 13 words > 12 → shortened. B20 per-blob contrast 2.85:1: first fixed the phase-coloured labels (no effect), then found the flagged blob was a strip frame's brown wall against mid-tone phase-coloured borders → neutral borders, phase shown as a bar under each frame. GATE T then **PASS, 0 FAIL** (`_qc/gate-t-3.log`).
7. A first `./art final` had been started before the GATE T result and completed with the old B20/B24 (the wrapper skips GATE T under Anaconda, "missing deps", as in A2–A6); it was overwritten.
8. Re-render, then `./art final REEL --height 2160 --fps 30 --out REEL/exports/landscape --audio REEL/audio/master.wav` → written, receipt **ready**; **GATE V 60 frames, 0 BLOCKER, 0 MAJOR**.
9. Export QC (`_qc/REPORT.md`, bottom), `./art godot-gamedev --check` at handoff: **PASS** (same counts).

## Isolation
- Snapshot: all 1,077 files byte-identical before and after (`_qc/snapshot-manifest-before.txt`, `-after.txt`).
- Run copy: received the capture driver, `override.cfg`, Godot's import cache and 9 import-generated `.gd.uid` files.
- Kiran's repository: this session created and changed no file there; only read-only `git log`, `git show`, `git diff` (tree to tree) and `git rev-parse` were run. **Observed:** during the session, files in the repository changed from another source — `sessions/a7/prompt-11.txt`, `session-11.jsonl`, `verify_fresh_clone.sh`, `prompt-12.txt`, `session-12.jsonl`, edits to FRICTIONAL.md, SOURCES.md, SUBMISSION.md, TEST-REPORT.md, CLAUDE.md and four session transcripts, a commit at 15:46:09 and a remote-ref update at 15:28:46. The film was built only from the c1bbb13 snapshot, so it does not reflect those changes. Nothing committed by this session.

## Final
- `exports/landscape/claude-liam-jelly-hop-a7.mp4`, 622.967 s, 51,364,479 bytes, SHA-256 `deb57025203a194150e436b4ce198af71d85ad0b3b76bd7ded0b98dda71411ac` (MEDIA.md).
- Toolkit side effect: `remotion_scenes.py` updates `brutalist.art/runtime/remotion/_bench/consumers.json` (gitignored there).
- **Not done:** a human viewing with sound; Kiran's script review; no transcript check of the narration. The `rendered` provenance stamp in beat_sheet.json is present only for B20 (the sheet was regenerated after the full render; every other beat's props were unchanged).
