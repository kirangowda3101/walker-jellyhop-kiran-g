# TEST-REPORT — Jelly Hop: Fork From Above

- **Source revision tested:** `23ae39c` (`23ae39ce6c84b683670640d6ef51502376896dbe`, on GitHub `kirangowda3101/walker-jellyhop-kiran-g`, branch `main`).
- **Changes since then:** this report and its evidence are committed after it, together with one fix to a check script (`tools/check_game_audio.py`, see §1). No game code or asset changed after `23ae39c`.
- **Engine:** Godot `4.7.2.stable.official.ed1daf0bf` (GL Compatibility renderer).
- **Machine:** macOS 26.5.1 (build 25F80), MacBook Pro, Apple M4, 16 GB, arm64.
- **Playtester:** Kiran only. There are no other playtesters.
- **Human playtest vs automated runs:** the human playtest is Kiran's (§4–§7, quoted word for word). Everything marked "automated" or "scripted" drives the game with scripted input or fixtures; none of it is a human playtest.
- **Date:** 2026-10-03.

## 1. Startup and controls (from a fresh copy)

Verified from a fresh clone of GitHub into a temporary folder outside the working repository. Full log: `evidence/test-fresh-copy.txt`, with the complete outputs in `evidence/test-fresh-*-full.txt`.

```
git clone https://github.com/kirangowda3101/walker-jellyhop-kiran-g.git <tmp>/fresh-clone      # exit 0; HEAD 23ae39c
cd <tmp>/fresh-clone
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --import                   # exit 0
bash tools/run_slice_checks.sh                                                                 # see below
./walker-jumpman.command                                                                       # the game launches; closed after 8 s, no errors logged
```

- **The fresh copy has no `.godot` import cache.** That's expected (it is git-ignored); the import builds it.
- **First check run at `23ae39c`: STOPPED at the game audio checks.** 7 of 8 checks failed only on "process-log SHA match False"; every audio measurement passed (start 0 ms, peaks, loudness, loop on).
  - **Cause:** `tools/check_game_audio.py` looked up each file's processing record by the *absolute path* of the original working copy, which doesn't exist in a clone at another path.
  - **Fix (committed with this report):** look the record up by the repo-relative path `audio/game/<ID>.ogg`.
  - **Second run in the fresh copy,** with the fixed script copied in: `ALL SLICE CHECKS PASSED`:
    - art 18/18 and audio 7/7 copies byte-identical
    - game audio 8/0
    - mechanics 25/0
    - keyboard 12/0
    - slice 61/0
    - 7 screenshots at 1280 × 720
    - an 8 s launch with no errors
  - **Not a game bug,** but a real portability bug in a check; `23ae39c` as committed fails this check from a fresh copy.
- **Every asset the game loads is present** (tracked in git):
  - 18 PNG in `godot/assets/art/`: the 12 poses `CHAR-<POSE>.png` and the 6 environment images `ENV-ROOM/TABLE/PLATE/SAUCE/FORK/DOME`;
  - 7 OGG in `godot/assets/audio/`: the 6 sound effects and `MUS-LOOP`, with `MUS-LOOP.ogg.import` set to `loop=true`.
  - The art and audio copies are byte-identical to `art/game/` and `audio/game/`.
  - The largest tracked file is 0.85 MB; there are no MP3 or MP4 files.
- **Requirements for running the checks:** the Godot app at `/Applications/Godot.app`. The game-audio check also needs the Python environment `~/Documents/jellyhop-audio-env` (it is outside the repository). Playing the game needs only Godot.
- **Controls** (SLICE-BRIEF §6), checked by `godot/tests/test_keyboard.gd` with synthetic key events (12/0):

| Control | Keys | Check |
|---|---|---|
| Move | ← / → or A / D | `keyboard-move-d`, `-a`, `-right-arrow`, `-left-arrow` |
| Hop | Space, ↑ or W | `keyboard-jump-space`, `-up`, `-w` |
| Pause / resume | Esc | `escape-pause`, `escape-resume` |
| Skip intro / play again | any key (never hops or moves) | `any-key-start`, `any-key-replay`; slice `skip-key-no-hop-no-move-*`, `restart-key-no-hop-first-plate-reset` |
| Mute all / music only | M / N (never skip or restart) | `m-n-mute-only`; slice `mute-keys-do-not-skip`, `mute-changes-no-state` |

Kiran played the game from the Godot editor (F5) in the slice setup review (FRICTIONAL.md, 2026-10-03 slice entry), and played it again for the three Batch 3 auditions and this playtest.

## 2. Character against the sheet

`evidence/test-character-vs-sheet.png` puts each CHARACTER-SHEET pose (`design/character/poses.svg`, cropped from the sheet) beside the in-engine pose facing right and facing left.
- The in-engine screenshots are rendered by the game and captured by `godot/tests/capture_poses.gd`, at 4× zoom on plate 1. The active collision box is outlined in magenta by the capture script only.
- Single captures: `evidence/test-poses/<POSE>-R|L.png`; boxes: `evidence/test-poses/boxes.txt`. The image was built by `tools/test_report_images.py`.

- **Facing:** every pose flips for left (`flip_h` true facing left, false facing right). The jelly keeps facing the way it last moved (automated: `pose-flip-keeps-facing`).
- **Size and anchor (automated):** the resting cube is 64.2 × 63.8 px on screen (`pose-idle-size-64`), and the art's bottom is flush with the box bottom within 0.11 px (`pose-bottom-flush`).
- **Pose states (automated):**
  - `pose-hop-sequence` ANTIC → RISE → FALL → LAND → IDLE;
  - `pose-bored-after-delay` (4.0 s);
  - `pose-worry-overrides-bored`;
  - `pose-scoot-loop` (A and B);
  - `pose-splat`, `pose-respawn`, `pose-control-returns-idle`;
  - `win-dome-celebrate-prompt` (CELEBRATE).
- **The art is the accepted Batch 1 and 2 art.** The pose drift review against the sheet was done when it was accepted (ASSET-LOG.md, Batch 1); this comparison does not re-judge it.
- **Mismatches with the collision rules:**
  1. **Crouch (ANTIC) keeps the standing box** (52 × 58). The sheet gives the crouch the low box (52 × 44). In this build the crouch is a visual-only pose shown for the first 4 ticks after takeoff. With the low box in the air, the starter's low-ceiling check failed: the feet rose 48 px under a 40 px ceiling gap. So the code keeps the standing box, and the check was not changed. In the comparison the box reaches above the squashed art.
  2. **Splat and re-forming:** the sheet says "hits off". In the engine the collider stays the standing box (it keeps the body on the plate), and hits are off because hazards are not checked in the SPLAT and REFORM states (automated: `duplicate-death-ignored`, `twenty-retries`). The magenta box drawn over the flat splat is that collider, not a hit zone.
  3. **Scoot A:** the standing box sits about 2 px above the art, the sheet's own watch item (failure #14). It has not been playtested separately near strikes.
  4. **Stretched poses** (RISE, SCOOT-B, CELEBRATE) reach well above the standing box, as the sheet allows ("stretched poses reach further above it").

## 3. Storyboard against the slice

`evidence/test-storyboard-vs-slice.png` puts each STORYBOARD panel (`design/storyboard/*.svg`) beside the in-engine screenshot of the same moment (`evidence/slice-screens/`, rendered by `godot/tests/capture_slice.gd`). The setups are scripted; fixtures are listed in `evidence/slice-screens/captures.txt`.

| Panel | Same in the slice | Differences, and why |
|---|---|---|
| 1 Establishing (wide, high angle, design view) | title, "any key skips the intro", forks above the plates, shadows on plates 5 and 6, sauce in the gaps, the pan from the dome back to the jelly | **Eye level, not high angle.** STORYBOARD says the slice shows this as an eye-level side-view pan. **One frame can't show the whole table:** the screenshot is 35 % into the 4 s pan, so the jelly and the dome are not in it. **The forks are much larger** than drawn: Kiran's fork-reach decision, tines spanning the whole plate. |
| 2 Hop (medium, eye level) | stretched rising pose, next plate's fork raised, camera ahead of the jelly | **No speed lines or arrows** (storyboard notation). **The crouch is a 4-tick visual pose at takeoff** (§2), not visible in this frame. **The first gap is bare table, not sauce;** sauce is in gaps 2, 4 and 5 (a build default). |
| 3 Warning (close-up, low angle, design view) | worried pose, the shadow on the plate | **Medium, eye level** (STORYBOARD says so). **SFX-WARN timing:** the panel says the scrape plays "as the shadow starts". After Kiran's second audition it plays when the fork over the current or next plate *starts descending*; the shadow alone is the warning (§8; a difference from CHANGE-BRIEF.md, recorded in `evidence/batch3-review.md`). The music dip is unchanged. |
| 4 Safe landing (medium, eye level) | landing squash on the next plate, the fork striking the plate behind | no impact lines (storyboard notation) |
| 5 Splat (medium, eye level) | flat splat with droplets, the fork in view on the plate | **Camera shake can't show in a still** (automated: `shake-on-fork-splat-camera-only`, max offset 6.3 px, jelly and collider unmoved; `shake-none-on-sauce-splat`, 0). **The jelly is drawn in front of the tines** (a revision so the splat stays visible, §8). |
| 6 Respawn (medium, eye level) | re-forming pose on the last safe plate, its fork raised, the next forks on their rhythm | **The camera's glide back can't show in a still** (it glides on respawn and snaps on play start or replay). **The checkpoint fork's safe window starts when control returns** (automated: `respawn-checkpoint-fork-safe`, `respawn-safe-window-lasts` 132/132 ticks). |
| 7 Dome (close-up, high angle, design view) | relief pose under the glass, "SAFE!", "press any key to play again" | **Eye level, not close-up and high** (STORYBOARD says so). **The forks stay visible above.** The music fade and SFX-WIN are covered in §5 and §4. |

- **Shots the slice does not cover:** the wide high-angle shot (panel 1), the close-up low angle (panel 3) and the close-up high angle (panel 7). All three are design views; STORYBOARD itself says the slice shows them at eye level.
- **Not drawn in the slice:** motion notation (arrows, speed lines, impact lines).
- **Cups:** not in the slice (unresolved in the design; SLICE-BRIEF §5).

## 4. Sound events

**Kiran's playtest, sound on (at `23ae39c`), note 1**, "each sound against its event": "Yeah it all looks good"

**Automated:** `bash tools/run_slice_checks.sh` → `test_slice.gd` 61/0. Each sound is counted per event from scripted input. Every call is recorded with its event ID, physics frame and game state (`sfx-calls-record-frame-and-state`).

| Check | Scripted input | Result |
|---|---|---|
| `sfx-rapid-hops-once-each` | 5 hops, each with an extra press in mid-air | 5 jumps → SFX-HOP 5, SFX-LAND 5 |
| `sfx-held-jump-once` | jump held 2 s | SFX-HOP 1, SFX-LAND 1 |
| `held-jump-through-splat-no-hop` / `fresh-press-hops-after-lock` | real key events: Space held through a splat and re-form, plus W pressed during the lock | 0 hops and 0 SFX-HOP while held; 1 after a fresh press |
| `skip-key-no-hop-no-move-space-held` / `-space-tap` / `-d-held` | skipping the intro with Space held, Space tapped, D held | 0 jumps, 0 SFX-HOP, 0 px moved |
| `restart-key-no-hop-first-plate-reset` | Space held to play again from the dome | 0 jumps, 0 SFX-HOP; first plate, everything reset |
| `sfx-respawn-silent` | splat, then re-form | SFX-SPLAT-SAUCE 1, no SFX-LAND |
| `sfx-fork-splat-once` | a real fork hit | SFX-SPLAT-FORK 1, SFX-SPLAT-SAUCE 0, SFX-LAND 0 |
| `sfx-sauce-splat-once-no-land` | walking off plate 2 into sauce | SFX-SPLAT-SAUCE 1, SFX-LAND 0 |
| `sfx-win-once` | reaching the dome, then touching the goal again | SFX-WIN 1 |
| `audio-every-event-has-a-stream`, `audio-hop-plays-its-stream` | — | 6 OGG streams, one player per event on the SFX bus; a hop plays its stream once |
| SFX-WARN: `warn-current-plate-fork-descends-once`, `warn-next-plate-fork-descends-once`, `warn-far-on-screen-fork-silent`, `warn-offscreen-next-fork-silent`, `warn-none-while-shadow-grows`, `warn-airborne-uses-last-plate`, `overlapping-strikes-warn-only-near-fork` | forks started into their descent (fixtures) | 1 scrape at the descent of a visible current-plate or next-plate fork; 0 for a far fork, an off-screen fork, or a growing shadow |
| Decoded game files: `tools/check_game_audio.py` | — | every sound effect starts within 10 ms (0 ms measured); peaks ≤ −1 dBFS; loudness at target |

## 5. Music

**Kiran's playtest, sound on (at `23ae39c`):**
- **Note 2**, "music seam, standing still for 30+ seconds (three or more loops)": "No. I dont hear any gap or jump when it repeats"
- **Note 3**, "music behavior (intro quieter, splat dip, pause very quiet, fade at the dome, fresh start on replay)": "yes"

**Automated** (the music controller's change log, and the Music bus):
- `music-intro-quieter-then-normal`: restart, then intro −8 dB, then normal when play starts.
- `music-splat-dip-back-on-respawn`: splat, then normal.
- `music-pause-quiet-muffled`: pause (−20 dB, 500 Hz low-pass), then normal.
- `music-win-fade-quiet-restart`: win fade, end quiet, restart from the top, normal.
- `music-bus-follows-target`: the bus reaches its target volume and cutoff.
- `overlapping-shadows-one-dip`: two overlapping on-screen warnings give one dip, from the first start to the last end, with no flicker.
- `offscreen-shadow-dip-once-on-screen-warn-at-strike`, `onscreen-shadow-dips-no-warn-at-start`.
- `audio-music-loops-and-plays`: an OGG stream with loop on, playing on the Music bus.
- **The loop:** take 1, 16.88–26.48 s, 4 bars at 101 bpm tracked, 9.6 s, 2 ms crossfade. The seam measurement passes any crossfade of 2 ms or more, so it only rules out a hard cut; Kiran's note 2 is the judgment of the seam.
- **Overall volume:** Kiran's note 4, "overall volume at my normal level": "yes"

## 6. Muted play

**Kiran's playtest (at `23ae39c`):**
- **Note 5**, "muted run (M) to the dome": "yes with mute also I can see the clues like the shadow keep increasing on the plate and i can also understand what killed me and when i won"
- **Note 6**, "N mutes music only": "this works too"

**Automated:**
- `mute-changes-no-state`: M and N change no game state, position, fork rhythm or logs.
- `m-n-mute-only` (keyboard suite): M mutes Master, N mutes Music, the state is unchanged.
- `mute-keys-do-not-skip`.
- `hud-text-per-state`: shows "MUTED (M)" and "MUSIC OFF (N)".

## 7. Automated checks (commands and results)

| Command | Result (final run in the working repo, and in the fresh copy) |
|---|---|
| `bash tools/run_slice_checks.sh` | ALL SLICE CHECKS PASSED |
| `bash tools/copy_game_art.sh --check` | 18 of 18 byte-identical |
| `bash tools/copy_game_audio.sh --check` | 7 of 7 byte-identical |
| `~/Documents/jellyhop-audio-env/bin/python tools/check_game_audio.py` | 8 checks / 0 failures |
| `godot --headless --path godot --script res://tests/test_game.gd` | 25 checks / 0 failures (starter mechanics, ported) |
| `godot --headless --path godot --script res://tests/test_keyboard.gd` | 12 checks / 0 failures |
| `godot --headless --path godot --script res://tests/test_slice.gd` | 61 checks / 0 failures |
| `godot --path godot --script res://tests/capture_slice.gd` | 7 screenshots at 1280 × 720 |
| `godot --path godot --script res://tests/capture_poses.gd` | 24 pose screenshots (12 poses × 2 facings) |
| `TRACE_LABEL=<name> godot --headless --path godot --script res://tests/trace_audio.gd` | sound-call trace on a scripted route (§8) |

- **Pass rule:** a suite passes only if Godot exits 0 **and** prints its summary line with 0 failures; a script that fails to compile can still exit 0.
- **Logs:** `evidence/slice-checks/final-*.txt`, `evidence/batch3-checks.txt`, and the per-run JSON reports in `evidence/`.

## 8. Inspect and revise (evidence-based revisions)

1. **SFX-WARN trigger, from Kiran's audition notes** (`evidence/batch3-audition.md`, `evidence/batch3-review.md`):
   - **Audition 1:** "the fork sound plays randomly even if the forks are not coming down".
   - **Trace before** (real game, scripted route plates 1 → 2 → 3 → 2 → 1, 25.5 s; `evidence/batch3-audio-trace-before.txt`): **22 scrapes**, 18 from forks not over the jelly's plate, 16 while no fork was down. The scrape fired at the start of every on-screen shadow.
   - **Decision 1 (Kiran):** only the current or next plate's fork scrapes. Same route: **9** (`-after.txt`).
   - **Audition 2:** "i want the sound only when the fork is coming down. it is still not connected to forks."
   - **Decision 2 (Kiran):** the scrape plays when that fork starts descending. Same route: **8**, all 8 in the same tick as their fork's descent, 0 while no fork was down (`-after2.txt`). When the descending fork hits the jelly, SFX-SPLAT-FORK follows 7 ticks (0.117 s) after the scrape.
   - **Audition 3:** "this looks good actually". Kiran's selection note for SFX-WARN: "the scrape now feels connected to the fork descending, which is what I wanted."
2. **Shadow readability (slice setup, from screenshots):** the warning shadow on the jelly's own plate was barely visible in `03-warning`. It was strengthened twice (darker, taller rings) and recaptured. Kiran's muted note 5 now says "I can see the clues like the shadow keep increasing on the plate".
3. **Splat visibility (slice setup, from screenshots):** the fork's tines covered the splat. The fork is now drawn behind the jelly, so the splat and the fork are both in view (panel 5).
4. **Fork reach (Kiran's decision):** the first plan's ~130 px fork left a safe band about 40 px wide at each plate edge. Kiran asked for the tines to span the plate, with the hit zone equal to the visible tines. `fork-edge-band-0px` gives a safe band of 0 px on all 5 forked plates. Its negative control, `fork-edge-band-control-70px`, finds a 128 px band at the Batch 2 size, so the check can fail.
5. **Other revisions found by checks** (details in FRICTIONAL.md and the review sheets):
   - the starter's low-ceiling check against the airborne crouch box (§2);
   - the camera gliding from the dome at play start (it snaps now);
   - music ramps on physics ticks;
   - leading silence trimmed at the delivered level (SFX-WARN 244 ms and SFX-HOP 60 ms, now 0);
   - audio still playing at test exit;
   - the check script's absolute paths, found by this report's fresh-copy run (§1).

## 9. Limitations and what is not verified

- **One playtester (Kiran), one machine** (macOS 26.5.1, Apple M4). No other playtesters. Windows and Linux are untested. The fresh-copy check ran on the same Mac, not a second machine.
- **Automated checks and screenshots use scripted input, and some use fixtures** (fork timing, placement, held forks, camera position), named in the test code and in `captures.txt`. They test the logic, not how the game feels or sounds.
- **Not separately confirmed by Kiran's playtest notes:**
  - whether the face reads at 64 px at 100 % zoom (predicted failure #2);
  - the jelly's visibility against each surface beyond the screenshots (#3);
  - Scoot A's 2 px box near strikes (#14);
  - the camera look-ahead's feel on every plate (#11; the automated check only shows the next shadow is on screen);
  - the shake's feel (#13; automated only).
- **The sounds' fit with their events is in Kiran's words only** (note 1, "Yeah it all looks good"). The listening judgments recorded per sound in ASSET-LOG.md stay as Kiran set them; see the dated note there.
- **The music seam is judged by one listener** (note 2). The measured seam only rules out a hard cut.
- **Collision mismatches with the sheet:** the airborne crouch's standing box, and the splat and re-form collider that stays (§2).
- **Godot crashed once (exit 139)** importing `MUS-LOOP.ogg` during Batch 3. It was not reproduced in later imports (including the fresh copy's), and the cause is unknown.
- **The audio models' output and the check tools depend on an environment outside the repository** (`~/Documents/jellyhop-audio-env`). Regenerating audio also needs the torchsde workaround in `tools/batch3_generate.py`.
- **Design differences:** the SFX-WARN trigger differs from CHANGE-BRIEF.md by Kiran's decisions (recorded, not edited into CHANGE-BRIEF.md). Cups are not in the slice.
