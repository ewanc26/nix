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
  # Reachable at http://${cockpit.hostname} from any tailnet device once
  # split-dns is configured (see modules/split-dns.nix).
  services.cockpit = lib.mkIf cockpit.enable {
    enable = true;
    port = cockpit.port;
    # Bind to localhost only — Caddy is the sole entry point.
    settings.WebService.Origins = "http://${cockpit.hostname} ws://${cockpit.hostname}";
  };

  services.caddy.virtualHosts."http://${cockpit.hostname}" =
    lib.mkIf (cockpit.enable && cfg.server.tailscaleIP != "")
      {
        extraConfig = ''
          bind ${cfg.server.tailscaleIP}
          reverse_proxy http://127.0.0.1:${toString cockpit.port} {
            transport http {
              read_timeout 30s
            }
          }
        '';
      };
}
