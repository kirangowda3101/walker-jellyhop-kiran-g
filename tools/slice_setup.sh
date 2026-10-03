#!/usr/bin/env bash
# Slice setup for Jelly Hop: Fork From Above (before any slice code).
# Run:  bash ~/Documents/walker-jellyhop-kiran-g/tools/slice_setup.sh
#
# 1. Checks the repo (at the Batch 2 commit, clean), Godot, Claude Code, and the
#    Brutalist godot-gamedev skill in ~/Documents/brutalist.art.
# 2. Gets the walker-jumpman starter (clones it to ~/Documents/walker-jumpman-upstream
#    if not there) and records its commit.
# 3. Waits for you to type SETUP.
# 4. Commit A: imports the starter's godot/ folder and launcher UNCHANGED, verified
#    blob-by-blob against the starter's own commit.
# 5. Commit B: SLICE-BRIEF.md, CLAUDE.md, the SOURCES.md starter credit, a FRICTIONAL
#    entry, and this run's log. Pushes and verifies GitHub matches.
# Stops with a STOPPED line on any problem; never pushes after a failed commit.
set -Eeuo pipefail
trap 'echo; echo "STOPPED: line $LINENO failed: $BASH_COMMAND" >&2; exit 1' ERR

REPO="${REPO:-$HOME/Documents/walker-jellyhop-kiran-g}"
UPSTREAM="${UPSTREAM:-$HOME/Documents/walker-jumpman-upstream}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/nikbearbrown/walker-jumpman.git}"
BRUTALIST="${BRUTALIST:-$HOME/Documents/brutalist.art}"
EXPECTED_HEAD="${EXPECTED_HEAD:-e6f1644}"
KIT="tools/slice-docs"

stop() { echo; echo "STOPPED: $*" >&2; exit 1; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }

cd "$REPO" || stop "repo not found at $REPO"
mkdir -p evidence
LOG="evidence/slice-setup-log.txt"
: > "$LOG"
say() { echo "$*" | tee -a "$LOG"; }

say "== Slice setup  $(date '+%Y-%m-%d %H:%M')"

# ---- 1. checks ----
[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || stop "not on branch main"
HEAD_SHORT="$(git rev-parse --short=7 HEAD)"
[ "$HEAD_SHORT" = "$EXPECTED_HEAD" ] || stop "HEAD is $HEAD_SHORT, expected $EXPECTED_HEAD (the Batch 2 commit)"
UNEXPECTED="$(git status --porcelain --untracked-files=all | grep -v -E '^\?\? (tools/slice_setup\.sh|tools/slice-docs/|evidence/slice-setup-log\.txt)' || true)"
[ -z "$UNEXPECTED" ] || stop "uncommitted changes other than the setup kit:
$UNEXPECTED"
[ ! -e godot ] || stop "a godot/ folder already exists in the repo"
[ ! -e SLICE-BRIEF.md ] || stop "SLICE-BRIEF.md already exists"
[ ! -e CLAUDE.md ] || stop "CLAUDE.md already exists"
for f in SLICE-BRIEF.md CLAUDE.md frictional_entry.md; do
  [ -f "$KIT/$f" ] || stop "$KIT/$f missing (unzip slice-setup-kit.zip into the repo first)"
done
check_sha() { [ "$(sha "$1")" = "$2" ] || stop "$1 does not have the expected checksum ($3)"; }
check_sha FRICTIONAL.md b23ea5fde3f8f7fa1020b46014891df7c1f2335b7aacc3778b8fa40c98d05463 "changed since the Batch 2 commit"
check_sha SOURCES.md 0ae7d20ec23645e73c0b0d25b15943d543fcfd9e8e9d7909d08e6465990b04f5 "changed since the Batch 2 commit"
check_sha "$KIT/SLICE-BRIEF.md" b4b17a979b7d38674c3d69ad2a754e5dcb8bd68529bbe4a947fabe9e1d29dfa4 "kit file"
check_sha "$KIT/CLAUDE.md" bc11cee3f25fa1f2291f3e12341c668c3ff69458fce4b56c6173713f8c082ec3 "kit file"
check_sha "$KIT/frictional_entry.md" f64d3a2f97214bd5b100016990a47fa47304e514af86ee7fdb8e79a496475219 "kit file"
say "repo: main at $HEAD_SHORT, clean apart from the setup kit; kit files verified"

GODOT=""
if command -v godot >/dev/null 2>&1; then GODOT="$(command -v godot)"; fi
if [ -z "$GODOT" ] && [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then GODOT=/Applications/Godot.app/Contents/MacOS/Godot; fi
[ -n "$GODOT" ] || stop "Godot not found (looked for 'godot' on PATH and /Applications/Godot.app). Install Godot 4.7.2 (standard, not .NET) into Applications, then rerun."
GODOT_VERSION="$("$GODOT" --version 2>/dev/null | tail -n 1 | tr -d '\r')"
[ -n "$GODOT_VERSION" ] || stop "could not read the Godot version from $GODOT"
say "Godot: $GODOT_VERSION ($GODOT)"
case "$GODOT_VERSION" in 4.7.2.*) ;; *) say "NOTE: the starter's tested engine is 4.7.2; this Mac has $GODOT_VERSION" ;; esac

if command -v claude >/dev/null 2>&1; then
  say "Claude Code: $(claude --version 2>/dev/null | head -n 1)"
else
  say "NOTE: Claude Code ('claude') is not on PATH. It is needed for the next step, not for this setup."
fi

if [ -d "$BRUTALIST/.git" ]; then
  BCOMMIT="$(git -C "$BRUTALIST" rev-parse --short=7 HEAD)"
  # The skill is the folder holding SKILL.md under skills/ (not the example films under youtube/).
  GG="$(cd "$BRUTALIST" && find ./skills -maxdepth 4 -type f -name SKILL.md -path '*/godot-gamedev/*' 2>/dev/null | head -n 1)"
  if [ -n "$GG" ]; then
    GGDIR="$(dirname "${GG#./}")"
    DESC="$(tr '\n' ' ' < "$BRUTALIST/${GG#./}" | tr -s ' ')"
    if echo "$DESC" | grep -q "Does not build or publish a game"; then
      SKILL="\`godot-gamedev\` found in my brutalist.art clone at \`$GGDIR\` (commit \`$BCOMMIT\`); its SKILL.md describes it as making a Liam-narrated Godot development film, using \`walker\` for Claude/GDD bookends, and says it \"Does not build or publish a game\""
    else
      SKILL="\`godot-gamedev\` found in my brutalist.art clone at \`$GGDIR\` (commit \`$BCOMMIT\`)"
    fi
  else
    SKILL="\`godot-gamedev\` SKILL.md NOT found under skills/ in my brutalist.art clone (commit \`$BCOMMIT\`); to be requested as the course-provided version before the film"
  fi
else
  SKILL="no brutalist.art clone at ~/Documents/brutalist.art; \`godot-gamedev\` to be located before the film"
fi
say "Brutalist skill: $SKILL"

# ---- 2. starter ----
if [ ! -d "$UPSTREAM/.git" ]; then
  say "cloning the starter into $UPSTREAM"
  git clone -q "$UPSTREAM_URL" "$UPSTREAM"
fi
STARTER="$(git -C "$UPSTREAM" rev-parse HEAD)"
STARTER_SHORT="$(git -C "$UPSTREAM" rev-parse --short=7 HEAD)"
STARTER_ORIGIN="$(git -C "$UPSTREAM" remote get-url origin)"
say "starter: $STARTER_ORIGIN at $STARTER_SHORT ($(git -C "$UPSTREAM" log -1 --format='%ad, %s' --date=short | cut -c1-80))"
git -C "$UPSTREAM" cat-file -e "HEAD:godot/project.godot" 2>/dev/null || stop "the starter has no godot/project.godot at $STARTER_SHORT"
IMPORT_PATHS="godot"
if git -C "$UPSTREAM" cat-file -e "HEAD:walker-jumpman.command" 2>/dev/null; then IMPORT_PATHS="godot walker-jumpman.command"; fi
LICENSE_FILES="$(git -C "$UPSTREAM" ls-tree --name-only HEAD | grep -i -E '^(license|licence|copying)' || true)"
if [ -n "$LICENSE_FILES" ]; then LICENSE="$(echo "$LICENSE_FILES" | tr '\n' ' ' | sed 's/ $//')"; else LICENSE="none in the starter repository"; fi
say "importing: $IMPORT_PATHS (license file: $LICENSE)"

echo
read -r -p "Type SETUP to import the starter, commit, and push; anything else stops with nothing changed: " ANSWER
[ "$ANSWER" = "SETUP" ] || stop "not confirmed; nothing changed"

# ---- 3. commit A: unchanged starter import ----
# git archive writes exactly the starter's committed files (nothing untracked, no .godot/ cache).
git -C "$UPSTREAM" archive --format=tar HEAD $IMPORT_PATHS | tar -x -f - -C .
git add $IMPORT_PATHS
# Verify blob-by-blob: same paths and same contents as the starter's commit.
diff <(git -C "$UPSTREAM" ls-tree -r HEAD $IMPORT_PATHS | awk '{print $3, $4}') \
     <(git ls-files -s $IMPORT_PATHS | awk '{print $2, $4}') >/dev/null \
  || stop "imported files differ from the starter's commit (nothing committed; 'git reset' and delete godot/ to undo)"
NFILES="$(git ls-files $IMPORT_PATHS | wc -l | tr -d ' ')"
[ -z "$(git diff --cached --name-only | grep -v -E "^(godot/|walker-jumpman\.command$)" || true)" ] || stop "something other than the starter is staged"
if ! git commit -q -m "Import walker-jumpman starter unchanged ($STARTER_ORIGIN at $STARTER_SHORT): $IMPORT_PATHS"; then
  stop "commit A failed; nothing pushed"
fi
IMPORT="$(git rev-parse --short=7 HEAD)"
say "commit A: $IMPORT  ($NFILES starter files, identical to $STARTER_SHORT)"

# ---- 4. commit B: brief, rules, credit, log entry ----
cp "$KIT/SLICE-BRIEF.md" SLICE-BRIEF.md
cp "$KIT/CLAUDE.md" CLAUDE.md
export STARTER_SHORT IMPORT GODOT_VERSION SKILL LICENSE STARTER_ORIGIN
python3 - "$KIT/frictional_entry.md" <<'PY'
import os, sys
e = os.environ
fill = lambda t: (t.replace("{{STARTER}}", e["STARTER_SHORT"]).replace("{{IMPORT}}", e["IMPORT"])
                   .replace("{{GODOT}}", e["GODOT_VERSION"]).replace("{{SKILL}}", e["SKILL"])
                   .replace("{{LICENSE}}", e["LICENSE"]))
entry = fill(open(sys.argv[1]).read())
assert "{{" not in entry, "unfilled placeholder in the FRICTIONAL entry"
with open("FRICTIONAL.md", "a") as f:
    f.write(entry)
s = open("SOURCES.md").read()
old_start = "- Not decided yet: an empty Godot 4 project or the walker-jumpman structure. No Godot project exists in this repository yet. Whichever I start from will be credited here."
assert s.count(old_start) == 1, "SOURCES.md starting-point line not found"
url = e["STARTER_ORIGIN"].removesuffix(".git")
new_start = (f"- **walker-jumpman** \"First Steps\" starter by Nik Bear Brown ({url}), commit `{e['STARTER_SHORT']}`, "
             f"imported unchanged into `godot/` (with its launcher, if present) in this repository's commit `{e['IMPORT']}`, "
             f"so every later change to it is a visible diff. The starter's other documents were not imported. "
             f"License file in the starter: {e['LICENSE']}.")
s = s.replace(old_start, new_start)
old_tools = "- **Draw Things** 26.0924.0 (260924.0), free macOS app."
assert s.count(old_tools) == 1, "SOURCES.md Draw Things line not found"
s = s.replace(old_tools, f"- **Godot** `{e['GODOT_VERSION']}` (engine for the slice).\n" + old_tools)
old_collab = "- **Me (Kiran):**"
assert s.count(old_collab) == 1, "SOURCES.md collaborator line not found"
s = s.replace(old_collab, "- **Claude Code** (Anthropic): builds the slice in this repository from SLICE-BRIEF.md under the rules in CLAUDE.md (from 2026-10-02).\n" + old_collab)
open("SOURCES.md", "w").write(s)
PY
rm -r "$KIT"
say "installed SLICE-BRIEF.md, CLAUDE.md; SOURCES.md credits the starter; FRICTIONAL.md has the setup entry"
say "starter import: $IMPORT; next: open Claude Code in this folder (see the chat for the first prompt)"

git add SLICE-BRIEF.md CLAUDE.md SOURCES.md FRICTIONAL.md tools/slice_setup.sh "$LOG"
git status --short
NSTAGED="$(git diff --cached --name-only | wc -l | tr -d ' ')"
[ "$NSTAGED" = "6" ] || stop "expected 6 staged files, found $NSTAGED (commit A is local only; nothing pushed)"
[ -z "$(git status --porcelain --untracked-files=all | grep -v '^[AM]  ' || true)" ] || stop "files left unstaged or untracked (shown above); commit A is local only; nothing pushed"
if ! git commit -q -m "Slice setup before any slice code: SLICE-BRIEF.md, CLAUDE.md, starter credit in SOURCES.md, FRICTIONAL entry, setup script and log"; then
  stop "commit B failed; nothing pushed"
fi
git log --oneline -3
git push
git fetch -q
[ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ] || stop "push not confirmed: local HEAD differs from GitHub"
echo "PUSHED: GitHub now matches $(git rev-parse --short=7 HEAD) (starter import $IMPORT)."
