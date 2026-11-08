# FACTCHECK — Jelly Hop: Particle Effects (A6 film)

Every spoken or on-screen claim, with its source at revision 8004dea (read from the read-only snapshot; each figure input checked byte for byte against `git show 8004dea:<path>` by `tools/make_images.py`, list in `images/inputs.sha256`). Written by Claude Code, 2026-11-08, before rendering.

| Beat | Claim | Source |
|---|---|---|
| B00 | The prompt is a reconstruction, not a transcript | PROMPTS.md; labelled on screen |
| B01 | A headless run times the CPU only | Kiran's film prompt item 2; TEST-REPORT.md A6 "Price — headless CPU" ("These are CPU numbers only") |
| B02 | Effect A event `player.just_landed` while PLAYING, same branch as SFX-LAND | CHANGE-BRIEF.md Effect A "The job"; CLAUDE.md (session.gd lines 372, 374) |
| B02 | Effect B: ambience, condition `state != State.WON` | CHANGE-BRIEF.md Effect B "The job"; CLAUDE.md |
| B02 | Both GPUParticles2D | CHANGE-BRIEF.md line 7; land_puff.tscn line 61; dome_glints.tscn line 51 |
| B03 | Emission: land_puff.tscn line 69 `explosiveness = 1.0`; amount 16 (line 64) | file; CHANGE-BRIEF.md "(all 16 on the landing frame)" |
| B03 | Process: particles_generated.gdshader line 343 `force = gravity;`; radial accel line 349, damping 360 | file; TEST-REPORT.md A6 Step 6 table (343) |
| B03 | Draw: land_puff.tscn line 65 texture, GradientTexture2D lines 7–13, 16 × 16 radial | file; SOURCES.md A6 |
| B04 | Process step is a particles shader running on the GPU; headless measures CPU only; low headless cost expected | Kiran's film prompt item 2 (the explanation Kiran asked for); shader line 3 `shader_type particles;`; CHANGE-BRIEF.md "Why GPU" |
| B04 | None of the three effect cases distinguishable from effects-off within spread | TEST-REPORT.md A6; `logs/cost_effects_60fps_mine_20261108-001211.log` compare lines (shown verbatim) |
| B04 | Not a measured zero; log reports opengl3; dummy-renderer statement unconfirmed | TEST-REPORT.md A6 "Limits"; CLAUDE.md Unconfirmed |
| B04 | Spread for effect_a_restart shown as 0.0194 ms | the log line verbatim. **Note:** TEST-REPORT.md's table says 0.0195 (0.2171 − 0.1976 from rounded round means); the log computes from unrounded values. The film quotes the log and does not speak the number. |
| B05 | Intent quotes: phases 0–2, 2–5, 5–12; cream core / dark rim; 6–12 px; over life; layering z −1 | CHANGE-BRIEF.md Effect A "The intent block", checked verbatim |
| B05 | "written before any Claude Code session for A6" | CHANGE-BRIEF.md line 3 |
| B06 | Lines 61–73 of land_puff.tscn; written by Claude Code session 2 | file; SOURCES.md A6 |
| B07 | Strip r0 is a fixture; Kiran's r0 verdict quote | TUNING.md Effect A r0 (verbatim); captures/land_puff/r0/ |
| B08 | r1 curve (0,1),(0.18,1),(0.2,0); r0 (0,1)→(0.2,0); range 4000/6500 unchanged; Claude proposed doubling, Kiran chose curve-only; edit session 4c | TUNING.md Effect A r1; CHANGE-BRIEF.md Revision 1; land_puff.tscn line 16 |
| B09 | Claude's prediction (frame 12 mostly behind, frame 15 ≤ ~40 px) | TUNING.md (session-4b-prediction.md) |
| B09 | Strips: 5–15 px at frame 12, 36–49 px at 15; one-frame offset | TUNING.md (session-4d-comparison.md) |
| B09 | Kiran: kept, easy to see on landing | TUNING.md, verbatim |
| B10 | effects_driver.gd 21–26; same condition as SFX-LAND; parent session; feet; finished → queue_free; then emitting | file; CLAUDE.md Ownership; FRICTIONAL.md A6 (Kiran moved `finished` before emitting) |
| B11 | Scripted capture, landings, scoot-off 9 ticks, 2 nodes alive | capture/run-a6-inputs.jsonl; CAPTURE.md |
| B11 | Visible overlap unverified | CLAUDE.md Unconfirmed; TEST-REPORT.md "In play — Effect A" item 2. The capture shows the two puffs' crumbs on screen in different places; the film does not claim they overlap. |
| B12 | Intent quotes for Effect B | CHANGE-BRIEF.md Effect B, verbatim; header notes Revision 2 changed the fade-in |
| B12 | "about twenty-four glints at a time, drifting upward over two point four seconds" | CHANGE-BRIEF.md "Steady state: about 24 glints alive … over its 2.4 s life" |
| B13 | dome_glints.tscn 32–40: shape 3 = box (brief: EMISSION_SHAPE_BOX), extents 70,45; gravity −6 drift up; line 16 blend_mode 1 = add, material on line 53; preprocess 2.4 line 59 | file; CHANGE-BRIEF.md Effect B settings |
| B14 | Fixture strip r0; restart at 10, stop at 70; Kiran's r0 verdict quote; Claude found fade-in at odds with frame 85 | TUNING.md Effect B r0 and r1 (session-7a-reading.md); dome_glints_preview.gd |
| B15 | Ramp offsets 0.2 → 0.08; peak alpha 0.85 at 8 %; colours and scale curve unchanged | CHANGE-BRIEF.md Revision 2; dome_glints.tscn lines 26–27 |
| B16 | Prediction 16–18 at frame 10; Kiran's cmp (10–85 differ, 145 identical); Claude no visible difference, own mistake; Kiran overruled; frame-85 thinning not met | TUNING.md Effect B r1; CHANGE-BRIEF.md Revision 2 "Still not met" |
| B17 | effects_driver.gd 27–34; line 31 stops; node stays; line 33 restart(); comment "preprocess applies again" unverified | file; CLAUDE.md Unconfirmed (B3) |
| B18 | Glints at tick 1; drift during PAUSED; emitting false on WON tick 1233; replay tick 1384 emitting true, dome off screen | capture log; CAPTURE.md |
| B19 | B1–B7 headless results; Esc drift seen by Kiran in play; replay not verified in play; Kiran toggled Visible in play | TEST-REPORT.md A6 "State — Effect B", "In play — Effect B" items 3, 4, 6 |
| B20 | Line 145 picks speed between min and max with a seeded random value; line 254 samples curve at lifetime percentage; generated, saved unedited, not used by game | TEST-REPORT.md A6 Step 6 table; CLAUDE.md Ownership; SOURCES.md A6; land_puff.tscn 45–46, 16 |
| B21 | 51/0, 45/0, 24/0, 27/0 at 60 fps; A1 ticks; A3 0.0 px; A4 10 ticks; A5 peak 2 on tested route; 1,667 ticks; same emitter; A2 at WON | logs/test_*_60fps.log summary lines (verbatim); TEST-REPORT.md A6 tables (verbatim quotes) |
| B22 | Mutation 1 read back 0.0, no warning, puff still fired in preview; Mutation 2 exactly one failure; restored to 51/0 | logs/mutation1_*, mutation2_* (verbatim); TEST-REPORT.md A6 |
| B23 | GPU readings 0.0 ms, blank graph, Compatibility and Forward+ comparison; budgets 0.25 ms unverified; CPU unresolved | TEST-REPORT.md A6 "Price — GPU"; evidence/a6-visual-profiler-*.png |
| B24 | Not provable headlessly | TEST-REPORT.md A6 "Unverified" and "Not provable headlessly" lists |
| B25 | Brief draft (Claude in chat) said headless test would show both puffs emitting; Kiran corrected before commit | FRICTIONAL.md A6 "I corrected the brief…" |
| B25 | Kiran changed the plan so `finished` was connected before emission | FRICTIONAL.md A6 "I changed the signal setup…" |
| B25 | Route ran off plate 1 (23-tick gap), route fixed, check kept | TEST-REPORT.md A6 "Other findings"; FRICTIONAL.md A6 |
| B25 | Third puff in 25 of 300 frames; slot limit | TEST-REPORT.md A6; FRICTIONAL.md A6 |
| B25 | Branch explanation (Claude in chat) contradicted by the file | FRICTIONAL.md A6 "The generated shader contradicted…"; Who did what (A6) |
| B25 | Engine-monitor columns identical (107.4364 ms) for empty and Effect A cases | TEST-REPORT.md A6 "Not used" |
| B26 | Open items | CLAUDE.md Unconfirmed; FRICTIONAL.md A6 "Still unresolved" |
| BVDT | Contributions | FRICTIONAL.md A6 "Who did what (A6)"; SOURCES.md A6. "Claude Code … made this film" = this session. |
| BVDT | Textures: two GradientTexture2D in the scene files; no third-party textures | SOURCES.md A6 |
| BVDT | Next step, quoted verbatim | Kiran's film prompt item 7 |
| BVDT | Revision 8004dea | SNAPSHOT-REVISION.txt; `git rev-parse 8004dea` = 8004deac38c5b4ad260f24433e0537b3e94d16e2 |

## Wording decisions

- "Not a measured zero" and "did not establish what ran on the GPU" follow Kiran's instruction and CLAUDE.md Unconfirmed. The film never says near-zero.
- The film says "two puff nodes were alive at once" (log) and "whether their crumbs visibly overlap is still unverified".
- No math notation is typeset; the only formula-like content is verbatim source code, labelled as code.
