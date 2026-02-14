{
  description = "Nix config management tools in Rust";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          
          mkRustTool = { name, src }:
            pkgs.stdenv.mkDerivation {
              inherit name;
              inherit src;
              
              # Tell Nix not to try to unpack the .rs file like a tarball
              dontUnpack = true;
              
              buildInputs = [ pkgs.rustc ];
              
              # Use $src (shell variable) because we aren't in an unpacked directory
              buildPhase = ''
                rustc --edition 2021 -O $src -o ${name}
              '';
              
              installPhase = ''
                mkdir -p $out/bin
                cp ${name} $out/bin/
              '';
            };
        in
        {
          darwin-export = mkRustTool {
            name = "darwin-export";
            src = ./src/darwin-export.rs;
          };
          
          gnome-export = mkRustTool {
            name = "gnome-export";
            src = ./src/gnome-export.rs;
          };
          
          secrets-setup = mkRustTool {
            name = "secrets-setup";
            src = ./src/secrets-setup.rs;
          };
          
          default = pkgs.buildEnv {
            name = "nix-config-tools";
            paths = [
              (mkRustTool { name = "darwin-export"; src = ./src/darwin-export.rs; })
              (mkRustTool { name = "gnome-export"; src = ./src/gnome-export.rs; })
              (mkRustTool { name = "secrets-setup"; src = ./src/secrets-setup.rs; })
            ];
          };
        }
      );
      
      apps = forAllSystems (system: {
        darwin-export = {
          type = "app";
          program = "${self.packages.${system}.darwin-export}/bin/darwin-export";
        };
        
        gnome-export = {
          type = "app";
          program = "${self.packages.${system}.gnome-export}/bin/gnome-export";
        };
        
        secrets-setup = {
          type = "app";
          program = "${self.packages.${system}.secrets-setup}/bin/secrets-setup";
        };
        
        default = {
          type = "app";
          program = "${self.packages.${system}.secrets-setup}/bin/secrets-setup";
        };
      });
    };
}