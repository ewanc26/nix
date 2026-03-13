##############################################################################
#  PDS Gatekeeper — 2FA proxy for the ATProto PDS.
#
#  By Bailey Townsend; NixOS module and package by Isabel (tgirlcloud/pkgs).
#  Sits between Caddy and the PDS for a small set of auth endpoints,
#  adding TOTP-based two-factor authentication on top of the standard
#  ATProto login flow.
#
#  Architecture:
#    Caddy (auth routes only)
#      ↓ reverse_proxy
#    PDS Gatekeeper (127.0.0.1:3602)
#      ↓ proxies upstream to
#    PDS (127.0.0.1:cfg.pds.port)
#
#  Prerequisites:
#    - myConfig.services.pds.enable = true   (pds.nix must be imported)
#    - tgirlpkgs.nixosModules.default         (wired in via flake.nix)
#    - secrets/pds.env sops secret            (shared with bluesky-pds)
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

  gkHost = "127.0.0.1";
  gkPort = 3602;
  gkUrl = "http://${gkHost}:${toString gkPort}";
in
lib.mkIf cfg.services.pdsGatekeeper.enable {

  # ── Permissions ────────────────────────────────────────────────────────────
  # The pds.env sops secret is owned by pds:pds. Widen to group-readable so
  # the gatekeeper service (added to the pds group below) can read it.
  sops.secrets."pds.env".mode = lib.mkForce "0440";

  # ── PDS Gatekeeper service ─────────────────────────────────────────────────
  services.pds-gatekeeper = {
    enable = true;
    environmentFiles = [ config.sops.secrets."pds.env".path ];
    settings = {
      GATEKEEPER_HOST = gkHost;
      GATEKEEPER_PORT = gkPort;
      PDS_BASE_URL = "http://127.0.0.1:${pdsPort}";
      PDS_HOSTNAME = pds.hostname;
      PDS_DATA_DIRECTORY = "/srv/bluesky-pds";
      GATEKEEPER_TRUST_PROXY = "true";
      # Gatekeeper expects a .env file path; supply an empty nix-store file
      # so it doesn't error on startup (secrets come via environmentFiles).
      PDS_ENV_LOCATION = toString (pkgs.writeText "gatekeeper-pds-env" "");
    };
  };

  # ── Systemd tweaks ─────────────────────────────────────────────────────────
  systemd.services.pds-gatekeeper = {
    after = [ "bluesky-pds.service" ];
    wants = [ "bluesky-pds.service" ];
    serviceConfig = {
      # Allow reading the pds:pds group-owned sops secret.
      SupplementaryGroups = [ "pds" ];
      Restart = "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
    };
    unitConfig = {
      StartLimitIntervalSec = cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst = cfg.server.servicePolicy.startLimitBurst;
    };
  };

  # ── Caddy routes ───────────────────────────────────────────────────────────
  # These four endpoints are intercepted by gatekeeper before the catch-all
  # reverse_proxy in pds.nix. lib.mkBefore ensures they appear first in the
  # merged extraConfig string so Caddy evaluates them with higher priority.
  services.caddy.virtualHosts."http://${pds.hostname}:${caddyPort}".extraConfig = lib.mkBefore ''
    handle /xrpc/com.atproto.server.createSession {
      reverse_proxy ${gkUrl}
    }
    handle /xrpc/com.atproto.server.getSession {
      reverse_proxy ${gkUrl}
    }
    handle /xrpc/com.atproto.server.updateEmail {
      reverse_proxy ${gkUrl}
    }
    handle /@atproto/oauth-provider/~api/sign-in {
      reverse_proxy ${gkUrl}
    }
  '';
}
