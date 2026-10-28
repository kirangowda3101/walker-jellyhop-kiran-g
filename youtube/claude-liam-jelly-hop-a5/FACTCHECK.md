# FACTCHECK — Jelly Hop: Shaders and Materials (A5 film)

Drafted by Claude Code on 2026-10-28. Each narrated or on-screen claim → its source in the repository at revision `77a6d10`. **Kiran must still read the script for accuracy**; this table shows where each claim comes from, not that the wording is how Kiran would put it. Figures parse their numbers from the files named (tools/make_images.py stops on any mismatch with the committed copies).

| Beat | Claim | Source |
|---|---|---|
| B00 | Prompt is an illustrative reconstruction | Written by Claude Code; labelled on screen (PROMPTS.md) |
| B00 | Revision 77a6d10, Godot 4.7.2, Compatibility | Kiran's film request; SOURCES.md A5 tools; `project.godot` line 32 |
| B01 | Fork turns amber before it strikes; one wood shader, two materials; a texture's numbers mean what the shader's reading says | CHANGE-BRIEF.md §1, §7; LANGUAGE-NOTES.md answer 4 |
| B02 | Jelly cube, plates, forks from above; state = SHADOW phase, gradual turn to candle amber with the shadow; Floor as worn table plus polished board | CHANGE-BRIEF.md §1, §7; Kiran's film request item 1 |
| B02 | Held frame value (plate 2, SHADOW, 0.88 at tick 455) | `capture/run-a5-inputs.jsonl` (this film's scripted capture), `media/clips.json` |
| B03 | Colour line, uniforms, alpha untouched, what `warning` is | CHANGE-BRIEF.md §2 (quoted verbatim by make_images.py) |
| B04 | Runs for the fragments that form the fork's pixels when drawn | LANGUAGE-NOTES.md answer 2 (Kiran's words, paraphrased) |
| B04 | Lines 1, 4, 9; hand-written by Kiran; no agent edited it | `godot/shaders/fork_warning.gdshader`; SOURCES.md A5; TEST-REPORT.md A5.10 |
| B05 | Physics stopped, warning set to 0/0.5/1/2 on the plate 2 fork; every value within one step; (255, 178, 37) at 2.0; hint_range does not clamp | TEST-REPORT.md A5.4; `evidence/a5-captures/capture-results.json`; LANGUAGE-NOTES.md answer 5 |
| B06 | Driver written by Claude Code from Kiran's approved plan; lines 221–231; `_apply()` runs when t or held changes; one duplicate per fork | SOURCES.md A5; `fork.gd` lines 49, 221–231; CHANGE-BRIEF.md Revision 1 |
| B07 | Scripted capture, not a playtest; intro forks half amber (0.51/0.52); plate 2 warms, strikes, returns to silver; forks hold after the win | This film's capture log (CAPTURE.md); matches TEST-REPORT.md A5.3 rule 4 and A5.5 (Kiran's playtest) |
| B08 | `cycle_of` reads slice_tuning.gd only; `expected_at` is the brief's formula; sampler after the session, every tick; Kiran's grep | `tests/test_fork_warning.gd` lines 134–147, 28–36; TEST-REPORT.md A5.3; FRICTIONAL.md A5-5 |
| B09 | 29/0 at 30/60/144; MD5 35385bc4… over 601 ticks × 5 forks; 1/96 … 1.0; plates 5/6 held; pause holds; splat → 0 | `logs/test_fork_warning_{30,60,144}fps.log`; TEST-REPORT.md A5.3 |
| B10 | Mutation 1: SHADER ERROR, empty list, 5 failures; mutation 2: no error, 4/29 failures, 25 still passed, silent store; mutation 3: 1/108 | `logs/mutation-1/2/3-*_60fps.log`; TEST-REPORT.md A5.2, A5.9; FRICTIONAL.md A5-6 |
| B10 | Headless draws nothing; colour judgements are human checks | CLAUDE.md headless facts; CHANGE-BRIEF.md §5 |
| B11 | Board material: shader line 10, tint, roughness 0.35, normal 0.5; worn: white, 1.0, 1.0, uv 2.0; made by Kiran in the editor | `materials/serving_board_polished.tres`, `table_wood_worn.tres`; FRICTIONAL.md "Who did what" |
| B12 | In memory, no file changed; shader edit changes both; board material edit changes only the board; table stays (92, 45, 29) | TEST-REPORT.md A5.8; `evidence/a5-captures/shared/` |
| B13 | Strip 64/128/192, two samplers, lines 4, 5, 7 | `hint_experiment.gdshader`; SOURCES.md A5; CHANGE-BRIEF.md §8 |
| B14 | Predictions; Forward+ exactly as predicted; Compatibility unchanged on both; difference is the renderer; why unresolved | TEST-REPORT.md A5.6; both `capture-results.json`; FRICTIONAL.md A5-10, "Still unresolved" |
| B15 | Albedo sRGB colour → source_color; roughness data, 0 mirror 1 rough, hint_default_white; normal slopes, hint_normal | `table_wood.gdshader` lines 5, 11, 12; CHANGE-BRIEF.md §7; LANGUAGE-NOTES.md answer 4 |
| B16 | 108/0; curl 0.3838 GL; threshold < 0.70 for this texture; Sun only | `logs/test_materials_60fps.log`; `logs/calibrate_normal_check_60fps.log`; CHANGE-BRIEF.md Revisions 3, 4; TEST-REPORT.md A5.9 |
| B17 | Converted and saved unedited; generated 7 ↔ table 5; 19 ↔ 12; hint difference not verified | LANGUAGE-NOTES.md Part 1 and answer 6 (quoted); SOURCES.md A5 |
| B18 | 15 captures; brightness, uv_scale, tint as predicted; roughness max 20, no highlight, prediction did not hold; normal max 2, flat map likely, not tested | `evidence/a5-sweep-notes.md`; TEST-REPORT.md A5.7 |
| B19 | shader_type decides object kind and built-ins; COLOR / ALBEDO / ROUGHNESS; Godot lights; hints and groups → Inspector; plain GLSL needs the application to provide it | LANGUAGE-NOTES.md answers 1 and 8 |
| B20 | Test read sampler rows early, stopped twice, fixes approved after reading; unmeasured video-memory estimate deleted; 5 corrections to CLAUDE.md draft; commands beyond expectation, empty shader diff the guard; audit found the UV slice | FRICTIONAL.md A5-3, A5-5, A5-8; TEST-REPORT.md A5.10; commit 07106ef message |
| B21 | Five unresolved items; import twice | FRICTIONAL.md A5 "Still unresolved"; TEST-REPORT.md A5.9 |
| BVDT | Results summary; two predictions that did not hold | TEST-REPORT.md A5.3, A5.4, A5.6, A5.7, A5.9 |
| BVDT | Contributions | FRICTIONAL.md "Who did what (A5)"; SOURCES.md A5 |
| BVDT | Dark Wood, Poly Haven, CC0, Dario Barresi, Dimitrios Savva, Rico Cilliers | SOURCES.md A5; CHANGE-BRIEF.md §7 |
| BVDT | Next step: measure whether the tint is converted to linear | **Proposed by Claude Code from the open items** (TEST-REPORT.md A5.11; FRICTIONAL.md "Still unresolved"). Kiran has not written an A5 next step; narrated as "proposed from the open items". **For Kiran to confirm or replace.** |
| BVDT | "Claude Code … made this film" | This run (2026-10-28) |
| BHTF | Your Turn prompt; "Kiran's rename nearly did" | Written by Claude Code (PROMPTS.md); FRICTIONAL.md A5-6 (25 of 29 checks still passed) |

## Choices of mine to note

- Title "Jelly Hop: Shaders and Materials" is Claude Code's choice.
- B20 lists the agent's mistakes only; Kiran's own editor slips (FRICTIONAL.md A5-7) are not narrated.
- "Claude Code wrote … both tests": `test_fork_warning.gd` (sessions 2b–2d) and `test_materials.gd` (session 3), per SOURCES.md A5.
