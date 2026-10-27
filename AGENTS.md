# AGENTS.md — lasting working rules for this repository

Project: **Jelly Hop: Fork From Above** (CSYE 7270), by Kiran Gowda. The game is in `godot/`. These rules apply to every agent session and carry from one assignment to the next; assignment-specific context lives in CLAUDE.md and CHANGE-BRIEF.md.

## How we work
- Propose a plan before editing. Implement only the steps I approve, and show the diff after each one.
- Explain briefly what each command does; I am new to Godot and want to learn.
- Be precise and honest. If an earlier claim was wrong, correct it explicitly. Never report a check as passed without running it, and never describe an automated input route as a human playtest.

## Hard rules
- Do not rewrite the approved design documents or earlier FRICTIONAL entries; changes go in new dated sections or entries. Files in `archive/` are read-only.
- Do not edit source art or generations: `art/`, `gen-inputs/`, `~/Documents/jellyhop-generations/`, or the source models and textures in `godot/assets/`. Their `.import` sidecar files hold import settings and may be edited when a task calls for it; the source image and model files themselves never change.
- Files in `godot/shaders/` are hand-written by me, except `standard_generated.gdshader`, which Godot generates from a converted StandardMaterial3D and I save exactly as generated (my annotations live in LANGUAGE-NOTES.md, by line number). No agent edits any file in `godot/shaders/`.
- Do not edit `scripts/run-test.sh`. It is the course-provided test wrapper; run every Godot test through it.
- No paid services, no API keys or credentials in the repository, no MP3 or MP4 files, no file over 25 MB.
- Do not change gameplay tuning or remove collision checks just to make a layout or test pass; say so if tuning must change.
- Do not delete or weaken a failing assertion to get a green run, and do not change existing test expectations. Replace a check only with an explained equivalent that I approve.

## Scripts and git
- Shell scripts you write: `set -Eeuo pipefail`, an ERR trap that names the failing command, explicit checks, and a stop on any problem. No `| tail` or similar that hides a failure. (`scripts/run-test.sh` is exempt: it is used exactly as provided.)
- **Never commit or push.** I review every change and make every commit myself, so the history shows who wrote which lines.

## Logs
- `FRICTIONAL.md` and other logs record only actual decisions, observations, edits and results. Do not infer my motivations; use my own words for my reasons. Mark your own routine choices as yours.
- Predictions are recorded only if I write them.
