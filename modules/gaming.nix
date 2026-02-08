{ config, pkgs, ... }:

{
  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # GameMode for performance optimization
  programs.gamemode.enable = true;

  # Enable 32-bit graphics support for gaming
  hardware.graphics.enable32Bit = true;

  # Additional gaming packages
  environment.systemPackages = with pkgs; [
    mangohud  # Performance overlay
    gamescope # Gaming compositor
  ];
}
