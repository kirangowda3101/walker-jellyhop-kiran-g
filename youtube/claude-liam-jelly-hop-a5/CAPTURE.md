# CAPTURE — in-play footage for the A5 film (B07 and the B02 held frame)

One **scripted-input** take, recorded by Claude Code on 2026-10-28 (03:02 EDT). It is not a human playtest; Kiran's human playtest is `evidence/a5-playtest-notes.md` (TEST-REPORT.md A5.5), quoted as text, never shown as footage.

## Method (the A2 film's capture contract, reused)

- **Snapshot:** `git archive 77a6d10 | tar -x` into `/Users/kiran/Documents/jellyhop-a5-film-work/snapshot`, outside the repository. The repository's `godot/` and its `.godot/` cache were not used or changed. No file was added under `godot/tools/`.
- **build_id:** `7da8a555f6c137f4f660043245ddabe8623730abfdbb39edcec42eccf48f0768` = SHA-256 of `capture/source-manifest.txt` (SHA-256 of all 134 files in the snapshot's `godot/`, including `.uid` files), taken before the two copy-only files below were added.
- **Two copy-only additions to the snapshot** (disclosed; not in the repository): `godot/override.cfg` (window 3840 × 2160 so Movie Maker records natively at 4K; the game's canvas stays 1280 × 720, stretch mode `canvas_items`) and `godot/capture/capture_driver.gd` (this folder's driver).
- **Engine:** Godot 4.7.2.stable.official.ed1daf0bf, Compatibility renderer, **windowed** (not headless), `--write-movie … --fixed-fps 60`. Movie Maker renders offline at a fixed 60 fps, so the footage says nothing about real-time frame pacing.
- **Driver:** `capture/capture_driver.gd` is the A2 film's driver, unchanged in what it presses (Right arrow and Space through `Input.parse_input_event`, timed with the read-only planner `tests/route_driver.gd`), plus one read-only addition: every physics tick it logs each fork's phase, the `warning` value its own material holds (`get_shader_parameter`) and its screen position. It never sets a shader parameter and never writes `t`, `held`, `hold_pending`, `announced` or session state. One disclosed setting, as in A2: `game.test_mode = true` (only disables pause-on-focus-loss).
- **Route (main):** intro pan untouched → hop to plate 2 → stay until its fork strikes (fork splat, tick 476) → re-form → hops to plate 6 → into the dome (WON, tick 1091) → 2.5 s hold. Result: `CAPTURE OK: route complete: fork splat=true cause=fork wins=1`.
- **Script:** `capture/run_captures.sh` (copy of the A2 script; `set -Eeuo pipefail`, ERR trap, import before recording, checks the exit code, `CAPTURE OK`, and the AVI's streams). Console output: `capture/capture-console.log`.

## Files

`capture/captures.sha256`:

    0b545b7d9eed2558d7888d90d08016d7cfc84b8d9c4d8564331f574fb58a78be  run-a5.avi
    232c3861bfba75aae31426c948a55c5b1be5ce5d017ff250efb94e61fc163d1d  run-a5-inputs.jsonl

The AVI (MJPEG 3840 × 2160, 60 fps, with PCM audio) stays outside git in the work folder. The input/fork log is in this folder.

## How it is used and labelled

`tools/make_clips.py` checks both hashes, cuts on tick boundaries (movie frame = tick − 1), keeps every other frame for 30 fps (no retiming, no interpolation) and burns in labels (Pillow; this ffmpeg has no `drawtext`):

| Film use | Source | Labels |
|---|---|---|
| B07 `media/B07.mp4`, 12.5 s, video only | excerpt 1: ticks 1–600 (intro pan, play, plate 2 strike at 476); excerpt 2: ticks 1085–1234 (state WON) | "Scripted capture · real engine frames · Godot Movie Maker, windowed, offline 4K render · rev 77a6d10 · not a human playtest"; "excerpt N of 2 · ticks · state"; under each fork on screen: "plate N · PHASE · warning X.XX" |
| B02 left panel | held frame, tick 455 | "Held frame · the film's scripted capture, tick 455" and the plate 2 fork's logged value |

**One-tick offset, disclosed:** the driver logs at the start of each physics tick, before the forks advance, so the tag on the frame of tick T shows the value logged at tick T + 1 (the value after tick T). Values are read from the log, never computed by the film.
