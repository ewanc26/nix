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
#    volume). Automatic daily backups go to /srv/vaultwarden/backup.
#
#  Secrets (sops-encrypted, age backend):
#    secrets/vaultwarden.env — KEY=value env file, must contain:
#      ADMIN_TOKEN   # argon2 hash — generate with:
#                    #   vaultwarden hash --preset owasp
#                    # or a plain token (less secure):
#                    #   openssl rand -base64 48
#      SMTP_PASSWORD # Resend API key
#
#    Encrypt: sops --encrypt --age <host-age-pubkey> secrets/vaultwarden.env
#    (Use .sops.yaml at the repo root to configure recipients automatically.)
#
#  First-run:
#    1. Navigate to https://vault.ewancroft.uk/admin and enter your ADMIN_TOKEN.
#    2. Disable signups after creating your account (already set below).
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  vw = cfg.vaultwarden;
  vwPort = toString vw.port;
in
lib.mkIf cfg.services.vaultwarden.enable {

  # ── Storage ───────────────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /srv/vaultwarden        0700 vaultwarden vaultwarden -"
    "d /srv/vaultwarden/backup 0700 vaultwarden vaultwarden -"
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

    # Built-in backup — runs daily, keeps SQLite snapshots in backupDir.
    backupDir = "/srv/vaultwarden/backup";

    config = {
      DOMAIN = "https://${vw.hostname}";

      # Bind to localhost only — Caddy is the sole entry point.
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = vw.port;
      ROCKET_LOG = "critical";

      # Store data on /srv so it survives OS reinstalls.
      DATA_FOLDER = "/srv/vaultwarden";

      # No public registrations — admin-created accounts only.
      SIGNUPS_ALLOWED = false;

      # SMTP via Resend.
      SMTP_HOST = "smtp.resend.com";
      SMTP_PORT = 465;
      SMTP_SECURITY = "force_tls";
      SMTP_USERNAME = "resend";
      SMTP_FROM = vw.smtpFrom;
      SMTP_FROM_NAME = vw.smtpFromName;

      # Don't leak password hints.
      SHOW_PASSWORD_HINT = false;

      LOG_LEVEL = "warn";
      EXTENDED_LOGGING = true;
    };
  };

  # Wait for /srv before starting — the data directory must exist first.
  systemd.services.vaultwarden = {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
      # The NixOS vaultwarden module applies ReadOnlyPaths hardening by default.
      # Explicitly grant write access to the data and backup directories on /srv.
      ReadWritePaths = [ "/srv/vaultwarden" ];
    };
    unitConfig = {
      StartLimitIntervalSec = cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst = cfg.server.servicePolicy.startLimitBurst;
    };
  };

  # ── Caddy reverse proxy ───────────────────────────────────────────────────
  # Tailnet-only — no Cloudflare Tunnel. Caddy terminates TLS with the
  # Let's Encrypt wildcard cert (*.ewancroft.uk) obtained via DNS-01.
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
