# FACTCHECK — Jelly Hop: Three 3D Assets (A3 film)

Drafted by Claude Code on 2026-10-13 (unattended). Each narrated or on-screen claim → its source in the repository at revision `948ab6a`. **Kiran must still read the script for accuracy**; this table shows where each claim comes from, not that the wording is how Kiran would put it.

| Beat | Claim | Source |
|---|---|---|
| B00 | The Walker prompt is an illustrative reconstruction | Written by Claude Code for this film; labelled on screen. See PROMPTS.md. |
| B00 | 72 / 266 / 36 triangles; revision 948ab6a; Blender 5.2.2; Godot 4.7.2 | TEST-REPORT.md A3 header and A3.5; `git rev-parse --short HEAD` at the start of the run |
| B01 | Built in Blender by Claude Code through the MCP, checked in Godot | FRICTIONAL.md "A3 — human and AI contributions"; TEST-REPORT.md A3.7–A3.8 |
| B01 | The final dome colours are Kiran's, set by hand | TEST-REPORT.md A3.10; FRICTIONAL.md "the dessert dome and my hand edit" |
| B02 | Fork = hazard stabbing down from above, so the jelly times its jumps; dome = goal at the end of the level; biscuit = stepping stone, planned for future levels | CHANGE-BRIEF.md A3 v1, "Role" lines |
| B02 | Sizes against the 0.5 m jelly; fork three jellies tall (1.5 m) | CHANGE-BRIEF.md A3 v1 "Scale reference" and Asset 1 size |
| B02 figure | Crops of screenshot 19 | `evidence/a3/screenshots/19-godot-scene-camera-run.png` (SHA-256 65f60d89…) |
| B03 | Kiran's screenshot of the fork prompt; names Walker's loop, points at the brief, repeats 0.5 m wide, 1.5 m tall, 6 boxes, budget 100; "Do not build yet"; no asset libraries or generators | Screenshot 23 (4ae34107…); `evidence/a3/claude-code-a3-transcript.txt` lines 440–470 |
| B04 | Claude's plan: four prongs, a head, a handle, all 0.05 m deep; Kiran accepted it | FRICTIONAL.md "A3: the fork" ("Claude Code's plan (23:26)… I accepted the plan, the join and metallic 0") |
| B04 | Status bar Tris 72, budget 100; fork points down with the tips at the origin | Screenshot 12 (status bar "Tris:72"); FRICTIONAL.md "A3: the fork", "My checks" |
| B05 | Washed out in Material Preview: cover nearly white-lavender, cherry salmon | TEST-REPORT.md A3.9; FRICTIONAL.md dome entry |
| B05 | Saturation 0.184 → 0.45 (narrated "about point one eight"); cherry darkened; cream changed; hex values on screen | TEST-REPORT.md A3.10 table |
| B05 | A value went into the wrong field and the cherry turned blue; Kiran restored the original before redoing it | FRICTIONAL.md dome entry, "Mistakes" (corrected 2026-10-13: which field is not known) |
| B05 figure | Screenshot captions | `evidence/a3/screenshots/INDEX.md` rows 13–15 |
| B06 | Instances at x = −2.5 (platform), origin (dome), 1.5 (fork); 0.5 m cube at 3, a reference not an asset | `godot/showcase/a3_assets.tscn` lines 27–37 (shown verbatim); README.md A3 section |
| B06 note | Scene written by Claude Code, plan accepted by Kiran | FRICTIONAL.md "export, Godot import and the headless check" |
| B07 | Run Current Scene through the scene camera; upright on the floor | Screenshot 19; INDEX.md row 19; TEST-REPORT.md A3.3–A3.4 ("Seen by me through the scene camera") |
| B07 | Quote "At this size, I can recognise the fork, dessert dome, and sandwich biscuit."; dark sides hide some detail | TEST-REPORT.md A3.8 (exact first sentence; the second is paraphrased as "noted that") |
| B08 | Line 7 "Expected values come from the brief… never from the files checked"; Blender Z-up → Godot Y-up; budget and Blender count per row | `godot/tests/test_a3_assets.gd` lines 7–12 (shown verbatim); TEST-REPORT.md A3.2 |
| B09 | Sizes match within 1 mm; 72 / 266 / 36 under budget; lowest points on the floor; 36 checks / 0 failures, exit 0; nothing rendered | `evidence/a3-assets-run.log` (parsed by tools/make_images.py); TEST-REPORT.md A3.4, A3.5, A3.7 |
| B10 | Kiran checked sidebar sizes, status-bar triangles, scene camera, undersides with the floor hidden | TEST-REPORT.md A3.2, A3.3, A3.5, A3.8 |
| B10 | One light and no environment → pure black shaded sides; fork tips not checked close up; fresh build_dome.py recreates Claude's colours | TEST-REPORT.md A3.12 |
| B10 | In the A2 code the dome sits on the table, not on a plate; not yet confirmed by Kiran | `godot/game/session.gd:146–153`, `godot/game/slice_tuning.gd:32, 107–108`; CHANGE-BRIEF.md "Assignment 3 — Revision 1 (2026-10-13)", drafted by Claude Code in this run, to be confirmed by Kiran |
| B11 | Washed-out dome colours fixed by hand; cherry first planned touching at one point, Kiran asked for 0.04 m into the cover; removed "Dots Stroke" and set fake users beyond the plan, reported afterwards; flagged its own cherry test as weak | TEST-REPORT.md A3.9; FRICTIONAL.md fork and dome entries |
| B11 output line | The course's `claude mcp add` command failed on Claude Code 2.1.288 (not Claude) | TEST-REPORT.md A3.9 last bullet; FRICTIONAL.md MCP entry |
| BVDT | Contributions: Kiran wrote the brief and every number, approved each plan and Blender call, made the hand edit, did every human check; Claude Code wrote and ran the Blender code, scene and check; Claude chat guided and organised notes | FRICTIONAL.md "A3 — human and AI contributions"; SOURCES.md A3 "AI assistance and my contributions" |
| BVDT | Claude Code made this film | This run (2026-10-13) |
| BVDT | Next step: decide where the dome goes before the assets enter a level | **Proposed by Claude Code from the open items** (CHANGE-BRIEF.md open item; TEST-REPORT.md A3.12). Kiran has not written an A3 next step; narrated as "from the open items", not as Kiran's plan. **For Kiran to confirm or replace.** |
| BVDT | MCP for Blender 2.1.9; revision 948ab6a | SOURCES.md A3 tools table; start of this run |
| BHTF | Your Turn prompt | Written by Claude Code (PROMPTS.md) |

## Corrections made while drafting

- A first label draft for B03 used a gendered pronoun for Kiran; replaced with "Kiran's fork prompt" before any render.
- After GATE T flagged low-contrast regions **inside** Kiran's screenshots (Blender's Outliner in 12, the colour-picker slider tracks in 14, the Godot editor chrome in 19), those figures were changed by **cropping only** (no retouching): B04 shows the 3D viewport of screenshot 12, with its status-bar values (Verts 48, Faces 36, Tris 72, Objects 0/6) typed beside it from the full screenshot; B05 shows viewport crops of 13, 14 and 15 and the picker's Hex field from 14 (a Hex-field crop from 15 was dropped after GATE T §8.6b read its border as an overlapping label); B07 shows screenshot 19 cropped to the game view. On-screen labels say "cropped". The full screenshots are unchanged in `evidence/a3/screenshots/`.
- B11's output line was shortened to 12 words for GATE T's wordy-card rule; meaning unchanged.
- **After Kiran's script review (2026-10-13):** B05 had said "point six five typed into Hue", with a "Hue 0.65 → blue" card. That came from the earlier FRICTIONAL.md wording, which Kiran says was a guess: Kiran cannot confirm which field the value went into. The narration now reads "a value went into the wrong field and the cherry turned blue", and the card reads "wrong field → blue".
