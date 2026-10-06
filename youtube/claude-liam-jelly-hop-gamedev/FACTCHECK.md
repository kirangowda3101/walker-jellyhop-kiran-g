# FACTCHECK — Jelly Hop: Fork From Above

Each narrated or on-screen claim is listed with the source I checked it against. Status: ✓ verified against the source; ≈ simplified (the simplification is stated); ⏳ pending a decision. Checked 2026-10-03 against revision `7a48ea8`.

## Opening (B00–B02)

| Claim | Source | Status |
|---|---|---|
| The Walker prompt's wording | CONCEPT.md v1, "The game in two sentences", nearly verbatim. Shown as an "illustrative reconstruction… not a saved transcript". The phrase "dodge forks" does not appear anywhere in the repository (searched every file), so it is not used. | ✓ |
| One level; six plates; five forks; three sauce gaps; a glass dome | `slice_tuning.gd`: `PLATE_GAPS` (6 plates), `FORK_CYCLES` (`null` + 5 cycles), `SAUCE_IN_GAP` (3 true); `session.gd` builds the dome | ✓ |
| The hesitant-writer correction: "The scrape plays as shadows grow." → "The scrape plays as forks descend.", after "The shadow gives the warning." (on-screen wording is Claude Code's, because the component corrects single words). Kiran's film review, 2026-10-05: "the video looks good." | CONCEPT.md v1 pillar 1: the scrape "plays once when a shadow starts to grow". Changed in `23ae39c` after Kiran's audition notes (`evidence/batch3-audition.md`). Kiran confirmed it at the script review: "keep it, corrected so the scrape plays as the fork starts descending, while the shadow provides the warning". | ✓ |
| "That last line came from a playtest, not the design" | FRICTIONAL.md, Batch 3 audition notes 1–3 | ✓ |
| The four pillars, verbatim names | CONCEPT.md "Design pillars" | ✓ |
| A hit costs about a second and a quarter, then you are back on the last plate you landed on | `SPLAT_TIME` 0.6 + `REFORM_TIME` 0.7 = 1.3 s; `checkpoint = plate_under(...)` on landing (`session.gd`) | ≈ |

## Asset trace (B03–B04)

| Claim | Source | Status |
|---|---|---|
| Design: the character sheet's front view as a guide on flat magenta | ASSET-LOG.md shared setup ("the approved front view from CHARACTER-SHEET.md, 1024 × 1024 on flat #FF00FF"); `char-ref-guide.png` SHA-256 `89c7a49f…` matches | ✓ |
| Model and settings | ASSET-LOG.md: SDXL Base 1.0, Draw Things 26.0924.0, local; image to image, strength 60%, seed 7270, 30 steps, guidance 7.0 | ✓ |
| The prompt shown on screen | ASSET-LOG.md line 10, verbatim | ✓ |
| The raw output is shown unedited (scaled only) | `~/Documents/jellyhop-generations/CHAR-REF-B-seed7270-s60.png`, SHA-256 `2c0f71a7…`, matches ASSET-LOG.md | ✓ |
| The text-only try had legs and a tongue | ASSET-LOG.md CHAR-REF-A: "three-quarter 3D view with legs", "an open mouth with a tongue" | ✓ |
| Two stray dots; 1,954 px filled in two boxes; nothing outside them | ASSET-LOG.md CHAR-REF cleanup (777 + 1,177 px), `tools/remove_specks.py` | ✓ |
| Magenta cut out; copied byte for byte; a check script compares them | ASSET-LOG.md (`process_env.py cutout`); `tools/copy_game_art.sh --check` passed 18/18 on 2026-10-03 | ✓ |
| `player.gd` line 54 loads it by name | `load("res://assets/art/CHAR-%s.png" % p)` at `player.gd:54` | ✓ |
| The in-engine panel is a 1:1 crop of the 4K capture | run-01 tick 303, crop 600×540 (CAPTURE.md) | ✓ |

## Code → result pairs (B05–B08)

| Claim | Source | Status |
|---|---|---|
| Twelve poses; the order in `choose_pose()` is the priority | `player.gd:7` (`POSES`), `147–163` | ✓ |
| Crouch for "the first few ticks" | `hop_ticks <= T.ANTIC_TICKS` (4): 5 ticks | ≈ |
| Bored after four seconds without input | `BORED_DELAY := 4.0` | ✓ |
| Worry while this plate's shadow grows | `session.gd:390` | ✓ |
| B06 pose sequence | run-01 input log, ticks 241–961 (`media/clips.json`) | ✓ |
| Before `23ae39c` the scrape played when any on-screen shadow started to grow, a second or more before the fork moved | `git show 23ae39c -- godot/game/session.gd`; `evidence/batch3-review.md` ("1.0–1.6 s before that fork came down") | ✓ |
| Kiran's words "the fork sound plays randomly" and "this looks good actually" | `evidence/batch3-audition.md` lines 7 and 21 (quoted from the longer notes, unchanged) | ✓ |
| `advance()` returns `"down"`; only the fork over the jelly's current or next plate, on screen, scrapes | `fork.gd:144–162`; `session.gd:295–299` | ✓ |
| Counts 22 / 16 idle → 9 / 6 → 8 / 0, every one on the tick its fork starts down | `evidence/batch3-audio-trace-before.txt`, `-after.txt`, `-after2.txt` (SUMMARY and SCRAPES lines). Same scripted 25.5 s route; not a playtest. | ✓ |
| In the capture, the scrape fires at tick 469 and the tines land 7 ticks later | run-01 log: SFX-WARN tick 469, SFX-SPLAT-FORK tick 476 | ✓ |

## Tests, verdict, Your Turn (B10–BHTF)

| Claim | Source | Status |
|---|---|---|
| 25 / 12 / 61 / 8 checks, 0 failures, rerun on a clean snapshot of this revision | `tools/run_slice_checks.sh` on 2026-10-03 (BUILD-LOG.md, Batch 1) | ✓ |
| Some tests use fixtures; none of them is a playtest | TEST-REPORT.md §9; test code | ✓ |
| Kiran's quotes, sound on and muted | TEST-REPORT.md §4 note 1, §6 note 5 (quoted from the longer note, unchanged) | ✓ |
| Every sound event fires in real play, under scripted input, offline-rendered | run-01 + run-02 logs: all six IDs (CAPTURE.md) | ✓ |
| Uncertain: one tester and one Mac; face at 64 px; collision boxes vs the sheet; one import crash | TEST-REPORT.md §9 | ✓ |
| Plate, sauce, fork and dome are SDXL at 50% over guides drawn by Claude's script, 4–19% of object pixels changed | ASSET-LOG.md Batch 2 line 128 (8.6 / 11.6 / 4.4 / 19.3% changed by more than 32 levels); SOURCES.md line 50 (`tools/make_env_guides.py`, drawn by Claude's script) | ✓ |
| Room and table were text to image | ASSET-LOG.md Batch 2 rows (ENV-ROOM try 3, ENV-TABLE: "text") | ✓ |
| Batch 2's prompts file was restored after generation because its commit failed | FRICTIONAL.md line 346; ASSET-LOG.md line 126 | ✓ |
| Models: art SDXL Base 1.0; sound effects Stable Audio Open 1.0; music MusicGen-small | SOURCES.md, ASSET-LOG.md Batch 3 | ✓ |
| Human and AI roles | Kiran's wording at the script review: Claude chat (claude.ai) drafted documents and prompts; Claude Code did the implementation, the audio generation and the film production; Kiran made the design decisions, the image generation runs, the asset selections, the reviews and the playtesting. Consistent with SOURCES.md (Claude, Claude Code entries; "Batch 3 exception: Claude Code ran the audio generation"). | ✓ |
| Next step toward the full game | Kiran's words at the script review: "My next step would be a second level that introduces new fork rhythms gradually, then combines them into more challenging timing decisions." Spoken as "Kiran's next step: a second level that …". | ✓ |
| Revision shown | `7a48ea8` (godot/ identical to `23ae39c`) | ✓ |

## Decisions recorded at the script review (2026-10-03)

- **B09 (slice audio, no narration): Kiran's decision, 2026-10-03, at the script review.** The godot-gamedev pipeline strips the audio of gameplay clips by default (`compile.py` encodes every clip with `-an`), and the skill gives no per-beat way to play gameplay audio without narration. The brief says to ask for the course-provided method in that case. **Kiran chose not to ask the course** and to use the premixed `--audio` master instead, in Kiran's words: "lets use the fall back option only. even that satisfies the requirements".
  - **Method:** `tools/make_master.py` builds one master track the way `compile.py` builds its own per-beat track. B09's 11.733 s slot carries the captures' own recorded engine audio (PCM from run-01 and run-02, same tick ranges as the picture), unchanged in level, with no narration. Nothing is dubbed or added. `./art final` receives it through its `--audio` option.
  - **Label on screen:** "Slice audio · no narration · scripted-input capture".
  - **Level change for audibility (Kiran's instruction):** one plain gain of +4.90 dB on B09's segment (ffmpeg `volume`), so its peak reaches −1 dBFS. No compression, limiting or added sound. Before: mean −37.6 dB, peak −5.9 dB. After: mean −32.7 dB, peak −1.0 dBFS. The balance between music and effects inside the game mix is unchanged.
  - **Correction:** the Batch 2 draft of this file said "Kiran asked the course … on 2026-10-03". That was my wording and it was wrong: Kiran had said they would ask, and later decided not to. The course was not asked.
