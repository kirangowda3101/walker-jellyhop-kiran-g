# CAPTURE — in-play footage for the A7 film (B11, B13, B17 and the held frames)

One **scripted-input** take, recorded by Claude Code on 2026-11-17 (14:46 EST). It is not a human playtest. Kiran's in-play checks are TEST-REPORT.md A7, "HUMAN CHECK rows", quoted as text, never shown as footage.

## Method (the A6 film's capture contract, reused)

- **Copy:** `/Users/kiran/Documents/jellyhop-a7-film-work/run-copy-c1bbb13/`, a disposable git-archive copy of `c1bbb13` supplied by Kiran (launch note). The read-only snapshot and Kiran's repository were not used for any Godot run and were not changed.
- **Same source:** `capture/run_captures.sh` compares every file of the snapshot's `godot/` with the run copy's by SHA-256 (`.godot/` excluded): all 179 identical. **Disclosed difference:** Godot's import generated 9 `.gd.uid` sidecars in the run copy for A7 scripts committed without one (`capture/run-copy-extras.txt`); the script allows only such `.uid` extras. (A first headless dry run of the driver, below, imported before the script's check existed in this form.) **build_id** `92e6694a907be2e040e3133157d3de14bcdb9f655b0794d8cefba43539a7456b` = SHA-256 of `capture/source-manifest.txt`.
- **Two copy-only additions to the run copy** (never in the repository): `godot/override.cfg` (window 3840 × 2160 so Movie Maker records natively at 4K; the canvas stays 1280 × 720, stretch `canvas_items`) and `godot/capture/capture_driver.gd` (this folder's driver).
- **Import:** `godot --headless --path godot --import`, exit 0.
- **Dry run first:** the driver was run once headless (`--fixed-fps 60`, no movie) to debug it: first a log-path error (relative path), then my own check bug (it looked for the hop before that tick had run). After the fix the headless dry run printed the same result as the take below. Logs in `../takes/dry/` (outside the film folder).
- **Engine:** Godot 4.7.2.stable.official.ed1daf0bf, Compatibility renderer (`OpenGL API 4.1 Metal - 90.5 - Compatibility - Using Device: Apple - Apple M4`), **windowed**, `--write-movie … --fixed-fps 60`. Movie Maker renders offline (1 min 27 s to record 17.3 s), so the footage says nothing about real-time frame pacing.
- **Driver:** `capture/capture_driver.gd`. It plays `res://game/main.tscn` and presses A, D and Space only through `Input.parse_input_event` + `Input.flush_buffered_events`, each sent at the end of the tick before the tick that reads it: the input harness of Kiran's committed `tests/test_a7_edges.gd` / `test_a7_pins.gd`. The stationary-hop timing (press read → touchdown 41 ticks) is `PRESS_TO_TOUCHDOWN` in `previews/land_preview.gd` line 26, re-checked on every hop. It never writes game state, never moves the jelly, never calls the AnimationPlayer and never sets frame, scale, position, visibility or pause. One disclosed setting, as in the A2–A6 films and the A7 tests: `game.test_mode = true` (only disables pause-on-focus-loss).
- **Route (all on plate 1, which has no fork; gap 1 has no sauce):** intro untouched → "plain" stationary hop (touchdown 293, LAND 293–300, IDLE 301) → "scoot" A, D, A (ticks 344–466: 134 SCOOT ticks in the take, 9 wraps, both facings) → "handoff": D pressed 11 ticks before touchdown (touchdown 521, LAND 521–528, SCOOT-B at 529, tick % 14 = 9) → interrupts with a fresh jump press read at touchdown + k: **startup** k = 1 (touchdown 652, ANTIC 653), **active** k = 3 (786, ANTIC 789), **recovery** k = 6 (922, ANTIC 928), each followed by a full second landing.
- **Checks (every logged tick from PLAYING on):** LAND shows only the rig with clip `land` at (8 − land_ticks)/60 within 1e-6 s; SCOOT shows only the scoot sprite with clip `scoot` at (tick % 14)/60 (circular distance) and cell 0 on phases 0–6, 1 on 7–13; every other pose shows only the original sprite and no clip; each touchdown at press + 41; each interrupt hop at its predicted tick. Driver result: `CAPTURE OK: checks=859 failures=0`.
- **Log:** one JSON line per process frame after that frame's physics tick, plus events. Movie frame n = log `pframe` n = physics tick n + 1, checked on all 1,038 entries.
- **Script:** `capture/run_captures.sh` (`set -Eeuo pipefail`, ERR trap, source check, import, exit code, `CAPTURE OK`, no SCRIPT/SHADER/load errors, ffprobe `mjpeg,3840,2160,60/1`). Godot console: `capture/run-a7-godot.log`.

## Files

`capture/captures.sha256`:

    65fcf2358409c26da008e7f50e43c6a76c655443a384230a5667163a0ab0ce9b  run-a7.avi
    65c0ad9161642ad1e785f8f97274ee6314d64bcce97e15bf7a1afc4fa4ae6062  run-a7-inputs.jsonl

The AVI (MJPEG 3840 × 2160, 60 fps, 1,039 frames) stays outside git in `/Users/kiran/Documents/jellyhop-a7-film-work/takes/`. The input log is in this folder.

## How it is used and labelled

`tools/make_clips.py` checks both hashes, cuts on frame boundaries and burns in three labels on every frame (Pillow): the capture label, the excerpt label with its crop note, and the logged values for that frame (tick, tick relative to touchdown, pose, clip and clip time, cell, facing, which visual is shown). Every value is read from the log entry of that frame.

Crop: a 1920 × 1080 region (0, 700)–(1920, 1780) of the 4K frame (game canvas x 0–640, y 233–593), enlarged 2× with Lanczos. No retouching or colour change. Real-speed parts keep every other 60 fps frame for 30 fps (speed unchanged, no interpolation), so odd engine frames are not shown at real speed. Every slowed part is a **labelled replay of frames already shown**, showing every engine frame, each repeated R times.

| Film use | Ticks | Treatment |
|---|---|---|
| B11 excerpt 1 | 245–332 | stationary hop, full landing, IDLE · real speed |
| B11 excerpt 2 | 291–302 | labelled replay · 1/16 speed |
| B11 excerpt 3 | 333–465 | scoot left, right, left · real speed |
| B11 excerpt 4 | 386–396 | labelled replay (swap 387, wrap 394) · 1/16 speed |
| B13 interrupts 1–3 | 600–733, 734–869, 870–1008 | real speed, each followed by a labelled 1/16-speed replay of 651–655, 785–791, 921–930 |
| B17 excerpt 1 | 466–596 | hand-off hop · real speed |
| B17 excerpt 2 | 519–540 | labelled replay · 1/16 speed |
| Held frames | 295, 390 (B02); others unused | `_work/held/`, hashes in `media/clips.json`, labelled "Held frame" in the figure |

Holds, added after the narration was measured: B11 3.0 s (tick 396), B13 1.2 s (tick 930), B17 0.5 s (tick 540), each a repeat of the clip's last frame labelled "Held frame" on every held frame. No hold sits inside a landing or an interrupt.
