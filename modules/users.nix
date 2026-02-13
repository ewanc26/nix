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
    openssh.authorizedKeys.keys = [
      # Mac Mini (primary machine)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcEH7Belx/vpnmuspyAc/3iIAFqtxKGeftG5z5vBsUv git@ewancroft.uk"
    ];
  };
}
