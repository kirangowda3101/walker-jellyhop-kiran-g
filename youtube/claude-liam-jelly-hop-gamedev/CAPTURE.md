# CAPTURE — gameplay footage for the Jelly Hop film

All gameplay in this film comes from two **scripted-input** takes, rendered offline by Godot's Movie Maker. Neither is a human playtest. Kiran's human playtest is TEST-REPORT.md §4–§7; the film quotes it as text and never presents it as footage.

## Source and engine

- **Revision:** `7a48ea8cb29c04dfafa3e6df6fe491e1807c8409` (main). `godot/` is unchanged since `23ae39c`; `7a48ea8` changed only `tools/check_game_audio.py` and documents.
- **Engine:** Godot `4.7.2.stable.official.ed1daf0bf`, GL Compatibility, on Kiran's MacBook Pro (Apple M4, macOS 26.5.1).
- **Snapshot:** `git archive 7a48ea8 | tar -x` into the session scratchpad, so the repository and its `.godot/` cache were not used or changed.
- **build_id:** `c71c049161eed3b05b224458078085533e2da516b179d6da69b966395d57b0ba`. This is the SHA-256 of `capture/source-manifest.txt`, which lists the SHA-256 of all 83 files under the snapshot's `godot/`. That count includes Godot's `.uid` files; the godot-gamedev check counts 68 files without them. The manifest is taken **before** the two copy-only files below are added.
- **Script:** `capture/run_captures.sh` (Claude Code wrote it; `set -Eeuo pipefail`, ERR trap, explicit checks).

## Two copy-only additions (disclosed; not in the repository's game)

1. **`godot/override.cfg`** in the snapshot only:

       [display]
       window/size/window_width_override=3840
       window/size/window_height_override=2160

   Godot reads `override.cfg` at startup. The 3024×1964 display clamped `--resolution 3840x2160` to a 1280×720 recording. With this override, Movie Maker recorded at a native 3840×2160.
   - The game's logical canvas stays 1280×720 (`project.godot`, stretch mode `canvas_items`). The 2D scene is drawn at 4K from the 1024-px source art; it is not a 720p image scaled up.
   - A 1:1 crop of the jelly in the Batch 1 pilot is sharp.
2. **`godot/capture/capture_driver.gd`**, a copy of this folder's driver.

## The driver (`capture/capture_driver.gd`)

- **Input path:** keyboard events only (Right arrow, Space) through `Input.parse_input_event`, the same path a keyboard uses. The game's own InputMap and `_unhandled_input` handle them.
- **Choosing when to press:** it reads positions and fork phases, using the read-only planner in `godot/tests/route_driver.gd` (`plan()`, `safe_span()`).
- **What it never does:** move the jelly, change forks, timers or collisions, or use the player's test controls (`player.test_control` stays false).
- **One disclosed setting:** `game.test_mode = true`. Its only effect in `session.gd` is in `_on_focus_lost()`: the game does not pause when the window loses focus. Without it, focus changes during the offline render could pause play. Nothing else in the game reads `test_mode`.
- **Input rule it respects:** the game ignores a direction already held when control returns (`require_axis_release`). The driver keeps the keys up for 2 ticks after control returns, then presses, as a player would.
- **Pass condition:** it asserts its outcome and exits 1 otherwise.
  - run-01 needs a fork splat, splat cause `fork`, and exactly one SFX-WIN.
  - run-02 needs splat cause `sauce` and exactly one SFX-SPLAT-SAUCE.
- **Log:** every key down/up, state change, pose change and sound call is written with its tick to `capture/run-0N-inputs.jsonl`.

## Takes

| Take | Route | Length | Result | Sound calls (from the log) |
|---|---|---|---|---|
| run-01 | Intro pan (untouched) → hop to plate 2 → stay under plate 2's fork until it strikes (deliberate fork splat, tick 476) → re-form → safe hops to plate 6 → walk into the dome (WIN, tick 1091) → 2.5 s hold | 1,241 frames (20.68 s) | CAPTURE OK | HOP 6, LAND 5, WARN 7, SPLAT-FORK 1, SPLAT-SAUCE 0, WIN 1 |
| run-02 | Space at tick 60 skips the intro (the game's own "any key skips" rule; the skip key never hops) → hop to plate 2 → walk off its right edge with no hop into the sauce in gap 2 (tick 217) → re-form on plate 2 → 1 s of control | 354 frames (5.90 s) | CAPTURE OK | HOP 1, LAND 1, WARN 1, SPLAT-SAUCE 1 |

Both takes: `mjpeg 3840x2160 60/1` and `pcm_s16le 48000 Hz 2 ch` (the engine's own audio mix). Movie Maker renders offline at fixed 60 fps (about 18% of real-time speed here), so the footage shows nothing about real-time frame rate.

SHA-256 (`capture/captures.sha256`):

    885d6be57b2b23bc6163de2a511779644b0b00361ce04449b01bcf9f408b84f6  run-01.avi
    75a929aac8d940391bfa1a2f6e3f773d3e5c9acdd6e35fe337497734c8a10666  run-01-inputs.jsonl
    62fe1f141a8dcae4b0214f67bc9e0efbc14a864c6ee80487be4bc4914a11f6fd  run-02.avi
    34656a34656114889e8afe6923054975bfe2815d6ae3bb577212d66001cf5641  run-02-inputs.jsonl

The AVIs (about 0.6 GB) stay outside git, in the session scratchpad (`…/scratchpad/capture-2/takes/`), until the final film is verified. The input logs are in this folder.

## How the footage is used and labeled

`tools/make_clips.py` cuts on tick boundaries (movie frame = tick − 1) and keeps every other frame for the film's 30 fps. Playback speed is unchanged: no retiming, interpolation or speed change. It checks each AVI against `captures.sha256` first.

| Film use | Source | Labels burned in (Pillow PNG overlays; this ffmpeg has no `drawtext`) |
|---|---|---|
| B06 `media/B06.mp4` | run-01 ticks 241–961 (12.0 s, continuous), video only | "Scripted-input capture · Godot Movie Maker (offline render) · rev 7a48ea8 · not a human playtest"; "pose: NAME (from the input log)" |
| B09 `media/B09.mp4` | three excerpts, 11.73 s total, **with engine audio**: run-01 ticks 300–620 (HOP, LAND, WARN ×3, SPLAT-FORK); run-01 1001–1211 (LAND, HOP, WIN); run-02 123–297 (HOP, LAND, WARN, SPLAT-SAUCE) | capture label; "Slice audio · no narration · scripted-input capture"; "excerpt N of 3 · take · ticks a–b"; each sound event's ID and tick shown for 0.8 s at the tick it fires |
| B02 still | run-01 tick 90 (intro pan), cropped to y 0–1600 of 2160 (above the table curtain; the HUD skip hint on the curtain is cut) | "Held frame · run-01, tick 90 · intro pan · cropped above the curtain" plus the capture label |
| B04 panel d | run-01 tick 303, 600×540 crop at 1:1 | "In engine, 4K capture · run-01, tick 303, crop at 1:1" |
| B08 frames | run-01 ticks 439, 469 (SFX-WARN), 476 (SFX-SPLAT-FORK) | tick and event under each frame; "Frames from run-01 (scripted-input 4K capture)" |

- **B09 audio check:** the recorded audio peaks sit on the logged frames (Batch 1 pilot: HOP −15.9 dB, LAND −10.8 dB, WARN −18.4 dB against −33 dB of music).
- **B09 in the final film:** the compiler drops clip audio, so B09's sound reaches the film through the premixed `--audio` master (Kiran's decision; FACTCHECK.md). That master cuts B09's audio straight from the AVIs' PCM with the same tick ranges as the picture, not from B09.mp4's AAC track, which ran 96 ms long.

## First attempt, stopped (kept for the record)

The first `run_captures.sh` run (work folder `capture-final/`) never imported the snapshot. A `git archive` copy has no `.godot/imported/` cache, so every texture and sound failed to load (`Failed loading resource … .ctex`), and `fork.gd`'s `tine_outlines()` got a null texture. The forks therefore had no hit shapes, and the jelly stood under nine strikes untouched.

I stopped that take (the driver would have failed its assertion), added `godot --headless --import` plus checks for load and script errors to the script, and recorded again. This was a defect in the capture setup, not in the game. Its logs are kept in the scratchpad; its partial AVI was deleted.
