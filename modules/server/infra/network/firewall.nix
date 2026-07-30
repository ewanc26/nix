# Server firewall — locked down by default, Tailscale interface exempted.
# SSH port is always open (even if allowedTCPPorts is overridden).
# Tailscale interface gets HTTPS (443) and DNS (53) for tailnet services.
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
in
{
  networking.firewall = {
    enable = lib.mkDefault cfg.server.firewall.enable;
    # Always include the SSH port — even if someone overrides allowedTCPPorts.
    allowedTCPPorts = lib.unique (cfg.server.firewall.allowedTCPPorts ++ [ cfg.server.sshd.port ]);
    allowedUDPPorts = cfg.server.firewall.allowedUDPPorts;

    # Allow ICMP (ping) if configured
    allowPing = lib.mkDefault cfg.server.firewall.allowPing;

    # Tailscale interface — allow HTTPS (443) and DNS (53) from tailnet devices.
    # These ports are NOT opened globally; they're only reachable via the tailnet.
    interfaces.tailscale0 = {
      allowedTCPPorts = [
        53
        80
        443
      ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
