{ config, lib, pkgs, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  # Import Darwin system-defaults (auto-exported values from settings/darwin/domains/)
  imports = [
    ../../settings/darwin
  ];

  # Keyboard – driven from settings/config/darwin.nix
  system.keyboard = {
    enableKeyMapping       = cfg.darwin.keyboard.enableKeyMapping;
    remapCapsLockToControl = cfg.darwin.keyboard.remapCapsLockToControl;
  };

  # Startup chime – driven from settings/config/darwin.nix
  system.startup.chime = cfg.darwin.startup.chime;

  # Touch ID for sudo – driven from settings/config/darwin.nix
  security.pam.services.sudo_local.touchIdAuth = cfg.darwin.security.touchIdForSudo;

  # ── Time Machine destination ──────────────────────────────────────────────────
  # No native nix-darwin option exists for tmutil setdestination, so we use an
  # activation script.  It is idempotent: skipped if the URL is already registered.
  #
  # First-time setup (one-off, interactive — stores password in macOS keychain):
  #   sudo tmutil setdestination -p smb://<user>@server/TimeMachine
  # After that, nrs registers it automatically on every rebuild without prompting.
  system.activationScripts.timeMachineDestination = lib.mkIf cfg.server.timemachine.enable {
    text = let
      shareUrl = "smb://${cfg.user.username}@server/${cfg.server.timemachine.shareName}";
    in ''
      shareUrl='${shareUrl}'
      echo "Checking Time Machine destination ($shareUrl)..."
      if /usr/bin/tmutil destinationinfo 2>/dev/null | /usr/bin/grep -qF "$shareUrl"; then
        echo "  already registered, skipping"
      else
        echo "  registering..."
        # -a adds alongside existing destinations rather than replacing them.
        # Credentials come from the macOS keychain — never stored in the Nix store.
        /usr/bin/tmutil setdestination -a "$shareUrl" 2>&1 || \
          echo "  WARNING: could not register (share may be unreachable right now)"
      fi
    '';
  };
}
