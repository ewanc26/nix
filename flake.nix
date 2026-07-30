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

    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    mac-app-util.url = "github:hraban/mac-app-util";

    # Language-agnostic monorepo with TypeScript and Rust packages
    pkgs-monorepo = {
      url = "github:ewanc26/pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Isabel's packages — provides pds-gatekeeper NixOS module and package
    tgirlpkgs = {
      url = "github:tgirlcloud/pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-darwin,
      sops-nix,
      nix-topology,
      nix-vscode-extensions,
      mac-app-util,
      plasma-manager,
      pkgs-monorepo,
      tgirlpkgs,
      ...
    }:
    let
      # Shared home-manager modules used by every host.
      sharedHMModules = [
        sops-nix.homeManagerModules.sops
      ];

      # Nixpkgs settings applied identically on every host.
      sharedNixpkgsConfig = {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
      };

      # Build a home-manager configuration block, parameterised per platform.
      # isDarwin   — sets extraSpecialArgs.isDarwin and controls which extra
      #              HM modules are loaded (plasma-manager vs mac-app-util).
      # extraModules — platform-specific HM modules appended to sharedHMModules.
      mkHMConfig =
        {
          isDarwin,
          extraModules ? [ ],
        }:
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit isDarwin; };
          home-manager.sharedModules = sharedHMModules ++ extraModules;
          home-manager.users.ewan = ./home/default.nix;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.overwriteBackup = true;
        };

      # Instantiate nixpkgs-unstable for a given system with allowUnfree = true.
      mkUnstablePkgs =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

      # Modules common to every NixOS host.
      nixosModules = [
        ./modules/options.nix
        ./modules/common.nix
        sops-nix.nixosModules.sops
        nix-topology.nixosModules.default
        home-manager.nixosModules.home-manager
        sharedNixpkgsConfig
        (mkHMConfig {
          isDarwin = false;
          extraModules = [ plasma-manager.homeModules.plasma-manager ];
        })
      ];

      # Modules common to every nix-darwin host.
      darwinModules = [
        ./modules/options.nix
        mac-app-util.darwinModules.default
        home-manager.darwinModules.home-manager
        sharedNixpkgsConfig
        (mkHMConfig {
          isDarwin = true;
          extraModules = [ mac-app-util.homeManagerModules.default ];
        })
      ];

      forAllSystems =
        f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system: f system);

      # Package set with the nix-topology overlay — required to build the topology output.
      topologyPkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ nix-topology.overlays.default ];
      };
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # Every host, exposed so `nix flake check` covers all of them.
      #
      # With --no-build (what CI runs) this is eval-only: every module is
      # imported and every option type-checked, but nothing is built, so it
      # finishes in minutes on a free runner. Drop --no-build to actually build
      # the closures. Evaluating the nix-darwin host does not require macOS.
      #
      # This exists because the failure mode that bit this repo was a module
      # edited into a syntax error and a host that only breaks on an
      # architecture nobody rebuilds by hand — both invisible for a month
      # because nothing ever evaluated the configs except a manual rebuild.
      checks = {
        x86_64-linux = {
          laptop = self.nixosConfigurations.laptop.config.system.build.toplevel;
          server = self.nixosConfigurations.server.config.system.build.toplevel;
        };
        aarch64-linux.server-arm = self.nixosConfigurations.server-arm.config.system.build.toplevel;
        aarch64-darwin.macmini = self.darwinConfigurations.macmini.system;
      };

      # Render infrastructure diagrams: nix build .#topology.x86_64-linux.config.output
      topology.x86_64-linux = import nix-topology {
        pkgs = topologyPkgs;
        modules = [
          ./topology.nix
          { nixosConfigurations = self.nixosConfigurations; }
        ];
      };

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
            inherit self pkgs-monorepo;
            pkgs-unstable = mkUnstablePkgs "x86_64-linux";
          };
          modules = nixosModules ++ [
            tgirlpkgs.nixosModules.default
            ./hosts/server
            { nixpkgs.hostPlatform = "x86_64-linux"; }
          ];
        };

        server-arm = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit self pkgs-monorepo;
            pkgs-unstable = mkUnstablePkgs "aarch64-linux";
          };
          modules = nixosModules ++ [
            tgirlpkgs.nixosModules.default
            ./hosts/server
            { nixpkgs.hostPlatform = "aarch64-linux"; }
          ];
        };
      };

      darwinConfigurations = {
        macmini = nix-darwin.lib.darwinSystem {
          modules = darwinModules ++ [
            ./hosts/macmini
            { nixpkgs.hostPlatform = "aarch64-darwin"; }
          ];
        };
      };
    };
}
