{
  config,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;

  resolvePackages =
    names:
    builtins.filter (x: x != null) (
      map (
        name:
        if pkgs ? ${name} then
          pkgs.${name}
        else
          builtins.trace "WARNING: package '${name}' not found in nixpkgs, skipping" null
      ) names
    );
in
{
  environment.systemPackages =
    # Common CLI utilities (all systems)
    resolvePackages cfg.packages.common
    # Cross-platform development packages (shared with NixOS laptop)
    ++ resolvePackages cfg.packages.development
    # macOS-specific packages (GNU replacements, macFUSE tools, build libs)
    ++ resolvePackages cfg.packages.darwin;

  programs = {
    # zsh is already enabled in darwin/common.nix
    bash.enable = true;
  };
}
