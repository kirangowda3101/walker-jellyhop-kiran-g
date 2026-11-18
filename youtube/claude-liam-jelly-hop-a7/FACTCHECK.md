# FACTCHECK — Jelly Hop: Animation Clips (A7 film)

Every narrated or on-screen claim, with its source at revision `c1bbb13` (read from the snapshot; figure inputs also matched `git show c1bbb13:<path>` byte for byte, `images/inputs.sha256`). Commit facts are from `git log` in Kiran's repository (read-only). "Capture" = this film's scripted take (`capture/run-a7-inputs.jsonl`). Written by Claude Code, 2026-11-17.

| Beat | Claim | Source |
|---|---|---|
| B00 | The on-screen prompt is an illustrative reconstruction | PROMPTS.md; labelled on screen |
| B01 | One hand-off ran a tick ahead until a test caught it | TEST-REPORT.md A7, "The 132/5 failure"; commit 74fe4b5 |
| B02 | Jelly Hop: jelly cube, plates, dinner table, forks from above | earlier films; CHANGE-BRIEF.md title |
| B02 | Routes: "Two cells on a Sprite2D, held by a discrete `frame` track." / "Two Sprite2D cutouts under Node2D pivots. The pieces move and scale without swapping drawings." | CHANGE-BRIEF.md lines 11, 12 (quoted, checked verbatim by make_images.py) |
| B02 | Sheet packed from Kiran's A2 SCOOT-A/B art; 7 ticks per cell; LOOP_LINEAR | CHANGE-BRIEF.md lines 16, 25, 27; CLAUDE.md line 19; scoot.tres line 6 |
| B02 | Land cut from CHAR-IDLE.png at row 622; keys at 0/2/4/8; LOOP_NONE | CHANGE-BRIEF.md lines 41, 31, 53–58; land.tres lines 6, 15 |
| B02 | Held frames: tick 390 SCOOT-B clip scoot; tick 295 LAND clip land | capture log; media/clips.json `held` |
| B03 | hframes 2, vframes 1, frame 0, offset (−512, −812) at lines 27, 28, 29, 26 | player_visuals.tscn lines 20–29 |
| B04 | Sheet 2048 × 1024; cells A and B side by side, no cropping; 0 mismatched px per cell | CHAR-SCOOT-SHEET.ATTRIBUTION.md lines 3–4; CHANGE-BRIEF.md line 25 |
| B05 | Length 14/60 (0.23333333), loop_mode 1 = LOOP_LINEAR, step 1/60, path line 11, keys 0 and 7/60 line 15, update 1 = discrete line 17 | scoot.tres lines 5–17; CLAUDE.md line 85–86 (names); TEST-REPORT.md A7 read-back (DISCRETE, LOOP_LINEAR) |
| B06 | Fixture: frame 259 t=0.1 cell 0; 260 t=0.116667 cell 1; wrap: 322 t=0.216667 cell 1, 323 t=0 cell 0 | captures/scoot/r1/ filenames and scoot.log FRAME lines |
| B06 | "no pause or jerk" over five wraps | TEST-REPORT.md A7, HUMAN CHECK row 1 (Kiran's words) |
| B07 | track_problems called line 169, print 171, check 172; function from the handout | test_a7_land_readback.gd lines 46–47, 169–172 |
| B08 | M1: position → positon; import exit 0; 94 / 3; track problem line; committed 135 / 0 | evidence/a7-mutations/M1_diff.txt, summary.txt, fail_lines.txt, M1 log line 99; logs/test_a7_land_readback_60fps.log |
| B09 | "Exactly one writer per animated node and property"; table rows | CLAUDE.md lines 67, 69–78 |
| B10 | Line 201 transform with X basis (facing, 0); 203–205 visibility; 209 stop() | player.gd lines 200–212 |
| B11 | Stationary hop: touchdown 293, rig + clip land ticks 293–300, original sprite from 301; scoot swaps at phase 7; facing mirrors | capture log; driver checks (859 / 0) |
| B12 | 219 pause() while disabled (Revision 1); 222 entry rule; 224 steady tick no call; 227 play | player.gd lines 213–227; CHANGE-BRIEF.md lines 152–158 |
| B13 | Presses read at +1, +3, +6; ANTIC at 653, 789, 928; LAND on earlier ticks; each hop on its predicted tick | capture log; CHANGE-BRIEF.md lines 89–94 (k=1 and k=3 predictions); k=6 lies in Recovery 4–7 (line 37) |
| B14 | callback_mode_process = 0 = physics (line 66); root_node ".." (62); autoplay empty (67); gameplay in _physics_process at 60 ticks/s | player_visuals.tscn 61–67; scoot read-back log line 42; player.gd line 94; TEST-REPORT.md A7 "Two clocks" |
| B15 | 74fe4b5: 132 checks / 5 failures; SCOOT one tick ahead on direct LAND → SCOOT; cell 1 during SCOOT-A | commit 74fe4b5 message; TEST-REPORT.md A7 (quoted lines) |
| B15 | fd4d855: play() on an already-playing AnimationPlayer gets +1/60 in its own update that tick | commit fd4d855 message; CHANGE-BRIEF.md line 184 |
| B15 | 5c0fb9a fix; now diff_ticks 0 | commit 5c0fb9a; logs/test_a7_visual_state_60fps.log lines 4468–4469 |
| B16 | Direct LAND → SCOOT only, not a resume: seek fposmod(t − 1/60) at line 232; others line 234 | player.gd lines 227–236; CHANGE-BRIEF.md lines 186–188 |
| B17 | Lands moving at 521; LAND 521–528; SCOOT-B at 529 at the synced phase (9/60) | capture log (`handoff` event; SCOOT rule check) |
| B18 | Phase table: Startup 0–1, Active 2–3, Recovery 4–7; eight-tick window; keys 0, 2/60, 4/60, 8/60; 2 and 4 identical; ease out | CHANGE-BRIEF.md lines 31, 33–37, 53–58; land.tres lines 15, 18 |
| B19 | Line 15 key times; line 16 transitions 2, 1, 0.5 (,1); line 18 lower height 0.55 at frames 2 and 4 (Revision 3, from 0.60); about 43 game px | land.tres lines 15–18; CHANGE-BRIEF.md lines 196–207 |
| B20 | r0 frames 104–109, r1 145–150; FALL, rig 0/2/4/6, IDLE at tick 8; 30 fps fixture | captures/land/r0, r1; land_clean.log STRIP lines |
| B20 | Kiran's r0 verdict: smooth at normal speed; hold easier frame by frame | TUNING.md "A7 — landing, r0" |
| B21 | Claude predicted ≈1 game px flatter, "almost the same"; Kiran's verdict first: barely different at normal speed, flatter in Preview at rig 2 and 4, kept; Claude's comparison: not confirmable within ±2 px | TUNING.md A7 r1 sections; TEST-REPORT.md A7 "Claude against Kiran" |
| B21 | "Kiran overruled that reading" | Kiran's own wording in the film request; the record shows Kiran's verdict (kept r1) was written before Claude's comparison |
| B22 | land 135/0, scoot 62/0, structure 29/0, state 132/0 at 30/60/144, edges 397/0 at 30/60/144; all 12 interrupt predictions matched | logs/test_a7_*.log summary lines; TEST-REPORT.md A7 "Edges" |
| B23 | M1 94/3, M2 62/1, M3 62/2 CONFIRMED; M4 empty cache 135/0 and 62/0 PASSED AS EXPECTED; loop modes saved in the clip resources | evidence/a7-mutations/summary.txt |
| B24 | "Headless: nothing is drawn" in the test headers; seam, feet, pop, feel, contrast are visual judgments | test_a7_visual_state.gd line 5; test_a7_edges.gd line 7; CHANGE-BRIEF.md line 113; TEST-REPORT.md HUMAN CHECK rows |
| B25 | CLAUDE.md draft: wrapper-never-edited statement corrected, A6 shader clause restored | FRICTIONAL.md A7 note 5; commit ffac0d8 |
| B25 | Agent expected 10 baseline-only checks, Kiran's run showed 9 | FRICTIONAL.md A7 note 6; SOURCES.md A7; commit fe9a1f0 |
| B25 | Read-only cat/ls/head/grep despite wrapper-only scope; %.3e formatting errors the wrapper missed | FRICTIONAL.md A7 note 8; commits 73eba42, 1bf1133 |
| B25 | SCOOT a tick ahead after wiring | FRICTIONAL.md A7 entry 12; 74fe4b5 |
| B25 | Chat: pixel scan reported row 601 (smile edge); also cp without -p, 18 vs 16, zsh array bug | SOURCES.md A7 "Claude in chat"; FRICTIONAL.md A7 note 3 |
| B26 | No realtime run recorded; run_slice_checks.sh not read; A6 open items not rechecked | CLAUDE.md lines 105–107 |
| B26 | Later evidence covers API names (ClassDB), pins, saved library (M4), float32 keys (KEYTIME) | TEST-REPORT.md A7 "Read-back", "Pins", "Fresh cache (M4)" |
| B26 | Pause during LAND then SCOOT: untested | CHANGE-BRIEF.md line 188; TEST-REPORT.md A7 "Untested" |
| B26 | 14 baseline runs not re-run after r1 (9ada865) | TEST-REPORT.md A7 "Baseline (before and after)" |
| B26 | landing-r0: 516 PNGs vs 356 reported, unexplained | FRICTIONAL.md A7 note 2 |
| BVDT | Contributions | SOURCES.md A7 (Specified, Measured, Ran, Judged; Written by Claude Code; Claude chat) |
| BVDT | Sheet: Kiran Gowda's A2 art, SDXL Base 1.0 locally, CreativeML Open RAIL++-M | CHAR-SCOOT-SHEET.ATTRIBUTION.md lines 6–7 |
| BVDT | Next step, verbatim | the film request (Kiran's words) |
| BVDT | Revision c1bbb13 | launch note; `git rev-parse c1bbb13` = c1bbb13f538408f4b6ef608d4d3b4ef5d2b620fa |

## Wording choices to review

- "Kiran overruled that reading" (B21) is Kiran's framing from the request. Strictly, Claude's comparison neither confirmed nor contradicted the difference; Kiran's Preview reading and the decision to keep r1 stand.
- B13 calls k = 6 "inside recovery". The brief's interrupt table names k = 5 and 7, not 6; the capture's prediction for k = 6 (LAND on 0–5, ANTIC at 6) follows the same rule and was checked tick by tick.
- B26 does not list as "uncertain" the CLAUDE.md Unconfirmed items that later committed runs cover; it says so on screen.
