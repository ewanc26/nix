# Steam / gaming support. Active only when myConfig.gaming.enable = true.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig;
in
{
  programs.steam = lib.mkIf cfg.gaming.enable {
    enable = cfg.gaming.steam.enable;
    remotePlay.openFirewall = cfg.gaming.steam.openFirewall;
    dedicatedServer.openFirewall = cfg.gaming.steam.openFirewall;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = lib.mkIf cfg.gaming.enable cfg.gaming.steam.enable;

  hardware.graphics.enable32Bit = lib.mkIf cfg.gaming.enable true;

  environment.systemPackages = lib.optionals cfg.gaming.enable (with pkgs; [
    mangohud
    gamescope
  ]);
}
