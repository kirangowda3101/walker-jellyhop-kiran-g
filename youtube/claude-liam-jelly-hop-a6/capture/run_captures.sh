#!/usr/bin/env bash
# A6 film capture script (Claude Code, 2026-11-08), after the A5 film's run_captures.sh. Does NOT commit and does not
# touch the repository: per the launch note it records in the disposable git-archive copy of 8004dea.
#   bash film/capture/run_captures.sh
# 1. Checks that the run copy's godot/ matches the read-only snapshot's godot/ file for file (both are git archives
#    of 8004dea) and fingerprints it BEFORE adding anything (source-manifest.txt, build_id).
# 2. Adds two copy-only files to the run copy: capture/capture_driver.gd (this folder's driver) and override.cfg
#    (window 3840x2160, so Movie Maker renders natively at 4K). Disclosed in CAPTURE.md.
# 3. Imports headless (a git archive has no .godot cache), then records one windowed Movie Maker take, run-a6.
#    A take passes only if Godot exits 0, the driver printed "CAPTURE OK", the log has no script/load errors and
#    ffprobe shows 3840x2160 MJPEG at 60 fps.
# 4. Writes SHA-256 of the AVI and the input log to captures.sha256 in this folder.
set -Eeuo pipefail
trap 'echo; echo "STOPPED: line $LINENO failed: $BASH_COMMAND" >&2; exit 1' ERR
stop() { echo; echo "STOPPED: $*" >&2; exit 1; }

HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
WORK="/Users/kiran/Documents/jellyhop-a6-film-work"
SNAP="$WORK/snapshot-8004dea"
RUN="$WORK/run-copy-8004dea"
OUT="$WORK/takes"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
[ -x "$GODOT" ] || stop "Godot not found at $GODOT"
[ "$(cat "$WORK/SNAPSHOT-REVISION.txt")" = "8004dea" ] || stop "unexpected snapshot revision"

manifest() { ( cd "$1" && find godot -type f ! -path '*/.godot/*' ! -path 'godot/capture/*' ! -name override.cfg | LC_ALL=C sort | while IFS= read -r f; do shasum -a 256 "$f"; done ); }
mkdir -p "$OUT"
manifest "$SNAP" > "$HERE/source-manifest.txt"
manifest "$RUN" > "$OUT/run-copy-manifest.txt"
cmp -s "$HERE/source-manifest.txt" "$OUT/run-copy-manifest.txt" || stop "run copy godot/ differs from the snapshot's godot/"
BUILD_ID="$(shasum -a 256 "$HERE/source-manifest.txt" | cut -d' ' -f1)"
echo "build_id: $BUILD_ID ($(wc -l < "$HERE/source-manifest.txt" | tr -d ' ') files in godot/, .godot/ excluded)"

mkdir -p "$RUN/godot/capture" "$OUT"
cp "$HERE/capture_driver.gd" "$RUN/godot/capture/capture_driver.gd"
printf '[display]\n\nwindow/size/window_width_override=3840\nwindow/size/window_height_override=2160\n' > "$RUN/godot/override.cfg"

# Import (the A5 README notes a first fresh-cache import can segfault; a second completes).
for attempt in 1 2; do
  irc=0
  ( cd "$RUN" && "$GODOT" --headless --path godot --import ) > "$OUT/import-$attempt.log" 2>&1 || irc=$?
  echo "import attempt $attempt: exit $irc"
  [ "$irc" -eq 0 ] && break
done
[ "$irc" -eq 0 ] || stop "Godot import exited $irc twice (see $OUT/import-*.log)"

take() {
  local name="$1" limit="$2" log rc=0
  log="$OUT/$name-godot.log"
  echo "-- $name"
  ( cd "$RUN" && CAPTURE_LOG="$OUT/$name-inputs.jsonl" "$GODOT" --path godot \
      --script res://capture/capture_driver.gd --write-movie "$OUT/$name.avi" --fixed-fps 60 \
      --quit-after "$limit" ) > "$log" 2>&1 || rc=$?
  grep -E "Movie Maker|CAPTURE|frames at|Compatibility|OpenGL" "$log" || true
  [ "$rc" -eq 0 ] || stop "$name: Godot exited $rc (see $log)"
  grep -q "^CAPTURE OK" "$log" || stop "$name: driver did not report CAPTURE OK"
  ! grep -qE "SCRIPT ERROR|SHADER ERROR|Failed loading|Cannot open file" "$log" || stop "$name: engine log has errors (see $log)"
  local v
  v="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate -of csv=p=0 "$OUT/$name.avi")"
  echo "video: $v"
  [ "$v" = "mjpeg,3840,2160,60/1" ] || stop "$name: unexpected video stream: $v"
}
take run-a6 7200

( cd "$OUT" && shasum -a 256 run-a6.avi run-a6-inputs.jsonl ) > "$HERE/captures.sha256"
cp "$OUT/run-a6-inputs.jsonl" "$OUT/run-a6-godot.log" "$HERE/"
{
  echo "rev: 8004deac38c5b4ad260f24433e0537b3e94d16e2 (git archive, run copy)"
  echo "build_id: $BUILD_ID"
  echo "godot: $("$GODOT" --version)"
  echo "recorded: $(date '+%Y-%m-%d %H:%M %Z')"
  echo "run_copy: $RUN"
} > "$HERE/capture-run.txt"
cat "$HERE/captures.sha256" "$HERE/capture-run.txt"
echo "CAPTURES OK"
