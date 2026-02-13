{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-darwin, home-manager, nix-darwin, ragenix, ... }:
    let
      lib = nixpkgs.lib;

      # Reusable function for NixOS configurations
      mkNixOS = { system, hostFile }: nixpkgs.lib.nixosSystem {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          hostFile
          ragenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix {
              inherit pkgs lib;
              isDarwin = false;
            };
          }
        ];
      };

      # Reusable function for Darwin configurations
      mkDarwin = { system, hostFile }: nix-darwin.lib.darwinSystem {
        inherit system;
        pkgs = nixpkgs-darwin.legacyPackages.${system};
        modules = [
          hostFile
          ragenix.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix {
              inherit pkgs lib;
              isDarwin = true;
            };
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    in {

      nixosConfigurations = {
        default = mkNixOS { system = "x86_64-linux"; hostFile = ./hosts/laptop; };
        laptop  = mkNixOS { system = "x86_64-linux"; hostFile = ./hosts/laptop; };
        server  = mkNixOS { system = "x86_64-linux"; hostFile = ./hosts/server; };
        vm      = mkNixOS { system = "aarch64-linux"; hostFile = ./hosts/vm; };
      };

      darwinConfigurations = {
        macmini = mkDarwin { system = "aarch64-darwin"; hostFile = ./hosts/macmini; };
      };
    };
}