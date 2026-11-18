# BUILD-PROMPT — how this film was asked for

Kiran's instruction for this film is `sessions/a7/prompt-10-film.txt` with a launch note appended. Neither is in the c1bbb13 snapshot; the text was given to this Claude Code session directly. In short: read CLAUDE.md; follow the installed Brutalist `godot-gamedev` skill with the `walker` modifier; use the A6 film's pipeline and narration (run from `~/Documents/brutalist.art`, scripted captures from a disposable copy, local Kokoro narration as "Liam, in for Bear", no paid tools); make one landscape 4K film for Assignment 7 (animation) of revision `c1bbb13` covering items 1–7 (the game, both clips and both routes; the four questions, each tied to a numbered line of Kiran's files; the sheet, its slicing and the frame track; the phase table beside the key times and the r0/r1 strips with verdicts and Claude's readings; the state machine in real play with an interrupt in each landing phase, as labelled scripted captures; the read-backs, structure/state/edge tests, the four mutations and the headless limits; the agent mistakes, the overruled r1 reading, the uncertainties, the next step, the contributions, the sheet's source and licence, and the revision). Label every fixture, scripted capture, reconstruction and held frame; use only committed facts; write the beat sheet, script and prompts before rendering; then render and run every quality check.

The launch note sets the locations: evidence and code excerpts are read from the read-only git-archive snapshot `snapshot-c1bbb13/` (no Godot run there, no change); every Godot import, launch and scripted capture runs in the disposable copy `run-copy-c1bbb13/`; the film is built in `/Users/kiran/Documents/jellyhop-a7-film-work/film/` with every WAV, MP3, MP4, rendered frame, capture script and working file under `/Users/kiran/Documents/jellyhop-a7-film-work/`; nothing in Kiran's repository is created or changed. Kiran copies the reviewed deliverables in after watching the export with sound.

Pipeline (as the A6 film), run from `~/Documents/brutalist.art` with `PATH=/opt/anaconda3/bin:$PATH`:

0. `bash film/capture/run_captures.sh` — checks every snapshot file is byte-identical in the run copy, adds the capture driver and a 4K `override.cfg` to the run copy only, imports, records one scripted-input Movie Maker take (CAPTURE.md).
1. `python3 tools/make_clips.py [--hold B11=S] [--hold B13=S] [--hold B17=S]` — `media/B11.mp4`, `B13.mp4`, `B17.mp4` and held frames, labels burned in.
2. `python3 tools/make_images.py` — figures from Kiran's committed captures and logs; each input checked against `git show c1bbb13:<path>`.
3. `python3 tools/make_reel.py` — beat_sheet.json, gamedev-evidence.json, SCRIPT.md.
4. `./art godot-gamedev --check REEL --game snapshot-c1bbb13/godot` must PASS.
5. `python3 runtime/scripts/generate_audio_kokoro.py REEL`.
6. `python3 tools/make_master.py` — timing, cues, `audio/master.wav`.
7. `python3 runtime/scripts/remotion_scenes.py REEL` — pilot, inspect, then all beats.
8. `./art final REEL --height 2160 --fps 30 --out REEL/exports/landscape --audio REEL/audio/master.wav`.
9. GATE T with `~/Documents/jellyhop-audio-env/bin/python runtime/scripts/type_check.py REEL`; frame QC in `_qc/REPORT.md`; `./art godot-gamedev --check` again.
