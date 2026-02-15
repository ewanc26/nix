{ config, pkgs, lib, ... }:

let
  cfg = import ../../settings/config.nix;
in
{
  # Common Darwin (macOS) settings shared across all hosts

  # Enable zsh system-wide
  programs.zsh.enable = true;

  nix = {
    # Explicit nix management via nix-darwin.
    # NOTE: Set `nix.enable = false` if you use Determinate Nix, which manages
    # the nix daemon itself and conflicts with nix-darwin's native management.
    enable  = true;
    package = pkgs.nix;

    settings = {
      experimental-features = cfg.nix.experimentalFeatures;

      # IMPORTANT: Disable store optimisation on macOS.
      # `auto-optimise-store = true` triggers a kernel bug on macOS that causes
      # build failures:  https://github.com/NixOS/nix/issues/7273
      # Use `nix store optimise` manually when needed instead.
      auto-optimise-store = false;

      # Allow the primary user to use trusted nix operations (e.g. adding
      # substituters) without requiring root.
      trusted-users = [ "root" cfg.user.username ];
    };

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
