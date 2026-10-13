# Gate V — visual QC report

Frames sampled: 30  ·  BLOCKER: 0  ·  MAJOR: 0

Clean — no BLOCKER/MAJOR defects. ✓

---

# Claude Code's QC of the final export (rebuilt 2026-10-13 after Kiran's script review)

The Gate V section above is rewritten by every `./art final`; this section was re-added afterwards for the current file, `exports/landscape/claude-liam-jelly-hop-a3.mp4` (SHA-256 `10adb47d931ffa23d500f409658eee709397dcc48303ae61805a62aadfe599fc`). The earlier QC section described the superseded overnight export `825ce7bf…`.

| Check | Result |
|---|---|
| GATE V (inside `./art final`) | 30 frames, 0 BLOCKER, 0 MAJOR (above) |
| GATE T (`type_check.py`, jellyhop-audio-env Python) | PASS, 0 FAIL, before the export (`gate-t-6.log`) and after it (`gate-t-7.log`) |
| `./art godot-gamedev --check` at handoff | PASS: 13 files, 63 exclusions, 4 components, 2 exact excerpts, 2 code → result pairs |
| Streams | h264 3840×2160 30 fps; AAC; 284.133 s = timeline; receipt ready, SHA-256 matches |
| Per-beat audio | all 15 beats narrated; means −26.0 to −27.9 dB, peaks −4.4 to −9.5 dB |
| Outro | last 0.9 s max −91.0 dB: silent tail, no jingle |
| B05 correction | Slip card read in an exported frame: "wrong field → blue". Local faster-whisper transcript of the B05 narration: "…a value went into the wrong field and the cherry turned blue…" |

Not done: a human viewing with sound (Kiran's review).
