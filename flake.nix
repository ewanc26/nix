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

  outputs = { self, nixpkgs, nixpkgs-darwin, home-manager, nix-darwin, ragenix, ... }: let
    lib = nixpkgs.lib;
  in {

    nixosConfigurations = {

      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/laptop
          ragenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix {
              inherit pkgs lib;
              isDarwin = false;
              extraSpecialArgs = {
                hostName = "laptop";
                homeDirectory = "/home/ewan";
              };
            };
          }
        ];
      };

      laptop = default;

      server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server
          ragenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix {
              inherit pkgs lib;
              isDarwin = false;
              extraSpecialArgs = {
                hostName = "server";
                homeDirectory = "/home/ewan";
              };
            };
          }
        ];
      };

      vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/vm
          ragenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix {
              inherit pkgs lib;
              isDarwin = false;
              extraSpecialArgs = {
                hostName = "vm";
                homeDirectory = "/home/ewan";
              };
            };
          }
        ];
      };
    };

    darwinConfigurations = {
      macmini = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/macmini
          ragenix.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix {
              inherit pkgs lib;
              isDarwin = true;
              extraSpecialArgs = {
                hostName = "macmini";
                homeDirectory = "/Users/ewan";
              };
            };
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    };
  };
}