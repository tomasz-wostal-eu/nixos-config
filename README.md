# nixos-config

Personal NixOS and nix-darwin configuration using Nix Flakes.

## Platforms

- **NixOS** (aarch64-linux) - UTM virtual machine
- **macOS** (aarch64-darwin) - Apple Silicon via nix-darwin

## Usage

### NixOS

```bash
sudo nixos-rebuild switch --flake .#nixos
```

### macOS

```bash
nix run nix-darwin -- switch --flake .#mbp
```

### Update inputs

```bash
nix flake update
```

## Structure

```
flake.nix              # Entry point
hosts/
  nixos-utm/           # NixOS system configuration
  darwin/              # macOS system configuration
twostal.nix            # Shared Home Manager config
```
