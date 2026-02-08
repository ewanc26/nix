{ config, pkgs, lib, ... }:

{
  # GNOME desktop settings
  dconf.settings = {
    # Wallpaper settings
    "org/gnome/desktop/background" = {
      picture-uri = "file://${config.home.homeDirectory}/.config/wallpapers/wallpaper.jpg";
      picture-uri-dark = "file://${config.home.homeDirectory}/.config/wallpapers/wallpaper.jpg";
      picture-options = "zoom";
    };

    # Lock screen wallpaper
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${config.home.homeDirectory}/.config/wallpapers/wallpaper.jpg";
      picture-options = "zoom";
    };

    # Interface settings
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-show-weekday = true;
      show-battery-percentage = true;
    };

    # Window manager preferences
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      num-workspaces = 4;
    };

    # File chooser settings
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };
  };

  # Copy wallpaper to home directory
  home.file.".config/wallpapers/wallpaper.jpg" = {
    source = ../../wallpapers/wallpaper.jpg;
  };
}
