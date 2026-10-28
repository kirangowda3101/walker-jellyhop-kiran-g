# CHANGE-BRIEF — Assignment 5: Shaders, Materials, and the Godot Shading Language

Version 1 · 2026-10-27 · written before shader implementation and before any Claude Code session; drafted with Claude in chat from my decisions. Later revisions are added below as dated sections; this version is not rewritten.

Earlier contracts (A2 asset slice, A3 3D assets) are archived at `archive/CHANGE-BRIEF-A2-A3.md`. Code comments and documents written before A5 that cite "CHANGE-BRIEF.md" mean that archived file.

Renderer: Compatibility (`godot/project.godot` line 32, `renderer/rendering_method="gl_compatibility"`). HDR 2D is off (no `rendering/viewport/hdr_2d` line). Physics: default 60 ticks per second.

## 1. The state

**What the effect communicates:** a fork is in its SHADOW phase, the window when its shadow grows on the plate before it strikes. During SHADOW the fork's steel gradually turns toward candle amber (#FFB347), in step with the shadow, so the amount of amber tells the player how much time is left before the strike.

**Why the player needs it:** reading the shadow is the core skill (GDD pillar "Read the shadow, then commit"). The shadow is on the plate; the glow adds the same timing cue on the fork itself, in the colour the GDD palette reserves for warnings, so the warning is readable wherever the player is looking.

**Where the state lives:**
- `godot/features/fork/fork.gd`: `enum Phase { SAFE, SHADOW, DOWN, HOLD, UP }` (line 9); the current phase is `phase()`, computed from the tick counter `t`, `safe_ticks` and `shadow_ticks`.
- Forks advance one tick per physics tick in `godot/game/session.gd` `_physics_process()` → `_advance_forks()`, only while the session state is PLAYING, SPLAT or REFORM. INTRO, PAUSED and WON freeze them.
- SHADOW lengths per fork, from `godot/game/slice_tuning.gd` `FORK_CYCLES` (lines 42–48): 1.6, 1.4, 1.3, 1.2 and 1.0 s at `Engine.time_scale = 1.0`. The two forks that start off screen begin halfway through SHADOW.
- Each fork draws its own `Sprite2D` (`ENV-FORK.png`), created in `fork.gd` `setup()`. That sprite is the object the shader changes.

## 2. Effect specification

**Shader:** `godot/shaders/fork_warning.gdshader`, to be hand-written by me.
- `shader_type canvas_item;`
- `render_mode unshaded;` so 2D lights never change the result, and the colour depends only on the texture, the uniforms and the arithmetic below.
- No sampler uniforms. The fork's own sprite texture arrives in `COLOR`.

**Material:** each fork gets its own `ShaderMaterial` instance that uses this one shader, so each fork holds its own `warning` value.

| Uniform | Type | Hint | Default | Set by |
|---|---|---|---|---|
| `warning` | `float` | `hint_range(0.0, 1.0)` | `0.0` | The driver, every physics tick, from that fork's phase (Section 3) |
| `warn_color` | `vec4` | `source_color` | `vec4(1.0, 0.702, 0.278, 1.0)` (#FFB347) | Nobody at runtime; fixed default |
| `strength` | `float` | `hint_range(0.0, 1.0)` | `0.65` | Nobody at runtime; tuned in the Inspector |

**The colour line** (inside `fragment()`):

```glsl
COLOR.rgb = mix(COLOR.rgb, warn_color.rgb, warning * strength);
```

Only `.rgb` changes. `COLOR.a` is untouched, so the fork's transparent pixels stay transparent and its silhouette never changes.

**What `warning` is:** during SHADOW, `warning` equals the fork's own shadow growth, `(p − safe_ticks + 1) / shadow_ticks`, the same value `fork.gd` `shadow_amount()` returns in SHADOW. In every other phase, and whenever the fork is held, `warning` is `0.0`.

## 3. Observable rules

Ticks are physics ticks at 60 per second; `slice_tuning.gd` `ticks(s) = int(round(s * 60.0))` (lines 116–117). SHADOW lengths: 96, 84, 78, 72 and 60 ticks.

1. **Begin and end values.** In SAFE, `warning` is `0.0`. On the first SHADOW tick it is `1 / shadow_ticks` (for example `1/96 = 0.0104` for the 1.6 s fork). It rises by `1 / shadow_ticks` per tick and is exactly `1.0` on the last SHADOW tick. On the first DOWN tick it is `0.0` again: no fade-out. These exact values hold per physics tick. A per-frame sample cannot always see them: at 30 fps each frame spans two ticks, so a frame may never show `1 / shadow_ticks` or exactly `1.0`; at 144 fps some frames contain no tick and repeat the previous value.
2. **Duration.** The ramp lasts `shadow_ticks` physics ticks: 1.6, 1.4, 1.3, 1.2 or 1.0 s of game time at `Engine.time_scale = 1.0`, with a tolerance of one frame period (33.3 ms at 30 fps, 16.7 ms at 60, 6.9 ms at 144). It takes the same game time at 30, 60 and 144 fps, because it is computed from the fork's tick counter, never from frames rendered.
3. **Retrigger.** In the normal cycle SHADOW cannot begin again while it is running. A new SHADOW always **restarts** the ramp from `1 / shadow_ticks`; it never continues an earlier partial ramp.
4. **Starting mid-state.** After `reset_cycle()` the value comes from the fork's starting `t`. The plate 5 and plate 6 forks begin mid-SHADOW at `37/72 = 0.514` and `31/60 = 0.517`, and hold those values while the intro pan freezes them.
5. **Time scale and pause.** Prediction, to be checked by a test: in Godot 4, `Engine.time_scale` scales `delta` but not the number of physics ticks per second. Since the ramp counts ticks, it lasts the same tick count, and the same real time, under any time scale. Measured in scaled game time it is then shorter: 0.8 s for the 1.6 s fork at `time_scale = 0.5`. While the session is PAUSED, INTRO or WON, or while the tree is paused, forks do not advance, so `warning` holds its last value.
6. **State ends early.** If a fork is held during SHADOW (`hold_raised()` on respawn sets `t = 0`), `warning` is `0.0` on that same tick. `restart_at_safe()` also gives `0.0`.
7. **Several instances.** Each of the five forks has its own `ShaderMaterial`, all using the same `Shader` resource. A fork's `warning` depends only on its own phase: while one fork is in SHADOW, a fork in SAFE reads `0.0`.

## 4. Boundaries

These stay unchanged:
- Collision, movement and input: the jelly, the fork hit areas (traced from `ENV-FORK.png` alpha in `fork.gd` `tine_outlines()`), plates and sauce.
- The session state machine and the fork cycle: `session.gd`, the phase logic in `fork.gd`, and every timing in `slice_tuning.gd`.
- Sound and music behaviour.
- Every other object's look: the jelly, plates, sauce, the code-drawn shadow ellipse, the background and the HUD.
- The existing tests and their expectations: `test_game.gd` 25, `test_slice.gd` 61, `test_keyboard.gd` 12, `test_a3_assets.gd` 36 checks, all passing at 60 fps before A5.
- Source art and models: `ENV-FORK.png` and the A3 `.glb` files.

Presentation code may **read** a fork's phase and tick counter. It never **writes** `t`, `held`, `hold_pending`, `announced` or any session state.

Files in `godot/shaders/` are hand-written by me. No agent edits them.

## 5. Evidence split

| Rule | Checked by | How |
|---|---|---|
| Shader parses; uniform names and types | Headless | `get_shader_uniform_list()` on the shader lists `warning`, `warn_color` and `strength` with their types; defaults read from the shader source text |
| 1 Begin and end values (exact, per tick) | Headless | A sampler in `_physics_process` with a high `process_physics_priority`, so it runs after the session advances the forks, reads every fork's `warning` every physics tick and compares it with `(p − safe_ticks + 1) / shadow_ticks` in SHADOW and `0.0` elsewhere. The per-tick sequence must be identical at 30, 60 and 144 fps |
| 2 Duration at 30, 60, 144 fps (per frame) | Headless | A sampler in `_process` with a high `process_priority`, so it reads after every other `_process()`, records `warning` every rendered frame with `--fixed-fps` 30, 60 and 144; game time from the first frame with `warning > 0` to the first frame back at `0.0` equals the SHADOW length within one frame period. Exact first and last values are not expected per frame at 30 or 144 fps |
| 3 Retrigger restarts | Headless | Drive a splat through the real game loop and real input so a fork is held and released; its next SHADOW starts at `1 / shadow_ticks` |
| 4 Starting mid-state | Headless | On the first frame after start, the plate 5 and 6 forks read `0.514` and `0.517`, unchanged through the intro pan |
| 5 Time scale | Headless | Ramp tick count with `Engine.time_scale = 0.5` equals the count at `1.0` |
| 5 Pause | Headless | Pause mid-SHADOW; `warning` holds the same value for every sampled frame until resume |
| 6 State ends early | Headless | A fork held mid-SHADOW reads `0.0` on that tick |
| 7 Several instances | Headless | The five materials are distinct objects with the same `shader`; a SAFE fork reads `0.0` while another is in SHADOW |
| Colour on screen matches the predicted pixels | **My eyes** | In-engine captures at controlled values, sampled pixels beside the predicted table (Section 6) |
| Glow readable in play; fork still reads as a fork | **My eyes** | Normal play, several warnings, on the real background |
| Silhouette and every other object unchanged | **My eyes** | Side-by-side captures, glow on and off |
| Intro pan shows plate 5 and 6 forks half-amber | **My eyes** | Watch the pan in a windowed run |

## 6. Controlled inputs and predicted values

**Controlled values:** `warning` = 0.0, 0.5 and 1.0, with `strength` at its default 0.65, so the mix amount `warning * strength` is 0.0, 0.325 and 0.65. `warn_color` = (255, 179, 71).

**Named pixels** (fully opaque, in flat areas of `ENV-FORK.png`, 335 × 1267):
- **P1, light steel:** art pixel (168, 300) = (179, 188, 187). Every channel within 2 across a 13 × 13 box.
- **P2, mid steel:** art pixel (298, 850) = (113, 126, 128). Every channel within 8 across a 13 × 13 box.

The sprite is drawn at scale `200 / (326 − 9) = 0.631` (`slice_tuning.gd` lines 24–25, 104–105), so a 13 × 13 art box covers about 8 × 8 screen pixels. Screen position of an art pixel = the fork node's position + (art − (167.5, 1258)) × 0.631 (`fork.gd` sprite offset).

**Predictions** (each channel = pixel + amount × (amber − pixel), rounded to 8 bits):

| Pixel | `warning` 0.0 | 0.5 | 1.0 |
|---|---|---|---|
| P1 (179, 188, 187) | (179, 188, 187) | (204, 185, 149) | (228, 182, 112) |
| P2 (113, 126, 128) | (113, 126, 128) | (159, 143, 109) | (205, 160, 91) |

**Background:** both pixels are opaque and the colour line never changes alpha, so the background does not enter the arithmetic.

**Lighting:** `render_mode unshaded`, so no 2D light changes the result. HDR 2D is off, so the mix happens on the values as written. Prediction: `source_color` on `warn_color` does not convert it in a non-HDR 2D canvas. The captures check this.

**Contrast:** against the palette room colour #1A1420, P1's contrast ratio goes from about 9.3:1 at 0.0 to about 9.6:1 at 1.0. The effect is a hue shift, not a brightness change. I will re-measure against the real room pixel behind the fork in the captures.

## 7. Material plan

**Object:** the A3 `Floor` (a `BoxMesh`, `godot/showcase/a3_assets.tscn` lines 23–25) as the dinner table, plus a second `BoxMesh` serving board beside it. Both live in a new scene, `godot/showcase/a5_materials.tscn`, which instances `a3_assets.tscn` instead of editing it, so `test_a3_assets.gd` (36 checks) stays unchanged. A `BoxMesh` always has clean UVs and tangents; the A3 `.glb` models have UVs but no tangents.

**Lighting I judge under:** the A3 `Sun` (`DirectionalLight3D`, `a3_assets.tscn` line 39) as committed. SSAO, SSR, SDFGI and VoxelGI are not available in the Compatibility renderer, so none of them can be confused with a roughness or normal-map change.

**Textures:** Poly Haven "Dark Wood", https://polyhaven.com/a/dark_wood, CC0. Authors: Dario Barresi (baking), Dimitrios Savva (photography), Rico Cilliers (tiling). Checked 2026-10-27. 2K PNG, 2048 × 2048 RGB, in `godot/assets/textures/dark_wood/`. Normal convention used: **OpenGL (`_nor_gl`)**, which Godot expects. `_nor_dx` is kept only to calibrate the curl check.

| File | Role | What its numbers mean | Sampled as | `compress/mode` | `compress/normal_map` | `mipmaps/generate` |
|---|---|---|---|---|---|---|
| `dark_wood_diff_2k.png` | albedo | sRGB-encoded colour | colour, `source_color` | Lossless | Disabled | on |
| `dark_wood_rough_2k.png` | roughness | 0 = mirror, 1 = fully rough; grey stored in R, G and B; read `.r` | data, no colour hint | Lossless | Disabled | on |
| `dark_wood_nor_gl_2k.png` | normal map | tangent-space slope, each channel `n * 0.5 + 0.5`, green up (OpenGL) | data, `hint_normal` | Lossless | Enable | on |
| `dark_wood_nor_dx_2k.png` | calibration only, not bound | same, green down (DirectX) | not sampled | Lossless | Enable | on |

All four also set `detect_3d/compress_to` to Disabled, so the editor has nothing to change when it first draws them in 3D.

Finding: the roughness PNG carries a colour-space tag like the diffuse does. The tag does not decide what the numbers mean; the shader's hint does, so roughness is sampled without `source_color`.

**Shader:** `godot/shaders/table_wood.gdshader`, to be hand-written by me. `shader_type spatial;` with the default lit render mode, so the Sun lights it.

| Group | Sampler | Hints | Bound to |
|---|---|---|---|
| colour | `albedo_tex` | `source_color`, `filter_linear_mipmap`, `repeat_enable` | `dark_wood_diff_2k.png` |
| surface | `roughness_tex` | `hint_default_white`, `filter_linear_mipmap`, `repeat_enable` (no `source_color`) | `dark_wood_rough_2k.png` |
| surface | `normal_tex` | `hint_normal`, `filter_linear_mipmap`, `repeat_enable` | `dark_wood_nor_gl_2k.png` |

| Group | Uniform | Type | Hint | Default | Expected across its range |
|---|---|---|---|---|---|
| colour | `tint` | `vec4` | `source_color` | `vec4(1.0, 1.0, 1.0, 1.0)` | Multiplies the wood colour. White leaves the photo as is; warm tints read as varnish. |
| colour | `brightness` | `float` | `hint_range(0.0, 2.0)` | `1.0` | 0 = black; above about 1.5 the dark wood looks washed out and plastic. |
| surface | `roughness_scale` | `float` | `hint_range(0.0, 1.0)` | `1.0` | 1 = matte as photographed; toward 0 a sharp Sun highlight appears. At 0 it looks like dark glass, because the scene has no environment to reflect. |
| surface | `normal_strength` | `float` | `hint_range(0.0, 2.0)` | `1.0` | 0 = flat, the grain only in colour; 2 = deep, noisy grain. |
| mapping | `uv_scale` | `float` | `hint_range(0.25, 8.0)` | `1.0` | Repeats of the texture across the surface. At 0.25 the grain is stretched and blurry; at 8 the repeats become obvious. |

**Prediction:** in a spatial shader, `source_color` on `tint` converts the Inspector's sRGB colour to linear before the shader sees it, so `(1.0, 0.85, 0.70)` arrives as about `(1.0, 0.69, 0.45)`. The hint experiment and the Use It captures check this on Compatibility.

**The two materials** (`.tres` files, both using `table_wood.gdshader`):

| Material | Path | `tint` | `roughness_scale` | `normal_strength` | `uv_scale` | Why |
|---|---|---|---|---|---|---|
| Dinner table, worn | `godot/materials/table_wood_worn.tres` | white | 1.0 | 1.0 | 2.0 | The long table: matte, used, grain as photographed, small repeats over a large surface. |
| Serving board, polished | `godot/materials/serving_board_polished.tres` | `(1.0, 0.85, 0.70)` | 0.35 | 0.5 | 1.0 | A varnished board: warmer, catches the Sun, softer grain. |

They differ in four values and share every texture, so any difference on screen comes from the values alone.

## 8. Hint experiment

**Setup:** a 3 × 1 PNG with texels 64, 128 and 192 (grey), written by a committed GDScript, imported Lossless with no mipmaps. One spatial shader, to be hand-written by me, `render_mode unshaded`, with two samplers bound to that same file: one `source_color, filter_nearest`, one `filter_nearest` only. A `bool` uniform picks which one writes `ALBEDO`. Two materials, one per bool value, on two quads facing the camera, in their own scene. A `WorldEnvironment` sets a Linear tonemap at exposure 1.0, with glow, fog and adjustments off.

**Predicted displayed 8-bit values**, using encode(x) = 12.92x for x ≤ 0.0031308, else 1.055·x^(1/2.4) − 0.055:

| Band (file value) | Quad A: with `source_color` | Quad B: without |
|---|---|---|
| 64 | 64 | 137 |
| 128 | 128 | 188 |
| 192 | 192 | 225 |

Worked example for 128 without `source_color`: x = 128/255 = 0.502; 1.055 × 0.502^(1/2.4) − 0.055 = 0.737; 0.737 × 255 = 188.

**Which quad shows the file unchanged:** Quad A. `source_color` decodes the stored sRGB value to linear, and the renderer encodes linear back to sRGB for display. The two cancel. Quad B treats the stored number as already linear, so only the display encode is applied, and every band comes out brighter.

**Renderer caveat:** these predictions assume Forward+ or Mobile. This project uses Compatibility, so I measure first and explain after. If Compatibility gives different values, that is a finding, recorded with the capture.

## 9. Predicted failure cases

| # | Failure | Why it could happen | Check that catches it |
|---|---|---|---|
| 1 | One fork's glow appears on every fork | One `ShaderMaterial` shared by all five sprites, so a single `warning` value drives them all | Headless rule 7: the five materials are distinct objects with the same shader; a SAFE fork reads `0.0` while another is in SHADOW |
| 2 | The ramp takes a different time at 30 or 144 fps | The driver counts frames or adds up `_process` delta instead of reading the fork's tick counter | Headless rule 2 at 30, 60 and 144 fps, and reading the test to confirm it runs the real game loop |
| 3 | The glow lags one tick behind the shadow | The driver updates before the session advances the forks in the same frame | Headless rule 1, per-tick sampler: on the first SHADOW tick, `warning` equals `1 / shadow_ticks`, not `0.0` |
| 4 | A held fork keeps its glow | Holding sets `t = 0`, but the driver only updates on phase changes | Headless rule 6: a fork held mid-SHADOW reads `0.0` on that tick |
| 5 | Roughness sampled with `source_color`, or the DX normal map bound | Copying hints between samplers, or picking the wrong file | `test_materials.gd` asserts each sampler's hints from the source and each bound path; the curl ratio of the bound normal map is near 0; the `source_color` mutation on `albedo_tex` exits 1 |
| 6 | The editor rewrites an import setting | Detect-on-first-draw changes a texture used in 3D | `git status` after the first editor session; `test_materials.gd` reads every `.import` file with `ConfigFile` |

## 10. Answers before building

1. **Renderer:** `project.godot` names Compatibility (`gl_compatibility`, lines 32–33). It rules out decals and compute shaders, and VoxelGI, SDFGI and SSIL. SSAO and SSR are unavailable too, so none can be confused with my materials.
2. **Colour arriving in `fragment()` (fork, `canvas_item`):** `COLOR` already holds the sprite's texture sample multiplied by the vertex colour (the node's modulate, white here), so it is the fork's own pixel. The tempting alternative, replacing it with `texture(TEXTURE, UV)`, gives the texel alone and throws away any modulate, so a future fade or tint on the fork would stop working.
3. **`canvas_item`, `texture(TEXTURE, UV)` instead of `COLOR`:** the raw texel of `ENV-FORK.png`, without the modulate multiply. With white modulate it looks the same today, which is why the mistake would go unnoticed.
4. **Spatial (table):** if I never write `ALBEDO`, it stays white, `vec3(1.0)`. `COLOR` holds the interpolated vertex colour; a `BoxMesh` has none, so I predict white. I never use it.
5. **Frame-counting version:** tuned as 96 frames for the 1.6 s fork at 60 fps, it would last 3.2 s at 30 fps, 1.6 s at 60 and 0.67 s at 144. In general, `shadow_ticks / fps` seconds. Mine counts physics ticks, so at `time_scale = 1.0` it lasts 1.6 s at all three.
6. **Default vs current value:** the default lives in the `Shader` resource (the source text of `fork_warning.gdshader`). The current value lives in each `ShaderMaterial`, set by `set_shader_parameter`. If two forks shared one material they would share one `warning`, and both would glow whenever either was in SHADOW. That is why each fork gets its own material (rule 7, failure 1).
7. **Does `hint_range` clamp a value set from code?** Prediction: no. It only limits the Inspector slider. `warning = 2.0` gives a mix amount of 1.3, which overshoots amber; P1 becomes about (278, 176, 36), clipped on output to (255, 176, 36). Checked by a capture in Use It.

## Revision 1 — 2026-10-27 (after the Claude Code planning run, `sessions/plan-2a.md`; decisions mine)

**Driver location and timing (replaces "every physics tick" in the §2 uniform table).** The driver lives in `godot/features/fork/fork.gd`. `warning` is initialized during `setup()` (through `reset_cycle()`), and updated in `_apply()` whenever `t` or `held` changes. While a fork is frozen (held, or the session in INTRO, PAUSED or WON, or the tree paused) nothing is written and `warning` retains its value. When a fork is held during SHADOW, `warning` is `0.0` on that same tick, unchanged from rule 6.

**Boundary clarification (§4).** The driver adds presentation-only lines to `fork.gd`: the material in `setup()`, a function that reads the phase and returns the `warning` value, and one line in `_apply()` that sets it. The phase logic, the tick counter and every timing stay unchanged, and the driver never writes `t`, `held`, `hold_pending` or `announced`.

**Base material (replaces the §2 "Material" line).** `godot/materials/fork_warning.tres` is a `ShaderMaterial` using `fork_warning.gdshader`. Each fork's `setup()` gives its sprite a **duplicate** of it, so every fork has its own material and its own `warning` (rule 7), while `strength` and `warn_color` are tuned once in the Inspector on the base `.tres`. Until I tune it, the base material sets no parameters, so the shader defaults apply.

**Uncovered rule.** Rule 5's "WON holds its value" has no headless check in this change. I will observe it by eye in a windowed run when the jelly reaches the dome, and record the result in TEST-REPORT.md.

## Revision 2 — 2026-10-27 (import settings, before committing the textures; decision mine)

The §7 texture table lists `compress/mode`, `compress/normal_map`, `mipmaps/generate` and `detect_3d/compress_to`. Godot's default `.import` files also hold `roughness/mode=0` (Detect). To leave the editor nothing to change later, all four dark-wood textures also set `roughness/mode=1` (Disabled). Values as written in the `.import` files: `compress/mode=0` (Lossless), `compress/normal_map=2` (Disabled) for diff and rough and `1` (Enable) for nor_gl and nor_dx, `mipmaps/generate=true`, `detect_3d/compress_to=0` (Disabled), `roughness/mode=1` (Disabled). The enum names are to be confirmed in the editor's Import dock.
