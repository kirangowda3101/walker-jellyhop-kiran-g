# A5 interface sweep notes (HUMAN CHECK)

Looked at by Kiran Gowda, 2026-10-28: the 15 scripted in-engine captures `evidence/a5-captures/sweep_table_*.png` (Compatibility; worn dinner table, Sun only, no ambient). My observations, in my own words:

| Uniform | Values captured | What I saw | Broken look? |
|---|---|---|---|
| `brightness` | 0.0, 1.0, 2.0 | Yes, the wood goes from dark to bright | none reported |
| `roughness_scale` | 0.0, 0.5, 1.0 | I feel they all look the same | none reported |
| `normal_strength` | 0.0, 1.0, 2.0 | They all look the same actually | none reported |
| `uv_scale` | 0.25, 1.0, 8.0 | Yes, the pattern gets smaller and more repeated | none reported |
| `tint` | black, (1, 0.85, 0.7), white | Yes: black, then warm, then normal | none reported |

**Measured with a pixel difference** (PIL, whole frame, Compatibility captures):

| Pair | Largest per-pixel difference (0–255) | Pixels changed by more than 3 |
|---|---|---|
| `brightness` 0.0 vs 2.0 | 159 | 16.2% |
| `roughness_scale` 0.0 vs 1.0 | 20 | 15.9% |
| `normal_strength` 0.0 vs 2.0 | 2 | 0.0% |

**What this means:**
- `roughness_scale` does change the whole table, but gently (at most 20 levels, spread evenly), which is why it looked the same to me. My §7 prediction of "a sharp Sun highlight toward 0" did **not** hold in this view: with the Sun as the only light and nothing around to reflect (Revision 4), no highlight lands where the camera looks.
- `normal_strength` has no visible or measurable effect here (at most 2 levels). Likely reason, **not tested**: the Dark Wood normal map is very flat, which is consistent with the curl calibration's drift toward 1 (Revision 3).
- `brightness`, `uv_scale` and `tint` behave as predicted.
