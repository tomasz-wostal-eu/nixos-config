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
# Build and switch (auto-detects platform)
nix run .#build-switch

# Update flake inputs
nix flake update

# Clean old generations
nix run .#clean
```

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
└── apps/              # Helper scripts
```

## Features

- Zsh with oh-my-zsh, starship prompt, atuin history
- LazyVim (Neovim) with LSP support
- Catppuccin Macchiato theme
- Ghostty terminal
- tmux with custom keybindings
- Terminal mail, calendar and issue tracking (see below)

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
