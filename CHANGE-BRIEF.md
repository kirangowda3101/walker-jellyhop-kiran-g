# CHANGE-BRIEF — Assignment 7: Animation

**Jelly Hop: Fork From Above · Version 1 · 2026-11-16**

Starting point: A6 at tag `a6` (`31b9e9e`). The 14 counted A7 baseline runs and separate supplemental checks are in `evidence/a7-baseline/`, committed in `735b200`. Engine: Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility renderer, 1280 × 720. This brief records the plan before implementation. Keep the initial version in history and append dated revisions after reviewing the strips and playing the game.

## Clips

| Clip | What it communicates | Route | Trigger and authority |
| --- | --- | --- | --- |
| `scoot`, looping cycle | The jelly is shuffling along the plate. The cadence and facing should match the current A/B poses. | Two cells on a Sprite2D, held by a discrete `frame` track. | `player.gd` selects SCOOT-A or SCOOT-B. The AnimationPlayer writes the displayed cell. |
| `land`, committing action | The jelly has touched down, absorbed the impact and settled. I want a quick squash, a short hold and a slower return to upright. | Two Sprite2D cutouts under Node2D pivots. The pieces move and scale without swapping drawings. | `player.gd` selects LAND. The `just_landed` flag marks fresh contact and `land_ticks` gives the phase. The AnimationPlayer writes the rig transforms. |

## Sheet and cycle

The source is Kiran Gowda's A2 jelly artwork, made locally with [Stable Diffusion XL Base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0). The prompts, edits and cutouts are recorded in `ASSET-LOG.md` (prompt at lines 10–11, pose entries at 57–85 and 112–121, cutouts at 166). See `SOURCES.md` for the model and terms. There is no downloaded sheet; the input PNGs are already in the repo, with identical A2 copies under `art/game/`.

The model's [CreativeML Open RAIL++-M terms](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md) are dated 2023-07-26 and were checked on 2026-11-16. Section 6 generally leaves the rights in generated output unclaimed by the licensor; output use remains subject to the terms. The public repo and film will contain the artwork, not the model weights. Record the source, author, terms link and date checked in `godot/assets/art/CHAR-SCOOT-SHEET.ATTRIBUTION.md`.

| Cell | Source | SHA-256 |
| --- | --- | --- |
| 0, left | `godot/assets/art/CHAR-SCOOT-A.png` | `6aa35cf27aa3ed6202f2d0254f1defe456d0db4a387981cf0104be03af6b916a` |
| 1, right | `godot/assets/art/CHAR-SCOOT-B.png` | `f95dacdb13614d9ed7d4a5798e3bf6df8902d5dcd5186f368631bcce0a4bb271` |

Pack the two 1024 × 1024 RGBA canvases side by side without cropping, resizing or padding. The resulting sheet is `godot/assets/art/CHAR-SCOOT-SHEET.png`, 2048 × 1024, with `hframes = 2` and `vframes = 1`. I will review and run the headless packing tool, `godot/tools/make_scoot_sheet.gd`. It must verify each output cell against its source pixel for pixel. Commit the tool, sheet and `.import` file. Match the source PNG's import `[params]`, including lossless compression, mipmaps and alpha border handling. Keep the bottom-centre anchor at canvas (512, 812), scale 0.106 and the existing texture filter.

The cycle has **two cells over 14 timeline frames at 60 fps**. Set `Animation.step = 1/60` s, `Animation.LOOP_LINEAR` and `Animation.UPDATE_DISCRETE`. Key cell 0 at 0 and cell 1 at 7/60 s, with length 14/60 s. Hold A on frames 0–6 and B on 7–13. The gap from the last key to the end is one key interval (7/60 s), with no duplicate key at the wrap. On entry or re-entry, sync playback to `(tick % 14) / 60` s. A/B changes inside SCOOT never restart the clip.

## Landing reference and phase table

The existing 60 fps `landing-r0` gameplay capture shows the last FALL drawing at frame 291, the first squashed LAND at 292, the last LAND at 299, and upright again at 300. Those are eight rendered LAND frames. The baseline pins will verify the physics timing. The new clip keeps the existing eight-tick window. Set `Animation.step = 1/60` s, `Animation.LOOP_NONE`, and length 8/60 s.

| Phase | Frames at 60 fps | What the player may do | What gameplay reads |
| --- | --- | --- | --- |
| Startup | 0–1 | Move or make an eligible hop under the existing rules. | Physics sets `just_landed` at contact on frame 0. The session reads that flag in its physics update. The existing LAND rule selects the 52 × 44 px box. |
| Active | 2–3 | Keep moving or interrupt with an eligible hop. | The pose code uses `land_ticks`; physics uses the low box. There is no new gameplay window. |
| Recovery | 4–7 | Keep moving or interrupt with an eligible hop. | The low box persists while LAND is selected. At tick 8, the existing pose rule takes over. In the stationary reference it returns to IDLE and the 52 × 58 px box. |

## Rig design

Cut both pieces from `godot/assets/art/CHAR-IDLE.png` (SHA-256 `2b5ef1aad00cddb51ca6b155bd9a14c343f0b923e0a00c356107c3d56fc08099`). Leave the PNG intact. The upper piece uses rows 0–621, including the whole face. The lower uses rows 622–1023, including the dark band and feet. Rows 609–648 are uninterrupted body colour across the measured interior (x 240–784).

Use `centered = false`, local position `(0, 0)` and `scale = Vector2(0.106, 0.106)` and `texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` on all three Sprite2D nodes, matching the original pose sprite. The pivots and parents have unit scale at rest, except for the facing mirror. Pivot positions are in game pixels.

- `ScootSprite`: `offset = Vector2(-512, -812)` on each sheet cell.
- `UpperSprite`: `region_enabled = true`, `region_rect = Rect2(0, 0, 1024, 622)`, `offset = Vector2(-512, -622)`.
- `LowerSprite`: `region_enabled = true`, `region_rect = Rect2(0, 622, 1024, 402)`, `offset = Vector2(-512, -190)`.

`LowerPivot` stays at `(0, 0)` and `UpperPivot` rests at `(0, -20.14)`. At each key, `UpperPivot.position.y = -20.14 * LowerPivot.scale.y`. Use the same width scale and centre line for both pieces and matching easing on all three rig tracks. No rotation, lag or overshoot.

`player.gd` sets the full `FacingPivot` mirror transform: X basis `(facing, 0)`, Y basis `(0, 1)`, origin `(0, 0)`, with `facing` either +1 or -1. Keep the original sprite's `flip_h`. Set starting values in the scene; use no `RESET` clip.

| Frame | Time (s) | Width scale, both pieces | Lower height scale | Upper height scale | Upper pivot y (game px) | Outgoing transition |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 0, impact | 0 | 1.05 | 0.85 | 0.90 | −17.119 | 2.0, ease in |
| 2, deepest squash | 2/60 | 1.15 | 0.60 | 0.73 | −12.084 | 1.0, hold with identical endpoints |
| 4, start recovery | 4/60 | 1.15 | 0.60 | 0.73 | −12.084 | 0.5, ease out |
| 8, rest | 8/60 | 1.00 | 1.00 | 1.00 | −20.140 | End |

Use continuous value tracks with linear interpolation and the per-key transitions above. The deepest squash should be about 44 game px tall. At frame 6, I expect width 1.0375, lower height scale 0.90, upper height scale 0.9325, and upper pivot y about −18.13 game px. The frame-8 key defines exact IDLE rest; the live pose selector hands off at tick 8.

## Scene, authority and states

Use `godot/features/player/player_visuals.tscn`, rooted at `PlayerVisuals` (Node2D). Put `AnimationPlayer` beside `FacingPivot`, with `Scoot` and `LandRig` under `FacingPivot`. The three Sprite2D nodes are `Scoot/ScootSprite`, `LandRig/LowerPivot/LowerSprite` and `LandRig/UpperPivot/UpperSprite`. Use one embedded AnimationLibrary referencing `godot/animations/scoot.tres` and `godot/animations/land.tres`. Author the keys in the saved resources. Set `root_node = ".."` on the AnimationPlayer.

| Track relative to `PlayerVisuals` | Update mode |
| --- | --- |
| `FacingPivot/Scoot/ScootSprite:frame` | Discrete |
| `FacingPivot/LandRig/LowerPivot:scale` | Continuous |
| `FacingPivot/LandRig/UpperPivot:position` | Continuous |
| `FacingPivot/LandRig/UpperPivot:scale` | Continuous |

Only the AnimationPlayer writes to the animated nodes. `player.gd` requests playback and controls facing and visibility through the parent pivots. The original pose sprite stays outside this scene and the new facing pivot. The player script still sets its `texture` and `flip_h` even while it is hidden. Keep `p.sprite` pointing to it and keep `p.textures["IDLE"]`; existing tests and the capture helper read them.

| Existing poses, in priority order | Visual and clip |
| --- | --- |
| SPLAT, RESPAWN, CELEBRATE | Original sprite; no clip |
| ANTIC, RISE, FALL | Original sprite; no clip |
| LAND when grounded with `land_ticks > 0` | Landing rig; `land` |
| SCOOT-A, SCOOT-B when grounded with `abs(velocity.x) > 8` and no higher pose | Scoot sprite; `scoot` |
| WORRY, BORED, IDLE | Original sprite; no clip |

Keep `choose_pose()` and its order and return values unchanged. On fresh touchdown, play LAND from frame 0 if LAND is selected. If LAND returns after an override while its countdown is still active, seek to `(8 − land_ticks) / 60` s. Movement alone does not end LAND. On any exit from LAND or SCOOT, stop the old clip. A hop, walk-off or session override can interrupt LAND. If the selected pose after LAND is SCOOT, start the loop at the current A/B phase. No AnimationTree, AnimatedSprite2D or method tracks.

### Jump interrupt predictions

Tick 0 is touchdown in the uninterrupted baseline. Use a separate replay per case, with a stationary hop onto the starting plate and no overrides. Send a fresh jump press through `Input.parse_input_event` before the designated physics tick reads it. `buffer_ticks` and `coyote_ticks` are both 6. The code evaluates jump eligibility before detecting the current tick's floor contact. The −1 and 0 cases are predicted to show LAND for one tick before the buffered hop. Verify the timing with the baseline pins.

| Boundary | One tick before | On the boundary | One tick after |
| --- | --- | --- | --- |
| 0, startup | −1: buffer; LAND at 0, ANTIC at 1 | 0: buffer; LAND at 0, ANTIC at 1 | 1: ANTIC at 1 |
| 2, active | 1: ANTIC at 1 | 2: ANTIC at 2 | 3: ANTIC at 3 |
| 4, recovery | 3: ANTIC at 3 | 4: ANTIC at 4 | 5: ANTIC at 5 |
| 8, end | 7: ANTIC at 7 | 8: ANTIC at 8 instead of IDLE | 9: IDLE at 8, then ANTIC at 9 |

## Clocks and boundaries

Set `callback_mode_process` to `AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS` ([Godot 4.7 reference](https://docs.godotengine.org/en/4.7/classes/class_animationmixer.html)). Confirm the callback and 60 physics ticks per second in the running project. Gameplay reads on physics too: the player sets `just_landed` and selects the box; the session handles the landing event. Neither clip keys a gameplay value.

The synced frame must show on the entry tick, without an extra advance. After the pose and animation have both updated, compare the displayed clip phase with the expected phase. Let SCOOT advance normally after entry, and compare it with the player tick modulo 14 across many wraps and re-entries. Expect zero ticks of difference. A single extra advance on entry would be a 1/60 s error.

Among existing gameplay files, change only the visual setup and pose-to-visual mapping in `player.gd`. Preserve the original pose selection, timing, movement, input, collision, pose-to-box rule, tuning, session, other objects, original PNGs, A5 shaders and A6 effects. Presentation reads gameplay state without writing it. The existing tests, their counts and the gameplay pins should be unchanged.

## Evidence and frame strips

| Rule | How to check it |
| --- | --- |
| Sheet and registration | The packing tool compares the cells against their sources. Compare import parameters. Read back dimensions, grid and frame keys in the range 0–1. Use the SCOOT strip to check the feet at the swap and wrap, facing both ways. |
| Clip resources | Read back both clips before wiring. Resolve every track, reject unexpected targets including `LowerPivot:position`, and check update modes, length, step, loop mode, key times, transforms, easing and the seam equation. Use a half-frame tolerance for saved key times. |
| State and timing | Check the mapping and clip names against the saved scene. Observe `current_animation` and log the tick, pose, `land_ticks`, expected and actual clip time, and visible scoot cell after both updates at 30, 60 and 144 render fps. Use the real game loop and `Input.parse_input_event`. |
| Gameplay and edges | Commit behavior pins before wiring. Capture the pin replay with collision overlays so the log can be checked against the screen. Re-run pins and the 14 baseline runs after wiring. Test the interrupt table, walk-off and overrides, including return to LAND while ticks remain. Check the protected paths in the diff. |
| Mutations and fresh import | In separate worktrees, break a track subname, disable SCOOT looping and key cell 2. Each must fail the corresponding check. In a fresh-cache worktree, import and read back both clips and the sheet. The valid native rig should still load. Record the actual results in `TEST-REPORT.md`. |
| Visual judgment | Watch at least five normal-speed SCOOT wraps, play the landing repeatedly and interrupt every phase. Check the seam, feet, distinct phases and IDLE hand-off on light and dark backgrounds. Write my first visual verdict before comparing other readings. Record the predicted revision and before/after strips and verdict in `TUNING.md`. |

Use `res://previews/land_preview.tscn` and `res://previews/scoot_preview.tscn`, both reusing the live visual scene. Render LAND in Movie Maker at 30 fps on the starting plate with the real table and room at 1280 × 720. Make a clean strip and a matching collision-overlay strip, both labelled as fixtures. Align the trigger so it is captured at rig frame 0, and confirm the capture index and boundaries with a frame log.

| Relative capture | What to check |
| --- | --- |
| Trigger − 1 | Airborne FALL before contact |
| Trigger | Frame 0: partial squash and planted feet |
| Trigger + 1 | Frame 2: deepest squash, about the height of the low box |
| Trigger + 2 | Frame 4: same squash, now beginning recovery |
| Trigger + 3 | Frame 6: eased rise, joined cut and fixed feet |
| Trigger + 4 | Tick 8: IDLE hand-off without a pop, seam or anchor shift |

Capture SCOOT at 60 fps to see each seven-tick swap. Keep `landing-r0` labelled as the existing 60 fps gameplay reference, separate from the fixtures.

## Predicted failures

1. A continuous scoot track could switch cells early, or a discrete rig could jump between key poses. The read-back checks the modes; the tick log and strip show the result.
2. A misspelled track could leave part of the rig frozen. Resolve every target and check that the broken-subname worktree fails.
3. A double advance on entry or later drift could desync the loop. Check the cell and clip time against the pose through re-entries and wraps at all three render rates.
4. The pieces could gap, overlap or show a filtering line even at rest. Check the seam equation at keys and inspect the moving silhouette and IDLE hand-off in the clean strip.
5. A capture one tick out of alignment could miss the 30 fps boundary frames. Check the trigger and sampled phases in the capture log.

## Seven handout answers

1. **Routes.** The Sprite2D read-back checks slicing, frame indices, discrete updates and timing; a SpriteFrames read-back would inspect its own frame and animation data. The native cutout rig read-back resolves real pivot properties and checks movement and easing; there are no imported bones.
2. **Continuous frame values.** Linear interpolation would evaluate numeric frame indices between the keys instead of holding the first cell. With adjacent indices 0 and 1 there is no third drawing, but integer rounding can make the switch happen before the intended key. Discrete updates give each cell its full seven-tick hold. With interpolation across the loop wrap, B can also switch back to A early.
3. **Step.** Both clips use 1/60 s. On a 1/30 s editing grid, snapped keys can only land on even frames of this timeline. LAND's keys at 2, 4 and 8 fit; SCOOT's swap at frame 7 does not.
4. **Authority.** The AnimationPlayer alone writes the new sprite frame and rig transforms. The player script writes the original sprite, facing and visibility parents, and requests playback. A script setting the animated frame or transforms, or a second animation node targeting them, would compete.
5. **Clocks.** Both clips and gameplay use physics ticks. Gameplay reads ground contact and the existing countdown, not a window in a clip. Expect zero logical disagreement; an extra advance on entry would show a 1/60 s error.
6. **Cycle seam.** The last key is at 7/60 s and the length is 14/60 s, one key interval apart. An extra hold on a duplicated cell at the wrap would make the shuffle hesitate.
7. **Fresh import.** This is a native rig. An imported clip's loop mode would belong in its per-animation import settings. Here it belongs in the saved clip. Verify both clips and the sheet from an empty import cache in a worktree.

---

## Revision 1 — 2026-11-16 (before wiring, after the Step 5 plan)

Version 1 above is unchanged. This revision adds one rule, records one Version 1 case as unreachable through real input, and adds one predicted failure. It follows the read-only Step 5 plan (`sessions/a7/session-5a.jsonl`).

### Pause: clips freeze with the game

Escape sets the session to PAUSED and disables the player (`session.gd` lines 248–252) without pausing the tree. While the player is disabled, `tick` and `land_ticks` stop changing (`player.gd` lines 97–99) and no override is set (`session.gd` line 392). So if the player pauses during LAND or SCOOT, the selected pose stays the same: LAND stays LAND and SCOOT stays SCOOT for the whole pause. An AnimationPlayer on the physics callback would keep advancing: the rig would finish its squash, or the scoot keep shuffling, while the game is frozen.

Rule: while the player is disabled and a clip is selected, `player.gd` pauses the AnimationPlayer. On the first enabled tick, the clip re-enters through the same synced entry as Version 1, with no extra advance: LAND at `(8 − land_ticks) / 60`, SCOOT at `(tick % 14) / 60`. Movement, input, collision and pose selection are unchanged; only what the visual layer shows during a pause changes.

Checked by: the per-tick state test pauses with Escape during LAND and during SCOOT, and checks that the selected pose stays the same, the clip time stays frozen while paused, and it resumes at the synced time. My eyes: the pause hold in play.

### LAND resume after an override: kept, but not reachable through real input

Version 1 says that if LAND returns after an override while its countdown is still active, the clip seeks to `(8 − land_ticks) / 60`. Every override (SPLAT, REFORM, WON) ends through `reset_at()`, which sets `land_ticks = 0` (`player.gd` line 78; `session.gd` lines 239 and 354). So LAND never returns after an override with ticks remaining. The rule stays in the code as a safeguard, but no real-input test can reach it. The same synced resume is exercised through pause, above. In the edge tests, the override-resume case is reported as "not reachable through real input", not as a pass.

### Predicted failure 6: the SCOOT swap tick and the float32 key

The second SCOOT key is stored as a 32-bit float: 0.116666667163 s, slightly above the exact 7/60 = 0.116666666667 s (`logs/test_a7_scoot_readback_60fps.log`, `KEYTIME`). A playback position that reaches exactly 7/60, whether by seeking to `(tick % 14) / 60` or by adding 1/60 seven times, sits about 5 × 10⁻¹⁰ s below the key. Unless the engine's discrete-key lookup tolerates that, the first SCOOT-B tick of every cycle would still show cell 0: a swap one tick late, with A held for 8 ticks and B for 6.

Checked by: the timing probe (supplemental) logs the displayed cell on the swap tick at 30, 60 and 144 fps, and the per-tick state test then checks the cell against the pose on every tick. If it happens, the agent stops and reports. The keys, the step and the cycle spec do not change without a further dated revision.

### Evidence split: one addition

| Rule | How to check it |
| --- | --- |
| Entry order and the swap tick (engine assumptions A1–A4 in the Step 5 plan) | `godot/tests/probe_a7_entry_order.gd`, supplemental and not counted. It plays its own instance of `player_visuals.tscn`, never the game's, at 30, 60 and 144 fps, before `player.gd` changes. |

---

## Revision 2 — 2026-11-16 (after wiring, after the hand-off probe)

Version 1 and Revision 1 are unchanged. This revision changes one entry: the direct LAND → SCOOT switch.

### Direct LAND → SCOOT switch seeks one tick earlier

The wired state test failed 132/5 at 30, 60 and 144 fps (74fe4b5): when LAND hands off to SCOOT in one tick, SCOOT showed one tick ahead. The hand-off probe (fd4d855; variants H0 `stop()`, H1 `stop(true)`, H2 no stop) showed the cause: when `play()` is called on an AnimationPlayer that is already playing a clip, its own physics update later in the same tick adds 1/60 s. Fresh entries (R1) do not get this extra advance.

Rule: on a direct LAND → SCOOT switch only (old clip `land`, new clip `scoot`, not a resume after a pause), `player.gd` keeps `stop()` and `play(&"scoot")` and seeks to `fposmod((tick % 14) / 60 − 1/60, scoot length)`. The AnimationPlayer's own update then lands exactly on `(tick % 14) / 60`. All other entries are unchanged: fresh entries, touchdowns (LAND from 0) and resumes (LAND at `(8 − land_ticks) / 60`, SCOOT at `(tick % 14) / 60`).

The resume exclusion was the agent's call, which I accepted: a paused AnimationPlayer is not playing, and fd4d855 measured the extra 1/60 only when it was. A pause during LAND followed by SCOOT on the first enabled tick therefore keeps the plain seek. No test covers that case; it is recorded as an untested edge.

Checked by: probe variant H3 (`godot/tests/probe_a7_entry_order.gd`; `logs/probe_a7_entry_order_{30,60,144}fps.log`; 5c0fb9a). For each phase k = 0..13, the switch tick and the 31 ticks after it, 448 ticks per rate: 0 time failures (circular distance within 1e-6 s) and 0 cell failures at all three rates. k = 0 reads 0 on the switch tick, and all 32 ticks expected at 7/60 per rate show cell 1. After the change: the state test reports 132/0 at 30, 60 and 144; pins 31/0 with PINDIGESTs identical to fe9a1f0; the 14 baseline runs and both read-backs are unchanged.

---

## Revision 3 — 2026-11-17 (Step 7, landing r1, kept)

Version 1 and Revisions 1 and 2 are unchanged. This revision changes the depth of the landing squash. It is a tuning change I chose after my r0 verdict in TUNING.md ("A7 — landing, r0"): the landing looked smooth, but the hold was easier to see frame by frame than at normal speed. I kept it after my r1 verdict ("A7 — landing, r1: my verdict").

### Deeper squash at frames 2 and 4

Lower height scale 0.60 → 0.55 at the keys at 2/60 and 4/60 s. Upper pivot y follows the seam rule: −20.14 × 0.55 = −11.077 game px. Key times (0, 2/60, 4/60, 8/60 s), transitions (2.0, 1.0, 0.5), widths (1.05, 1.15, 1.15, 1.00), upper height scales (0.90, 0.73, 0.73, 1.00) and the keys at 0 and 8/60 are unchanged. The 2/2/4 timing and the eight-tick window are unchanged.

| Frame | Time (s) | Width scale, both pieces | Lower height scale | Upper height scale | Upper pivot y (game px) | Outgoing transition |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 2, deepest squash | 2/60 | 1.15 | 0.55 | 0.73 | −11.077 | 1.0, hold with identical endpoints |
| 4, start recovery | 4/60 | 1.15 | 0.55 | 0.73 | −11.077 | 0.5, ease out |

At frame 6 I now expect width 1.0375, lower height scale 0.8875, upper height scale 0.9325 and upper pivot y about −17.874 game px. The deepest squash is about 43 game px tall (Version 1: about 44).

Checked by: `test_a7_land_readback.gd` at 60 (135/0; frame-6 sample 0.8875 and −17.874); state 132/0 and edges 397/0 at 30, 60 and 144; pins 31/0 with all PINDIGEST lines unchanged; scoot read-back 62/0; structure 29/0 (9ada865). My eyes: the r1 strip (`captures/land/r1/`) and the r0/r1 comparison at normal speed.
