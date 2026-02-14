{ config, pkgs, ... }:

let
  cfg = import ../../settings/config.nix;

  # Resolve a nixpkgs attribute name safely
  toPkg = name:
    if pkgs ? ${name} then pkgs.${name}
    else builtins.trace "WARNING: package '${name}' not found in nixpkgs, skipping" null;

  resolve = names: builtins.filter (x: x != null) (map toPkg names);
in
{
  environment.systemPackages =
    # Common CLI utilities (all systems)
    resolve cfg.packages.common
    # Cross-platform development packages (shared with NixOS laptop)
    ++ resolve cfg.packages.development
    # macOS-specific packages (GNU replacements, macFUSE tools, build libs)
    ++ resolve cfg.darwin.packages;

  programs = {
    # zsh is already enabled in darwin/common.nix
    bash.enable = true;
  };
}
