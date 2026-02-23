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
{ config, lib, ... }:
{
  # ── External devices ───────────────────────────────────────────────────────
  nodes.internet = {
    name = "Internet";
    icon = "services.cloudflare";
    interfaces.tunnel = {
      name = "CF Tunnel";
      network = "cloudflare";
    };
  };

  nodes.router = {
    name = "Router";
    deviceType = "router";
    interfaces.wan = {
      name = "WAN";
      network = "wan";
    };
    interfaces.lan = {
      name = "LAN";
      network = "home";
    };
  };

  # ── Networks ───────────────────────────────────────────────────────────────
  networks.home = {
    name = "Home Network";
    cidrv4 = "192.168.1.0/24";
  };

  networks.cloudflare = {
    name = "Cloudflare Tunnel";
    style.color = "#f48120";
  };

  networks.tailscale = {
    name = "Tailnet";
    cidrv4 = "100.64.0.0/10";
    style.color = "#4a9eed";
  };

  # ── Physical connections ───────────────────────────────────────────────────
  # Router LAN → each host's primary ethernet/wifi interface.
  nodes.router.interfaces.lan.physicalConnections = [
    {
      node = "server";
      interface = "eth0";
    }
    {
      node = "laptop";
      interface = "wlan0";
    }
  ];

  # ── Host network assignments ───────────────────────────────────────────────
  nodes.server.interfaces.eth0.network = "home";
  nodes.server.interfaces.tailscale0.network = "tailscale";

  nodes.laptop.interfaces.wlan0.network = "home";
  nodes.laptop.interfaces.tailscale0.network = "tailscale";

  # ── Cloudflare tunnel (logical, outbound-only from server) ─────────────────
  nodes.server.interfaces.cf-tunnel = {
    name = "CF Tunnel";
    network = "cloudflare";
    physicalConnections = [
      {
        node = "internet";
        interface = "tunnel";
      }
    ];
  };
}
