##############################################################################
#  Caddy reverse proxy module.
#
#  Two classes of virtual host live here:
#
#  1. Cloudflare Tunnel vhosts  (defined in each service's module)
#     http://<hostname>:<caddyPort>  — plain HTTP on non-standard ports.
#     TLS is terminated by Cloudflare; Caddy never sees HTTPS here.
#
#  2. Tailnet vhosts  (defined in each service's module)
#     https://<hostname>  — TLS bound to the Tailscale IP only.
#     Cert is a Let's Encrypt wildcard (*.ewancroft.uk) obtained via
#     Cloudflare DNS-01 challenge; see the security.acme block below.
#     Tailscale's WireGuard tunnel provides an additional layer of
#     end-to-end encryption at the network layer.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  hasTailnet = cfg.server.tailscaleIP != "";
in
{
  # ── Caddy service ─────────────────────────────────────────────────────────
  services.caddy = {
    enable = true;

    # Disable automatic HTTPS — CF tunnel vhosts are plain HTTP, and tailnet
    # vhosts supply their own cert from security.acme below.
    globalConfig = ''
      auto_https off
    '';
  };

  # ── Caddy systemd service tweaks ──────────────────────────────────────────
  systemd.services.caddy = {
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = lib.mkDefault "5s";
    };
    # Ensure the ACME wildcard cert exists before Caddy starts.
    after = lib.optional hasTailnet "acme-ewancroft.uk.service";
    wants = lib.optional hasTailnet "acme-ewancroft.uk.service";
  };

  # ── ACME wildcard cert for tailnet vhosts ─────────────────────────────────
  # Uses Cloudflare DNS-01 so no port needs to be opened. Covers all
  # *.ewancroft.uk tailnet services (Nextcloud, Immich, Jellyfin, Cockpit).
  #
  # Prerequisite: create and sops-encrypt secrets/cloudflare-acme.env
  # containing: CLOUDFLARE_DNS_API_TOKEN=<token>
  # The token needs Zone.DNS edit permission for ewancroft.uk.
  sops.secrets."cloudflare-acme.env" = lib.mkIf hasTailnet {
    sopsFile = ../secrets/cloudflare-acme.env;
    format = "dotenv";
    owner = "acme";
    mode = "0440";
  };

  security.acme = lib.mkIf hasTailnet {
    acceptTerms = true;
    defaults.email = cfg.user.email;
    certs."ewancroft.uk" = {
      domain = "*.ewancroft.uk";
      dnsProvider = "cloudflare";
      # Explicitly disable HTTP challenge — DNS-01 only.
      webroot = null;
      # environmentFile is a dotenv-format file: CLOUDFLARE_DNS_API_TOKEN=<token>
      environmentFile = config.sops.secrets."cloudflare-acme.env".path;
      # Emit verbose lego output so failures are diagnosable in the journal.
      enableDebugLogs = true;
      # Let Caddy read the cert files.
      group = config.services.caddy.group;
      # Reload Caddy whenever the cert is renewed.
      reloadServices = [ "caddy" ];
    };
  };
}
