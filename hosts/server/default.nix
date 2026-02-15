{ cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  imports = [
    ./minimal-hardware.nix
    ../../modules/common.nix
    ../../modules/users.nix
    ../../modules/pds.nix
    ../../profiles/server-hardened.nix
  ];

  networking.hostName = "server";

  # Boot – clean /tmp on every boot
  boot.tmp.cleanOnBoot = true;

  # sudo requires password
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  system.stateVersion = cfg.system.stateVersion;
}
