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

  # Service toggles — all services run on the server.
  myConfig.services.forgejo.enable = true;
  myConfig.services.pds.enable = true;
  myConfig.services.cloudflare.enable = true;

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
