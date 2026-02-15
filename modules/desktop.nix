{ config, pkgs, lib, ... }:

let
  cfg = import ../settings/config.nix;
in
{
  # X11 windowing system
  services.xserver = {
    enable = true;

    videoDrivers = [ "modesetting" ];

    xkb.layout = "gb";
  };

  # Display manager – driven from settings/config/desktop.nix
  services.displayManager.gdm.enable    = cfg.desktop.displayManager == "gdm";
  services.desktopManager.gnome.enable  = cfg.desktop.environment    == "gnome";

  # Enable GTK4 in system environment
  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-tweaks
  ];

  # Exclude default GNOME apps – list driven from settings/config/desktop.nix
  environment.gnome.excludePackages =
    map (name: pkgs.${name}) cfg.desktop.gnome.excludePackages;
}
