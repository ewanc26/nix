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
  imports = [
    ./hardware-configuration.nix
    ../../modules/users.nix
    ../../modules/desktop.nix
    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/gaming.nix
  ];

  myConfig.isDesktop = true;
  myConfig.gaming.enable = true;
  myConfig.forgejo.userApiTokenFile = "/home/${config.myConfig.user.username}/.config/forgejo-user-token";

  networking.hostName = "laptop";

  # Firewall – trust Tailscale for inter-host SSH
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };

  # Audio – backend driven from myConfig.audio
  security.rtkit.enable = cfg.audio.enable;
  services.pipewire = lib.mkIf (cfg.audio.enable && cfg.audio.backend == "pipewire") {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Allow passwordless sudo for nixos-rebuild so remote one-liners work over SSH
  # (no TTY is available in that context). Other sudo commands still require a password.
  # The server keeps wheelNeedsPassword = true; this exception is laptop-only.
  security.sudo.extraRules = [
    {
      users = [ cfg.user.username ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # After auto-upgrade commits the updated flake.lock, run any pre-commit hooks
  # then push. Runs as the user so SSH keys are available.
  systemd.services.nixos-upgrade-push = {
    description = "Push flake.lock commit after nixos-upgrade";
    after = [ "nixos-upgrade.service" ];
    requires = [ "nixos-upgrade.service" ];
    wantedBy = [ "nixos-upgrade.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = cfg.user.username;
      WorkingDirectory = "/home/${cfg.user.username}/.config/nix-config";
    };
    path = with pkgs; [
      git
      nix
    ];
    script = ''
      if [ -x .git/hooks/pre-commit ]; then
        .git/hooks/pre-commit || exit 1
      fi
      git push
    '';
  };

  system.stateVersion = cfg.stateVersion;
}
