# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS configuration repository using Nix Flakes to manage declarative system configurations for multiple platforms:
- **NixOS (Linux):** aarch64-linux on UTM (virtualization)
- **macOS (Darwin):** aarch64-darwin on Apple Silicon (nix-darwin)

## Common Commands

```bash
# Rebuild and switch to new NixOS configuration
sudo nixos-rebuild switch --flake /home/twostal/nixos-config#nixos

# Rebuild and switch macOS configuration
nix run nix-darwin -- switch --flake /home/twostal/nixos-config#mbp

# Update all flake inputs to latest versions
nix flake update

# Check flake for syntax/evaluation errors
nix flake check

# Build without activating (useful for testing)
nixos-rebuild build --flake /home/twostal/nixos-config#nixos

# Show all flake outputs
nix flake show
```

## Architecture

```
flake.nix                    # Entry point - defines system configurations
├── nixosConfigurations.nixos
│   ├── hosts/nixos-utm/configuration.nix   # NixOS system config (services, packages)
│   ├── hosts/nixos-utm/hardware-configuration.nix  # Hardware/boot settings
│   └── home-manager → twostal.nix
│
└── darwinConfigurations.mbp
    ├── hosts/darwin/configuration.nix      # macOS system config (not yet created)
    └── home-manager → twostal.nix

twostal.nix                  # Home Manager user config (shared between platforms)
```

**Key pattern:** `twostal.nix` is shared between Linux and macOS, providing portable user-level configuration (shell, editor, tools).

## Flake Inputs

- **nixpkgs:** nixos-unstable branch
- **home-manager:** User-level configuration management
- **nix-darwin:** macOS system management
- **lazyvim-nix:** LazyVim Neovim IDE integration

## Configuration Notes

- State version: 25.11 (both NixOS and Home Manager)
- User: twostal (in groups: networkmanager, wheel)
- Theme: Catppuccin Macchiato across all terminal tools
- TMux prefix: `C-a`
- SSH: Key-based auth only, password authentication disabled
