##############################################################################
#  Bluesky ATProto Personal Data Server — NixOS module.
#
#  Architecture:
#    PDS (127.0.0.1:cfg.port)
#      ↑ reverse proxy
#    Caddy (127.0.0.1:cfg.caddyPort — internal only, no TLS here)
#      ↑ Cloudflare tunnel (cloudflared — outbound only, no firewall ports needed)
#
#  Non-secret settings live in settings/config/pds.nix.
#  Secrets decrypted by ragenix at activation time.
#
#  Required secrets (set in secrets/age/pds.env.age as KEY=value pairs):
#    PDS_JWT_SECRET                         openssl rand --hex 16
#    PDS_ADMIN_PASSWORD                     openssl rand --hex 16
#    PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX
#      openssl ecparam --name secp256k1 --genkey --noout --outform DER \
#        | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32
#    PDS_EMAIL_SMTP_URL                     (optional — for email verification)
#    PDS_EMAIL_FROM_ADDRESS                 (optional — for email verification)
#
#  Cloudflare tunnel setup (one-time, outside Nix):
#    Handled by modules/cloudflare-tunnel.nix.
#    See that module for setup instructions.
##############################################################################
{ config, lib, pkgs, self, settings, ... }:

let
  cfg      = settings.pds;
  pdsPort  = toString cfg.port;
  pdsHost  = cfg.hostname;
  caddyPort = toString cfg.caddyPort;

  # UK Online Safety Act age-assurance static responses.
  # Required for UK-based PDS instances (Online Safety Act 2023).
  # Source: https://gist.github.com/mary-ext/6e27b24a83838202908808ad528b3318
  ageAssuranceBlocks = ''
    handle /xrpc/app.bsky.unspecced.getAgeAssuranceState {
      header Content-Type "application/json"
      header Access-Control-Allow-Headers "authorization,dpop,atproto-accept-labelers,atproto-proxy"
      header Access-Control-Allow-Origin "*"
      respond `{"lastInitiatedAt":"2025-07-14T14:22:43.912Z","status":"assured"}` 200
    }
    handle /xrpc/app.bsky.ageassurance.getConfig {
      header Content-Type "application/json"
      header Access-Control-Allow-Headers "authorization,dpop,atproto-accept-labelers,atproto-proxy"
      header Access-Control-Allow-Origin "*"
      respond `{"regions":[]}` 200
    }
    handle /xrpc/app.bsky.ageassurance.getState {
      header Content-Type "application/json"
      header Access-Control-Allow-Headers "authorization,dpop,atproto-accept-labelers,atproto-proxy"
      header Access-Control-Allow-Origin "*"
      respond `{"state":{"lastInitiatedAt":"2025-07-14T14:22:43.912Z","status":"assured","access":"full"},"metadata":{"accountCreatedAt":"2022-11-17T00:35:16.391Z"}}` 200
    }
  '';
in
lib.mkIf cfg.enable {

  # ── Secrets ──────────────────────────────────────────────────────────────────
  age.secrets."pds.env" = {
    file  = self + /secrets/age/pds.env.age;
    owner = "pds";
    group = "pds";
    mode  = "0400";
  };

  # ── PDS service ───────────────────────────────────────────────────────────────
  environment.systemPackages = [ pkgs.atproto-goat ];

  services.bluesky-pds = {
    enable           = true;
    environmentFiles = [ config.age.secrets."pds.env".path ];
    settings = {
      PDS_DATA_DIRECTORY = "/srv/bluesky-pds";
      PDS_PORT        = cfg.port;
      PDS_HOSTNAME    = cfg.hostname;
      PDS_ADMIN_EMAIL = cfg.adminEmail;
      PDS_SERVICE_HANDLE_DOMAINS =
        lib.concatStringsSep "," cfg.serviceHandleDomains;
      PDS_CRAWLERS =
        lib.concatStringsSep "," cfg.crawlers;
    };
  };

  systemd.services.bluesky-pds = {
    serviceConfig.Restart    = "always";
    serviceConfig.RestartSec = cfg.restartSec;
    unitConfig = {
      StartLimitIntervalSec = cfg.startLimitIntervalSec;
      StartLimitBurst       = cfg.startLimitBurst;
    };
  };

  # ── Caddy reverse proxy ───────────────────────────────────────────────────────
  # Listens on localhost:caddyPort only — never exposed publicly.
  # Cloudflare handles TLS; Caddy receives plain HTTP from the tunnel daemon.
  # Using http:// prefix disables Caddy's automatic HTTPS / ACME entirely.
  #
  # Note: Caddy service itself is enabled by modules/caddy.nix.
  services.caddy.virtualHosts."http://127.0.0.1:${caddyPort}" = {
    extraConfig = ''
      ${ageAssuranceBlocks}
      handle {
        reverse_proxy http://127.0.0.1:${pdsPort}
      }
    '';
  };

  # ── Firewall ──────────────────────────────────────────────────────────────────
  # Cloudflare tunnel is configured by modules/cloudflare-tunnel.nix.
  # SSH is handled by modules/server/firewall.nix and modules/server/ssh.nix.
}
