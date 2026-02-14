{ config, pkgs, ... }:

let
  cfg = import ../settings/config.nix;
in
{
  # System-wide programs with built-in NixOS options
  programs = {
    firefox.enable = true;
    git.enable     = true;
  };

  # Packages that don't have dedicated NixOS program options.
  # The canonical list lives in settings/config/packages.nix → desktop.
  environment.systemPackages = map (name: pkgs.${name}) cfg.packages.desktop;
}
