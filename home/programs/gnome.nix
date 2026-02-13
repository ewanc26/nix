{ config, pkgs, lib, ... }:

{
  # Import all GNOME settings from encrypted dconf settings
  # This will load all dconf settings from settings/gnome/default.nix
  imports = [
    ../../settings/gnome
  ];

  # Install GNOME extensions
  home.packages = with pkgs.gnomeExtensions; [
    astra-monitor
    media-controls
    dash-to-dock
  ];

  # GNOME wallpaper and extension configuration
  dconf.settings = {
    # Wallpaper
    "org/gnome/desktop/background" = {
      picture-uri = "file://${../../wallpapers/wallpaper.jpg}";
      picture-uri-dark = "file://${../../wallpapers/wallpaper.jpg}";
      picture-options = "zoom";
    };

    # Enable extensions
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        # New extensions
        "astra-monitor@astraext.github.io"                    # Astra Monitor
        "mediacontrols@cliffniff.github.com"                  # Media Controls
        "dash-to-dock@micxgx.gmail.com"                       # Dash to Dock
        
        # Your existing extensions
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "extension-list@tu.berry"
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "add-to-desktop@tommimon.github.com"
        "fq@megh"
      ];
    };

    # Dash to Dock configuration (macOS-like settings)
    "org/gnome/shell/extensions/dash-to-dock" = {
      # Position
      dock-position = "BOTTOM";                # Bottom like macOS
      extend-height = false;                   # Don't extend to full height
      
      # Size and appearance
      dash-max-icon-size = 48;                # Icon size
      icon-size-fixed = false;                # Allow dynamic sizing
      transparency-mode = "DYNAMIC";          # Dynamic transparency
      
      # Behavior
      autohide = false;                       # Always visible like macOS
      intellihide = false;                    # Don't auto-hide
      dock-fixed = true;                      # Fixed position
      
      # Click behavior
      click-action = "minimize-or-previews";  # Click to minimize or show previews
      scroll-action = "cycle-windows";        # Scroll to cycle windows
      
      # Show options
      show-favorites = true;                  # Show favorite apps
      show-running = true;                    # Show running apps
      show-show-apps-button = true;          # Show applications button
      show-trash = true;                      # Show trash icon
      show-mounts = true;                     # Show mounted drives
      
      # Animation
      animation-time = 0.2;                   # Smooth animations
      hide-delay = 0.2;
      show-delay = 0.25;
    };

    # Media Controls configuration
    "org/gnome/shell/extensions/mediacontrols" = {
      extension-position = "right";           # Position in top bar
      element-order = [ "icon" "title" "controls" "menu" ];
      show-control-icons-play-pause = true;
      show-control-icons-seek-backward = true;
      show-control-icons-seek-forward = true;
      max-widget-width = 350;
    };

    # Astra Monitor configuration (comprehensive monitoring)
    "org/gnome/shell/extensions/astra-monitor" = {
      # Processor monitoring
      processor-header-show = true;
      processor-header-graph = true;
      processor-header-percentage = true;
      
      # Memory monitoring
      memory-header-show = true;
      memory-header-graph = true;
      memory-header-percentage = true;
      
      # Storage monitoring
      storage-header-show = false;            # Disable to reduce clutter (enable if needed)
      
      # Network monitoring  
      network-header-show = true;
      network-header-graph = false;
      network-header-io = true;
      network-header-io-unit = "kB/s";
      
      # GPU monitoring (if you have a dedicated GPU)
      gpu-header-show = true;
      gpu-header-activity-percentage = true;
      
      # Sensors (temperature)
      sensors-header-show = true;
    };
  };
}
