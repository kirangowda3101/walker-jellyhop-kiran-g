# TYPECHECK.md — GATE T

Reel: `claude-liam-jelly-hop-a3`  |  Checked: 2026-10-13T04:22  |  Overall: **FAIL**  |  Beats checked: 15  |  FAILs: 4

Spec: `skills/make/kerning/reference/type-spec.md` §8.  Floor: 1.9% frame-height.  Contrast: 4.5:1 WCAG.  Kern threshold: 3.5× expected advance.  Wordy budget: 2 elements.

| beat | lane | polarity | worst finding | status | fix |
|------|------|----------|---------------|--------|-----|
| B00 | ? | light | min-size §8.1: hand-drawn pattern (ClaudeComposerAsk) — §8.1 hachure/crossbar fragments ar… | PASS | — |
| B01 | ? | light | min-size §8.1: min text-run height 84px >= floor 41px (individual-char fallback at 2×) | PASS | — |
| B02 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B03 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B04 | ? | light | contrast-local §8.3b: per-blob contrast 1.58:1 < 3.0:1 — text unreadable on actual local b… | **FAIL** | Use INK on cream; add backing plate under accent text |
| B05 | ? | light | contrast-local §8.3b: per-blob contrast 1.62:1 < 3.0:1 — text unreadable on actual local b… | **FAIL** | Use INK on cream; add backing plate under accent text |
| B06 | ? | light | no-wordy-card §8.5: pull-quote (6 words ≤ 12) | PASS | — |
| B07 | ? | light | contrast-local §8.3b: per-blob contrast 1.62:1 < 3.0:1 — text unreadable on actual local b… | **FAIL** | Use INK on cream; add backing plate under accent text |
| B08 | ? | light | no-wordy-card §8.5: pull-quote (6 words ≤ 12) | PASS | — |
| B09 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B10 | ? | light | no-wordy-card §8.5: pull-quote (12 words ≤ 12) | PASS | — |
| B11 | ? | light | no-wordy-card §8.5: prose element 'output[0]': 14 words > 12 pull-quote limit. The screen … | **FAIL** | De-wordify → Manim diagram or Remotion build-on |
| BVDT | ? | light | min-size §8.1: hand-drawn pattern (ClaudeVerdictArtifact) — §8.1 hachure/crossbar fragment… | PASS | — |
| BHTF | ? | light | min-size §8.1: hand-drawn pattern (ClaudeComposerAsk) — §8.1 hachure/crossbar fragments ar… | PASS | — |
| BOUT | ? | light | min-size §8.1: min text-run height 43px >= floor 41px | PASS | — |

---

## Failures requiring action before cut

### B04 (?)
- **contrast-local §8.3b**: per-blob contrast 1.58:1 < 3.0:1 — text unreadable on actual local background (blob@(1965,555)–(2265,741) fg≈(43, 43, 43) bg≈(74, 73, 72)); move label off its background or change text color
- **Fix:** Use INK on cream; add backing plate under accent text

### B05 (?)
- **contrast-local §8.3b**: per-blob contrast 1.62:1 < 3.0:1 — text unreadable on actual local background (blob@(2237,716)–(2343,762) fg≈(79, 81, 86) bg≈(46, 50, 58)); move label off its background or change text color
- **Fix:** Use INK on cream; add backing plate under accent text

### B07 (?)
- **contrast-local §8.3b**: per-blob contrast 1.62:1 < 3.0:1 — text unreadable on actual local background (blob@(1065,664)–(2905,1607) fg≈(71, 68, 63) bg≈(101, 99, 97)); move label off its background or change text color
- **bbox-overlap §8.6b**: text-run bbox overlap 100% >= 10% — two labels are printing on top of each other: blob@(923,552)–(2916,1607) ∩ blob@(1065,664)–(2905,1607) (100% of smaller); separate label positions in scenes.py or Remotion component | §8.6c ADVISORY: possible fused run(s) — blob@(923,552)–(2916,1607) h=1055px (2.0×med)
- **Fix:** Use INK on cream; add backing plate under accent text

### B11 (?)
- **no-wordy-card §8.5**: prose element 'output[0]': 14 words > 12 pull-quote limit. The screen should show structure, not sentences. De-wordify: shorten to a label or rebuild beat as a Manim/Remotion visual.
- **Fix:** De-wordify → Manim diagram or Remotion build-on

---

## Check summary

| Check | Beats checked | FAILs |
|-------|---------------|-------|
| no-wordy-card §8.5 | 10 | 1 |
| min-size §8.1 | 15 | 0 |
| overflow §8.2 | 15 | 0 |
| contrast §8.3 | 15 | 0 |
| contrast-local §8.3b | 15 | 3 |
| bbox-overlap §8.6b | 15 | 1 |
| card-clip §8.13 | 15 | 0 |
| kerning §8.4 | 0 | 0 |
| redundancy §8.10 (advisory) | 1 | 0 (advisory — no exit effect) |

---

*GATE T: any FAIL blocks `./art run` and `./art final`. Fix the flagged beats and re-run `scripts/type_check.py` until green.*
