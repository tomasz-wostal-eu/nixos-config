{ user, config, pkgs, ... }:

{
  ".config/ghostty/config".text = ''
    theme = catppuccin-macchiato
    font-family = JetBrainsMono Nerd Font
    font-size = 12
    background-opacity = 0.9
    background-blur-radius = 20
    mouse-hide-while-typing = true
    window-decoration = true
    keybind = shift+enter=text:\x1b\r
  '';

  ".config/ghostty/themes/catppuccin-macchiato".text = ''
    palette = 0=#494d64
    palette = 1=#ed8796
    palette = 2=#a6da95
    palette = 3=#eed49f
    palette = 4=#8aadf4
    palette = 5=#f5bde6
    palette = 6=#8bd5ca
    palette = 7=#b8c0e0
    palette = 8=#5b6078
    palette = 9=#ed8796
    palette = 10=#a6da95
    palette = 11=#eed49f
    palette = 12=#8aadf4
    palette = 13=#f5bde6
    palette = 14=#8bd5ca
    palette = 15=#a5adcb
    background = 24273a
    foreground = cad3f5
    cursor-color = f4dbd6
    selection-background = 5b6078
    selection-foreground = cad3f5
  '';

  # The pi-clean runtime (~/dev/pi-clean, PI_CODING_AGENT_DIR=~/dev/pi-clean/agent) gets
  # the same workmux integration as ~/.pi/agent (shared/files.nix) plus its router.
  # macOS only. Mutable on purpose, because pi writes them: settings.json, auth.json,
  # mcp.json, mcp-auth.json, models-store.json, sessions/, npm/ and subagents.json
  # (pi-subagents saves /agents -> Settings into it; seeded once from
  # ../shared/config/pi/pi-clean-subagents.json by the piCleanSubagentsSeed activation
  # in home-manager.nix). The pi binary itself is the npm install in ~/dev/pi-clean;
  # moving it to Homebrew is deferred until the formula reaches >= 1.6.1.
  "dev/pi-clean/agent/extensions/subagents-workmux.ts".source = ../shared/config/pi/subagents-workmux.ts;
  "dev/pi-clean/agent/extensions/workmux-status.ts".source = ../shared/config/pi/workmux-status.ts;
  "dev/pi-clean/agent/extensions/jev-router.ts".source = ../shared/config/pi/jev-router.ts;
}
