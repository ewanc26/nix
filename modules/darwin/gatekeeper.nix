##############################################################################
#  Gatekeeper Management for macOS
#
#  Removes quarantine attributes from Homebrew-installed apps so they open
#  without the "downloaded from the internet" prompt, and can optionally
#  report apps whose code signature no longer validates.
#
#  Invalid signatures usually mean the app needs to be reinstalled:
#    brew reinstall --cask <app-name>
#
#  NOTE: this must hang off `system.activationScripts.postActivation`.
#  nix-darwin only runs a fixed set of activation-script names; an entry under
#  any other name (this module previously used `removeQuarantine`) is still
#  evaluated and built, but never executed. See modules/darwin/common.nix.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  gk = cfg.darwin.gatekeeper;

  # Activation scripts run as root, so $HOME is root's home, not the user's.
  userHome = "/Users/${cfg.user.username}";
in
{
  system.activationScripts.postActivation.text = lib.mkIf gk.enable (
    lib.mkAfter ''
      echo "Removing quarantine attributes from applications..." >&2

      for apps_dir in /Applications "${userHome}/Applications" "${userHome}/Applications/Home Manager Apps"; do
        [ -d "$apps_dir" ] || continue
        for app in "$apps_dir"/*.app; do
          [ -d "$app" ] || continue
          xattr -dr com.apple.quarantine "$app" 2>/dev/null || true
        done
      done

      echo "Quarantine attributes removed" >&2

      ${lib.optionalString gk.checkSignatures ''
        # Off by default: spctl shells out per app and adds seconds to every
        # rebuild. Enable myConfig.darwin.gatekeeper.checkSignatures when an app
        # is actually refusing to launch.
        echo "Checking code signatures..." >&2
        for app in /Applications/*.app; do
          [ -d "$app" ] || continue
          if spctl -a -vv "$app" 2>&1 | grep -qi "invalid"; then
            echo "WARNING: $(basename "$app") has an invalid signature and may not open" >&2
            echo "  Fix: brew reinstall --cask <cask-name>" >&2
          fi
        done
      ''}
    ''
  );
}
