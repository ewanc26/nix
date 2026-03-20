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
#  PostgreSQL + Redis + Meilisearch:
#    services.sharkey.setupPostgresql, setupRedis, and setupMeilisearch are all
#    enabled. setupMeilisearch starts a local Meilisearch instance on port 7700
#    and wires it into Sharkey's config automatically via the NixOS module.
#
#  Secrets (secrets/sharkey.env — sops dotenv):
#    MK_CONFIG_DB_PASS=...       PostgreSQL password for the sharkey user
#
#  SMTP is configured via Admin → Settings → Email in the Sharkey web UI,
#  NOT via the YAML config. There is no smtp key in the config schema.
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

  # Declare the sharkey user/group statically so sops-nix can resolve the
  # owner at activation time. The nixpkgs sharkey module creates this user
  # during service activation, which is too late for sops secret ownership.
  users.users.sharkey = {
    isSystemUser = true;
    group = "sharkey";
  };
  users.groups.sharkey = { };

  # Meilisearch master key — file must contain the raw key value only (no KEY= prefix).
  # Generate and encrypt:
  #   openssl rand -base64 32 > secrets/meilisearch-master-key
  #   SOPS_AGE_KEY_FILE=~/.config/age/keys.txt sops --encrypt --in-place --input-type binary --output-type binary secrets/meilisearch-master-key
  sops.secrets."meilisearch-master-key" = {
    sopsFile = ../../secrets/meilisearch-master-key;
    format = "binary";
    owner = "meilisearch";
    group = "meilisearch";
    mode = "0400";
  };

  # Declare meilisearch user/group statically so sops-nix can resolve the
  # owner at activation time (same pattern as sharkey above).
  users.users.meilisearch = {
    isSystemUser = true;
    group = "meilisearch";
  };
  users.groups.meilisearch = { };

  services.meilisearch = {
    masterKeyFile = config.sops.secrets."meilisearch-master-key".path;
    listenAddress = "127.0.0.1";
    settings = {
      env = "production";
      no_analytics = true;
    };
  };

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
    setupPostgresql = true;
    setupRedis = true;

    # Meilisearch full-text search — local instance managed by the NixOS module.
    # Starts services.meilisearch on localhost:7700 and wires the API key automatically.
    setupMeilisearch = true;

    openFirewall = false;

    settings = {
      # Public-facing URL — do NOT change after initial setup.
      url = "https://${sk.hostname}/";

      port = sk.port;
      address = "127.0.0.1";

      # ID generation algorithm — do NOT change after initial setup.
      # Changing this after data exists will corrupt existing record IDs.
      id = "aidx";

      # Full-text search via Meilisearch — local instance on localhost:7700.
      # setupMeilisearch = true above provisions the service and API key automatically.
      fulltextSearch.provider = "meilisearch";

      # Media storage on /srv — survives rebuilds, same disk as other services.
      mediaDirectory = sk.mediaDir;

      # NOTE: SMTP / email is NOT configured here.
      # Sharkey stores email server settings in the database, configured via
      # Admin → Settings → Email in the web UI. There is no smtp key in the
      # Sharkey YAML config schema.
    };
  };

  # ── Media directory on /srv ───────────────────────────────────────────────
  # Must exist before Sharkey starts — nixpkgs bind-mounts mediaDirectory into
  # the service namespace and fails with NAMESPACE (226) if the path is absent.
  systemd.tmpfiles.rules = [
    "d ${sk.mediaDir} 0750 sharkey sharkey -"
  ];

  # ── Systemd service tweaks ────────────────────────────────────────────────
  systemd.services.sharkey = {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
    serviceConfig = {
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
