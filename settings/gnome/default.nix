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
      clock-show-weekday = false;     # macOS doesn't show weekday in menu bar
      clock-show-seconds = false;      # Keep time minimal like macOS
      enable-hot-corners = false;
      show-battery-percentage = true;
    };

    # ── Window manager ────────────────────────────────────────────────────────
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "close,minimize,maximize:";  # Mac-style: buttons on left
      num-workspaces = 4;
    };

    # ── Night light ───────────────────────────────────────────────────────────
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = false;
    };

    # ── Shell — taskbar favourites ────────────────────────────────────────────
    # enabled-extensions and disable-user-extensions are set by gnome.nix.
    # Order matches macOS dock (only apps available on both systems)
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"     # Files (Finder equivalent)
        "signal-desktop.desktop"          # Signal
        "org.gnome.Calendar.desktop"     # Calendar
        "obsidian.desktop"               # Obsidian
        "spotify.desktop"                # Spotify
        "steam.desktop"                  # Steam
        "discord.desktop"                # Discord
        "firefox.desktop"                # Firefox
        "code.desktop"                   # VS Code
        "org.gnome.Console.desktop"      # Console (Terminal equivalent)
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
      primary-color = "#1e1e2e";   # Catppuccin Mocha Base
      secondary-color = "#11111b"; # Catppuccin Mocha Crust
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
    # Catppuccin Mocha colour values:
    #   Base    #1e1e2e  → rgb(30,30,46)
    #   Text    #cdd6f4  → rgb(205,214,244)
    #   Green   #a6e3a1  → rgb(166,227,161)
    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      background-color = "rgb(30,30,46)";
      foreground-color = "rgb(205,214,244)";
      font = "FiraCode Nerd Font Mono 11";
      use-system-font = false;
      use-theme-colors = false;
      visible-name = "Catppuccin Mocha";
      bold-color = "rgb(205,214,244)";
      bold-color-same-as-fg = true;
      cursor-background-color = "rgb(166,227,161)";
      cursor-foreground-color = "rgb(30,30,46)";
      cursor-colors-set = true;
    };

    # ── Extension: astra-monitor ──────────────────────────────────────────────
    # The `profiles` blob and `storage-main` are omitted — they contain
    # machine-specific hardware identifiers.
    "org/gnome/shell/extensions/astra-monitor" = {
      experimental-features = "[]";
      monitors-order = "[\"processor\",\"memory\",\"network\",\"sensors\"]";

      # CPU: compact — graph + percentage only
      processor-header-show = true;
      processor-header-percentage = true;
      processor-header-graph = true;
      processor-header-bars = false;
      processor-indicators-order = "[\"icon\",\"graph\",\"percentage\"]";

      # RAM: compact — graph + percentage only
      memory-header-show = true;
      memory-header-percentage = true;
      memory-header-graph = true;
      memory-header-bars = false;
      memory-indicators-order = "[\"icon\",\"graph\",\"percentage\"]";

      # Network: IO speed only, no graph (keeps bar uncluttered)
      network-header-show = true;
      network-header-io = true;
      network-header-graph = false;
      network-header-bars = false;
      network-header-io-unit = "kB/s";
      network-indicators-order = "[\"icon\",\"IO speed\"]";

      # GPU: hidden (enable manually if needed)
      gpu-header-show = false;

      # Storage: hidden
      storage-header-show = false;

      # Sensors: temperature value only
      sensors-header-show = true;
      sensors-header-tooltip = false;
      sensors-indicators-order = "[\"icon\",\"value\"]";

      headers-height = 0;
      headers-height-override = 0;
    };

    # ── Extension: dash-to-dock ───────────────────────────────────────────────
    "org/gnome/shell/extensions/dash-to-dock" = {
      animation-time = 0.2;                 # Smooth animations like macOS
      autohide = true;
      autohide-in-fullscreen = true;
      intellihide = true;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      click-action = "minimize-or-previews";
      dash-max-icon-size = 48;              # Larger icons like macOS
      dock-fixed = false;
      dock-position = "BOTTOM";
      extend-height = false;
      hide-delay = 0.2;                     # Slight delay like macOS
      icon-size-fixed = false;              # Allow dynamic sizing
      scroll-action = "cycle-windows";
      show-delay = 0.2;                     # Slight delay like macOS
      show-favorites = true;
      show-mounts = false;
      show-running = true;
      show-show-apps-button = true;
      show-trash = false;
      transparency-mode = "DYNAMIC";
      background-opacity = 0.7;             # More transparent like macOS
      custom-background-color = false;
    };

    # ── Extension: blur-my-shell ──────────────────────────────────────────────
    "org/gnome/shell/extensions/blur-my-shell" = {
      brightness = 0.75;
      noise-amount = 0;
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = true;
      brightness = 0.7;        # Slightly brighter (more transparent like macOS)
      sigma = 15;              # Less blur for sharper look like macOS
      static-blur = true;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.6;
      sigma = 20;
      static-blur = true;
    };

    # ── Extension: just-perfection ────────────────────────────────────────────
    "org/gnome/shell/extensions/just-perfection" = {
      # Hide clutter, keep it minimal (Mac-like)
      activities-button = false;   # hide Activities button (use Super key instead)
      app-menu = false;            # hide app name in top bar
      news = false;                # disable welcome tour
      startup-status = 0;          # skip startup animation
      workspace-switcher-should-show = false;
      window-demands-attention-focus = true;
      panel-in-overview = true;
      
      # Panel appearance (Mac-like)
      panel-size = 32;             # Smaller panel (default 40, macOS is ~28-32)
      panel-corner-size = 8;       # Rounded corners like macOS
      panel-notification-icon = false;  # Hide notification icon for cleaner look
      
      # Clock position
      clock-menu-position = 2;     # Right side like macOS (0=left, 1=center, 2=right)
      clock-menu-position-offset = 0;
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
