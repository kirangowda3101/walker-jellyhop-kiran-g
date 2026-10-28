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

---

## Assignment 3 — Three 3D assets (fork, dessert dome, biscuit platform)

Added 2026-10-13. The Assignment 2 sections above are unchanged.

**Machine and versions:** MacBook Pro, Apple M4 (Apple Silicon), macOS. Blender 5.2.2 LTS (macOS arm64 build). glTF exporter: Khronos glTF Blender I/O v5.2.40. MCP for Blender: server package `mcp-for-blender` 2.1.9 (run with `uvx`), Blender add-on 1.8. Godot 4.7.2.stable.official.ed1daf0bf, Compatibility renderer (OpenGL 4.1 Metal). Commands below were run on macOS from the repository root.

### A3.1 Interface notes

Six parts of Blender's window described in my own words, with a screenshot of my own session: `BLENDER-NOTES.md` and `evidence/a3/blender-interface.png` (commit 7d9c184).

### A3.2 Size: brief, Blender sidebar, Godot

Blender is Z-up and Godot is Y-up. The glTF exporter's +Y Up option was ticked by default for all three exports (I checked it and did not change it), so Blender (X, Y, Z) becomes Godot (X, Z, −Y): Blender's height becomes Godot's Y and Blender's depth becomes Godot's Z.

| Asset | Brief W × D × H (m) | Blender sidebar X, Y, Z (read by me) | Godot bounding box X × Y × Z (headless check) |
|---|---|---|---|
| Fork | 0.5 × 0.05 × 1.5 | 0.5, 0.05, 1.5 | 0.5 × 1.5 × 0.05 |
| Dessert dome | 1 × 1 × 0.75 | 1, 1, 0.75 | 1.0 × 0.75 × 1.0 |
| Biscuit platform | 2 × 1.5 × 0.25 | 2, 1.5, 0.25 | 2.0 × 0.25 × 1.5 |

All three match the brief within the check's 1 mm tolerance.

### A3.3 Upright and scale

- Blender sidebar: scale 1, 1, 1 for Fork, Dome and Platform (read by me); rotation and scale were applied in the build scripts before export.
- Godot: every node in each imported .glb has scale (1, 1, 1) and rotation 0, and each instance in the scene has an identity transform basis (checks A2 and B3).
- Orientation from the vertices (check A6): the fork is 0.5 m wide near the bottom (prongs) and 0.1 m wide near the top (handle), so it points down as designed; the dome is 1.0 m wide at its base, so it is not upside down; the platform's top face at Y = 0.25 spans the full 2.0 × 1.5 m.
- Seen by me through the scene camera: all three stand the right way up.

### A3.4 Origin

Each asset is placed at Y = 0 in `godot/showcase/a3_assets.tscn`, on a floor whose top is at Y = 0 (check B1). Check B2 compares each asset's lowest vertex in world space with the top of the Floor node's own mesh (two different nodes, so the asset is not measured against itself):

| Asset | Lowest vertex − floor top |
|---|---|
| Fork (prong tips) | 2.98e-08 m (floating-point rounding from export, inside the 1 mm tolerance) |
| Dessert dome | 0 |
| Biscuit platform | 0 (landing surface at Y = 0.25) |

Seen by me through the scene camera: all three sit on the floor; none floats or sinks.

### A3.5 Triangle count

| Asset | Budget (brief) | Blender status bar (seen by me) | Godot (check A7) |
|---|---|---|---|
| Fork | 100 | 72 | 72 |
| Dessert dome | 300 | 266 | 266 |
| Biscuit platform | 60 | 36 | 36 |

### A3.6 Imports and appears

`godot --headless --path godot --import` imported `dome.glb`, `fork.glb` and `platform.glb` with no errors or warnings and created their `.import` files (commit caa382b). All three appear in `godot/showcase/a3_assets.tscn`, side by side with a 0.5 m `JellyScaleRef` cube (a size reference for the 0.5 m jelly, not an asset).

### A3.7 Automated check (command and result)

```
set -o pipefail
timeout 120 godot --headless --path godot --script res://tests/test_a3_assets.gd --fixed-fps 60 2>&1 | tee evidence/a3-assets-run.log
echo "exit: $?"
```

Result (2026-10-13, 01:46): `A3 ASSET CHECKS: 36 checks / 0 failures`, exit code 0, and no ERROR, FAIL or WARNING lines in `evidence/a3-assets-run.log`. JSON report: `evidence/a3-assets-1791870366.json` (commit 8a019a2). Claude Code wrote the check; I read its plan and its report before accepting it.

**What the check shows:** each .glb loads; its bounding box, scale, rotation, lowest and highest Y, rough shape orientation and triangle count match the brief converted to Godot's axes; each asset's lowest point sits on this scene's floor; every asset is inside the camera's view.

**What it does not show:** nothing is rendered, so it says nothing about colours, lighting or how the shot looks; "inside the camera's view" is geometric only; "on the floor" is only this scene's floor, which was built for the check; no gameplay or colliders are tested; differences under 1 mm pass; the dome's cherry test is weak (it would pass for any small shape on top, as Claude Code itself pointed out); only the current imports are tested.

### A3.8 HUMAN CHECK: look

My own words after running the scene and orbiting the editor camera:

- Through the scene camera: "At this size, I can recognise the fork, dessert dome, and sandwich biscuit. I don't see obvious holes in the visible surfaces, but the dark sides hide some detail."
- From below: "From below, the floor blocks the assets, so I haven't verified their undersides yet." I then hid the floor temporarily: "With the floor hidden, the platform's underside and the dome's base look closed, with no obvious holes. They're quite dark, though, and the fork tips are too small in this view for me to confidently check every face."
- Scale beside the jelly reference: the fork is about three reference cubes tall and the dome about one and a half, as the brief intends.
- No other person has looked at the scene.

### A3.9 What Claude got wrong

- **Dome colours.** Claude Code's original Dome_Pink, Dome_Cream and Dome_Red read as washed out in Material Preview: the cover looked nearly white-lavender, the base nearly white and the cherry salmon. I corrected all three by hand (A3.10).
- **Cherry placement.** Claude Code's first dome plan had the cherry touching the cover at a single point. I asked for it to sit 0.04 m into the cover, keeping the top at 0.75 m.
- **Beyond the plan.** In step 1 of each build Claude Code also removed an unused "Dots Stroke" material and set fake users on new materials, which its plan had not mentioned; it reported both afterwards.
- **Its own check.** Claude Code flagged that its cherry test is weak (A3.7).
- Not Claude: the course chapter's `claude mcp add -e DISABLE_TELEMETRY=true blender -- uvx mcp-for-blender` failed on Claude Code 2.1.288 (see FRICTIONAL.md).

### A3.10 Inspect and revise (evidence-based revision)

**Observation:** in Blender's Material Preview, the dome's colours looked washed out (see A3.9).
**Change (my hand edit in Blender's Material tab):**

| Material | Before (perceptual hex) | After | What I changed |
|---|---|---|---|
| Dome_Pink (cover) | #D1AAB6 | #D17390 | Saturation 0.184 → 0.45 |
| Dome_Red (cherry) | #DA303F | #A6111E | Saturation 0.90, Value 0.65 |
| Dome_Cream (base) | ≈ #F9EDD3 (computed from Claude's linear 0.95, 0.85, 0.65; not read by me) | #F9DEA2 | Saturation 0.35 |

**Re-check:** Claude Code read the base colours back after the join; converted to sRGB they equal my three hex values exactly. In Godot, through the scene camera, the dome reads clearly as a pink cover with a red cherry and a cream rim.

### A3.11 Predicted failure cases (from CHANGE-BRIEF.md) and results

| # | Prediction | Check | Result |
|---|---|---|---|
| 1 | Fork arrives sideways or upside down | Scene camera; checks A2, A5, A6 | Did not happen: handle up, prong tips on the floor |
| 2 | Dome arrives at the wrong size | Blender sidebar vs Godot bounding box; node scale | Did not happen: 1 × 1 × 0.75 in Blender, 1.0 × 0.75 × 1.0 in Godot, scale 1, 1, 1 |
| 3 | Platform origin in its centre, so it sinks | Check B2; side view | Did not happen: underside on the floor, top at 0.25 m |
| 4 | MCP does not connect | Add-on panel; `get_scene_info` | Connected after about 15 minutes, with one command fix |
| 5 | Claude exceeds a triangle budget | Blender status bar vs budget | Did not happen: 72 / 266 / 36 against 100 / 300 / 60 |

### A3.12 Limitations and what is not verified

- **Black shaded sides.** The scene has one DirectionalLight3D and no WorldEnvironment, so faces turned away from the light render pure black. This hides colour and detail there: the platform's right side and its cream line, the reference cube's side, and the undersides seen from below. I kept the one-light scene the assignment specifies rather than adding ambient light.
- The fork's prong tips were not checked close up from below.
- The editor's preview lighting made the fork look nearly white; through the scene's own light it reads as silver-grey. Material Preview in Blender and Godot's lighting also show the same colours differently.
- The dome's Solid-mode viewport colours in Blender still hold Claude Code's original values, and a fresh run of `tools/blender/build_dome.py` recreates the original colours, not my hand-edited ones (the hand edit is recorded in the call 5 comment and here).
- Box-only shapes: the fork's prong tips are blunt, and the biscuit's plain top could pass for a plank from directly above.
- Where the fork and dome currently appear in the Assignment 2 game is still to be confirmed (open item in CHANGE-BRIEF.md); the platform placement is planned for future levels and is not implemented.
- The assets are not in the 2D game and have no colliders; nothing here is a playtest.

## Assignment 5 — Shaders, materials and the Godot shading language

Godot 4.7.2.stable.official.ed1daf0bf, macOS, Apple M4. Project renderer: **Compatibility** (`project.godot` line 32); one comparison run on Forward+ via `--rendering-method forward_plus` (project unchanged). All tests run through `scripts/run-test.sh` (pinned `--fixed-fps`). Drafted with Claude in chat from the committed logs and evidence; every value below was checked against those files by me.

### A5.1 Baseline, before and after (no existing expectation changed)

| Suite | Before A5, 60 fps (2026-10-27) | After the driver, 60 fps |
|---|---|---|
| `test_game.gd` | 25 / 0 | 25 / 0 |
| `test_slice.gd` | 61 / 0 | 61 / 0 |
| `test_keyboard.gd` | 12 / 0 | 12 / 0 |
| `test_a3_assets.gd` | 36 / 0 | 36 / 0 |

"Before" logs: `logs/test_*_60fps.log` at commit dda6bd9. "After": sessions 2b (step 2) and 2d (step 8). The `ObjectDB … leaked` warning and `resources still in use` error at exit are pre-existing (CLAUDE.md headless facts).

### A5.2 Shaders parse; uniform names (headless)

- `test_fork_warning.gd` asserts `warning`, `warn_color`, `strength` via `get_shader_uniform_list()` and the defaults from the source text. `test_materials.gd` does the same for `table_wood.gdshader` and `hint_experiment.gdshader`. No `SHADER ERROR` in any final log.
- **Mutation 1 (semicolon)**, line 4 of `fork_warning.gdshader`: `SHADER ERROR: Expected a ';'`, uniform list empty, exit 1 (`logs/mutation-1-semicolon_60fps.log`).
- **Mutation 2 (rename `warning` → `warn_level`, shader only)**: no shader error, 4 / 29 checks fail (uniform list and source checks), exit 1. The other 25 value checks still passed, because `set_shader_parameter` stores an undeclared name silently, so only the uniform-list check catches it (`logs/mutation-2-rename_60fps.log`).

### A5.3 Driver: fork warning, through the real game loop

`test_fork_warning.gd`: **29 / 0 at 30, 60 and 144 fps**. Per-tick `warning` sequence identical at all three rates: MD5 `35385bc4a519009a685ec285b3ba7529`. I checked the test does not call `advance()` / `_apply()`, set the uniform, or write `t`, `held` or `state` (grep, commit 2385d6b).

- First SHADOW tick reads `1/n`, rises `1/n` per tick, last tick exactly `1.0`, first DOWN tick `0.0` (rule 1). Per frame at 30 fps the last frame reads `(n−1)/n`, as my per-tick/per-frame split in rule 1 predicted.
- Each ramp's per-frame duration within one frame period at 30, 60, 144 (rule 2).
- Intro: plates 5 and 6 read exactly `37/72` and `31/60`, held through the pan (rule 4).
- Pause (real Esc) and tree pause both hold the value exactly; `Engine.time_scale = 0.5` keeps 96 ticks, 0.8 s scaled and 1.6 s real (rule 5).
- Sauce splat mid-SHADOW (real keys): 0.375 / 0.385 on the tick before, `0.0` on the splat tick; next SHADOW restarts at exactly `1/96`; the fork-splat (`hold_pending`) path also restarts at `1/96` (rules 3 and 6).
- Five distinct materials, none the base `.tres`, one shared `Shader` (rule 7).

### A5.4 Controlled values (HUMAN CHECK: scripted in-engine captures, windowed)

`tools/capture_a5.gd` (by Claude in chat, run by me) freezes the session's physics so no fork advances, then sets `warning` on the plate 2 fork. P1 moved to art (194, 1144) in CHANGE-BRIEF Revision 5, because the original P1 is never on screen. Compatibility values (`logs/capture_a5.log`, `evidence/a5-captures/fork_warning_*.png`):

| `warning` | P1 measured | P1 predicted | P2 measured | P2 predicted |
|---|---|---|---|---|
| 0.0 | (179, 183, 184) | (179, 183, 184) | (114, 127, 129) | (113, 126, 128) |
| 0.5 | (204, 182, 147) | (204, 182, 147) | (160, 144, 110) | (159, 143, 109) |
| 1.0 | (229, 181, 110) | (228, 180, 111) | (206, 161, 91) | (205, 160, 91) |
| 2.0 | (255, 178, 37) | (255, 178, 37) | (255, 195, 53) | (255, 195, 54) |

Every value is within one 8-bit step (P2's 5 × 5 neighbourhood itself varies by ±2). Forward+ gives the same within one step. **`hint_range` does not clamp a value set from code:** `warning = 2.0` gives exactly the extrapolated (255, 178, 37). The background behind the tines is table wood (105, 65, 45), not the room colour my §6 assumed; against it P1's contrast ratio goes from about 4.3 : 1 to 4.7 : 1 (WCAG relative luminance, computed by Claude from these measured pixels).

### A5.5 In play (HUMAN CHECK, by me)

`evidence/a5-playtest-notes.md`: far forks start partly golden; each fork turns golden gradually before it strikes and returns to silver; the gold is easy to see and the fork still reads as a fork; everything else looks normal; a golden fork stayed golden after the win (the WON hold, the one rule with no headless check).

### A5.6 Hint experiment (HUMAN CHECK, scripted captures + one OS screenshot)

| Band (file value) | With `source_color`: Compatibility | Forward+ | Without: Compatibility | Forward+ | Predicted without (§8) |
|---|---|---|---|---|---|
| 64 | 64 | 64 | **64** | **137** | 137 |
| 128 | 128 | 128 | **128** | **188** | 188 |
| 192 | 192 | 192 | **192** | **225** | 225 |

Every 5 × 5 neighbourhood is flat. **My §8 predictions hold exactly on Forward+.** On the project's Compatibility renderer both quads show the file's values unchanged, so the difference is the renderer: measured first, explained after, as the brief said I would. A macOS window screenshot gave the same 64/128/192 as the in-engine capture; I trust the in-engine capture for measurement (`evidence/a5-os-screenshot-note.md`). Logs: `logs/capture_a5.log`, `logs/capture_a5_forward_plus.log`.

### A5.7 Interface sweep (HUMAN CHECK, by me)

`evidence/a5-sweep-notes.md` (15 frames of the worn table, each uniform at min / default / max): `brightness`, `uv_scale` and `tint` change as predicted. `roughness_scale` changes the table only gently (largest pixel difference 20 / 255), with **no Sun highlight**, so my §7 prediction did not hold under Sun-only lighting. `normal_strength` has no measurable effect (largest difference 2 / 255); likely reason, not tested: the normal map is very flat. No setting produced a broken look.

### A5.8 One shader, two materials (HUMAN CHECK, scripted captures, in memory only)

`evidence/a5-captures/shared/`: the table and the board share one `Shader` object and have different materials. Editing one shader line changed both (table (92, 45, 29) → (41, 31, 29); board (87, 32, 11) → (33, 17, 11)). Editing only the board material's `brightness` changed only the board (→ (23, 4, 0)); the table stayed (92, 45, 29). No file changed.

### A5.9 Material wiring, texture data, import settings

- `test_materials.gd` (agent audit, reviewed by me): **108 / 0** at 60 fps. From an empty cache (`rm -rf godot/.godot`) the **first headless `--import` segfaults** (exit 139, 2 / 2 attempts; the log ends at `reimport | SFX-WIN.ogg`, an A2 audio file); the **second `--import` completes** and the test passes 108 / 0. Fresh clones need `--import` run twice (`logs/fresh_import_run2–4.log`).
- **`source_color` mutation** (removed from `albedo_tex`): no shader error, 1 / 108 fails (`sampler_hints albedo_tex`), exit 1 (`logs/mutation-3-source-color_60fps.log`).
- **Curl ratio** (`normal_map_check.gd`, the handout's check, verbatim; stride 4): `nor_gl` 0.3838 (GL) / 1.6162 (DX); `nor_dx` 1.6163 / 0.3837. The bound GL map passes my texture-specific threshold < 0.70 (Revision 3). The PNGs are 16-bit in the file but Godot decodes them to `FORMAT_RGB8`, which adds quantization noise.
- **Import settings**: set explicitly (Revisions 2 and 3); confirmed by name in the Import dock. **No `.import` file was rewritten** after the editor drew the textures in 3D (failure 6 did not happen).

### A5.10 Agent sessions and checks after each

| Session | Turns | Denials | Result | `git diff godot/shaders/` |
|---|---|---|---|---|
| 1 (CLAUDE.md) | 18 | 1 | success | empty |
| 2a (plan, read-only) | 12 | 0 | success | empty |
| 2b (driver + test, steps 1–5) | 37 | 3 | stopped at step 5 as instructed | empty |
| 2c (step 5 fixes, step 6) | 21 | 0 | stopped at step 6 as instructed | empty |
| 2d (steps 6–8) | 29 | 0 | success | empty |
| 3 (audit) | 28 | 8 | success | empty |

In session 1, commands outside the allowlist (`file`, `wc`, `head`, `which`) ran, and only one compound `grep` was denied, so the diff, not the permissions, is what guaranteed the shaders were untouched.

### A5.11 Known limitations

- On Compatibility, `source_color` on a texture makes no visible difference on the unshaded path (A5.6); the Forward+ comparison was a one-run override.
- `roughness_scale` is subtle and `normal_strength` invisible under Sun-only lighting with this flat map (A5.7).
- `uv_scale` scales the `BoxMesh`'s own UVs: the top face is a 1/3 × 1/2 UV slice, so about 0.67 × 1 copies show at 2.0 (Revision 4).
- The fresh-cache first import segfaults on an A2 `.ogg` (A5.9).
- Whether the table's `tint` (`source_color` on a spatial `vec4`) is converted to linear was not measured.
- Captures are scripted (labelled as such); `--fixed-fps` hides real-time frame pacing.
