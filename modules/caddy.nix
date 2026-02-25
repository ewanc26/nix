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
#     http://<hostname>  — plain HTTP bound to the Tailscale IP only.
#     Tailscale's WireGuard tunnel already encrypts all traffic end-to-end,
#     so an additional TLS layer inside the tailnet is unnecessary.
##############################################################################
{ lib, ... }:
{
  # ── Caddy service ─────────────────────────────────────────────────────────
  services.caddy = {
    enable = true;

    # Disable automatic HTTPS — CF tunnel vhosts are plain HTTP, and tailnet
    # vhosts rely on WireGuard encryption rather than TLS.
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
  };
}
