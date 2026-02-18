##############################################################################
#  Forgejo git forge — NixOS module.
#
#  Architecture:
#    Forgejo (127.0.0.1:cfg.forgejo.port)
#      ↑ reverse proxy
#    Caddy (127.0.0.1:cfg.forgejo.caddyPort — internal only, no TLS here)
#      ↑ Cloudflare tunnel (outbound only, no firewall ports needed)
#
#  Secrets (sops-encrypted, age backend):
#    secrets/forgejo.env — KEY=value env file, must contain:
#      SECRET_KEY      # openssl rand -hex 32
#      INTERNAL_TOKEN  # openssl rand -hex 32
#
#    Encrypt: sops --encrypt --age <host-age-pubkey> secrets/forgejo.env > secrets/forgejo.env
#    (Use .sops.yaml at the repo root to configure recipients automatically.)
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  forgejo = cfg.forgejo;
  forgejoPort = toString forgejo.port;
  caddyPort = toString forgejo.caddyPort;
in
lib.mkIf cfg.services.forgejo.enable {

  sops.secrets."forgejo.env" = {
    sopsFile = ../secrets/forgejo.env;
    format = "binary";
    owner = "forgejo";
    group = "forgejo";
    mode = "0400";
  };

  services.forgejo = {
    enable = true;
    stateDir = "/srv/forgejo";

    settings = {
      DEFAULT.APP_NAME = forgejo.appName;

      server = {
        DOMAIN = forgejo.hostname;
        ROOT_URL = "https://${forgejo.hostname}";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = forgejo.port;
      };

      service.DISABLE_REGISTRATION = forgejo.disableRegistration;
    };
  };

  systemd.services.forgejo = {
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
      EnvironmentFile = config.sops.secrets."forgejo.env".path;
    };
    unitConfig = {
      StartLimitIntervalSec = cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst = cfg.server.servicePolicy.startLimitBurst;
    };
  };

  services.caddy.virtualHosts."http://127.0.0.1:${caddyPort}" = {
    extraConfig = ''
      handle {
        reverse_proxy http://127.0.0.1:${forgejoPort}
      }
    '';
  };
}
