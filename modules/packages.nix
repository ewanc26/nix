{ config, pkgs, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
  resolve = cfgLib.resolvePackages pkgs;
in
{
  # System-wide programs with dedicated NixOS module options
  programs = {
    firefox.enable = true;
    git.enable     = true;
  };

  environment.systemPackages =
    # Common CLI utilities (all systems)
    resolve cfg.packages.common
    # Cross-platform development packages
    ++ resolve cfg.packages.development
    # NixOS desktop / GUI apps
    ++ resolve cfg.packages.desktop;
}
