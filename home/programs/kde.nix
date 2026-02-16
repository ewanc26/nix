{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  # ─── Declarative plasma-manager settings ────────────────────────────────────
  # settings/plasma/default.nix contains intentional layout / behaviour prefs.
  # Values below supplement it with config-driven values from settings/config/.
  imports = [
    ../../settings/plasma
  ];

  # ─── Konsole ────────────────────────────────────────────────────────────────
  programs.konsole = {
    enable = true;
    defaultProfile = "Catppuccin Mocha";
    profiles = {
      "Catppuccin Mocha" = {
        name        = "Catppuccin Mocha";
        # Name= field from the .colorscheme file installed by catppuccin/konsole
        colorScheme = "Catppuccin Mocha";
        font = {
          name = cfg.desktop.monoFontConsole;
          size = 11;
        };
      };
    };
  };

  # ─── Config-derived plasma settings ──────────────────────────────────────────
  programs.plasma = {

    # Wallpaper – tracks wallpapers/wallpaper.jpg in this repo
    workspace.wallpaper = "${../../wallpapers/wallpaper.jpg}";

    # Fonts – driven from settings/config/desktop.nix
    fonts = {
      # UI font: Noto Sans is the closest open-source match to macOS San Francisco.
      # Override with "Inter" if you add pkgs.inter to home.packages.
      general = {
        family    = "Noto Sans";
        pointSize = 10;
      };
      fixedWidth = {
        family    = "FiraCode Nerd Font Mono";
        pointSize = 11;
      };
    };

    # Icon theme – driven from settings/config/desktop.nix
    # Catppuccin module installs catppuccin-papirus-folders; Papirus-Dark works
    # whether or not the catppuccin icon override is active.
    configFile."kdeglobals".Icons.Theme = cfg.desktop.iconTheme;

  };
}
