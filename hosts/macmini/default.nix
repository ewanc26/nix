{
  config,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;
in
{
  imports = [
    ../../modules/darwin/common.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/system.nix
    ../../modules/darwin/launch-services.nix
    ../../modules/darwin/gatekeeper.nix
  ];

  # Primary user for homebrew and user-specific options
  system.primaryUser = cfg.user.username;

  networking = {
    hostName = "macmini";
    computerName = "MacMini";
  };

  # SMB/NetBIOS hostname (used by network discovery and file sharing)
  system.defaults.smb.NetBIOSName = "macmini";

  # ── External disk (CT2000X9SSD9, APFS container on disk4s2) ───────────────
  # See docs/time-machine.md for first-time setup instructions.
  myConfig.darwin.externalDisk.timeMachineVolumeUUID = "9217DB34-722B-4596-8ADD-20C8060FC257";

  # Timezone — driven from myConfig.timeZone
  time.timeZone = cfg.timeZone;

  users.users.${cfg.user.username} = {
    home = "/Users/${cfg.user.username}";
    shell = pkgs.zsh;
  };

  # nix-darwin uses an integer for stateVersion
  system.stateVersion = 5;
}
