I stopped at step 5, as your rules say. The new test failed 2 checks at 30 fps (21 checks, 2 failures, exit 1), so I haven't run it at 60 or 144, and steps 6–8 are not started. Both failures come from bugs in my test code, not from the driver. I've changed nothing to get past them.

## Done

**Step 1, driver** (`git diff godot/features/fork/fork.gd`):
- `const WARNING_MATERIAL = preload("res://materials/fork_warning.tres")`.
- `setup()`: `sprite.material = WARNING_MATERIAL.duplicate()`.
- The `warning()` function: 0 if `held` or the phase isn't SHADOW, else `shadow_amount()`.
- In `_apply()`: `if sprite: sprite.material.set_shader_parameter("warning", warning())`.
- `godot/materials/fork_warning.tres` is a `ShaderMaterial` with `shader = ExtResource(...)` pointing at `uid://uw0kr563expl` / `res://shaders/fork_warning.gdshader`, and no parameters set.

**Step 2, regression at 60 fps:** `test_game` 25/0, `test_slice` 61/0, `test_keyboard` 12/0, `test_a3_assets` 36/0. No `SHADER ERROR` or `SCRIPT ERROR` in any log; the only extra output is the leak warning CLAUDE.md already records.

**Step 3, checks 1–4:** 11/0 at 30, 60 and 144.
- **`warn_color` type:** 20 (`TYPE_COLOR`), as predicted, so the assertion is unchanged. Its hint reads 0 with an empty `hint_string`, so `source_color` isn't visible headlessly.
- **Unset parameters:** `strength` and `warn_color` read back `null` (Nil), on the base and on every duplicate. Check 4 is therefore `null == null`. It shows that no fork has an override; it doesn't show the value the GPU uses.
- **Check 3:** none of the five materials is the base object, and all share one `Shader`.

**Step 4, check 5:** 15/0 at 30, 60 and 144. Plates 5 and 6 read exactly 37/72 and 31/60 (max difference 0.0) on the first frame. They hold those values on every INTRO frame (120, 240 and 574 frames) and every INTRO tick (239).

## Step 5 failure (30 fps)

Checks 6, 7, 8 and the one-tick-late control passed: the per-tick values match the formula exactly over 601 ticks, with 2–3 complete ramps per fork, and the sequence MD5 is `35385bc4…7529`. Two checks failed:

1. **`9-per-frame-ramp-duration`:** plate 6 shows a "ramp" that starts at 0.5167 and lasts 4.5 s. The test started its frame window at index −1, so the window began with the *last* frame and then wrapped to the intro frames. The 4.5 s is the 4 s pan plus 30 ticks. The reason is that `process_frame` resumes my coroutine *before* nodes' `_process()`, so when I searched for the first PLAYING frame, the frame sampler had not recorded one yet.
2. **`9c-control-frame-counted-ramp`:** `fps` was 0, because `OS.get_cmdline_args()` doesn't contain `--fixed-fps`. The evidence files are all named `fork-warning-0fps-*.json`. With fps unknown, the tolerance fell back to 1/60 and the control took the wrong branch. Checks 1–5 don't use fps.

## Proposed fixes (for your approval)

- **Window start:** find the first PLAYING frame *after* the 600-tick wait, not before it.
- **Frame period:** measure it from the frame sampler's `delta` during INTRO (time scale 1.0) and set `fps = round(1/delta)`. Both are recorded in the evidence.

No assertion, tolerance or expected value changes. If you approve, I'll make these two fixes and rerun step 5 at 30, 60 and 144.

## Two things for you

- **Dark-wood `.import` files:** all four exist, dated 2026-10-27 19:03:40–42. That's before this session's first file (19:32), so these runs didn't create them, but CLAUDE.md says none existed. I haven't opened or changed them, and their settings haven't been checked against §7.
- **No `test_fork_warning.gd.uid`:** headless `--script` runs don't generate one. I didn't run the editor to make one, because an editor scan could reimport the textures. It will appear the next time you open the project in the editor.

Nothing is committed.