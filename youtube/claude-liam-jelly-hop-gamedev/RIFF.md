# RIFF — observations on the captures (riff skill format)

Observed in the actual frames and logs (Claude Code inspected the extracted frames and the input logs on 2026-10-03). These are observations of scripted-input runs, not judgments of feel or fun; those are Kiran's.

| Artifact + time range | Visible observation | Interpretation and source | Narration (draft) | Suggested next experiment |
|---|---|---|---|---|
| run-01 ticks 241–961 (B06) | Scoot frames alternate while moving; ANTIC → RISE → FALL → LAND on each hop; WORRY on plate 2 from tick 388; IDLE at 470 as the fork starts down; SPLAT at 477 (log); RESPAWN; control back at 554 | `choose_pose()` priority (`player.gd:147–163`); worry follows only the SHADOW phase (`session.gd:390`), so the face relaxes during the strike itself (IDLE, ticks 470–476 in the log) | "Watch the label at the bottom…" | Ask a second player whether the relaxed face during the strike reads as wrong; it could be held as WORRY through DOWN |
| run-01 ticks 439 / 469 / 476 (B08) | Shadow on plate 2 with the jelly worried; the fork starts down at 469 with SFX-WARN in the log; the tines land at 476 | The `23ae39c` trigger (`session.gd:295–299`); 7 ticks (0.117 s) between scrape and hit match the Batch 3 trace's 7 ticks | "In our capture, the scrape fires at tick four sixty-nine…" | Kiran's Your Turn: predict a tick, then trace it |
| run-01 1001–1211 and run-02 123–297 (B09) | Last hop, the dome slide, WIN; a walk-off into the sauce gives SPLAT-SAUCE (shake not checked frame by frame) | The game shakes only on a fork splat (STORYBOARD decision 4; `shake-none-on-sauce-splat` test) | none (slice audio) | — |
| run-01 tick 90 (B02) | Intro pan with title and "any key skips the intro"; forks frozen | `intro-shows-shadows-frozen` test | "This is a held frame from the intro pan." | — |

Separated from these observations: the code explanations (COMPONENTS.md) and the claims about tests (FACTCHECK.md). Nothing here claims a human played these runs.
