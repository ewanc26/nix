{ config, pkgs, lib, ... }:

{
  # Common NixOS settings shared across all hosts
  
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Enable zsh system-wide
  programs.zsh.enable = true;
  
  # Automatic file placement - symlink config to correct locations
  system.activationScripts.linkConfigs = ''
    # Ensure config directory exists and is properly linked
    mkdir -p /etc/nixos
    if [ ! -L /etc/nixos ]; then
      rm -rf /etc/nixos
      ln -sf /home/ewan/.config/nix-config /etc/nixos
    fi
  '';
  
  # Auto-update system configuration
  system.autoUpgrade = {
    enable = true;
    flake = "/home/ewan/.config/nix-config";
    flags = [
      "--update-input" "nixpkgs"
      "--commit-lock-file"
    ];
    dates = "daily";
    randomizedDelaySec = "45min";
  };
  
  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  
  # Optimize nix store automatically
  nix.settings.auto-optimise-store = true;
  
  # Default timezone and locale (can be overridden per host)
  time.timeZone = lib.mkDefault "Europe/London";
  i18n.defaultLocale = lib.mkDefault "en_GB.UTF-8";
  
  # Console configuration defaults
  console = {
    font = lib.mkDefault "Lat2-Terminus16";
    keyMap = lib.mkDefault "uk";
  };
  
  # NetworkManager enabled by default
  networking.networkmanager.enable = lib.mkDefault true;
  
  # Boot configuration defaults
  boot = {
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };
}
