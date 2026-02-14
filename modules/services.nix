{ config, pkgs, lib, ... }:

let
  cfg = import ../settings/config.nix;
in
{
  # Desktop system services

  # Printing (CUPS)
  services.printing.enable = true;

  # Avahi – local network discovery
  services.avahi = {
    enable       = true;
    nssmdns4     = true;
    openFirewall = true;
  };

  # SSH daemon (desktop – password auth enabled for convenience)
  services.openssh = {
    enable  = true;
    settings = {
      PermitRootLogin         = cfg.server.sshd.permitRootLogin;
      PasswordAuthentication  = true;  # Desktop: allow password login
    };
  };

  # Locate database
  services.locate = {
    enable  = true;
    package = pkgs.plocate;
  };

  # Virtual file systems (GVfs)
  services.gvfs.enable = true;

  # GNOME Keyring
  services.gnome.gnome-keyring.enable = true;

  # D-Bus
  services.dbus.enable = true;

  # Disk management
  services.udisks2.enable = true;

  # Tailscale VPN
  services.tailscale.enable = true;
}
