{ config, pkgs, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
  resolve = cfgLib.resolvePackages pkgs;
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
