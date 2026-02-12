{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/users.nix
    ../../modules/desktop.nix
    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/gaming.nix
    ../../modules/git-backup.nix
  ];

  # Networking
  networking.hostName = "laptop";

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # System version
  system.stateVersion = "25.11";
}
