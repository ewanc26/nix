# Common Darwin (macOS) settings shared across all hosts.
{
  config,
  lib,
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
  '';
}
