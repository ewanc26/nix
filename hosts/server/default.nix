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
    ../../modules/cockpit.nix
    ../../modules/cloudflare-tunnel.nix
    ../../modules/pds.nix
    ../../modules/forgejo.nix
    ../../profiles/server-hardened.nix
  ];

  # Service toggles
  myConfig.services.forgejo.enable = false;
  myConfig.services.pds.enable = true;
  myConfig.services.cloudflare.enable = true;

  # Ignore laptop lid — treat as headless, never suspend
  services.logind.lidSwitch = "ignore";
  services.logind.lidSwitchExternalPower = "ignore";
  services.logind.lidSwitchDocked = "ignore";
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  networking.hostName = "server";

  # Boot – clean /tmp on every boot
  boot.tmp.cleanOnBoot = true;

  # sudo requires password
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  system.stateVersion = cfg.stateVersion;
}
