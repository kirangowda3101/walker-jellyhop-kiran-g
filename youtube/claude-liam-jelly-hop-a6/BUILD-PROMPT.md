# BUILD-PROMPT — how this film was asked for

Kiran's instruction for this film is committed verbatim in `sessions/a6/prompt-9-film.txt` (commit 6c0d7c5), with a launch note appended for this session (`sessions/a6/prompt-9-film-launch-note.txt`, commit 545fb01). In short: follow the installed Brutalist `godot-gamedev` skill with the `walker` modifier, use the A5 film's pipeline and local Kokoro narration with no paid tools, make one landscape 4K film of revision `8004dea`, cover items 1–7 (the game and both effects; emission/process/draw with one cited line each and the headless price; Effect A intent, strips r0/r1, prediction, comparison, verdict and the effect in play with a quick-repeat attempt; Effect B the same way plus box emission, the additive material and its start/stop/pause behaviour; generated shader lines 145 and 254 beside the brief; tests, mutations, prices against budgets and the headless limits; agent mistakes, the overruled strip reading, uncertainty, the next step, contributions, texture sources and the revision), label every fixture, scripted capture, reconstruction and held frame, use only facts from the committed files, write the beat sheet, script and prompts before rendering, then render and run every quality check.

The launch note overrides the film location: the film is built in `/Users/kiran/Documents/jellyhop-a6-film-work/film/`, evidence and code excerpts are read from the read-only git-archive snapshot `snapshot-8004dea/`, every Godot import and capture runs in the disposable copy `run-copy-8004dea/`, and nothing in Kiran's repository is created or changed. Kiran copies the reviewed deliverables in after watching the export with sound.

Pipeline (as the A5 film), run from `~/Documents/brutalist.art` with `PATH=/opt/anaconda3/bin:$PATH`:

0. `bash film/capture/run_captures.sh` — checks the run copy's `godot/` against the snapshot file for file, adds the capture driver and a 4K `override.cfg` to the run copy only, imports, records one scripted-input Movie Maker take (CAPTURE.md).
1. `python3 tools/make_clips.py [--hold B11=S] [--hold B18=S]` — `media/B11.mp4`, `media/B18.mp4` and held frames, labels burned in.
2. `python3 tools/make_images.py` — figures from Kiran's committed captures, screenshots and logs; each input checked against `git show 8004dea:<path>`.
3. `python3 tools/make_reel.py` — beat_sheet.json, gamedev-evidence.json, SCRIPT.md.
4. `./art godot-gamedev --check REEL --game snapshot-8004dea/godot` must PASS.
5. `python3 runtime/scripts/generate_audio_kokoro.py REEL`.
6. `python3 tools/make_master.py` — timing, cues, `audio/master.wav`.
7. `python3 runtime/scripts/remotion_scenes.py REEL` — pilot, inspect, then all beats.
8. `./art final REEL --height 2160 --fps 30 --out REEL/exports/landscape --audio REEL/audio/master.wav`.
9. GATE T with `~/Documents/jellyhop-audio-env/bin/python runtime/scripts/type_check.py REEL`; frame QC in `_qc/REPORT.md`; `./art godot-gamedev --check` again.
