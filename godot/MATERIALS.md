# MATERIALS.md — A5 material audit

Audit of the materials named in CHANGE-BRIEF.md §7 and §8, written by Claude Code on 2026-10-27 from the files as they are in the working tree (HEAD `221a039`). Nothing was edited during the audit. Every value below is pinned by `godot/tests/test_materials.gd` (108 checks, 0 failures at 60 fps: `./scripts/run-test.sh test_materials.gd 60`, log `logs/test_materials_60fps.log`), unless the row says INFO or "not checked".

The fork shader (`fork_warning.gdshader`, `fork_warning.tres`) is out of scope here. `test_fork_warning.gd` covers it.

**Enum names.** Engine enums (`Environment.ToneMapper`, `Environment.BGMode`, `Image.Format` and others) were looked up at run time with `ClassDB.class_get_enum_constants()`, and the test prints them. The `.import` integers belong to the editor's texture importer, which `ClassDB` does not expose, and the agent could not look them up. **Confirmed by Kiran by name in the editor's Import dock (2026-10-27):** `compress/mode=0` Lossless, `mipmaps/generate=true` On, `roughness/mode=1` Disabled, `detect_3d/compress_to=0` Disabled. `compress/normal_map` is hidden in the dock while the mode is Lossless. Godot's `ResourceImporterTexture` documentation describes it as choosing RGTC VRAM compression for normal maps (default 0 = Detect), so in Lossless mode it does not change the stored data; a non-Detect value still stops the editor from changing it and reimporting.

**Tolerances (my choice).** Floats: 1e-5. The editor saves float32 values as doubles, for example `uv_scale = 2.000000083125`. Colours: 1/255 per channel, one 8-bit step, because the Inspector snaps colours to 8 bits (`0.85` is saved as `0.8509804` = 217/255).

## Materials

| Resource | Shader | Uniform values set (as saved) | Textures bound |
|---|---|---|---|
| `res://materials/table_wood_worn.tres` | `res://shaders/table_wood.gdshader` | `tint = Color(1, 1, 1, 1)`, `brightness = 1.0`, `roughness_scale = 1.0`, `normal_strength = 1.0000000475`, `uv_scale = 2.000000083125` (lines 12–18) | `albedo_tex` → `dark_wood_diff_2k.png`, `roughness_tex` → `dark_wood_rough_2k.png`, `normal_tex` → `dark_wood_nor_gl_2k.png` (lines 4–6, 11, 14, 15) |
| `res://materials/serving_board_polished.tres` | `res://shaders/table_wood.gdshader` | `tint = Color(1, 0.8509804, 0.7019608, 1)`, `brightness = 1.0`, `roughness_scale = 0.350000016625`, `normal_strength = 0.50000002375`, `uv_scale = 1.0000000356249998` (lines 12–18) | same three files as above (lines 4–6, 11, 14, 15) |
| `res://materials/hint_with_source_color.tres` | `res://shaders/hint_experiment.gdshader` | `use_source_color = true` (line 11) | `strip_as_colour` and `strip_as_data` → `hint_strip/hint_strip_3x1.png` (lines 9–10) |
| `res://materials/hint_without_source_color.tres` | `res://shaders/hint_experiment.gdshader` | `use_source_color = false` (line 11) | same strip on both samplers (lines 9–10) |

All four set `render_priority = 0`. Both table materials load the same `Shader` object (`same_object: true`). No material binds `dark_wood_nor_dx_2k.png`.

Where they are used:
- `showcase/a5_materials.tscn` line 15: `A3Assets/Floor` `surface_material_override/0` = `table_wood_worn.tres`.
- Line 20: `ServingBoard` (`BoxMesh` 1.6 × 0.05 × 0.8 at (0, 0.025, 1.4)) `surface_material_override/0` = `serving_board_polished.tres`.
- `showcase/hint_experiment.tscn` lines 26 and 31: `QuadWithSourceColor` → `hint_with_source_color.tres`, `QuadWithoutSourceColor` → `hint_without_source_color.tres`.
- No node uses `material_override`.

## Shader uniforms

`table_wood.gdshader`: `shader_type spatial;`, default (lit) render mode.

| Uniform | Group | Type (engine list) | Hint / range | Default in source |
|---|---|---|---|---|
| `tint` | colour | `TYPE_COLOR` (20) | `source_color` | `vec4(1.0, 1.0, 1.0, 1.0)` (line 6) |
| `brightness` | colour | `TYPE_FLOAT` (3) | `hint_range(0.0, 2.0)` | `1.0` (line 7) |
| `roughness_scale` | surface | `TYPE_FLOAT` | `hint_range(0.0, 1.0)` | `1.0` (line 13) |
| `normal_strength` | surface | `TYPE_FLOAT` | `hint_range(0.0, 2.0)` | `1.0` (line 14) |
| `uv_scale` | mapping | `TYPE_FLOAT` | `hint_range(0.25, 8.0)` | `1.0` (line 18) |

`hint_experiment.gdshader`: `shader_type spatial; render_mode unshaded;`. `use_source_color`: `TYPE_BOOL` (1), no hint, default `true` (line 7).

All of these match CHANGE-BRIEF.md §7 and §8. `get_shader_uniform_list(true)` returns 8 entries and the groups `colour`, `surface`, `mapping` for `table_wood`, and 3 entries for `hint_experiment`. A non-empty list means each shader parsed.

## Samplers

The three import columns are the values read from each `.import` `[params]` section with `ConfigFile`.

| Shader | Sampler (line) | Hints as written | Bound by | Texture | `compress/mode` | `compress/normal_map` | `mipmaps/generate` |
|---|---|---|---|---|---|---|---|
| table_wood | `albedo_tex` (5) | `source_color, filter_linear_mipmap, repeat_enable` | worn, polished | `dark_wood/dark_wood_diff_2k.png` | 0 [Lossless] | 2 [Disabled] | true |
| table_wood | `roughness_tex` (11) | `hint_default_white, filter_linear_mipmap, repeat_enable` | worn, polished | `dark_wood/dark_wood_rough_2k.png` | 0 [Lossless] | 2 [Disabled] | true |
| table_wood | `normal_tex` (12) | `hint_normal, filter_linear_mipmap, repeat_enable` | worn, polished | `dark_wood/dark_wood_nor_gl_2k.png` | 0 [Lossless] | 1 [Enable] | true |
| hint_experiment | `strip_as_colour` (4) | `source_color, filter_nearest` | with, without | `hint_strip/hint_strip_3x1.png` | 0 [Lossless] | 2 [Disabled] | false |
| hint_experiment | `strip_as_data` (5) | `filter_nearest` | with, without | `hint_strip/hint_strip_3x1.png` | 0 [Lossless] | 2 [Disabled] | false |
| (not bound) | — | — | none | `dark_wood/dark_wood_nor_dx_2k.png` | 0 [Lossless] | 1 [Enable] | true |

All five textures also have `detect_3d/compress_to=0` [Disabled] and `roughness/mode=1` [Disabled], as Revision 2 specifies. This holds for the hint strip too, which Revision 2 does not cover.

Source images, decoded with `Image.load_from_file`:
- All four dark-wood PNGs: 2048 × 2048, `FORMAT_RGB8`.
- Hint strip: 3 × 1, `FORMAT_RGB8`, texels (64,64,64), (128,128,128), (192,192,192), as §8 describes.
- Roughness PNG: R = G = B at all 16 384 pixels sampled (stride 16, maximum channel difference 0), so reading `.r` loses nothing.

Normal-map curl ratio (`normal_map_check.gd`, stride 4, source PNGs):

| Map | `directx = false` (GL) | `directx = true` (DX) | Check |
|---|---|---|---|
| `dark_wood_nor_gl_2k.png` (bound) | 0.3838 | 1.6162 | PASS, below 0.70 under GL (Revision 3) |
| `dark_wood_nor_dx_2k.png` (calibration pair) | 1.6163 | 0.3837 | printed only, no pass/fail |

These are the same values as the Revision 3 calibration.

## Lights and environment

**`a5_materials.tscn`**
- One light: `A3Assets/Sun`, `DirectionalLight3D` (`a3_assets.tscn` lines 39–41).
  - `shadow_enabled = true`; `light_energy` 1.0, `light_indirect_energy` 1.0 and `light_color` white are defaults.
  - `directional_shadow_mode = SHADOW_PARALLEL_4_SPLITS` (default).
  - Points along (0, −0.766, −0.643) in its parent's space: down and away from the camera, 50° below horizontal.
- No `WorldEnvironment` in the scene. The current camera (`A3Assets/Camera3D`, perspective, fov 40) has no `environment` and no `attributes`.
- `rendering/environment/defaults/default_environment` is empty in `project.godot`.
- So no tonemap, exposure, ambient light or sky is set for this scene. What the renderer uses instead is not established headlessly (see findings).

**`hint_experiment.tscn`**
- No lights. Both quads are `unshaded`.
- `WorldEnvironment` → `Environment_linear` (lines 6–7, 14–15). The `.tscn` writes only `background_mode = 1`. The test reads the loaded resource:

| Property | Value |
|---|---|
| `background_mode` | 1 `BG_COLOR`, `background_color` = `Color(0, 0, 0, 1)` (default) |
| `tonemap_mode` | 0 `TONE_MAPPER_LINEAR` |
| `tonemap_exposure` | 1.0 |
| `tonemap_white` | 1.0 |
| `glow_enabled`, `fog_enabled`, `volumetric_fog_enabled`, `adjustment_enabled` | false |
| `ssr_enabled`, `ssao_enabled`, `ssil_enabled`, `sdfgi_enabled` | false |
| `ambient_light_source` | 0 `AMBIENT_SOURCE_BG` (no effect on unshaded quads) |

- Camera: `PROJECTION_ORTHOGONAL`, size 2.0, no `environment` or `attributes` of its own.

## Findings

1. **`BoxMesh` UVs put each face in a 3 × 2 atlas, so `uv_scale` is not "repeats across the surface".**
   - Evidence: test INFO `a5 Floor top face UV` gives `uv_min [0.3333, 0.5]`, `uv_max [0.6667, 1.0]` for the 8 × 4 m top face. The board's top face (1.6 × 0.8 m) gets the same region.
   - What it means: the top face samples only 1/3 × 1/2 of UV space. At `uv_scale = 2.0` the table top shows 0.67 × 1.0 copies of the texture, not 2 × 2. At `uv_scale = 1.0` the board shows one third by one half of the texture.
   - The face is 2:1 and its UV region is 2:3, so the grain is stretched non-uniformly. If U runs along X the stretch is 3:1; if U runs along Z it is 4:3. The test measures the extents, not which axis U follows.
   - Conflict with the brief: CHANGE-BRIEF.md §7 says `uv_scale` is "Repeats of the texture across the surface" and the worn table has "small repeats over a large surface".
   - Fixing it would mean changing the shader or the mesh. Both are Kiran's decision; no change was made.

2. **The A5 scene has no environment at all.**
   - Evidence: `a5 environment`: `world_environments: 0`, the camera has no `environment`, and the project default environment is `""`.
   - Tonemap, exposure and ambient light for the table are therefore whatever Compatibility does with no `Environment`. They are not set by any file. In particular the shadowed sides get no ambient term from an environment.
   - This matches §7 "the A3 Sun as committed", but the hint experiment controls tonemap and exposure while the table scene does not. So the §7 `source_color`-on-`tint` prediction would be judged under different output settings from the §8 experiment.

3. **Three 2K textures are bound uncompressed** (`compress/mode=0` on diff, rough and nor_gl).
   - Video memory: not measured. (Corrected by Kiran, 2026-10-27: the agent's estimate was removed because nobody measured it.)
   - This is the brief's choice (§7, Revision 2). I record it as cost, not as an error.
   - The roughness map is grey in all three channels (above), so three channels carry one channel of data.

4. **The source PNGs are larger than 8-bit RGB would need.**
   - `dark_wood_diff_2k.png` is 21 249 991 bytes; raw 2048 × 2048 × 3 bytes is 12 582 912. Both normal maps are about 18.6 MB.
   - That suggests the files are 16 bits per channel. Godot decodes them as `FORMAT_RGB8`, so the extra precision would be dropped on import.
   - **Confirmed by Kiran with `file` (2026-10-27):** all four Dark Wood PNGs are 16-bit/colour RGB; the hint strip is 8-bit RGB. Godot decodes the Dark Wood maps to `FORMAT_RGB8` (measured with `get_format()`), so the 8-bit quantization that pulls the curl ratio toward 1 comes from Godot's PNG decode, not from the source files.
   - The diffuse is 4.2 MB under the 25 MB repository limit (AGENTS.md).

5. **`dark_wood_nor_dx_2k.png` is imported but bound by nothing** (`dx_normal_map_not_bound` PASS).
   - This is intended (§7: "calibration only, not bound"; ATTRIBUTION.md).
   - The cost: the editor still imports it into `.godot/imported/`, and an export that includes all resources would ship it (18.6 MB source).

6. **The worn material saves values equal to the shader defaults** (`tint` white, `brightness`, `roughness_scale`, `normal_strength` = 1.0; `table_wood_worn.tres` lines 12–17).
   - Not wrong. If a default in `table_wood.gdshader` changes later, this material keeps the saved value and will not follow.

7. **The polished tint is stored 8-bit-snapped**: `Color(1, 0.8509804, 0.7019608, 1)` (line 12) against the brief's `(1.0, 0.85, 0.70)`.
   - The differences are 0.0010 and 0.0020, within one 8-bit step. This is the Inspector's 8-bit colour picker, not an error.

8. **The original A3 `Mat_floor` is still on the Floor mesh** (`a3_assets.tscn` line 11; test INFO `mesh_material: StandardMaterial3D`).
   - The surface override hides it, which is what §7 asks for (the A3 scene unchanged). It is noted so nobody reads `BoxMesh.material` and thinks the wood is not applied.

9. **No mutation run.** CHANGE-BRIEF.md §9 failure 5 names "the `source_color` mutation on `albedo_tex` exits 1".
   - The sampler-hint check compares the full hint list exactly, so adding or removing `source_color` on any sampler would fail it.
   - But I was not allowed to edit any `.gdshader` in this task, so that mutation was **not run**.

No problem was found in either shader's hints, either material's bindings, any `.import` value named in Revision 2, or the hint scene's environment. All match CHANGE-BRIEF.md.

## Attribution

Facts as recorded in CHANGE-BRIEF.md §7 (checked there by Kiran):

- Textures: Poly Haven "Dark Wood", https://polyhaven.com/a/dark_wood, CC0.
- Authors: Dario Barresi (baking), Dimitrios Savva (photography), Rico Cilliers (tiling).
- Checked 2026-10-27. 2K PNG, 2048 × 2048 RGB, in `godot/assets/textures/dark_wood/`.
- Normal convention used: OpenGL (`_nor_gl`). `_nor_dx` is kept only to calibrate the curl check.

The hint strip `hint_strip_3x1.png` is written by the committed script `godot/tools/make_hint_strip.gd` (§8).

## What the headless test cannot establish

A headless run uses a dummy renderer and draws nothing. So `test_materials.gd` cannot show:

- **Visuals:** any colour, brightness, grain, highlight or shadow on screen.
- **Hint experiment:** the predicted 64/128/192 vs 137/188/225 values, or whether `source_color` decodes at all on Compatibility.
- **Tint conversion:** whether `tint` arrives linearised (the §7 prediction 0.85 → 0.69).
- **Normal map on the GPU:** whether the normal map bends light in the right direction. The curl ratio checks the file's convention, not how it is lit.
- **Import and memory:** how much video memory the textures use (not measured). `compress/normal_map=1` does not change the imported data while the mode is Lossless (the option is hidden in the Import dock; see the enum note above). (Updated by Kiran, 2026-10-27.)
- **Lighting without an environment:** what Compatibility does with no `Environment` in `a5_materials.tscn`.
- **UV orientation:** which axis U follows on the `BoxMesh` top face. The test measures extents only.

Those need in-engine captures and Kiran's eyes.
