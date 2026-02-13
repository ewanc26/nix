{ config, pkgs, lib, ... }:

{
  # Common Darwin (macOS) settings shared across all hosts
  
  # Enable zsh system-wide
  programs.zsh.enable = true;
  
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
    
    # Auto-optimize nix store (new format)
    optimise.automatic = true;
    
    # Automatic garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
  };
  
  # NOTE: system.autoUpgrade doesn't exist in nix-darwin
  # To auto-update, you need to manually create a launchd service
  # For now, run: darwin-rebuild switch --flake ~/.config/nix-config#macmini
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # NOTE: services.nix-daemon.enable is no longer needed
  # nix-darwin manages nix-daemon automatically when nix.enable is on
  
  # Activation script for git hooks
  system.activationScripts.postActivation.text = ''
    # Setup git hooks
    if [ -d /Users/ewan/.config/nix-config/.git ]; then
      ${pkgs.bash}/bin/bash /Users/ewan/.config/nix-config/scripts/setup-hooks.sh
    fi
    
    # Ensure nix-darwin config is always accessible
    echo "Configuration is managed at /Users/ewan/.config/nix-config"
  '';
}
