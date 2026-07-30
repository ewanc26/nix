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
#  Secrets (sops-encrypted; your PGP key + the host's age key):
#    secrets/nextcloud-admin-pass — raw plaintext file containing only the
#    initial admin password (no KEY=value, just the password string).
#
#    Create and encrypt:
#      echo -n "$(openssl rand -base64 24)" > secrets/nextcloud-admin-pass
#      nix run nixpkgs#sops -- --encrypt --in-place secrets/nextcloud-admin-pass
#
#    The admin password is only used on first install. After that you can
#    rotate it via the Nextcloud web UI and the file is no longer read.
#
#  DNS / Cloudflare:
#    Route traffic via Cloudflare tunnel. Add a CNAME record in Cloudflare
#    DNS pointing cloud.ewancroft.uk to <tunnel-id>.cfargotunnel.com.
##############################################################################
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;
  nc = cfg.nextcloud;
  ncPort = toString nc.port;
  caddyPort = toString nc.caddyPort;
  metaFiles = pkgs.linkFarm "nextcloud-meta" [
    {
      name = "privacy.txt";
      path = ./nextcloud-meta/privacy.txt;
    }
    {
      name = "legal.txt";
      path = ./nextcloud-meta/legal.txt;
    }
  ];
in
lib.mkIf cfg.services.nextcloud.enable {

  sops.secrets."nextcloud-smtp-pass" = {
    sopsFile = ../../../../secrets/nextcloud-smtp-pass;
    format = "binary";
    owner = "nextcloud";
    group = "nextcloud";
    mode = "0400";
  };

  sops.secrets."nextcloud-admin-pass" = {
    sopsFile = ../../../../secrets/nextcloud-admin-pass;
    format = "binary";
    owner = "nextcloud";
    group = "nextcloud";
    mode = "0400";
  };

  services.nextcloud = {
    enable = true;

    # Store all Nextcloud state (config, apps, data) on the /srv volume.
    home = nc.dataDir;

    # Cloudflare tunnel terminates TLS — nginx serves plain HTTP.
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
      # Serve over HTTPS — Cloudflare tunnel terminates TLS.
      overwriteprotocol = "https";
      "overwrite.cli.url" = "https://${nc.hostname}";

      default_phone_region = nc.defaultPhoneRegion;

      # Trust localhost (nginx) and Cloudflare tunnel as reverse proxies.
      # Fixes the "reverse proxy header configuration is incorrect" warning.
      # Cloudflare IP ranges are documented at:
      # https://www.cloudflare.com/ips-v4/ and https://www.cloudflare.com/ips-v6/
      trusted_proxies = [
        "127.0.0.1"
        "::1"
        "173.245.48.0/20"
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "141.101.64.0/18"
        "108.162.192.0/18"
        "190.93.240.0/20"
        "188.114.96.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
        "162.158.0.0/15"
        "104.16.0.0/13"
        "104.24.0.0/14"
        "172.64.0.0/13"
        "131.0.72.0/22"
        "2400:cb00::/32"
        "2606:4700::/32"
        "2803:f800::/32"
        "2405:b500::/32"
        "2405:8100::/32"
        "2a06:98c0::/29"
        "2c0f:f248::/32"
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

    # Keep PHP temp uploads on the same filesystem as the data dir so that
    # chunk assembly is an atomic rename rather than a cross-device copy.
    # Without this, large uploads silently fail to assemble and leave ghost
    # entries in the database.
    phpOptions."upload_tmp_dir" = "${nc.dataDir}/tmp";
  };

  # Pin nginx to localhost — Caddy is the sole external entry point.
  services.nginx.virtualHosts."${nc.hostname}" = {
    listen = [
      {
        addr = "127.0.0.1";
        port = nc.port;
      }
    ];
  };

  # Ensure the PHP upload tmp dir exists with correct ownership before Nextcloud
  # starts. Without this, PHP silently falls back to /tmp (a different filesystem),
  # causing cross-device rename failures that leave large uploads as ghost entries.
  systemd.tmpfiles.rules = [
    "d ${nc.dataDir}/tmp 0750 nextcloud nextcloud -"
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

  # Caddy vhost — plain HTTP on caddyPort, proxied via Cloudflare tunnel.
  # TLS is terminated by Cloudflare; Caddy never sees HTTPS.
  services.caddy.virtualHosts.":${caddyPort}" = {
    extraConfig = ''
      handle /.meta/* {
        uri strip_prefix /.meta
        root * ${metaFiles}
        file_server
      }
      handle {
        reverse_proxy http://127.0.0.1:${ncPort} {
          transport http {
            read_timeout  3600s
            write_timeout 3600s
          }
        }
      }
      request_body {
        max_size 50GB
      }
    '';
  };

  # Increase PHP-FPM request timeout to match Caddy — prevents large uploads
  # from being killed mid-transfer.
  services.phpfpm.pools.nextcloud.settings = {
    "request_terminate_timeout" = "3600";
  };

  # nextcloud-occ internally calls systemd-run to execute as the nextcloud user,
  # which requires polkit permission to start transient units. On a headless
  # server with no interactive session polkit denies this by default — this rule
  # grants the nextcloud system user the minimum necessary permission.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        (action.id === "org.freedesktop.systemd1.manage-units" ||
         action.id === "org.freedesktop.systemd1.manage-unit-files") &&
        subject.user === "nextcloud"
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  # Periodically scan the data directory so files added directly to /srv
  # or written by co-located services (Immich, Jellyfin) are picked up by Nextcloud.
  systemd.services.nextcloud-files-scan = {
    description = "Nextcloud periodic file scan";
    after = [ "nextcloud-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
      ExecStart = "${config.services.nextcloud.occ}/bin/nextcloud-occ files:scan --all";
    };
  };

  systemd.timers.nextcloud-files-scan = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
