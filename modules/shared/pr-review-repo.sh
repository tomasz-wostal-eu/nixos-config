#!/usr/bin/env bash
# Review a PR from the dashboards (tea-dash / gh-dash `r`). Run in the repo: if it has exactly
# one executable scripts/*-review wrapper, run that (it adds the repo's --jira-prefix, DW-245),
# otherwise plain pr-review. pr-review itself never calls a repo script (DW-242), so no loop.
#
#   pr-review-repo <pr> [--quick]
shopt -s nullglob
wrappers=()
for f in scripts/*-review; do
  [[ -f $f && -x $f ]] && wrappers+=("$f")
done
if [[ ${#wrappers[@]} -eq 1 ]]; then
  exec "${wrappers[0]}" "$@"
fi
exec pr-review "$@"
