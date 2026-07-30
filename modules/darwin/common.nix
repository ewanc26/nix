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

  # NOTE: Set `nix.enable = false` if you use Determinate Nix, which manages
  # the nix daemon itself and conflicts with nix-darwin's native management.
  nix.enable = false;

  # With nix.enable = false, nix-darwin writes no /etc/nix/nix.conf at all, so
  # every `nix.settings.*` here is silently discarded (verified: the darwin
  # config emits no environment.etc."nix/nix.conf"). Daemon settings such as
  # auto-optimise-store belong in Determinate's own config instead:
  #   /etc/nix/nix.custom.conf

  launchd.daemons.nix-collect-garbage = {
    serviceConfig = {
      Label = "org.nix-darwin.nix-collect-garbage";
      ProgramArguments = [
        "${pkgs.nix}/bin/nix-collect-garbage"
        "--delete-older-than"
        "30d"
      ];
      StartCalendarInterval = {
        Hour = 3;
        Minute = 0;
      };
      RunAtLoad = true;
      StandardOutPath = "/tmp/nix-collect-garbage.log";
      StandardErrorPath = "/tmp/nix-collect-garbage.err";
    };
  };

  # NOTE: system.autoUpgrade does not exist in nix-darwin.
  # Run manually: darwin-rebuild switch --flake ~/.config/nix-config#macmini

  # Symlink tracked hooks into .git/hooks so they're always up to date.
  # nix-darwin only executes hardcoded script names, so we append to postActivation
  # rather than using a custom name (which would be silently ignored).
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # Clean up stale nix-darwin launchd services left over from nix.enable = true.
    for svc in org.nixos.nix-daemon org.nixos.nix-gc; do
      if /bin/launchctl list "$svc" &>/dev/null; then
        /bin/launchctl bootout system "$svc" 2>/dev/null || true
        echo "postActivation: booted out stale service $svc"
      fi
    done

    REPO="/Users/${cfg.user.username}/.config/nix-config"
    if [ -d "$REPO/.git" ]; then
      ln -sf "$REPO/hooks/pre-commit" "$REPO/.git/hooks/pre-commit"
      chmod +x "$REPO/hooks/pre-commit"
    fi

    # Reload the Dock after activation so any Homebrew-installed apps
    # (e.g. Element, Spotify) that were absent when the dock plist was
    # written are picked up cleanly.
    killall Dock 2>/dev/null || true
  '';
}
