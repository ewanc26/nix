# Generated at 2026-02-14 20:25:55
# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "apps/seahorse/listing" = {
      keyrings-selected = [ "openssh:///home/ewan/.ssh" ];
    };

    "apps/seahorse/windows/key-manager" = {
      height = 476;
      width = 600;
    };

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
      primary-color = "#3a4ba0";
      secondary-color = "#2f302f";
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
      monospace-font-name = "FiraCode Nerd Font Mono 11";
      show-battery-percentage = true;
    };

    "org/gnome/desktop/notifications" = {
      application-children = [ "gnome-about-panel" "discord" ];
    };

    "org/gnome/desktop/notifications/application/discord" = {
      application-id = "discord.desktop";
    };

    "org/gnome/desktop/notifications/application/firefox" = {
      application-id = "firefox.desktop";
    };

    "org/gnome/desktop/notifications/application/gnome-about-panel" = {
      application-id = "gnome-about-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = false;
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///nix/store/mh4hbqq6b0x4sfb2jqjjzllya0lg27fx-simple-blue-2016-02-19/share/backgrounds/nixos/nix-wallpaper-simple-blue.png";
      primary-color = "#3a4ba0";
      secondary-color = "#2f302f";
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
      initial-size = mkTuple [ 890 550 ];
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
      command-history = [ "r" ];
      disable-user-extensions = false;
      disabled-extensions = [];
      enabled-extensions = [ "system-monitor@gnome-shell-extensions.gcampax.github.com" "extension-list@tu.berry" "drive-menu@gnome-shell-extensions.gcampax.github.com" "add-to-desktop@tommimon.github.com" "fq@megh" "astra-monitor@astraext.github.io" "mediacontrols@cliffniff.github.com" "dash-to-dock@micxgx.gmail.com" "system-monitor@gnome-shell-extensions.gcampax.github.com" "extension-list@tu.berry" "drive-menu@gnome-shell-extensions.gcampax.github.com" "add-to-desktop@tommimon.github.com" "fq@megh" "monitor@astraext.github.io" "astra-monitor@astraext.github.io" "mediacontrols@cliffniff.github.com" "dash-to-dock@micxgx.gmail.com" "system-monitor@gnome-shell-extensions.gcampax.github.com" "extension-list@tu.berry" "drive-menu@gnome-shell-extensions.gcampax.github.com" "add-to-desktop@tommimon.github.com" "fq@megh" "astra-monitor@astraext.github.io" "mediacontrols@cliffniff.github.com" "dash-to-dock@micxgx.gmail.com" "system-monitor@gnome-shell-extensions.gcampax.github.com" "extension-list@tu.berry" "drive-menu@gnome-shell-extensions.gcampax.github.com" "add-to-desktop@tommimon.github.com" "fq@megh" ];
      favorite-apps = [ "org.gnome.Nautilus.desktop" "steam.desktop" "org.prismlauncher.PrismLauncher.desktop" "firefox.desktop" "spotify.desktop" "signal.desktop" "discord.desktop" "code.desktop" ];
      welcome-dialog-last-shown-version = "49.2";
    };

    "org/gnome/shell/extensions/astra-monitor" = {
      experimental-features = "[]";
      gpu-header-activity-percentage = true;
      gpu-header-show = false;
      gpu-indicators-order = "[\"icon\",\"activity bar\",\"activity graph\",\"activity percentage\",\"memory bar\",\"memory graph\",\"memory percentage\",\"memory value\"]";
      headers-height = 0;
      headers-height-override = 0;
      memory-header-graph = true;
      memory-header-percentage = true;
      memory-header-show = true;
      memory-indicators-order = "[\"icon\",\"bar\",\"graph\",\"percentage\",\"value\",\"free\"]";
      monitors-order = "[\"processor\",\"gpu\",\"memory\",\"storage\",\"network\",\"sensors\"]";
      network-header-graph = false;
      network-header-io = true;
      network-header-io-unit = "kB/s";
      network-header-show = true;
      network-indicators-order = "[\"icon\",\"IO bar\",\"IO graph\",\"IO speed\"]";
      processor-header-graph = true;
      processor-header-percentage = true;
      processor-header-show = true;
      processor-indicators-order = "[\"icon\",\"bar\",\"graph\",\"percentage\",\"frequency\"]";
      processor-menu-gpu-color = "";
      profiles = ''
        {"default":{"panel-margin-left":0,"sensors-header-tooltip-sensor2-digits":-1,"memory-update":3,"gpu-header-memory-graph-color1":"rgba(29,172,214,1.0)","panel-box":"right","memory-header-show":true,"network-header-tooltip-io":true,"processor-header-bars-color2":"rgba(214,29,29,1.0)","processor-header-icon-size":18,"storage-source-storage-io":"auto","sensors-header-tooltip-sensor4-name":"","storage-header-icon-color":"","network-source-public-ipv4":"https://api.ipify.org","storage-header-io-graph-color2":"rgba(214,29,29,1.0)","storage-header-io":false,"processor-menu-top-processes-percentage-core":true,"sensors-header-sensor1":"\\"\\"","processor-header-graph":true,"storage-header-graph-width":30,"network-header-bars":false,"processor-source-load-avg":"auto","network-menu-arrow-color1":"rgba(29,172,214,1.0)","network-source-top-processes":"auto","gpu-header-icon":true,"processor-menu-graph-breakdown":true,"storage-ignored":"\\"[]\\"","sensors-header-icon-custom":"","sensors-header-sensor2":"\\"\\"","network-header-icon-alert-color":"rgba(235, 64, 52, 1)","memory-header-tooltip-free":false,"storage-header-io-figures":2,"network-menu-arrow-color2":"rgba(214,29,29,1.0)","sensors-header-tooltip-sensor3-name":"","network-source-public-ipv6":"https://api6.ipify.org","monitors-order":"[\\"processor\\",\\"gpu\\",\\"memory\\",\\"storage\\",\\"network\\",\\"sensors\\"]","network-header-graph":false,"network-indicators-order":"[\\"icon\\",\\"IO bar\\",\\"IO graph\\",\\"IO speed\\"]","memory-header-percentage":true,"gpu-data":"\\"\\"","storage-header-bars":true,"processor-header-tooltip":true,"memory-menu-swap-color":"rgba(29,172,214,1.0)","storage-io-unit":"kB/s","memory-header-graph-width":30,"processor-header-graph-color1":"rgba(29,172,214,1.0)","sensors-header-tooltip-sensor5-digits":-1,"gpu-header-icon-custom":"","gpu-header-icon-size":18,"panel-margin-right":0,"processor-header-frequency":false,"processor-header-graph-breakdown":true,"sensors-header-tooltip-sensor3-digits":-1,"processor-source-cpu-usage":"auto","memory-header-value-figures":3,"compact-mode":false,"processor-header-frequency-mode":"average","panel-box-order":0,"compact-mode-compact-icon-custom":"","network-header-graph-width":30,"gpu-header-tooltip":true,"sensors-header-icon":true,"gpu-header-activity-percentage-icon-alert-threshold":0,"sensors-header-sensor2-digits":-1,"processor-header-graph-color2":"rgba(214,29,29,1.0)","sensors-header-icon-alert-color":"rgba(235, 64, 52, 1)","sensors-update":3,"gpu-header-tooltip-memory-value":true,"processor-header-bars":false,"gpu-header-tooltip-memory-percentage":true,"gpu-header-memory-bar-color1":"rgba(29,172,214,1.0)","sensors-header-tooltip-sensor1":"\\"\\"","sensors-header-tooltip-sensor1-digits":-1,"storage-header-free-figures":3,"processor-header-percentage-core":false,"sensors-header-tooltip-sensor2-name":"","network-source-network-io":"auto","memory-header-bars":true,"processor-header-percentage":true,"processor-header-frequency-figures":3,"storage-header-io-threshold":0,"memory-header-graph-color1":"rgba(29,172,214,1.0)","compact-mode-activation":"both","storage-header-icon-size":18,"sensors-header-tooltip-sensor1-name":"","sensors-header-icon-size":18,"sensors-header-icon-color":"","explicit-zero":false,"sensors-source":"auto","storage-header-io-graph-color1":"rgba(29,172,214,1.0)","storage-header-percentage-icon-alert-threshold":0,"sensors-header-tooltip-sensor2":"\\"\\"","compact-mode-expanded-icon-custom":"","memory-header-graph-color2":"rgba(29,172,214,0.3)","processor-header-icon-alert-color":"rgba(235, 64, 52, 1)","processor-header-tooltip-percentage":true,"gpu-header-show":false,"network-update":1.5,"sensors-header-tooltip-sensor3":"\\"\\"","sensors-ignored-attribute-regex":"","memory-header-icon-custom":"","storage-header-tooltip-io":true,"sensors-header-tooltip-sensor4":"\\"\\"","storage-header-percentage":false,"sensors-temperature-unit":"celsius","storage-header-icon-alert-color":"rgba(235, 64, 52, 1)","storage-header-free-icon-alert-threshold":0,"memory-source-top-processes":"auto","storage-header-value-figures":3,"storage-header-io-bars-color1":"rgba(29,172,214,1.0)","storage-menu-arrow-color1":"rgba(29,172,214,1.0)","gpu-header-tooltip-activity-percentage":true,"network-header-icon-custom":"","processor-header-graph-width":30,"network-header-icon":true,"storage-menu-arrow-color2":"rgba(214,29,29,1.0)","sensors-header-sensor2-layout":"vertical","sensors-header-tooltip-sensor5":"\\"\\"","memory-header-bars-breakdown":true,"sensors-header-show":true,"sensors-header-tooltip":false,"storage-header-tooltip":true,"processor-header-bars-core":false,"storage-indicators-order":"[\\"icon\\",\\"bar\\",\\"percentage\\",\\"value\\",\\"free\\",\\"IO bar\\",\\"IO graph\\",\\"IO speed\\"]","processor-menu-bars-breakdown":true,"storage-header-io-bars-color2":"rgba(214,29,29,1.0)","network-io-unit":"kB/s","storage-header-icon":true,"gpu-header-activity-graph-color1":"rgba(29,172,214,1.0)","memory-unit":"kB-KB","processor-menu-core-bars-breakdown":true,"sensors-header-sensor2-show":false,"network-header-tooltip":true,"storage-header-tooltip-free":true,"storage-header-bars-color1":"rgba(29,172,214,1.0)","theme-style":"dark","storage-source-storage-usage":"auto","network-header-io":true,"storage-header-tooltip-value":false,"storage-main":"BC711_NVMe_SK_hynix_256GB__CY12N08781220331S-part2","memory-header-tooltip-percentage":true,"memory-indicators-order":"[\\"icon\\",\\"bar\\",\\"graph\\",\\"percentage\\",\\"value\\",\\"free\\"]","memory-source-memory-usage":"auto","memory-header-graph-breakdown":false,"memory-header-tooltip-value":true,"memory-menu-graph-breakdown":true,"sensors-indicators-order":"[\\"icon\\",\\"value\\"]","compact-mode-start-expanded":false,"startup-delay":2,"memory-header-percentage-icon-alert-threshold":0,"sensors-header-sensor1-show":false,"network-ignored-regex":"","storage-update":3,"memory-header-value":false,"memory-header-bars-color1":"rgba(29,172,214,1.0)","network-header-io-graph-color1":"rgba(29,172,214,1.0)","gpu-header-memory-bar":true,"memory-used":"total-free-buffers-cached","gpu-header-memory-graph-width":30,"gpu-header-memory-graph":false,"sensors-ignored-category-regex":"","headers-font-family":"","memory-header-icon":true,"memory-header-bars-color2":"rgba(29,172,214,0.3)","network-header-io-graph-color2":"rgba(214,29,29,1.0)","processor-gpu":true,"network-header-icon-color":"","storage-header-value":false,"gpu-header-icon-alert-color":"rgba(235, 64, 52, 1)","processor-header-icon":true,"headers-font-size":0,"network-header-io-figures":2,"network-header-show":true,"sensors-ignored-regex":"","network-header-io-bars-color1":"rgba(29,172,214,1.0)","processor-update":1.5,"network-source-wireless":"auto","processor-indicators-order":"[\\"icon\\",\\"bar\\",\\"graph\\",\\"percentage\\",\\"frequency\\"]","storage-header-icon-custom":"","gpu-header-activity-bar":true,"gpu-header-activity-bar-color1":"rgba(29,172,214,1.0)","shell-bar-position":"top","network-ignored":"\\"[]\\"","network-header-io-bars-color2":"rgba(214,29,29,1.0)","memory-header-icon-color":"","sensors-header-sensor1-digits":-1,"storage-header-io-layout":"vertical","memory-header-icon-size":18,"network-header-io-threshold":0,"storage-header-show":false,"sensors-header-tooltip-sensor4-digits":-1,"processor-header-percentage-icon-alert-threshold":0,"memory-header-tooltip":true,"headers-height-override":0,"memory-header-graph":true,"network-header-icon-size":18,"gpu-header-icon-color":"","memory-header-free-figures":3,"processor-header-bars-breakdown":true,"gpu-header-activity-graph":false,"storage-header-io-bars":false,"memory-header-icon-alert-color":"rgba(235, 64, 52, 1)","storage-header-free":false,"processor-header-icon-custom":"","gpu-header-memory-percentage":false,"processor-header-tooltip-percentage-core":false,"processor-source-cpu-cores-usage":"auto","processor-source-top-processes":"auto","processor-header-icon-color":"","sensors-header-tooltip-sensor5-name":"","gpu-header-activity-graph-width":30,"gpu-header-activity-percentage":true,"gpu-indicators-order":"[\\"icon\\",\\"activity bar\\",\\"activity graph\\",\\"activity percentage\\",\\"memory bar\\",\\"memory graph\\",\\"memory percentage\\",\\"memory value\\"]","network-header-io-layout":"vertical","gpu-update":2,"gpu-header-memory-percentage-icon-alert-threshold":0,"processor-header-bars-color1":"rgba(29,172,214,1.0)","processor-header-show":true,"storage-header-graph":false,"memory-header-free-icon-alert-threshold":0,"storage-ignored-regex":"","storage-menu-device-color":"rgba(29,172,214,1.0)","storage-header-tooltip-percentage":true,"memory-header-free":false,"storage-source-top-processes":"auto"}}
      '';
      queued-pref-category = "";
      sensors-header-show = true;
      sensors-header-tooltip = false;
      sensors-indicators-order = "[\"icon\",\"value\"]";
      storage-header-show = false;
      storage-indicators-order = "[\"icon\",\"bar\",\"percentage\",\"value\",\"free\",\"IO bar\",\"IO graph\",\"IO speed\"]";
      storage-main = "BC711_NVMe_SK_hynix_256GB__CY12N08781220331S-part2";
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      animation-time = 0.2;
      autohide = false;
      click-action = "minimize-or-previews";
      dash-max-icon-size = 48;
      dock-fixed = true;
      dock-position = "BOTTOM";
      extend-height = false;
      hide-delay = 0.2;
      icon-size-fixed = false;
      intellihide = false;
      scroll-action = "cycle-windows";
      show-delay = 0.25;
      show-favorites = true;
      show-mounts = true;
      show-running = true;
      show-show-apps-button = true;
      show-trash = true;
      transparency-mode = "DYNAMIC";
    };

    "org/gnome/shell/extensions/mediacontrols" = {
      element-order = [ "icon" "title" "controls" "menu" "icon" "title" "controls" "menu" ];
      extension-position = "right";
      max-widget-width = 350;
      show-control-icons-play-pause = true;
      show-control-icons-seek-backward = true;
      show-control-icons-seek-forward = true;
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

    "org/gnome/tweaks" = {
      show-extensions-notice = false;
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      show-hidden = true;
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
