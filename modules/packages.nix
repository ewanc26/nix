{ config, pkgs, ... }:

let
  cfg = import ../settings/config.nix;

  # Resolve a nixpkgs attribute name, skipping any that don't exist in this
  # pkgs set (e.g. macOS-only packages referenced by mistake).
  toPkg = name:
    if pkgs ? ${name} then pkgs.${name}
    else builtins.trace "WARNING: package '${name}' not found in nixpkgs, skipping" null;

  resolve = names: builtins.filter (x: x != null) (map toPkg names);
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
