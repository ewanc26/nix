##############################################################################
#  Nextcloud — NixOS module.
#
#  Architecture:
#    Nextcloud / PHP-FPM (via nginx on 127.0.0.1:cfg.nextcloud.port)
#      ↑ reverse proxy
#    Caddy (bound to tailscale0 interface, port 80 — Tailscale-only, no Cloudflare tunnel)
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

      # Raise upload limit for large files.
      "upload_max_filesize" = nc.maxUploadSize;
      "post_max_size" = nc.maxUploadSize;
    };

    maxUploadSize = nc.maxUploadSize;
  };

  # Pin nginx to localhost so Caddy is the sole external entry point.
  services.nginx.virtualHosts."${nc.hostname}".listen = [
    {
      addr = "127.0.0.1";
      port = nc.port;
    }
  ];

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
