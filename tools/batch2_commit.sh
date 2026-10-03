#!/usr/bin/env bash
# Batch 2 commit for Jelly Hop: Fork From Above.
# Run:  bash ~/Documents/walker-jellyhop-kiran-g/tools/batch2_commit.sh
#
# 1. Checks the repo is at 136721b with the three logs unchanged since they were uploaded.
# 2. Checks every processed file, guide, thumbnail, and evidence file from batch2_process.sh
#    (pixel fingerprints must match the run log).
# 3. Checks the updated ASSET-LOG.md, FRICTIONAL.md, SOURCES.md and the restored
#    gen-inputs/batch2-env-prompts.md in the kit against their expected checksums.
# 4. Shows a summary and waits for you to type COMMIT; only then installs them.
# 5. Stages exactly the 54 Batch 2 files, commits, pushes, and verifies GitHub matches.
# Never pushes if the commit fails. Stops with a STOPPED line on any problem.
set -Eeuo pipefail
trap 'echo; echo "STOPPED: line $LINENO failed: $BASH_COMMAND" >&2; exit 1' ERR

REPO="${REPO:-$HOME/Documents/walker-jellyhop-kiran-g}"
EXPECTED_HEAD="${EXPECTED_HEAD:-136721b}"
stop() { echo; echo "STOPPED: $*" >&2; exit 1; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }

cd "$REPO" || stop "repo not found at $REPO"
DOCS="tools/batch2-docs"

echo "== 1. Repo"
[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || stop "not on branch main"
HEAD_SHORT="$(git rev-parse --short=7 HEAD)"
[ "$HEAD_SHORT" = "$EXPECTED_HEAD" ] || stop "HEAD is $HEAD_SHORT, expected $EXPECTED_HEAD"
echo "HEAD $HEAD_SHORT"
[ -d "$DOCS" ] || stop "$DOCS missing (unzip batch2-commit-kit.zip into the repo first)"

check_sha() {  # file expected-sha label
  [ -f "$1" ] || stop "missing $1"
  [ "$(sha "$1")" = "$2" ] || stop "$3: $1 does not have the expected checksum"
}
# The logs must be exactly the versions uploaded to Claude (no edits since).
check_sha ASSET-LOG.md  6390900648c3d49c8a58accd6de2dbe873410197b639675487cfa555dc911d02 "current log changed since upload"
check_sha FRICTIONAL.md 54035cc4a37a11642329df527e5c4eac22b3f409a9ed78768b4847fa104bbd11 "current log changed since upload"
check_sha SOURCES.md    eeed6acd20a77ee1cc948f40975b462eab88f36b340237b79cad6355a93ae245 "current log changed since upload"
[ ! -e gen-inputs/batch2-env-prompts.md ] || stop "gen-inputs/batch2-env-prompts.md already exists; tell Claude before continuing"
echo "logs unchanged since upload; no prompts file present"

echo; echo "== 2. Batch 2 outputs"
python3 - <<'PY'
import hashlib, sys
import numpy as np
from PIL import Image
exp = {
 "gen-inputs/ENV-PLATE-guide.png": "7846989018675fd5", "gen-inputs/ENV-SAUCE-guide.png": "2a1429c50e039a4e",
 "gen-inputs/ENV-FORK-guide.png": "154de43fcf77afec", "gen-inputs/ENV-DOME-guide.png": "1aa8a963c3740455",
 "art/game/ENV-ROOM.png": "c674cced52b04d0f", "art/game/ENV-TABLE.png": "fa0928189d852264",
 "art/game/ENV-PLATE.png": "bdf417a0b57a3afa", "art/game/ENV-SAUCE.png": "5e0806cbbf0a6519",
 "art/game/ENV-FORK.png": "e5b50c5e1a064c51", "art/game/ENV-DOME.png": "b8b20794d0b874ab",
 "art/game/CHAR-ANTIC.png": "baa296f2dda432c9", "art/game/CHAR-BORED.png": "8e079ea2174160e9",
 "art/game/CHAR-CELEBRATE.png": "52a4a55499ef863a", "art/game/CHAR-FALL.png": "8acf874f9c32d317",
 "art/game/CHAR-IDLE.png": "2b451f0fc38bd284", "art/game/CHAR-LAND.png": "38efcb2616a63fd0",
 "art/game/CHAR-RESPAWN.png": "c6e76489c6d16d8f", "art/game/CHAR-RISE.png": "30b16a3463034f6e",
 "art/game/CHAR-SCOOT-A.png": "7debfac52fe909ae", "art/game/CHAR-SCOOT-B.png": "0931271333ff00a1",
 "art/game/CHAR-SPLAT.png": "4b0de8682eb7972b", "art/game/CHAR-WORRY.png": "3bf41741d7baef7b",
}
bad = 0
for f, e in exp.items():
    try:
        a = np.ascontiguousarray(np.asarray(Image.open(f)))
    except Exception as ex:
        print(f"MISSING/UNREADABLE {f}: {ex}"); bad += 1; continue
    got = hashlib.sha256(a.tobytes()).hexdigest()[:16]
    print(("match   " if got == e else "MISMATCH") + f" {f} {got}")
    bad += got != e
sys.exit(1 if bad else 0)
PY
[ "$(ls art/game/*.png | wc -l | tr -d ' ')" = "18" ] || stop "art/game should hold exactly 18 files"
for f in batch2-review.png batch2-mock-scene.png batch2-table-seam.png batch2-sprites.png batch2-poses.png batch2-process-log.txt batch2-checksums.txt; do
  [ -s "evidence/$f" ] || stop "missing evidence/$f"
done
grep -q "^DONE. Nothing was committed." evidence/batch2-process-log.txt || stop "the process log does not end in DONE; rerun batch2_process.sh"
[ "$(ls art/rejected/ENV-*-thumb.png | wc -l | tr -d ' ')" = "10" ] || stop "expected 10 rejected ENV thumbnails"
[ "$(ls art/source/ENV-*-raw-*-thumb.png | wc -l | tr -d ' ')" = "6" ] || stop "expected 6 source ENV thumbnails"
echo "guides, 18 processed files, 7 evidence files, 16 thumbnails present"

echo; echo "== 3. Check the updated logs and the restored prompts file (from the kit)"
check_sha "$DOCS/ASSET-LOG.md"  71da110ed65d689f8a39da6c02c0c1f40dc1d12159fb81279af3c8cdc0dd62dc "kit file"
check_sha "$DOCS/FRICTIONAL.md" b23ea5fde3f8f7fa1020b46014891df7c1f2335b7aacc3778b8fa40c98d05463 "kit file"
check_sha "$DOCS/SOURCES.md"    0ae7d20ec23645e73c0b0d25b15943d543fcfd9e8e9d7909d08e6465990b04f5 "kit file"
check_sha "$DOCS/gen-inputs/batch2-env-prompts.md" 0124cb1f8fd445c4165a4bcc4f3ba4f16a3475454d855b1bda85d4ab6767cbfd "kit file"
echo "kit files match"

echo; echo "== 4. Summary"
echo "Outcome lines to be committed (ASSET-LOG.md, Batch 2):"
grep -E '^\| ENV-[A-Z]+ \| [0-9] \|' "$DOCS/ASSET-LOG.md" | awk -F'|' '{gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$3); gsub(/^ +| +$/,"",$7); print "  " $2 " try " $3 ": " $7}'
echo "Prompts file: restored after generation (says so in its first paragraph)."
echo "Read the full texts first if you like: open $DOCS/ASSET-LOG.md (and FRICTIONAL.md, SOURCES.md, gen-inputs/batch2-env-prompts.md)"
echo
read -r -p "Type COMMIT to install the logs, commit, and push; anything else stops with nothing changed: " ANSWER
[ "$ANSWER" = "COMMIT" ] || stop "not confirmed; nothing changed (run the script again when ready)"

cp "$DOCS/ASSET-LOG.md" ASSET-LOG.md
cp "$DOCS/FRICTIONAL.md" FRICTIONAL.md
cp "$DOCS/SOURCES.md" SOURCES.md
cp "$DOCS/gen-inputs/batch2-env-prompts.md" gen-inputs/batch2-env-prompts.md
rm -r "$DOCS"
echo "installed ASSET-LOG.md, FRICTIONAL.md, SOURCES.md, gen-inputs/batch2-env-prompts.md"

echo; echo "== 5. Commit and push"
git add tools/make_env_guides.py tools/process_env.py tools/batch2_review.py tools/batch2_process.sh tools/batch2_commit.sh \
        gen-inputs/ENV-PLATE-guide.png gen-inputs/ENV-SAUCE-guide.png gen-inputs/ENV-FORK-guide.png gen-inputs/ENV-DOME-guide.png \
        gen-inputs/batch2-env-prompts.md art/game evidence/batch2-review.png evidence/batch2-mock-scene.png \
        evidence/batch2-table-seam.png evidence/batch2-sprites.png evidence/batch2-poses.png \
        evidence/batch2-process-log.txt evidence/batch2-checksums.txt \
        art/rejected/ENV-*-thumb.png art/source/ENV-*-raw-*-thumb.png ASSET-LOG.md FRICTIONAL.md SOURCES.md
git status --short
NSTAGED="$(git diff --cached --name-only | wc -l | tr -d ' ')"
[ "$NSTAGED" = "54" ] || stop "expected 54 staged files, found $NSTAGED (nothing committed; 'git reset' unstages)"
[ -z "$(git status --porcelain --untracked-files=all | grep -v '^[AM]  ' || true)" ] || stop "files left unstaged or untracked (shown above); nothing committed"
BIG="$(git diff --cached --name-only | while read -r f; do [ "$(wc -c < "$f")" -gt 25000000 ] && echo "$f"; done || true)"
[ -z "$BIG" ] || stop "file over 25 MB: $BIG"

if ! git commit -q -m "Batch 2: accept six environment assets (plate, sauce, fork, dome from drawn guides at 50%; table and room text to image); cut-outs for sprites and 12 poses, dome transparency edit, table seam; restored prompts file; tools, evidence, logs"; then
  stop "commit failed; nothing pushed"
fi
git log --oneline -1
git push
git fetch -q
[ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ] || stop "push not confirmed: local HEAD differs from GitHub"
echo "PUSHED: GitHub now matches $(git rev-parse --short=7 HEAD)."
