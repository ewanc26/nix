{ config, pkgs, cfgLib, ... }:

let
  cfg = cfgLib.cfg;

  # Normalise every cask entry to an attrset and force greedy = true so
  # that `brew upgrade` always overwrites out-of-date casks — including
  # those that declare auto_updates or version :latest.
  makeGreedy = cask:
    if builtins.isString cask
    then { name = cask; greedy = true; }
    else cask // { greedy = true; };
in
{
  # Homebrew configuration – all values driven from settings/config/darwin.nix
  homebrew = {
    inherit (cfg.darwin.homebrew) enable taps brews masApps;
    casks = map makeGreedy cfg.darwin.homebrew.casks;

    onActivation = {
      autoUpdate = true;
      upgrade    = true;
      cleanup    = "uninstall";
    };
  };
}
