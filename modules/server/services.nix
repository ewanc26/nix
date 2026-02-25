{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  cockpit = cfg.server.cockpit;
in
{
  # Tailscale VPN for inter-host communication
  services.tailscale.enable = true;

  # SSH daemon (server hardened configuration from modules/server/ssh.nix)
  # No additional SSH config needed here — it's handled by server-hardened profile.

  # ── Cockpit — tailnet-only web management console ──────────────────────────
  # Cockpit listens on localhost only; Caddy proxies it on the Tailscale IP.
  # Reachable at https://${cockpit.hostname} from any tailnet device once
  # split-dns is configured (see modules/split-dns.nix).
  services.cockpit = lib.mkIf cockpit.enable {
    enable = true;
    port = cockpit.port;
    settings.WebService = {
      # Required when behind a reverse proxy — Cockpit rejects WebSocket
      # connections from origins it doesn't recognise.
      Origins = lib.mkForce "https://${cockpit.hostname} wss://${cockpit.hostname}";
      # Tell Cockpit to trust the X-Forwarded-Proto header from Caddy.
      ProtocolHeader = "X-Forwarded-Proto";
      # Allow plain HTTP from Caddy (WireGuard encrypts the tailnet).
      AllowUnencrypted = true;
    };
  };

  services.caddy.virtualHosts."https://${cockpit.hostname}" =
    lib.mkIf (cockpit.enable && cfg.server.tailscaleIP != "")
      {
        extraConfig = ''
          bind ${cfg.server.tailscaleIP}
          tls internal
          reverse_proxy http://127.0.0.1:${toString cockpit.port} {
            header_up X-Forwarded-Proto https
            transport http {
              read_timeout 30s
            }
          }
        '';
      };
}
