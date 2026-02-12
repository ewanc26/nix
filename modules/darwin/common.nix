{ config, pkgs, lib, ... }:

{
  # Common Darwin (macOS) settings shared across all hosts
  
  # Enable zsh system-wide
  programs.zsh.enable = true;
  
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Auto-optimize nix store
      auto-optimise-store = true;
    };
    
    # Automatic garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
  };
  
  # Auto-update system
  system.autoUpgrade = {
    enable = true;
    operation = "switch";
    flake = "/Users/ewan/.config/nix-config";
    flags = [
      "--update-input" "nixpkgs"
      "--update-input" "nixpkgs-darwin"
      "--commit-lock-file"
    ];
  };
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Auto upgrade nix package and the daemon service
  services.nix-daemon.enable = true;
  
  # Activation script for git hooks
  system.activationScripts.postActivation.text = ''
    # Setup git hooks
    if [ -d /Users/ewan/.config/nix-config/.git ]; then
      ${pkgs.bash}/bin/bash /Users/ewan/.config/nix-config/scripts/setup-hooks.sh
    fi
    
    # Ensure nix-darwin config is always accessible
    echo "Configuration is managed at /Users/ewan/.config/nix-config"
    echo "Auto-updates are enabled and will run automatically"
  '';
}
