{ config, pkgs, lib, ... }:

# NOTE: This file is a legacy entry point kept for compatibility.
# The canonical host configuration lives in hosts/laptop/default.nix.
# All configurable values come from settings/config/.

let
  cfg = import ./settings/config.nix;
in
{
  imports = [
    ./modules/desktop.nix
    ./modules/packages.nix
    ./modules/services.nix
    ./modules/gaming.nix
    ./modules/secrets.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable      = cfg.system.boot.loader == "systemd-boot";
      efi.canTouchEfiVariables = true;
    };
    kernelPackages =
      if cfg.system.kernel.useLatest then pkgs.linuxPackages_latest else pkgs.linuxPackages;
  };

  networking = {
    hostName                  = "laptop";
    networkmanager.enable     = cfg.system.network.enableNetworkManager;
  };

  time.timeZone       = cfg.system.timeZone;
  i18n.defaultLocale  = cfg.system.locale;

  console = {
    font   = "Lat2-Terminus16";
    keyMap = "uk";
  };

  # Audio
  security.rtkit.enable = cfg.audio.enable;
  services.pipewire = lib.mkIf (cfg.audio.enable && cfg.audio.backend == "pipewire") {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    jack.enable       = true;
  };

  users.users.${cfg.user.username} = {
    isNormalUser  = true;
    description   = cfg.user.fullName;
    extraGroups   = [ "networkmanager" "wheel" "audio" "video" ];
    shell         = pkgs.${cfg.user.shell};
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';

  programs.zsh.enable = true;

  nix.settings.experimental-features = cfg.nix.experimentalFeatures;

  system.stateVersion = cfg.system.stateVersion;
}
