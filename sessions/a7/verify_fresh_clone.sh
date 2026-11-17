#!/usr/bin/env bash
# sessions/a7/verify_fresh_clone.sh — A7 fresh-clone verification. Written by the agent; Kiran reviews and runs it
# after tagging a7.
#
# Usage, from the repository root:   bash sessions/a7/verify_fresh_clone.sh [ref]    (default ref: a7)
#
# 1. Stops if ../a7-check exists. Clones `git remote get-url origin` into ../a7-check, checks out <ref> (detached)
#    and prints the commit SHA. The ref must exist on origin (a local-only tag is not in the clone).
# 2. Runs `godot --headless --path godot --import` once in the clone (empty import cache); records the exit code.
#    Output goes to the clone's logs/fresh_import.log.
# 3. Runs every suite, one at a time, through the clone's ./scripts/run-test.sh in its pinned mode and reads the
#    summary line "<PREFIX>: <n> checks / <f> failures" (prefixes from each test file's final print). Then the
#    supplemental runs: probe_a7_entry_order at 30/60/144 (H3VERDICT ... pass=yes), cost_effects 60 with timeout
#    300 ("control separates: true") and check_lifecycle_peak 60 (peak 2 by both PEAK counts). Supplemental runs are
#    reported separately and not counted, but a failure there still makes the overall result FAIL.
#    Wrapper output for each run goes to logs/<name>_<fps>fps.wrapper.txt; the test log itself is the wrapper's
#    logs/<name>_<fps>fps.log.
# 4. Checks every log (including the import log) for "SHADER ERROR", "SCRIPT ERROR" or "Failed loading resource".
# 5. Prints the table and writes it, with the SHA, date and Godot version, to
#    ~/Documents/a7-reference/fresh-clone-<sha>.txt (never overwritten; the script stops if it exists).
# Exit status: 0 only if the import and all 31 runs passed; 1 if anything failed; 2 if it stopped before testing.
# ../a7-check is always left in place for inspection.
#
# Written for bash 3.2 (macOS /bin/bash) as well as newer bash: no mapfile, no associative arrays.

set -Eeuo pipefail
trap 'rc=$?; echo "STOPPED: command \"$BASH_COMMAND\" failed with exit $rc (line $LINENO)" >&2' ERR

stop() {
	echo "STOPPED: $*" >&2
	exit 2
}

# ---------------------------------------------------------------- preflight (nothing is created before these pass)

if [ "$#" -gt 1 ]; then
	stop "usage: bash sessions/a7/verify_fresh_clone.sh [ref]"
fi
REF="${1:-a7}"

REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || stop "not inside a git repository"
if [ "$(pwd -P)" != "$(cd "$REPO" && pwd -P)" ]; then
	stop "run this from the repository root: $REPO"
fi
for tool in git godot timeout grep date; do
	command -v "$tool" >/dev/null 2>&1 || stop "'$tool' is not on PATH"
done

CLONE="$(cd "$REPO/.." && pwd -P)/a7-check"
if [ -e "$CLONE" ] || [ -L "$CLONE" ]; then
	stop "$CLONE already exists. Inspect it, then remove it yourself (rm -rf \"$CLONE\") and run again."
fi

ORIGIN="$(git remote get-url origin)" || stop "no remote named origin"
LOCAL_SHA=""
if git rev-parse --verify --quiet "${REF}^{commit}" >/dev/null; then
	LOCAL_SHA="$(git rev-parse "${REF}^{commit}")"
fi

REPORT_DIR="$HOME/Documents/a7-reference"
ERR_RE='SHADER ERROR|SCRIPT ERROR|Failed loading resource'

# ---------------------------------------------------------------- 1. clone and check out

echo "== 1. Clone origin into $CLONE and check out $REF"
git clone --quiet "$ORIGIN" "$CLONE" || stop "git clone failed"
if ! git -C "$CLONE" rev-parse --verify --quiet "${REF}^{commit}" >/dev/null; then
	stop "ref '$REF' is not in the clone of origin. If it is a local tag, push it first (git push origin $REF). The clone is left at $CLONE; remove it with: rm -rf \"$CLONE\""
fi
git -C "$CLONE" checkout --quiet --detach "$REF"
SHA="$(git -C "$CLONE" rev-parse HEAD)"
echo "Checked out $REF at commit $SHA"

REF_NOTE="local $REF: not found in this repository"
if [ -n "$LOCAL_SHA" ]; then
	if [ "$LOCAL_SHA" = "$SHA" ]; then
		REF_NOTE="local $REF: $LOCAL_SHA (same commit)"
	else
		REF_NOTE="WARNING: local $REF is $LOCAL_SHA, origin's is $SHA (different commits; this run checks origin's)"
	fi
fi
echo "$REF_NOTE"

REPORT="$REPORT_DIR/fresh-clone-$SHA.txt"
if [ -e "$REPORT" ]; then
	stop "$REPORT already exists; not overwriting it. Move it aside, remove the clone (rm -rf \"$CLONE\"), and run again."
fi

cd "$CLONE"
if [ ! -f scripts/run-test.sh ] || [ ! -x scripts/run-test.sh ]; then
	stop "the clone's scripts/run-test.sh is missing or not executable"
fi
mkdir -p logs
GODOT_VERSION="$(godot --version 2>&1)" || stop "godot --version failed: $GODOT_VERSION"
RUN_DATE="$(date '+%Y-%m-%d %H:%M:%S %Z')"
SECONDS=0

# ---------------------------------------------------------------- helpers

# Result rows: group (I import, C counted, S supplemental), suite, mode, expected, observed, exit, PASS/FAIL.
R_GROUP=(); R_SUITE=(); R_MODE=(); R_EXP=(); R_OBS=(); R_EXIT=(); R_RES=()
ERR_LINES=()
add_row() {
	R_GROUP+=("$1"); R_SUITE+=("$2"); R_MODE+=("$3"); R_EXP+=("$4"); R_OBS+=("$5"); R_EXIT+=("$6"); R_RES+=("$7")
}

# err_scan <log>: sets ERR_STATE to none | found | missing | unreadable; records any matching lines.
err_scan() {
	local log="$1" g=0 hits=""
	if [ ! -f "$log" ]; then
		ERR_STATE="missing"
		return 0
	fi
	hits="$(grep -nE "$ERR_RE" "$log")" || g=$?
	case "$g" in
		0) ERR_STATE="found"; ERR_LINES+=("$log:"$'\n'"$hits") ;;
		1) ERR_STATE="none" ;;
		*) ERR_STATE="unreadable" ;;
	esac
}

# match_lines <log> <ERE>: MATCH_COUNT = number of matching lines; MATCH_1/MATCH_2 = capture groups of the last one.
match_lines() {
	local log="$1" re="$2" line
	MATCH_COUNT=0; MATCH_1=""; MATCH_2=""
	if [ ! -f "$log" ]; then
		return 0
	fi
	while IFS= read -r line || [ -n "$line" ]; do
		line="${line%$'\r'}"
		if [[ $line =~ $re ]]; then
			MATCH_COUNT=$((MATCH_COUNT + 1))
			MATCH_1="${BASH_REMATCH[1]:-}"
			MATCH_2="${BASH_REMATCH[2]:-}"
		fi
	done <"$log"
}

TOTAL_RUNS=31
STEP=0
# run_suite <file.gd> <fps> [timeout]: runs the clone's wrapper; sets RUN_RC and RUN_LOG.
run_suite() {
	local file="$1" fps="$2" t="${3:-}" name
	name="${file%.gd}"
	RUN_LOG="logs/${name}_${fps}fps.log"
	RUN_RC=0
	STEP=$((STEP + 1))
	echo "[$STEP/$TOTAL_RUNS] $file @ $fps fps${t:+ (timeout $t s)} -> $CLONE/$RUN_LOG"
	if [ -n "$t" ]; then
		./scripts/run-test.sh "$file" "$fps" "$t" >"logs/${name}_${fps}fps.wrapper.txt" 2>&1 || RUN_RC=$?
	else
		./scripts/run-test.sh "$file" "$fps" >"logs/${name}_${fps}fps.wrapper.txt" 2>&1 || RUN_RC=$?
	fi
}

# note_errors <observed>: appends the error-scan state to an observed value.
note_errors() {
	case "$ERR_STATE" in
		none) printf '%s' "$1" ;;
		found) printf '%s' "$1; error pattern in log" ;;
		missing) printf '%s' "log missing" ;;
		*) printf '%s' "$1; log unreadable" ;;
	esac
}

# counted <file.gd> <fps> <expected checks> <summary prefix>
counted() {
	local file="$1" fps="$2" expected="$3" prefix="$4" obs res="FAIL"
	run_suite "$file" "$fps"
	match_lines "$RUN_LOG" "^${prefix}: ([0-9]+) checks / ([0-9]+) failures\$"
	if [ "$MATCH_COUNT" -eq 1 ]; then
		obs="$MATCH_1 / $MATCH_2"
	elif [ "$MATCH_COUNT" -eq 0 ]; then
		obs="no summary line"
	else
		obs="$MATCH_COUNT summary lines"
	fi
	err_scan "$RUN_LOG"
	if [ "$RUN_RC" -eq 0 ] && [ "$MATCH_COUNT" -eq 1 ] && [ "$MATCH_1" = "$expected" ] && [ "$MATCH_2" = "0" ] \
		&& [ "$ERR_STATE" = "none" ]; then
		res="PASS"
	fi
	add_row C "$file" "$fps" "$expected / 0" "$(note_errors "$obs")" "$RUN_RC" "$res"
}

# ---------------------------------------------------------------- 2. import

echo "== 2. Import (empty cache): godot --headless --path godot --import"
IMPORT_LOG="logs/fresh_import.log"
IMPORT_RC=0
timeout 600 godot --headless --path godot --import >"$IMPORT_LOG" 2>&1 || IMPORT_RC=$?
echo "import exit code: $IMPORT_RC (log: $CLONE/$IMPORT_LOG)"
err_scan "$IMPORT_LOG"
IMPORT_RES="FAIL"
if [ "$IMPORT_RC" -eq 0 ] && [ "$ERR_STATE" = "none" ]; then
	IMPORT_RES="PASS"
fi
add_row I "godot --import" "-" "exit 0" "$(note_errors "exit $IMPORT_RC")" "$IMPORT_RC" "$IMPORT_RES"

# ---------------------------------------------------------------- 3. counted suites (26 runs)

echo "== 3. Counted suites, one at a time"
# file | fps list | expected checks | summary prefix (from each file's final print line)
SPECS=(
	"test_game.gd|60|25|WALKER TESTS"
	"test_slice.gd|60|61|SLICE TESTS"
	"test_keyboard.gd|60|12|KEYBOARD TESTS"
	"test_a3_assets.gd|60|36|A3 ASSET CHECKS"
	"test_fork_warning.gd|30 60 144|29|FORK WARNING TESTS"
	"test_materials.gd|30 60 144|108|MATERIAL CHECKS"
	"test_land_puff_config.gd|60|51|LAND PUFF CONFIG"
	"test_land_puff_state.gd|60|24|LAND PUFF STATE TESTS"
	"test_dome_glints_config.gd|60|45|DOME GLINTS CONFIG"
	"test_dome_glints_state.gd|60|27|DOME GLINTS STATE TESTS"
	"test_a7_pins.gd|30 60 144|31|A7 PINS"
	"test_a7_scoot_readback.gd|60|62|A7 SCOOT READBACK"
	"test_a7_land_readback.gd|60|135|A7 LAND READBACK"
	"test_a7_visual_structure.gd|60|29|A7 VISUAL STRUCTURE"
	"test_a7_visual_state.gd|30 60 144|132|A7 VISUAL STATE"
	"test_a7_edges.gd|30 60 144|397|A7 EDGES"
)
for spec in "${SPECS[@]}"; do
	IFS='|' read -r s_file s_fps_list s_expected s_prefix <<<"$spec"
	for s_fps in $s_fps_list; do
		counted "$s_file" "$s_fps" "$s_expected" "$s_prefix"
	done
done

# ---------------------------------------------------------------- 3b. supplemental (5 runs, not counted)

echo "== 3b. Supplemental runs (not counted)"
for s_fps in 30 60 144; do
	run_suite probe_a7_entry_order.gd "$s_fps"
	match_lines "$RUN_LOG" '^H3VERDICT .* pass=(yes|NO)$'
	if [ "$MATCH_COUNT" -eq 1 ]; then obs="pass=$MATCH_1"
	elif [ "$MATCH_COUNT" -eq 0 ]; then obs="no H3VERDICT line"
	else obs="$MATCH_COUNT H3VERDICT lines"; fi
	err_scan "$RUN_LOG"
	res="FAIL"
	if [ "$RUN_RC" -eq 0 ] && [ "$MATCH_COUNT" -eq 1 ] && [ "$MATCH_1" = "yes" ] && [ "$ERR_STATE" = "none" ]; then
		res="PASS"
	fi
	add_row S probe_a7_entry_order.gd "$s_fps" "H3 pass=yes" "$(note_errors "$obs")" "$RUN_RC" "$res"
done

run_suite cost_effects.gd 60 300
match_lines "$RUN_LOG" '^COST EFFECTS: .*control separates: (true|false)$'
if [ "$MATCH_COUNT" -eq 1 ]; then obs="separates: $MATCH_1"
elif [ "$MATCH_COUNT" -eq 0 ]; then obs="no COST EFFECTS line"
else obs="$MATCH_COUNT COST EFFECTS lines"; fi
err_scan "$RUN_LOG"
res="FAIL"
if [ "$RUN_RC" -eq 0 ] && [ "$MATCH_COUNT" -eq 1 ] && [ "$MATCH_1" = "true" ] && [ "$ERR_STATE" = "none" ]; then
	res="PASS"
fi
add_row S cost_effects.gd "60/300s" "separates: true" "$(note_errors "$obs")" "$RUN_RC" "$res"

run_suite check_lifecycle_peak.gd 60
match_lines "$RUN_LOG" '^PEAK puffs in the tree \(including queued for deletion\): ([0-9]+) \|'
PEAK_TREE_COUNT="$MATCH_COUNT"; PEAK_TREE="$MATCH_1"
match_lines "$RUN_LOG" '^PEAK puffs not queued for deletion: ([0-9]+) \|'
PEAK_LIVE_COUNT="$MATCH_COUNT"; PEAK_LIVE="$MATCH_1"
if [ "$PEAK_TREE_COUNT" -eq 1 ] && [ "$PEAK_LIVE_COUNT" -eq 1 ]; then
	obs="tree $PEAK_TREE, live $PEAK_LIVE"
else
	obs="PEAK lines: tree x$PEAK_TREE_COUNT, live x$PEAK_LIVE_COUNT"
fi
err_scan "$RUN_LOG"
res="FAIL"
if [ "$RUN_RC" -eq 0 ] && [ "$PEAK_TREE_COUNT" -eq 1 ] && [ "$PEAK_LIVE_COUNT" -eq 1 ] \
	&& [ "$PEAK_TREE" = "2" ] && [ "$PEAK_LIVE" = "2" ] && [ "$ERR_STATE" = "none" ]; then
	res="PASS"
fi
add_row S check_lifecycle_peak.gd 60 "peak 2 (both)" "$(note_errors "$obs")" "$RUN_RC" "$res"

# ---------------------------------------------------------------- 4 and 5. table, report

ROW_FMT='%-30s %-8s %-16s %-34s %-5s %s\n'
N_C=0; P_C=0; N_S=0; P_S=0
ALL_PASS=1
i=0
while [ "$i" -lt "${#R_SUITE[@]}" ]; do
	case "${R_GROUP[$i]}" in
		C) N_C=$((N_C + 1)); if [ "${R_RES[$i]}" = "PASS" ]; then P_C=$((P_C + 1)); fi ;;
		S) N_S=$((N_S + 1)); if [ "${R_RES[$i]}" = "PASS" ]; then P_S=$((P_S + 1)); fi ;;
	esac
	if [ "${R_RES[$i]}" != "PASS" ]; then ALL_PASS=0; fi
	i=$((i + 1))
done
if [ "$STEP" -ne "$TOTAL_RUNS" ]; then
	ALL_PASS=0
fi

print_group() {
	local g="$1" j=0
	while [ "$j" -lt "${#R_SUITE[@]}" ]; do
		if [ "${R_GROUP[$j]}" = "$g" ]; then
			printf "$ROW_FMT" "${R_SUITE[$j]}" "${R_MODE[$j]}" "${R_EXP[$j]}" "${R_OBS[$j]}" "${R_EXIT[$j]}" "${R_RES[$j]}"
		fi
		j=$((j + 1))
	done
}

render_report() {
	echo "A7 fresh-clone verification"
	echo "Ref:      $REF"
	echo "Commit:   $SHA"
	echo "$REF_NOTE"
	echo "Origin:   $ORIGIN"
	echo "Clone:    $CLONE"
	echo "Date:     $RUN_DATE (took ${SECONDS} s)"
	echo "Godot:    $GODOT_VERSION"
	echo "Wrapper:  the clone's ./scripts/run-test.sh; logs in $CLONE/logs/"
	echo
	printf "$ROW_FMT" "Suite" "Mode" "Expected" "Observed" "Exit" "Result"
	printf "$ROW_FMT" "-----" "----" "--------" "--------" "----" "------"
	echo "-- Import (empty cache)"
	print_group I
	echo "-- Counted suites"
	print_group C
	echo "-- Supplemental, not counted"
	print_group S
	echo
	echo "Counted suites:  $P_C of $N_C PASS (26 expected)"
	echo "Supplemental:    $P_S of $N_S PASS (not counted; 5 expected)"
	echo "Runs performed:  $STEP of $TOTAL_RUNS, plus the import"
	echo
	echo "Error-pattern check ($ERR_RE) over the import log and every test log:"
	if [ "${#ERR_LINES[@]}" -eq 0 ]; then
		echo "  no matches"
	else
		for e in "${ERR_LINES[@]}"; do
			echo "  $e"
		done
	fi
	echo
	if [ "$ALL_PASS" -eq 1 ]; then
		echo "OVERALL: PASS"
	else
		echo "OVERALL: FAIL"
	fi
}

mkdir -p "$REPORT_DIR"
render_report >"$REPORT"
echo
cat "$REPORT"
echo
echo "Report written to: $REPORT"
echo "The clone is left in place for inspection: $CLONE"
echo "Remove it when done with:  rm -rf \"$CLONE\""

if [ "$ALL_PASS" -eq 1 ]; then
	exit 0
fi
exit 1
