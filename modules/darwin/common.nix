# Common Darwin (macOS) settings shared across all hosts.
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
  programs.zsh.enable = true;

  nix = {
    # Explicit nix management via nix-darwin.
    # NOTE: Set `nix.enable = false` if you use Determinate Nix, which manages
    # the nix daemon itself and conflicts with nix-darwin's native management.
    enable = true;
    package = pkgs.nix;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # IMPORTANT: Disable store optimisation on macOS.
      # `auto-optimise-store = true` triggers a kernel bug on macOS that causes
      # build failures: https://github.com/NixOS/nix/issues/7273
      # Use `nix store optimise` manually when needed instead.
      auto-optimise-store = false;

      # Allow the primary user to use trusted nix operations (e.g. adding
      # substituters) without requiring root.
      trusted-users = [
        "root"
        cfg.user.username
      ];

      # Storage pressure management — keep the Nix store from ballooning on
      # a 256 GB disk. Nix will trigger GC automatically when free space on
      # the store volume drops below min-free, stopping once max-free is reached.
      # Values are in bytes: 5 GiB min-free, 10 GiB max-free.
      min-free = 5368709120; # 5 GiB
      max-free = 10737418240; # 10 GiB

      # Do not retain build-time inputs or derivations after a successful build.
      # These are only needed for `nix develop` / `nix-shell` workflows; keeping
      # them on a space-constrained machine is not worth it.
      keep-outputs = false;
      keep-derivations = false;
    };

    # Automatic garbage collection (macOS launchd schedule)
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      }; # Every Sunday at 02:00
      # Keep only the last 14 days of generations on the space-constrained
      # 256 GB Mac. Linux hosts retain 30 days (set in modules/common.nix).
      options = "--delete-older-than 14d";
    };
  };

  # NOTE: system.autoUpgrade does not exist in nix-darwin.
  # Run manually: darwin-rebuild switch --flake ~/.config/nix-config#macmini

  # Symlink tracked hooks into .git/hooks so they're always up to date.
  # nix-darwin only executes hardcoded script names, so we append to postActivation
  # rather than using a custom name (which would be silently ignored).
  system.activationScripts.postActivation.text = lib.mkAfter ''
    REPO="/Users/${cfg.user.username}/.config/nix-config"
    if [ -d "$REPO/.git" ]; then
      ln -sf "$REPO/hooks/pre-commit" "$REPO/.git/hooks/pre-commit"
      chmod +x "$REPO/hooks/pre-commit"
    fi
  '';
}
