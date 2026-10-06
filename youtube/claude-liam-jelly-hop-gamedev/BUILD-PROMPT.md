# BUILD-PROMPT — rebuild this film end to end

Paste into Claude Code from the walker-jellyhop-kiran-g repository. It never publishes, uploads or pushes.

> Rebuild the Jelly Hop explainer in `youtube/claude-liam-jelly-hop-gamedev/` with the brutalist.art godot-gamedev skill (walker modifier). Do not edit brutalist.art, the game, art/, gen-inputs/ or ~/Documents/jellyhop-generations/. Use `PATH=/opt/anaconda3/bin:$PATH` for the toolkit.
> 1. `bash youtube/claude-liam-jelly-hop-gamedev/capture/run_captures.sh <empty scratch dir>`. Stop unless it prints CAPTURES OK and `captures.sha256` matches CAPTURE.md.
> 2. From the reel folder: `python3 tools/make_images.py <dir>`, `python3 tools/make_clips.py <dir>`, `python3 tools/make_reel.py`.
> 3. `./art godot-gamedev --check REEL --game godot` must PASS.
> 4. `python3 runtime/scripts/generate_audio_kokoro.py REEL`; check every narrated beat's measured audio fits its clip (B06 must not be retimed).
> 5. `python3 tools/make_master.py <dir>` (beat timings, cue times, and the premixed master with B09's engine audio; Kiran's decision). It must run before rendering.
> 6. Render the Remotion beats with `runtime/scripts/remotion_scenes.py REEL`, inspect a pilot, then all of them. Then `./art final REEL --height 2160 --fps 30 --out REEL/exports/landscape --audio REEL/audio/master.wav`.
> 7. Frame-level QC (`_qc/REPORT.md`): read sampled frames, check every label, listen across every transition and to B09. Run `./art godot-gamedev --check` again.
> 8. Record the MP4's filename, size, duration and SHA-256 in MEDIA.md. Report the results exactly as observed.
