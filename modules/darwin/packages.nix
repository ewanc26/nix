{ config, pkgs, ... }:

let
  cfg = import ../../settings/config.nix;
in
{
  # macOS nixpkgs packages – list driven from settings/config/darwin.nix
  environment.systemPackages = map (name: pkgs.${name}) cfg.darwin.packages;

  programs = {
    # zsh is already enabled in darwin/common.nix
    bash.enable = true;
  };
}
