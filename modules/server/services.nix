{ lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  # Tailscale VPN for inter-host communication
  services.tailscale.enable = true;

  # SSH daemon (server hardened configuration from modules/server/ssh.nix)
  # No additional SSH config needed here - it's handled by server-hardened profile
}
