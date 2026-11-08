# Gate V — visual QC report

Frames sampled: 60  ·  BLOCKER: 0  ·  MAJOR: 0

Regional text-contrast checks (all declared regions required): B11, B18. Whole-frame dimming/scene color is not text contrast; empty-frame, fill and declared safe-area checks remain active. Visual content review remains required.

Clean — no BLOCKER/MAJOR defects. ✓---

# Claude Code's QC of the final export (2026-11-08)

The Gate V section above is rewritten by every `./art final`. This section covers `exports/landscape/claude-liam-jelly-hop-a6.mp4` (SHA-256 `7c094ecaebacabaa84d2c93928b60dc8955f6cde2ef169983c23b8532197b0db`).

| Check | Result |
|---|---|
| GATE V (inside `./art final`) | 60 frames, 0 BLOCKER, 0 MAJOR (first attempt refused: 2 MAJOR on B11's label region, fixed by per-line regions; BUILD-LOG.md step 8) |
| GATE T (`type_check.py`, jellyhop-audio-env Python) | PASS, 0 FAIL, before the export (`gate-t-2.log`) and after it (`gate-t-final.log`); 28 Remotion beats checked, B11/B18 footage not text-checked by GATE T |
| `./art godot-gamedev --check` at handoff | PASS: 17 files, 105 exclusions, 6 components, 6 exact excerpts, 6 code → result pairs |
| Streams | h264 3840×2160 30 fps; AAC 48 kHz stereo; 647.700 s = timeline; receipt ready, SHA-256 matches |
| Per-beat audio (from the export) | all 30 beats narrated; means −26.1 to −27.8 dB, peaks −2.8 to −8.5 dB |
| Outro | last 0.9 s max −91.0 dB: silent tail, no jingle |
| Footage timing | B11 and B18 frames in the export match the source clips at start, middle and end with a constant one-frame seek offset (mean abs diff ≈ 0.1): no retiming; no retime/trim notice in the compile log |
| Frames | a frame at 60% of every beat inspected (`final-sheet-0.png`, `final-sheet-1.png`) plus every beat at 85% before export: all labels legible, no clipping. B01's correction "A headless run times the CPU only." is on screen from about 75% of the beat to the cut |
| B11 | capture, excerpt and logged-value labels on every frame; the scoot-off pair (ticks 449, 458) and the ¼-speed replay labelled; no overlap claim |
| B18 | glints at tick 1 (crop), PAUSED drift (full frame), WON tick 1233 `emitting false`, replay tick 1384 with "the dome is off screen", 2.5 s labelled held frame |

Not done: a human viewing with sound; no transcript check of the narration.
