##############################################################################
#  Umami web analytics — NixOS module.
#
#  Architecture:
#    Umami (127.0.0.1:cfg.umami.port)
#      ↑ reverse proxy
#    Caddy (http://${hostname}:${caddyPort} — Cloudflare tunnel)
#
#  GDPR compliance:
#    Cookie-free by design. No consent banner required. Uses hashed IP +
#    User-Agent for daily unique visitor counting, then discards the hash.
#
#  Storage:
#    PostgreSQL database (local, peer auth via unix socket).
#
#  Secrets (sops-encrypted, age backend):
#    secrets/umami.env — KEY=value env file, must contain:
#      APP_SECRET  # Random string for session signing (openssl rand -base64 32)
##############################################################################
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;
  umami = cfg.umami;
  umamiPort = toString umami.port;
  caddyPort = toString umami.caddyPort;
  dataDir = umami.dataDir;
  isPublic = cfg.services.umami.public or true;
in
lib.mkIf cfg.services.umami.enable {

  # ── Storage ───────────────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 umami umami -"
  ];

  # ── User/Group ────────────────────────────────────────────────────────────
  users.users.umami = {
    isSystemUser = true;
    group = "umami";
    home = dataDir;
  };
  users.groups.umami = { };

  # ── Secrets ───────────────────────────────────────────────────────────────
  sops.secrets."umami.env" = {
    sopsFile = ../../../../secrets/umami.env;
    format = "dotenv";
    owner = "umami";
    group = "umami";
    mode = "0400";
  };

  # ── PostgreSQL database ───────────────────────────────────────────────────
  services.postgresql = {
    enable = lib.mkDefault true;
    ensureDatabases = [ "umami" ];
    ensureUsers = [
      {
        name = "umami";
        ensureDBOwnership = true;
      }
    ];
  };

  # ── Umami service (native) ────────────────────────────────────────────────
  systemd.services.umami = {
    description = "Umami Web Analytics";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "postgresql.service"
      "srv.mount"
    ];
    wants = [
      "postgresql.service"
      "srv.mount"
    ];
    requires = [ "postgresql.service" ];

    environment = {
      # PostgreSQL via unix socket (peer auth, no password needed)
      DATABASE_URL = "postgresql:///umami?host=/run/postgresql";
      HOSTNAME = "127.0.0.1";
      PORT = umamiPort;
      DISABLE_TELEMETRY = "1";
      REMOVE_TRAILING_SLASH = "1";
    };

    serviceConfig = {
      Type = "simple";
      User = "umami";
      Group = "umami";
      WorkingDirectory = dataDir;
      EnvironmentFile = config.sops.secrets."umami.env".path;
      ExecStart = "${lib.getExe pkgs.umami}";
      Restart = "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
    };

    unitConfig = {
      StartLimitIntervalSec = cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst = cfg.server.servicePolicy.startLimitBurst;
    };
  };

  # ── Caddy reverse proxy (Cloudflare tunnel — public) ───────────────────────
  services.caddy.virtualHosts."http://${umami.hostname}:${caddyPort}" = lib.mkIf isPublic {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${umamiPort} {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
      }
    '';
  };

  # ── Tailscale reverse proxy (private access) ──────────────────────────────
  services.caddy.virtualHosts."http://${umami.hostname}" = lib.mkIf (!isPublic) {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      redir https://${umami.hostname}{uri} permanent
    '';
  };

  services.caddy.virtualHosts."https://${umami.hostname}" = lib.mkIf (!isPublic) {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      tls ${cfg.server.acmeCertDir}/fullchain.pem ${cfg.server.acmeCertDir}/key.pem
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${umamiPort} {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
      }
    '';
  };
}
