{ ... }:
{
  imports = [
    ./server-base.nix
    ../modules/server/ssh.nix
    ../modules/server/intrusion.nix
    ../modules/server/firewall.nix
  ];

  # Headless — no display manager, no getty on tty1.
  # All interaction is via SSH, with tty2 as emergency fallback.
  services.getty.autologinUser = null;
  systemd.services."getty@tty1".enable = false;

  # Don't block boot waiting for network
  systemd.services.NetworkManager-wait-online.enable = false;
}
