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

    # Decrypt sops secrets to local files for shell env vars.
    # macOS doesn't have sops-nix (NixOS-only), so we decrypt at activation time.
    # Faol secrets live in the lettabot faol config directory.
    #
    # These stay on the age key on purpose, even though the user recipient for
    # this repo's secrets/ is now a PGP key (see .sops.yaml). Activation runs as
    # root with no controlling terminal, so gpg-agent has nowhere to prompt for
    # a passphrase; an age keyfile decrypts unattended. These files live outside
    # the repo and are not covered by .sops.yaml's creation rules, so they are
    # unaffected by the PGP migration.
    FAOL_DIR="/Volumes/Storage/Developer/Local/lettabot/faol"
    AGE_KEY="/Users/${cfg.user.username}/.config/age/keys.txt"
    if [ -f "$AGE_KEY" ]; then
      # Telegram bot token for Faol
      SOPS_AGE_KEY_FILE="$AGE_KEY" ${pkgs.sops}/bin/sops --decrypt \
        --input-type binary --output-type binary \
        "$FAOL_DIR/telegram-bot-token" \
        > "/Users/${cfg.user.username}/.config/telegram-bot-token" 2>/dev/null \
        && chmod 600 "/Users/${cfg.user.username}/.config/telegram-bot-token" \
        && echo "postActivation: decrypted telegram-bot-token" \
        || echo "postActivation: failed to decrypt telegram-bot-token"

      # Bluesky app password for Faol
      SOPS_AGE_KEY_FILE="$AGE_KEY" ${pkgs.sops}/bin/sops --decrypt \
        --input-type binary --output-type binary \
        "$FAOL_DIR/bluesky-app-password" \
        > "/Users/${cfg.user.username}/.config/bluesky-app-password" 2>/dev/null \
        && chmod 600 "/Users/${cfg.user.username}/.config/bluesky-app-password" \
        && echo "postActivation: decrypted bluesky-app-password" \
        || echo "postActivation: failed to decrypt bluesky-app-password"

      # Letta API key for Faol
      SOPS_AGE_KEY_FILE="$AGE_KEY" ${pkgs.sops}/bin/sops --decrypt \
        --input-type binary --output-type binary \
        "$FAOL_DIR/letta-api-key" \
        > "/Users/${cfg.user.username}/.config/letta-api-key" 2>/dev/null \
        && chmod 600 "/Users/${cfg.user.username}/.config/letta-api-key" \
        && echo "postActivation: decrypted letta-api-key" \
        || echo "postActivation: failed to decrypt letta-api-key"
    fi

    # Reload the Dock after activation so any Homebrew-installed apps
    # (e.g. Element, Spotify) that were absent when the dock plist was
    # written are picked up cleanly.
    killall Dock 2>/dev/null || true
  '';
}
