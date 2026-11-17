#!/usr/bin/env bash
# sessions/a7/capture_strips.sh — A7 Step 7: the LAND and SCOOT fixture strips (CHANGE-BRIEF.md, "Evidence and frame
# strips"). Written by the agent (Step 7a session); Kiran reviews and runs it. Every frame it keeps is a FIXTURE
# frame from res://previews/*_preview.tscn, not gameplay evidence; landing-r0 stays the separate gameplay reference.
#
# Usage, from the repository root (needs a window; do not press keys in the Godot window while it records):
#   bash sessions/a7/capture_strips.sh
#
# 1. Refuses to start if captures/land/r0, captures/scoot/r0 or any ~/Documents/a7-reference/captures-full/<run>
#    directory already exists.
# 2. Runs windowed Movie Maker three times, each run's output teed to a log:
#      land  --fixed-fps 30                     -> captures/land/r0/clean/    log captures/land/r0/land_clean.log
#      land  --fixed-fps 30 --debug-collisions  -> captures/land/r0/overlay/  log captures/land/r0/land_overlay.log
#      scoot --fixed-fps 60                     -> captures/scoot/r0/         log captures/scoot/r0/scoot.log
#    Movie Maker writes frame<NNNNNNNN>.png, one per rendered frame counted from 0 (and frame.wav).
# 3. Checks every run before anything is moved: Godot exit 0, the preview's own result line with problems=0, no
#    SCRIPT ERROR / Failed loading resource, contiguous FRAME lines, contiguous PNG numbers from 0, and
#    PNG count == FRAME line count. PNG index = FRAME index - (index of the first FRAME line); the offset is printed.
#    Land: the TRIGGER frame's PNG exists, and frames trigger-1 .. trigger+4 show FALL, rig 0, 2, 4, 6 and IDLE at
#    tick 8 in the log. Scoot: one frame before, on and after every SWAP and WRAP line, with the expected cell and
#    clip frame. Every kept PNG must be 1280 x 720.
# 4. Only if every check passed: moves each run's full Movie Maker output (all frame* files) to
#    ~/Documents/a7-reference/captures-full/<run>/ (with a copy of its log), then copies the frames to read back into
#    the repository under names that carry the rig frame or clip frame, and prints a table of them.
# If anything fails it prints STOPPED and exits 1. A failure in step 3 moves nothing; the captures stay where
# Movie Maker wrote them.

set -Eeuo pipefail
trap 'rc=$?; echo "STOPPED: command \"$BASH_COMMAND\" failed with exit $rc (line $LINENO)" >&2' ERR

stop() {
	echo "STOPPED: $*" >&2
	exit 1
}

# ---------------------------------------------------------------- preflight (nothing is created before these pass)

REPO="$(git rev-parse --show-toplevel)"
if [ "$(pwd -P)" != "$(cd "$REPO" && pwd -P)" ]; then
	stop "run this from the repository root: $REPO"
fi
LAND_DIR="captures/land/r0"
SCOOT_DIR="captures/scoot/r0"
CLEAN_DIR="$LAND_DIR/clean"
OVERLAY_DIR="$LAND_DIR/overlay"
CLEAN_LOG="$LAND_DIR/land_clean.log"
OVERLAY_LOG="$LAND_DIR/land_overlay.log"
SCOOT_LOG="$SCOOT_DIR/scoot.log"
EXT="$HOME/Documents/a7-reference/captures-full"
EXT_CLEAN="$EXT/land-r0-clean"
EXT_OVERLAY="$EXT/land-r0-overlay"
EXT_SCOOT="$EXT/scoot-r0"
WANT_SIZE="1280 x 720"

for d in "$LAND_DIR" "$SCOOT_DIR"; do
	if [ -e "$d" ]; then
		stop "$d already exists. Check what it is and move it yourself; this script never overwrites a capture."
	fi
done
for d in "$EXT_CLEAN" "$EXT_OVERLAY" "$EXT_SCOOT"; do
	if [ -e "$d" ]; then
		stop "$d already exists. Move it aside first; this script never overwrites a full sequence."
	fi
done
for tool in git godot timeout tee awk sed grep sort wc tr file mkdir mv cp; do
	if ! command -v "$tool" > /dev/null; then
		stop "required command not found: $tool"
	fi
done
for f in godot/previews/land_preview.tscn godot/previews/land_preview.gd godot/previews/scoot_preview.tscn godot/previews/scoot_preview.gd; do
	if [ ! -f "$f" ]; then
		stop "$f is missing"
	fi
done

echo "capture_strips.sh: HEAD $(git rev-parse HEAD), godot $(godot --version)"
echo "Do not press keys in the Godot window while it records: real key events reach the game."

# ---------------------------------------------------------------- helpers

strip_ansi() {   # file -> stdout without terminal colour codes
	LC_ALL=C sed -e $'s/\033\\[[0-9;]*m//g' "$1"
}

kv() {           # line key -> the value of key=value in the line, or nothing
	awk -v k="$2" '{ for (i = 1; i <= NF; i++) if (index($i, k "=") == 1) { print substr($i, length(k) + 2); exit } }' <<< "$1"
}

clip_frame() {   # clip time in seconds -> nearest 1/60 s timeline frame
	awk -v t="$1" 'BEGIN { printf "%d", t * 60 + 0.5 }'
}

near_frame() {   # clip time, frame: exit 0 if the time is that frame within 1e-3 frame
	awk -v t="$1" -v n="$2" 'BEGIN { d = t * 60 - n; if (d < 0) d = -d; exit (d < 0.001 ? 0 : 1) }'
}

run_capture() {  # label fps scene outdir log debug_collisions(0|1)
	local label="$1" fps="$2" scene="$3" outdir="$4" log="$5" debug="$6" rc=0 bad flags
	mkdir -p "$outdir"
	flags="--fixed-fps $fps"
	if [ "$debug" = "1" ]; then
		flags="$flags --debug-collisions"
	fi
	echo
	echo "=== $label: Movie Maker, $flags, $scene -> $outdir/"
	if [ "$debug" = "1" ]; then
		timeout 1800 godot --path godot --fixed-fps "$fps" --debug-collisions --write-movie "$REPO/$outdir/frame.png" "$scene" 2>&1 | tee "$log" || rc=$?
	else
		timeout 1800 godot --path godot --fixed-fps "$fps" --write-movie "$REPO/$outdir/frame.png" "$scene" 2>&1 | tee "$log" || rc=$?
	fi
	if [ "$rc" != "0" ]; then
		stop "$label: godot (or tee) exited $rc; see $log. Nothing was moved."
	fi
	bad="$( { strip_ansi "$log" | grep -cE 'SCRIPT ERROR|Failed loading resource'; } || true)"
	if [ "$bad" != "0" ]; then
		stop "$label: $bad SCRIPT ERROR / Failed loading resource lines in $log. Nothing was moved."
	fi
	echo "$label: godot exit 0"
}

FRAMES_TXT=""
F0=""
NFR=""
load_frames() {  # label log: FRAME lines into FRAMES_TXT; first index F0; count NFR; checks they are contiguous
	FRAMES_TXT="$( { strip_ansi "$2" | grep -E '^FRAME [0-9]+ '; } || true)"
	if [ -z "$FRAMES_TXT" ]; then
		stop "$1: no FRAME lines in $2"
	fi
	NFR="$(wc -l <<< "$FRAMES_TXT" | tr -d '[:space:]')"
	F0="$(awk 'NR == 1 { print $2 }' <<< "$FRAMES_TXT")"
	if ! awk 'NR == 1 { f0 = $2 } $2 != f0 + NR - 1 { bad = 1 } END { exit bad ? 1 : 0 }' <<< "$FRAMES_TXT"; then
		stop "$1: FRAME indices in $2 are not contiguous"
	fi
}

frame_line() {   # index -> the FRAME line with that process-frame index (from FRAMES_TXT)
	awk -v f="$1" '$1 == "FRAME" && $2 == f { print; exit }' <<< "$FRAMES_TXT"
}

NPNG=""
W=""
check_pngs() {   # label dir: counts frame<N>.png in NPNG, digit width in W; checks the numbers are 0..NPNG-1
	local names nums
	names="$( { ls "$2" | grep -E '^frame[0-9]+\.png$'; } || true)"
	if [ -z "$names" ]; then
		stop "$1: Movie Maker wrote no frame<N>.png in $2"
	fi
	NPNG="$(wc -l <<< "$names" | tr -d '[:space:]')"
	W="$(awk 'NR == 1 { print length($0) - 9 }' <<< "$names")"
	if ! awk -v w="$W" 'length($0) - 9 != w { bad = 1 } END { exit bad ? 1 : 0 }' <<< "$names"; then
		stop "$1: PNG names in $2 do not all have $W digits"
	fi
	nums="$(sed -E 's/^frame0*([0-9]+)\.png$/\1/' <<< "$names" | sort -n)"
	if ! awk '$1 != NR - 1 { bad = 1 } END { exit bad ? 1 : 0 }' <<< "$nums"; then
		stop "$1: PNG numbers in $2 are not contiguous from 0"
	fi
}

png_name() {     # index -> frame<index, W digits>.png
	printf "frame%0${W}d.png" "$1"
}

check_size() {   # label png
	local size
	size="$( { file -b "$2" | grep -oE '[0-9]+ x [0-9]+' | head -n 1; } || true)"
	if [ "$size" != "$WANT_SIZE" ]; then
		stop "$1: $2 is '${size:-unknown}', expected $WANT_SIZE. Nothing was moved."
	fi
}

map_run() {      # label outdir log: loads FRAME lines and PNGs, checks the counts match, prints the offset
	load_frames "$1" "$3"
	check_pngs "$1" "$2"
	if [ "$NPNG" != "$NFR" ]; then
		stop "$1: Movie Maker wrote $NPNG PNGs but $3 has $NFR FRAME lines, so PNGs cannot be matched to log frames. Nothing was moved."
	fi
	echo "$1: $NPNG PNGs = $NFR FRAME lines; first FRAME line is process frame $F0, so PNG index = FRAME index - $F0 (offset $F0)"
}

KEEP=""          # one line per kept frame: outdir \t ext \t source png \t new name \t frame \t png \t tick \t pose \t clip \t t \t cell \t expect
keep() {
	KEEP="$KEEP$(printf '%s\t' "$@")"$'\n'
}

# ---------------------------------------------------------------- land: trigger - 1 .. trigger + 4

CLEAN_TRIGGER=""
OVERLAY_TRIGGER=""
select_land() {  # variant(clean|overlay) outdir log ext
	local variant="$1" outdir="$2" log="$3" ext="$4" label="land $1"
	local result trig n tf td aligned tp rel fr line pose clip t tick cell rel_tick rig tag expect png ok
	map_run "$label" "$outdir" "$log"
	result="$( { strip_ansi "$log" | grep -E '^LAND PREVIEW: .* problems=0$'; } || true)"
	if [ -z "$result" ]; then
		stop "$label: no 'LAND PREVIEW: ... problems=0' line in $log (see its PROBLEM lines)"
	fi
	trig="$( { strip_ansi "$log" | grep -E '^TRIGGER '; } || true)"
	n=0
	if [ -n "$trig" ]; then
		n="$(wc -l <<< "$trig" | tr -d '[:space:]')"
	fi
	if [ "$n" != "1" ]; then
		stop "$label: expected exactly one TRIGGER line in $log, found $n"
	fi
	tf="$(kv "$trig" frame)"
	td="$(kv "$trig" touchdown_tick)"
	aligned="$(kv "$trig" aligned)"
	if [ "$aligned" != "true" ]; then
		stop "$label: TRIGGER line says aligned=$aligned: $trig"
	fi
	tp=$((tf - F0))
	if [ ! -f "$outdir/$(png_name "$tp")" ]; then
		stop "$label: TRIGGER frame $tf -> PNG index $tp, but $outdir/$(png_name "$tp") does not exist"
	fi
	echo "$label: TRIGGER frame=$tf (touchdown tick $td) -> PNG index $tp = $(png_name "$tp")"
	if [ "$variant" = "clean" ]; then
		CLEAN_TRIGGER="$tf/$tp"
	else
		OVERLAY_TRIGGER="$tf/$tp"
	fi
	for rel in -1 0 1 2 3 4; do
		fr=$((tf + rel))
		png=$((fr - F0))
		line="$(frame_line "$fr")"
		if [ -z "$line" ]; then
			stop "$label: no FRAME line for trigger $rel (frame $fr)"
		fi
		pose="$(kv "$line" pose)"
		clip="$(kv "$line" clip)"
		t="$(kv "$line" t)"
		tick="$(kv "$line" tick)"
		cell="$(kv "$line" cell)"
		rel_tick=$((tick - td))
		ok=1
		case "$rel" in
			-1)
				[ "$pose" = "FALL" ] && [ "$clip" = "-" ] || ok=0
				tag="trig-1_FALL"
				expect="Airborne FALL before contact"
				;;
			4)
				[ "$pose" = "IDLE" ] && [ "$clip" = "-" ] && [ "$rel_tick" = "8" ] || ok=0
				tag="trig+4_tick8_IDLE-handoff"
				expect="Tick 8: IDLE hand-off without a pop, seam or anchor shift"
				;;
			*)
				rig=$((2 * rel))
				if [ "$pose" != "LAND" ] || [ "$clip" != "land" ] || [ "$rel_tick" != "$rig" ] || ! near_frame "$t" "$rig"; then
					ok=0
				fi
				case "$rel" in
					0) tag="trig+0_rig0_impact"; expect="Frame 0: partial squash and planted feet" ;;
					1) tag="trig+1_rig2_deepest-squash"; expect="Frame 2: deepest squash, about the height of the low box" ;;
					2) tag="trig+2_rig4_same-squash"; expect="Frame 4: same squash, now beginning recovery" ;;
					3) tag="trig+3_rig6_eased-rise"; expect="Frame 6: eased rise, joined cut and fixed feet" ;;
				esac
				;;
		esac
		if [ "$ok" != "1" ]; then
			stop "$label: trigger $rel (frame $fr) does not show what the strip needs ($tag): $line"
		fi
		check_size "$label" "$outdir/$(png_name "$png")"
		keep "$outdir" "$ext" "$(png_name "$png")" "land_${variant}_${tag}_png$(printf "%0${W}d" "$png").png" \
			"$fr" "$png" "$tick" "$pose" "$clip" "$t" "$cell" "$expect"
	done
}

# ---------------------------------------------------------------- scoot: one before, on and one after every swap and wrap

select_scoot() { # outdir log ext
	local outdir="$1" log="$2" ext="$3" label="scoot"
	local result events n ev kind kind_lc f dir k pos off fr png line pose clip t tick cell cf want_cell want_cf expect
	local right_swap=0 right_wrap=0 left_swap=0 left_wrap=0
	map_run "$label" "$outdir" "$log"
	result="$( { strip_ansi "$log" | grep -E '^SCOOT PREVIEW: .* problems=0$'; } || true)"
	if [ -z "$result" ]; then
		stop "$label: no 'SCOOT PREVIEW: ... problems=0' line in $log (see its PROBLEM lines)"
	fi
	events="$( { strip_ansi "$log" | grep -E '^(SWAP|WRAP) '; } || true)"
	if [ -z "$events" ]; then
		stop "$label: no SWAP or WRAP lines in $log"
	fi
	n="$(wc -l <<< "$events" | tr -d '[:space:]')"
	echo "$label: $n SWAP/WRAP lines"
	while IFS= read -r ev; do
		kind="$(awk '{ print $1 }' <<< "$ev")"
		kind_lc="$(tr 'A-Z' 'a-z' <<< "$kind")"
		f="$(kv "$ev" frame)"
		dir="$(kv "$ev" dir)"
		case "$dir/$kind" in
			right/SWAP) right_swap=$((right_swap + 1)); k=$right_swap ;;
			right/WRAP) right_wrap=$((right_wrap + 1)); k=$right_wrap ;;
			left/SWAP) left_swap=$((left_swap + 1)); k=$left_swap ;;
			left/WRAP) left_wrap=$((left_wrap + 1)); k=$left_wrap ;;
			*) stop "$label: unexpected event line: $ev" ;;
		esac
		for pos in before on after; do
			case "$pos" in
				before) off=-1 ;;
				on) off=0 ;;
				after) off=1 ;;
			esac
			fr=$((f + off))
			png=$((fr - F0))
			line="$(frame_line "$fr")"
			if [ -z "$line" ]; then
				stop "$label: no FRAME line $pos $kind at frame $f"
			fi
			pose="$(kv "$line" pose)"
			clip="$(kv "$line" clip)"
			t="$(kv "$line" t)"
			tick="$(kv "$line" tick)"
			cell="$(kv "$line" cell)"
			if [ "$clip" != "scoot" ]; then
				stop "$label: frame $fr ($pos $kind at $f) is not in the scoot clip: $line"
			fi
			cf="$(clip_frame "$t")"
			case "$kind/$pos" in
				SWAP/before) want_cell=0; want_cf=6; expect="Cell 0 (A), last tick of the A hold" ;;
				SWAP/on) want_cell=1; want_cf=7; expect="Cell 1 (B) at the swap: feet registered, no jump" ;;
				SWAP/after) want_cell=1; want_cf=8; expect="Cell 1 (B), second tick of the B hold" ;;
				WRAP/before) want_cell=1; want_cf=13; expect="Cell 1 (B), last frame of the loop" ;;
				WRAP/on) want_cell=0; want_cf=0; expect="Cell 0 (A) at the wrap: no hesitation, feet registered" ;;
				WRAP/after) want_cell=0; want_cf=1; expect="Cell 0 (A), second tick of the A hold" ;;
			esac
			if [ "$cell" != "$want_cell" ] || [ "$cf" != "$want_cf" ] || ! near_frame "$t" "$want_cf"; then
				stop "$label: frame $fr ($pos $kind at $f) shows cell $cell at clip frame $cf, expected cell $want_cell at $want_cf: $line"
			fi
			check_size "$label" "$outdir/$(png_name "$png")"
			keep "$outdir" "$ext" "$(png_name "$png")" \
				"scoot_${dir}_${kind_lc}${k}_${pos}_clip${cf}_cell${cell}_png$(printf "%0${W}d" "$png").png" \
				"$fr" "$png" "$tick" "$pose" "$clip" "$t" "$cell" "$expect, facing $dir"
		done
	done <<< "$events"
	echo "$label: right $right_swap swaps, $right_wrap wraps; left $left_swap swaps, $left_wrap wraps"
	if [ "$right_swap" -lt 2 ] || [ "$right_wrap" -lt 2 ] || [ "$left_swap" -lt 2 ] || [ "$left_wrap" -lt 2 ]; then
		stop "$label: expected at least two swaps and two wraps in each direction"
	fi
}

# ---------------------------------------------------------------- move the full sequences out, copy the kept frames back

move_full() {    # outdir ext log
	local outdir="$1" ext="$2" log="$3" f left
	mkdir -p "$ext"
	for f in "$outdir"/frame*; do
		if [ ! -e "$f" ]; then
			stop "no Movie Maker files to move in $outdir"
		fi
		mv -n "$f" "$ext/"
	done
	left="$( { ls "$outdir" | grep -cE '^frame'; } || true)"
	if [ "$left" != "0" ]; then
		stop "$left Movie Maker files are still in $outdir after the move"
	fi
	cp "$log" "$ext/"
	echo "moved the full sequence: $outdir/frame* -> $ext/ (with a copy of $(basename "$log"))"
}

# ---------------------------------------------------------------- run

run_capture "land clean" 30 res://previews/land_preview.tscn "$CLEAN_DIR" "$CLEAN_LOG" 0
run_capture "land overlay" 30 res://previews/land_preview.tscn "$OVERLAY_DIR" "$OVERLAY_LOG" 1
run_capture "scoot" 60 res://previews/scoot_preview.tscn "$SCOOT_DIR" "$SCOOT_LOG" 0

echo
echo "=== checks (nothing is moved unless all pass)"
select_land clean "$CLEAN_DIR" "$CLEAN_LOG" "$EXT_CLEAN"
select_land overlay "$OVERLAY_DIR" "$OVERLAY_LOG" "$EXT_OVERLAY"
if [ "$CLEAN_TRIGGER" = "$OVERLAY_TRIGGER" ]; then
	echo "land: clean and overlay TRIGGER frame/PNG are the same: $CLEAN_TRIGGER"
else
	echo "land: NOTE clean TRIGGER frame/PNG $CLEAN_TRIGGER differs from overlay $OVERLAY_TRIGGER (each run checked on its own)"
fi
select_scoot "$SCOOT_DIR" "$SCOOT_LOG" "$EXT_SCOOT"

echo
echo "=== moving"
move_full "$CLEAN_DIR" "$EXT_CLEAN" "$CLEAN_LOG"
move_full "$OVERLAY_DIR" "$EXT_OVERLAY" "$OVERLAY_LOG"
move_full "$SCOOT_DIR" "$EXT_SCOOT" "$SCOOT_LOG"
kept=0
while IFS=$'\t' read -r outdir ext src name _rest; do
	if [ -z "$outdir" ]; then
		continue
	fi
	if [ ! -f "$ext/$src" ]; then
		stop "$ext/$src missing after the move"
	fi
	if [ -e "$outdir/$name" ]; then
		stop "$outdir/$name already exists (a frame kept twice?)"
	fi
	cp "$ext/$src" "$outdir/$name"
	kept=$((kept + 1))
done <<< "$KEEP"

echo
echo "=== kept frames ($kept): FIXTURE frames from res://previews/, not gameplay evidence"
printf '%-58s %6s %6s %6s %-8s %-6s %-9s %4s  %s\n' "file" "frame" "png" "tick" "pose" "clip" "t" "cell" "should show"
while IFS=$'\t' read -r outdir ext src name fr png tick pose clip t cell expect; do
	if [ -z "$outdir" ]; then
		continue
	fi
	printf '%-58s %6s %6s %6s %-8s %-6s %-9s %4s  %s\n' "$name" "$fr" "$png" "$tick" "$pose" "$clip" "$t" "$cell" "$expect"
done <<< "$KEEP"
echo
echo "Kept frames: $CLEAN_DIR/, $OVERLAY_DIR/, $SCOOT_DIR/ (logs beside them). Full sequences: $EXT/."
echo "RESULT: all three captures checked; $kept frames kept."
