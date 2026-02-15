{ config, pkgs, lib, ... }:

let
  cfg = import ../../settings/config.nix;
in
{
  imports = [
    ../../modules/darwin/common.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/system.nix
  ];

  # Primary user for homebrew and user-specific options
  system.primaryUser = cfg.user.username;

  networking = {
    hostName     = "macmini";
    computerName = "MacMini";
  };

  # SMB/NetBIOS hostname (used by network discovery and file sharing)
  system.defaults.smb.NetBIOSName = "macmini";

  # Timezone
  time.timeZone = "Europe/London";

  users.users.${cfg.user.username} = {
    home  = "/Users/${cfg.user.username}";
    shell = pkgs.${cfg.user.shell};
  };

  # nix-darwin uses an integer for stateVersion
  system.stateVersion = 5;
}
