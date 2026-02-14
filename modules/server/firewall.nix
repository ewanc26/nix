{ lib, ... }:

let
  cfg = import ../../settings/config.nix;
in
{
  networking.firewall = {
    enable           = lib.mkDefault cfg.server.firewall.enable;
    allowedTCPPorts  = cfg.server.firewall.allowedTCPPorts;
    allowedUDPPorts  = cfg.server.firewall.allowedUDPPorts;
  };
}
