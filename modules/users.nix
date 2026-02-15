{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;  # Use config from cfgLib instead of importing
  authorizedKeys = cfgLib.mkAuthorizedKeys config.networking.hostName;
  shellPkg = if cfg.user.shell == "zsh" then pkgs.zsh else pkgs.bash;
in
{
  # Standard user configuration
  # Can be imported by any NixOS host

  users.users.${cfg.user.username} = {
    isNormalUser = true;
    description = cfg.user.fullName;
    extraGroups = [ "networkmanager" "wheel" ] 
      ++ lib.optionals (config.services.pipewire.enable or false) [ "audio" "video" ];
    shell = shellPkg;
    openssh.authorizedKeys.keys = authorizedKeys;
  };
}
