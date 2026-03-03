##############################################################################
#  Vaultwarden — NixOS module.
#
#  Architecture:
#    Vaultwarden (127.0.0.1:cfg.vaultwarden.port)
#      ↑ reverse proxy
#    Caddy (https://vault.ewancroft.uk — tailnet only)
#
#  Access:
#    Tailnet only — never exposed via Cloudflare Tunnel. A password manager
#    has no business being reachable from the public internet.
#
#  Storage:
#    SQLite database and attachments live at /srv/vaultwarden (on the /srv
#    volume). Daily SQLite backups go to /srv/vaultwarden/backup via a
#    custom systemd timer (the built-in backupDir option is not used because
#    it hardcodes /var/lib/vaultwarden as source and ignores DATA_FOLDER).
#
#  Secrets (sops-encrypted, age backend):
#    secrets/vaultwarden.env — KEY=value env file, must contain:
#      ADMIN_TOKEN   # argon2 hash — generate with:
#                    #   nix run nixpkgs#vaultwarden -- hash --preset owasp
#      SMTP_PASSWORD # Resend API key
##############################################################################
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;
  vw = cfg.vaultwarden;
  vwPort = toString vw.port;
  dataDir = "/srv/vaultwarden";
  backupDir = "/srv/vaultwarden/backup";
in
lib.mkIf cfg.services.vaultwarden.enable {

  # ── Storage ───────────────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d ${dataDir}        0700 vaultwarden vaultwarden -"
    "d ${backupDir}      0700 vaultwarden vaultwarden -"
  ];

  # ── Secrets ───────────────────────────────────────────────────────────────
  sops.secrets."vaultwarden.env" = {
    sopsFile = ../../secrets/vaultwarden.env;
    format = "dotenv";
    owner = "vaultwarden";
    group = "vaultwarden";
    mode = "0400";
  };

  # ── Vaultwarden service ───────────────────────────────────────────────────
  services.vaultwarden = {
    enable = true;

    # Sops-managed env file holds ADMIN_TOKEN and SMTP_PASSWORD.
    environmentFile = config.sops.secrets."vaultwarden.env".path;

    # backupDir is intentionally omitted: the built-in backup script
    # hardcodes /var/lib/vaultwarden as source and ignores DATA_FOLDER.
    # Our own timer below handles backups correctly.

    config = {
      DOMAIN = "https://${vw.hostname}";

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = vw.port;
      ROCKET_LOG = "critical";

      DATA_FOLDER = dataDir;

      SIGNUPS_ALLOWED = false;

      SMTP_HOST = "smtp.resend.com";
      SMTP_PORT = 465;
      SMTP_SECURITY = "force_tls";
      SMTP_USERNAME = "resend";
      SMTP_FROM = vw.smtpFrom;
      SMTP_FROM_NAME = vw.smtpFromName;

      SHOW_PASSWORD_HINT = false;

      LOG_LEVEL = "warn";
      EXTENDED_LOGGING = true;
    };
  };

  # ── Systemd service tweaks ────────────────────────────────────────────────
  systemd.services.vaultwarden = {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
      # The NixOS module applies ReadOnlyPaths hardening — explicitly allow
      # writes to /srv/vaultwarden so the RSA key and DB can be created.
      ReadWritePaths = [ dataDir ];
    };
    unitConfig = {
      StartLimitIntervalSec = cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst = cfg.server.servicePolicy.startLimitBurst;
    };
  };

  # ── Backup (custom — replaces broken built-in) ────────────────────────────
  # sqlite3 .backup produces a consistent online snapshot of the live DB.
  systemd.services.vaultwarden-backup = {
    description = "Vaultwarden SQLite backup";
    after = [ "vaultwarden.service" ];
    requires = [ "vaultwarden.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "vaultwarden";
      ExecStart = "${pkgs.writeShellScript "vaultwarden-backup" ''
        set -euo pipefail
        stamp=$(date +%Y%m%d-%H%M%S)
        dest="${backupDir}/db-$stamp.sqlite3"
        ${pkgs.sqlite}/bin/sqlite3 "${dataDir}/db.sqlite3" ".backup '$dest'"
        # Keep only the 14 most recent backups
        ls -t ${backupDir}/db-*.sqlite3 | tail -n +15 | xargs -r rm --
      ''}";
    };
  };

  systemd.timers.vaultwarden-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # ── Caddy reverse proxy ───────────────────────────────────────────────────
  services.caddy.virtualHosts."http://${vw.hostname}" = {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      redir https://${vw.hostname}{uri} permanent
    '';
  };

  services.caddy.virtualHosts."https://${vw.hostname}" = {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      tls ${cfg.server.acmeCertDir}/fullchain.pem ${cfg.server.acmeCertDir}/key.pem
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${vwPort} {
        header_up X-Real-IP {remote_host}
      }
    '';
  };
}
