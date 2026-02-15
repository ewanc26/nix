{ lib }:

let
  # Import the central config once at the library level
  cfg = import ../settings/config.nix;

in {
  # Expose the config so modules can just use `cfgLib.cfg` instead of importing
  inherit cfg;

  # Helper to create a module with auto-injected config
  # Usage: mkModule { config, pkgs, ... }: { ... }
  mkModule = moduleFunc: { config, pkgs, lib, ... }@args:
    moduleFunc (args // { inherit cfg; });

  # Helper to create a home-manager program module with platform info
  # Usage: mkHomeProgram { isDarwin }: { config, pkgs, ... }: { ... }
  mkHomeProgram = { isDarwin ? false }: moduleFunc: { config, pkgs, lib, ... }@args:
    moduleFunc (args // { inherit cfg isDarwin; });

  # Helper to resolve package names to actual packages, skipping missing ones
  # Usage: resolvePackages pkgs [ "firefox" "vscode" ]
  resolvePackages = pkgs: names:
    let
      toPkg = name:
        if pkgs ? ${name} then pkgs.${name}
        else builtins.trace "WARNING: package '${name}' not found in nixpkgs, skipping" null;
    in
      builtins.filter (x: x != null) (map toPkg names);

  # Helper to create SSH authorized keys excluding the current host
  # Usage: mkAuthorizedKeys hostName
  mkAuthorizedKeys = hostName:
    let
      allKeys = import ../modules/ssh-keys.nix;
    in
      lib.attrValues (lib.filterAttrs (name: _: name != hostName) allKeys);
}
