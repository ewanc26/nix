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
    # generic lib from the main nixpkgs input
    lib = nixpkgs.lib;

    # helper that returns the value to use as the home manager user module
    homeUser = { pkgsFor, isDarwin }: import ./home/home.nix {
      pkgs = pkgsFor;
      lib = lib;
      isDarwin = isDarwin;
    };

    # DRY NixOS builder: compute pkgsForSystem and pass it explicitly into homeUser
    mkNixOS = { system, hostFile }: let
      pkgsForSystem = import nixpkgs {
  inherit system;
  config = { allowUnfree = true; };
};
    in nixpkgs.lib.nixosSystem {
      inherit system;
      pkgs = pkgsForSystem;
      modules = [
        hostFile
        ragenix.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.ewan = homeUser { pkgsFor = pkgsForSystem; isDarwin = false; };
        }
      ];
    };

    # DRY Darwin builder: compute pkgs for Darwin and pass into homeUser
    mkDarwin = { system, hostFile }: let
      pkgsForDarwin = import nixpkgs-darwin {
  inherit system;
  config = { allowUnfree = true; };
};
    in nix-darwin.lib.darwinSystem {
      inherit system;
      pkgs = pkgsForDarwin;
      modules = [
        hostFile
        ragenix.darwinModules.default
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.ewan = homeUser { pkgsFor = pkgsForDarwin; isDarwin = true; };
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
  in {
      nixosConfigurations = rec {
        default = mkNixOS { system = "x86_64-linux"; hostFile = ./hosts/laptop; };
        laptop  = default;
        server  = mkNixOS { system = "x86_64-linux"; hostFile = ./hosts/server; };
        vm      = mkNixOS { system = "aarch64-linux"; hostFile = ./hosts/vm; };
      };

    darwinConfigurations = {
      macmini = mkDarwin { system = "aarch64-darwin"; hostFile = ./hosts/macmini; };
    };
  };
}