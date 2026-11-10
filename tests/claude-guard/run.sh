#!/usr/bin/env bash
# Feeds the PreToolUse samples in cases.jsonl to claude-guard and checks the decision
# (allow = no output). Usage: tests/claude-guard/run.sh [path/to/claude-guard]
# Default is the Python source; pass the built script to test the Nix output.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd -P)
root=$(cd "$here/../.." && pwd -P)
guard=${1:-"$root/modules/shared/claude-code/claude-guard.py"}
case "$guard" in *.py) run=(python3 "$guard") ;; *) run=("$guard") ;; esac

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export CLAUDE_GUARD_LOG_DIR="$work/log"
export CLAUDE_GUARD_POLICY="$root/modules/shared/claude-code/guard-policy.json"

# Two throwaway repos: one on main, one on a feature branch.
for pair in main:main feat:feat/CO-84-test; do
  dir="$work/${pair%%:*}"
  git init -q -b "${pair#*:}" "$dir"
  git -C "$dir" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
done

pass=0 fail=0 allow=0 deny=0 ask=0 blocks=0
while IFS= read -r line; do
  name=$(jq -r .name <<<"$line")
  expect=$(jq -r .expect <<<"$line")
  input=$(jq -c .input <<<"$line" | sed "s#@MAIN@#$work/main#g; s#@FEAT@#$work/feat#g")
  out=$("${run[@]}" <<<"$input" 2>&1)
  got=$(jq -r '.hookSpecificOutput.permissionDecision // empty' <<<"$out" 2>/dev/null)
  got=${got:-allow}
  if [ "$got" = "$expect" ]; then
    pass=$((pass + 1))
    case "$got" in allow) allow=$((allow + 1)) ;; deny) deny=$((deny + 1)) ;; ask) ask=$((ask + 1)) ;; esac
  else
    fail=$((fail + 1))
    echo "FAIL: $name: expected $expect, got $got: $out"
  fi
  [ "$expect" != allow ] && blocks=$((blocks + 1))
done <"$here/cases.jsonl"

logged=$(wc -l <"$work/log/blocks.jsonl" 2>/dev/null || echo 0)
if [ "$((logged + 0))" -ne "$blocks" ]; then
  echo "FAIL: $blocks blocks expected in the log, found $logged"
  fail=$((fail + 1))
fi
echo "claude-guard: $pass/$((pass + fail)) as expected ($allow allow, $deny deny, $ask ask); $logged log lines"
[ "$fail" -eq 0 ]
