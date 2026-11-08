# CAPTURE — in-play footage for the A6 film (B11, B18 and the held frames)

One **scripted-input** take, recorded by Claude Code on 2026-11-08 (03:00 EST). It is not a human playtest. Kiran's in-play checks are TEST-REPORT.md A6, "In play — Effect A" and "In play — Effect B", quoted as text, never shown as footage.

## Method (the A5 film's capture contract, reused)

- **Copy:** `/Users/kiran/Documents/jellyhop-a6-film-work/run-copy-8004dea/`, a disposable git-archive copy of `8004dea` supplied by Kiran (launch note). The read-only snapshot and Kiran's repository were not used for any Godot run and were not changed.
- **Same source:** `capture/run_captures.sh` first compares the run copy's `godot/` with the snapshot's `godot/`, file for file by SHA-256 (`.godot/` excluded): identical, 160 files. **build_id** `0e9e9f5d2e905948f7edbc745682f5b8e22747babb702e6cb064a4f76b1cee0a` = SHA-256 of `capture/source-manifest.txt`.
- **Two copy-only additions to the run copy** (disclosed; never in the repository): `godot/override.cfg` (window 3840 × 2160 so Movie Maker records natively at 4K; the game's canvas stays 1280 × 720, stretch mode `canvas_items`) and `godot/capture/capture_driver.gd` (this folder's driver).
- **Import:** `godot --headless --path godot --import`, exit 0 on the first attempt.
- **Engine:** Godot 4.7.2.stable.official.ed1daf0bf, Compatibility renderer (`OpenGL API 4.1 Metal - 90.5 - Compatibility - Using Device: Apple - Apple M4`), **windowed** (not headless), `--write-movie … --fixed-fps 60`. Movie Maker renders offline at a fixed 60 fps (2 min 6 s to record 25 s), so the footage says nothing about real-time frame pacing or cost.
- **Driver:** `capture/capture_driver.gd`. It presses A, D, Space, Esc and Enter only through `Input.parse_input_event`. Its routes come from Kiran's committed tests: the plate-edge scoot-off of `tests/test_land_puff_state.gd` (`RUN_LEFT_TO_X` 170, `HOP_FROM_X` 160) and the keyboard route of `tests/test_dome_glints_state.gd` (`route_driver.gd`'s jump marks and read-only `plan()`). It never moves the jelly, touches a fork, calls the effects driver, sets `emitting`, calls `restart()`, changes `visible` or sets `get_tree().paused`. One disclosed setting, as in the A2 and A5 films: `game.test_mode = true` (only disables pause-on-focus-loss).
- **Log:** one JSON line per frame, written after that frame's physics tick: tick, process-frame index, state, jelly position, `just_landed`, `SFX-LAND` count, LandPuff spawns and nodes in the tree, `DomeGlints.emitting` and its screen position. Movie frame n = log entry `pframe` n = tick n + 1 (checked by eye: frame 448 shows the LAND squash of the tick-449 landing).
- **Route and result:** intro pan untouched → solo hop on plate 1 (landing tick 313) → back up, run, hop to plate 1's right edge with D held: landing at the edge (tick 449) and on the table 9 ticks later (tick 458) → hop back to plate 1 (558) → route over plates 2–5 (698, 774, 883, 950, 1027) → Esc on plate 6 (PAUSED ticks 1059–1180) → into the dome (WON, tick 1233, `emitting` false the same tick) → Enter after the replay prompt → PLAYING at tick 1384 with `emitting` true, dome off screen. Driver result: `CAPTURE OK: route complete: scoot gap=9 ticks, pause at 1060, WON at 1233, replay at 1383, puff/SFX-LAND mismatched ticks=0, splats=0` (its own replay counter is one tick earlier than the log's first PLAYING tick, 1384). Peak LandPuff nodes in the tree: 2 (ticks 458–473, 16 ticks).
- **Script:** `capture/run_captures.sh` (`set -Eeuo pipefail`, ERR trap, source check, import, exit code, `CAPTURE OK`, no SCRIPT/SHADER/load errors, ffprobe `mjpeg,3840,2160,60/1`). Godot console: `capture/run-a6-godot.log`.

## Files

`capture/captures.sha256`:

    82b1c53aa26c4b7356349bb07f5529b73cabf07790ab2f422b2cd95a5b01f817  run-a6.avi
    32682fd9615c30b186fd48e2d32587720f154a54ac077a61bcc73f02c1ba532b  run-a6-inputs.jsonl

The AVI (MJPEG 3840 × 2160, 60 fps, 1,503 frames) stays outside git in `/Users/kiran/Documents/jellyhop-a6-film-work/takes/`. The input log is in this folder.

## How it is used and labelled

`tools/make_clips.py` checks both hashes, cuts on frame boundaries, keeps every other 60 fps frame for 30 fps (no retiming, no interpolation) and burns in three labels on every frame (Pillow): the capture label, the excerpt label with its crop note, and the logged values for that frame.

| Film use | Movie frames (ticks) | Treatment |
|---|---|---|
| B11 excerpt 1 | 269–539 (270–540): solo hop, back-up, scoot-off | real speed · 1920 × 1080 region (0, 700)–(1920, 1780) of the 4K frame, enlarged 2× |
| B11 excerpt 2 | 439–489 (440–490) | **labelled replay** of frames already shown, each 60 fps frame shown twice = ¼ speed · same crop |
| B11 excerpt 3 | 555–1053 (556–1054): route over plates 1–5 | real speed · same crop |
| B18 excerpt 1 | 0–60 (1–61): first second of the intro | real speed · region (1854, 700)–(3774, 1780), enlarged 2× |
| B18 excerpt 2 | 959–1383 (960–1384): landing on plate 6, Esc pause, resume, win | real speed · **full native 4K frame** (the game's HUD text spans the frame; a crop would cut it) |
| B18 excerpt 3 | 1380–1500 (1381–1501): replay | real speed · full native 4K frame |
| B18 hold | the clip's last frame (tick 1501), 2.5 s | labelled "Held frame · tick 1501" on every held frame; B18's narration (11.6 s) is longer than its 10.2 s of real footage. No hold inside the pause, where a frozen frame would misrepresent the drift. B11 has no hold. |
| Held frames | 316, 461, 0, 1300 (crops) and 1100 (full) | `_work/held/`, hashes in `media/clips.json`, labelled "Held frame" in the figures |

The 2× enlargement is a plain Lanczos resize of the captured pixels: no retouching, no colour change. The crumbs and glints are a few game pixels across, so at full frame they are hard to see on an ordinary screen.
