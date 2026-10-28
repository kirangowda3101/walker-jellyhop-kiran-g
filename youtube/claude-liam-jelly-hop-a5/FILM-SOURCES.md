# FILM-SOURCES — A5 film

(The skill names this file SOURCES.md. This run's permission rules deny writing any file named SOURCES.md, which protects the repository's own SOURCES.md, so the film's source record is kept here instead.)

- **Game source revision shown:** `77a6d10fd6b9548355a194454f3e1d65148d0758` (walker-jellyhop-kiran-g, main). HEAD at the time of this run was `b0112a1`, which only adds `prompts/prompt-4-film.txt`; every repository input used by the figures was checked byte for byte against its copy at `77a6d10` (`images/inputs.sha256`).
- **Kiran's in-engine captures (committed):** `evidence/a5-captures/` (fork_warning_*, hint_experiment, materials_default, shared/1–3, sweep_table_*) and `evidence/a5-captures-forward-plus/hint_experiment.png`, with their `capture-results.json`. Scripted captures (script by Claude in chat, run by Kiran).
- **Logs:** `logs/test_fork_warning_{30,60,144}fps.log`, `logs/mutation-{1-semicolon,2-rename,3-source-color}_60fps.log`, `logs/test_materials_60fps.log`, `logs/calibrate_normal_check_60fps.log`.
- **This film's own capture:** `capture/` (CAPTURE.md): one scripted-input take from a snapshot of 77a6d10, Godot Movie Maker, windowed, 4K; AVI hash in `capture/captures.sha256`.
- **Code excerpts:** `fork_warning.gdshader` 1–10, `fork.gd` 221–231, `test_fork_warning.gd` 134–147, `serving_board_polished.tres` 8–18, `hint_experiment.gdshader` 1–15, `table_wood.gdshader` 3–14 (hashes in gamedev-evidence.json). Typeset quotes: CHANGE-BRIEF.md §2, `standard_generated.gdshader` 7 and 19, `table_wood.gdshader` 5 and 12, LANGUAGE-NOTES.md answer 6, `evidence/a5-sweep-notes.md`.
- **Texture credit:** Poly Haven "Dark Wood", https://polyhaven.com/a/dark_wood, CC0, by Dario Barresi, Dimitrios Savva and Rico Cilliers (SOURCES.md A5; `godot/assets/textures/dark_wood/ATTRIBUTION.md`). Not re-checked online for this film.
- **Toolkit:** brutalist.art at commit 6a8380a (not modified by me; its `runtime/remotion/package-lock.json` already showed a local modification dated 2026-09-22 before this run). `godot-gamedev` skill with `walker`; Remotion scenes ClaudeComposerAsk, BrutalistHesitantWriter, GodotDesignFigure, GodotDevWorkbench, ClaudeVerdictArtifact, ClaudeTitleOutro.
- **Voice:** Kokoro-82M (kokoro-onnx), voice `am_onyx`, local, no cost.
- No downloaded media, no paid services.
