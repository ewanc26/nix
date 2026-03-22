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

  # Allow the nixos-upgrade service (runs as root) to read the flake repo
  # owned by the regular user. Without this, git 2.35.2+ refuses to open
  # repos not owned by the calling user (CVE-2022-24765 mitigation).
  system.activationScripts.nixosUpgradeGitSafeDir = ''
    ${pkgs.git}/bin/git config --global --add safe.directory /home/${cfg.user.username}/.config/nix-config
  '';

  # Symlink tracked hooks into .git/hooks so they're always up to date.
  system.activationScripts.installGitHooks = ''
    REPO="/home/${cfg.user.username}/.config/nix-config"
    HOOK="$REPO/.git/hooks/pre-commit"
    TARGET="$REPO/hooks/pre-commit"
    if [ -d "$REPO/.git" ]; then
      # Only (re)create the symlink if it's missing or points somewhere else.
      if [ "$(readlink "$HOOK" 2>/dev/null)" != "$TARGET" ]; then
        ln -sf "$TARGET" "$HOOK"
        chmod +x "$TARGET"
      fi
    fi
  '';

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

  # Forgejo user API token — decrypted at system level (root) so it lands at
  # /run/secrets/forgejo-user-token with user ownership, readable by the
  # home-manager activation script without requiring user-level sops access.
  sops.secrets."forgejo-user-token" = {
    sopsFile = ../secrets/forgejo-user-token;
    format = "binary";
    owner = cfg.user.username;
  };
}
