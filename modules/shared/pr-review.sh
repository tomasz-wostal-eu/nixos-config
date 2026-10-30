#!/usr/bin/env bash
# Review a PR with pi reviewer subagents in its own throwaway worktree. The one review flow
# for every repo; scripts/dw-review, met-review and we-review are thin wrappers that exec
# this with their --jira-prefix (DW-242), so it must never call back into them.
#
#   pr-review <pr>                       interactive: the `review` layout, pi + reviewer panes
#   pr-review <pr> --quick               one-shot: reviewer-openai only, printed to this terminal
#   pr-review <pr> --jira-prefix KEY     also mention the Jira key (KEY-123) found in the PR title
#
# The forge comes from `git remote get-url origin`: GitHub is read with gh, anything else
# (Codeberg/Forgejo) with tea. The PR head is fetched from refs/pull/<n>/head, so forks work
# too. It lands on a local branch review/pr-<n>, never on the author's branch, so nothing a
# reviewer does can be pushed to the PR by accident. pi only orchestrates; the reviewers
# (reviewer-openai, optionally reviewer-ollama) read and write .workmux/review-<model>.md
# and never post. The reviews are posted to the PR as signed comments by agent-review-post.
# The verdict is the last line of each posted review.
usage() {
  echo "usage: pr-review <pr-number> [--quick] [--jira-prefix KEY]" >&2
  exit 2
}

pr=''
quick=0
jira_prefix=''
while [[ $# -gt 0 ]]; do
  case $1 in
    --quick) quick=1 ;;
    --jira-prefix)
      [[ $# -ge 2 && $2 =~ ^[A-Za-z][A-Za-z0-9]*$ ]] || usage
      jira_prefix=$2
      shift
      ;;
    *)
      [[ -z $pr && $1 =~ ^[0-9]+$ ]] || usage
      pr=$1
      ;;
  esac
  shift
done
[[ -n $pr ]] || usage

remote=$(git remote get-url origin)
case $remote in
  *github.com*)
    forge=github
    forge_cli=gh
    ;;
  *)
    forge=forgejo
    forge_cli=tea
    ;;
esac

for tool in git jq workmux pi agent-review-post "$forge_cli"; do
  command -v "$tool" > /dev/null || {
    echo "missing: $tool" >&2
    exit 1
  }
done

git rev-parse --show-toplevel > /dev/null

if [[ $forge == github ]]; then
  meta=$(gh pr view "$pr" --json title,baseRefName,headRefOid,state,author,headRefName |
    jq -c '{title, base: .baseRefName, headSha: .headRefOid, state, user: .author.login, head: .headRefName}')
else
  meta=$(tea pulls "$pr" -o json)
fi
title=$(jq -r .title <<< "$meta")
base=$(jq -r .base <<< "$meta")
sha=$(jq -r .headSha <<< "$meta")
state=$(jq -r .state <<< "$meta")
author=$(jq -r '.user // empty' <<< "$meta")
head=$(jq -r '.head // empty' <<< "$meta")
jira=''
if [[ -n $jira_prefix ]]; then
  jira=$(grep -oE "${jira_prefix}-[0-9]+" <<< "$title" | head -1 || true)
fi

name="pr-$pr"
branch="review/$name"

if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "$branch already exists. Reopen it:  workmux open $name" >&2
  echo "or review the new head from scratch: workmux rm $name && pr-review $pr" >&2
  exit 1
fi

echo "PR #$pr ($state): $title"
git fetch --prune origin "$base" "refs/pull/$pr/head"
git cat-file -e "$sha^{commit}" || {
  echo "head commit $sha not found after fetch" >&2
  exit 1
}

opened=${author:+opened by $author}
opened+=${head:+${opened:+ }from branch $head}
# The worktree is the PR head, so its AGENTS.md is the PR's own: a PR branched before a
# guideline change would be reviewed by old rules, and a PR editing AGENTS.md would set
# its own. The reviewers get the base branch's copy, written before workmux starts any
# agent (the interactive layout starts pi as soon as the worktree exists), outside the
# worktree: under the git dir every worktree of this repository shares, untracked.
guidelines=$(git rev-parse --path-format=absolute --git-common-dir)/pr-review/AGENTS.base-pr-$pr.md
mkdir -p "${guidelines%/*}"
if git show "origin/$base:AGENTS.md" > "$guidelines" 2> /dev/null; then
  against="applying the \"Review guidelines\" section of $guidelines (the AGENTS.md of \
origin/$base, not the AGENTS.md of the PR)"
else
  rm -f "$guidelines"
  against="with no repository guidelines (origin/$base has no AGENTS.md)"
fi

task="review PR #$pr (\"$title\"${jira:+, Jira $jira}${opened:+, $opened}) against base \
origin/$base, $against"

# pi-ollama-up (nixos-config) exits non-zero when the LAN Ollama does not answer.
# Without it, keep asking: the user knows whether the box is up.
if ((! quick)) && command -v pi-ollama-up > /dev/null && ! pi-ollama-up; then
  steps="1. Tell me the LAN Ollama is unreachable, so reviewer-ollama will not run.
   Run \`git diff --stat origin/$base...HEAD\` and show me the size of the change.
2. Spawn reviewer-openai in the background. Give it the task: $task.
3. When it finishes, give me the verdict (the last line of its review) and the top
   findings. You do not post it: a watcher started by pr-review posts each
   .workmux/review-*.md to the PR as soon as it is written (it becomes *.posted)."
else
  steps="1. Run \`git diff --stat origin/$base...HEAD\` and show me the size of the change.
   Then ask me whether to run the second reviewer, reviewer-ollama (a local model
   with 32k of context: a diff of more than about 1500 lines will not fit). Wait
   for my answer.
2. Spawn reviewer-openai, and reviewer-ollama only if I said yes, in the
   background and in parallel. Give each the task: $task.
3. When they finish, give me the verdict of each (the last line of its review) and
   the top findings, and point out where they disagree. You do not post them: a
   watcher started by pr-review posts each .workmux/review-*.md to the PR as soon as
   it is written (it becomes *.posted)."
fi

prompt=$(
  cat << EOF
You orchestrate the review of PR #$pr: "$title"${jira:+ (Jira $jira)}.
The PR head is checked out here on branch $branch; its base is origin/$base.
You do not review it yourself: the reviewer subagents do.

$steps

Do not edit tracked files, commit, push or post anything. The reviewers never post
either; only the watcher does.
EOF
)

quick_prompt="Spawn reviewer-openai in the foreground (not in the background) with the task: \
$task. Do not review it yourself and do not post anything. When it finishes, print \
its review verbatim."

# Posting does not wait for pi. The ChatGPT stream of a reviewer can stall after it has
# written its review: keepalives defeat pi's idle timeout and pi-subagents has no run
# timeout, so pi may never get to a step after it. A review file that has not changed
# for a minute is finished (the reviewer writes it in one call), so it is posted then.
# agent-review-post posts every pending file of the directory, so it runs only when all
# of them are a minute old, and renames each to *.posted, so nothing is posted twice.
unposted() { [[ -n $(find .workmux -maxdepth 1 -name 'review-*.md' 2> /dev/null) ]]; }
written() { unposted && [[ -z $(find .workmux -maxdepth 1 -name 'review-*.md' -mmin -1 2> /dev/null) ]]; }
posted() { [[ -n $(find .workmux -maxdepth 1 -name 'review-*.md.posted' 2> /dev/null) ]]; }
working() { grep -qs '"status":"working"' .workmux/agents/*.json; }

# Interactive mode, detached from this terminal: post what is written until no reviewer
# is working and nothing is left, or for two hours at most (a stalled reviewer stays
# "working" for ever).
watch_and_post() {
  cd "$1" || return 1
  local end=$((SECONDS + 7200))
  while ((SECONDS < end)); do
    if written; then agent-review-post -y . || true; fi
    if posted && ! unposted && ! working; then return 0; fi
    sleep 15
  done
}

if ((quick)); then
  workmux add "$branch" --name "$name" --base "$sha" --headless > /dev/null
  wt_path=$(workmux path "$name")
  echo "worktree: $wt_path"
  cd "$wt_path" || exit 1
  mkdir -p .workmux
  (exec pi -p --no-session "$quick_prompt" > .workmux/pi-quick.log 2>&1) &
  pi_pid=$!
  # Until pi ends or the review is written; a pi still running after that is stalled.
  while kill -0 "$pi_pid" 2> /dev/null && ! written; do sleep 15; done
  if kill -0 "$pi_pid" 2> /dev/null; then
    echo "the review is written but pi is still running: stopping it" >&2
    kill "$pi_pid" 2> /dev/null || true
  fi
  wait "$pi_pid" 2> /dev/null || true
  if unposted; then
    agent-review-post -y .
  elif ! posted; then
    echo "reviewer-openai wrote no review; pi's output: $wt_path/.workmux/pi-quick.log" >&2
    exit 1
  fi
  echo
  echo "Done. Remove the worktree: workmux rm $name"
else
  workmux add "$branch" --name "$name" --base "$sha" -l review -p "$prompt"
  wt_path=$(workmux path "$name")
  mkdir -p "$wt_path/.workmux"
  nohup bash -c "$(declare -f unposted written posted working watch_and_post); watch_and_post \"\$1\"" \
    _ "$wt_path" > "$wt_path/.workmux/review-watch.log" 2>&1 &
  disown
  echo "Review session started: $name. Each review is posted to the PR as soon as it is written"
  echo "(log: $wt_path/.workmux/review-watch.log). When done: workmux rm $name"
fi
