##############################################################################
#  Immich — NixOS module.
#
#  Architecture:
#    Immich server (127.0.0.1:cfg.immich.port)
#      ↑ reverse proxy
#    Caddy (https://immich.ewancroft.uk — tailnet only)
#
#  Storage:
#    Media lives at cfg.immich.mediaDir (default: /srv/immich), owned by the
#    immich user. Completely independent of Nextcloud.
#
#  Database & cache:
#    PostgreSQL and Redis are managed locally by NixOS (separate instances
#    from Nextcloud's — no conflicts).
#
#  First-run:
#    Navigate to https://immich.ewancroft.uk and complete the onboarding
#    wizard to create your admin account.
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

  # ── Storage ───────────────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d ${im.mediaDir} 0770 immich immich -"
  ];

  # ── Immich service ────────────────────────────────────────────────────────
  services.immich = {
    enable = true;

    # Bind to localhost only — Caddy is the sole entry point.
    host = "127.0.0.1";
    port = im.port;

    mediaLocation = im.mediaDir;

    # Local PostgreSQL — NixOS creates a dedicated DB and user automatically.
    database.enable = true;

    # Redis for job queues and caching (separate instance from Nextcloud's).
    redis.enable = true;
  };

  # Wait for /srv before starting Immich so the media directory exists.
  systemd.services.immich-server = {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
  };

  # ── Caddy reverse proxy ───────────────────────────────────────────────────
  # Tailscale direct route — bypasses Cloudflare (no upload size limit).
  # Let's Encrypt wildcard cert (*.ewancroft.uk) via Cloudflare DNS-01.
  services.caddy.virtualHosts."http://${im.hostname}" = lib.mkIf (cfg.server.tailscaleIP != "") {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      redir https://${im.hostname}{uri} permanent
    '';
  };

  services.caddy.virtualHosts."https://${im.hostname}" = lib.mkIf (cfg.server.tailscaleIP != "") {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      tls ${cfg.server.acmeCertDir}/fullchain.pem ${cfg.server.acmeCertDir}/key.pem
      reverse_proxy http://127.0.0.1:${toString im.port}
    '';
  };
}
