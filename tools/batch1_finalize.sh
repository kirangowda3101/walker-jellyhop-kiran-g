#!/bin/bash
# Batch 1 finalize: approved edits, file copies, checksums, evidence, and log updates.
# Written by Claude at Kiran's request. Run from the project root:  bash tools/batch1_finalize.sh
# Raw outputs in ~/Documents/jellyhop-generations are read, never modified (checked below).
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
G="$HOME/Documents/jellyhop-generations"
OK=1
say() { printf '%s\n' "$*"; }
fail() { say "PROBLEM: $*"; OK=0; }

say "== 1. Raw outputs: present and unchanged since upload =="
while read -r sum name; do
  f="$G/$name"
  if [ ! -f "$f" ]; then fail "missing $name"; continue; fi
  got=$(shasum -a 256 "$f" | cut -d' ' -f1)
  [ "$got" = "$sum" ] && say "match   $name" || fail "checksum differs: $name"
done << 'SUMS'
f9a3786bd617961cecd4ff1ca0a56c9a47ee24c9771996763636476b2a98d143 CHAR-ANTIC-try1-seed7270-s50.png
7dd8bb87ea122f2cee8357c4dcc1f5643fd565e60a9d67bc966545dda142039a CHAR-BORED-try1-seed7270-s50.png
5cacef9ba4a137edd86805b666c89a3cfeb27b49bcbc33b2a277cc0221d34534 CHAR-CELEBRATE-try1-seed7270-s50.png
3ca186a8e1ac225e5537dd88c721b32264edc7ce7e6041509b19947b344583d6 CHAR-FALL-try1-seed7270-s50.png
279b34cad954799a960affb7205d5e6068f330c56caf2a739779dccdf7adec88 CHAR-LAND-try1-seed7270-s50.png
26805d1c706f6b182c469c2f98ffe65f9afeccb92f58594d10b934bb44a16db5 CHAR-RESPAWN-try1-seed7270-s50.png
bf1f0c4935c193fdecb827e0e2faaf47135dbe1d918180512c6715e347852db5 CHAR-RISE-try1-seed7270-s50.png
0b41486d41a860608c8265fff59b46dc4c9008366bd37b952498e43918b33f2b CHAR-SCOOT-A-try1-seed7270-s50.png
2e37f99e525156cb85d94c388aa035d8a405a64eb42a9f3297ba865cc51fb52d CHAR-SPLAT-try1-seed7270-s50.png
7fc036893b55c389ff165a900df5f0527769f119b54a0001b0b0754e9a04b19b CHAR-WORRY-try1-seed7270-s50.png
SUMS
[ "$OK" = 1 ] || { say "Stopping: fix the problems above first."; exit 1; }

say ""
say "== 2. Earlier edits still reproduce with the updated remove_specks.py =="
fp() { grep "fingerprint" | awk '{print $NF}'; }
check() { [ "$1" = "$2" ] && say "match   $3 $1" || fail "$3 fingerprint $1, expected $2"; }
check "$(python3 tools/remove_specks.py "$G/CHAR-REF-B-seed7270-s60.png" /tmp/chk1.png 660 334 696 373 559 345 603 390 | fp)" 5fbc3cce005d71c8 "CHAR-REF edit"
check "$(THRESH=15 GROW=6 FILL=smooth python3 tools/remove_specks.py "$G/CHAR-SCOOT-B-try2-seed7270-s50.png" /tmp/chk2.png 356 664 414 721 461 659 519 716 568 658 626 710 652 668 705 719 | fp)" 023e9bea89d15c77 "CHAR-SCOOT-B edit"

say ""
say "== 3. Approved edits (new -edited files; raws untouched) =="
edit() {  # name, expected fingerprint, env settings, boxes...
  local n="$1" exp="$2" envs="$3"; shift 3
  local out
  out=$(env $envs python3 tools/remove_specks.py "$G/$n-try1-seed7270-s50.png" "$G/$n-try1-seed7270-s50-edited.png" "$@") || { fail "$n edit stopped: $out"; return; }
  check "$(printf '%s\n' "$out" | fp)" "$exp" "$n edit"
}
edit CHAR-ANTIC   83396e0809c00898 "SELECT=pink GROW=2 FILL=smooth"   515 643 571 669
edit CHAR-RISE    187179dc273b9474 "THRESH=15 GROW=6 FILL=smooth"     559 334 607 390 514 166 549 223 582 166 613 234
edit CHAR-FALL    54b4e53be8c9de4f "THRESH=15 GROW=6 FILL=smooth"     336 410 410 483 653 395 719 465 550 337 610 398 287 487 348 542 266 381 322 436 711 410 765 462 659 555 710 601
edit CHAR-WORRY   309ac423825dd995 "THRESH=30 GROW=5 FILL=smooth"     598 248 674 309 578 282 634 319
edit CHAR-RESPAWN 71af26165dcead5f "THRESH=15 GROW=6 FILL=smooth"     498 598 565 667

say ""
say "== 4. Accepted poses into art/poses, raw thumbnails, evidence =="
mkdir -p art/poses art/source art/rejected evidence
for n in CHAR-ANTIC CHAR-RISE CHAR-FALL CHAR-WORRY CHAR-RESPAWN; do
  cp "$G/$n-try1-seed7270-s50-edited.png" "art/poses/$n.png"
  sips -Z 256 "$G/$n-try1-seed7270-s50.png" --out "art/source/$n-try1-raw-seed7270-s50-thumb.png" > /dev/null
done
for n in CHAR-BORED CHAR-LAND CHAR-CELEBRATE CHAR-SPLAT; do
  cp "$G/$n-try1-seed7270-s50.png" "art/poses/$n.png"
done
cp art/reference/CHAR-REF.png art/poses/CHAR-IDLE.png
sips -Z 256 "$G/CHAR-SCOOT-A-try1-seed7270-s50.png" --out "art/rejected/CHAR-SCOOT-A-try1-seed7270-s50-thumb.png" > /dev/null
for p in "CHAR-ANTIC 50" "CHAR-RISE 80" "CHAR-FALL 60" "CHAR-WORRY 66" "CHAR-RESPAWN 40"; do
  set -- $p
  low=$(printf '%s' "${1#CHAR-}" | tr 'A-Z' 'a-z')
  TARGET_H=$2 python3 tools/check_64px.py "evidence/char-$low-cleanup.png" "$G/$1-try1-seed7270-s50.png" "$G/$1-try1-seed7270-s50-edited.png" > /dev/null
done
if [ -f "$HOME/Downloads/batch1-review.png" ]; then mv "$HOME/Downloads/batch1-review.png" evidence/batch1-review.png; else fail "batch1-review.png not found in Downloads"; fi
ls art/poses

say ""
say "== 5. Raws unchanged after the edits; checksums file =="
{
  echo "# Batch 1 checksums (SHA-256), written by tools/batch1_finalize.sh"
  echo "## Raw outputs (~/Documents/jellyhop-generations)"
  (cd "$G" && shasum -a 256 CHAR-*-try1-seed7270-s50.png)
  echo "## Edited outputs"
  (cd "$G" && shasum -a 256 CHAR-*-try1-seed7270-s50-edited.png)
  echo "## Accepted poses (art/poses)"
  shasum -a 256 art/poses/*.png
} > evidence/batch1-checksums.txt
while read -r sum name; do
  got=$(shasum -a 256 "$G/$name" | cut -d' ' -f1)
  [ "$got" = "$sum" ] || fail "raw changed after edits: $name"
done << 'SUMS'
f9a3786bd617961cecd4ff1ca0a56c9a47ee24c9771996763636476b2a98d143 CHAR-ANTIC-try1-seed7270-s50.png
bf1f0c4935c193fdecb827e0e2faaf47135dbe1d918180512c6715e347852db5 CHAR-RISE-try1-seed7270-s50.png
3ca186a8e1ac225e5537dd88c721b32264edc7ce7e6041509b19947b344583d6 CHAR-FALL-try1-seed7270-s50.png
7fc036893b55c389ff165a900df5f0527769f119b54a0001b0b0754e9a04b19b CHAR-WORRY-try1-seed7270-s50.png
26805d1c706f6b182c469c2f98ffe65f9afeccb92f58594d10b934bb44a16db5 CHAR-RESPAWN-try1-seed7270-s50.png
SUMS
say "wrote evidence/batch1-checksums.txt"

say ""
say "== 6. Log updates =="
if grep -q "## Batch 1 — remaining poses" ASSET-LOG.md; then say "ASSET-LOG.md already has Batch 1 (skipped)"; else
cat >> ASSET-LOG.md << 'LOG'

## Batch 1 — remaining poses (BORED, SCOOT-A, ANTIC, RISE, FALL, LAND, WORRY, CELEBRATE, SPLAT, RESPAWN)

- **Guides:** `tools/make_pose_guides.py` (commit `d0199e8`, committed before any batch generation). Shapes and faces follow CHARACTER-SHEET.md; every body pixel comes from CHAR-REF. Neutral faces reuse CHAR-REF's face; expression poses reuse CHAR-REF's eye pixels where the sheet keeps dot eyes and draw the sheet's brows, mouths, lids, closed eyes, or X eyes in CHAR-REF's face color `#0F3236` at its smile's stroke width (23 px). Splat and re-form reshape CHAR-REF column by column ("9-slice") to the sheet's outline; splat droplets are the whole CHAR-REF body scaled down; re-form drip marks are left out.
- **Guide pixel fingerprints (as built on my Mac):** BORED `e71b217d8e64d2ae`, SCOOT-A `a1d43047a1576b80`, ANTIC `81e27d52c8d9f4f8`, RISE `3817ab9dac3b451e`, FALL `59130cf7272c3808`, LAND `8be9f7560d5b5741`, WORRY `4c1b50993c5d6cae`, CELEBRATE `e2db31c27e3b736a`, SPLAT `246f33971f69869f`, RESPAWN `d095f24919a5030c`. Nine match Claude's preview build; SCOOT-A differs from the preview (`c89367734f6e8970`), cause not confirmed.
- **Settings for every try 1:** the CHAR-REF prompt and negative prompt, SDXL Base (v1.0) in Draw Things 26.0924.0, 1024 × 1024, seed 7270, 30 steps, text guidance 7.0, DPM++ 2M AYS, shift 1.00, image to image at 50% from the pose's guide.
- **CHAR-IDLE:** CHAR-REF itself (the sheet's idle pose is the resting cube); `art/poses/CHAR-IDLE.png` is a copy of `art/reference/CHAR-REF.png`. No new generation.
- **Shapes:** every try 1 result's outer box is within 1 game px of its guide's.
- **Edit tool:** `tools/remove_specks.py`, now also with `SELECT=pink` (only pinkish pixels) and a stop if a box leaves no untouched pixels around a mark. Re-running the CHAR-REF and CHAR-SCOOT-B edits with it gave their original fingerprints (`5fbc3cce005d71c8`, `023e9bea89d15c77`).
- **Raw output checksums (SHA-256):** see the table. File checksums of every accepted pose: `evidence/batch1-checksums.txt`. Before-and-after at each pose's height: `evidence/char-<pose>-cleanup.png`. Batch review sheet: `evidence/batch1-review.png`.

| Pose | Raw output (checksum) | Observed in raw output | Edit (tool settings and boxes) | Edit fingerprint | Outcome |
|------|-----------------------|------------------------|--------------------------------|------------------|---------|
| CHAR-BORED | `CHAR-BORED-try1-seed7270-s50.png` (`7dd8bb87…039a`) | Matches the guide; a faint smudge left of the left eye | None (a test cleanup left a visible rectangle in the low-contrast area and was dropped) | — | Accepted as-is; smudge documented |
| CHAR-SCOOT-A | `CHAR-SCOOT-A-try1-seed7270-s50.png` (`0b41486d…3f2b`) | Shape matches; the mouth became a wavy "w"; two large soft patches beside the eyes | None | — | Rejected; retried with seed 7271 (try 2 row added after review) |
| CHAR-ANTIC | `CHAR-ANTIC-try1-seed7270-s50.png` (`f9a3786b…d143`) | Brows and eyes match; a pink tongue under the mouth (off-palette, close to magenta) | `SELECT=pink GROW=2 FILL=smooth`, box 515 643 571 669 | `83396e0809c00898` | Accepted after edit; a soft dark shadow remains under the mouth |
| CHAR-RISE | `CHAR-RISE-try1-seed7270-s50.png` (`bf1f0c49…52db5`) | Shape and face match; a teardrop "nose" between the eyes and two drips under the highlight | `THRESH=15 GROW=6 FILL=smooth`, boxes 559 334 607 390 · 514 166 549 223 · 582 166 613 234 | `187179dc273b9474` | Accepted after edit; faint drip tops remain at the highlight's edge |
| CHAR-FALL | `CHAR-FALL-try1-seed7270-s50.png` (`3ca186a8…83d6`) | Shape and face match; seven raised bubbles on the face | `THRESH=15 GROW=6 FILL=smooth`, boxes 336 410 410 483 · 653 395 719 465 · 550 337 610 398 · 287 487 348 542 · 266 381 322 436 · 711 410 765 462 · 659 555 710 601 | `54b4e53be8c9de4f` | Accepted after edit |
| CHAR-LAND | `CHAR-LAND-try1-seed7270-s50.png` (`279b34ca…ec88`) | Matches the guide | None | — | Accepted as-is |
| CHAR-WORRY | `CHAR-WORRY-try1-seed7270-s50.png` (`7fc03689…b19b`) | Shape and face match; two light bubbles near the top right; faint dots at the band's corners | `THRESH=30 GROW=5 FILL=smooth`, boxes 598 248 674 309 · 578 282 634 319 (a first, larger box clipped the right brow and was redone) | `309ac423825dd995` | Accepted after edit; band corner dots documented |
| CHAR-CELEBRATE | `CHAR-CELEBRATE-try1-seed7270-s50.png` (`5cacef9b…4534`) | Matches the guide; faint dots in the band, barely visible at game size | None | — | Accepted as-is; band dots documented |
| CHAR-SPLAT | `CHAR-SPLAT-try1-seed7270-s50.png` (`2e37f99e…b52d`) | Matches the guide's outline and X eyes; droplets rendered as tiny rounded cubes | None | — | Accepted as-is |
| CHAR-RESPAWN | `CHAR-RESPAWN-try1-seed7270-s50.png` (`26805d1c…6db5`) | Shape and eyes match; a small mouth-like mark (the sheet shows eyes only); the thin puddle reads mostly as outline | `THRESH=15 GROW=6 FILL=smooth`, box 498 598 565 667 | `71af26165dcead5f` | Accepted after edit |

- **Where used:** `art/poses/<POSE>.png`, each pose's in-game frame, drawn facing right and flipped at runtime.
LOG
say "appended Batch 1 to ASSET-LOG.md"; fi
if grep -q "## 2026-10-02 — Batch 1: remaining poses" FRICTIONAL.md; then say "FRICTIONAL.md already has Batch 1 (skipped)"; else
cat >> FRICTIONAL.md << 'LOG'

---

## 2026-10-02 — Batch 1: remaining poses

**Status (confirmed):** ten poses generated from guides committed in `d0199e8`; nine accepted (four as-is, five after logged edits); Scoot A try 1 rejected and retried with seed 7271 (outcome recorded after review). CHAR-IDLE is CHAR-REF itself. Details, boxes, and fingerprints: ASSET-LOG.md, Batch 1.

**Workflow change (my instruction):** from this batch on, work proceeds in complete batches: Claude makes routine choices from the approved design and settings, asks me only about significant design changes, and we review assets once per batch; logs record decisions, observations, edits, and results only.

**Design decisions:**
- **Expression poses:** I approved the hybrid: warp CHAR-REF's body, reuse its eye pixels where the sheet keeps dot eyes, and draw the sheet's brows, mouths, lids, and closed or X eyes in CHAR-REF's face color.
- **Splat and re-form:** reshape or mask the actual CHAR-REF body and texture, using the sheet as the shape guide. Sampling its colors alone wouldn't clearly demonstrate that those poses were derived from the accepted reference.
- **Backgrounds:** magenta only for isolated sprites; ENV-ROOM and the repeating ENV-TABLE strip get their intended backgrounds and surfaces, with the table strip checked for seamless repetition (Batch 2).
- **Scoot A:** retry once with seed 7271, everything else unchanged.

**Routine choices made by Claude (from the approved design):** CHAR-IDLE = CHAR-REF; every pose at 50% with the CHAR-SCOOT-B settings; face strokes at CHAR-REF's smile width (23 px), so the sheet's small "o" mouths render nearly filled; re-form drip marks left out of the guide; tight-box edits with the smooth fill; marks barely visible at game size left in place and documented.

**Prediction (written before generating; mine):** "I expect most poses to preserve CHAR-REF's colors and texture while following the guides' shapes. Splat, re-form, and the expression poses seem most likely to drift, so I'll check their silhouettes and facial readability at their intended game sizes."

**What came back:** colors, texture, and shapes held across all ten; every outer box is within 1 game px of its guide, splat and re-form included. The drift appeared as added marks and face changes: bubbles on falling, a teardrop nose and drips on rising, bubbles on worried, a pink tongue on crouch, a mouth-like mark on re-form, and on Scoot A a wavy mouth and two large soft patches. Landing and splat came back clean.

**Inspect and revise:**
- Two of Claude's cleanup tests failed and were redone or dropped before review: on worried, a first box clipped the right brow (redone with two boxes clear of it); on bored, the fill left a visible rectangle in a low-contrast area (dropped; the smudge is documented instead).
- Crouch's tongue sits against the dark mouth, so a new pink-only selection removes it without touching the mouth line; a soft dark shadow remains under the mouth.
- The edit tool now stops if a box leaves no untouched pixels around a mark; this caught boxes on falling and re-form that were too tight, which were widened.
- The earlier CHAR-REF and CHAR-SCOOT-B edits still reproduce their fingerprints with the updated tool.
- I approved the handling for the nine poses, with the remaining minor marks documented, after one batch review (`evidence/batch1-review.png`).

**Human / Claude / model:**
- **Kiran:** set the batch workflow; approved the hybrid; directed that splat and re-form reshape CHAR-REF's actual body and that magenta is for isolated sprites only; wrote the batch prediction; ran all ten generations and the batch script on my Mac; approved the nine-pose handling; chose the Scoot A retry.
- **Claude:** wrote `make_pose_guides.py`, the `SELECT=pink` option and safety stop in `remove_specks.py`, and the batch script; measured every result against its guide; located the marks; tested, revised, or dropped cleanups; drafted the asset log rows and this entry.
- **Model (SDXL Base 1.0):** produced the ten raw outputs, including the added marks listed above.

**Still unresolved:**
- Scoot A (try 2 pending review).
- Documented minor marks: bored smudge, relief and worried band dots, rising drip tops, crouch's shadow under the mouth.
- The SCOOT-A guide fingerprint differs between my Mac and Claude's preview build; cause not confirmed.
- Background removal and fringe checks for all sprites; environment art, audio, the Godot slice, testing, and the film.

**Traceability:** commit `d0199e8` (guides); ASSET-LOG.md Batch 1; `evidence/batch1-review.png`, `evidence/char-<pose>-cleanup.png`, `evidence/batch1-checksums.txt`; raw thumbnails in `art/source/` and `art/rejected/`.
LOG
say "appended Batch 1 entry to FRICTIONAL.md"; fi

say ""
say "== 7. Scoot A try 2 =="
S2="$G/CHAR-SCOOT-A-try2-seed7271-s50.png"
if [ -f "$S2" ]; then
  say "found; checksum $(shasum -a 256 "$S2" | cut -d' ' -f1)"
  TARGET_H=56 python3 tools/check_64px.py evidence/char-scoot-a-56px-compare.png gen-inputs/pose-guide-CHAR-SCOOT-A.png "$G/CHAR-SCOOT-A-try1-seed7270-s50.png" "$S2"
else
  fail "CHAR-SCOOT-A-try2-seed7271-s50.png not found yet"
fi

say ""
[ "$OK" = 1 ] && say "ALL CHECKS PASSED. Review: git diff --stat, then upload CHAR-SCOOT-A-try2 and this output." || say "SOME CHECKS NEED ATTENTION (see PROBLEM lines above)."
