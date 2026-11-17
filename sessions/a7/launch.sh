#!/usr/bin/env bash
# Usage: bash sessions/a7/launch.sh <name> "<edit paths, space-separated>" "<extra allowed tools, comma-separated>" [max-turns]
# Runs sessions/a7/prompt-<name>.txt as a fresh, scoped claude -p session; transcript to sessions/a7/session-<name>.jsonl.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
repo="$PWD"; name="$1"; edits="$2"; extra="$3"; turns="${4:-80}"
prompt="sessions/a7/prompt-$name.txt"; out="sessions/a7/session-$name.jsonl"
[ -f "$prompt" ] || { echo "STOPPED: $prompt missing"; exit 1; }
[ -e "$out" ] && { echo "STOPPED: $out exists; transcript preserved"; exit 1; }
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "STOPPED: tracked files have uncommitted changes"; git status --short --untracked-files=no; exit 1
fi
deny_saved="$(python3 - "$repo" <<'PY'
import json, os, sys
repo = sys.argv[1]
paths = [os.path.expanduser("~/.claude/settings.json"), os.path.expanduser("~/.claude/settings.local.json"),
         os.path.join(repo, ".claude/settings.json"), os.path.join(repo, ".claude/settings.local.json"),
         "/Library/Application Support/ClaudeCode/managed-settings.json"]
widen, bash = False, []
for p in paths:
    if not os.path.exists(p): continue
    try: perms = json.load(open(p)).get("permissions", {}) or {}
    except Exception as e: print(f"UNREADABLE {p}: {e}", file=sys.stderr); widen = True; continue
    for r in perms.get("allow", []) or []:
        if r == "Bash": print(f"WIDENS: {p}: blanket Bash", file=sys.stderr); widen = True
        elif r.startswith("Bash("): bash.append(r)
        else: print(f"WIDENS: {p}: allow {r}", file=sys.stderr); widen = True
    if perms.get("additionalDirectories"): print(f"WIDENS: {p}: additionalDirectories", file=sys.stderr); widen = True
if any("," in r for r in bash): print("WIDENS: comma in a saved Bash rule", file=sys.stderr); widen = True
print(",".join(dict.fromkeys(bash)))
sys.exit(1 if widen else 0)
PY
)" || { echo "STOPPED: saved settings would widen the scope"; exit 1; }
tools="Read,Glob,Grep"; allow="Read,Glob,Grep"
deny="Edit(godot/shaders/**),Edit(godot/effects/**)${deny_saved:+,$deny_saved}"
if [ -n "$edits" ]; then tools="$tools,Edit,Write"; for p in $edits; do allow="$allow,Edit(/$repo/$p)"; done
else deny="$deny,Edit,Write"; fi
if [ -n "$extra" ]; then tools="$tools,Bash"; allow="$allow,$extra"; else deny="$deny,Bash"; fi
before="$(mktemp)"; git status --porcelain > "$before"
echo "prompt: $prompt sha256 $(shasum -a 256 "$prompt" | cut -c1-16)…"
echo "tools: $tools"; echo "allow: $allow"
echo "Running Claude Code ($name). Quiet until it finishes..."
caffeinate -i claude -p "$(cat "$prompt")" --tools "$tools" --strict-mcp-config --permission-mode dontAsk \
  --allowedTools "$allow" --disallowedTools "$deny" --max-turns "$turns" \
  --output-format stream-json --verbose > "$out" < /dev/null
echo "claude exit: $?"
python3 - "$out" <<'PY'
import json, sys, collections
ev = []
for l in open(sys.argv[1], encoding="utf-8"):
    l = l.strip()
    if l:
        try: ev.append(json.loads(l))
        except Exception: pass
init = next((e for e in ev if e.get("type") == "system" and e.get("subtype") == "init"), {})
print("permissionMode:", init.get("permissionMode"), "| tools:", init.get("tools"), "| mcp:", init.get("mcp_servers"))
bash, files = collections.Counter(), collections.Counter()
for e in ev:
    if e.get("type") == "assistant":
        for c in (e.get("message", {}) or {}).get("content", []) or []:
            if c.get("type") == "tool_use":
                i = c.get("input", {}) or {}
                if c.get("name") == "Bash": bash[i.get("command", "")[:160]] += 1
                if c.get("name") in ("Edit", "Write"): files[i.get("file_path", "")] += 1
print("Bash:"); [print(f"  {v}x {k}") for k, v in bash.items()]
print("Edited:"); [print(f"  {v}x {k}") for k, v in files.items()]
r = next((e for e in reversed(ev) if e.get("type") == "result"), {})
print("result:", r.get("subtype"), "| error:", r.get("is_error"), "| turns:", r.get("num_turns"), "| reason:", r.get("terminal_reason"))
d = r.get("permission_denials") or []
print("denials:", len(d)); [print("  ", x.get("tool_name"), (x.get("tool_input") or {}).get("command") or (x.get("tool_input") or {}).get("file_path")) for x in d]
print("===== agent report ====="); print(r.get("result", "(no result text)"))
PY
echo "----- status changes since launch ('>' = new) -----"
git status --porcelain | diff "$before" - | grep '^[<>]' || echo "(none)"
echo "----- tracked diff -----"; git diff --stat
rm -f "$before"
