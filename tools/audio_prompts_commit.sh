#!/usr/bin/env bash
# Commit the Batch 3 prompts file and AUDIO-BRIEF.md BEFORE any audio generation.
# Run:  bash ~/Documents/walker-jellyhop-kiran-g/tools/audio_prompts_commit.sh
# Checks the repo (main at the slice commit, clean apart from this kit), shows the models and
# prompts, waits for you to type COMMIT, installs the two files, commits, pushes, and verifies.
# Stops with a STOPPED line on any problem; never pushes after a failed commit.
set -Eeuo pipefail
trap 'echo; echo "STOPPED: line $LINENO failed: $BASH_COMMAND" >&2; exit 1' ERR

REPO="${REPO:-$HOME/Documents/walker-jellyhop-kiran-g}"
EXPECTED_HEAD="${EXPECTED_HEAD:-7a51e0f}"
KIT="tools/audio-docs"
stop() { echo; echo "STOPPED: $*" >&2; exit 1; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }

cd "$REPO" || stop "repo not found at $REPO"
echo "== 1. Repo"
[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || stop "not on branch main"
HEAD_SHORT="$(git rev-parse --short=7 HEAD)"
[ "$HEAD_SHORT" = "$EXPECTED_HEAD" ] || stop "HEAD is $HEAD_SHORT, expected $EXPECTED_HEAD (the slice commit)"
git fetch -q
[ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ] || stop "local main differs from GitHub; tell Claude before continuing"
UNEXPECTED="$(git status --porcelain --untracked-files=all | grep -v -E '^\?\? (tools/audio_prompts_commit\.sh|tools/audio-docs/)' || true)"
[ -z "$UNEXPECTED" ] || stop "uncommitted changes other than this kit:
$UNEXPECTED"
[ ! -e gen-inputs/batch3-audio-prompts.md ] || stop "gen-inputs/batch3-audio-prompts.md already exists"
[ ! -e AUDIO-BRIEF.md ] || stop "AUDIO-BRIEF.md already exists"
[ ! -e "$HOME/Documents/jellyhop-generations/audio" ] || [ -z "$(ls -A "$HOME/Documents/jellyhop-generations/audio" 2>/dev/null)" ] || stop "~/Documents/jellyhop-generations/audio already has files: generation must come after this commit"
[ "$(sha "$KIT/gen-inputs/batch3-audio-prompts.md")" = "0f4e6f9f7f59b3103087627d1a01871122d4d0456410b175a2acf3f60dc3fc05" ] || stop "kit prompts file has an unexpected checksum"
[ "$(sha "$KIT/AUDIO-BRIEF.md")" = "07cad4a7b9d52332d9f830f05ab7e1844a54d909ff762103cb23738a599e2320" ] || stop "kit AUDIO-BRIEF.md has an unexpected checksum"
echo "main at $HEAD_SHORT, level with GitHub, clean apart from this kit; no audio generated yet; kit files verified"

echo; echo "== 2. What will be committed"
echo "Models and prompts in gen-inputs/batch3-audio-prompts.md:"
grep -E '^\| (Stable|MusicGen|The six|The music)|^\| (SFX|MUS)-' "$KIT/gen-inputs/batch3-audio-prompts.md" | cut -c1-150
echo
read -r -p "Type COMMIT to install these two files, commit, and push; anything else stops with nothing changed: " ANSWER
[ "$ANSWER" = "COMMIT" ] || stop "not confirmed; nothing changed (run the script again when ready)"
cp "$KIT/gen-inputs/batch3-audio-prompts.md" gen-inputs/batch3-audio-prompts.md
cp "$KIT/AUDIO-BRIEF.md" AUDIO-BRIEF.md
rm -r "$KIT"
echo "installed gen-inputs/batch3-audio-prompts.md and AUDIO-BRIEF.md"

echo; echo "== 3. Commit and push"
git add gen-inputs/batch3-audio-prompts.md AUDIO-BRIEF.md tools/audio_prompts_commit.sh
git status --short
[ "$(git diff --cached --name-only | wc -l | tr -d ' ')" = "3" ] || stop "expected 3 staged files (nothing committed)"
[ -z "$(git status --porcelain --untracked-files=all | grep -v '^A  ' || true)" ] || stop "files left unstaged or untracked (nothing committed)"
if ! git commit -q -m "Add Batch 3 audio prompts, models and AUDIO-BRIEF before any audio generation"; then
  stop "commit failed; nothing pushed"
fi
git log --oneline -1
git push
git fetch -q
[ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ] || stop "push not confirmed: local HEAD differs from GitHub"
echo "PUSHED: GitHub now matches $(git rev-parse --short=7 HEAD). Prompts are committed; generation can start."
