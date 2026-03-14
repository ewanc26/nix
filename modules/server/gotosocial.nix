##############################################################################
#  GoToSocial ActivityPub server — NixOS module.
#
#  Architecture:
#    GoToSocial (127.0.0.1:cfg.gotosocial.port)
#      ↑ reverse proxy
#    Caddy (127.0.0.1:cfg.gotosocial.caddyPort — internal only, no TLS here)
#      ↑ Cloudflare tunnel (outbound only, no firewall ports needed)
#
#  Account handle trick:
#    host          = ap.ewancroft.uk  (where the server lives)
#    account-domain = ewancroft.uk        (what handles show as)
#    → accounts appear as @ewan@ewancroft.uk
#
#  WebFinger:
#    ewancroft.uk/.well-known/webfinger redirects to
#    ap.ewancroft.uk/.well-known/webfinger (handled in the website repo's
#    vercel.json). Clients follow the redirect and GoToSocial responds normally.
#
#  First-run (once the service is up):
#    gotosocial-admin account create \
#      --username ewan --email contact@ewancroft.uk --password <pw>
#    gotosocial-admin account confirm --username ewan
#    gotosocial-admin account promote --username ewan
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  gts = cfg.gotosocial;
  gtsPort = toString gts.port;
  caddyPort = toString gts.caddyPort;
in
lib.mkIf cfg.services.gotosocial.enable {

  sops.secrets."gotosocial.env" = {
    sopsFile = ../../secrets/gotosocial.env;
    format = "dotenv";
    owner = "gotosocial";
    group = "gotosocial";
    mode = "0400";
  };

  services.gotosocial = {
    enable = true;
    environmentFile = config.sops.secrets."gotosocial.env".path;
    settings = {
      host = gts.hostname;
      account-domain = gts.accountDomain;
      port = gts.port;
      bind-address = "127.0.0.1";
      db-type = "sqlite";
      db-address = "/srv/gotosocial/sqlite.db";
      storage-local-base-path = "/srv/gotosocial/storage";
      accounts-registration-open = false;
      accounts-allow-custom-css = false;
      letsencrypt-enabled = false;
      trusted-proxies = [
        "127.0.0.1/32"
        # Cloudflare IPv4 ranges — required because requests arrive via CF → Caddy → GTS
        # and GTS needs to trust the full proxy chain to resolve the real client IP.
        # https://www.cloudflare.com/ips-v4/
        "173.245.48.0/20"
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "141.101.64.0/18"
        "108.162.192.0/18"
        "190.93.240.0/20"
        "188.114.96.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
        "162.158.0.0/15"
        "104.16.0.0/13"
        "104.24.0.0/14"
        "172.64.0.0/13"
        "131.0.72.0/22"
      ];
      # Tell federation partners this is an English-language instance.
      landing-page-user = "ewan";
      instance-languages = [ "en" ];
      # Persist the Wazero/WASM ffmpeg compilation cache across restarts.
      # Without this GoToSocial recompiles on every cold start (~100MiB, slow).
      wazero-compilation-cache = "/srv/gotosocial/wazero-cache";
      # SMTP via Resend — useful for password resets even on a single-user instance.
      smtp-host = "smtp.resend.com";
      smtp-port = 587;
      smtp-username = "resend";
      smtp-from = "gts@server.ewancroft.uk";
      # Emoji
      media-emoji-local-max-size = 500 KiB;
    };
  };

  systemd.services.gotosocial = {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
    serviceConfig = {
      ReadWritePaths = [ "/srv/gotosocial" ];
      Restart = lib.mkForce "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
    };
    unitConfig = {
      StartLimitIntervalSec = cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst = cfg.server.servicePolicy.startLimitBurst;
    };
  };

  services.caddy.virtualHosts."http://${gts.hostname}:${caddyPort}" = {
    extraConfig = ''
      handle {
        reverse_proxy http://127.0.0.1:${gtsPort} {
          # Cloudflare tunnel passes CF-Connecting-IP with the real client IP.
          # Forward it as X-Real-IP so GTS can resolve the actual remote address.
          header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
          header_up X-Real-IP {http.request.header.CF-Connecting-IP}
        }
        header Cache-Control "no-store, private"
      }
    '';
  };
}
