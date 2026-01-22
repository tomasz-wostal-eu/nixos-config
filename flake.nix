{
  description = "NixOS + nix-darwin bootstrap (aarch64)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nix-darwin (na macOS)
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # home-manager (opcjonalnie, ale zwykle i tak skończysz tu)
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    # lazy-vim
    lazyvim.url = "github:pfassina/lazyvim-nix";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, lazyvim, ... }:
  let
    linuxSystem = "aarch64-linux";
    darwinSystem = "aarch64-darwin";
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      modules = [
        ./hosts/nixos-utm/configuration.nix
        ./hosts/nixos-utm/hardware-configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit lazyvim; };
          home-manager.users.twostal = import ./twostal.nix;
        }
      ];
    };

    darwinConfigurations.mbp = nix-darwin.lib.darwinSystem {
      system = darwinSystem;
      modules = [
        ./hosts/darwin/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.twostal = import ./twostal.nix;
        }
      ];
    };
  };
}

