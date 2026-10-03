#!/usr/bin/env bash
# Copies the game-ready art (art/game/*.png) into the Godot project (godot/assets/art/)
# and verifies that every copy is byte-identical to its original. Never writes to art/game/.
#   bash tools/copy_game_art.sh           copy (only missing or different files), then verify
#   bash tools/copy_game_art.sh --check   verify only; changes nothing
# Result log: evidence/slice-art-copy.txt. Does NOT commit.
set -Eeuo pipefail
trap 'echo; echo "STOPPED: line $LINENO failed: $BASH_COMMAND" >&2; exit 1' ERR

stop() { echo; echo "STOPPED: $*" >&2; exit 1; }

REPO="$(cd -- "$(dirname -- "$0")/.." && pwd)"
SRC="$REPO/art/game"
DST="$REPO/godot/assets/art"
LOG="$REPO/evidence/slice-art-copy.txt"
MODE="copy"
if [ "${1:-}" = "--check" ]; then MODE="check"; elif [ -n "${1:-}" ]; then stop "unknown option: $1"; fi

[ -d "$SRC" ] || stop "missing $SRC"
EXPECTED=18
COUNT="$(find "$SRC" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')"
[ "$COUNT" = "$EXPECTED" ] || stop "expected $EXPECTED PNGs in art/game, found $COUNT"

mkdir -p "$DST" "$(dirname "$LOG")"
{
  echo "== Game art copy check ($MODE)  $(date '+%Y-%m-%d %H:%M')"
  echo "source: art/game/   copy: godot/assets/art/"
} > "$LOG"

copied=0
for src in "$SRC"/*.png; do
  name="$(basename "$src")"
  dst="$DST/$name"
  if [ "$MODE" = "copy" ] && ! cmp -s "$src" "$dst"; then
    cp "$src" "$dst"
    copied=$((copied + 1))
  fi
  [ -f "$dst" ] || stop "missing copy: godot/assets/art/$name"
  cmp -s "$src" "$dst" || stop "copy differs from original: $name"
  a="$(shasum -a 256 "$src" | cut -d' ' -f1)"
  b="$(shasum -a 256 "$dst" | cut -d' ' -f1)"
  [ "$a" = "$b" ] || stop "SHA-256 differs: $name"
  echo "OK  $a  $name" >> "$LOG"
done

# No stray PNGs in the copy folder that have no original.
for dst in "$DST"/*.png; do
  [ -f "$SRC/$(basename "$dst")" ] || stop "godot/assets/art/$(basename "$dst") has no original in art/game"
done

echo "copied this run: $copied; verified: $COUNT of $EXPECTED byte-identical (cmp + SHA-256)" >> "$LOG"
cat "$LOG"
