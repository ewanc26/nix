{ config, pkgs, ... }:

{
  # X11 windowing system
  services.xserver = {
    enable = true;

    # Video drivers
    videoDrivers = [ "modesetting" ];

    # Keyboard layout
    xkb = {
      layout = "gb";
      variant = "";
    };
  };

  # Display manager / desktop environment (25.11+ correct)
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  
  # Enable GTK4 in system environment
  programs.dconf.enable = true;
  
  # Expose schemas for gtk4-desktop-icons extension
  services.xserver.desktopManager.gnome.extraGSettingsOverridePackages = with pkgs; [
    gnome.nautilus
  ];
  
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    
    # GTK4 Desktop Icons dependencies (required by gtk4-ding)
    gjs               # JavaScript bindings for GNOME
    gdk-pixbuf        # Image loading library
    imagemagick       # For converting jpg to png thumbnails
    poppler           # PDF thumbnails (includes glib bindings)
    libadwaita        # GTK4 theming support
    
    # GNOME Extensions (system-level for proper schema compilation)
    gnomeExtensions.gtk4-desktop-icons-ng-ding
  ];

  # Exclude some default GNOME apps to keep it minimal
  environment.gnome.excludePackages = with pkgs; [
    gnome-photos
    gnome-tour
    cheese
    gnome-music
    gedit
    epiphany
    geary
    gnome-characters
    totem
    tali
    iagno
    hitori
    atomix
  ];
}