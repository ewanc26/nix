##############################################################################
#  Jellyfin — NixOS module.
#
#  Architecture:
#    Jellyfin server (127.0.0.1:cfg.jellyfin.port)
#      ↑ reverse proxy
#    Caddy (http://jellyfin.ewancroft.uk:cfg.jellyfin.caddyPort)
#      ↑ Cloudflare Tunnel (outbound only, no firewall ports needed)
#
#  Storage — shared with Nextcloud:
#    Media lives at cfg.jellyfin.mediaDir, which defaults to
#    /srv/nextcloud/data/ewan/files/Media — inside the Nextcloud user files
#    tree. This means:
#      • Media uploaded via Nextcloud (desktop/mobile sync) is immediately
#        available to add as a Jellyfin library.
#      • The nextcloud-files-scan timer (daily) keeps Nextcloud aware of any
#        files written directly to this path.
#
#    After first-run, add libraries from the Jellyfin web UI pointing at
#    subdirectories of cfg.jellyfin.mediaDir, e.g.:
#      /srv/nextcloud/data/ewan/files/Media/Movies
#      /srv/nextcloud/data/ewan/files/Media/TV
#      /srv/nextcloud/data/ewan/files/Media/Music
#
#  Permissions:
#    The `jellyfin` user is added to the `nextcloud` group. The Media
#    directory is created with mode 2770 (setgid) so new files created by
#    either service inherit the nextcloud group. Jellyfin only reads media —
#    it does not write to cfg.jellyfin.mediaDir.
#
#  Config/metadata:
#    Jellyfin's own config, metadata, and plugins live at cfg.jellyfin.dataDir
#    (/var/lib/jellyfin by default) — managed entirely by the NixOS module,
#    separate from the /srv volume.
#
#  First-run:
#    Navigate to https://jellyfin.ewancroft.uk and complete the setup wizard.
#    Add media libraries pointing at subdirectories of cfg.jellyfin.mediaDir.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  jf = cfg.jellyfin;
in
lib.mkIf cfg.services.jellyfin.enable {

  # ── User / group ─────────────────────────────────────────────────────────
  # Add jellyfin to the nextcloud group so it can traverse and read inside
  # the Nextcloud data tree.
  users.users.jellyfin = {
    extraGroups = [ "nextcloud" ];
  };

  # ── Storage ───────────────────────────────────────────────────────────────
  # Create the Media root inside the Nextcloud user files tree.
  # Mode 2770: setgid ensures files created here inherit the nextcloud group.
  # Subdirectories (Movies, TV, Music etc.) should be created manually or by
  # a future module — Jellyfin does not create library directories itself.
  systemd.tmpfiles.rules = [
    "d ${jf.mediaDir}        2770 nextcloud nextcloud -"
    "d ${jf.mediaDir}/Movies 2770 nextcloud nextcloud -"
    "d ${jf.mediaDir}/TV     2770 nextcloud nextcloud -"
    "d ${jf.mediaDir}/Music  2770 nextcloud nextcloud -"
  ];

  # ── Jellyfin service ──────────────────────────────────────────────────────
  services.jellyfin = {
    enable = true;

    # Config, metadata, and plugins on the system disk.
    dataDir = jf.dataDir;

    # Do NOT open Jellyfin's default ports (8096/8920) — Caddy is the sole
    # entry point, proxied through the Cloudflare tunnel.
    openFirewall = false;
  };

  # Wait for /srv (and Nextcloud's initial setup) before starting Jellyfin,
  # so the Media directory is guaranteed to exist with correct ownership.
  systemd.services.jellyfin = {
    after = [
      "srv.mount"
      "nextcloud-setup.service"
    ];
    wants = [ "srv.mount" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = cfg.server.servicePolicy.restartSec;
    };
  };

  # ── Caddy reverse proxy ───────────────────────────────────────────────────
  # Tailscale direct route — bypasses Cloudflare.
  # Reachable at https://${jf.hostname} from any tailnet device once split-dns
  # is configured (see modules/split-dns.nix).
  services.caddy.virtualHosts."https://${jf.hostname}" = lib.mkIf (cfg.server.tailscaleIP != "") {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      tls internal
      reverse_proxy http://127.0.0.1:${toString jf.port}
    '';
  };
}
