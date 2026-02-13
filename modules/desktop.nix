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
  
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    
    # Note: Desktop icons extensions (gtk4-ding, desktop-icons-ng) are broken on NixOS
    # due to GSettings schema issues. Install manually from extensions.gnome.org instead
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