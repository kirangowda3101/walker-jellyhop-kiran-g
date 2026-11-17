#!/usr/bin/env bash
# sessions/a7/mutations.sh — A7 Step 6: mutations and fresh import (CHANGE-BRIEF.md, "Evidence and frame strips",
# row "Mutations and fresh import"). Written by the agent (Step 6 session); Kiran reviews and runs it.
#
# Usage, from the repository root:   bash sessions/a7/mutations.sh
#
# For each of M1-M4:
#   a) adds a detached worktree at ../a7-mutate from HEAD (uncommitted changes in the main tree are NOT in it);
#   b) applies one exact text replacement after checking the old text occurs exactly once (M4: none);
#   c) runs `godot --headless --path godot --import` in the worktree (no godot/.godot there: an empty cache);
#   d) runs the named read-back test through the worktree's ./scripts/run-test.sh at 60 fps;
#   e) removes the worktree with `git worktree remove --force`, also after a failure (EXIT trap).
# Evidence goes to evidence/a7-mutations/ in the main repository: summary.txt (one row per mutation),
# fail_lines.txt (every FAIL and track-problem line of every test log), and per mutation <M>_diff.txt,
# <M>_import.txt and <M>_<test>_60fps.log. Nothing else in the main working tree is written.
# Exit status: 0 only if M1-M3 are CONFIRMED and M4 PASSED AS EXPECTED; 1 otherwise (after writing the summary).

set -Eeuo pipefail
trap 'rc=$?; echo "STOPPED: command \"$BASH_COMMAND\" failed with exit $rc (line $LINENO)" >&2' ERR

# ---------------------------------------------------------------- preflight (nothing is created before these pass)

REPO="$(git rev-parse --show-toplevel)"
if [ "$(pwd -P)" != "$(cd "$REPO" && pwd -P)" ]; then
	echo "STOPPED: run this from the repository root: $REPO" >&2
	exit 1
fi
WT="$(cd "$REPO/.." && pwd -P)/a7-mutate"
EV="$REPO/evidence/a7-mutations"
if [ -e "$WT" ]; then
	echo "STOPPED: $WT already exists. Check what it is and remove it yourself; this script never touches it." >&2
	exit 1
fi
wt_list="$(git worktree list --porcelain)"
if grep -qxF "worktree $WT" <<<"$wt_list"; then
	echo "STOPPED: git still registers a worktree at $WT (directory gone). Check, then run: git worktree prune" >&2
	exit 1
fi
if [ -e "$EV/summary.txt" ] || [ -e "$EV/fail_lines.txt" ]; then
	echo "STOPPED: $EV already holds results; move them aside first so earlier evidence is not overwritten." >&2
	exit 1
fi
for tool in git godot timeout awk sed grep wc tr cp; do
	if ! command -v "$tool" > /dev/null; then
		echo "STOPPED: required command not found: $tool" >&2
		exit 1
	fi
done
if [ ! -x scripts/run-test.sh ]; then
	echo "STOPPED: scripts/run-test.sh missing or not executable" >&2
	exit 1
fi

HEAD_SHA="$(git rev-parse HEAD)"
GODOT_VERSION="$(godot --version)"
mkdir -p "$EV"

on_exit() {
	local status=$?
	if [ -e "$WT" ]; then
		echo "Cleaning up: git worktree remove --force $WT" >&2
		if ! git -C "$REPO" worktree remove --force "$WT"; then
			echo "WARNING: could not remove $WT; remove it by hand (git worktree remove --force $WT)" >&2
			status=1
		fi
	fi
	exit "$status"
}
trap on_exit EXIT   # set only after preflight, so a pre-existing ../a7-mutate is never removed

# ---------------------------------------------------------------- helpers

strip_ansi() {   # file -> stdout without terminal colour codes
	LC_ALL=C sed -e $'s/\033\\[[0-9;]*m//g' "$1"
}

count_of() {     # number of occurrences of literal text $1 in file $2
	local n
	n="$( { grep -o -F -- "$1" "$2" || true; } | wc -l | tr -d '[:space:]')"
	echo "$n"
}

replace_once() { # file old new: replaces the single occurrence (count checked by the caller); keeps trailing newlines
	local f="$1" old="$2" new="$3" content prefix suffix
	content="$(cat -- "$f"; printf x)"
	content="${content%x}"
	prefix="${content%%"$old"*}"
	suffix="${content#*"$old"}"
	printf '%s' "$prefix$new$suffix" > "$f"
}

has_prefix_line() { # prefix file: a line starting with the prefix exists
	strip_ansi "$2" | awk -v p="$1" 'index($0, p) == 1 { f = 1 } END { exit (f ? 0 : 1) }'
}

has_exact_line() {  # line file: exactly this line exists
	strip_ansi "$2" | awk -v p="$1" '$0 == p { f = 1 } END { exit (f ? 0 : 1) }'
}

remove_worktree() {
	git -C "$REPO" worktree remove --force "$WT"
	if [ -e "$WT" ]; then
		echo "STOPPED: $WT still exists after git worktree remove --force" >&2
		exit 1
	fi
}

add_worktree() {
	git -C "$REPO" worktree add --detach "$WT" HEAD
}

IMPORT_RC=""
IMPORT_OK=0
do_import() {    # name: import in the worktree; output to evidence/a7-mutations/<name>_import.txt
	local out="$EV/$1_import.txt" bad
	IMPORT_RC=0
	(cd "$WT" && timeout 600 godot --headless --path godot --import) > "$out" 2>&1 || IMPORT_RC=$?
	bad="$( { strip_ansi "$out" | grep -cE 'Failed loading resource|SCRIPT ERROR'; } || true)"
	IMPORT_OK=1
	if [ "$IMPORT_RC" != "0" ] || [ "$bad" != "0" ]; then
		IMPORT_OK=0
	fi
	echo "$1 import: exit $IMPORT_RC, 'Failed loading resource'/'SCRIPT ERROR' lines: $bad"
}

TEST_RC=""
TEST_LOG=""
TEST_SUMMARY=""
run_test() {     # name test: runs the worktree's wrapper at 60 fps and copies its log to evidence
	local name="$1" test="$2" base wlog
	base="${test%.gd}"
	wlog="$WT/logs/${base}_60fps.log"
	rm -f "$wlog"   # in the throwaway worktree only: never copy a committed log by mistake
	TEST_RC=0
	# The wrapper tees the full output into its own log, which is copied below.
	(cd "$WT" && ./scripts/run-test.sh "$test" 60) > /dev/null 2>&1 || TEST_RC=$?
	TEST_LOG=""
	TEST_SUMMARY="none"
	if [ -f "$wlog" ]; then
		TEST_LOG="$EV/${name}_${base}_60fps.log"
		cp "$wlog" "$TEST_LOG"
		local s
		s="$( { strip_ansi "$TEST_LOG" | grep -E '^A7 (LAND|SCOOT) READBACK: [0-9]+ checks / [0-9]+ failures'; } || true)"
		if [ -n "$s" ]; then
			TEST_SUMMARY="$s"
		fi
		{
			echo "## $name $test (wrapper exit $TEST_RC)"
			{ strip_ansi "$TEST_LOG" | grep -E '^FAIL |^  track problem: '; } || echo "(no FAIL lines)"
			echo
		} >> "$EV/fail_lines.txt"
	else
		echo "## $name $test (wrapper exit $TEST_RC): NO LOG at $wlog" >> "$EV/fail_lines.txt"
	fi
	echo "$name $test: wrapper exit $TEST_RC; $TEST_SUMMARY"
}

row() {          # 11 tab-separated fields
	printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@" >> "$EV/summary.txt"
}

ALL_AS_INTENDED=1

# ---------------------------------------------------------------- M1-M3: one text change, one read-back

# name file old new test intended_prefix intended_exact_line ("" if none)
mutation() {
	local name="$1" file="$2" old="$3" new="$4" test="$5" want_prefix="$6" want_exact="$7"
	local applied="no" import_col="n.a." actual="n.a." found="n.a." summary="n.a." verdict="" note=""
	echo
	echo "=== $name: $file: '$old' -> '$new'; test $test"
	add_worktree
	local f="$WT/$file" n changed
	if [ ! -f "$f" ]; then
		verdict="SETUP FAILED"; note="$file not found in the worktree"
	elif [ ! -f "$WT/godot/tests/$test" ]; then
		verdict="SETUP FAILED"; note="godot/tests/$test not in HEAD"
	else
		n="$(count_of "$old" "$f")"
		if [ "$n" != "1" ]; then
			verdict="SETUP FAILED"; note="text not found: old text occurs $n times, exactly 1 required"
		else
			replace_once "$f" "$old" "$new"
			changed="$(git -C "$WT" diff --name-only)"
			git -C "$WT" diff > "$EV/${name}_diff.txt"
			if [ "$(count_of "$old" "$f")" != "0" ] || [ "$(count_of "$new" "$f")" != "1" ] || [ "$changed" != "$file" ]; then
				verdict="SETUP FAILED"; note="replacement not verified (changed files: ${changed:-none})"
			else
				applied="yes"
			fi
		fi
	fi
	if [ "$applied" = "yes" ]; then
		do_import "$name"
		import_col="$IMPORT_RC"
		run_test "$name" "$test"
		actual="$TEST_RC"
		summary="$TEST_SUMMARY"
		found="no"
		if [ -n "$TEST_LOG" ] && has_prefix_line "$want_prefix" "$TEST_LOG"; then
			found="yes"
			if [ -n "$want_exact" ] && ! has_exact_line "$want_exact" "$TEST_LOG"; then
				found="no"
			fi
		fi
		note="intended: '$want_prefix ...'"
		if [ -n "$want_exact" ]; then
			note="$note and '$want_exact'"
		fi
		if [ "$IMPORT_OK" != "1" ]; then
			verdict="IMPORT FAILED"; note="$note; import failed, test result not counted"
		elif [ "$TEST_RC" = "1" ] && [ "$found" = "yes" ]; then
			verdict="CONFIRMED"
		elif [ "$TEST_RC" = "0" ]; then
			verdict="NOT AS EXPECTED"; note="$note; the test passed, so the mutation was not caught"
		else
			verdict="FAILED FOR ANOTHER REASON"
		fi
	fi
	row "$name" "$file" "$applied" "$import_col" "$test" "1" "$actual" "$found" "$summary" "$verdict" "$note"
	if [ "$verdict" != "CONFIRMED" ]; then
		ALL_AS_INTENDED=0
	fi
	echo "$name verdict: $verdict"
	remove_worktree
}

# ---------------------------------------------------------------- M4: fresh cache, no change, both read-backs

fresh_cache() {
	local name="M4" t1="test_a7_land_readback.gd" t2="test_a7_scoot_readback.gd"
	local import_col="n.a." actual="n.a." summary="n.a." verdict="" cache_before cache_after="n.a."
	local reason="native rig: the loop modes are saved in the clip resources (land.tres LOOP_NONE; scoot.tres LOOP_LINEAR, the loop) and survive a fresh-cache import, unlike an imported clip edited in a scene"
	local note="$reason"
	echo
	echo "=== $name: fresh cache, no text change; tests $t1 and $t2"
	add_worktree
	cache_before="absent"
	if [ -e "$WT/godot/.godot" ]; then
		cache_before="present"
	fi
	if [ "$cache_before" != "absent" ]; then
		verdict="SETUP FAILED"; note="godot/.godot exists in the fresh worktree, so the cache is not empty"
	elif [ ! -f "$WT/godot/tests/$t1" ] || [ ! -f "$WT/godot/tests/$t2" ]; then
		verdict="SETUP FAILED"; note="a read-back test is not in HEAD"
	else
		do_import "$name"
		import_col="$IMPORT_RC"
		cache_after="absent"
		if [ -d "$WT/godot/.godot" ]; then
			cache_after="present"
		fi
		run_test "$name" "$t1"
		local rc1="$TEST_RC" s1="$TEST_SUMMARY"
		run_test "$name" "$t2"
		local rc2="$TEST_RC" s2="$TEST_SUMMARY"
		actual="$rc1, $rc2"
		summary="$s1 | $s2"
		note="cache before import: $cache_before, after: $cache_after; $reason"
		if [ "$IMPORT_OK" != "1" ]; then
			verdict="IMPORT FAILED"
		elif [ "$rc1" = "0" ] && [ "$rc2" = "0" ] && [[ "$s1" == *" / 0 failures" ]] && [[ "$s2" == *" / 0 failures" ]]; then
			verdict="PASSED AS EXPECTED"
		else
			verdict="NOT AS EXPECTED"
		fi
	fi
	row "$name" "none (fresh cache)" "n.a. (no change)" "$import_col" "$t1 + $t2" "0, 0" "$actual" "n.a." "$summary" "$verdict" "$note"
	if [ "$verdict" != "PASSED AS EXPECTED" ]; then
		ALL_AS_INTENDED=0
	fi
	echo "$name verdict: $verdict"
	remove_worktree
}

# ---------------------------------------------------------------- run

{
	echo "# A7 mutations and fresh import (sessions/a7/mutations.sh)"
	echo "# run: $(date -u +%Y-%m-%dT%H:%M:%SZ)  HEAD: $HEAD_SHA  godot: $GODOT_VERSION"
	echo "# worktree: $WT (detached, from HEAD; removed after each mutation)"
	echo "# Each test: ./scripts/run-test.sh <test> 60 inside the worktree. Import: godot --headless --path godot --import."
	echo "# CONFIRMED = import succeeded, test exit 1, and its log contains the intended FAIL line."
	printf 'name\tfile\tapplied\timport_exit\ttest\texpected_exit\tactual_exit\tintended_fail_line_found\tsummary_line\tverdict\tnote\n'
} > "$EV/summary.txt"
: > "$EV/fail_lines.txt"

mutation M1 "godot/animations/land.tres" "UpperPivot:position" "UpperPivot:positon" "test_a7_land_readback.gd" \
	"FAIL every track of every clip resolves (track_problems):" \
	"  track problem: land track 1: UpperPivot has no property positon"

mutation M2 "godot/animations/scoot.tres" "loop_mode = 1" "loop_mode = 0" "test_a7_scoot_readback.gd" \
	"FAIL loop_mode LOOP_LINEAR:" ""

mutation M3 "godot/animations/scoot.tres" '"values": [0, 1]' '"values": [0, 2]' "test_a7_scoot_readback.gd" \
	"FAIL every frame key in 0..hframes*vframes-1:" ""

fresh_cache

echo
echo "===== $EV/summary.txt"
cat "$EV/summary.txt"
if [ "$ALL_AS_INTENDED" != "1" ]; then
	echo "RESULT: at least one mutation did not behave as intended (see verdicts above)." >&2
	exit 1
fi
echo "RESULT: M1-M3 CONFIRMED, M4 PASSED AS EXPECTED."
