{
  description = "Nix config management tools";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = "nix-config-tools";
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };
        }
      );
      apps = forAllSystems (system: 
        let pkg = self.packages.${system}.default; in
        {
          darwin-export = { type = "app"; program = "${pkg}/bin/darwin-export"; };
          gnome-export = { type = "app"; program = "${pkg}/bin/gnome-export"; };
          secrets-setup = { type = "app"; program = "${pkg}/bin/secrets-setup"; };
        }
      );
    };
}
