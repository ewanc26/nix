{
  config,
  lib,
  pkgs,
  ...
}:

##############################################################################
#  Launch Services Management for macOS
#
#  Automatically rebuilds the Launch Services database after system activation
#  to ensure Nix-installed applications are properly registered with macOS.
#
#  This solves issues where apps show "can't be opened" errors because
#  macOS doesn't recognize apps from the Nix store or symlinked locations.
##############################################################################

{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "Rebuilding Launch Services database..." >&2

    # Modern approach: garbage collect and rescan all domains
    # This ensures all Nix apps are properly registered with macOS
    # Using -gc (garbage collect) instead of deprecated -kill flag
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
      -gc -R -apps u,s,l 2>/dev/null || true

    # Reset Launchpad cache to show updated apps
    # This is necessary for apps to appear in Spotlight and Launchpad
    find /private/var/folders/ -type d -name com.apple.dock.launchpad -exec rm -rf {} + 2>/dev/null || true

    # Restart Dock to apply changes
    killall Dock 2>/dev/null || true

    echo "Launch Services database rebuilt successfully" >&2
  '';
}
