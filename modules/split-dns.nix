##############################################################################
#  Split DNS — CoreDNS resolver for *.ewancroft.uk on the Tailscale interface.
#
#  Why this exists:
#    Services like Immich, Jellyfin, and Nextcloud are only accessible via
#    the Cloudflare Tunnel publicly. Cloudflare imposes a ~100 MiB upload
#    limit. For tailnet-connected clients (phones, laptops) we want to reach
#    these services *directly* over the tailnet, bypassing Cloudflare.
#
#  How it works:
#    CoreDNS listens on the server's Tailscale IP (port 53). When a tailnet
#    device queries *.ewancroft.uk, CoreDNS returns the server's Tailscale IP,
#    routing traffic directly over the tailnet to Caddy.
#    All other queries are forwarded to Cloudflare's public resolvers.
#
#  Setup (one-time, outside Nix):
#    1. Set myConfig.server.tailscaleIP to your server's Tailscale IP.
#       Find it with: tailscale ip -4
#    2. In the Tailscale admin console → DNS → Nameservers:
#       Click "Add nameserver" → "Custom", enter the Tailscale IP, and set
#       "Restrict to domain" to "ewancroft.uk". Save.
#    This tells all tailnet devices to use CoreDNS for ewancroft.uk queries.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  tsIP = cfg.server.tailscaleIP;

  # Build host entries for all enabled Tailnet-routed services.
  hostEntries = lib.concatStringsSep "\n        " (
    lib.optional cfg.services.immich.enable "${tsIP} ${cfg.immich.hostname}"
    ++ lib.optional cfg.services.nextcloud.enable "${tsIP} ${cfg.nextcloud.hostname}"
    ++ lib.optional cfg.services.jellyfin.enable "${tsIP} ${cfg.jellyfin.hostname}"
    ++ lib.optional cfg.services.forgejo.enable "${tsIP} ${cfg.forgejo.hostname}"
  );
in
lib.mkIf (tsIP != "") {

  services.coredns = {
    enable = true;
    config = ''
      # Authoritative for ewancroft.uk — return Tailscale IP for known services,
      # forward everything else (e.g. pds.ewancroft.uk) to public DNS.
      ewancroft.uk {
        bind ${tsIP}
        hosts {
          ${hostEntries}
          fallthrough
        }
        forward . 1.1.1.1 8.8.8.8
        cache 300
        log
        errors
      }

      # All other domains — forward to Cloudflare public DNS.
      . {
        bind ${tsIP}
        forward . 1.1.1.1 8.8.8.8
        cache 3600
        errors
      }
    '';
  };

  # Allow DNS from tailnet devices on the Tailscale interface only.
  # Port 53 is NOT added to the global allowedTCPPorts/allowedUDPPorts,
  # so it remains inaccessible from the public internet.
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

}
