{ config, pkgs, lib, lazyvim, ... }:

let
  user = "twostal";
  shared-programs = import ../shared/home-manager.nix { inherit config pkgs lib; };
  shared-files = import ../shared/files.nix { inherit config pkgs; };
in
{
  imports = [ lazyvim.homeManagerModules.default ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix {};
    file = shared-files // import ./files.nix { inherit user; };
    stateVersion = "25.11";
  };

  programs = shared-programs // {
    ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "catppuccin-macchiato";
        font-family = "JetBrainsMono Nerd Font";
        font-size = 12;
        background-blur-radius = 20;
        mouse-hide-while-typing = true;
        window-decoration = true;
        keybind = [
          "shift+enter=text:\\x1b\\r"
        ];
      };
      themes = {
        catppuccin-macchiato = {
          palette = [
            "0=#494d64"
            "1=#ed8796"
            "2=#a6da95"
            "3=#eed49f"
            "4=#8aadf4"
            "5=#f5bde6"
            "6=#8bd5ca"
            "7=#b8c0e0"
            "8=#5b6078"
            "9=#ed8796"
            "10=#a6da95"
            "11=#eed49f"
            "12=#8aadf4"
            "13=#f5bde6"
            "14=#8bd5ca"
            "15=#a5adcb"
          ];
          background = "24273a";
          foreground = "cad3f5";
          cursor-color = "f4dbd6";
          selection-background = "5b6078";
          selection-foreground = "cad3f5";
        };
      };
    };
  };
}
