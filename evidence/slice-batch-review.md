# Slice setup batch: review sheet (2026-10-03)

Built by Claude Code from the approved plan (`evidence/slice-plan.md`), in steps 0–10, then revised after Kiran's review (§7). **Nothing is committed.** Every result below comes from a command that was run, and its log is in `evidence/slice-checks/`. All automated tests drive the game with scripted input; **the only human playtest is Kiran's, recorded in §7 and in FRICTIONAL.md.**

## 1. Results (final run after the review changes: `bash tools/run_slice_checks.sh`, 2026-10-03 02:18)

| Check | Result | Log |
|---|---|---|
| Art copies in `godot/assets/art/` byte-identical to `art/game/` (cmp + SHA-256) | 18 of 18 | `final-art.txt`, `evidence/slice-art-copy.txt` |
| `test_game.gd` (mechanics, ported from the starter) | 25 checks / 0 failures, exit 0 | `final-test_game.txt` |
| `test_keyboard.gd` (synthetic key events, ported) | 12 checks / 0 failures, exit 0 | `final-test_keyboard.txt` |
| `test_slice.gd` (SLICE-BRIEF §8 and the rest of this batch) | 52 checks / 0 failures, exit 0 | `final-test_slice.txt` |
| Screenshots of the 7 storyboard moments | 7 of 7 at 1280 × 720 | `evidence/slice-screens/`, `captures.txt` |
| Game launched from the command line (`godot --path godot`) | ran 8 s with no errors logged, then closed by the script | `final-launch.txt` |
| Game launched from the Godot editor | Kiran played it from the editor (F5), silent build (§7) | FRICTIONAL.md |

Commands (`G=/Applications/Godot.app/Contents/MacOS/Godot`):
```
bash tools/run_slice_checks.sh                                     # everything below, stops on the first problem
bash tools/copy_game_art.sh --check                                # art copies only
$G --headless --path godot --import
$G --headless --path godot --script res://tests/test_game.gd
$G --headless --path godot --script res://tests/test_keyboard.gd
$G --headless --path godot --script res://tests/test_slice.gd
$G --path godot --script res://tests/capture_slice.gd              # opens a window
./walker-jumpman.command        # or: $G --path godot              # play the game
```
**A suite counts as passed only if Godot exits 0 *and* prints its summary line with 0 failures.** In step 5 a test script failed to compile, and Godot still exited 0.

### SLICE-BRIEF §8 checks → test ids (all in `test_slice.gd`)
1. Each sound fires once per event (failure #5): `sfx-rapid-hops-once-each` (5 hops → 5 HOP, 5 LAND, including presses in mid-air), `sfx-held-jump-once`, `sfx-respawn-silent`, `sfx-fork-splat-once`, `sfx-sauce-splat-once-no-land`, `sfx-win-once`, `sfx-calls-record-frame-and-state`.
2. The skip and restart keys never hop or move the jelly (#6): `skip-key-no-hop-no-move-space-held`, `-space-tap`, `-d-held`, `restart-key-no-hop-first-plate-reset`, `mute-keys-do-not-skip`.
3. A jump held through a splat gives no hop until a fresh press (#7): `held-jump-through-splat-no-hop` (0 jumps, 0 SFX-HOP), `fresh-press-hops-after-lock`.
4. A shadow phase that starts off screen never plays SFX-WARN (#8). **Revised by Kiran's decision (§7):** it dips the music once any part of it is on screen while it is still warning, and not before. Check: `offscreen-shadow-no-warn-dip-once-on-screen` (no music change while off screen; `warning` once on screen; `normal` after the strike; 0 SFX-WARN). Control check, the same fork's next shadow phase starting on screen: `onscreen-shadow-warns-and-dips`. **Note:** SLICE-BRIEF §8 #4's "no music dip" wording came from the Claude chat brief. Kiran's decision on 2026-10-03, which follows CHANGE-BRIEF.md's music rule, supersedes it. SLICE-BRIEF.md itself is not edited.
5. The checkpoint fork is in its safe window when control returns (#12): `respawn-checkpoint-fork-safe` (after a real fork splat; t = 0 at control return), `respawn-other-forks-keep-rhythm` (0 ticks of drift), `respawn-safe-window-lasts` (132 of 132 ticks).
6. No camera shake on a sauce splat; a fork splat shakes the camera only (#13): `shake-none-on-sauce-splat` (max offset 0), `shake-on-fork-splat-camera-only` (max offset ≈ 6.3 px; jelly and collider unmoved).
7. Overlapping on-screen shadows (#9): `overlapping-shadows-one-dip`. The music log shows exactly `warning` at the first shadow's start and `normal` when the last warning ends, with 91 ticks of overlap and nothing in between. `overlapping-shadows-two-warns` confirms one SFX-WARN per fork.

Other checks in this batch:
- **Fork decision:** `fork-edge-band-0px` (safe band 0 px on all 5 forked plates, both boxes, 1 px steps). Its negative control, `fork-edge-band-control-70px`, squeezes the hit area to the Batch 2 size and finds a 128 px safe band, which shows the check can fail. `fork-hit-equals-tines` (hit −100.0…+100.6 px = the visible tines; the plate's landing surface is ±98.5), `fork-top-off-screen`.
- **Poses, intro and camera:** pose and box checks; `intro-pan-dome-to-jelly`; `look-ahead-next-shadow-on-screen` (failure #11, from each jump mark).
- **Win and music:** `win-dome-celebrate-prompt`; the `music-*` checks (intro → normal, splat dip → normal, pause → normal, win fade → end quiet → restart → normal, bus volume and cutoff reach their targets).
- **Mute and HUD:** `mute-changes-no-state`, `hud-text-per-state`.
- **Intro shadows (Kiran's decision, §7):**
  - `intro-shows-shadows-frozen`: the shadows of plates 5 and 6 are visible during the pan at 51–52 % and frozen, with 0 SFX-WARN. 230 pan ticks were observed. The threshold is half the pan, because headless runs can batch two physics ticks into one frame.
  - `play-starts-quiet-no-onscreen-shadow`: when play starts, no fork is on screen in its shadow phase. Plates 5 and 6 are in their shadow phase off screen; 0 SFX-WARN; music `normal`.
  - `replay-starts-quiet-no-onscreen-shadow`: the same checks after a replay from the dome.

### Starter checks: kept, ported, replaced
- **Step 2 (unit conversion):** the unchanged starter suite passed at the ×2 scale. Every length and speed came out exactly doubled and every tick count was identical (route 325 ticks both times, retry 34 ticks both times). See `step2-units.txt`.
- **Kept with new numbers:**
  - The checks themselves: launch-grounded, speed-cap (320), neutral-stop, simultaneous-directions, fixed-jump-and-no-double (rise 112.07 px, expected 106.7 ± 10), held-jump-no-bounce, coyote-5/6/7, buffer-5/6/7, low-ceiling, pause-freezes, focus-loss-pauses, duplicate-death-ignored, respawn, death-before-finish, complete-real-route, replay-idempotent.
  - left-wall: x 26 here. The starter clamped at x 10; here the 52 px box stops against the end wall.
  - twenty-retries: limit = splat + re-form + 2 ticks = 80; measured 78. The starter's limit was 60 for a 0.55 s retry.
- **Replaced:**
  - `actual-spike-collision` → `actual-sauce-collision` (no spikes).
  - `manual-restart-not-death` → `checkpoint-respawn` (R is not in the decided controls).
  - `fall-boundary` → `level-bounds` (the table is continuous, so there is no pit).
  - Keyboard checks: `enter-start` → `any-key-start`; `enter-resume` → `escape-resume`; `r-retry` → removed (no R key); `enter-replay` → `any-key-replay`; `pause-main-menu` and `menu-start-again` → `m-n-mute-only` (no menu). New: A, D and arrow moves; Space, Up and W jumps.
- **`complete-real-route`** now goes through the forks. The route driver still only presses keys. At each plate's jump mark it searches the forks' known cycles for a safe hop, and it reaches the dome with 0 splats (hops at ticks 71, 147, 221, 303, 387, 458 after the review's fork-offset change).

## 2. Defaults chosen for §9 (all in `godot/game/slice_tuning.gd`, marked DEFAULT)

| Value | Default |
|---|---|
| Plate gaps (rim to rim) | 120, 140, 150, 160, 170 px; plates at x 160, 480, 820, 1170, 1530, 1900 (200 px wide) |
| Sauce | gaps 2, 4, 5 (hit zone 116 × 14 px, the puddle's lower body). Gaps 1 and 3 are bare table, which is safe floor |
| Dome | on the table, 150 px after plate 6; goal = the dome's footprint minus 40 px each side; level 2684 px wide |
| Fork cycles (shadow / safe / offset, s) | P1 none · P2 1.6/2.2/0.0 · P3 1.4/1.9/1.0 · P4 1.3/1.6/0.4 · **P5 1.2/1.4/2.0 · P6 1.0/1.2/1.7**; strike = down 0.12 + hold 0.30 + up 0.28. The offset is seconds into the cycle, which starts with the safe window. P5 and P6 are off screen at the start, so they begin halfway into their shadow phase (Kiran's decision, §7). In the first build they were 1.0 and 0.8; the plan's 1.6 for P5 was longer than its safe window. |
| Raised fork | tine tips at y 240 (above the hop's peak) |
| Bored delay | 4.0 s |
| Splat / re-form | 0.6 s / 0.7 s |
| Intro pan | 4.0 s, ease in-out |
| Look-ahead | 240 px; camera smoothing 4 (the glide on respawn) |
| Shake | 8 px, 0.25 s, decaying; camera offset only |
| Music (dB / low-pass) | intro −8 · normal 0 · warning −9 / 900 Hz · splat −12 · pause −20 / 500 Hz · win fade −40 over 1.5 s · end quiet −40; 0.25 s ramps |
| Pose timing | crouch 4 ticks, landing 8 ticks, scoot frame 0.12 s, prompt after 1.0 s, win slide 0.3 s |
| Shadow look | 5 stacked ellipses, 25 % → 100 % of 212 px, ring alpha 0.28 × (0.45…1). Strengthened twice after looking at the screenshots |
| Room | static, brightness unchanged (flagged for review) |

## 3. Differences from the design documents or the plan (for your review)

Decided by you:
1. **Units:** the world is 1280 × 720 and movement values are ×2 (speed 320, jump −640, gravity 1920). The jump looks and feels the same on screen.
2. **Fork:** the tines span the plate (fork scale 0.6309, ≈ 799 px tall; Batch 2 proposed a 70 px head). The hit zone is the four tine outlines traced from the art's transparency, so it matches the visible tines. Safe band 0 px. Found while building: at this size the fork's top is always off-screen, so **the handle extension in the plan was not needed** and was not built. A test asserts the top stays off-screen.

My routine choices (from the plan, or found during the build):

3. Controls follow SLICE-BRIEF §6. The starter's R, Enter, P and M-menu keys are removed, and so is its menu card. The intro pan is the opening.
4. **The crouch (ANTIC) is visual only** and is shown for 4 ticks after takeoff. **New: it keeps the standing box**, while CHARACTER-SHEET.md gives the crouch the low box. With the low box in the air, the starter's low-ceiling check failed: the feet rose 48 px under 40 px of headroom. I fixed the code, not the check.
5. M and N only mute, and never skip or restart.
6. SFX-LAND also plays for a landing on bare table. The map says "on a plate". A landing into sauce is a splat, not a landing.
7. Forks are frozen during the intro and start their cycles when play starts. **Changed by Kiran (§7):** the forks off screen at the start (plates 5 and 6) now begin halfway into their shadow phase, so the pan shows shadows. No fork is on screen in its shadow phase at the start, and nothing warns.
8. On reaching the dome, the jelly slides 0.3 s to the dome's centre so it is inside the glass.
9. The starter's retry counter and timer line are removed.
10. The audio buses are created in code (Master, Music with a low-pass, SFX).
11. **Kept by Kiran (§7).** A direction held through a lock (skip, restart, splat and re-form, unpause) is ignored until released, like a held jump. §8 #2 requires "no movement" from the skip or restart key.
12. **Kept by Kiran (§7).** The music "warning" covers the shadow phase *and* the strike (down and hold), and ends when the fork starts to rise. Reason: CHANGE-BRIEF says the music is quieter "while an on-screen shadow is growing", and panel 4 says it "fades back to normal after the strike".
13. **Changed by Kiran (§7):** a shadow that started off screen dips the music once any part of it is on screen while it is still warning (CHANGE-BRIEF.md's rule). It still never plays SFX-WARN. Because #12 is kept, "still warning" means the shadow phase and the strike for every shadow (my reading of how #12 and #13 combine).
14. **New:** "on screen" means any part of the full-size shadow is inside the camera's view.
15. **New:** the checkpoint plate's fork is held from the moment of the splat. A strike in progress finishes, so the cause stays visible, and then the fork stays raised until control returns. At that point its safe window starts.
16. **New, after inspecting the screenshots:** the fork is drawn behind the jelly, so a splat under the tines is visible (panel 5).
17. **New:** the camera snaps to the jelly when play starts or restarts. It glides only on respawn.
18. The starter's `levels/first_steps.json` is removed; the layout is built from `slice_tuning.gd`. `capture_game.gd` was renamed and ported to `capture_slice.gd`.

## 4. Problems found during the batch, and what was done
- **Step 0:** the first baseline loop hung at `--import` and was stopped. zsh passed the arguments as one word; I didn't confirm this was the cause. Rerun with separate arguments: passed.
- **Step 4:** starter `low-ceiling` FAILED (see difference 4). Fixed in code; the check is unchanged.
- **Step 5:** `test_slice.gd` failed to compile and Godot exited 0. The run script now requires each suite's summary line.
- **Step 5:** I added a negative control so the 0 px edge-band result can't pass by accident.
- **Step 7:** 7 failures.
  - A real camera bug: after a skip or start, the camera glided from the dome, putting far forks on screen.
  - A real music issue: the volume and filter ramps ran on render frames, which don't track game time in a headless run. They now run on physics ticks.
  - Two test-window mistakes: counting started before a placement drop had landed, and an overlap window ran into a fork's next cycle. The windows were fixed; the assertions are unchanged.
  - The mute check passed once the camera was fixed.
- **Step 9:** the warning shadow was too faint and the splat was hidden behind the tines. Both were revised and recaptured. Shadow readability still needs your eyes (failure #4).

## 5. Still needs a human: playtest or listening
- **Feel and difficulty:**
  - The jump at the new scale; the gap sizes.
  - Fork timings: a route exists (found by search), but whether it is fair and readable is a playtest question.
  - How the very large forks read and feel.
  - The bored delay, pan length, crouch read, and splat and re-form lengths.
- **Failure #2** (face readable at 64 px, 100 % zoom), **#3** (jelly visible on plate, fork and table), **#4** (room brightness; whether the shadow reads as a countdown).
- **#11** (the look-ahead's feel), **#13** (the shake's feel), **#14** (Scoot A's 2 px box near strikes), **#15** (a full muted playtest).
- **All listening** (#8 and #9 by ear, #10 loop seam): this waits for the audio batch. The placeholders play nothing; only the call and log logic is tested.
- ~~Launching from the Godot editor (F5)~~: done by Kiran (§7).
- Kiran's playtest covered the shadow as a timing clue, fairness of the timing, and overall feel (§7). The other items above have no recorded result yet.

## 6. Files
- **Changed (starter files):** `godot/project.godot`, `features/player/player.gd`, `features/player/tuning.gd`, `game/session.gd`, `ui/hud.gd`, `tests/test_game.gd`, `tests/test_keyboard.gd`, `tests/route_driver.gd`; `tests/capture_game.gd` → `tests/capture_slice.gd`; `levels/first_steps.json` deleted.
- **New:** `godot/game/slice_tuning.gd`, `godot/features/fork/fork.gd`, `godot/audio/sound_events.gd`, `godot/audio/music_controller.gd`, `godot/tests/test_slice.gd`, `godot/assets/art/` (18 PNG copies + Godot `.import` files; mipmaps on all but ENV-ROOM), Godot-generated `.uid` files, `tools/copy_game_art.sh`, `tools/run_slice_checks.sh`.
- **Evidence:**
  - `evidence/slice-plan.md`, this file, `evidence/slice-checks/` (step and final logs), `evidence/slice-screens/`, `evidence/slice-art-copy.txt`.
  - The test runners also write a JSON report per run into `evidence/`. Kiran asked to stage all 25. The reruns for the review changes added 7, so **32 are staged**. Tell me if you want only the original 25.
- **Also changed after the review:** `godot/game/main.tscn`, where the root node `WalkerJumpman` is now `JellyHop`.
- **Unchanged (checked with `git status`):** `art/`, `gen-inputs/`, `design/`, CONCEPT, STORYBOARD, CHARACTER-SHEET, CHANGE-BRIEF, SLICE-BRIEF, ASSET-LOG. FRICTIONAL.md: a new dated entry appended; earlier entries byte-identical. No audio files, nothing over 25 MB (`godot/assets` is 4.5 MB).

## 7. Kiran's review (2026-10-03)

**Playtest (Kiran, from the Godot editor, F5, silent build, no audio), in Kiran's words:**
"1. Yes i can see the shadow growing and yeah it acts like a clue to when to jump 2. yes the timing is fair 3. its good"

**Decisions:**
- **#12** (music through the strike): kept. Quiet and muffled through the shadow and the strike; back as the fork rises.
- **#13** (off-screen shadow): changed to follow CHANGE-BRIEF's music rule. A shadow that started growing off screen dips the music once any part of it is on screen while it is still growing, but it never plays SFX-WARN. The check was updated and renamed `offscreen-shadow-no-warn-dip-once-on-screen`. SLICE-BRIEF §8 #4's "no music dip" came from the Claude chat brief and is superseded; SLICE-BRIEF.md is not edited.
- **#7** (intro shadows): changed. Forks off screen when play begins start partway into their shadow phase, frozen during the pan. No fork is on screen in its shadow phase at the start, and nothing warns. Three checks were added (§1).
- **#11** (held direction ignored after a lock): kept.
- All other differences were accepted as listed.
- **Routine:** the root node is renamed `JellyHop`; the JSON test reports are staged.

**Two test fixes during these changes (logged in `evidence/slice-checks/review1-changes.txt`):**
1. The first version of `intro-shows-shadows-frozen` ran one tick past the pan, into play, where the forks correctly move.
2. Its coverage threshold (237 observed ticks) then failed at 230 observed. The forks were frozen on every observed tick. Observed ticks can be fewer than physics ticks when a headless run batches two physics steps into one frame, so the threshold is now half the pan. The "frozen" assertion is unchanged.
