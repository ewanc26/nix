# Terminal emulator profile — shared by all non-Darwin hosts (laptop + server).
# Controls the font and colour scheme used by Konsole / any KDE-aware terminal.
# Font and size come from settings/config/desktop.nix — never hardcoded here.
{ lib, cfgLib, ... }:

let
  d = cfgLib.cfg.desktop;
in
{
  programs.konsole = {
    enable         = true;
    defaultProfile = "Catppuccin Mocha";
    profiles."Catppuccin Mocha" = {
      name        = "Catppuccin Mocha";
      colorScheme = "Catppuccin Mocha";   # installed by the catppuccin/konsole package
      font = {
        name = d.monoFontConsole;   # "FiraCode Nerd Font Mono"
        size = d.monoFontSize;      # 11
      };
    };
  };
}
