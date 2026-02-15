{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  # ─── Declarative dconf settings ─────────────────────────────────────────────
  # settings/gnome/dconf-settings.nix contains intentional dconf preferences.
  # Values below supplement it with config-driven values from settings/config/.
  # Both sets are merged by Home Manager — gnome.nix keys take precedence on
  # any path that appears in both files.
  imports = [
    ../../settings/gnome
  ];

  # ─── GNOME extension packages ────────────────────────────────────────────────
  # Package list driven from settings/config/desktop.nix → gnome.extensionPackages
  home.packages =
    map (name: pkgs.gnomeExtensions.${name}) cfg.desktop.gnome.extensionPackages;

  # ─── Config-derived dconf overrides ──────────────────────────────────────────
  # Only keys that should track settings/config values live here.
  # Extension preferences, input sources, WM settings, etc. live in
  # settings/gnome/dconf-settings.nix (edit directly — it is the source of truth).
  dconf.settings = {

    # Wallpaper – tracks the wallpapers/wallpaper.jpg in this repo
    "org/gnome/desktop/background" = {
      picture-uri      = "file://${../../wallpapers/wallpaper.jpg}";
      picture-uri-dark = "file://${../../wallpapers/wallpaper.jpg}";
      picture-options  = "zoom";
    };

    # Theme + monospace font – driven from settings/config/desktop.nix
    "org/gnome/desktop/interface" = {
      gtk-theme           = cfg.desktop.theme;
      icon-theme          = cfg.desktop.iconTheme;
      color-scheme        = "prefer-dark";
      monospace-font-name = cfg.desktop.monoFont;
    };

    # GNOME Console font – driven from settings/config/desktop.nix
    "org/gnome/Console" = {
      custom-font      = cfg.desktop.monoFontConsole;
      use-system-font  = false;
    };

    # Enabled extensions – driven from settings/config/desktop.nix
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions      = cfg.desktop.gnome.enabledExtensions;
    };
  };
}
