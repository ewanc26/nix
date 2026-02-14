{ ... }:
{
  system.defaults.CustomUserPreferences = {
    "com.apple.dock" = import ./domains/com.apple.dock.nix;
    "com.apple.finder" = import ./domains/com.apple.finder.nix;
    "com.apple.screencapture" = import ./domains/com.apple.screencapture.nix;
    "com.apple.menuextra.clock" = import ./domains/com.apple.menuextra.clock.nix;
    "com.apple.systemuiserver" = import ./domains/com.apple.systemuiserver.nix;
    "com.apple.AppleMultitouchTrackpad" = import ./domains/com.apple.AppleMultitouchTrackpad.nix;
    "NSGlobalDomain" = import ./domains/NSGlobalDomain.nix;
  };
}
