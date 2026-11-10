{ pkgs }:

with pkgs;
let
  shared-packages = import ../shared/packages.nix { inherit pkgs; };
in
shared-packages
++ [
  # dockutil # requires Swift - broken in nixpkgs-unstable
  lens
  # raine/workmux, pinned by the flake input (flake.nix); not in nixpkgs.
  workmux
]
