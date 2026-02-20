{ ... }:
{
  imports = [
    ./server-base.nix
    ../modules/server/ssh.nix
    ../modules/server/intrusion.nix
    ../modules/server/firewall.nix
  ];

  # Headless — no display manager, no getty on tty1.
  # All interaction is via SSH.
  services.getty.autologinUser = null;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;
}
