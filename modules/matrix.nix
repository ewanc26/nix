##############################################################################
#  Matrix Synapse homeserver module — NixOS module.
#
#  Architecture:
#    Synapse (127.0.0.1:cfg.port)
#      ↑ reverse proxy
#    Caddy (127.0.0.1:cfg.caddyPort — internal only, no TLS here)
#      ↑ Cloudflare tunnel (cloudflared — outbound only, no firewall ports needed)
#
#  Non-secret settings live in settings/config/matrix.nix.
#  Secrets decrypted by ragenix at activation time.
#
#  Matrix delegation:
#    Since server_name (ewancroft.uk) differs from hostname (matrix.ewancroft.uk),
#    you need to set up .well-known delegation on your main website.
#
#    Add to your main website's nginx/caddy config at ewancroft.uk:
#      /.well-known/matrix/server → {"m.server": "matrix.ewancroft.uk:443"}
#      /.well-known/matrix/client → see example below
#
#  Example .well-known/matrix/client (serve as application/json):
#    {
#      "m.homeserver": {
#        "base_url": "https://matrix.ewancroft.uk"
#      }
#    }
#
#  Example .well-known/matrix/server (serve as application/json):
#    {
#      "m.server": "matrix.ewancroft.uk:443"
#    }
#
#  Required secrets (set in secrets/age/matrix.env.age as KEY=value pairs):
#    REGISTRATION_SHARED_SECRET    # Generate with: pwgen -s 64 1
#    MACAROON_SECRET_KEY           # Generate with: pwgen -s 64 1
#
#  Cloudflare tunnel setup (one-time, outside Nix):
#    Handled by modules/cloudflare-tunnel.nix.
#    See that module for setup instructions.
##############################################################################
{ config, lib, pkgs, self, cfgLib, ... }:

let
  cfg        = cfgLib.cfg.matrix;
  synapsePort = toString cfg.port;
  caddyPort   = toString cfg.caddyPort;
  matrixHost  = cfg.hostname;
in
lib.mkIf cfg.enable {

  # ── Secrets ──────────────────────────────────────────────────────────────────
  age.secrets."matrix.env" = {
    file  = self + /secrets/age/matrix.env.age;
    owner = "matrix-synapse";
    group = "matrix-synapse";
    mode  = "0400";
  };

  # ── Matrix Synapse service ────────────────────────────────────────────────────
  services.matrix-synapse = {
    enable = true;
    dataDir = "/srv/matrix-synapse";
    
    settings = {
      server_name = cfg.serverName;  # Domain used in Matrix IDs (@user:ewancroft.uk)
      
      # Public base URL for client-server API
      public_baseurl = "https://${matrixHost}";
      
      # Listener configuration
      listeners = [
        {
          port = cfg.port;
          bind_addresses = [ "127.0.0.1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          
          resources = [
            {
              names = [ "client" "federation" ];
              compress = false;
            }
          ];
        }
      ];

      # Database - using PostgreSQL for better performance
      database = {
        name = "psycopg2";
        args = {
          database = "matrix-synapse";
        };
      };

      # Enable registration (you may want to disable this and use registration_shared_secret)
      enable_registration = false;
      
      # Allow guests (optional)
      allow_guest_access = false;

      # URL previews
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

      # Media
      max_upload_size = "50M";
      
      # Security
      suppress_key_server_warning = true;
    };

    # Use environment file for secrets
    extraConfigFiles = [ config.age.secrets."matrix.env".path ];
  };

  # Enable PostgreSQL for Synapse
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

  # Restart policy for Synapse
  systemd.services.matrix-synapse = {
    serviceConfig = {
      Restart    = lib.mkForce "always";
      RestartSec = cfgLib.cfg.server.servicePolicy.restartSec;
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
      # Handle Matrix client-server and server-server APIs
      handle {
        reverse_proxy http://127.0.0.1:${synapsePort}
      }
    '';
  };

  # ── Firewall ──────────────────────────────────────────────────────────────────
  # Cloudflare tunnel is configured by modules/cloudflare-tunnel.nix.
  # SSH is handled by modules/server/firewall.nix and modules/server/ssh.nix.
}
