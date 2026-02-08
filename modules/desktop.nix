{ config, pkgs, ... }:

{
  # X11 windowing system
  services.xserver = {
    enable = true;
    
    # Video drivers
    videoDrivers = [ "modesetting" ];
    
    # Desktop environment - using GNOME as default
    # You can change this to your preferred DE/WM
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    
    # Keyboard layout
    xkb = {
      layout = "gb";
      variant = "";
    };
  };

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
