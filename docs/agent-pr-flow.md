# Agent PR flow

This document describes the end-to-end pull-request workflow configured in this
repository: how a task becomes a branch, how multiple coding agents work on it in
parallel, and how a PR gets reviewed and commented on — for both **Codeberg**
(the primary forge) and **GitHub** (mirrors and GitHub-only repos).

The whole flow is built on **[workmux](https://github.com/raine/workmux)** (git
worktrees + tmux sessions) plus a set of small helper scripts. The "sub-agents"
are independent coding CLIs — `claude`, `codex`, and `agy` (Antigravity) — each
running in its own tmux pane against a shared or per-agent worktree. workmux is
the orchestrator; it creates the worktrees, lays out the panes, and tracks each
agent's status via hooks.

> Orchestration model: agents are **separate processes coordinated by workmux**,
> not sub-agents spawned inside a single runtime. `pi` is present on these
> machines only as an Ollama client (`~/.pi/agent/models.json`) and via the
> `herdr` runtime; it is **not** the orchestrator of this PR flow. See
> [Note on `pi` and orchestration](#note-on-pi-and-orchestration).

## Components

| Piece | What it does | Where it is configured |
|-------|--------------|------------------------|
| `workmux` | Worktree + tmux session manager; runs agents in panes | `~/.config/workmux/config.yaml` (global) and `<repo>/.workmux.yaml` (per-repo) — see `modules/shared/files.nix` |
| `tea-dash` | gh-dash for Codeberg; PR/issue dashboard, review keybindings | `~/.config/tea-dash/config.yml` — `modules/shared/files.nix` |
| `gh-dash` | PR/issue dashboard for GitHub repos | `modules/shared/home-manager.nix` |
| `wja` | Start a task from a Jira key → fresh branch + worktree + prompt | `modules/shared/files.nix` (`.local/bin/wja`) |
| `pr-review` | Open the `review` layout for a PR (checks out the PR head) | `modules/shared/files.nix` (`.local/bin/pr-review`) |
| `agent-review-post` | Collect reviewer files and post them to the PR (with preview) | `modules/shared/files.nix` (`.local/bin/agent-review-post`) |
| `agent-pr-comment` | Post one signed comment to the PR for the current branch | `modules/shared/files.nix` (`.local/bin/agent-pr-comment`) |
| `codeberg-tasks` | Import Codeberg (Forgejo) issues into taskwarrior | `modules/shared/codeberg-tasks.py` |

### Agents (the "sub-agents")

- `claude` — primary author (installed as a cask).
- `codex` — reviewer / second author; runs with `-a never -s workspace-write`
  so it writes only inside its worktree and asks for nothing.
- `agy` — Antigravity CLI, a second reviewer; runs with
  `--dangerously-skip-permissions`.

Each CLI has workmux status hooks installed (`~/.claude/settings.json`,
`~/.codex/hooks.json`, `~/.gemini/config/hooks.json`) so it reports
🤖 working / 💬 waiting / ✅ done to the workmux dashboard and sidebar.

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
workmux add feat/my-change -l trio         # claude + codex + agy on one tree
workmux add feat/my-change -a claude,codex # two worktrees, one branch per model
```

Layouts (`-l`) and `--agent` are **separate modes** and do not combine:

| Layout | Panes | Use |
|--------|-------|-----|
| `solo` | agent + free shell | one agent + shell (pass `-l solo`; omitting `-l` opens only the agent pane) |
| `duel` | claude + codex (shared tree) | one writes, one reviews |
| `trio` | claude + codex + agy (shared tree) | one writes, two read |
| `review` | codex + agy + free shell | PR review (see below) |

### 2. Review a PR

From `tea-dash` (Codeberg) or `gh-dash` (GitHub), press **`r`** on a PR, or run:

```sh
pr-review 42
```

`pr-review`:
- fetches the PR head (`refs/pull/42/head`) and checks it out on a worktree
  branch `review/pr-42`,
- opens the `review` layout (codex as main reviewer, agy as second reader, plus a
  shell),
- prompts both reviewers to stay inside `git diff <base>...HEAD`, **not** to edit
  / commit / push / post anything, and to write their review in English to
  `.workmux/review-<agent>.md`.

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
signed comment. A posted file is renamed `*.md.posted`; a failed post is kept for
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
- `agy` — the Antigravity CLI. **Not** defined anywhere in this repo; install it
  separately or the `trio` / `review` layouts will fail to start that pane.
- `codex`, `claude`, `gemini` — installed via packages / casks.

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

The question "is this configured so that `pi` manages the agents?" — **no, not
currently.** The PR flow is orchestrated by **workmux**, which runs each agent as
an independent CLI process in its own tmux pane. `pi` on these machines is
configured only as:

- an Ollama LAN client (`~/.pi/agent/models.json`, see `modules/shared/files.nix`), and
- one of the runtimes `herdr` can keep alive per project.

If the goal is to have `pi` itself orchestrate the reviewers as in-process
sub-agents (rather than workmux spawning separate CLIs), that is a different
design and is **not** implemented here yet.
