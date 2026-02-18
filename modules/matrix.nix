##############################################################################
#  Matrix Synapse homeserver — NixOS module.
#
#  Architecture:
#    Synapse (127.0.0.1:cfg.matrix.port)
#      ↑ reverse proxy
#    Caddy (127.0.0.1:cfg.matrix.caddyPort — internal only, no TLS here)
#      ↑ Cloudflare tunnel (outbound only, no firewall ports needed)
#
#  Secrets (sops-encrypted, age backend):
#    secrets/matrix.env — KEY=value env file, must contain:
#      REGISTRATION_SHARED_SECRET   pwgen -s 64 1
#      MACAROON_SECRET_KEY          pwgen -s 64 1
#
#  Matrix .well-known delegation:
#    Since server_name (ewancroft.uk) differs from the Matrix hostname,
#    serve at ewancroft.uk:
#      /.well-known/matrix/server → {"m.server": "matrix.ewancroft.uk:443"}
#      /.well-known/matrix/client → {"m.homeserver": {"base_url": "https://matrix.ewancroft.uk"}}
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  matrix = cfg.matrix;
  synapsePort = toString matrix.port;
  caddyPort = toString matrix.caddyPort;
in
lib.mkIf cfg.services.matrix.enable {

  sops.secrets."matrix.env" = {
    sopsFile = ../secrets/matrix.env;
    format = "binary";
    owner = "matrix-synapse";
    group = "matrix-synapse";
    mode = "0400";
  };

  services.matrix-synapse = {
    enable = true;
    dataDir = "/srv/matrix-synapse";

    settings = {
      server_name = matrix.serverName;
      public_baseurl = "https://${matrix.hostname}";

      listeners = [
        {
          port = matrix.port;
          bind_addresses = [ "127.0.0.1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = false;
            }
          ];
        }
      ];

      database = {
        name = "psycopg2";
        args.database = "matrix-synapse";
      };

      enable_registration = false;
      allow_guest_access = false;
      url_preview_enabled = true;

      url_preview_ip_range_blacklist = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "100.64.0.0/10"
        "169.254.0.0/16"
        "::1/128"
        "fe80::/64"
        "fc00::/7"
      ];

      max_upload_size = "50M";
      suppress_key_server_warning = true;
    };

    extraConfigFiles = [ config.sops.secrets."matrix.env".path ];
  };

  services.postgresql = {
    enable = true;
    dataDir = "/srv/postgresql";
    ensureDatabases = [ "matrix-synapse" ];
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.matrix-synapse = {
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
    };
    unitConfig = {
      StartLimitIntervalSec = cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst = cfg.server.servicePolicy.startLimitBurst;
    };
  };

  services.caddy.virtualHosts."http://127.0.0.1:${caddyPort}" = {
    extraConfig = ''
      handle {
        reverse_proxy http://127.0.0.1:${synapsePort}
      }
    '';
  };
}
