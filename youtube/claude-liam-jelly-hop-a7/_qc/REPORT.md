# Gate V — visual QC report

Frames sampled: 60  ·  BLOCKER: 0  ·  MAJOR: 0

Regional text-contrast checks (all declared regions required): B11, B13, B17. Whole-frame dimming/scene color is not text contrast; empty-frame, fill and declared safe-area checks remain active. Visual content review remains required.

Clean — no BLOCKER/MAJOR defects. ✓---

# Claude Code's QC of the final export (2026-11-17)

The Gate V section above is rewritten by every `./art final`. This section covers `exports/landscape/claude-liam-jelly-hop-a7.mp4` (SHA-256 `deb57025203a194150e436b4ce198af71d85ad0b3b76bd7ded0b98dda71411ac`).

| Check | Result |
|---|---|
| GATE V (inside `./art final`) | 60 frames, 0 BLOCKER, 0 MAJOR; regional label checks on B11, B13, B17 |
| GATE T (`type_check.py`, jellyhop-audio-env Python) | first run FAIL (B20 contrast-local, B24 wordy line), fixed; PASS, 0 FAIL (`gate-t-3.log`); the wrapper's own GATE T was skipped ("missing deps") |
| `./art godot-gamedev --check` | PASS before rendering and at handoff: 22 files, 118 exclusions, 5 components, 8 exact excerpts, 8 code → result pairs (`gamedev-check-handoff.log`) |
| Streams | h264 3840×2160 30 fps; AAC 48 kHz stereo; 622.967 s = timeline = master.wav; receipt ready, SHA-256 matches |
| Per-beat audio (from the export) | all 30 beats narrated; means −27.8 to −26.0 dB, peaks −8.7 to −2.9 dB (`beat-audio.json`) |
| Outro | last 0.9 s max −91.0 dB: silent tail, no jingle |
| Footage timing | B11, B13, B17 export frames match the source clips at 5%, 50% and 95% with 0-frame offset (mean abs diff ≤ 0.04): no retiming |
| Frames | every beat at 85% before export (`pre-sheet-*.png`) and at 60% of the export (`final-sheet-*.png`); every code beat at its deepest cue: all cued lines visible, labels legible, nothing clipped |
| B01 | "late" in terracotta at 60%; corrected to "ahead" by 85% |
| Footage labels | capture, excerpt and logged-value labels on every frame; replays and held frames labelled |
| Known limitation | figures inside GodotDesignFigure are inset (as in the A6 film); their smallest text (~25 px at 4K) is legible but small |

Not done: a human viewing with sound; no transcript check of the narration.
