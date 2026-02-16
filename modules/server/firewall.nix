{ lib, settings, ... }:

let
  cfg = settings;
in
{
  networking.firewall = {
    enable           = lib.mkDefault cfg.server.firewall.enable;
    allowedTCPPorts  = cfg.server.firewall.allowedTCPPorts;
    allowedUDPPorts  = cfg.server.firewall.allowedUDPPorts;
  };
}
