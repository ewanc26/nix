# Server hardened profile — extends server-base with SSH, intrusion detection,
# firewall, and headless optimisations. Disables getty and boots faster by
# not waiting for network-online. All interaction is via SSH only.
{ ... }:
{
  imports = [
    ./server-base.nix
    ../server/infra/security/ssh.nix
    ../server/infra/security/intrusion.nix
    ../server/infra/network/firewall.nix
  ];

  # Headless — no display manager, no getty on tty1.
  # All interaction is via SSH, with tty2 as emergency fallback.
  services.getty.autologinUser = null;
  systemd.services."getty@tty1".enable = false;

  # Don't block boot waiting for network
  systemd.services.NetworkManager-wait-online.enable = false;
}
