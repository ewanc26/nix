# System-wide packages — common, development, and desktop lists.
# On Linux desktop hosts (laptop), all three categories are installed.
# Server and headless hosts only get common + development packages.
# The actual package name lists live in options.nix (myConfig.packages.*).
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
