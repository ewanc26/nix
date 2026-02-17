##############################################################################
#  Cloudflare Tunnel module — Shared tunnel for all services.
#
#  Architecture:
#    All services (PDS, Matrix, etc.) → Caddy (internal ports) → Single CF Tunnel
#
#  This module provides a single Cloudflare tunnel that routes traffic to
#  multiple internal services based on hostname. Individual service modules
#  (pds.nix, matrix.nix, etc.) configure their Caddy reverse proxies, and
#  this module routes external traffic to them.
#
#  Cloudflare tunnel setup (one-time, outside Nix):
#    1. cloudflared tunnel login
#    2. cloudflared tunnel create server
#    3. Encrypt the resulting ~/.cloudflared/<UUID>.json with ragenix:
#         nix run github:yaxitech/ragenix -- -e secrets/age/cf-tunnel.json.age
#    4. Set cfg.cloudflare.tunnelId to that UUID in settings/config/cloudflare.nix
#    5. Add CNAME records in Cloudflare DNS for each service:
#         pds.ewancroft.uk → <UUID>.cfargotunnel.com
#         matrix.ewancroft.uk → <UUID>.cfargotunnel.com
#         git.ewancroft.uk → <UUID>.cfargotunnel.com
##############################################################################
{ config, lib, self, cfgLib, ... }:

let
  cfg = cfgLib.cfg.cloudflare;
  pdsCfg = cfgLib.cfg.pds;
  matrixCfg = cfgLib.cfg.matrix;
  forgejoCfg = cfgLib.cfg.forgejo;
  
  # Build ingress routes based on enabled services
  ingressRoutes = lib.mkMerge [
    # PDS routes (if enabled)
    (lib.mkIf pdsCfg.enable {
      ${pdsCfg.hostname} = "http://127.0.0.1:${toString pdsCfg.caddyPort}";
      "*.${pdsCfg.hostname}" = "http://127.0.0.1:${toString pdsCfg.caddyPort}";
    })
    
    # Matrix routes (if enabled)
    (lib.mkIf matrixCfg.enable {
      ${matrixCfg.hostname} = "http://127.0.0.1:${toString matrixCfg.caddyPort}";
    })

    # Forgejo routes (if enabled)
    (lib.mkIf forgejoCfg.enable {
      ${forgejoCfg.hostname} = "http://127.0.0.1:${toString forgejoCfg.caddyPort}";
    })
  ];
in
lib.mkIf cfg.enable {

  # ── Secrets ──────────────────────────────────────────────────────────────────
  # JSON credentials file created by `cloudflared tunnel create server`.
  # Encrypted with: nix run github:yaxitech/ragenix -- -e secrets/age/cf-tunnel.json.age
  age.secrets."cf-tunnel.json" = {
    file  = self + /secrets/age/cf-tunnel.json.age;
    owner = "cloudflared";
    mode  = "0400";
  };

  # ── Cloudflare tunnel ─────────────────────────────────────────────────────────
  # cloudflared dials outbound to Cloudflare's edge — zero inbound ports needed.
  # Single tunnel serves all configured services via hostname-based routing.
  services.cloudflared = {
    enable = true;
    tunnels.${cfg.tunnelId} = {
      credentialsFile = config.age.secrets."cf-tunnel.json".path;
      default = "http_status:404";
      ingress = ingressRoutes;
    };
  };

  # ── Firewall ──────────────────────────────────────────────────────────────────
  # The Cloudflare tunnel is fully outbound — no ports need to be open.
}
