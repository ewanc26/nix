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