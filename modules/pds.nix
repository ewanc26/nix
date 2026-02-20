##############################################################################
#  Bluesky ATProto Personal Data Server — NixOS module.
#
#  Architecture:
#    PDS (127.0.0.1:cfg.pds.port)
#      ↑ reverse proxy
#    Caddy (127.0.0.1:cfg.pds.caddyPort — internal only, no TLS here)
#      ↑ Cloudflare tunnel (outbound only, no firewall ports needed)
#
#  Secrets (sops-encrypted, age backend):
#    secrets/pds.env — KEY=value env file, must contain:
#      PDS_JWT_SECRET                              openssl rand --hex 16
#      PDS_ADMIN_PASSWORD                          openssl rand --hex 16
#      PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX  see pds docs
#      PDS_EMAIL_SMTP_URL                          (optional)
#      PDS_EMAIL_FROM_ADDRESS                      (optional)
##############################################################################
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;
  pds = cfg.pds;
  pdsPort = toString pds.port;
  caddyPort = toString pds.caddyPort;

  # Static landing page served by Caddy at the PDS root URL.
  # Built from modular source files in ./pds-landing/.
  landingPage = pkgs.runCommand "pds-landing" { } ''
    mkdir $out
    cp ${./pds-landing/index.html} $out/index.html
    cp ${./pds-landing/style.css}  $out/style.css
    cp ${./pds-landing/script.js}  $out/script.js
  '';

  # UK Online Safety Act age-assurance static responses.
  ageAssuranceBlocks = ''
    handle /xrpc/app.bsky.unspecced.getAgeAssuranceState {
      header Content-Type "application/json"
      header Access-Control-Allow-Headers "authorization,dpop,atproto-accept-labelers,atproto-proxy"
      header Access-Control-Allow-Origin "*"
      respond `{"lastInitiatedAt":"2025-07-14T14:22:43.912Z","status":"assured"}` 200
    }
    handle /xrpc/app.bsky.ageassurance.getConfig {
      header Content-Type "application/json"
      header Access-Control-Allow-Headers "authorization,dpop,atproto-accept-labelers,atproto-proxy"
      header Access-Control-Allow-Origin "*"
      respond `{"regions":[]}` 200
    }
    handle /xrpc/app.bsky.ageassurance.getState {
      header Content-Type "application/json"
      header Access-Control-Allow-Headers "authorization,dpop,atproto-accept-labelers,atproto-proxy"
      header Access-Control-Allow-Origin "*"
      respond `{"state":{"lastInitiatedAt":"2025-07-14T14:22:43.912Z","status":"assured","access":"full"},"metadata":{"accountCreatedAt":"2022-11-17T00:35:16.391Z"}}` 200
    }
  '';
in
lib.mkIf cfg.services.pds.enable {

  sops.secrets."pds.env" = {
    sopsFile = ../secrets/pds.env;
    format = "dotenv";
    owner = "pds";
    group = "pds";
    mode = "0400";
  };

  environment.systemPackages = [ pkgs.atproto-goat ];

  services.bluesky-pds = {
    enable = true;
    environmentFiles = [ config.sops.secrets."pds.env".path ];
    settings = {
      PDS_DATA_DIRECTORY = "/srv/bluesky-pds";
      PDS_PORT = pds.port;
      PDS_HOSTNAME = pds.hostname;
      PDS_ADMIN_EMAIL = pds.adminEmail;
      PDS_SERVICE_HANDLE_DOMAINS = lib.concatStringsSep "," pds.serviceHandleDomains;
      PDS_CRAWLERS = lib.concatStringsSep "," pds.crawlers;
    };
  };

  systemd.services.bluesky-pds = {
    # Wait for /srv to be mounted — but don't fail if it isn't yet.
    # When the drive is plugged in and srv.mount starts, this service
    # will start automatically via the wantedBy relationship.
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
      ReadWritePaths = [ "/srv/bluesky-pds" ];
    };
    unitConfig = {
      StartLimitIntervalSec = cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst = cfg.server.servicePolicy.startLimitBurst;
    };
  };

  services.caddy.virtualHosts."http://${pds.hostname}:${caddyPort}" = {
    # was 127.0.0.1
    extraConfig = ''
      ${ageAssuranceBlocks}

      # Landing page — serve static assets; redirect bare /index.html to /.
      handle /index.html {
        redir / permanent
      }
      @landing path / /style.css /script.js
      handle @landing {
        root * ${landingPage}
        file_server
      }

      handle {
        reverse_proxy http://127.0.0.1:${pdsPort}
      }
    '';
  };
}
