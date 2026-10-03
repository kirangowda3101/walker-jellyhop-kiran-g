#!/usr/bin/env bash
# Swap one sound in the game for another Batch 3 take, processed with the same settings. Does NOT commit.
#   bash tools/batch3_swap.sh <ID> <TAKE>     e.g.  bash tools/batch3_swap.sh SFX-HOP 2
#                                                   bash tools/batch3_swap.sh MUS-LOOP 3
# 1. tools/batch3_process.py processes the raw take (read only) into audio/game/<ID>.ogg with the fixed
#    settings (sound effects: -50 dBFS trims, 15 ms fade-out, -30.1 LUFS max momentary; music: whole-bar
#    loop, -40.1 LUFS integrated; gain only, peaks <= -1 dBFS) and appends its record to the process log.
# 2. tools/copy_game_audio.sh copies it into godot/assets/audio/ and verifies the copy is byte-identical.
# 3. Godot re-imports it (the music's .import keeps loop=true; checked).
# 4. Quick checks: game audio checks (decoded file), the audio copy check, and the slice suite.
# Every swap is listed in evidence/batch3-swaps.txt. Alternative raw takes stay outside the repo.
set -Eeuo pipefail
trap 'echo; echo "STOPPED: line $LINENO failed: $BASH_COMMAND" >&2; exit 1' ERR

stop() { echo; echo "STOPPED: $*" >&2; exit 1; }

REPO="$(cd -- "$(dirname -- "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
AUDIO_PY="${AUDIO_PY:-$HOME/Documents/jellyhop-audio-env/bin/python}"
export PYTHONDONTWRITEBYTECODE=1
ID="${1:-}"; TAKE="${2:-}"
case "$ID" in SFX-HOP|SFX-LAND|SFX-WARN|SFX-SPLAT-FORK|SFX-SPLAT-SAUCE|SFX-WIN|MUS-LOOP) ;; *) stop "usage: bash tools/batch3_swap.sh <ID> <1|2|3>; unknown ID '$ID'" ;; esac
case "$TAKE" in 1|2|3) ;; *) stop "usage: bash tools/batch3_swap.sh <ID> <1|2|3>; take must be 1, 2 or 3" ;; esac
[ -x "$GODOT" ] || stop "Godot not found at $GODOT"
[ -x "$AUDIO_PY" ] || stop "audio environment not found at $AUDIO_PY"
cd "$REPO"
LOG="evidence/batch3-swaps.txt"
CHK="$(mktemp -t jellyhop-swap)"

echo "-- 1. process $ID take $TAKE"
before="$(shasum -a 256 "audio/game/$ID.ogg" | cut -d' ' -f1)"
"$AUDIO_PY" tools/batch3_process.py --sound "$ID" --take "$TAKE" || stop "processing failed"
after="$(shasum -a 256 "audio/game/$ID.ogg" | cut -d' ' -f1)"

echo "-- 2. copy into godot/assets/audio/ and verify"
bash tools/copy_game_audio.sh || stop "audio copy failed"

echo "-- 3. Godot import"
"$GODOT" --headless --path godot --import > "$CHK" 2>&1 || stop "Godot import failed (log: $CHK)"
if [ "$ID" = "MUS-LOOP" ]; then
  grep -qx "loop=true" godot/assets/audio/MUS-LOOP.ogg.import || stop "MUS-LOOP.ogg.import lost loop=true"
fi

echo "-- 4. quick checks"
"$AUDIO_PY" tools/check_game_audio.py || stop "game audio checks failed"
bash tools/copy_game_audio.sh --check > /dev/null || stop "audio copy check failed"
"$GODOT" --headless --path godot --script res://tests/test_slice.gd > "$CHK" 2>&1 || true
line="$(grep -E "^SLICE TESTS: [0-9]+ checks / [0-9]+ failures$" "$CHK" || true)"
[ -n "$line" ] || stop "slice suite printed no summary line (log: $CHK)"
grep -E '"status":"FAIL"' "$CHK" || true
case "$line" in *" / 0 failures") ;; *) stop "slice suite: $line (log: $CHK)" ;; esac

echo "$(date '+%Y-%m-%d %H:%M')  $ID -> take $TAKE  sha256 $before -> $after  checks: game audio 0 failures; copy byte-identical; $line" >> "$LOG"
echo
echo "SWAPPED: $ID is now take $TAKE ($line). Run the game to listen: ./walker-jumpman.command"
