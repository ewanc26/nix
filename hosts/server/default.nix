{
  config,
  ...
}:
let
  cfg = config.myConfig;
in
{
  imports = [
    ./minimal-hardware.nix
    ../../modules/users.nix
    ../../modules/caddy.nix
    ../../modules/split-dns.nix
    ../../modules/cloudflare-tunnel.nix
    ../../modules/pds.nix
    ../../modules/forgejo.nix
    ../../modules/nextcloud.nix
    ../../modules/immich.nix
    ../../modules/jellyfin.nix
    ../../profiles/server-hardened.nix
  ];

  # Service toggles
  myConfig.services.forgejo.enable = true;
  myConfig.services.nextcloud.enable = true; # Tailnet-only — not in CF tunnel
  myConfig.services.immich.enable = true; # Tailnet-only — not in CF tunnel
  myConfig.services.jellyfin.enable = true; # Tailnet-only — not in CF tunnel
  myConfig.services.pds.enable = true;
  myConfig.services.cloudflare.enable = true;

  # Ignore laptop lid — treat as headless, never suspend
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
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

  # Don't commit flake.lock on the server — it never pushes, so local commits
  # would just diverge from the laptop's pushed updates.
  system.autoUpgrade.flags = [
    "--update-input"
    "nixpkgs"
  ];

  system.stateVersion = cfg.stateVersion;
}
