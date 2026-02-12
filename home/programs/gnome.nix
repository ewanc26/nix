{ config, pkgs, lib, ... }:

{
  # Import all GNOME settings from encrypted dconf settings
  # This will load all dconf settings from settings/gnome/default.nix
  imports = [
    ../../settings/gnome
  ];

  # GNOME wallpaper configuration
  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri = "file://${../../wallpapers/wallpaper.jpg}";
      picture-uri-dark = "file://${../../wallpapers/wallpaper.jpg}";
      picture-options = "zoom";
    };
  };
}
