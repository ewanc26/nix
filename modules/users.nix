{ config, pkgs, lib, ... }:

let
  allKeys = import ./ssh-keys.nix;
  authorizedKeys = lib.attrValues (lib.filterAttrs (name: _: name != config.networking.hostName) allKeys);
in
{
  # Standard user configuration for ewan
  # Can be imported by any NixOS host

  users.users.ewan = {
    isNormalUser = true;
    description = "Ewan";
    extraGroups = [ "networkmanager" "wheel" ] 
      ++ lib.optionals (config.services.pipewire.enable or false) [ "audio" "video" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = authorizedKeys;
  };
}
