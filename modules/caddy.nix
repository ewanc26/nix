##############################################################################
#  Caddy reverse proxy module — Generic HTTP reverse proxy configuration.
#
#  This module provides a minimal Caddy configuration for reverse proxying
#  HTTP services. Designed to work with Cloudflare Tunnel (or other external
#  TLS terminators), so automatic HTTPS is disabled.
#
#  Usage:
#    Import this module and configure services.caddy.virtualHosts as needed.
#    For PDS, the configuration is handled by modules/pds.nix.
##############################################################################
{ config, lib, pkgs, ... }:

{
  # ── Caddy service ─────────────────────────────────────────────────────────────
  services.caddy = {
    enable = true;
    
    # Global config: disable automatic HTTPS since external service (like 
    # Cloudflare) handles TLS. Caddy only receives plain HTTP from tunnel.
    globalConfig = ''
      auto_https off
    '';
  };

  # Keep Caddy service running even if it crashes.
  systemd.services.caddy = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
