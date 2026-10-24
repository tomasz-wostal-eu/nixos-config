# Agent PR flow

This document describes the end-to-end pull-request workflow configured in this
repository: how a task becomes a branch, how multiple coding agents work on it in
parallel, and how a PR gets reviewed and commented on — for both **Codeberg**
(the primary forge) and **GitHub** (mirrors and GitHub-only repos).

The whole flow is built on **[workmux](https://github.com/raine/workmux)** (git
worktrees + tmux sessions) plus a set of small helper scripts. Authoring agents
(`claude`, `codex`) are independent CLIs, each in its own tmux pane. PR review
runs one `pi` session in a pane, which orchestrates in-process reviewer
sub-agents ([pi-subagents](https://github.com/tintinweb/pi-subagents)). workmux
creates the worktrees, lays out the panes, and tracks each agent's status via
hooks.

## Components

| Piece | What it does | Where it is configured |
|-------|--------------|------------------------|
| `workmux` | Worktree + tmux session manager; runs agents in panes | `~/.config/workmux/config.yaml` (global) and `<repo>/.workmux.yaml` (per-repo) — see `modules/shared/files.nix` |
| `tea-dash` | gh-dash for Codeberg; PR/issue dashboard, review keybindings | `~/.config/tea-dash/config.yml` — `modules/shared/files.nix` |
| `gh-dash` | PR/issue dashboard for GitHub repos | `modules/shared/home-manager.nix` |
| `wja` | Start a task from a Jira key → fresh branch + worktree + prompt | `modules/shared/files.nix` (`.local/bin/wja`) |
| `pr-review` | Open the `review` layout for a PR (checks out the PR head) | `modules/shared/files.nix` (`.local/bin/pr-review`) |
| `agent-review-post` | Collect reviewer files and post them to the PR (with preview) | `modules/shared/files.nix` (`.local/bin/agent-review-post`) |
| `pi-agent-pane` | One pane per pi sub-agent: live transcript + workmux status | `modules/shared/files.nix` (`.local/bin/pi-agent-pane`) |
| `subagents-workmux.ts` | pi extension: publishes sub-agent lifecycle for workmux | `modules/shared/files.nix` (`.pi/agent/extensions/`) |
| `agent-pr-comment` | Post one signed comment to the PR for the current branch | `modules/shared/files.nix` (`.local/bin/agent-pr-comment`) |
| `codeberg-tasks` | Import Codeberg (Forgejo) issues into taskwarrior | `modules/shared/codeberg-tasks.py` |

### Agents

- `claude` — primary author (installed as a cask).
- `codex` — second author / reader in the `duel` layout.
- `pi` — review orchestrator. Default model `claude-bridge/claude-opus-5-5`
  (`~/.pi/agent/settings.json`, mutable: pi rewrites it itself). It does not
  review; it runs the reviewer sub-agents:
  - `reviewer-openai` — `openai/gpt-6-astra`, thinking high. Always runs.
  - `reviewer-ollama` — `ollama/qwen3-coder:30b-32k` on the LAN box, no
    thinking, at most 15 turns. Optional: pi asks before running it. 32k of
    context, so it is only useful for diffs up to roughly 1500 lines. A MoE
    model that fits the box's VRAM; the dense `qwen3.8:27b` did not, and one
    review with it ran past 78 minutes.

  Both are defined in `modules/shared/files.nix` (`piReviewer`), land in
  `~/.pi/agent/agents/`, run `isolated` (built-in tools only, no MCP or skills)
  and write `.workmux/review-<model>.md`.

Each CLI has workmux status hooks installed (`~/.claude/settings.json`,
`~/.codex/hooks.json`, `~/.pi/agent/extensions/workmux-status.ts`) so it
reports 🤖 working / 💬 waiting / ✅ done to the workmux dashboard and sidebar.

pi's sub-agents live inside the pi process, which workmux cannot see. The
`subagents-workmux.ts` extension bridges them: it keeps pi itself at 🤖 while
background sub-agents run (the `suba:activity` count that `workmux-status.ts`
reads), and writes each sub-agent's state to `.workmux/agents/<type>.json`.
`pi-agent-pane <type>` follows that file: once pi starts the sub-agent, the
pane registers with workmux (its own sidebar/dashboard entry), mirrors the
status and prints the transcript. A reviewer pi never starts stays an idle
pane and never shows up in the sidebar.

## The flow

### 1. Start a task

```sh
wja DW-123 short title words        # feat/DW-123-short-title-words
wja -t fix DW-456 crash on logout   # fix/DW-456-crash-on-logout
```

`wja`:
- fetches and branches from the **freshly fetched default branch** (not a stale
  local one),
- names the branch `type/KEY-slug` (`feat` by default; `-t` overrides),
- hands the agent a prompt that carries the Jira key and the repo's `CLAUDE.md`
  workflow, then runs `workmux add <branch> --base <base> -p <prompt>`.

For ad-hoc work without a Jira key, use `workmux add` directly:

```sh
workmux add feat/my-change                 # one worktree, the default agent (claude)
workmux add feat/my-change -a claude,codex # two worktrees, one branch per model
```

Layouts (`-l`) and `--agent` are **separate modes** and do not combine:

| Layout | Panes | Use |
|--------|-------|-----|
| `solo` | agent + free shell | one agent + shell (pass `-l solo`; omitting `-l` opens only the agent pane) |
| `duel` | claude + codex (shared tree) | one writes, one reviews |
| `review` | pi + one `pi-agent-pane` per reviewer | PR review (see below) |

### 2. Review a PR

From `tea-dash` (Codeberg) or `gh-dash` (GitHub), press **`r`** on a PR, or run:

```sh
pr-review 42
```

`pr-review`:
- fetches the PR head (`refs/pull/42/head`) and checks it out on a worktree
  branch `review/pr-42`,
- opens the `review` layout (pi plus a pane for each reviewer) and hands pi a prompt that makes it:
  1. show `git diff --stat` and **ask whether to run `reviewer-ollama`** too,
  2. spawn `reviewer-openai` (and `reviewer-ollama` on yes) in the background, in
     parallel,
  3. summarise each verdict and top findings, and point out disagreements.
- the reviewers stay inside `git diff <base>...HEAD`, do **not** edit / commit /
  push / post anything, and write their review in English to
  `.workmux/review-gpt-6-astra.md` / `.workmux/review-qwen3-coder-30b.md`.

Overrides: `scripts/dw-review` / `scripts/met-review`, if present and executable,
replace `pr-review` **entirely** (they are `exec`'d before the fetch and prompt).
A `layouts.review` block in a repo's `.workmux.yaml` only customizes the tmux
panes — the `refs/pull/<n>/head` fetch, the `review/pr-<n>` branch, and the review
prompt still come from `pr-review`.

### 3. Post the review to the PR

After the reviewers have written their `.workmux/review-*.md` files, press **`P`**
in the dashboard, or run:

```sh
agent-review-post "$(workmux path pr-42)"   # previews each review, asks before posting
agent-review-post -y .                       # post all without prompting
```

Each review is shown, then (unless `-y`) you confirm before it is posted as a
signed comment. The signature is the model from the file name, e.g.
`**gpt-6-astra**`. A posted file is renamed `*.md.posted`; a failed post is kept for
a retry. Posting is deliberately a manual step — it is visible on the forge.

### 4. Leave an ad-hoc signed comment

```sh
echo "Looks good, one nit on error handling" | agent-pr-comment claude
agent-pr-comment codex 42 <<< "body..."     # explicit PR number
```

`agent-pr-comment`:
- picks the forge from the `origin` remote (Codeberg → `tea`, GitHub → `gh`),
- resolves the PR from the branch (or from a `review/pr-<n>` worktree name, or an
  explicit number),
- signs the comment with the agent, the PR **head branch**, and the short SHA:
  `**claude** · ` `` `feat/DW-123@a1b2c3d` ``,
- **rejects any body containing Polish letters** — PR comments are English by rule.

## Issue sync (bonus)

`codeberg-tasks` walks `~/projects`, finds repos whose origin is on
`codeberg.org`, and upserts their open issues into taskwarrior under the
`cbissue` UDA (bugwarrior has no Forgejo service). A repo that fails to respond
is skipped rather than having its tasks closed. Token: `~/.config/codeberg/token`
(mode 0600).

## Prerequisites (not managed by Nix)

A few binaries are installed by hand and are expected on `$PATH`:

- `workmux` — `nix profile install github:raine/workmux` (only its config is
  declarative; a fresh machine needs this one command).
- `codex`, `claude`, `gemini`, `pi` — installed via packages / casks.
- pi packages `pi-claude-bridge` and `@tintinweb/pi-subagents` (`pi install
  npm:<name>`; listed in the mutable `~/.pi/agent/settings.json`), and pi logins
  for Anthropic and OpenAI (`/login`, stored in `~/.pi/agent/auth.json`).

Forge auth and tokens (never stored in the Nix store):

- Codeberg CLI: `tea login add` (tea-dash reads `tea`'s own login, named
  `codeberg`).
- GitHub CLI: `gh auth login`.
- Codeberg API token for issue sync: `~/.config/codeberg/token`.

## Conventions

- **English only** on the forge — enforced by `agent-pr-comment` (and by the
  reviewer prompts).
- Branches: `type/KEY-slug` (`feat`, `fix`, `docs`, `chore`, …).
- Worktrees live under `~/dev/worktrees/{project}`; one tmux session per worktree,
  window prefix `{project}-`.
- This repo's `.workmux.yaml` adds a `pre_merge` gate that blocks a merge while
  any `*.nix` file is untracked — `nix build` only sees the git index, so an
  unstaged `.nix` file would pass silently with stale content.

## Note on `pi` and orchestration

Two orchestration models coexist. Authoring is **workmux-orchestrated**: each
agent is a separate CLI process in its own pane. Review is **pi-orchestrated**:
one `pi` session spawns the reviewers as in-process sub-agents
(pi-subagents), so the optional second reviewer is a question pi asks, not a
pane that always starts. `pi` is also one of the runtimes `herdr` keeps alive.
