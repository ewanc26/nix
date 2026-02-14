{ config, pkgs, lib, ... }:

let
  cfg = import ../settings/config.nix;
  allKeys = import ./ssh-keys.nix;
  authorizedKeys = lib.attrValues (lib.filterAttrs (name: _: name != config.networking.hostName) allKeys);
  
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
