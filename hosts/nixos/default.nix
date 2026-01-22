{ config, inputs, pkgs, ... }:

{
  imports = [
    ./configuration.nix
    ../../modules/shared
  ];
}
