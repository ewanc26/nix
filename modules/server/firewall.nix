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

    # Trust Tailscale interface for inter-host communication
    trustedInterfaces = [ "tailscale0" ];

    # Allow ICMP (ping) if configured
    allowPing = lib.mkDefault cfg.server.firewall.allowPing;
  };
}
