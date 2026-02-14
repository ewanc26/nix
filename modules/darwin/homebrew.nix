{ config, pkgs, ... }:

let
  cfg = import ../../settings/config.nix;
in
{
  # Homebrew configuration – all values driven from settings/config/darwin.nix
  homebrew = {
    inherit (cfg.darwin.homebrew) enable taps brews casks masApps;

    onActivation = {
      autoUpdate = true;
      upgrade    = true;
      cleanup    = "uninstall";
    };
  };
}
