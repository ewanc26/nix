# System-wide packages for Linux desktop hosts.
{
  config,
  pkgs,
  lib,
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
  programs = {
    firefox.enable = true;
    git.enable = true;
  };

  environment.systemPackages =
    resolvePackages cfg.packages.common
    ++ resolvePackages cfg.packages.development
    ++ lib.optionals cfg.isDesktop (resolvePackages cfg.packages.desktop);
}
