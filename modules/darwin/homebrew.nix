{ config, pkgs, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
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
