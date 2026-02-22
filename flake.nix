{
  description = "NixOS / nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-darwin,
      sops-nix,
      nix-vscode-extensions,
      catppuccin,
      mac-app-util,
      plasma-manager,
      ...
    }:
    let
      # Shared home-manager modules used by every host.
      sharedHMModules = [
        catppuccin.homeModules.catppuccin
        sops-nix.homeManagerModules.sops
      ];

      # Modules common to every NixOS host.
      nixosModules = [
        ./modules/options.nix
        ./modules/common.nix
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
        }
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            isDarwin = false;
          };
          home-manager.sharedModules = sharedHMModules ++ [
            plasma-manager.homeModules.plasma-manager
          ];
          home-manager.users.ewan = ./home/default.nix;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.overwriteBackup = true;
        }
      ];

      # Modules common to every nix-darwin host.
      darwinModules = [
        ./modules/options.nix
        mac-app-util.darwinModules.default
        home-manager.darwinModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
        }
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            isDarwin = true;
          };
          home-manager.sharedModules = sharedHMModules ++ [
            mac-app-util.homeManagerModules.default
          ];
          home-manager.users.ewan = ./home/default.nix;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.overwriteBackup = true;
        }
      ];

      forAllSystems =
        f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system: f system);
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self; };
          modules = nixosModules ++ [
            ./hosts/laptop
            { nixpkgs.hostPlatform = "x86_64-linux"; }
          ];
        };

        server = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit self;
            pkgs-unstable = import nixpkgs-unstable { system = "x86_64-linux"; config.allowUnfree = true; };
          };
          modules = nixosModules ++ [
            ./hosts/server
            { nixpkgs.hostPlatform = "x86_64-linux"; }
          ];
        };

        server-arm = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit self;
            pkgs-unstable = import nixpkgs-unstable { system = "aarch64-linux"; config.allowUnfree = true; };
          };
          modules = nixosModules ++ [
            ./hosts/server
            { nixpkgs.hostPlatform = "aarch64-linux"; }
          ];
        };
      };

      darwinConfigurations = {
        macmini = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit self; };
          modules = darwinModules ++ [
            ./hosts/macmini
            { nixpkgs.hostPlatform = "aarch64-darwin"; }
          ];
        };
      };
    };
}
