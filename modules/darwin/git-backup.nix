{ config, pkgs, ... }:

{
  # LaunchAgent for automatic git backup
  launchd.user.agents.nix-config-backup = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "/Users/ewan/.config/nix-config/scripts/auto-backup.sh"
      ];
      StartInterval = 21600;  # Run every 6 hours (in seconds)
      RunAtLoad = true;  # Run on login
      StandardOutPath = "/Users/ewan/Library/Logs/nix-config-backup.log";
      StandardErrorPath = "/Users/ewan/Library/Logs/nix-config-backup.error.log";
      WorkingDirectory = "/Users/ewan/.config/nix-config";
    };
  };
  
  # Note: Git hooks setup is handled in modules/darwin/common.nix
}
