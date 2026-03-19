##############################################################################
#  Sharkey ActivityPub / microblogging server — NixOS module.
#
#  Architecture:
#    Sharkey (127.0.0.1:cfg.sharkey.port)
#      ↑ reverse proxy
#    Caddy (http://ap.ewancroft.uk:cfg.sharkey.caddyPort — internal only)
#      ↑ Cloudflare tunnel (outbound only, no firewall ports needed)
#
#  Account identity:
#    settings.url  = "https://ap.ewancroft.uk/"  (Sharkey's public host)
#    WebFinger redirect at ewancroft.uk (Vercel) still points to
#    ap.ewancroft.uk, so handles resolve as @ewan@ewancroft.uk unchanged.
#
#  PostgreSQL + Redis:
#    services.sharkey.setupPostgresql and setupRedis both default to true in
#    nixpkgs, so local instances are provisioned and wired automatically.
#
#  Secrets (secrets/sharkey.env — sops dotenv):
#    MK_CONFIG_DB_PASS=...       PostgreSQL password for the sharkey user
#    MK_CONFIG_SMTP_PASS=...     Resend API key
#
#  First-run:
#    Open https://ap.ewancroft.uk — Sharkey prompts for initial setup.
#    Then run the migration script to inject the old GTS RSA keypair.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  sk = cfg.sharkey;
  skPort = toString sk.port;
  caddyPort = toString sk.caddyPort;
in
lib.mkIf cfg.services.sharkey.enable {

  sops.secrets."sharkey.env" = {
    sopsFile = ../../secrets/sharkey.env;
    format = "dotenv";
    owner = "sharkey";
    group = "sharkey";
    mode = "0400";
  };

  services.sharkey = {
    enable = true;
    environmentFiles = [ config.sops.secrets."sharkey.env".path ];

    # Automatically provision a local PostgreSQL database and Redis instance.
    # Both default to true in nixpkgs — kept explicit here for clarity.
    setupPostgresql = true;
    setupRedis = true;
    openFirewall = false;

    settings = {
      # Public-facing URL — do NOT change after initial setup.
      url = "https://${sk.hostname}/";

      port = sk.port;
      address = "127.0.0.1";

      # Media storage on /srv — survives rebuilds, same disk as other services.
      mediaDirectory = sk.mediaDir;

      # SMTP via Resend — for password resets / notifications.
      # Password injected via MK_CONFIG_SMTP_PASS in the env file.
      smtp = {
        host = "smtp.resend.com";
        port = 587;
        secure = false; # STARTTLS
        user = "resend";
        from = "sharkey@server.ewancroft.uk";
      };
    };
  };

  # ── Keep media on /srv (same physical disk as all other service data) ──────
  systemd.services.sharkey = {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
    serviceConfig = {
      ReadWritePaths = [ sk.mediaDir ];
      Restart = lib.mkForce "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
    };

  };

  # ── Caddy vhost — same pattern as every other CF-tunnel service ───────────
  services.caddy.virtualHosts."http://${sk.hostname}:${caddyPort}" = {
    extraConfig = ''
      handle {
        reverse_proxy http://127.0.0.1:${skPort} {
          # Cloudflare tunnel passes CF-Connecting-IP with the real client IP.
          header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
          header_up X-Real-IP      {http.request.header.CF-Connecting-IP}
        }
      }
    '';
  };
}
