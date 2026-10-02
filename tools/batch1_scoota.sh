#!/bin/bash
# Batch 1, last part: Scoot A try 2 edit, file copies, log corrections, then one commit and push.
# Written by Claude at Kiran's request. Run from the project root:  bash tools/batch1_scoota.sh
set -euo pipefail
trap 'echo "STOPPED: a command failed (line $LINENO): $BASH_COMMAND" >&2' ERR
cd "$(git rev-parse --show-toplevel)"
G="$HOME/Documents/jellyhop-generations"
OK=1
say() { printf '%s\n' "$*"; }
fail() { say "PROBLEM: $*"; OK=0; }
fp() { grep "fingerprint" | awk '{print $NF}'; }
stop_if_problems() { if [ "$OK" != 1 ]; then say "Stopping: $1"; exit 1; fi; }

say "== 1. Inputs =="
RAW="$G/CHAR-SCOOT-A-try2-seed7271-s50.png"
[ "$(shasum -a 256 "$RAW" | cut -d' ' -f1)" = c4d6026d1d60f3db549cf1f3e27575304ab0c83a766f7b9be5c6ab55c1585d82 ] && say "match   try 2 raw" || fail "try 2 raw checksum differs"
[ -f evidence/batch1-review.png ] && say "present evidence/batch1-review.png" || fail "evidence/batch1-review.png missing"
grep -q "## Batch 1 — remaining poses" ASSET-LOG.md && grep -q "## 2026-10-02 — Batch 1: remaining poses" FRICTIONAL.md && say "present Batch 1 log sections" || fail "Batch 1 log sections missing; run tools/batch1_finalize.sh first"
stop_if_problems "fix the problems above first."

say ""
say "== 2. Edit: remove the curls at the eyes' outer edges =="
if ! OUT=$(GROW=3 FILL=smooth python3 tools/remove_specks.py "$RAW" "$G/CHAR-SCOOT-A-try2-seed7271-s50-edited.png" 430 491 468 530 704 489 746 523); then
  fail "edit stopped: $OUT"; stop_if_problems "the edit did not complete."
fi
GOT=$(printf '%s\n' "$OUT" | fp) || GOT="(none)"
[ "$GOT" = cb0e787580f8e49e ] && say "match   CHAR-SCOOT-A edit $GOT" || fail "edit fingerprint $GOT, expected cb0e787580f8e49e"
[ "$(shasum -a 256 "$RAW" | cut -d' ' -f1)" = c4d6026d1d60f3db549cf1f3e27575304ab0c83a766f7b9be5c6ab55c1585d82 ] || fail "raw changed after edit"
stop_if_problems "the edit did not match."

say ""
say "== 3. Files and evidence =="
cp "$G/CHAR-SCOOT-A-try2-seed7271-s50-edited.png" art/poses/CHAR-SCOOT-A.png
sips -Z 256 "$RAW" --out art/source/CHAR-SCOOT-A-try2-raw-seed7271-s50-thumb.png > /dev/null
TARGET_H=56 python3 tools/check_64px.py evidence/char-scoot-a-56px-compare.png gen-inputs/pose-guide-CHAR-SCOOT-A.png "$G/CHAR-SCOOT-A-try1-seed7270-s50.png" "$RAW" "$G/CHAR-SCOOT-A-try2-seed7271-s50-edited.png" > /dev/null
{
  echo "## Scoot A try 2"
  (cd "$G" && shasum -a 256 CHAR-SCOOT-A-try2-seed7271-s50.png CHAR-SCOOT-A-try2-seed7271-s50-edited.png CHAR-SCOOT-A-try2-INVALID-identical-to-try1.png)
  shasum -a 256 art/poses/CHAR-SCOOT-A.png
} >> evidence/batch1-checksums.txt
N=$(ls art/poses/*.png | wc -l | tr -d ' ')
[ "$N" = 12 ] && say "12 pose files in art/poses" || fail "expected 12 pose files in art/poses, found $N"
[ -s evidence/char-scoot-a-56px-compare.png ] || fail "evidence/char-scoot-a-56px-compare.png was not written"
stop_if_problems "files or evidence incomplete."

say ""
say "== 4. Log corrections and the Scoot A try 2 row =="
python3 - << 'PY'
import sys
def fix(path, pairs, append=None):
    s = open(path, encoding="utf-8").read()
    for old, new in pairs:
        if new in s:
            continue
        if s.count(old) != 1:
            sys.exit(f"{path}: expected text not found exactly once: {old[:60]}")
        s = s.replace(old, new)
    if append and append.strip().splitlines()[0] not in s:
        s = s.rstrip("\n") + "\n" + append
    open(path, "w", encoding="utf-8").write(s)
    print("updated", path)

fix("ASSET-LOG.md", [
 ("Nine match Claude's preview build; SCOOT-A differs from the preview (`c89367734f6e8970`), cause not confirmed.",
  "Nine match Claude's preview build; SCOOT-A differs from the preview (`c89367734f6e8970`) only in 2,008 outline-edge pixels, each by at most 2 of 255 levels, with the face in the identical position (likely slightly different edge blending in the two machines' image libraries)."),
 ("| Rejected; retried with seed 7271 (try 2 row added after review) |", "| Rejected; retried with seed 7271 (next section) |"),
], append="""
### CHAR-SCOOT-A try 2 — seed 7271

- **Settings:** the same as try 1 except seed 7271; guide `gen-inputs/pose-guide-CHAR-SCOOT-A.png` (commit `d0199e8`).
- **First export, set aside:** pixel-identical to try 1 (the seed change had not taken effect, or an older history entry was exported). Kept outside the repo as `CHAR-SCOOT-A-try2-INVALID-identical-to-try1.png`; not used.
- **Raw output:** `CHAR-SCOOT-A-try2-seed7271-s50.png` (checksum `c4d6026d1d60f3db549cf1f3e27575304ab0c83a766f7b9be5c6ab55c1585d82`), confirmed different from try 1 · thumbnail `art/source/CHAR-SCOOT-A-try2-raw-seed7271-s50-thumb.png`
- **Observed:** shape matches (character box 721 × 524 px; guide 723 × 525). The mouth matches the guide's (CHAR-REF's small smile); no side patches. New: a curved stroke extending from the outer bottom edge of each eye (x 440–470, y 501–520 and x 702–736, y 499–513).
- **Edit:** `GROW=3 FILL=smooth python3 tools/remove_specks.py … 430 491 468 530 704 489 746 523`; 1,165 pixels in the two boxes; output pixel fingerprint `cb0e787580f8e49e`; raw checksum unchanged. Small stubs remain where the strokes met the eyes, visible at 2× zoom but not at game size.
- **Output:** `art/poses/CHAR-SCOOT-A.png` (file checksum in `evidence/batch1-checksums.txt`); comparison of guide, try 1, try 2, and the edit at 56 px: `evidence/char-scoot-a-56px-compare.png`.
- **Outcome:** accepted after the edit in my review: at game size it matches the guide's shape, eyes, and mouth.
- **Where used:** the scoot loop's key pose A, drawn facing right and flipped at runtime.
""")

fix("FRICTIONAL.md", [
 ("Scoot A try 1 rejected and retried with seed 7271 (outcome recorded after review).",
  "Scoot A try 1 rejected, retried with seed 7271, and accepted after a logged edit."),
 ("- I approved the handling for the nine poses, with the remaining minor marks documented, after one batch review (`evidence/batch1-review.png`).",
  "- Scoot A retry: the first try 2 export was pixel-identical to try 1 (the seed change had not taken effect, or an older entry was exported). It was set aside, the run redone with the seed confirmed, and a check confirmed the new output differs. Try 2 kept the guide's mouth and lost the side patches, but added a curved stroke at each eye's outer edge; two boxes removed them, leaving small stubs not visible at game size.\n- I approved the handling for the nine poses, with the remaining minor marks documented, after one batch review (`evidence/batch1-review.png`), and accepted Scoot A try 2 after its edit."),
 ("- Scoot A (try 2 pending review).\n", "- Small stubs where Scoot A's eye strokes were removed.\n"),
 ("- The SCOOT-A guide fingerprint differs between my Mac and Claude's preview build; cause not confirmed.",
  "- The SCOOT-A guide differs from Claude's preview build only in 2,008 outline-edge pixels (at most 2 of 255 levels); the face position is identical. Claude's first guess, a face-rounding difference, was wrong."),
 ("ran all ten generations and the batch script on my Mac; approved the nine-pose handling; chose the Scoot A retry.",
  "ran all ten generations, the Scoot A retry, and the batch scripts on my Mac; approved the nine-pose handling; chose the Scoot A retry and accepted its edited result."),
])
PY
say "logs updated"

say ""
say "== 5. Commit and push =="
git add ASSET-LOG.md FRICTIONAL.md tools/remove_specks.py tools/batch1_finalize.sh tools/batch1_scoota.sh art/poses art/source art/rejected evidence
git status --short
if git diff --cached --quiet; then say "Stopping: nothing staged to commit (already committed?)"; exit 1; fi
if ! git commit -q -m "Batch 1: accept 10 remaining poses (5 logged edits, Scoot A retry seed 7271 with edit), CHAR-IDLE = CHAR-REF; add SELECT=pink and safety stop to remove_specks, batch scripts, evidence, checksums, logs"; then
  say "Stopping: the commit failed, so nothing was pushed."; exit 1
fi
git log --oneline -1
if ! git push; then say "Stopping: the push failed. The commit exists locally; run git push again once the problem is fixed."; exit 1; fi
if [ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ]; then say "PUSHED: GitHub now matches $(git rev-parse --short HEAD)."; else say "Stopping: after the push, the local branch and GitHub differ."; exit 1; fi
