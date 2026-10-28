# SUBMISSION — Assignment 3

Prepared from the repository's records (drafted by Claude Code, reviewed and corrected by me on 2026-10-13). The submitted commit SHA and the final fresh-clone result are in the Canvas copy of this file, because a commit cannot contain its own SHA.

| Field | Value |
|---|---|
| Assignment | Assignment 3 - Your First 3D Game Assets with Claude, the Blender MCP, and Blender |
| Student | Kiran Gowda Ramanagara Jayaram |
| Project name | Jelly Hop: Fork From Above |
| Repository URL | https://github.com/kirangowda3101/walker-jellyhop-kiran-g |
| Tag | `a3` |
| Submitted commit SHA | given in the Canvas submission note (a commit cannot contain its own SHA) |
| Revisions | The film shows game source `948ab6a7f126f08dca8d49786f5adeb863aad044`; the submitted commit adds documentation only. `git diff --stat 948ab6a a3 -- godot/assets godot/showcase godot/game godot/features blender tools` prints nothing; the only other godot/ change is the generated `godot/tests/test_a3_assets.gd.uid`. |
| Game-source revision shown in the film | `948ab6a7f126f08dca8d49786f5adeb863aad044` (`948ab6a`) |
| OS | macOS 26.5.1 (build 25F80), MacBook Pro, Apple M4 (Apple Silicon) |
| Blender | 5.2.2 LTS (macOS arm64); glTF exporter Khronos glTF Blender I/O v5.2.40 (+Y Up, default) |
| Godot | 4.7.2.stable.official.ed1daf0bf, Compatibility renderer |
| Claude Code | 2.1.288 (Opus 5.5) |
| Other tools | uv 0.13.0, Homebrew 7.0.6, GNU coreutils 9.12 (`timeout`) |
| MCP project and version | "MCP for Blender" (community project named in the syllabus, mcp-for-blender.com): server package `mcp-for-blender` 2.1.9 run with `uvx`; Blender add-on 1.8 on 127.0.0.1:9876; `DISABLE_TELEMETRY=true`, add-on telemetry unticked, "Contribute session data" declined |

## The three assets

| Asset | Role in Jelly Hop | Size W × D × H (m) | Triangles / budget | Files |
|---|---|---|---|---|
| Fork | The hazard that stabs down from above | 0.5 × 0.05 × 1.5 | 72 / 100 | `blender/fork.blend`, `godot/assets/models/fork.glb` |
| Dessert dome | The goal at the end of the level | 1 × 1 × 0.75 | 266 / 300 | `blender/dome.blend`, `godot/assets/models/dome.glb` |
| Biscuit platform | A stepping stone to land on (planned for future levels) | 2 × 1.5 × 0.25 | 36 / 60 | `blender/platform.blend`, `godot/assets/models/platform.glb` |

Built in my Blender session from basic shapes by Python that Claude Code ran through the MCP's `execute_blender_code`, after I approved each plan and call (code in `tools/blender/build_*.py`). No downloaded or AI-generated meshes; no asset libraries or generators were used. Showcase scene: `godot/showcase/a3_assets.tscn`.

## My hand edit

In Blender's Material tab I corrected Claude Code's washed-out dome colours (TEST-REPORT.md A3.10):

- Dome_Pink (cover) #D1AAB6 → #D17390 (Saturation 0.184 → 0.45)
- Dome_Red (cherry) #DA303F → #A6111E (Saturation 0.90, Value 0.65)
- Dome_Cream (base) ≈ #F9EDD3 → #F9DEA2 (Saturation 0.35; the before value is computed from Claude's linear values, not read by me)

Claude Code read the colours back after the join; they converted exactly to my hex values.

## Checks run and results

| Check | Result |
|---|---|
| `godot --headless --path godot --import` | No errors or warnings; `.import` files created (commit caa382b) |
| `timeout 120 godot --headless --path godot --script res://tests/test_a3_assets.gd --fixed-fps 60` | `A3 ASSET CHECKS: 36 checks / 0 failures`, exit 0, no ERROR/FAIL/WARNING lines (`evidence/a3-assets-run.log`, 2026-10-13 01:46) |
| Fresh-clone rehearsal of `948ab6a` (Claude Code, 2026-10-13, unattended) | Import exit 0; check exit 0, 36 checks / 0 failures (evidence/a3/overnight-run-log.md, Phase 4) |
| Final fresh-clone check of the tagged commit | run on a fresh clone of tag `a3` after tagging; result in the Canvas submission note |
| Sizes: Blender sidebar vs Godot bounding box | All three match the brief within 1 mm (TEST-REPORT.md A3.2) |
| Scale, rotation, orientation | Scale 1, 1, 1, rotation 0; fork points down, dome not upside down (A3.3) |
| Origin / floor contact | Lowest vertex − floor top: fork 2.98e-08 m, dome 0, platform 0 (A3.4) |
| Triangle counts (Blender status bar and Godot) | 72 / 266 / 36 against 100 / 300 / 60 (A3.5) |
| Human check: look, through the scene camera and from below | Recognisable; no obvious holes in visible surfaces; dark sides hide detail; fork tips not checked close up (A3.8) |
| Predicted failure cases 1–5 (CHANGE-BRIEF.md) | None happened; the MCP connected after about 15 minutes with one command fix (A3.11) |

## Film

| Field | Value |
|---|---|
| Filename | `claude-liam-jelly-hop-a3.mp4` (284.133 s = 4 min 44.1 s, 3840×2160, 21,145,123 bytes; rebuilt after my script review — watched start to finish by me) |
| SHA-256 | `10adb47d931ffa23d500f409658eee709397dcc48303ae61805a62aadfe599fc` (changes if the film is re-rendered) |
| Final film URL | https://youtu.be/RBnJpG0Cnjc (YouTube, unlisted; I checked it plays in a logged-out private window). The SHA-256 is of the uploaded file; YouTube re-encodes it. |

## Summary of changes (Assignment 3)

- Assignment 3 brief added to CHANGE-BRIEF.md before building (eaaa66f); Blender interface notes (BLENDER-NOTES.md).
- Three assets built through the MCP, with the exact code of each call in `tools/blender/`; .blend sources in `blender/`.
- glTF exports and Godot imports in `godot/assets/models/`.
- 3D showcase scene `godot/showcase/a3_assets.tscn` and headless check `godot/tests/test_a3_assets.gd` (36 checks).
- Evidence: `evidence/a3/` (MCP connection test, Claude Code transcript, my screenshots with an index), `evidence/a3-assets-run.log` and JSON report.
- A3 sections in TEST-REPORT.md, FRICTIONAL.md, SOURCES.md and README.md; CHANGE-BRIEF.md "Assignment 3 — Revision 1 (2026-10-13)" on where the fork and dome appear in the A2 game **[drafted by Claude Code; to be confirmed by me]**.
- Explainer film (youtube/claude-liam-jelly-hop-a3/).

## Known limitations

- With one DirectionalLight3D and no WorldEnvironment, faces turned away from the light render pure black and hide colour and detail.
- The fork's prong tips were not checked close up from below.
- A fresh run of `tools/blender/build_dome.py` recreates Claude Code's original dome colours, not my hand-edited ones; Blender's Solid-mode viewport colours still hold the originals.
- Box-only shapes: blunt prong tips; the biscuit's plain top could pass for a plank from above.
- Placements: in the A2 code the forks sit over plates 2–6 and the dome sits on the table past the last plate, not on a final platform (CHANGE-BRIEF.md A3 Revision 1, to be confirmed). The platform is not in the A2 game.
- The assets are not in the 2D game and have no colliders; nothing here is a playtest. No other person has looked at the scene.
- The headless check renders nothing; its cherry test is weak.
- I could not verify whether `DISABLE_TELEMETRY=true` stops the add-on's minimal anonymous usage data.

## Changed games

No.
