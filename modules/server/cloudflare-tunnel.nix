##############################################################################
#  Cloudflare Tunnel module — Shared tunnel for all services.
#
#  Architecture:
#    All services (PDS, Forgejo, etc.) → Caddy (internal ports) → Single CF Tunnel
#
#  This module provides a single Cloudflare tunnel that routes traffic to
#  multiple internal services based on hostname. Individual service modules
#  (pds.nix, forgejo.nix, etc.) configure their Caddy reverse proxies, and
#  this module routes external traffic to them.
#
#  Cloudflare tunnel setup (one-time, outside Nix):
#    1. cloudflared tunnel login
#    2. cloudflared tunnel create server
#    3. Encrypt the resulting ~/.cloudflared/<UUID>.json with sops:
#         sops --encrypt --age <age-pubkey> cf-tunnel.json > secrets/cf-tunnel.json
#    4. Set myConfig.cloudflare.tunnelId to that UUID (modules/options.nix default
#       or a per-host override).
#    5. Add CNAME records in Cloudflare DNS for each service:
#         pds.ewancroft.uk  → <UUID>.cfargotunnel.com
#         git.ewancroft.uk  → <UUID>.cfargotunnel.com
##############################################################################
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;

  # Build ingress routes based on enabled services.
  # Only route publicly-accessible services through the CF tunnel.
  # Nextcloud, Immich, and Jellyfin are tailnet-only — they are reachable
  # via split DNS (CoreDNS) directly over the Tailscale network.
  ingressRoutes =
    lib.optionalAttrs cfg.services.pds.enable (
      {
        ${cfg.pds.hostname} = "http://127.0.0.1:${toString cfg.pds.caddyPort}";
        "*.${cfg.pds.hostname}" = "http://127.0.0.1:${toString cfg.pds.caddyPort}";
      }
      // lib.listToAttrs (
        lib.concatMap
          (
            domain:
            let
              bare = lib.removePrefix "." domain;
            in
            [
              {
                name = bare;
                value = "http://127.0.0.1:${toString cfg.pds.caddyPort}";
              }
              {
                name = "*.${bare}";
                value = "http://127.0.0.1:${toString cfg.pds.caddyPort}";
              }
            ]
          )
          (lib.filter (d: d != ".${cfg.pds.hostname}" && d != cfg.pds.hostname) cfg.pds.serviceHandleDomains)
      )
    )
    // lib.optionalAttrs cfg.services.forgejo.enable {
      ${cfg.forgejo.hostname} = "http://127.0.0.1:${toString cfg.forgejo.caddyPort}";
    }
    // lib.optionalAttrs cfg.services.gotosocial.enable {
      ${cfg.gotosocial.hostname} = "http://127.0.0.1:${toString cfg.gotosocial.caddyPort}";
    };
in
lib.mkIf cfg.services.cloudflare.enable {

  # ── User / group ────────────────────────────────────────────────────────────
  # The cloudflared nixpkgs service uses DynamicUser at the systemd level and
  # does not create a static entry in config.users.users.  We declare it here
  # so that sops-nix can resolve the owner/group at evaluation time and so
  # that the credentials file has a stable owner on disk.
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = { };

  # ── Secret ──────────────────────────────────────────────────────────────────
  # JSON credentials file created by `cloudflared tunnel create server`.
  # Encrypt with: sops --encrypt --age <age-pubkey> cf-tunnel.json > secrets/cf-tunnel.json
  sops.secrets."cf-tunnel.json" = {
    sopsFile = ../../secrets/cf-tunnel.json;
    format = "binary";
    owner = "cloudflared";
    group = "cloudflared";
    # set explicitly — cloudflared uses DynamicUser so the
    # user isn't in config.users.users without the block above
    mode = "0400";
  };

  sops.secrets."cloudflare.token" = {
    sopsFile = ../../secrets/cloudflare.token;
    format = "binary";
    owner = "root";
  };

  # ── Cloudflare tunnel ──────────────────────────────────────────────────────
  # cloudflared dials outbound to Cloudflare's edge — zero inbound ports needed.
  # Single tunnel serves all configured services via hostname-based routing.
  systemd.services."cloudflared-tunnel-${cfg.cloudflare.tunnelId}" = {
    after = [
      "network-online.target"
      "nss-lookup.target"
    ];
    wants = [
      "network-online.target"
      "nss-lookup.target"
    ];
    serviceConfig.ExecStartPre = [
      # Wait until DNS is actually responsive before starting the tunnel.
      # cloudflared fails fast at boot if DNS isn't ready yet.
      "+${pkgs.bash}/bin/bash -c 'until ${pkgs.dnsutils}/bin/dig +short _v2-origintunneld._tcp.argotunnel.com SRV &>/dev/null; do sleep 1; done'"
    ];
  };

  services.cloudflared = {
    enable = true;
    tunnels.${cfg.cloudflare.tunnelId} = {
      credentialsFile = config.sops.secrets."cf-tunnel.json".path;
      default = "http_status:404";
      ingress = ingressRoutes;
    };
  };

  # The Cloudflare tunnel is fully outbound — no firewall ports need to be opened.
}
