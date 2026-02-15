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
    libgtop  # required for astra-monitor to display in panel
  ];

  # Required for astra-monitor GObject introspection
  environment.variables.GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";

  # Exclude default GNOME apps – list driven from settings/config/desktop.nix
  environment.gnome.excludePackages =
    map (name: pkgs.${name}) cfg.desktop.gnome.excludePackages;
}
