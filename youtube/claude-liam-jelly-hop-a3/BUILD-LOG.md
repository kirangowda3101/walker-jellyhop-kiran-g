# BUILD-LOG — Jelly Hop A3 explainer film (godot-gamedev + walker)

Record of what was run for this film, with results as observed. Claude Code ran every command below on Kiran's Mac (Apple M4, macOS 26.5.1) during an unattended overnight run on 2026-10-13. Kiran was asleep: **every choice here is Claude Code's**, unless quoted from Kiran's instructions.

## Setup

- Skill: `~/Documents/brutalist.art/skills/make/godot-gamedev/SKILL.md` with the `walker` modifier (installed; toolkit commit 6a8380a, not modified). Read with ai-explainer, OUTRO-LOCK.md, SILENT-MODE.md and the evidence reference.
- Same pipeline as the A2 film (`../claude-liam-jelly-hop-gamedev/`): Anaconda Python (`PATH=/opt/anaconda3/bin:$PATH`), local Kokoro `am_onyx`, Remotion via `runtime/scripts/remotion_scenes.py`, `./art final`. No paid service, no install, no new account.
- `./art scenes "Godot editor code scene tree inspector assets"` → GodotDevWorkbench (used), GodotDesignFigure (used).
- Game-source revision shown: `948ab6a`. No new engine capture: pictures are Kiran's screenshots and the committed headless log.

## Files written before rendering

`tools/make_images.py`, `tools/make_reel.py` → `beat_sheet.json`, `gamedev-evidence.json`, `SCRIPT.md`; `PROMPTS.md`, `BUILD-PROMPT.md`, `FACTCHECK.md`, `COMPONENTS.md`, `SHOTLIST.md`, `RIFF.md`, `SOURCES.md`.

## Checks and renders, in order

1. `./art godot-gamedev --check REEL --game godot` → **PASS** (13 source files, 63 exclusions, 4 components, 2 exact excerpts, 2 code → result pairs, `code-then-result-v1`).
2. Kokoro: 15 beats, cost $0.00. `tools/make_master.py`: 284.267 s (4.74 min); master mean −27.5 dB, peak −4.3 dB.
3. Pilot B05 (GodotDesignFigure) and B06 (GodotDevWorkbench) rendered and inspected: readable, nothing clipped.
4. All beats rendered; frames at 50 % and 95 % inspected. **Defect found:** B10 and B11's fourth Inspector note was clipped. Fixed by moving those items into the wide left list (narration unchanged); durations unchanged.
5. First `./art final` → **ready**, GATE V 30 frames / 0 BLOCKER / 0 MAJOR. GATE T inside `./art final` printed "skipped — missing deps" (Anaconda's scipy/NumPy mismatch, as in A2). That export is kept in `_qc/prev/export-1/` and is **not** the film.
6. GATE T run directly with `~/Documents/jellyhop-audio-env/bin/python runtime/scripts/type_check.py REEL` (as in A2): **FAIL, 4 beats** (`_qc/gate-t.log`):
   - B04, B05, B07: `contrast-local §8.3b` on regions **inside Kiran's screenshots** (Blender's Outliner, the colour-picker panel, the Godot editor chrome);
   - B11: `no-wordy-card §8.5`, a 14-word output line.
   - The toolkit's exemptions are per pattern in `type_check.py`; I did not edit the toolkit or relax the gate.
7. Fix round 1 (crops only, no retouching): B07 cropped to the game view; B05 to viewport crops plus picker-field crops; B04's enlarged status-bar crop replaced by the values typed beside the screenshot; B11's line shortened to 12 words. GATE T: **FAIL, 2** (`_qc/gate-t-2.log`): B04 (the Outliner in the screenshot itself), B05 (picker slider tracks).
8. Fix round 2: B04 cropped to the 3D viewport (status-bar values typed from the full screenshot, labelled); B05 shows only the picker's Hex rows. GATE T: **FAIL, 1** (`_qc/gate-t-3.log`): B05 `bbox-overlap §8.6b`, the Hex field's border in the screenshot-15 crop read as an overlapping label.
9. Fix round 3: dropped the screenshot-15 Hex crop (its viewport crop stays). Result: see below.

Labels that became wrong after the crops were corrected before the next render ("status bar crop enlarged" → "status bar values typed beside it"; "unedited apart from scaling" → "cropped to the game view, not retouched").

Each fix round re-ran `make_images.py` → `make_reel.py` → Kokoro → `make_master.py` → all 15 Remotion renders, so every render matches the current sheet. Durations stayed 284.267 s throughout (narration text unchanged).

## Final
- GATE T after fix round 3: **PASS**, 0 FAIL (`_qc/gate-t-4.log`).
- `./art final REEL --height 2160 --fps 30 --out REEL/exports/landscape --audio REEL/audio/master.wav` → **ready**; GATE V 30 frames, 0 BLOCKER, 0 MAJOR (`_qc/REPORT.md`). GATE T inside the wrapper still prints "skipped" (Anaconda), so it was re-run directly after the export: **PASS** (`_qc/gate-t-5.log`).
- `./art godot-gamedev --check` at handoff: **PASS** (13 files, 63 exclusions, 4 components, 2 exact excerpts, 2 pairs).
- Export: `claude-liam-jelly-hop-a3.mp4`, 284.267 s, 21,143,097 bytes, SHA-256 `825ce7bf63b0fcb2db430984dcbf3a1a1a82d6c33e5c0a7baa14641f96d6aa3a` (MEDIA.md).
- My QC: `_qc/REPORT.md` (bottom section).
- **Toolkit side effect (as in A2):** each `remotion_scenes.py` render updates `brutalist.art/runtime/remotion/_bench/consumers.json` (gitignored in that repo). No tracked toolkit file was changed by me.
- **Not done:** a human viewing with sound. Nothing committed.

## 2026-10-13 — Corrections after Kiran's script review

- **Kiran's correction:** "I cannot confirm which field I typed into when the cherry turned blue; 'Hue' was a guess."
- **B05 narration** now reads, exactly as Kiran gave it: "One slip on the way: a value went into the wrong field and the cherry turned blue, so Kiran restored the original before redoing it." The **Slip card** changed from "Hue 0.65 → blue" to "wrong field → blue". The film folder was searched for every other Hue claim: it was only in `tools/make_reel.py`, `beat_sheet.json`, `SCRIPT.md` and `FACTCHECK.md`, all corrected. FACTCHECK.md keeps a note quoting the old wording as the correction record. The 6 case-insensitive "hue" hits left in `beat_sheet.json` are inside base64 image data, not text.
- **SCRIPT.md total** now states the measured duration (the `script_md` function in make_reel.py prints "measured" only when every beat has a measured duration).
- **Rebuild, same pipeline:** `make_reel.py` → Kokoro (B05 voice 20.05 s, was 20.18 s) → `make_master.py` (284.133 s; master SHA-256 `81076800…`) → all 15 Remotion renders → GATE T **PASS** (`_qc/gate-t-6.log`) → `./art final --height 2160` **ready**, GATE V 30 frames / 0 BLOCKER / 0 MAJOR → GATE T after export **PASS** (`_qc/gate-t-7.log`) → `./art godot-gamedev --check` **PASS** (13 files, 63 exclusions, 4 components, 2 exact excerpts, 2 pairs).
- **Checks of the new file:** h264 3840×2160 30 fps + AAC; 284.133 s; receipt status ready with a matching SHA-256; outro tail −91.0 dB. The B05 Slip card was read in an exported frame and says "wrong field → blue". A local faster-whisper (base.en) transcript of the new B05 narration contains "a value went into the wrong field and the cherry turned blue" (Whisper spells Kiran "Curran").
- **New film:** `claude-liam-jelly-hop-a3.mp4`, 21,145,123 bytes, SHA-256 `10adb47d931ffa23d500f409658eee709397dcc48303ae61805a62aadfe599fc`. Superseded: `825ce7bf…` (in `_qc/prev/export-2/`).
