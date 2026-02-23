##############################################################################
#  nix-topology — global infrastructure topology definition.
#
#  This file defines the physical connections, networks, and external devices
#  that can't be inferred automatically from the NixOS configurations.
#
#  Render:
#    nix build .#topology.x86_64-linux.config.output
#    # SVGs are in ./result/
#
#  Docs: https://oddlama.github.io/nix-topology
##############################################################################
{ config, ... }:
let
  inherit (config.lib.topology) mkInternet mkRouter mkConnection;
in
{
  # ── External devices ───────────────────────────────────────────────────────
  nodes.internet = mkInternet {
    connections = mkConnection "router" "wan";
  };

  nodes.router = mkRouter "Router" {
    interfaces.wan = { };
    interfaces.lan = {
      network = "home";
      physicalConnections = [
        (mkConnection "server" "eth0")
        (mkConnection "laptop" "wlan0")
      ];
    };
  };

  # ── Networks ───────────────────────────────────────────────────────────────
  networks.home = {
    name = "Home Network";
    cidrv4 = "192.168.1.0/24";
  };

  networks.tailscale = {
    name = "Tailnet";
    cidrv4 = "100.64.0.0/10";
  };

  # ── Host network assignments ───────────────────────────────────────────────
  nodes.server.interfaces.eth0.network = "home";
  nodes.server.interfaces.tailscale0 = {
    network = "tailscale";
    type = "wireguard";
    virtual = true;
  };

  nodes.laptop.interfaces.wlan0 = {
    network = "home";
    type = "wireless";
  };
  nodes.laptop.interfaces.tailscale0 = {
    network = "tailscale";
    type = "wireguard";
    virtual = true;
  };
}
