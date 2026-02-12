{ config, pkgs, ... }:

{
  # Systemd service for automatic git backup
  systemd.user.services.nix-config-backup = {
    description = "Automatic backup of Nix configuration to git";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /home/ewan/.config/nix-config/scripts/auto-backup.sh";
      WorkingDirectory = "/home/ewan/.config/nix-config";
    };
  };

  # Systemd timer to run backup every 6 hours
  systemd.user.timers.nix-config-backup = {
    description = "Timer for automatic Nix configuration backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15min";  # First run 15 min after boot
      OnUnitActiveSec = "6h";  # Then every 6 hours
      Persistent = true;  # Run missed timers on boot
    };
  };

  # Setup git hooks on activation (common with Darwin)
  system.activationScripts.setupGitHooks = ''
    if [ -d /home/ewan/.config/nix-config/.git ]; then
      ${pkgs.bash}/bin/bash /home/ewan/.config/nix-config/scripts/setup-hooks.sh
    fi
  '';
}
