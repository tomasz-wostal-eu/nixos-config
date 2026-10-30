#!/usr/bin/env bash
# Runs shellcheck on the tracked shell scripts (DW-231): git's *.sh files plus the extensionless
# files with a sh/bash shebang (the apps/<system>/* helpers). Optional arguments restrict the run
# to those files (pre-commit passes the staged ones); the same selection rules apply.
#
# Tool: shellcheck. Locally a missing shellcheck falls back to a pinned Docker image; with neither,
# the run fails (NC_SKIP_MISSING=1 skips instead).
set -uo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd -P)
SHELLCHECK_IMAGE=koalaman/shellcheck:v0.10.0
cd "$root" || exit 1

if [ "$#" -gt 0 ]; then
  candidates=$(printf '%s\n' "$@")
else
  candidates=$(git ls-files)
fi

scripts=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in
    node_modules/*|*/node_modules/*|result/*) continue ;;
    *.sh) scripts+=("$f") ;;
    *.*) ;;
    *) head -n1 "$f" | grep -qE '^#!.*[/ ](ba|da|k)?sh( |$)' && scripts+=("$f") ;;
  esac
done <<<"$candidates"
[ "${#scripts[@]}" -gt 0 ] || { echo "shellcheck: no shell scripts to check"; exit 0; }
echo "shellcheck: ${#scripts[@]} scripts"

if command -v shellcheck >/dev/null; then shellcheck -x "${scripts[@]}"
elif command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  docker run --rm -v "$root":"$root":ro -w "$root" "$SHELLCHECK_IMAGE" -x "${scripts[@]}"
elif [ "${NC_SKIP_MISSING:-}" = 1 ]; then echo "skipped shellcheck (not installed, no docker)"
else echo "missing: shellcheck (install it or start Docker; NC_SKIP_MISSING=1 skips)"; exit 1
fi
