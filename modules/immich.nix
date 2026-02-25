##############################################################################
#  Immich — NixOS module.
#
#  Architecture:
#    Immich server (127.0.0.1:cfg.immich.port)
#      ↑ reverse proxy
#    Caddy (http://immich.ewancroft.uk:cfg.immich.caddyPort)
#      ↑ Cloudflare Tunnel (outbound only, no firewall ports needed)
#
#  Storage — shared with Nextcloud:
#    Media lives at cfg.immich.mediaDir, which defaults to
#    /srv/nextcloud/data/ewan/files/Photos — inside the Nextcloud user files
#    tree. This means:
#      • Photos uploaded via the Immich mobile app appear in Nextcloud.
#      • Photos synced to Nextcloud via the desktop client appear in Immich
#        (picked up by the nextcloud-files-scan timer, which runs daily).
#
#  Permissions:
#    The `immich` user is added to the `nextcloud` group. The Photos directory
#    is created with mode 2770 (setgid) so all files created inside inherit
#    the nextcloud group, keeping Nextcloud happy when it scans them.
#    Nextcloud's own data directory is group-traversable (0750) by default,
#    so group membership is sufficient for access.
#
#  Database & cache:
#    PostgreSQL and Redis are managed locally by NixOS (separate instances
#    from Nextcloud's — no conflicts).
#
#  First-run:
#    Navigate to https://immich.ewancroft.uk and complete the onboarding
#    wizard to create your admin account. Then configure the library path
#    to cfg.immich.mediaDir from the UI.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  im = cfg.immich;
in
lib.mkIf cfg.services.immich.enable {

  # ── User / group ─────────────────────────────────────────────────────────
  # Add immich to the nextcloud group so it can read/write inside the
  # Nextcloud data tree with the setgid directories created below.
  users.users.immich = {
    extraGroups = [ "nextcloud" ];
  };

  # ── Storage ───────────────────────────────────────────────────────────────
  # Create the Photos directory inside the Nextcloud user files tree.
  # Mode 2770: owner=nextcloud, group=nextcloud, setgid so new files
  # inherit the group — Nextcloud's scanner expects group-owned files.
  systemd.tmpfiles.rules = [
    # Ensure the Media parent (shared with Jellyfin) exists even if jellyfin.nix
    # is disabled. Referencing cfg.jellyfin.mediaDir directly avoids builtins.dirOf,
    # which strips option context and causes an activation-script derivation warning.
    "d ${cfg.jellyfin.mediaDir} 2770 nextcloud nextcloud -"
    "d ${im.mediaDir}           2770 nextcloud nextcloud -"
  ];

  # ── Immich service ────────────────────────────────────────────────────────
  services.immich = {
    enable = true;

    # Bind to localhost only — Caddy is the sole entry point.
    host = "127.0.0.1";
    port = im.port;

    # Point at the shared directory inside the Nextcloud data tree.
    mediaLocation = im.mediaDir;

    # Local PostgreSQL — NixOS creates a dedicated DB and user automatically.
    database.enable = true;

    # Redis for job queues and caching (separate instance from Nextcloud's).
    redis.enable = true;
  };

  # Wait for /srv (and Nextcloud's initial setup) before starting Immich,
  # so the Photos directory is guaranteed to exist with correct ownership.
  systemd.services.immich-server = {
    after = [
      "srv.mount"
      "nextcloud-setup.service"
    ];
    wants = [ "srv.mount" ];
  };

  # ── Caddy reverse proxy ───────────────────────────────────────────────────
  # Tailscale direct route — bypasses Cloudflare (no upload size limit).
  # Let's Encrypt wildcard cert (*.ewancroft.uk) via Cloudflare DNS-01.
  # Reachable from any tailnet device at https://${im.hostname} once split-dns
  # is configured in the Tailscale admin console (see modules/split-dns.nix).
  services.caddy.virtualHosts."https://${im.hostname}" = lib.mkIf (cfg.server.tailscaleIP != "") {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      tls ${cfg.server.acmeCertDir}/fullchain.pem ${cfg.server.acmeCertDir}/key.pem
      reverse_proxy http://127.0.0.1:${toString im.port}
    '';
  };
}
