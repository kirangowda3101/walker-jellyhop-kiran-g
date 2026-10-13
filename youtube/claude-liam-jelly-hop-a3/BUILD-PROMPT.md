# BUILD-PROMPT — how this film was asked for

Kiran's overnight instruction (2026-10-13), Phase 2, summarised by Claude Code (the full text is in the session, not reproduced here):

> Read the installed course-provided Brutalist godot-gamedev skill instructions with the walker modifier and follow them. Use the same pipeline and narration approach as my Assignment 2 film, with no new paid tools. Make ONE landscape film at the skill's native 4K, plain and short. It must identify Jelly Hop, the three assets and why the game needs each; show my real Blender session using my own screenshots (23, 12, 13, 14, 15), each labelled as my screenshot; show the three assets in the Godot scene (19) and the headless check numbers beside the brief, labelled as headless; state what I checked, what remains uncertain, what Claude got wrong (TEST-REPORT A3.9), one next step, the human and AI contributions, and the source revision; use the Walker opening/summary and Verdict → Your Turn → regular outro. Write the beat sheet, script and prompts as files in the film folder before rendering. Then render, and run all the skill's quality checks.

Pipeline (same as `youtube/claude-liam-jelly-hop-gamedev/`), run from `~/Documents/brutalist.art` with `PATH=/opt/anaconda3/bin:$PATH`:

1. `python3 tools/make_images.py` (reel folder) — figures from Kiran's screenshots, hash-checked.
2. `python3 tools/make_reel.py` — beat_sheet.json, gamedev-evidence.json, SCRIPT.md.
3. `./art godot-gamedev --check REEL --game godot` must PASS.
4. `python3 runtime/scripts/generate_audio_kokoro.py REEL`.
5. `python3 tools/make_master.py` — timing, cues, `audio/master.wav`.
6. `python3 runtime/scripts/remotion_scenes.py REEL` — pilot, inspect, then all beats.
7. `./art final REEL --height 2160 --fps 30 --out REEL/exports/landscape --audio REEL/audio/master.wav`.
8. GATE T with `~/Documents/jellyhop-audio-env/bin/python runtime/scripts/type_check.py REEL`; frame QC in `_qc/REPORT.md`; `./art godot-gamedev --check` again.
