{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  # Common NixOS settings shared across all hosts

  # Enable flakes and nix command
  nix.settings.experimental-features = cfg.nix.experimentalFeatures;

  # Nix store optimisation
  nix.settings.auto-optimise-store = cfg.nix.autoOptimise;

  # Automatic garbage collection
  nix.gc = {
    automatic = cfg.nix.gc.automatic;
    dates     = cfg.nix.gc.dates;
    options   = cfg.nix.gc.options;
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Symlink config repo into /etc/nixos for convenience
  system.activationScripts.linkConfigs = ''
    mkdir -p /etc/nixos
    if [ ! -L /etc/nixos ]; then
      rm -rf /etc/nixos
      ln -sf /home/${cfg.user.username}/.config/nix-config /etc/nixos
    fi
  '';

  # Automatic system upgrades
  system.autoUpgrade = {
    enable            = cfg.maintenance.autoUpgrade.enable;
    flake             = "/home/${cfg.user.username}/.config/nix-config";
    flags             = map (i: "--update-input ${i}") cfg.maintenance.autoUpgrade.updateInputs
                        ++ [ "--commit-lock-file" ];
    dates             = cfg.maintenance.autoUpgrade.dates;
    randomizedDelaySec = cfg.maintenance.autoUpgrade.randomizedDelaySec;
    allowReboot       = cfg.maintenance.autoUpgrade.allowReboot;
  };

  # Default timezone and locale (can be overridden per host)
  time.timeZone         = lib.mkDefault cfg.system.timeZone;
  i18n.defaultLocale    = lib.mkDefault cfg.system.locale;

  # Console configuration defaults
  console = {
    font   = lib.mkDefault "Lat2-Terminus16";
    keyMap = lib.mkDefault "uk";
  };

  # Networking
  networking.networkmanager.enable = lib.mkDefault cfg.system.network.enableNetworkManager;

  # Boot configuration defaults
  boot = {
    loader = {
      systemd-boot.enable     = lib.mkDefault (cfg.system.boot.loader == "systemd-boot");
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    kernelPackages = lib.mkDefault (
      if cfg.system.kernel.useLatest then pkgs.linuxPackages_latest else pkgs.linuxPackages
    );
  };
}
