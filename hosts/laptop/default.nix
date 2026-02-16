{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/users.nix
    ../../modules/desktop.nix
    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/gaming.nix
  ];

  networking.hostName = "laptop";

  # Firewall – trust Tailscale for inter-host SSH
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };

  # Audio – backend driven from settings/config/audio.nix
  security.rtkit.enable = cfg.audio.enable;
  services.pipewire = lib.mkIf (cfg.audio.enable && cfg.audio.backend == "pipewire") {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    jack.enable       = true;
  };

  system.stateVersion = cfg.system.stateVersion;
}
