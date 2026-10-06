# Gate V — visual QC report

Frames sampled: 28  ·  BLOCKER: 0  ·  MAJOR: 0

Regional text-contrast checks (all declared regions required): B06, B09. Whole-frame dimming/scene color is not text contrast; empty-frame, fill and declared safe-area checks remain active. Visual content review remains required.

Clean — no BLOCKER/MAJOR defects. ✓
---

## Re-export after the B02 crop, 2026-10-05

- **Change:** B02's held frame is cropped above the table curtain; label "Held frame · run-01, tick 90 · intro pan · cropped above the curtain".
- **GATE T** (audio-env Python): **PASS**. 12 PASS, 2 SKIP (B06, B09), 0 FAIL. Run before and after the export.
- **GATE V:** 28 frames, 0 BLOCKER, 0 MAJOR.
- **`./art godot-gamedev --check`:** PASS.
- **Final file:** SHA-256 `e7cdb04c15af0e4106ac6da03f08eb52ef642decf95af2f1108ea4869480d817` (matches the receipt), 3840×2160 at 30 fps, 267.567 s. B02 frame inspected from the final file.
- **Unchanged:** only B02 changed. The master audio is the same file (`93190deb…`), so the earlier audio and sync measurements still describe this export.
