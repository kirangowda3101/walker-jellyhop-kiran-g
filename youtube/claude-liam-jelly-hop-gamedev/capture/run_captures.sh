#!/usr/bin/env bash
# Records the film's two gameplay takes from an isolated snapshot of the slice. Does NOT commit.
#   bash youtube/claude-liam-jelly-hop-gamedev/capture/run_captures.sh WORK_DIR
# 1. Extracts a fresh snapshot of REV (git archive) into WORK_DIR/snapshot; the repo is not touched.
# 2. Fingerprints the snapshot's godot/ tree BEFORE adding anything (source-manifest.txt, build_id).
# 3. Adds two copy-only files to the snapshot: capture/capture_driver.gd (this folder's driver) and
#    override.cfg (window 3840x2160, so Movie Maker renders natively at 4K). Disclosed in CAPTURE.md.
# 4. Records run-01 (main route) and run-02 (sauce route) with Godot Movie Maker (offline, fixed 60 fps).
#    A take passes only if Godot exits 0, the driver printed "CAPTURE OK", and ffprobe shows
#    3840x2160 MJPEG video plus a PCM audio stream.
# 5. Writes SHA-256 of each AVI and input log to captures.sha256 in this folder.
set -Eeuo pipefail
trap 'echo; echo "STOPPED: line $LINENO failed: $BASH_COMMAND" >&2; exit 1' ERR
stop() { echo; echo "STOPPED: $*" >&2; exit 1; }

REV="7a48ea8cb29c04dfafa3e6df6fe491e1807c8409"
HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
WORK="${1:-}"
[ -n "$WORK" ] || stop "usage: run_captures.sh WORK_DIR (outside the repo)"
case "$WORK" in "$REPO"*) stop "WORK_DIR must be outside the repository" ;; esac
[ -x "$GODOT" ] || stop "Godot not found at $GODOT"
[ -f "$HERE/capture_driver.gd" ] || stop "capture_driver.gd missing"

SNAP="$WORK/snapshot"
[ ! -e "$SNAP" ] || stop "$SNAP already exists; use an empty WORK_DIR"
mkdir -p "$SNAP"
git -C "$REPO" archive "$REV" | tar -x -C "$SNAP"
echo "snapshot: $REV -> $SNAP"

# Fingerprint of the untouched godot/ tree: sha256 of every file (sorted path list), then of the list.
( cd "$SNAP" && find godot -type f ! -path '*/.godot/*' | LC_ALL=C sort | while IFS= read -r f; do shasum -a 256 "$f"; done ) > "$HERE/source-manifest.txt"
BUILD_ID="$(shasum -a 256 "$HERE/source-manifest.txt" | cut -d' ' -f1)"
FILES="$(wc -l < "$HERE/source-manifest.txt" | tr -d ' ')"
[ "$FILES" -gt 0 ] || stop "empty source manifest"
echo "build_id: $BUILD_ID ($FILES files in godot/)"

mkdir -p "$SNAP/godot/capture"
cp "$HERE/capture_driver.gd" "$SNAP/godot/capture/capture_driver.gd"
printf '[display]\n\nwindow/size/window_width_override=3840\nwindow/size/window_height_override=2160\n' > "$SNAP/godot/override.cfg"

# A git archive has no .godot/imported cache: import first (as tools/run_slice_checks.sh does), or no
# texture or sound loads and the forks get no hit shapes (found on the first attempt; see BUILD-LOG.md).
OUT="$WORK/takes"
mkdir -p "$OUT"
irc=0
( cd "$SNAP" && "$GODOT" --headless --path godot --import ) > "$OUT/import.log" 2>&1 || irc=$?
[ "$irc" -eq 0 ] || stop "Godot import exited $irc (see $OUT/import.log)"
! grep -qE "SCRIPT ERROR|Failed loading|Cannot open file" "$OUT/import.log" || stop "import reported errors (see $OUT/import.log)"
echo "import: ok"

take() {
  local name="$1" route="$2" limit="$3" log rc=0
  log="$OUT/$name-godot.log"
  echo "-- $name ($route route)"
  ( cd "$SNAP" && CAPTURE_ROUTE="$route" CAPTURE_LOG="$OUT/$name-inputs.jsonl" "$GODOT" --path godot \
      --script res://capture/capture_driver.gd --write-movie "$OUT/$name.avi" --fixed-fps 60 \
      --quit-after "$limit" ) > "$log" 2>&1 || rc=$?
  grep -E "Movie Maker|CAPTURE|frames at" "$log" || true
  [ "$rc" -eq 0 ] || stop "$name: Godot exited $rc (see $log)"
  grep -q "^CAPTURE OK" "$log" || stop "$name: driver did not report CAPTURE OK"
  ! grep -qE "SCRIPT ERROR|Failed loading|Cannot open file" "$log" || stop "$name: engine log has load or script errors (see $log)"
  local v a
  v="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate -of csv=p=0 "$OUT/$name.avi")"
  a="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -of csv=p=0 "$OUT/$name.avi")"
  echo "video: $v   audio: $a"
  [ "$v" = "mjpeg,3840,2160,60/1" ] || stop "$name: unexpected video stream: $v"
  case "$a" in pcm_s16le,48000,2) ;; *) stop "$name: unexpected audio stream: $a" ;; esac
}
take run-01 main 6000
take run-02 sauce 3000

( cd "$OUT" && shasum -a 256 run-01.avi run-01-inputs.jsonl run-02.avi run-02-inputs.jsonl ) > "$HERE/captures.sha256"
cp "$OUT/run-01-inputs.jsonl" "$OUT/run-02-inputs.jsonl" "$HERE/"
{
  echo "rev: $REV"
  echo "build_id: $BUILD_ID"
  echo "godot: $("$GODOT" --version)"
  echo "recorded: $(date '+%Y-%m-%d %H:%M %Z')"
  echo "work_dir: $WORK"
} > "$HERE/capture-run.txt"
cat "$HERE/captures.sha256" "$HERE/capture-run.txt"
echo "CAPTURES OK"
