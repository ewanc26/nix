{ config, pkgs, lib, ... }:

{
  # Standard user configuration for ewan
  # Can be imported by any NixOS host
  
  users.users.ewan = {
    isNormalUser = true;
    description = "Ewan";
    extraGroups = [ "networkmanager" "wheel" ] 
      ++ lib.optionals (config.services.pipewire.enable or false) [ "audio" "video" ];
    shell = pkgs.zsh;
  };
}
