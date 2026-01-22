# nixos-config

Personal NixOS and macOS configuration using Nix Flakes.

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
