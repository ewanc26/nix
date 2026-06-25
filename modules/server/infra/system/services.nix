# Server base services — Tailscale VPN and SSH daemon.
# Tailscale provides encrypted WireGuard tunnels between all hosts.
# SSH is configured by the hardened profile separately (modules/server/ssh.nix).
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
in
{
  # Tailscale VPN for inter-host communication
  services.tailscale.enable = true;

  # SSH daemon (server hardened configuration from modules/server/ssh.nix)
  # No additional SSH config needed here — it's handled by server-hardened profile.
}
