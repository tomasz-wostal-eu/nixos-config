# nixos-config

Personal NixOS and macOS configuration using Nix Flakes.

## What is NixOS?

[NixOS](https://nixos.org/) is a Linux distribution built on the Nix package manager. What makes it unique:

- **Declarative configuration** - your entire system is defined in config files. No more "works on my machine" - if it builds, it works everywhere.
- **Reproducibility** - the same configuration always produces the same system. You can version control your OS.
- **Atomic upgrades and rollbacks** - updates are atomic. If something breaks, just boot into a previous generation.
- **No dependency hell** - each package has its own dependencies, isolated from others. Multiple versions can coexist.
- **Try before you buy** - `nix-shell -p package` lets you test any package without installing it permanently.

### Flakes

Flakes are the modern way to manage dependencies and configuration in Nix. A `flake.nix` file defines:

- **inputs** - external dependencies (nixpkgs, home-manager, nix-darwin) with versions pinned in `flake.lock`
- **outputs** - what the flake produces (system configurations, packages, dev shells)

Benefits:
- Dependencies are always at specific versions (no more "works on my machine")
- `nix flake update` updates everything at once
- Easy to share configuration between machines
- Built-in support for multiple systems (x86_64-linux, aarch64-darwin, etc.)

### Home Manager

[Home Manager](https://github.com/nix-community/home-manager) extends Nix to manage your user environment - dotfiles, shell configuration, and user-level packages. Instead of manually symlinking configs or using stow, you declare everything in Nix:

```nix
programs.git = {
  enable = true;
  userName = "Your Name";
  userEmail = "you@example.com";
};
```

Home Manager generates the appropriate config files and manages them declaratively. Change the config, rebuild, done. Works on NixOS, macOS, and any Linux with Nix installed.

### Where can you run Nix?

- **NixOS** - full Linux distribution (bare metal, VMs, cloud instances, WSL2, Raspberry Pi)
- **macOS** - via [nix-darwin](https://github.com/LnL7/nix-darwin) for system configuration + [Home Manager](https://github.com/nix-community/home-manager) for dotfiles
- **Any Linux distro** - Nix package manager works alongside apt/dnf/pacman
- **Docker** - official NixOS images available

This repo uses Nix Flakes to manage both NixOS machines and Macs from a single configuration.

## Platforms

- **NixOS:** x86_64-linux, aarch64-linux (UTM/QEMU VM)
- **macOS:** aarch64-darwin, x86_64-darwin (via nix-darwin)

## Usage

```bash
# Build and switch (auto-detects platform); bumps overlays/ packages first
nix run .#build-switch

# Build only, no switch (macOS)
nix run .#build

# Update flake inputs
nix flake update

# Bump the packages built from overlays/ (flake update does not touch those)
nix run .#update-overlays

# Roll back to a previous generation (macOS)
nix run .#rollback

# Clean old generations
nix run .#clean
```

`build-switch` runs `update-overlays` before building; a failed bump is not
fatal, and `SKIP_OVERLAY_UPDATE=1` skips it.

## Structure

```
flake.nix              # Entry point
├── hosts/
│   ├── nixos/         # NixOS configuration
│   └── darwin/        # macOS configuration
├── modules/
│   ├── nixos/         # NixOS-specific modules
│   ├── darwin/        # macOS-specific modules
│   └── shared/        # Shared configuration
├── overlays/          # Package overrides and pins, applied to every build
├── apps/<system>/     # Helper scripts exposed as `nix run .#<name>`
└── docs/              # Longer write-ups (agent PR flow)
```

## Features

- Zsh with oh-my-zsh, plus Nushell; both get starship, atuin, carapace, zoxide and direnv
- LazyVim (Neovim) with LSP support
- Catppuccin Macchiato theme everywhere (Ghostty, tmux, pi, terminal apps)
- Ghostty terminal (90% opacity, background blur)
- tmux with custom keybindings
- pi coding agent with sub-agents and MCP servers (see below)
- Terminal mail, calendar and issue tracking (see below)
- Multi-agent PR workflow on workmux (Codeberg + GitHub) — see [docs/agent-pr-flow.md](docs/agent-pr-flow.md)

## Shells

Zsh is the login shell; Nushell is configured alongside it from the same
`shellAliases`. Two deliberate differences:

- eza's Nushell integration stays off, so `ls` remains Nushell's built-in that
  returns a table instead of text.
- The sesh alias `s` is overridden for Nushell, which cannot parse bash's
  `$(...)`; it uses a `(...)` subexpression instead.

### `argo`

Both shells wrap the `argo` CLI to talk to Argo Workflows on mistwolf-dev
(`workflows-cli.tailc90e09.ts.net`) without a manual login. On first use it
mints a 1 h token for the `argo-cli` service account with `kubectl --context
mistwolf-dev create token`, caches it in `$XDG_CACHE_HOME/argo-cli/token`
(0600) and reuses it for 55 min.

```bash
argo login    # mint a fresh token now, print its expiry
argo logout   # drop the cached token
argo list     # in Nushell: a table, e.g. `argo list | where status == Failed`
```

The wrapper steps aside when `ARGO_SERVER` is already set and for
`version`/`completion`/`help`. In Nushell `argo list` returns a table only
without `-o`/`--output`.

## pi

pi is the agent harness for PR review and
general work. Its sub-agents, reviewers and the workmux integration are described
in [docs/agent-pr-flow.md](docs/agent-pr-flow.md). Everything else lives in
`modules/shared/files.nix`:

- **MCP servers** in `~/.config/mcp/mcp.json`, read by pi-mcp-adapter: atlassian,
  google-workspace, grafana, slack, chrome (Claude in Chrome), kubernetes and
  argocd. Destructive tools require approval. Secrets are never in the store:
  an env value starting with `!` runs a command when the server starts, which
  reads a 0600 file or Azure Key Vault. `secrets-restore` recreates those files.
  The comment above `mcp.json` explains auth and rotation for each server.
- **Theme**: Catppuccin Macchiato from the `pi-catppuccin` npm package, linked
  into `~/.pi/agent/themes/`. Select it with `"theme"` in the mutable
  `~/.pi/agent/settings.json` (or `/settings`).
- **Keys**: tmux sets `extended-keys-format csi-u`; by default it forwards
  modified keys (shift-enter etc.) in the xterm modifyOtherKeys format, which
  pi does not understand.

## Mail, calendar, tasks

Everything is mirrored locally and synced by launchd agents. Two Google
accounts: `tomasz.wostal@gmail.com` and the Workspace mailbox
`tomasz.wostal@itomm.pl`, whose `wostal.eu` / `devops.toys` / `mistwolf.tech`
addresses are *send-as aliases*, not separate accounts.

| Agent | Interval | Does |
|---|---|---|
| `mailsync` | 5 min | `gmi pull` then `gmi push` per account, `notmuch new` |
| `bugsync` | 5 min | git fetch/push of `refs/bugs/*`, `bugwarrior pull`, `codeberg-tasks` |
| `vdirsyncer` | 15 min | calendars into `~/.local/share/calendars*` |

```bash
launchctl list | grep nix-community   # second column is the last exit code
tail -f ~/Library/Logs/{mailsync,bugsync,vdirsyncer}.log
```

### Things that will bite you

**Never run `gmi sync` for a first pull.** It pushes *before* it pulls, so a
local state that is behind reads as mass deletion and trashes those messages in
Gmail. This has happened here: ~9000 messages, recovered from the Gmail History
API. Use `msync` (`gmi pull`); `mpush` is the two-way one. The agent runs pull
and push as separate steps and skips the push if the pull failed.

**Changing `collections` in the vdirsyncer config requires `vdirsyncer
discover <pair>`.** `build-switch` will not do it, and the agent then fails
every cycle with *"Detected change in config file"* — visible only as exit
code 1 in `launchctl list`. The agent now recovers by running `discover` once
after a failed sync and retrying; note that recovery accepts new remote
collections without asking.

**taskwarrior is pinned to 2.x on purpose.** bugwarrior writes through the
`taskw` library, which produces 2.x `.data` files; taskwarrior 3 reads
`taskchampion.sqlite3` and silently reports "No matches" for everything
bugwarrior imported.

**bugwarrior cannot read Codeberg issues** — it has no gitea/forgejo service and
2.1.0 is the newest upstream release. Two separate things fill that gap, and
they are not interchangeable:

- `git-bug` keeps issues *as git refs inside each repo*, synced to Codeberg by
  plain git. These never appear in Codeberg's web Issues tab. Each repo needs a
  one-time `git-bug user new`, otherwise every pull dies with "No identity is
  set". Close with `git-bug bug status close <id>` — `git-bug bug close` is
  parsed as a query and silently does nothing.
- `codeberg-tasks` (`modules/shared/codeberg-tasks.py`) reads the **native
  Forgejo tracker** over its API and upserts open issues into taskwarrior,
  keyed on the `cbissue` UDA. Repos are discovered from git remotes, so no list
  to maintain. This is what surfaces the issues you actually work from.

Its UDAs (`cbissue`, `cburl`) **must** be declared in `.taskrc`. `task config
uda...` cannot add them at runtime — `.taskrc` is a read-only store symlink, the
write fails silently, and taskwarrior then folds `cbissue:...` into the task
*description*, so the dedupe filter matches nothing and every run re-adds every
issue as a duplicate.

**Terminal colours use ANSI slots 0-15, never hex or the 256-cube.** The Ghostty
palette already maps those to exact Catppuccin values, so neomutt, khal and
taskwarrior match each other and the background. neomutt rejects `#rrggbb`
outright without a `*-direct` terminfo, and 256-cube approximations render a
visibly different black.

### Tagging

A `post-new` hook (`~/.config/notmuch/hooks/post-new`) applies 28 category tags
from `~/.config/notmuch/tag-rules`, both generated from `notmuchTagRules` in
`modules/shared/files.nix`. They cover 84% of the mailbox; the rest is a tail of
826 domains with fewer than 20 messages each, which is not worth a rule.

Rules key on **domains, not addresses** — notmuch matches address tokens, so
`from:adobe.com` also catches `mail.adobe.com` and every other marketing
subdomain a sender uses. Every rule ends in `and not tag:X`, which makes the
hook idempotent: the first full pass over 41k messages took 55 s, every pass
after that takes 0.2 s. The flip side is that a tag deleted by hand comes back
on the next `notmuch new` — delete the rule instead.

**These tags reach Gmail.** lieer pushes any tag not in its `ignore_tags` as a
label and `/` nests it there, so a wrong rule is visible on the account and on
the phone. Backfilling them is one enormous push: Gmail rate-limits it down to
single-message batches and it runs for the better part of an hour, during which
the repository lock makes every scheduled `mailsync` run abort. That is a
one-time cost, not a steady-state one. To keep a tag local instead, add it with
`gmi set --ignore-tags-local`.

Nothing in the rules touches `inbox`, `unread` or `flagged` — removing those
locally would archive or mark the mail in Gmail on the next push.

The neomutt sidebar gets `People`, `Dev`, `Jobs`, `Finance` and `Shopping` views
over the result. `People` is `tag:inbox` minus `automated` and `newsletter`,
which is the half of the mailbox a human actually wrote. Each view lists its
tags one by one because notmuch has no tag wildcard — `tag:dev/*` matches
nothing rather than expanding.

### Dashboard

`sesh` gains an **inbox** session: neomutt on the left, khal top-right, taskwarrior
bottom-right. Calendar and tasks redraw every 60 s. Reach it from the picker
(`prefix T`, or `sesh connect inbox`).

Refresh is a plain `clear; cmd; sleep` loop, not `watch(1)` — `watch -c` silently
strips 24-bit sequences, which would drop khal's Catppuccin colours to plain SGR.

It is a `programs.sesh.settings.session` entry, not a `window` one. Window entries
only materialise for sessions that name them in `windows`, and no session config
here does — as a window it was reachable from neither `sesh list` nor
`sesh window`. As a session it also means one neomutt, not one per session.

### Secrets

Static secrets (OAuth client ids/secrets, refresh tokens) live in `pass`, which
syncs to a private Codeberg repo. Runtime reads use plain 0600 files instead, so
the unattended agents never depend on an unlocked gpg-agent. `secrets-restore`
recreates those files on a new machine; `secrets-backup` pushes changes back.
Token caches that the tools rewrite themselves — `.credentials.gmailieer.json`,
`vdirsyncer/*_token` — are deliberately not in `pass`; re-run `gmi auth` or
`vdirsyncer discover` instead.

## Credits

Based on [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config).
