# Jelly Hop: Fork From Above

A small jelly cube left on a dinner table after a party hops across plates to reach a glass dessert dome. Giant forks strike from above, and a growing shadow warns before each strike. This repository holds the design, the generated assets with their full record, a playable Godot vertical slice, its tests, and a Brutalist explainer film about how it was made.

CSYE 7270, Assignment 2 · Kiran Gowda.

## Starting point and credit

The Godot project in `godot/` started from the **walker-jumpman "First Steps" starter by Nik Bear Brown** (https://github.com/nikbearbrown/walker-jumpman), commit `9387542`. It was imported unchanged in this repository's commit `d7f0c97`, so every later change to the starter is visible in git history. The movement model (fixed jump, coyote and buffer ticks, a held jump never re-jumps) comes from the starter. Full credits and licenses: [SOURCES.md](SOURCES.md).

## Engine

Godot **4.7.2.stable.official.ed1daf0bf**, GL Compatibility renderer, 1280×720 viewport, stretch mode `canvas_items`. Developed and tested on macOS 26.5.1 (Apple M4).

## Run it

**From the Godot editor:** open Godot 4.7.2, choose **Import**, select `godot/project.godot`, then press **Run Project** (F5). The main scene is `res://game/main.tscn`.

**From the command line (macOS):**

```sh
./walker-jumpman.command            # finds /Applications/Godot.app (or `godot` on PATH) and runs godot/
```

or directly:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path godot
```

A fresh clone has no `.godot/` import cache (it is git-ignored). The editor builds it on first open. From the command line, run `Godot --headless --path godot --import` once first.

**Checks:** `bash tools/run_slice_checks.sh` runs the art and audio copy checks, the three headless suites, the screenshot capture and a launch test. The audio checks need the audio environment described in [SOURCES.md](SOURCES.md).

## Controls

| Action | Keys |
|---|---|
| Move | ← / → or A / D |
| Hop | Space, ↑ or W |
| Pause / resume | Esc |
| Mute all sound | M (toggle) |
| Mute music only | N (toggle) |
| Skip the intro pan / play again at the end | any key (it never also hops; M and N only mute) |

The game also pauses itself when its window loses focus.

## What the slice demonstrates

- **One level, the full core loop:** six plates, five forks with fixed, learnable cycles, spilled sauce in three gaps, and a glass dome as the goal.
- **Read the shadow, then commit:**
  - A code-drawn shadow grows on a plate before its fork strikes.
  - The metallic scrape (SFX-WARN) plays once as the fork over the jelly's current or next plate starts descending. This timing was changed after playtesting (commit `23ae39c`).
  - Music turns quieter and muffled while an on-screen shadow grows.
- **Wobbly and alive:** 12 generated poses (idle, bored, two scoot frames, crouch, rise, fall, land, worry, splat, re-form, celebrate), chosen each tick by `choose_pose()` in `godot/features/player/player.gd`.
- **Every splat teaches:** a fork or sauce splat, a camera shake on fork hits only, and a quick re-form on the last plate landed on. That plate's fork restarts at its safe window.
- **Intro and ending:** an intro pan from the dome back to the jelly (skippable), and a win slide into the dome with a replay prompt.
- **Sound:**
  - Six sound events (HOP, LAND, WARN, SPLAT-FORK, SPLAT-SAUCE, WIN) through one entry point, each called only from the code that represents its event.
  - A looping music track with state-driven changes.
  - Separate mute keys for all sound and for music only.
- **Tests:** headless suites that pass at the film's revision (mechanics 25/0, keyboard 12/0, slice 61/0, game audio 8/0), plus byte-identical checks of every game art and audio copy. They use scripted input and some fixtures; they are not playtests.

## Known limitations

From [TEST-REPORT.md](TEST-REPORT.md) §9:

- **One playtester (Kiran), one machine** (macOS 26.5.1, Apple M4). No other playtesters; Windows and Linux are untested. The fresh-copy check ran on the same Mac.
- **Automated checks and screenshots use scripted input, some with fixtures.** They test the logic, not how the game feels or sounds.
- **Not separately confirmed in Kiran's playtest notes:**
  - whether the face reads at 64 px at 100% zoom
  - the jelly's visibility against each surface beyond the screenshots
  - Scoot A's 2 px box near strikes
  - the camera look-ahead's feel on every plate
  - the shake's feel
- **The sounds' fit with their events** is in Kiran's words only ("Yeah it all looks good"). **The music seam** is judged by one listener.
- **Collision differs from the character sheet** in two places: the airborne crouch keeps the standing box, and the splat and re-form collider stays.
- **Godot crashed once (exit 139)** importing `MUS-LOOP.ogg`. It was not reproduced later; the cause is unknown.
- **Generating or checking audio** depends on an environment outside the repository (`~/Documents/jellyhop-audio-env`) and on the torchsde workaround in `tools/batch3_generate.py`.
- **Batch 2 prompts record:** the prompts file was restored after generation, because its commit attempt failed. That batch has no committed-before-generation prompt record (ASSET-LOG.md, FRICTIONAL.md).
- **Design differences:**
  - the SFX-WARN trigger differs from CHANGE-BRIEF.md by Kiran's decisions (recorded, not edited into CHANGE-BRIEF.md)
  - cups are not in the slice

## The film

A 4 min 28 s landscape 4K explainer, **"Jelly Hop: Fork From Above"**, made with the course's Brutalist `godot-gamedev` skill and the `walker` modifier.
- **Narration:** "Liam, in for Bear", local Kokoro voice.
- **Revision shown:** source revision **`7a48ea8`**.
- **What it covers:**
  - the asset trace for the jelly (design → prompt → raw SDXL output → edits → in-engine)
  - the SFX-WARN fix as cause and effect
  - every sound event in real play, including a labeled segment of the slice's own audio with no narration
  - the tests and their limits, a verdict, and a next step toward the full game
- **Footage:** all gameplay footage is scripted-input capture, labeled as such; none of it is a human playtest.
- **The no-narration segment's audio:** the skill strips gameplay audio by default. This segment's sound reaches the film through a premixed master built from the capture's own recorded engine audio; nothing is dubbed. Kiran chose this method without asking the course for theirs ([FACTCHECK.md](youtube/claude-liam-jelly-hop-gamedev/FACTCHECK.md)).

**Where the film file is:** the MP4 is not in git. It is submitted in the **Canvas submission ZIP**:

| Field | Value |
|---|---|
| Filename | `claude-liam-jelly-hop-gamedev.mp4` |
| SHA-256 | `e7cdb04c15af0e4106ac6da03f08eb52ef642decf95af2f1108ea4869480d817` |
| Format | 3840×2160, 30 fps, h264 + AAC, 267.6 s, 48.3 MB |

This follows the professor's two options for film storage, as relayed by the TA, Zuoyu Wang, on 2026-09-23: "1. YouTube 2. Zip the video together and upload to Canvas". Kiran chose option 2. To check a copy: `shasum -a 256 claude-liam-jelly-hop-gamedev.mp4`.

**The film's record** in [`youtube/claude-liam-jelly-hop-gamedev/`](youtube/claude-liam-jelly-hop-gamedev/):

- Beat sheet: [beat_sheet.json](youtube/claude-liam-jelly-hop-gamedev/beat_sheet.json)
- Script (narration and what is on screen): [SCRIPT.md](youtube/claude-liam-jelly-hop-gamedev/SCRIPT.md)
- Evidence ledger (hashed source files, code excerpts, code → result pairs): [gamedev-evidence.json](youtube/claude-liam-jelly-hop-gamedev/gamedev-evidence.json)
- Fact-check of every claim: [FACTCHECK.md](youtube/claude-liam-jelly-hop-gamedev/FACTCHECK.md)
- Capture method, disclosures and hashes: [CAPTURE.md](youtube/claude-liam-jelly-hop-gamedev/CAPTURE.md)
- Build log (commands and results, including failures and fixes): [BUILD-LOG.md](youtube/claude-liam-jelly-hop-gamedev/BUILD-LOG.md)
- Quality checks: [_qc/REPORT.md](youtube/claude-liam-jelly-hop-gamedev/_qc/REPORT.md), [TYPECHECK.md](youtube/claude-liam-jelly-hop-gamedev/TYPECHECK.md)
- Film file record: [MEDIA.md](youtube/claude-liam-jelly-hop-gamedev/MEDIA.md)
- Also: [COMPONENTS.md](youtube/claude-liam-jelly-hop-gamedev/COMPONENTS.md), [SHOTLIST.md](youtube/claude-liam-jelly-hop-gamedev/SHOTLIST.md), [SOURCES.md](youtube/claude-liam-jelly-hop-gamedev/SOURCES.md), [RIFF.md](youtube/claude-liam-jelly-hop-gamedev/RIFF.md), [PROMPTS.md](youtube/claude-liam-jelly-hop-gamedev/PROMPTS.md), [BUILD-PROMPT.md](youtube/claude-liam-jelly-hop-gamedev/BUILD-PROMPT.md)

## Where each document lives

| Document | What it holds |
|---|---|
| [CONCEPT.md](CONCEPT.md) | the game in two sentences, core loop, the four design pillars, art and audio direction |
| [STORYBOARD.md](STORYBOARD.md) | seven panels (`design/storyboard/`) and the decisions behind them |
| [CHARACTER-SHEET.md](CHARACTER-SHEET.md) | the jelly: poses, sizes, collision boxes, palette (`design/character/`) |
| [CHANGE-BRIEF.md](CHANGE-BRIEF.md) | what changes from the starter: assets, events, sound and music behavior |
| [SLICE-BRIEF.md](SLICE-BRIEF.md) | the build brief for the playable slice: controls, sound placeholders, checks |
| [ASSET-LOG.md](ASSET-LOG.md) | every image and audio generation: prompts, settings, raw outputs, edits, selections |
| [AUDIO-BRIEF.md](AUDIO-BRIEF.md) | the sound and music plan for Batch 3 |
| [TEST-REPORT.md](TEST-REPORT.md) | Kiran's playtest (sound on and muted), the fresh-copy check, comparisons, limitations |
| [FRICTIONAL.md](FRICTIONAL.md) | dated log of decisions, observations, edits and results |
| [SOURCES.md](SOURCES.md) | starter credit, models, tools, licenses, human and AI roles |
| [CLAUDE.md](CLAUDE.md) | working rules for Claude Code in this repository |
| `art/`, `audio/`, `gen-inputs/` | game-ready art and audio, generation guides and prompts |
| `godot/` | the playable slice; tests in `godot/tests/` |
| `evidence/` | test outputs, traces, screenshots and checksums |
| `tools/` | the scripts used for assets, copies and checks |

## Human and AI contributions

- **Kiran:** the design decisions, the image generation runs, the asset selections, the reviews and the playtesting.
- **Claude chat (claude.ai):** drafted documents and prompts, and wrote the Batch 1–2 processing and guide scripts in `tools/`, which Kiran ran (as credited in [SOURCES.md](SOURCES.md)).
- **Claude Code:** the implementation, the audio generation and the film production.
- **Models:**
  - Stable Diffusion XL Base 1.0: all art
    - **Plate, sauce, fork and dome:** image-to-image at 50% over guides drawn by Claude's script (`tools/make_env_guides.py`). They stay close to those guides: 4–19% of object pixels changed (ASSET-LOG.md, Batch 2).
    - **Room and table:** text-to-image.
    - **The jelly:** image-to-image from Kiran's approved guide (`gen-inputs/char-ref-guide.png`). Its other poses came from pose guides built from that accepted reference.
  - Stable Audio Open 1.0: the six sound effects
  - MusicGen-small: the music

  Details and licenses: [SOURCES.md](SOURCES.md).
