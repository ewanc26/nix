{ config, pkgs, ... }:

{
  # Enable CUPS for printing
  services.printing.enable = true;

  # Enable Avahi for network discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable SSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Enable locate database
  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };

  # Enable GVfs for virtual file systems
  services.gvfs.enable = true;

  # Enable GNOME Keyring
  services.gnome.gnome-keyring.enable = true;

  # Enable D-Bus
  services.dbus.enable = true;

  # Enable udisks2 for disk management
  services.udisks2.enable = true;

  # Enable Tailscale VPN
  services.tailscale.enable = true;
}
