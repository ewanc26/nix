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

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, nixpkgs-darwin, home-manager, nix-darwin, ragenix, nix-vscode-extensions, catppuccin, ... }:
  let
    # generic lib from the main nixpkgs input
    lib = nixpkgs.lib;
    
    # Central configuration - single source of truth
    config = import ./settings/config.nix;
    userConfig = config.user;
    
    # helper that returns the value to use as the home manager user module
    homeUser = { pkgsFor, isDarwin, hostName }: import ./home/home.nix {
      pkgs = pkgsFor;
      lib = lib;
      isDarwin = isDarwin;
      hostName = hostName;
    };

    # DRY NixOS builder: compute pkgsForSystem and pass it explicitly into homeUser
    mkNixOS = { system, hostFile, hostName }: let
      pkgsForSystem = import nixpkgs {
  inherit system;
  config = { allowUnfree = config.packages.allowUnfree; };
  overlays = [ nix-vscode-extensions.overlays.default ];
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
          home-manager.sharedModules = [ catppuccin.homeManagerModules.catppuccin ];
          home-manager.users.${userConfig.username} = homeUser { pkgsFor = pkgsForSystem; isDarwin = false; inherit hostName; };
        }
      ];
    };

    # DRY Darwin builder: compute pkgs for Darwin and pass into homeUser
    mkDarwin = { system, hostFile, hostName }: let
      pkgsForDarwin = import nixpkgs-darwin {
  inherit system;
  config = { allowUnfree = config.packages.allowUnfree; };
  overlays = [ nix-vscode-extensions.overlays.default ];
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
          home-manager.users.${userConfig.username} = homeUser { pkgsFor = pkgsForDarwin; isDarwin = true; inherit hostName; };
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
  in {
      nixosConfigurations = rec {
        default = mkNixOS { system = "x86_64-linux"; hostFile = ./hosts/laptop; hostName = "laptop"; };
        laptop  = default;
        server  = mkNixOS { system = "x86_64-linux"; hostFile = ./hosts/server; hostName = "server"; };
      };

    darwinConfigurations = {
      macmini = mkDarwin { system = "aarch64-darwin"; hostFile = ./hosts/macmini; hostName = "macmini"; };
    };
  };
}