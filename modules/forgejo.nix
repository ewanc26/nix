##############################################################################
#  Forgejo git forge — NixOS module.
#
#  Architecture:
#    Forgejo (127.0.0.1:cfg.port)
#      ↑ reverse proxy
#    Caddy (127.0.0.1:cfg.caddyPort — internal only, no TLS here)
#      ↑ Cloudflare tunnel (cloudflared — outbound only, no firewall ports needed)
#
#  Non-secret settings live in settings/config/forgejo.nix.
#  Secrets decrypted by ragenix at activation time.
#
#  Required secrets (set in secrets/age/forgejo.env.age as KEY=value pairs):
#    SECRET_KEY      # Generate with: openssl rand -hex 32
#    INTERNAL_TOKEN  # Generate with: openssl rand -hex 32
#
#  Cloudflare tunnel setup (one-time, outside Nix):
#    Handled by modules/cloudflare-tunnel.nix.
#    Add a CNAME in Cloudflare DNS:
#      git.ewancroft.uk → <UUID>.cfargotunnel.com
#
#  First-run admin account:
#    The first user to register becomes admin, OR create one manually:
#      sudo -u forgejo forgejo admin user create \
#        --username admin --password <pw> --email <email> --admin
##############################################################################
{ config, lib, pkgs, self, cfgLib, ... }:

let
  cfg       = cfgLib.cfg.forgejo;
  forgejoPort = toString cfg.port;
  caddyPort   = toString cfg.caddyPort;
in
lib.mkIf cfg.enable {

  # ── Secrets ──────────────────────────────────────────────────────────────────
  age.secrets."forgejo.env" = {
    file  = self + /secrets/age/forgejo.env.age;
    owner = "forgejo";
    group = "forgejo";
    mode  = "0400";
  };

  # ── Forgejo service ───────────────────────────────────────────────────────────
  services.forgejo = {
    enable   = true;
    stateDir = "/srv/forgejo";

    settings = {
      DEFAULT.APP_NAME = cfg.appName;

      server = {
        DOMAIN   = cfg.hostname;
        ROOT_URL = "https://${cfg.hostname}";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = cfg.port;
      };

      service = {
        DISABLE_REGISTRATION = cfg.disableRegistration;
      };

      # Use the environment file for secrets (SECRET_KEY, INTERNAL_TOKEN).
      # Forgejo reads these from the environment automatically.
    };
  };

  systemd.services.forgejo = {
    serviceConfig = {
      Restart         = lib.mkForce "always";
      RestartSec      = cfgLib.cfg.server.servicePolicy.restartSec;
      # Inject age-decrypted secrets (SECRET_KEY, INTERNAL_TOKEN) into env.
      # services.forgejo.environmentFile was removed in nixos-25.11; use
      # systemd's EnvironmentFile directly instead.
      EnvironmentFile = config.age.secrets."forgejo.env".path;
    };
    unitConfig = {
      StartLimitIntervalSec = cfgLib.cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst       = cfgLib.cfg.server.servicePolicy.startLimitBurst;
    };
  };

  # ── Caddy reverse proxy ───────────────────────────────────────────────────────
  # Listens on localhost:caddyPort only — never exposed publicly.
  # Cloudflare handles TLS; Caddy receives plain HTTP from the tunnel daemon.
  # Using http:// prefix disables Caddy's automatic HTTPS / ACME entirely.
  #
  # Note: Caddy service itself is enabled by modules/caddy.nix.
  services.caddy.virtualHosts."http://127.0.0.1:${caddyPort}" = {
    extraConfig = ''
      handle {
        reverse_proxy http://127.0.0.1:${forgejoPort}
      }
    '';
  };

  # ── Firewall ──────────────────────────────────────────────────────────────────
  # Cloudflare tunnel is configured by modules/cloudflare-tunnel.nix.
  # SSH is handled by modules/server/firewall.nix and modules/server/ssh.nix.
}
