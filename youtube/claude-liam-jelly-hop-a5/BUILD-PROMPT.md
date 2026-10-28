# BUILD-PROMPT — how this film was asked for

Kiran's instruction for this film is committed verbatim in `prompts/prompt-4-film.txt` (commit b0112a1). In short: follow the installed Brutalist `godot-gamedev` skill with the `walker` modifier, use the A3 film's pipeline and local Kokoro narration with no paid tools, make one landscape 4K film of revision `77a6d10`, cover items 1–7 (game, state and 3D object; the four questions with code lines; colour line, shader, driver, controlled captures and the effect in play; hint experiment, sweep, one shader/two materials; generated vs hand-written lines; tests, mutations and headless limits; agent mistakes, uncertainty, next step, contributions, texture source, revision), label every scripted capture, reconstruction and held frame, use only facts from the committed files, write the beat sheet, script and prompts before rendering, then render and run every quality check. Do not edit `godot/` (except new capture scripts under `godot/tools/` if needed), the course documents, or commit.

Pipeline (same as `../claude-liam-jelly-hop-a3/`), run from `~/Documents/brutalist.art` with `PATH=/opt/anaconda3/bin:$PATH`:

0. `bash capture/run_captures.sh WORK_DIR` — one scripted-input take from a `git archive` snapshot of 77a6d10 (CAPTURE.md). The capture scripts live in this folder, not in `godot/`, so `godot/` is untouched.
1. `python3 tools/make_clips.py WORK_DIR` — `media/B07.mp4` and held frames, labels burned in.
2. `python3 tools/make_images.py WORK_DIR` — figures from Kiran's committed captures and logs, each input checked against its committed copy.
3. `python3 tools/make_reel.py` — beat_sheet.json, gamedev-evidence.json, SCRIPT.md.
4. `./art godot-gamedev --check REEL --game godot` must PASS.
5. `python3 runtime/scripts/generate_audio_kokoro.py REEL`.
6. `python3 tools/make_master.py` — timing, cues, `audio/master.wav`.
7. `python3 runtime/scripts/remotion_scenes.py REEL` — pilot, inspect, then all beats.
8. `./art final REEL --height 2160 --fps 30 --out REEL/exports/landscape --audio REEL/audio/master.wav`.
9. GATE T with `~/Documents/jellyhop-audio-env/bin/python runtime/scripts/type_check.py REEL`; frame QC in `_qc/REPORT.md`; `./art godot-gamedev --check` again.
