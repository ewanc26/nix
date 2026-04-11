{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
in
{
  imports = [
    ./minimal-hardware.nix
    ../../modules/users.nix
    ../../modules/server/infra/network/caddy.nix
    ../../modules/server/infra/network/split-dns.nix
    ../../modules/server/infra/network/cloudflare-tunnel.nix
    ../../modules/server/services/atproto/pds.nix
    ../../modules/server/services/atproto/pds-gatekeeper.nix
    ../../modules/server/services/forge/forgejo.nix
    ../../modules/server/services/nextcloud/nextcloud.nix
    ../../modules/server/services/media/immich.nix
    ../../modules/server/services/media/jellyfin.nix
    ../../modules/server/services/observability/grafana.nix
    ../../modules/server/services/utils/vaultwarden.nix
    ../../modules/server/services/utils/timemachine.nix
    ../../modules/server/services/fediverse/sharkey.nix
    ../../modules/profiles/server-hardened.nix
  ];

  # Service toggles
  myConfig.services.forgejo.enable = true;
  myConfig.services.nextcloud.enable = true; # Tailnet-only — not in CF tunnel
  myConfig.services.immich.enable = true; # Tailnet-only — not in CF tunnel
  myConfig.services.jellyfin.enable = true; # Tailnet-only — not in CF tunnel
  myConfig.services.pds.enable = false;
  myConfig.pds.serviceHandleDomains = [
    ".pds.ewancroft.uk"
    ".pds.croft.click"
  ];
  myConfig.services.pdsGatekeeper.enable = false;
  myConfig.services.cloudflare.enable = true;
  myConfig.services.vaultwarden.enable = true; # Tailnet-only — password manager, never public
  myConfig.services.timemachine.enable = true; # Tailnet-only — Time Machine AFP target
  myConfig.services.sharkey.enable = false;

  # ── Umami (native nixpkgs module) ───────────────────────────────────────────
  sops.secrets."umami-app-secret" = {
    sopsFile = ../../secrets/umami-app-secret;
    owner = "umami";
    group = "umami";
    mode = "0400";
  };

  # Create system user for PostgreSQL peer auth (native module uses DynamicUser)
  users.users.umami = {
    isSystemUser = true;
    group = "umami";
  };
  users.groups.umami = { };

  services.umami = {
    enable = true;
    settings = {
      APP_SECRET_FILE = "/run/secrets/umami-app-secret";
      HOSTNAME = "127.0.0.1";
      PORT = 3010;
      DISABLE_TELEMETRY = true;
    };
  };

  # Override DynamicUser with static user for PostgreSQL peer auth
  systemd.services.umami.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "umami";
    Group = "umami";
    LoadCredential = "appSecret:/run/secrets/umami-app-secret";
  };

  # Caddy reverse proxy for Cloudflare tunnel
  services.caddy.virtualHosts."http://analytics.ewancroft.uk:3011" = {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:3010 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
      }
    '';
  };

  # Ignore laptop lid — treat as headless, never suspend.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # ── Tailscale ─────────────────────────────────────────────────────────────
  # Set to the output of `tailscale ip -4` on the server.
  # This enables split-dns.nix (CoreDNS) and the tailnet Caddy vhosts.
  myConfig.server.tailscaleIP = "100.78.91.100";

  networking.hostName = "server";

  # Boot – clean /tmp on every boot
  boot.tmp.cleanOnBoot = true;

  # sudo requires password
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Global git config for root (needed by nixos-upgrade to commit lock files)
  environment.etc."gitconfig".text = ''
    [user]
      name = NixOS Upgrade
      email = root@server.local
  '';

  # Don't commit flake.lock on the server — it never pushes, so local commits
  # would just diverge from the laptop's pushed updates.
  system.autoUpgrade.flags = [
    "--update-input"
    "nixpkgs"
  ];

  system.stateVersion = cfg.stateVersion;
}
