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

## Credits

Based on [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config).
