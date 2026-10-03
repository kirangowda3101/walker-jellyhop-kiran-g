# Batch 3 review sheet — sound effects and music

AUDIO-BRIEF.md §2, steps 0–7. Kiran's selections are recorded as **current choices with their design purposes**. The only confirmed listening judgment is about the fork timing; the other listening judgments are pending (§5). Every result below comes from a command that was run, and its log is in `evidence/`. Scripted runs and automated checks are not playtests; Kiran's three in-game auditions are recorded in `evidence/batch3-audition.md`.

## 1. Selections (Kiran's words; `evidence/batch3-audition.md`)

| Sound | Take (seed) | Kiran's current choice and design purpose | Listening judgment |
|-------|-------------|-------------------------------------------|--------------------|
| SFX-HOP | 3 (7272) | "intended to give each hop a clear takeoff cue." | pending |
| SFX-LAND | 2 (7271) | "intended to distinguish landing safely from jumping." | pending |
| SFX-WARN | 1 (7270) | "the scrape now feels connected to the fork descending, which is what I wanted." | confirmed: the fork timing |
| SFX-SPLAT-FORK | 3 (7272) | "intended to identify a fork failure." | pending |
| SFX-SPLAT-SAUCE | 2 (7271) | "intended to distinguish a sauce failure from a fork hit." | pending |
| SFX-WIN | 3 (7272) | "intended to mark reaching the dome." | pending |
| MUS-LOOP | 1 (7270) | "keep the current music; I haven't separately confirmed whether the seam is audible." | pending (seam not confirmed) |

- Volume: "leave it unchanged for now." The 14 other takes are "not selected"; Kiran gave no per-take reasons.
- The selection steps were: provisional technical selections from the measurements, comparison copies, a provisional shortlist for an in-game audition, then three auditions and the final selections (ASSET-LOG.md, Batch 3).

## 2. Results

| Check | Result | Evidence |
|-------|--------|----------|
| Raw takes generated | 21 of 21 (3 seeds × 7 sounds); every SHA-256 logged and re-checked after processing | `batch3-generation-log.txt`, `batch3-listening.md` |
| Game files | 7 OGG Vorbis files in `audio/game/`, copied byte-identical into `godot/assets/audio/` | `batch3-audio-copy.txt` |
| Decoded game audio (`tools/check_game_audio.py`) | 8 checks / 0 failures: every sound effect starts within 10 ms (0 ms measured); every peak ≤ −1 dBFS; loudness at target (sound effects −30.1 LUFS max momentary, music −40.1 LUFS integrated, ±0.5 LU); music imports with `loop=true`; each file matches its processing record | `slice-checks/final-game-audio.txt` |
| `bash tools/run_slice_checks.sh` | art 18/18 and audio 7/7 byte-identical; mechanics 25/0; keyboard 12/0 (M and N mute only); **slice 61/0**; 7 screenshots at 1280 × 720; 8 s launch with no errors | `slice-checks/final-*.txt`, `batch3-checks.txt` |
| New slice checks for this batch | every event ID has its own OGG stream on the SFX bus and placeholder mode is off; the music stream loops and plays; a hop plays its sound once; the SFX-WARN checks in §4; mute still changes no game state | `slice-checks/final-test_slice.txt` |
| Sound-call traces (real game, scripted input) | route plates 1 → 2 → 3 → 2 → 1: 22 scrapes before, 9 after decision 1, 8 after decision 2 (all at their fork's descent start) | `batch3-audio-trace-*.txt` |

Commands:
- `bash tools/run_slice_checks.sh`
- `~/Documents/jellyhop-audio-env/bin/python tools/check_game_audio.py`
- `bash tools/batch3_swap.sh <ID> <take>`
- `TRACE_LABEL=<name> /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/trace_audio.gd`

## 3. Processing (planned edits, with the leveling change)

- **Leveling (Kiran's decision; the prompts file's second dated note):** perceived loudness, gain only, peaks ≤ −1 dBFS. This replaces the planned "level to a common peak (−1 dBFS)". It is a difference from the prompts file's planned edits, not from the design documents.
  - **Sound effects:** fixed at −30.1 LUFS maximum momentary, the highest level at which all 18 takes stay at or below −1 dBFS.
  - **Music:** −40.1 LUFS integrated, 10 LU below the sound effects (Claude Code's number).
- **Sound effects:** the leading trim at −50 dBFS with no fade-in, repeated at the delivered level; the tail trimmed below −50 dBFS with a 15 ms linear fade-out.
- **Music:** a whole-bar loop (take 1: 16.88–26.48 s, 4 bars at 101 bpm, 9.6 s) with a 2 ms crossfade. The seam measurement passes any crossfade of 2 ms or more, so it rules out only a hard cut; the seam is not confirmed by listening. An alternative loop of take 3 (5 bars at 134 bpm tracked, 9.0 s) is kept outside the repo.
- **Every parameter and result:** `evidence/batch3-process-log.txt`. The superseded first run is kept, marked superseded.
- **Torchsde workaround at generation:** approved by Kiran; no prompt or setting change; the prompts file's first dated note.

## 4. Differences from the design documents

1. **SFX-WARN scope (difference from CHANGE-BRIEF.md, decided by Kiran after playtesting, 2026-10-03).**
   - **CHANGE-BRIEF.md's event-to-sound map:** SFX-WARN plays when "a fork enters its shadow phase while its shadow is on screen", once per fork cycle. CHANGE-BRIEF.md is not edited.
   - **Now:** SFX-WARN plays only for the fork over the jelly's *current* plate or the *next* plate.
     - The current plate is the plate the jelly is on, or the last plate it stood on while airborne or on bare table.
     - The next plate is the one after it.
   - **Unchanged:** the on-screen requirement, and exactly one scrape at the start of each warning phase. A fork that was not current or next when its warning phase started stays silent for that whole phase.
   - **Music:** unchanged. The music still dips for any warning shadow on screen.
   - **Why it came up:** Kiran's audition note, word for word in `evidence/batch3-audition.md`: "the fork sound plays randomly even if the forks are not coming down".
   - **Verification before the change** (real game, scripted input, `godot/tests/trace_audio.gd`): the metallic sound heard while no fork was coming down was SFX-WARN. It fired at the start of every on-screen fork's shadow phase, 1.0–1.6 s before that fork came down.
     - On the route plates 1 → 2 → 3 → 2 → 1 (25.5 s): 22 SFX-WARN calls, 18 from forks not over the jelly's plate, 16 while no fork was down. See `evidence/batch3-audio-trace-before.txt`.
     - The first trace run had two script flaws, listed in its header: `evidence/batch3-audio-trace-first-run.txt`.
     - SFX-SPLAT-FORK fired only when the jelly's own fork struck it.
   - **After the change**, same route: 9 SFX-WARN calls, all from the current-plate or next-plate fork (`evidence/batch3-audio-trace-after.txt`). The scrape is still a warning: it plays when the shadow starts, before the fork comes down.
   - **Checks:**
     - Replaced: `overlapping-shadows-two-warns`, which expected one scrape per on-screen fork. It is now `overlapping-shadows-warn-only-near-fork`: with the jelly on plate 1, plate 2's fork (next) scrapes once and plate 3's fork (on screen, two plates away) stays silent, each scrape matched to its fork. Its music check, `overlapping-shadows-one-dip`, is unchanged.
     - Added: `warn-current-plate-fork-scrapes-once`, `warn-next-plate-fork-scrapes-once`, `warn-far-on-screen-fork-silent`, `warn-airborne-uses-last-plate`.

2. **SFX-WARN at the fork's descent (a further difference from CHANGE-BRIEF.md, decided by Kiran after the second audition, 2026-10-03).**
   - **CHANGE-BRIEF.md:** SFX-WARN plays when "a fork enters its shadow phase while its shadow is on screen". After difference 1 it played at that moment only for the current or next plate's fork. CHANGE-BRIEF.md is not edited.
   - **Now:** the existing scrape (event ID SFX-WARN, same take) plays once when the fork over the jelly's current or next plate **starts descending** (the start of its strike), and only if that fork is on screen at that moment. Nothing plays when a shadow starts growing; the shadow alone does the warning. The current and next plate definitions are as in difference 1. Music: unchanged (it still dips while any on-screen shadow grows and through the strike).
   - **Why it came up:** Kiran's second audition note, word for word in `evidence/batch3-audition.md`: "i want the sound only when the fork is coming down. it is still not connected to forks."
   - **Same scripted route after the change** (`evidence/batch3-audio-trace-after2.txt`, 25.5 s): 8 SFX-WARN calls, all 8 in the same tick as their fork's descent start, 0 while no fork was down. 7 came from the next-plate fork and 1 from the current-plate fork.
   - **When the descending fork hits the jelly:** the scrape plays as the fork starts down, and SFX-SPLAT-FORK follows when the tines reach the jelly. On the route: 7 ticks later (0.117 s). The processed scrape is 0.367 s long, so it is still sounding for about 0.25 s after the splat sound starts.
   - **Checks (each replaced check keeps its strength; old ids in the test comments):**
     - `offscreen-shadow-no-warn-dip-once-on-screen` → `offscreen-shadow-dip-once-on-screen-warn-at-strike`: music unchanged; 0 scrapes while the shadow grows; exactly 1 at the start of the descent, when that fork is the next plate's and on screen.
     - `onscreen-shadow-warns-and-dips` → `onscreen-shadow-dips-no-warn-at-start`.
     - `overlapping-shadows-warn-only-near-fork` → `overlapping-strikes-warn-only-near-fork`: scrapes matched to each fork's descent frame; the next fork scrapes once and the far fork stays silent.
     - `warn-*-scrapes-once` → `warn-current-plate-fork-descends-once` and `warn-next-plate-fork-descends-once`.
     - Kept, now with descents: `warn-far-on-screen-fork-silent`, `warn-airborne-uses-last-plate`.
     - Added: `warn-none-while-shadow-grows` and `warn-offscreen-next-fork-silent`.
     - "None during the intro" is covered by the existing `intro-shows-shadows-frozen` (0 SFX-WARN through the pan), `play-starts-quiet-no-onscreen-shadow` and `replay-starts-quiet-no-onscreen-shadow`.
     - The first version of `warn-offscreen-next-fork-silent` failed because of its fixture, not the game: the camera was put at the far left, where plate 3 is still on screen. It now uses the far right end of the level.

## 5. Still pending (needs Kiran; automated checks do not replace these)

- The music seam over at least three repetitions, by listening.
- The listening judgments for every sound except the fork timing.
- The overall volume ("leave it unchanged for now").
- A full muted playtest.
- The music's pause, splat-dip, warning and end behavior by ear (AUDIO-BRIEF §4).

## 6. Files in this batch

- **Game:** `audio/game/*.ogg` (7), `godot/assets/audio/*.ogg` (+ Godot `.import` files; `MUS-LOOP.ogg.import` has `loop=true`).
- **Code changed:** `godot/audio/sound_events.gd` (streams, one player per event, placeholder mode off), `godot/audio/music_controller.gd` (loop stream), `godot/game/session.gd` (SFX-WARN trigger, jelly plate tracking).
- **Tests:** `godot/tests/test_slice.gd`, `test_game.gd`, `test_keyboard.gd`, `capture_slice.gd` (shutdown wait); new `godot/tests/trace_audio.gd`.
- **Tools:** `batch3_generate.py`, `batch3_listening.py`, `batch3_compare.py`, `batch3_process.py`, `check_game_audio.py`, `copy_game_audio.sh`, `batch3_swap.sh`; `run_slice_checks.sh` (audio checks added).
- **Logs:** ASSET-LOG.md (Batch 3), SOURCES.md, FRICTIONAL.md (new entry), the prompts file (two dated notes).
- **Evidence:** `evidence/batch3-*`.
- **Outside the repository (not committed):** the raw takes, comparison copies and alternative loop in `~/Documents/jellyhop-generations/`; the virtual environment; the model caches.
