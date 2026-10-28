The audit is done and the new test passes: `./scripts/run-test.sh test_materials.gd 60` prints **`MATERIAL CHECKS: 108 checks / 0 failures`**. The log is `logs/test_materials_60fps.log`, and it has no `SHADER ERROR`, `SCRIPT ERROR` or other warning lines.

The first run failed 1 of 108 checks, `uniform_default_source tint`. The cause was my parser, not the shader: the number regex also caught the `4` in `vec4(`. I changed it to read only inside the parentheses, and the expected value is unchanged.

The only new files are `godot/MATERIALS.md`, `godot/tests/test_materials.gd` and the log. No shader, material, scene, `.import` or existing file was touched. Nothing is committed.

**What matches CHANGE-BRIEF.md:**
- **Samplers:** every hint matches §7 and §8, compared as an exact list against the source text.
- **Uniforms:** names, types, groups, ranges and source defaults all match.
- **Materials:** both table materials load the same shader. Their saved values are within tolerance of the brief. They bind diff, rough and nor_gl, and nothing binds `nor_dx`.
- **Import settings:** every `.import` value in Revision 2 matches.
- **Hint scene:** the loaded `Environment` has tonemap 0 `TONE_MAPPER_LINEAR`, exposure 1.0, and glow, fog and adjustments off.
- **Images:** the strip texels are 64/128/192. The roughness PNG is grey in all three channels.
- **Curl ratio:** nor_gl is 0.3838 under GL and 1.6162 under DX, so it passes the < 0.70 threshold. nor_dx is printed as the calibration pair, 1.6163 / 0.3837, with no pass or fail.

**Findings in MATERIALS.md that need your decision:**
1. **`BoxMesh` UVs:** each face gets its own part of a 3 × 2 layout. The top face only covers U 0.333–0.667, V 0.5–1.0 (measured), so `uv_scale` does not mean "repeats across the surface" as §7 says. At `uv_scale = 2.0` the table shows about 0.67 × 1 copies of the texture, and the grain is stretched unevenly.
2. **No environment in `a5_materials.tscn`:** there is no `WorldEnvironment`, no camera environment and no project default. The table's tonemap, exposure and ambient light are therefore set by no file, unlike the hint experiment.
3. **Texture memory:** the three 2K textures are bound Lossless. By my estimate (not measured) that is about 50–65 MiB of video memory.
4. **PNG bit depth:** the PNGs look 16-bit by file size (diff is 21.2 MB; 8-bit RGB would be 12.6 MB raw), but Godot decodes them as `FORMAT_RGB8`. Not confirmed: reading the headers with `file` or `xxd` needed approval. You can check with `file godot/assets/textures/dark_wood/*.png`.
5. **Smaller notes:** the DX map is imported but unbound (as intended), the worn material saves values equal to the defaults, the tint is stored snapped to 8 bits, and `Mat_floor` stays on the mesh under the override.

**Things I could not do:**
- **`.import` enum names:** I couldn't look up the names for `compress/mode`, `compress/normal_map`, `roughness/mode` and `detect_3d/compress_to`. The web fetch was declined and the Godot binary is outside the directories I may read. MATERIALS.md gives the integers, with Revision 2's names in brackets, marked as not confirmed by me. The engine enum names (tonemap, background mode, image format) are looked up at run time by the test through `ClassDB`.
- **Other frame rates:** the test was run at 60 fps only.
- **Mutation run:** I didn't run the §9 `source_color` mutation, because this task forbids editing shaders. The exact-list hint check should catch it.
- **Tolerances:** floats are compared within 1e-5 and colours within 1/255 per channel, one 8-bit step.

**What the test cannot establish headlessly:** anything on screen. That covers:
- the colours and grain;
- the hint-experiment pixel values;
- whether `source_color` decodes on Compatibility;
- whether `tint` arrives converted to linear;
- how the normal map is lit (the curl ratio checks only the file's convention);
- memory use;
- what Compatibility does with no environment;
- which axis U follows on the box's top face.

All of these need in-engine captures and your eyes.