## Shared
Much of the code running on macOS or NixOS is actually found here.

This configuration gets imported by both platforms. Examples include `git`, `zsh`, `nushell`, `neovim`, `tmux` and the pi agent setup.

## Layout
```
.
├── claude-code        # claude-guard hook and its policy
├── config             # Config files not written in Nix (p10k.zsh)
├── lazyvim            # LazyVim (Neovim) configuration
├── television         # television (fuzzy finder) channels
├── claude-code.nix    # Claude Code: guard hook, OTel, MCP servers synced into the user scope
├── codeberg-tasks.py  # Imports Codeberg (Forgejo) issues into taskwarrior
├── completions.nix    # zsh completions: generated for packages that ship none, carapace
│                      #   excludes/bridges, bash-only CLIs (floci), fzf-tab on Tab
├── default.nix        # nixpkgs config and how we import overlays
├── files.nix          # Static configuration files, scripts, pi agents
├── home-manager.nix   # The goods; most shared config lives here (zsh, starship, atuin, ...)
├── mcp-servers.nix    # MCP servers, one list for pi and Claude Code (atuin included)
├── ollama.nix         # Ollama on the LAN box: host and models for pi and the relay
├── packages.nix       # List of packages to share
├── pr-review.sh       # Source of the pr-review script (see docs/agent-pr-flow.md)
├── pr-review-repo.sh  # Source of pr-review-repo
```
