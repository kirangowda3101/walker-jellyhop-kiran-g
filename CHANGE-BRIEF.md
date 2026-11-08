# CHANGE-BRIEF — Assignment 6: Particle Effects

Version 1 · 2026-11-07 · written before any Claude Code session for A6; drafted with Claude in chat from my decisions. Later revisions are added below as dated sections; this version is not rewritten. The Assignment 5 brief is kept unchanged in history at tag `a5`.

Engine: Godot 4.7.2.stable.official.ed1daf0bf. Renderer: Compatibility (`godot/project.godot`, `renderer/rendering_method="gl_compatibility"`). Viewport 1280 × 720, stretch mode `canvas_items`. Physics 60 ticks per second. All sizes below are game pixels at 1280 × 720. The jelly's standing box is 52 × 58 px, its landing box 52 × 44 px (`player.gd` `STANDING`, `LOW`).

Both effects are 2D. Both use `GPUParticles2D`. Neither uses a texture file: each particle texture is a `GradientTexture2D` defined inside its scene file.

---

## Effect A — Landing crumb puff

### The job

**What it tells the player:** the jelly has touched down. Jelly Hop has a fixed hop height, and a landing is when the next hop becomes possible and, on a plate, when the checkpoint moves. The puff marks that moment at the jelly's feet, on both sides, so the player's eye catches the landing even when it is looking ahead at the next fork's shadow.

**Event:** there is no signal. The event is the per-tick flag `player.just_landed`:
- set in `godot/features/player/player.gd` `_physics_process()` when the jelly is grounded and was not grounded on the previous tick (line 137); cleared at the start of the jelly's next tick (line 95);
- read in `godot/game/session.gd` `_physics_process()`, `State.PLAYING` branch, `if state == State.PLAYING and player.just_landed:` (line 372), the same branch that plays `SFX-LAND` (line 374).

So Effect A fires exactly when `SFX-LAND` plays. A respawn is not a landing (`reset_at()` sets `was_grounded = true`), and a landing into sauce is a splat, not a landing.

### The intent block

**Timing phases** (30 fps frame numbers, frame 0 = the landing tick):
1. **Impact** (frames 0–2, about 0–70 ms): crumbs appear at both edges of the jelly's base at full size and full brightness, while the jelly shows its LAND squash pose. The LAND pose carries frame 0; the crumbs must be visible by frame 2 at the latest.
2. **Kick** (frames 2–5, about 70–170 ms): the crumbs travel fast outward, sideways, reaching roughly one jelly width beyond each side, staying within about 6 px of the surface.
3. **Settle** (frames 5–12, about 170–400 ms): they slow almost to a stop, shrink and fade. All are gone by frame 12 (0.40 s), well before the next landing of a chained hop (0.63–0.67 s later).

**Contrast against the real background:** the puff must read on both surfaces it lands on: the **pale plates** (lightest) and the **dark wood table** in the bare gaps (darkest). Value contrast does it, not hue: each crumb has a **light cream core and a dark brown rim**. On the pale plate the dark rim carries the shape; on the dark table the light core does. Judged in the running game over plate 1 and over the bare table in gap 1, never over the editor's grey.

**Scale against the character:** each crumb is about 6–12 px across (one eighth to one quarter of the jelly's 52 px width). At its widest (frame 10) the puff spans about 2–3 jelly widths across and is never taller than about a fifth of the jelly (≈ 10 px). Judged in the running game at 1280 × 720.

**Change over life:** size holds for the first third of life, then shrinks to zero; colour shifts from cream-white toward a warm crumb tan; alpha fades to zero at the end. Not alpha alone.

**Variation:** each crumb gets its own start point along the base, outward push, lift, size, lifetime (± 25 %) and a small hue shift, so two landings in a row never look stamped.

**Layering:** one emitter (`LandPuff`), whose job is the whole puff. It is drawn **behind the jelly and in front of the plates** (`z_index = -1`; plates are −2, the jelly is 0), so crumbs born under the jelly appear from behind its edges, and the plate never covers them.

### The settings

Scene: `godot/effects/land_puff.tscn`. Root node `LandPuff`, type **`GPUParticles2D`**.

**Why GPU:** the project is on Compatibility, where `GPUParticles2D` runs its process step as a particles shader on the GPU; Step 6 needs a GPU node's `ParticleProcessMaterial` to convert; and this effect needs only features both node types share, so nothing is lost.

**Node (emission and draw)**

| Property | Value | Part |
|---|---|---|
| `emitting` | `false` in the scene file (the driver sets it on the landing tick) | emission |
| `amount` | `16` | emission |
| `one_shot` | `true` | emission |
| `explosiveness` | `1.0` (all 16 on the landing frame) | emission |
| `randomness` | `0.0` | emission |
| `lifetime` | `0.40` s | emission |
| `preprocess` | `0.0` (a burst must start at the event, not mid-life) | emission |
| `local_coords` | `false` | emission space |
| `texture` | `GradientTexture2D` sub-resource, 16 × 16, `fill = FILL_RADIAL`, `fill_from = (0.5, 0.5)`, `fill_to = (1.0, 0.5)`; gradient offsets `[0.0, 0.55, 0.8, 1.0]`, colours `[#FFF6EA α1, #F2DFC4 α1, #3A2A22 α1, #3A2A22 α0]` (light core, dark rim) | draw |
| `material` | none (default mix blend; no `CanvasItemMaterial`) | draw |
| `z_index` | `-1` | draw |
| `visibility_rect` | `Rect2(-120, -40, 240, 70)`, **set by hand; to be verified in play** (edge of screen, predicted failure 6) (the furthest crumb reaches about ±106 px and −6 to +8 px vertically) | draw / culling |

**`local_coords` off, why:** each puff is a separate instance added to the session, which never moves. With `local_coords` off, crumbs already emitted stay where they were in the world even if their emitter moved, which is what dust on a surface does.

**`ParticleProcessMaterial` (process)**

| Property | Value |
|---|---|
| `particle_flag_disable_z` | `true` |
| `emission_shape` | `EMISSION_SHAPE_RING` |
| `emission_ring_axis` | `Vector3(0, 1, 0)` (a ring lying flat in X–Z; with Z disabled it collapses onto a horizontal line at the jelly's feet) |
| `emission_ring_radius` | `24.0` |
| `emission_ring_inner_radius` | `18.0` |
| `emission_ring_height` | `0.0` |
| `direction` | `Vector3(0, -1, 0)` |
| `spread` | `30.0` |
| `initial_velocity_min` / `initial_velocity_max` | `30.0` / `60.0` (a small lift only) |
| `radial_accel_min` / `radial_accel_max` | `4000.0` / `6500.0` (the sideways kick, outward from the emitter's origin) |
| `radial_accel_curve` | `CurveTexture`: `1.0` at 0.0 → `0.0` at 0.2 of life (the push acts only in the first ~80 ms) |
| `gravity` | `Vector3(0, 300, 0)` |
| `damping_min` / `damping_max` | `600.0` / `600.0` |
| `lifetime_randomness` | `0.25` |
| `scale_min` / `scale_max` | `0.4` / `0.75` (6.4–12 px with the 16 px texture) |
| `scale_curve` | `CurveTexture`: `1.0` at 0.0, `1.0` at 0.35, `0.0` at 1.0 |
| `color_ramp` | `GradientTexture1D`: `(1, 1, 1, 1)` at 0.0; `(0.95, 0.88, 0.80, 0.9)` at 0.5; `(0.85, 0.72, 0.58, 0.0)` at 1.0 |
| `hue_variation_min` / `hue_variation_max` | `-0.03` / `0.03` |

### Observable rules

Ticks are physics ticks at 60 per second.

- **A1. Fires on every landing.** On every tick where `player.just_landed` is true and the session state is still `PLAYING` after `resolve_contacts()`, exactly one new `LandPuff` instance is added with `emitting = true`. The number of puffs spawned equals `sound.count("SFX-LAND")` at all times.
- **A2. Never otherwise.** No puff on scene load, during the intro, on respawn (`reset_at()`), on a landing into sauce (that tick is a splat), or while the session is `PAUSED`, `SPLAT`, `REFORM` or `WON`.
- **A3. At the event's place.** Each puff's `global_position` equals `player.global_position` on its landing tick (within 0.5 px): the bottom centre of the jelly's box, its feet.
- **A4. Retrigger rule: overlap.** Each landing gets its own new instance. A second landing inside the first puff's lifetime never restarts, cuts off or suppresses the first, whatever the first is doing at that moment: still emitting, or already done emitting (with `explosiveness = 1.0` all 16 crumbs are born on the landing frame, so `emitting` may already be `false`) while its crumbs are still alive. Both puffs' crumbs are alive together, and the second puff emits its full 16.
- **A5. Most bursts alive at once: 2 (prediction, until I test the plate-edge route in play).** The shortest gap between two landings should be a landing near a plate's edge followed by scooting off it: the plate top is 22 px above the table, a drop of about 0.15 s. A third landing needs a hop, at least 0.63 s later, after the first puff (0.40 s) is gone. Predicted peak: 2 × 16 = **32 particles**. If play shows a shorter route, I revise this rule and the price prediction with a dated revision.
- **A6. Cleanup.** Each instance frees itself after it finishes (its `finished` signal). One second after the last landing, no `LandPuff` instance is left in the tree. Prediction to check: a headless run uses a dummy renderer that runs no particle process, so `finished` may never fire there. If it doesn't, I record that, and each instance instead frees itself `lifetime + 0.1` s (0.5 s) after it starts, in the running game and headless alike.
- **A7. A freed follow target.** The puff is never parented to the jelly, and the jelly is never freed on a landing (a respawn teleports it). If the jelly were freed on the same tick, the puff would still finish, because its parent is the session.
- **A8. Paused.** Esc sets the session to `PAUSED` but does not pause the tree. A puff already alive finishes (at most 0.40 s), and no new one starts because no landing can happen with the jelly disabled. With `get_tree().paused = true` (not used by the game, set by the test), a live puff freezes in place.

### Evidence split

| Rule | Checked by | How |
|---|---|---|
| Every setting above | headless test | `test_land_puff_config.gd` loads the scene and reads each property back against these values |
| A1, A2 | headless test | drive real landings, a respawn and a sauce splat; compare puffs spawned with `sound.count("SFX-LAND")` |
| A3 | headless test | puff `global_position` vs `player.global_position` on the landing tick |
| A4, A5 | headless test + my eyes | test: two real landings 0.15–0.2 s apart (plate-edge scoot-off) create two separate `LandPuff` instances, both in the tree at once, the first not restarted (node state only; a headless run draws no crumbs); eyes: the crumbs of both puffs visibly overlap in play, including rapid repeats |
| A6 | headless test | count `LandPuff` instances 1 s after the last landing |
| A8 | headless test | tree pause: the instance stays in the tree, `emitting` unchanged |
| Timing phases, scale, contrast, change over life | frame strip + my eyes | strip frames below; my verdict in the running game at 1280 × 720 over plate 1 and the bare table in gap 1 |
| Variation | my eyes | ten or more landings in play, looking for stamped repeats |

### The frame strip

**Preview scene:** `godot/previews/land_puff_preview.tscn`, a **fixture**. Background: the real level art for the first stretch, the room behind, the table front, plate 1 and the bare table gap after it, at in-game camera scale. A still jelly sprite (`CHAR-LAND.png`) stands at each trigger point, so the crumbs are judged next to the real character.

- Frame 10: two puffs fire together, one on plate 1 (pale) and one on the bare table in gap 1 (dark).
- With the preview's `retrigger` export on, a third puff fires at frame 15 beside the table one, 5 frames (0.167 s) later, the scoot-off case.
- `use_fixed_seed` on, on the preview's instances only (never in `land_puff.tscn`), if 4.7 has it.

| Frame | After trigger | Should show |
|---|---|---|
| 10 | 0 | the trigger frame: crumbs at most just appearing at the jelly's base edges |
| 12 | +2 | crumbs clearly out from behind both sides of the jelly, full size, bright, low |
| 15 | +5 | a flat fan about one jelly width beyond each side, within ~6 px of the surface |
| 20 | +10 | crumbs nearly stopped, shrunk to under half size, mostly faded |
| 30 | +20 | nothing |
| 50 | +40 | nothing |

---

## Effect B — Dome sugar glints (ambience)

### The job

**What it tells the player:** where the goal is, and that it is the prize. Soft sugar glints rise from the dessert dome for the whole run. The intro pan starts on the dome, so the glints are the first thing the player sees move; later, when the dome comes onto screen at the right edge, the glints mark it before the player reaches it.

**Job:** ambience.

**Condition:** the run is not won: `session.state != State.WON` (`godot/game/session.gd`, `enum State` line 12). The glints are on from scene load (state `INTRO`) through `PLAYING`, `PAUSED`, `SPLAT` and `REFORM`. They stop when the state becomes `WON` (`resolve_contacts()`, the jelly reached the dome) and start again when `start_session()` replays from `WON`.

**The feature Effect A doesn't use:** a **box emission shape** (`EMISSION_SHAPE_BOX`) across the dome's glass. Effect B also uses `preprocess` and an additive `CanvasItemMaterial`, which Effect A doesn't, but the box is the named feature.

### The intent block

**Timing phases** (ambience, so phases of the effect's life, not of one burst):
1. **Start:** on the first frame after the scene loads, the dome is already glinting at its steady-state density (preprocess). No fill-in.
2. **Steady state:** about 24 glints alive. Each fades in over about 0.5 s, drifts slowly upward 50–80 px over its 2.4 s life, turns from sugar white toward pale gold, and fades out. No pulsing, no bursts.
3. **Stop:** at `WON`, no new glints are born; the ones alive keep rising and fade out naturally. The dome is empty about 2.4 s after the win.

**Contrast against the real background:** the glints rise from the dome's glass into the **dark room** behind it (darkest), and the additive glow reads strongly there. Over the dome's **pale glass highlights** (lightest) an additive glint can wash out; that is acceptable only if each glint clears the glass into the dark room within about a third of its life. Judged in the running game over both.

**Scale against the character:** each glint is about 4–9 px across, smaller than the landing crumbs and far smaller than the jelly (about a tenth of its width). The whole cloud is about as wide as the dome (≈ 180 px, 3.5 jelly widths) and rises up to about 80 px above it.

**Change over life:** size grows from zero over the first fifth of life and shrinks to zero over the last fifth; alpha fades in and out with it; colour shifts from sugar white to pale gold.

**Variation:** start position anywhere in the box, rise speed, size, lifetime (± 30 %) and a small hue shift.

**Layering:** one emitter (`DomeGlints`) whose job is the whole effect. Drawn in front of the dome glass (`z_index = 6`; the dome is 5).

### The settings

Scene: `godot/effects/dome_glints.tscn`. Root node `DomeGlints`, type **`GPUParticles2D`**, for the same reasons as Effect A. The driver places it at `(dome centre x, TABLE_TOP − 70)`.

**Node (emission and draw)**

| Property | Value | Part |
|---|---|---|
| `emitting` | `true` in the scene file (on from load) | emission |
| `amount` | `24` | emission |
| `one_shot` | `false` | emission |
| `explosiveness` | `0.0` | emission |
| `randomness` | `0.0` | emission |
| `lifetime` | `2.4` s | emission |
| `preprocess` | `2.4` s (one full lifetime, so the first frame is at steady state) | emission |
| `local_coords` | `false` (the dome never moves; glints drift in world space) | emission space |
| `texture` | `GradientTexture2D` sub-resource, 32 × 32, `fill = FILL_RADIAL`, `fill_from = (0.5, 0.5)`, `fill_to = (1.0, 0.5)`; gradient offsets `[0.0, 0.35, 1.0]`, colours `[white α1, white α0.6, white α0]` | draw |
| `material` | `CanvasItemMaterial`, `blend_mode = BLEND_MODE_ADD` | draw |
| `z_index` | `6` | draw |
| `visibility_rect` | `Rect2(-110, -160, 220, 220)`, **set by hand; to be verified in play** (edge of screen, predicted failure 6) (box ±70 × ±45 plus up to 80 px of rise) | draw / culling |

**`ParticleProcessMaterial` (process)**

| Property | Value |
|---|---|
| `particle_flag_disable_z` | `true` |
| `emission_shape` | `EMISSION_SHAPE_BOX` |
| `emission_box_extents` | `Vector3(70, 45, 0)` |
| `direction` | `Vector3(0, -1, 0)` |
| `spread` | `20.0` |
| `initial_velocity_min` / `initial_velocity_max` | `12.0` / `30.0` |
| `gravity` | `Vector3(0, -6, 0)` (a slight upward drift) |
| `damping_min` / `damping_max` | `0.0` / `0.0` |
| `lifetime_randomness` | `0.3` |
| `scale_min` / `scale_max` | `0.13` / `0.28` (4–9 px with the 32 px texture) |
| `scale_curve` | `CurveTexture`: `0.0` at 0.0, `1.0` at 0.2, `1.0` at 0.8, `0.0` at 1.0 |
| `color_ramp` | `GradientTexture1D`: `(1.0, 0.95, 0.82, 0.0)` at 0.0; `(1.0, 0.95, 0.82, 0.85)` at 0.2; `(1.0, 0.82, 0.55, 0.6)` at 0.75; `(1.0, 0.82, 0.55, 0.0)` at 1.0 |
| `hue_variation_min` / `hue_variation_max` | `-0.05` / `0.05` |

### Observable rules

- **B1. On from load.** On the first frame after the session is ready, `DomeGlints` exists, `emitting == true`, and it sits at the dome position above.
- **B2. Stops at the win.** On the tick the state becomes `WON`, `emitting` becomes `false`. The node stays in the tree so live glints finish.
- **B3. Starts again on replay.** On the tick `start_session()` moves the state from `WON` to `PLAYING`, `emitting` becomes `true` again (by `restart()`, so preprocess applies again; prediction to check).
- **B4. Session pause (Esc).** No change: `emitting` stays `true` and the glints keep drifting, like the rest of the room. The game's pause does not pause the tree.
- **B5. Tree pause.** With `get_tree().paused = true`, the glints freeze in place and `emitting` stays `true`; they continue from the same state when unpaused.
- **B6. Hidden.** With `visible = false`, nothing is drawn and `emitting` stays `true`; the driver never changes `visible`. Prediction to observe: when shown again, the glints are present rather than refilling from empty.
- **B7. One instance.** Exactly one `DomeGlints` exists for the whole session, including after replays.

### Evidence split

| Rule | Checked by | How |
|---|---|---|
| Every setting above, including the box | headless test | `test_dome_glints_config.gd` reads each property back |
| B1, B2, B3, B7 | headless test | drive a real run to the dome with real input, then a replay; read `emitting` and the instance count each tick |
| B4, B5, B6 | headless test | Esc through the real input path; `get_tree().paused`; `visible = false`; read `emitting` |
| Start with no fill-in (preprocess) | frame strip + my eyes | strip frame 10; the first frames of the intro in the running game |
| Look, contrast, scale | frame strip + my eyes | strip frames below; running game over the dark room and the pale glass |
| B6's "present when shown again" | my eyes | toggle visibility in the running game's remote tree |

### The frame strip

**Preview scene:** `godot/previews/dome_glints_preview.tscn`, a **fixture**: the room, the table, the dome at in-game camera scale, the jelly sprite beside it for scale. The glints instance has `emitting = false` until frame 10, when the preview calls `restart()`; at frame 70 it sets `emitting = false`. Capture with `--quit-after 150`.

| Frame | Should show |
|---|---|
| 10 | start: steady-state density already (preprocess on restart) |
| 12 | the same density, glints drifting up |
| 40 | steady state, 1 s in: about 24 glints, mostly above the glass |
| 70 | the stop frame: still full |
| 85 | 0.5 s after stop: fewer near the glass, the upper ones still rising |
| 145 | 2.5 s after stop: empty |

---

## Boundaries (both effects)

These stay unchanged: collision, movement, input, the state machine and its timings in `session.gd`, every value in `slice_tuning.gd` and `features/player/tuning.gd`, `fork.gd`, `godot/audio/`, the HUD, every existing test and its expected counts, my Assignment 5 shaders in `godot/shaders/`, `godot/materials/`, the showcase scenes, and all source art.

**Trigger code:** a new presentation script, `godot/effects/effects_driver.gd`, runs after the session each physics tick (`process_physics_priority` higher than the session's 10). It reads `state`, `player.just_landed` and `player.global_position`, instances `LandPuff` on a landing, owns the one `DomeGlints` and sets its `emitting`. **It never writes game state.** The only change allowed in `session.gd` is one line in `_ready()` that adds the driver as a child; the agent proposes it in the Step 3 plan and I approve or reject it. Effect settings live in the scene files in `godot/effects/`, never in code.

---

## Predicted failures

1. **Godot 3 names.** The agent writes `initial_velocity`, `scale`, `scale_random` or `ParticlesMaterial`; the scene loads, the settings stay at defaults, the puff fires and looks wrong. *Caught by:* the configuration tests, and the Godot 3 name mutation in Step 2.
2. **The flat ring doesn't flatten.** If Z is not zeroed at spawn, the ring with axis Y does not collapse onto a line and radial acceleration starts with a Z component, so the puff starts as a tall cloud or kicks weakly. *Caught by:* strip frames 12 and 15 (crumbs above ~10 px, or still behind the jelly).
3. **Crumbs stuck behind the jelly.** The ring radius (18–24 px) is inside the jelly's half-width (26 px); if the push is too weak, frame 12 shows nothing. *Caught by:* strip frame 12, and my eyes in play.
4. **Additive glints wash out over the pale glass, or vanish.** *Caught by:* strip frame 40 and my eyes over the glass and the room.
5. **Preprocess not applied on restart.** After a win and a replay, the dome refills from empty instead of starting full. *Caught by:* strip frame 10 (the preview uses `restart()`), and my eyes on a replay.
6. **Visibility rect too small.** The dome glints pop out when the dome is at the right edge of the screen during the approach. *Caught by:* my eyes, walking the jelly so the dome sits at the screen edge.
7. **Puffs never freed.** Instances pile up in the tree. *Caught by:* the A6 count in the state test.
8. **A puff on respawn or on a sauce splat.** *Caught by:* A2 in the state test (puffs vs `sound.count("SFX-LAND")`).
9. **No GPU time on this renderer.** The Visual Profiler's GPU time may be missing or zero under Compatibility on macOS. *Caught by:* opening the Visual Profiler before building anything heavy; if it fails, I record that and price on what can be measured, saying so.

## Price predictions and budgets

| | Effect A (land puff) | Effect B (dome glints) |
|---|---|---|
| Node | `GPUParticles2D` | `GPUParticles2D` |
| Peak particle count | 32 (2 bursts × 16), predicted (A5) | 24 |
| Predicted headless CPU price | within the game-with-effects-off case's spread (< 0.02 ms added): the dummy renderer runs no particle process shader; the only CPU work is instancing and freeing a scene per landing | within the effects-off spread (< 0.01 ms added) |
| Predicted GPU time | < 0.05 ms at peak | < 0.05 ms |
| **Budget** | **0.25 ms GPU time at peak**, compared on GPU time | **0.25 ms GPU time**, compared on GPU time |

Both are GPU nodes, so both are compared on GPU time: their headless CPU price is near zero by construction.

## Answers

1. **Node types and missing features.** Both effects use `GPUParticles2D`. On Compatibility, 2D particle collision depends on a signed-distance field that this renderer does not provide, and I am not using collision, trails, turbulence, attractors or sub-emitters. Every feature in this brief (ring and box emission, radial acceleration with a curve, gravity, damping, scale and colour curves, hue variation, preprocess, an additive `CanvasItemMaterial`) is expected to exist on `GPUParticles2D` in 4.7; I will confirm each in the 4.7 class reference, and Step 1's CLAUDE.md lists any it cannot confirm.
2. **`local_coords` off and a moving parent.** Crumbs already emitted stay where they are in the world; only new particles would follow the emitter. The puff's parent is the session, which never moves, so in practice nothing follows anything.
3. **Bursts alive at once.** Under overlap, at most 2 (A5), so the peak is 32 particles. Both numbers are predictions until I have played the plate-edge route.
4. **Headless price of a GPU effect, and FPS with vsync.** Near zero: a headless run uses a dummy renderer that never runs the particle process shader or draws anything, so the GPU's work is never done and cannot be timed. With vsync on, FPS reads the display's refresh rate with the effect off and on alike (60, or 120 on a ProMotion display) until a frame misses, so it hides the cost.
5. **Effect B at scene load, paused and hidden.** With preprocess: steady-state density on the first frame. Without: empty, filling over 2.4 s, on every load. Tree paused: frozen, `emitting` still `true`. Session paused (Esc): keeps drifting. Hidden: not drawn, `emitting` still `true`.
6. **Emission, process, draw.**
   - Emission: `emitting`, `amount`, `one_shot`, `explosiveness`, `randomness`, `lifetime`, `preprocess`, `local_coords`, and the emission shape and its parameters (ring, box).
   - Process: `direction`, `spread`, initial velocity, radial acceleration and its curve, `gravity`, damping, `lifetime_randomness`, scale range and curve, colour ramp, hue variation, `particle_flag_disable_z`.
   - Draw: `texture`, `material` (blend mode), `z_index`, `visibility_rect`.

---

## Revision 1 — 2026-11-07 (Effect A, tuning r1)

Version 1 above is unchanged. This revision supersedes one Effect A setting.

| Setting | Version 1 | Revision 1 |
|---|---|---|
| `radial_accel_curve` (`CurveTexture`) | `1.0` at 0.0 → `0.0` at 0.2 of life | `1.0` at 0.0, `1.0` at 0.18, `0.0` at 0.2 of life, linear |

`radial_accel_min` / `radial_accel_max` stay at `4000.0` / `6500.0`. The push now stays at full strength until 0.18 of life and ends by 0.2, instead of fading from the start.

Why: in strip r0 and the preview, most crumbs were still under the jelly at frame 15, with no sideways fan. Kept after strip r1 and my check in the running game at 1280 × 720 (TUNING.md, Effect A, revision r1). The configuration test's expected curve points match this revision.

This is the last tuning revision for Effect A.

---

## Revision 2 — 2026-11-07 (Effect B, tuning r1)

Version 1 and Revision 1 above are unchanged. This revision supersedes one Effect B setting and the fade-in part of Effect B's intent.

| Setting | Version 1 | Revision 2 |
|---|---|---|
| `color_ramp` (`GradientTexture1D`, `Gradient_life`) offsets | `0.0`, `0.2`, `0.75`, `1.0` | `0.0`, `0.08`, `0.75`, `1.0` |

The four ramp colours are unchanged. The scale curve is unchanged.

Intent, revised: each glint now reaches its peak ramp alpha of 0.85 at 8% of its lifetime (about 0.13 to 0.19 s), instead of fading in over about 0.5 s. The scale curve is unchanged, so each glint still grows in size over the first fifth of its life and shrinks over the last fifth; its alpha fades out over the last quarter.

Why: kept after strip r1 and my check in the running game at 1280 × 720, where the glints were noticeably easier to see in the intro (TUNING.md, Effect B, revision r1).

Still not met: the frame-85 row of the strip table ("fewer near the glass"). Neither r0 nor r1 shows clearer thinning from frame 70 to frame 85. The configuration test's expected ramp offsets match this revision.
