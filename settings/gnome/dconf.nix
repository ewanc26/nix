# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "housekeeping" = {
      donation-reminder-last-shown = "int64 1770568675932549";
    };

    "org/gnome/Console" = {
      custom-font = "FiraCode Nerd Font 10";
      last-window-maximised = false;
      last-window-size = mkTuple [ 732 528 ];
      use-system-font = false;
    };

    "org/gnome/control-center" = {
      last-panel = "background";
      window-state = mkTuple [ 980 640 false ];
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [ "System" "Utilities" "YaST" "Pardus" ];
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/System" = {
      apps = [ "org.gnome.baobab.desktop" "org.gnome.DiskUtility.desktop" "org.gnome.Logs.desktop" "org.gnome.SystemMonitor.desktop" ];
      name = "X-GNOME-Shell-System.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [ "org.gnome.Decibels.desktop" "org.gnome.Connections.desktop" "org.gnome.Papers.desktop" "org.gnome.font-viewer.desktop" "org.gnome.Loupe.desktop" ];
      name = "X-GNOME-Shell-Utilities.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/amber-l.jxl";
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/amber-d.jxl";
      primary-color = "#ff7800";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/input-sources" = {
      sources = [ (mkTuple [ "xkb" "gb" ]) ];
      xkb-options = [ "terminate:ctrl_alt_bksp" ];
    };

    "org/gnome/desktop/interface" = {
      accent-color = "green";
      clock-show-weekday = true;
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      show-battery-percentage = true;
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/amber-l.jxl";
      primary-color = "#ff7800";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      num-workspaces = 4;
    };

    "org/gnome/evolution-data-server" = {
      migrated = true;
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      migrated-gtk-settings = true;
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = "(890, 550)";
      initial-size-file-chooser = "(890, 550)";
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = false;
    };

    "org/gnome/settings-daemon/plugins/housekeeping" = {
      donation-reminder-last-shown = "int64 1770582535353982";
    };

    "org/gnome/shell" = {
      app-picker-layout = "\"[{'org.gnome.Calculator.desktop': <{'position': <0>}>, 'org.gnome.Contacts.desktop': <{'position': <1>}>, 'org.gnome.Weather.desktop': <{'position': <2>}>, 'org.gnome.clocks.desktop': <{'position': <3>}>, 'org.gnome.Maps.desktop': <{'position': <4>}>, 'org.gnome.Extensions.desktop': <{'position': <5>}>, 'org.gnome.SimpleScan.desktop': <{'position': <6>}>, 'org.gnome.Settings.desktop': <{'position': <7>}>, 'htop.desktop': <{'position': <8>}>, 'org.gnome.Showtime.desktop': <{'position': <9>}>, 'org.gnome.Snapshot.desktop': <{'position': <10>}>, 'cups.desktop': <{'position': <11>}>, 'nixos-manual.desktop': <{'position': <12>}>, 'org.gnome.seahorse.Application.desktop': <{'position': <13>}>, 'org.gnome.Console.desktop': <{'position': <14>}>, 'org.gnome.TextEditor.desktop': <{'position': <15>}>, 'org.gnome.Yelp.desktop': <{'position': <16>}>}, {'vim.desktop': <{'position': <0>}>, 'vlc.desktop': <{'position': <1>}>, 'xterm.desktop': <{'position': <2>}>, 'org.gnome.Decibels.desktop': <{'position': <3>}>, 'org.gnome.Connections.desktop': <{'position': <4>}>, 'org.gnome.baobab.desktop': <{'position': <5>}>, 'org.gnome.DiskUtility.desktop': <{'position': <6>}>, 'org.gnome.Papers.desktop': <{'position': <7>}>, 'org.gnome.font-viewer.desktop': <{'position': <8>}>, 'org.gnome.Loupe.desktop': <{'position': <9>}>, 'org.gnome.Logs.desktop': <{'position': <10>}>, 'org.gnome.SystemMonitor.desktop': <{'position': <11>}>, 'org.gnome.Calendar.desktop': <{'position': <12>}>, 'spotify.desktop': <{'position': <13>}>}]\"";
      enabled-extensions = [ "system-monitor@gnome-shell-extensions.gcampax.github.com" "extension-list@tu.berry" "drive-menu@gnome-shell-extensions.gcampax.github.com" "add-to-desktop@tommimon.github.com" "fq@megh" ];
      favorite-apps = [ "org.gnome.Nautilus.desktop" "steam.desktop" "org.prismlauncher.PrismLauncher.desktop" "firefox.desktop" "spotify.desktop" "discord.desktop" "code.desktop" ];
      welcome-dialog-last-shown-version = "49.2";
    };

    "org/gnome/shell/world-clocks" = {
      locations = [];
    };

    "org/gnome/terminal/legacy" = {
      theme-variant = "dark";
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      background-color = "rgb(23,20,33)";
      font = "RobotoMono Nerd Font 11";
      foreground-color = "rgb(208,207,204)";
      use-system-font = false;
      use-theme-colors = false;
      visible-name = "Default";
    };

    "org/gtk/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 167;
      sort-column = "name";
      sort-directories-first = true;
      sort-order = "ascending";
      type-format = "category";
      window-position = mkTuple [ 26 23 ];
      window-size = mkTuple [ 1231 902 ];
    };

    "plugins/housekeeping" = {
      donation-reminder-last-shown = "int64 1770568675932549";
    };

  };
}
