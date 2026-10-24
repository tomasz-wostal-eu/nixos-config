## Shared
Much of the code running on macOS or NixOS is actually found here.

This configuration gets imported by both platforms. Examples include `git`, `zsh`, `nushell`, `neovim`, `tmux` and the pi agent setup.

## Layout
```
.
├── config             # Config files not written in Nix (p10k.zsh)
├── lazyvim            # LazyVim (Neovim) configuration
├── television         # television (fuzzy finder) channels
├── codeberg-tasks.py  # Imports Codeberg (Forgejo) issues into taskwarrior
├── completions.nix    # zsh completions generated for packages that ship none
├── default.nix        # nixpkgs config and how we import overlays
├── files.nix          # Static configuration files, scripts, pi agents and MCP servers
├── home-manager.nix   # The goods; most shared config lives here
├── packages.nix       # List of packages to share
```
