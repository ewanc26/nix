# System-wide packages for Linux desktop hosts.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  resolvePackages = (import ../lib).resolveFrom pkgs;
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
