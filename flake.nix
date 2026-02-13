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

  outputs = { self, nixpkgs, nixpkgs-darwin, home-manager, nix-darwin, ragenix, ... }@inputs: {
    nixosConfigurations = {
      # Default configuration (points to laptop)
      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/laptop
          ragenix.nixosModules.default
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix;
            home-manager.extraSpecialArgs = { isDarwin = false; hostName = "laptop"; };
          }
        ];
      };
      
      # Laptop configuration
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/laptop
          ragenix.nixosModules.default
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix;
            home-manager.extraSpecialArgs = { isDarwin = false; hostName = "laptop"; };
          }
        ];
      };
      
      # Server configuration
      server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server
          ragenix.nixosModules.default
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix;
            home-manager.extraSpecialArgs = { isDarwin = false; hostName = "server"; };
          }
        ];
      };

      # UTM Apple Silicon virual machine server
      vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/vm
          ragenix.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix;
            home-manager.extraSpecialArgs = { isDarwin = false; hostName = "vm"; };
          }
        ];
      };
      
      # Add more hosts here in the future, e.g.:
      # desktop = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     ./hosts/desktop
      #     home-manager.nixosModules.home-manager
      #     {
      #       home-manager.useGlobalPkgs = true;
      #       home-manager.useUserPackages = true;
      #       home-manager.users.ewan = import ./home/home.nix;
      #       home-manager.extraSpecialArgs = { isDarwin = false; };
      #     }
      #   ];
      # };
    };

    # macOS configurations
    darwinConfigurations = {
      # MacMini configuration
      macmini = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";  # Apple Silicon (M1/M2/M3)
        # Use "x86_64-darwin" for Intel Macs
        
        modules = [
          ./hosts/macmini
          ragenix.darwinModules.default
          
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ewan = import ./home/home.nix;
            home-manager.extraSpecialArgs = { isDarwin = true; hostName = "macmini"; };
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    };
  };
}
