{ config, lib, pkgs, ... }:

##############################################################################
#  Gatekeeper Management for macOS
#  
#  Automatically removes quarantine attributes from Homebrew-installed apps
#  and detects apps with invalid code signatures.
#  
#  Invalid signatures usually mean the app needs to be reinstalled.
#  Run: brew reinstall --cask <app-name>
##############################################################################

{
  system.activationScripts.removeQuarantine.text = lib.mkAfter ''
    echo "Removing quarantine attributes from applications..." >&2
    
    # Remove quarantine from Homebrew Cask apps in /Applications
    if [ -d "/Applications" ]; then
      for app in /Applications/*.app; do
        if [ -d "$app" ]; then
          xattr -dr com.apple.quarantine "$app" 2>/dev/null || true
          # Also ensure the app is executable
          chmod -R +x "$app/Contents/MacOS"/* 2>/dev/null || true
        fi
      done
    fi
    
    # Also check ~/Applications and Home Manager Apps
    for apps_dir in "$HOME/Applications" "$HOME/Applications/Home Manager Apps"; do
      if [ -d "$apps_dir" ]; then
        for app in "$apps_dir"/*.app; do
          if [ -d "$app" ]; then
            xattr -dr com.apple.quarantine "$app" 2>/dev/null || true
            chmod -R +x "$app/Contents/MacOS"/* 2>/dev/null || true
          fi
        done
      fi
    done
    
    echo "Quarantine attributes removed successfully" >&2
    
    # Check for apps with invalid signatures
    echo "Checking code signatures..." >&2
    for app in /Applications/*.app; do
      if [ -d "$app" ]; then
        if spctl -a -vv "$app" 2>&1 | grep -qi "invalid"; then
          app_name=$(basename "$app")
          echo "WARNING: $app_name has invalid signature and may not open" >&2
          echo "  Fix: brew reinstall --cask <cask-name>" >&2
        fi
      fi
    done
  '';
}
