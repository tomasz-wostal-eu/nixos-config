# Repository Guidelines

## Project Structure & Module Organization

This repository is a Nix flake for personal NixOS and macOS systems. `flake.nix` wires together `nixpkgs`, `home-manager`, `nix-darwin`, `disko`, and LazyVim inputs. Host entry points live in `hosts/nixos/` and `hosts/darwin/`. Reusable configuration is split under `modules/`: `modules/shared/` for cross-platform Home Manager and packages, `modules/nixos/` for Linux-specific system, disk, and desktop config, and `modules/darwin/` for macOS packages, casks, files, and Dock settings. Helper scripts are exposed from `apps/<system>/`. Static assets and non-Nix configs live beside their module, for example `modules/nixos/config/`.

## Build, Test, and Development Commands

- `nix develop`: enter the flake dev shell with Git and an interactive Bash available.
- `nix flake check`: evaluate flake outputs before switching.
- `nix run .#build-switch`: build and activate the current platform configuration.
- `nix run .#build-switch -- --host <name>`: build a named NixOS host.
- `nix run .#build`: build the Darwin system without switching.
- `nix run .#clean`: clean old generations using the platform helper script.
- `nix flake update`: update pinned inputs in `flake.lock`; review the diff.

## Coding Style & Naming Conventions

Use 2-space indentation in Nix files. Keep modules small and platform-scoped: shared options belong in `modules/shared/`, Linux-only settings in `modules/nixos/`, and macOS-only settings in `modules/darwin/`. Name Nix files by responsibility, such as `packages.nix`, `files.nix`, or `home-manager.nix`. Prefer declarative Nix options over shell hooks unless the behavior is operational.

## Testing Guidelines

There is no separate unit test suite. Treat Nix evaluation and builds as the test surface. Run `nix flake check` for validation, then build the target system before applying risky changes. For platform changes, use the relevant app, for example `nix run .#build-switch` on the host you intend to update. Avoid committing generated `result` symlinks or local artifacts.

## Commit & Pull Request Guidelines

Recent history uses short, imperative commit subjects such as `add bun`, `add forgejo cli`, `upgrade`, and `fix: config`. Keep commits focused and mention the affected platform or module when useful. Pull requests should describe the changed host/module, list validation commands, call out `flake.lock` updates, and note whether a system switch was performed. Include screenshots only for desktop, Dock, Polybar, Rofi, or editor UI changes.

## Security & Configuration Tips

Do not commit keys, host secrets, or credentials. Key helper scripts exist under `apps/<system>/`, but generated secrets should remain outside version control. Review destructive install or disk changes, especially `modules/nixos/disk-config.nix`, before applying them to hardware.
