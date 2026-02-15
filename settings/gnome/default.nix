##############################################################################
#  Declarative GNOME / dconf settings — intentional settings only.
#
#  Philosophy:
#  ✓ Only include values that express a deliberate preference
#  ✗ No window positions, sidebar widths, last-opened panels, or scroll state
#  ✗ No machine-specific nix store paths or device UUIDs
#  ✗ No internal migration flags or analytics timestamps
#  ✗ No duplicates of keys already set by home/programs/gnome.nix
#    (theme, icon-theme, color-scheme, monospace-font, Console font,
#     enabled-extensions — those come from settings/config/desktop.nix)
#
#  After editing, run `darwin-rebuild switch` / `nixos-rebuild switch` to apply.
#  No export script is needed; this file IS the source of truth.
##############################################################################
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {

    # ── Keyboard input ────────────────────────────────────────────────────────
    "org/gnome/desktop/input-sources" = {
      sources = [
        (mkTuple [
          "xkb"
          "gb"
        ])
      ];
      xkb-options = [ "terminate:ctrl_alt_bksp" ];
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = false;
    };

    # ── Interface extras (keys not set by gnome.nix's config-driven block) ────
    # NOTE: gtk-theme, icon-theme, color-scheme, monospace-font-name are set
    # from cfg.desktop in home/programs/gnome.nix — do not repeat them here.
    "org/gnome/desktop/interface" = {
      accent-color = "green";
      clock-show-weekday = true;
      enable-hot-corners = false;
      show-battery-percentage = true;
    };

    # ── Window manager ────────────────────────────────────────────────────────
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      num-workspaces = 4;
    };

    # ── Night light ───────────────────────────────────────────────────────────
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = false;
    };

    # ── Shell — taskbar favourites ────────────────────────────────────────────
    # enabled-extensions and disable-user-extensions are set by gnome.nix.
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
        "org.prismlauncher.PrismLauncher.desktop"
        "firefox.desktop"
        "spotify.desktop"
        "signal.desktop"
        "discord.desktop"
        "code.desktop"
      ];
    };

    # ── App folders ───────────────────────────────────────────────────────────
    "org/gnome/desktop/app-folders" = {
      folder-children = [
        "System"
        "Utilities"
      ];
    };

    "org/gnome/desktop/app-folders/folders/System" = {
      apps = [
        "org.gnome.baobab.desktop"
        "org.gnome.DiskUtility.desktop"
        "org.gnome.Logs.desktop"
        "org.gnome.SystemMonitor.desktop"
      ];
      name = "X-GNOME-Shell-System.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [
        "org.gnome.Decibels.desktop"
        "org.gnome.Connections.desktop"
        "org.gnome.Papers.desktop"
        "org.gnome.font-viewer.desktop"
        "org.gnome.Loupe.desktop"
      ];
      name = "X-GNOME-Shell-Utilities.directory";
      translate = true;
    };

    # ── Screensaver ───────────────────────────────────────────────────────────
    # picture-uri is intentionally omitted — the screensaver inherits
    # the desktop wallpaper set in home/programs/gnome.nix.
    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      primary-color = "#3a4ba0";
      secondary-color = "#2f302f";
    };

    # ── Nautilus (Files) ──────────────────────────────────────────────────────
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
    };

    # ── File chooser ─────────────────────────────────────────────────────────
    "org/gtk/gtk4/settings/file-chooser" = {
      show-hidden = true;
    };

    "org/gtk/settings/file-chooser" = {
      show-hidden = false;
      sort-directories-first = true;
      sort-column = "name";
      sort-order = "ascending";
    };

    # ── GNOME Terminal ────────────────────────────────────────────────────────
    "org/gnome/terminal/legacy" = {
      theme-variant = "dark";
    };

    # b1dcc9dd-… is the fixed UUID for the default GNOME Terminal profile.
    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      background-color = "rgb(23,20,33)";
      foreground-color = "rgb(208,207,204)";
      font = "RobotoMono Nerd Font 11";
      use-system-font = false;
      use-theme-colors = false;
      visible-name = "Default";
    };

    # ── Extension: astra-monitor ──────────────────────────────────────────────
    # The `profiles` blob and `storage-main` are omitted — they contain
    # machine-specific hardware identifiers.
    "org/gnome/shell/extensions/astra-monitor" = {
      experimental-features = "[]";
      monitors-order = "[\"processor\",\"gpu\",\"memory\",\"storage\",\"network\",\"sensors\"]";

      processor-header-show = true;
      processor-header-percentage = true;
      processor-header-graph = true;
      processor-indicators-order = "[\"icon\",\"bar\",\"graph\",\"percentage\",\"frequency\"]";

      memory-header-show = true;
      memory-header-percentage = true;
      memory-header-graph = true;
      memory-indicators-order = "[\"icon\",\"bar\",\"graph\",\"percentage\",\"value\",\"free\"]";

      network-header-show = true;
      network-header-io = true;
      network-header-graph = false;
      network-header-io-unit = "kB/s";
      network-indicators-order = "[\"icon\",\"IO bar\",\"IO graph\",\"IO speed\"]";

      gpu-header-show = false;
      gpu-header-activity-percentage = true;
      gpu-indicators-order = "[\"icon\",\"activity bar\",\"activity graph\",\"activity percentage\",\"memory bar\",\"memory graph\",\"memory percentage\",\"memory value\"]";

      storage-header-show = false;
      storage-indicators-order = "[\"icon\",\"bar\",\"percentage\",\"value\",\"free\",\"IO bar\",\"IO graph\",\"IO speed\"]";

      sensors-header-show = true;
      sensors-header-tooltip = false;
      sensors-indicators-order = "[\"icon\",\"value\"]";

      headers-height = 0;
      headers-height-override = 0;
    };

    # ── Extension: dash-to-dock ───────────────────────────────────────────────
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

    # ── Extension: media-controls ─────────────────────────────────────────────
    "org/gnome/shell/extensions/mediacontrols" = {
      element-order = [
        "icon"
        "title"
        "controls"
        "menu"
      ];
      extension-position = "right";
      max-widget-width = 350;
      show-control-icons-play-pause = true;
      show-control-icons-seek-backward = true;
      show-control-icons-seek-forward = true;
    };

  };
}
