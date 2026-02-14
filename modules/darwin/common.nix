{ config, pkgs, lib, ... }:

let
  cfg = import ../../settings/config.nix;
in
{
  # Common Darwin (macOS) settings shared across all hosts

  # Enable zsh system-wide
  programs.zsh.enable = true;

  nix = {
    settings = {
      experimental-features = cfg.nix.experimentalFeatures;
    };

    # Auto-optimise nix store
    optimise.automatic = cfg.nix.autoOptimise;

    # Automatic garbage collection (macOS launchd schedule)
    gc = {
      automatic = cfg.nix.gc.automatic;
      interval  = { Weekday = 0; Hour = 2; Minute = 0; };  # Every Sunday at 02:00
      options   = cfg.nix.gc.options;
    };
  };

  # NOTE: system.autoUpgrade does not exist in nix-darwin.
  # Run manually: darwin-rebuild switch --flake ~/.config/nix-config#macmini
}
