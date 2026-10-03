#!/usr/bin/env bash
# Runs every check for the Jelly Hop slice and stops on the first problem. Does NOT commit.
#   bash tools/run_slice_checks.sh
# 1. Game art copies are byte-identical to art/game/ (tools/copy_game_art.sh --check); game audio copies are
#    byte-identical to audio/game/ (tools/copy_game_audio.sh --check); the decoded game audio passes
#    tools/check_game_audio.py (start within 10 ms, peaks, loudness, music loop on) in ~/Documents/jellyhop-audio-env.
# 2. Godot import, then the three headless suites: test_game (mechanics), test_keyboard,
#    test_slice (SLICE-BRIEF.md §8). A suite passes only if Godot exits 0 AND prints its summary
#    line with 0 failures: a script that fails to compile can still exit 0.
# 3. Windowed screenshot capture of the 7 storyboard moments; each PNG must be 1280 x 720.
# 4. Smoke launch of the game itself (main scene) for a few seconds; the log must show no errors.
# Logs: evidence/slice-checks/final-*.txt (each printed after its step).
set -Eeuo pipefail
trap 'echo; echo "STOPPED: line $LINENO failed: $BASH_COMMAND" >&2; exit 1' ERR

stop() { echo; echo "STOPPED: $*" >&2; exit 1; }

REPO="$(cd -- "$(dirname -- "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
AUDIO_PY="${AUDIO_PY:-$HOME/Documents/jellyhop-audio-env/bin/python}"
OUT="$REPO/evidence/slice-checks"
[ -x "$GODOT" ] || stop "Godot not found at $GODOT"
[ -x "$AUDIO_PY" ] || stop "audio environment not found at $AUDIO_PY"
mkdir -p "$OUT"
cd "$REPO"

# Run Godot with a time limit; output goes to a log file. Returns Godot's exit code (124 = timed out).
run_godot() {
  local log="$1" limit="$2"
  shift 2
  echo "\$ godot $*" >> "$log"
  "$GODOT" "$@" >> "$log" 2>&1 &
  local pid=$! i=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$i" -ge "$limit" ]; then
      kill "$pid"
      wait "$pid" || true
      echo "TIMEOUT after ${limit}s" >> "$log"
      return 124
    fi
    sleep 1
    i=$((i + 1))
  done
  local rc=0
  wait "$pid" || rc=$?
  echo "exit: $rc" >> "$log"
  return "$rc"
}

SUMMARY="$OUT/final-summary.txt"
{
  echo "== Jelly Hop slice checks  $(date '+%Y-%m-%d %H:%M')"
  echo "engine: $("$GODOT" --version)"
  echo "repo: $(git rev-parse --short HEAD) on $(git rev-parse --abbrev-ref HEAD) (uncommitted batch changes present)"
} > "$SUMMARY"

echo "-- 1. art copies"
bash tools/copy_game_art.sh --check > "$OUT/final-art.txt" || stop "art copy check failed (see $OUT/final-art.txt)"
cat "$OUT/final-art.txt"
echo "art copies: $(tail -1 "$OUT/final-art.txt")" >> "$SUMMARY"
bash tools/copy_game_audio.sh --check > "$OUT/final-audio-copy.txt" || stop "audio copy check failed (see $OUT/final-audio-copy.txt)"
cat "$OUT/final-audio-copy.txt"
echo "audio copies: $(tail -1 "$OUT/final-audio-copy.txt")" >> "$SUMMARY"
PYTHONDONTWRITEBYTECODE=1 "$AUDIO_PY" tools/check_game_audio.py > "$OUT/final-game-audio.txt" 2>&1 || { cat "$OUT/final-game-audio.txt"; stop "game audio checks failed"; }
cat "$OUT/final-game-audio.txt"
echo "game audio: $(tail -1 "$OUT/final-game-audio.txt")" >> "$SUMMARY"

echo "-- 2. import and headless suites"
LOG="$OUT/final-import.txt"; : > "$LOG"
run_godot "$LOG" 120 --headless --path godot --import || stop "Godot import failed (see $LOG)"
for pair in "test_game:WALKER TESTS" "test_keyboard:KEYBOARD TESTS" "test_slice:SLICE TESTS"; do
  suite="${pair%%:*}"; label="${pair#*:}"
  LOG="$OUT/final-$suite.txt"; : > "$LOG"
  rc=0
  run_godot "$LOG" 400 --headless --path godot --script "res://tests/$suite.gd" || rc=$?
  cat "$LOG"
  line="$(grep -E "^$label: [0-9]+ checks / [0-9]+ failures$" "$LOG" || true)"
  [ -n "$line" ] || stop "$suite printed no summary line (did not run to the end; see $LOG)"
  [ "$rc" = "0" ] || stop "$suite exited $rc: $line"
  case "$line" in *" / 0 failures") ;; *) stop "$suite: $line" ;; esac
  if grep -E "SCRIPT ERROR|^ERROR" "$LOG" > /dev/null; then stop "$suite logged an error (see $LOG)"; fi
  echo "$suite: $line (exit $rc)" >> "$SUMMARY"
done

echo "-- 3. screenshots (opens a window)"
LOG="$OUT/final-capture.txt"; : > "$LOG"
run_godot "$LOG" 180 --path godot --script res://tests/capture_slice.gd || stop "capture failed (see $LOG)"
cat "$LOG"
grep -q "^SLICE CAPTURES: 7$" "$LOG" || stop "capture did not report 7 screenshots"
for shot in 01-intro-pan 02-hop 03-warning 04-safe-landing 05-splat 06-respawn 07-dome; do
  f="evidence/slice-screens/$shot.png"
  [ -f "$f" ] || stop "missing $f"
  w="$(sips -g pixelWidth "$f" | awk '/pixelWidth/ {print $2}')"
  h="$(sips -g pixelHeight "$f" | awk '/pixelHeight/ {print $2}')"
  [ "$w" = "1280" ] && [ "$h" = "720" ] || stop "$f is ${w}x${h}, not 1280x720"
done
echo "screenshots: 7 of 7 at 1280x720 in evidence/slice-screens/" >> "$SUMMARY"

echo "-- 4. smoke launch of the game (8 s, then closed)"
LOG="$OUT/final-launch.txt"; : > "$LOG"
rc=0
run_godot "$LOG" 8 --path godot || rc=$?
cat "$LOG"
[ "$rc" = "124" ] || stop "the game exited by itself during the smoke launch (exit $rc; see $LOG)"
if grep -E "SCRIPT ERROR|^ERROR" "$LOG" > /dev/null; then stop "the game logged an error on launch (see $LOG)"; fi
echo "game launch: ran 8 s from the command line with no errors logged, then closed by the script (not a playtest)" >> "$SUMMARY"

echo
cat "$SUMMARY"
echo "ALL SLICE CHECKS PASSED"
