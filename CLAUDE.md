# CLAUDE.md — working rules for this repository

Project: **Jelly Hop: Fork From Above** (CSYE 7270, Assignment 2), by Kiran Gowda. The playable slice is built in `godot/` (imported unchanged from the walker-jumpman starter; see SOURCES.md).

## Read first
- `SLICE-BRIEF.md`: the build brief for the slice.
- The approved design, which is the authority: `CONCEPT.md`, `STORYBOARD.md`, `CHARACTER-SHEET.md`, `CHANGE-BRIEF.md`.
- `ASSET-LOG.md` (Batch 2) for the game-ready art in `art/game/`.

## How we work
- Walker's loop: **brief → build → playtest → inspect → revise.** Propose a plan before editing. After I approve it, build in **complete batches**: make routine choices from the approved design yourself, ask me only about **significant design changes**, and stop for **one review per batch**.
- Explain briefly what each command does; I am new to Godot and want to learn.
- Be precise and honest. If an earlier claim was wrong, correct it explicitly. Never report a check as passed without running it, and never describe an automated input route as a human playtest.

## Hard rules
- Do not rewrite the approved design documents or earlier FRICTIONAL entries; changes go in new dated sections or entries.
- Do not edit `art/poses/`, `art/reference/`, `art/game/`, `gen-inputs/`, or anything in `~/Documents/jellyhop-generations/`. Copy game art into `godot/assets/` and verify the copies are byte-identical.
- No generated or downloaded audio until the audio batch. Sounds are silent placeholders that record their calls (SLICE-BRIEF.md §7).
- No paid services, no API keys in the repository, no MP3 or MP4 files, no file over 25 MB.
- Do not change jump strength or remove collision checks just to make a layout or test pass; revise geometry first, and say so if tuning must change.
- Do not delete or weaken a failing assertion to get a green run. Replace a starter check only with an explained equivalent.

## Scripts and git
- Shell scripts: `set -Eeuo pipefail`, an ERR trap that names the failing command, explicit checks, and a stop before committing on any problem. No `| tail` or similar that hides a failure.
- **No commit until I have reviewed the batch.** Then: stage only the intended files, show them, commit, and **never push if the commit failed**. After pushing, verify that local `HEAD` equals `@{u}`.

## Logs
- `FRICTIONAL.md` and other logs record only actual decisions, observations, edits and results. Do not infer my motivations; use my own words for my reasons. Mark your own routine choices as yours.
- Predictions are recorded only if I write them, labeled "(written before generating; reviewed and confirmed by me)".
