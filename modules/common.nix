# Common NixOS settings shared across all hosts.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  programs.zsh.enable = true;

  # Symlink config repo into /etc/nixos for convenience.
  system.activationScripts.linkConfigs = ''
    mkdir -p /etc/nixos
    if [ ! -L /etc/nixos ]; then
      rm -rf /etc/nixos
      ln -sf /home/${cfg.user.username}/.config/nix-config /etc/nixos
    fi
  '';

  system.autoUpgrade = {
    enable = true;
    flake = "/home/${cfg.user.username}/.config/nix-config";
    flags = [
      "--update-input"
      "nixpkgs"
      "--commit-lock-file"
    ];
    dates = "daily";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };

  time.timeZone = lib.mkDefault cfg.timeZone;
  i18n.defaultLocale = lib.mkDefault cfg.locale;

  console = {
    font = lib.mkDefault "Lat2-Terminus16";
    keyMap = lib.mkDefault "uk";
  };

  networking.networkmanager.enable = lib.mkDefault true;

  boot = {
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  # sops-nix: decrypt secrets using the host's SSH ed25519 key as an age key.
  # This key is generated on first boot and lives outside the Nix store.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
