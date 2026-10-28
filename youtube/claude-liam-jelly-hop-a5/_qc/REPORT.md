# Gate V — visual QC report

Frames sampled: 50  ·  BLOCKER: 0  ·  MAJOR: 0

Regional text-contrast checks (all declared regions required): B07. Whole-frame dimming/scene color is not text contrast; empty-frame, fill and declared safe-area checks remain active. Visual content review remains required.

Clean — no BLOCKER/MAJOR defects. ✓
---

# Claude Code's QC of the final export (2026-10-28)

The Gate V section above is rewritten by every `./art final`. This section covers `exports/landscape/claude-liam-jelly-hop-a5.mp4` (SHA-256 `240e7409d3974cd49357e429564657ec6f6743fb5a9ad4daefb4aa547e34b237`).

| Check | Result |
|---|---|
| GATE V (inside `./art final`) | 50 frames, 0 BLOCKER, 0 MAJOR |
| GATE T (`type_check.py`, jellyhop-audio-env Python) | PASS, 0 FAIL, before the export (`gate-t-4.log`) and after it (`gate-t-5.log`) |
| `./art godot-gamedev --check` at handoff | PASS: 34 files, 74 exclusions, 7 components, 6 exact excerpts, 6 code → result pairs |
| Streams | h264 3840×2160 30 fps; AAC 48 kHz stereo; 518.567 s = timeline; receipt ready, SHA-256 matches |
| Per-beat audio (from the export) | all 25 beats narrated; means −26.0 to −28.0 dB, peaks −2.9 to −8.1 dB |
| Outro | last 0.9 s max −91.0 dB: silent tail, no jingle |
| Frames | a frame at 60% of every beat was inspected in `final-sheet-0.png` and `final-sheet-1.png`: all labels legible, no clipping. B01's end frame shows the correction "Every texture is information." on screen before the cut |
| B07 | capture label, excerpt label and per-fork `warning` tags visible; plate 2 tag climbs during SHADOW and reads 0.00 after the strike |

Not done: a human viewing with sound; no transcript check of the narration.
