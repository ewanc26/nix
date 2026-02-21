##############################################################################
#  Nextcloud — NixOS module.
#
#  Architecture:
#    Nextcloud / PHP-FPM (via nginx on 127.0.0.1:cfg.nextcloud.port)
#      ↑ reverse proxy
#    Caddy (127.0.0.1:cfg.nextcloud.caddyPort — internal only, no TLS here)
#      ↑ Cloudflare tunnel (outbound only, no firewall ports needed)
#
#  Storage:
#    All Nextcloud state (config, apps, data) lives under /srv/nextcloud.
#    Data specifically lands at /srv/nextcloud/data — make sure the /srv
#    volume is mounted before this service starts.
#
#  Database:
#    PostgreSQL, created and managed locally by NixOS.
#
#  Secrets (sops-encrypted, age backend):
#    secrets/nextcloud-admin-pass — raw plaintext file containing only the
#    initial admin password (no KEY=value, just the password string).
#
#    Create and encrypt:
#      echo -n "$(openssl rand -base64 24)" > secrets/nextcloud-admin-pass
#      SOPS_AGE_KEY_FILE=~/.config/age/keys.txt \
#        nix run nixpkgs#sops -- --encrypt --in-place secrets/nextcloud-admin-pass
#
#    The admin password is only used on first install. After that you can
#    rotate it via the Nextcloud web UI and the file is no longer read.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  nc = cfg.nextcloud;
  ncPort = toString nc.port;
  caddyPort = toString nc.caddyPort;
in
lib.mkIf cfg.services.nextcloud.enable {

  sops.secrets."nextcloud-smtp-pass" = {
    sopsFile = ../secrets/nextcloud-smtp-pass;
    format = "binary";
    owner = "nextcloud";
    group = "nextcloud";
    mode = "0400";
  };

  sops.secrets."nextcloud-admin-pass" = {
    sopsFile = ../secrets/nextcloud-admin-pass;
    format = "binary";
    owner = "nextcloud";
    group = "nextcloud";
    mode = "0400";
  };

  services.nextcloud = {
    enable = true;

    # Store all Nextcloud state (config, apps, data) on the /srv volume.
    home = nc.dataDir;

    # TLS is terminated upstream by Cloudflare; nginx only speaks plain HTTP
    # locally. Setting https = false suppresses the nginx SSL config, but we
    # still tell Nextcloud to generate https:// URLs via overwriteProtocol.
    https = false;

    # Nginx listens on localhost only — Caddy is the only external entry point.
    hostName = nc.hostname;

    # Auto-update Nextcloud apps on rebuild.
    autoUpdateApps.enable = true;

    # Local PostgreSQL database — NixOS creates the DB and user automatically.
    database.createLocally = true;

    # Redis for file locking and caching — dramatically improves performance.
    configureRedis = true;

    config = {
      dbtype = "pgsql";
      adminuser = nc.adminUser;
      adminpassFile = config.sops.secrets."nextcloud-admin-pass".path;

    };

    settings = {
      # Tell Nextcloud its public URL uses HTTPS even though nginx is plain HTTP.
      overwriteprotocol = "https";

      default_phone_region = nc.defaultPhoneRegion;

      # Trust localhost (nginx) and Cloudflare tunnel as reverse proxies.
      # Fixes the "reverse proxy header configuration is incorrect" warning.
      trusted_proxies = [
        "127.0.0.1"
        "::1"
      ];

      # Run heavy background jobs (cleanup, preview generation etc.) at 2am.
      # Fixes the "no maintenance window start time configured" warning.
      maintenance_window_start = 2;

      # Use file logging so the Logreader app works in the admin panel.
      log_type = "file";

      # SMTP via Resend. Password is in secretFile to keep it out of the Nix store.
      mail_smtpmode = "smtp";
      mail_smtphost = "smtp.resend.com";
      mail_smtpport = 465;
      mail_smtpsecure = "ssl";
      mail_smtpauth = true;
      mail_smtpauthtype = "LOGIN";
      mail_smtpname = "resend";
      mail_from_address = lib.head (lib.splitString "@" nc.smtp.fromAddress);
      mail_domain = nc.smtp.fromDomain;
    };

    # SMTP password — file contains the raw API key, never ends up in the Nix store.
    secrets.mail_smtppassword = config.sops.secrets."nextcloud-smtp-pass".path;

    maxUploadSize = nc.maxUploadSize;

    # Increase PHP opcache interned strings buffer (fixes the opcache warning).
    phpOptions."opcache.interned_strings_buffer" = "16";
  };

  # Pin nginx to localhost so Caddy is the sole external entry point.
  # Also inject the HSTS header manually since https = false disables nginx.hstsMaxAge.
  services.nginx.virtualHosts."${nc.hostname}" = {
    listen = [
      {
        addr = "127.0.0.1";
        port = nc.port;
      }
    ];
    extraConfig = ''
      add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
    '';
  };

  # Wait for /srv to be mounted before starting Nextcloud.
  systemd.services.nextcloud-setup = {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
  };

  systemd.services.nextcloud-cron = {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = cfg.server.servicePolicy.restartSec;
    };
  };

  services.caddy.virtualHosts."http://${nc.hostname}:${caddyPort}" = {
    extraConfig = ''
      handle {
        reverse_proxy http://127.0.0.1:${ncPort}
      }
    '';
  };
}
