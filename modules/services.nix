# Desktop system services (printing, avahi, SSH, locate, etc.).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig;
in
{
  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = cfg.server.sshd.permitRootLogin;
      PasswordAuthentication = true; # Desktop: allow password login.
    };
  };

  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };

  services.gvfs.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  services.dbus.enable = true;
  services.udisks2.enable = true;
  services.tailscale.enable = true;
}
