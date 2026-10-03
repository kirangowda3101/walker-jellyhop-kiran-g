#!/usr/bin/env bash
# Batch 2 processing for Jelly Hop: Fork From Above. Does NOT commit or push.
# Run from anywhere:  bash ~/Documents/walker-jellyhop-kiran-g/tools/batch2_process.sh
#
# 1. Checks the repo, the 16 raw environment outputs, and Python.
# 2. Rebuilds the four environment guides into gen-inputs/ and measures how much SDXL changed each.
# 3. Cuts out plate, sauce, fork, dome (glass interior made see-through) and the 12 poses,
#    darkens + seams the table strip, resizes the room -> art/game/.
# 4. Builds review images in evidence/, thumbnails of every raw, and a checksum list.
# Everything printed is also saved to evidence/batch2-process-log.txt.
set -Eeuo pipefail
trap 'echo; echo "STOPPED: line $LINENO failed: $BASH_COMMAND" >&2; exit 1' ERR

REPO="${REPO:-$HOME/Documents/walker-jellyhop-kiran-g}"
GEN="${GEN:-$HOME/Documents/jellyhop-generations}"
EXPECTED_HEAD="136721b"

stop() { echo; echo "STOPPED: $*" >&2; exit 1; }

cd "$REPO" || stop "repo not found at $REPO"
mkdir -p evidence art/game art/rejected art/source gen-inputs
LOG="evidence/batch2-process-log.txt"
: > "$LOG"
say() { echo "$*" | tee -a "$LOG"; }
run() { if ! "$@" 2>&1 | tee -a "$LOG"; then stop "command failed: $*"; fi; }

say "== Batch 2 processing  $(date '+%Y-%m-%d %H:%M')"

# ---- 1. checks ----
[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || stop "not on branch main"
HEAD_SHORT="$(git rev-parse --short=7 HEAD)"
say "repo HEAD: $HEAD_SHORT ($(git log -1 --format=%s | cut -c1-70))"
[ "$HEAD_SHORT" = "$EXPECTED_HEAD" ] || say "NOTE: HEAD is not $EXPECTED_HEAD (the last commit seen in chat); continuing"

# Only the new Batch 2 tool files may be uncommitted.
UNEXPECTED="$(git status --porcelain --untracked-files=all | grep -v -E '^\?\? tools/(make_env_guides\.py|process_env\.py|batch2_review\.py|batch2_process\.sh)$' | grep -v -E '^\?\? (evidence/batch2-|art/game/|art/rejected/ENV-|art/source/ENV-|gen-inputs/ENV-)' || true)"
[ -z "$UNEXPECTED" ] || stop "uncommitted changes other than the Batch 2 files:
$UNEXPECTED"

for t in make_env_guides.py process_env.py batch2_review.py; do
  [ -f "tools/$t" ] || stop "tools/$t missing (unzip the kit into the repo first)"
done
python3 -c "import numpy, PIL; print('python', __import__('sys').version.split()[0], 'numpy', numpy.__version__, 'Pillow', PIL.__version__)" 2>&1 | tee -a "$LOG"

RAWS="ENV-ROOM-try1 ENV-ROOM-try2 ENV-ROOM-try3 ENV-TABLE-try1 ENV-TABLE-try2 ENV-TABLE-try3 ENV-TABLE-try4 ENV-TABLE-try5 ENV-PLATE-try1 ENV-PLATE-try2 ENV-PLATE-try3 ENV-SAUCE-try1 ENV-SAUCE-try2 ENV-FORK-try1 ENV-FORK-try2 ENV-DOME-try1"
CANDIDATES="ENV-ROOM-try3 ENV-TABLE-try5 ENV-PLATE-try3 ENV-SAUCE-try2 ENV-FORK-try2 ENV-DOME-try1"
for r in $RAWS; do
  [ -f "$GEN/$r-seed7270.png" ] || stop "missing raw output $GEN/$r-seed7270.png"
done
say "all 16 raw outputs found in $GEN"

# Retry outputs must differ from their previous try (lesson from the Scoot A export mix-up).
check_differs() {
  if cmp -s "$GEN/$1-seed7270.png" "$GEN/$2-seed7270.png"; then stop "$2 is byte-identical to $1"; fi
}
check_differs ENV-ROOM-try1 ENV-ROOM-try2; check_differs ENV-ROOM-try2 ENV-ROOM-try3
check_differs ENV-TABLE-try1 ENV-TABLE-try2; check_differs ENV-TABLE-try2 ENV-TABLE-try3
check_differs ENV-TABLE-try3 ENV-TABLE-try4; check_differs ENV-TABLE-try4 ENV-TABLE-try5
check_differs ENV-PLATE-try1 ENV-PLATE-try2; check_differs ENV-PLATE-try2 ENV-PLATE-try3
check_differs ENV-SAUCE-try1 ENV-SAUCE-try2; check_differs ENV-FORK-try1 ENV-FORK-try2
say "every retry differs from the try before it"

# Report on the Batch 2 prompts file (not a stop).
if [ -f gen-inputs/batch2-env-prompts.md ]; then
  if git ls-files --error-unmatch gen-inputs/batch2-env-prompts.md >/dev/null 2>&1; then
    say "gen-inputs/batch2-env-prompts.md: present and committed in $(git log -1 --format=%h -- gen-inputs/batch2-env-prompts.md)"
  else
    say "gen-inputs/batch2-env-prompts.md: present but NOT committed"
  fi
else
  say "gen-inputs/batch2-env-prompts.md: NOT in the repo"
  ls -l "$HOME"/Downloads/batch2-env-prompts* 2>/dev/null | tee -a "$LOG" || say "  (no batch2-env-prompts file in ~/Downloads either)"
fi

# ---- 2. guides ----
say ""; say "== guides (rebuilt on this Mac)"
run python3 tools/make_env_guides.py gen-inputs
say "Claude's preview build: PLATE 7846989018675fd5, SAUCE 2a1429c50e039a4e, FORK 154de43fcf77afec, DOME 1aa8a963c3740455"
say ""; say "== how much SDXL changed each guide"
run python3 tools/process_env.py compare gen-inputs/ENV-PLATE-guide.png "$GEN/ENV-PLATE-try3-seed7270.png"
run python3 tools/process_env.py compare gen-inputs/ENV-SAUCE-guide.png "$GEN/ENV-SAUCE-try2-seed7270.png"
run python3 tools/process_env.py compare gen-inputs/ENV-FORK-guide.png "$GEN/ENV-FORK-try2-seed7270.png"
run python3 tools/process_env.py compare gen-inputs/ENV-DOME-guide.png "$GEN/ENV-DOME-try1-seed7270.png"

# ---- 3. processing ----
say ""; say "== environment"
run python3 tools/process_env.py room  "$GEN/ENV-ROOM-try3-seed7270.png"  art/game/ENV-ROOM.png --size 1280x720
run python3 tools/process_env.py table "$GEN/ENV-TABLE-try5-seed7270.png" art/game/ENV-TABLE.png --bottom 48 --blend 160 --gain 0.5 --sat 0.75
run python3 tools/process_env.py cutout "$GEN/ENV-PLATE-try3-seed7270.png" art/game/ENV-PLATE.png --crop 8
run python3 tools/process_env.py cutout "$GEN/ENV-SAUCE-try2-seed7270.png" art/game/ENV-SAUCE.png --crop 8 --pink-to 244,184,160
run python3 tools/process_env.py cutout "$GEN/ENV-FORK-try2-seed7270.png"  art/game/ENV-FORK.png --crop 8
run python3 tools/process_env.py cutout "$GEN/ENV-DOME-try1-seed7270.png"  art/game/ENV-DOME.png --interior --crop 8
say ""; say "== poses (canvas kept at 1024 x 1024 so every frame keeps its alignment)"
NPOSE=0
for p in art/poses/CHAR-*.png; do
  run python3 tools/process_env.py cutout "$p" "art/game/$(basename "$p")"
  NPOSE=$((NPOSE + 1))
done
[ "$NPOSE" -eq 12 ] || stop "expected 12 poses in art/poses, found $NPOSE"

# Fringe gate: report any cut-out with magenta-like pixels left.
if grep -E "fringe \(magenta-like, alpha>0\): [1-9]" "$LOG" >/dev/null; then
  say "NOTE: some cut-outs still have magenta-like pixels (see 'fringe' lines above)"
fi

# ---- 4. review images, thumbnails, checksums ----
say ""; say "== review images"
run python3 tools/batch2_review.py art/game evidence

say ""; say "== thumbnails (256 px)"
for r in $RAWS; do
  if echo " $CANDIDATES " | grep -q " $r "; then
    out="art/source/${r}-raw-seed7270-thumb.png"
  else
    out="art/rejected/${r}-seed7270-thumb.png"
  fi
  sips -Z 256 "$GEN/$r-seed7270.png" --out "$out" >/dev/null
  [ -s "$out" ] || stop "thumbnail not written: $out"
  say "  $out"
done

say ""; say "== checksums -> evidence/batch2-checksums.txt"
{
  echo "# Batch 2 checksums (SHA-256), $(date '+%Y-%m-%d %H:%M')"
  echo "## raw outputs (in $GEN, not in the repo)"
  (cd "$GEN" && for r in $RAWS; do shasum -a 256 "$r-seed7270.png"; done)
  echo "## guides"
  shasum -a 256 gen-inputs/ENV-*-guide.png
  echo "## processed (art/game)"
  shasum -a 256 art/game/*.png
} > evidence/batch2-checksums.txt
[ "$(grep -c -E '^[0-9a-f]{64} ' evidence/batch2-checksums.txt)" -eq 38 ] || stop "checksum list incomplete (expected 16 raws + 4 guides + 18 processed)"
say "38 checksums written"

say ""
say "DONE. Nothing was committed. Please upload evidence/batch2-review.png and evidence/batch2-process-log.txt."
