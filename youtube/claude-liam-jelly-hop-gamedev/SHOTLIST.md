# SHOTLIST — Jelly Hop: Fork From Above

Landscape 3840×2160 at 30 fps. Remotion scenes are rendered at `--scale=2` from 1920×1080 compositions; gameplay is native 4K engine capture. Beat order is fixed by `beat_sheet.json`.

| Beat | Kind | Visual | Label on screen | Evidence |
|---|---|---|---|---|
| B00 | Remotion `ClaudeComposerAsk` | composer; the Walker prompt (worded from CONCEPT.md) types itself; 3 output lines | "Illustrative reconstruction of the ask… Not a saved transcript." | CONCEPT.md |
| B01 | Remotion `BrutalistHesitantWriter` | 3-line overview; "The shadow gives the warning. / The scrape plays as shadows grow." → corrected word by word to "The scrape plays as forks descend."; ≥ 9 s, lead silence 0.8 s | — | CONCEPT.md, audition notes |
| B02 | Remotion `GodotDesignFigure` | held frame of the intro pan + 4 pillar cards lit in turn | "Held frame · run-01, tick 90 · intro pan · cropped above the curtain" + capture label | images/B02 |
| B03 | Remotion `GodotDesignFigure` | design guide → prompt + settings → raw SDXL output | "Raw generation · not in-engine footage"; "Raw output (not in-engine)", "unedited" | images/B03 |
| B04 | Remotion `GodotDesignFigure` | raw 4× zoom with speck boxes → cleaned → cut-out → 1:1 engine crop | "boxes added"; "In engine, 4K capture · run-01, tick 303, crop at 1:1" | images/B04 |
| B05 | Remotion `GodotDevWorkbench` (code) | `player.gd` 149–162 (the branches of `choose_pose()`), line highlights on the narration | "Godot editor reconstruction · source-backed teaching view" | excerpt (checked) |
| B06 | **Gameplay** `media/B06.mp4` | run-01 ticks 241–961, 12.0 s, normal speed | capture label + "pose: NAME (from the input log)" | code → result pair 1 |
| B07 | Remotion `GodotDevWorkbench` (code) | `session.gd` 294–301; notes: the pre-`23ae39c` line, Kiran's audition note | editor-reconstruction banner; "Source notes — git show 23ae39c" | excerpt (checked) |
| B08 | Remotion `GodotDesignFigure` | 3 capture frames (shadow, descent + SFX-WARN, hit) + measured scrape counts | "3 frames from run-01 · counts from the Batch 3 audio traces" + capture label | code → result pair 2 |
| B09 | **Gameplay with slice audio** `media/B09.mp4` | 3 excerpts, 11.73 s, cuts marked by their excerpt labels; all 6 sound events; the captures' own engine audio via the premixed master, no narration | "Slice audio · no narration · scripted-input capture"; "excerpt N of 3 · take · ticks"; event ID + tick at each sound | premix, Kiran's decision (FACTCHECK.md) |
| B10 | Remotion `GodotDevWorkbench` (trace) | suite output lines; Kiran's playtest notes | "Output — tools/run_slice_checks.sh (automated)"; "Human playtest — Kiran's notes"; "Automated checks are not a playtest." | BUILD-LOG, TEST-REPORT |
| BVDT | Remotion `ClaudeVerdictArtifact` | 8 lines: works / tested / uncertain / art / models / Kiran / Claude chat and Claude Code / next (Kiran's words) | — | FACTCHECK |
| BHTF | Remotion `ClaudeComposerAsk` | "Your turn." prompt typed, read aloud | — | — |
| BOUT | Remotion `ClaudeTitleOutro` | exact title, @NikBearBrown, slug-seeded mascot; spoken title + "At Nik Bear Brown"; 1 s silent tail; no game audio | — | OUTRO-LOCK.md |

Held frames: B02 (labeled). Reconstructed interface views: B00, BHTF (the Claude composer, labeled reconstruction in B00), B05, B07, B10 (labeled Godot editor reconstruction). Scripted-input captures: B02, B04 panel d, B06, B08 frames, B09 (all labeled). No raw generation is presented as in-engine footage: B03's raw panel is labeled "not in-engine".
