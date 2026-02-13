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
    
    # Automatic garbage collection - runs weekly
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };  # Every Sunday at 2 AM
      options = "--delete-older-than 30d";  # Delete generations older than 30 days
    };
  };
  
  # NOTE: system.autoUpgrade doesn't exist in nix-darwin
  # To auto-update, you need to manually create a launchd service
  # For now, run: darwin-rebuild switch --flake ~/.config/nix-config#macmini
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
