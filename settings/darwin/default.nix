{ ... }:
##############################################################################
#  macOS system.defaults — intentional settings only.
#
#  Prefer nix-darwin's first-class system.defaults.* options over
#  CustomUserPreferences wherever possible:
#  ✓ Type-checked by the module system
#  ✓ Self-documenting (option names match macOS keys)
#  ✓ Documented in the nix-darwin manual:
#    https://daiderd.com/nix-darwin/manual/index.html#sec-options
#
#  CustomUserPreferences is reserved for keys that have no native option yet.
#
##############################################################################
{
  # ── Dock ─────────────────────────────────────────────────────────────────────
  system.defaults.dock = {
    autohide = false;
    tilesize = 46;
    orientation = "bottom";
    show-recents = false;
    minimize-to-application = true;
    show-process-indicators = true;
    magnification = false;
    # Hot corners
    # 1=None  2=MissionControl  3=AppWindows  4=Desktop  5=ScreenSaver  13=LockScreen
    wvous-bl-corner = 2; # bottom-left  → Mission Control
    wvous-br-corner = 4; # bottom-right → Desktop
    wvous-tl-corner = 1; # top-left     → None
    wvous-tr-corner = 5; # top-right    → Screen Saver

    # Persistent applications in the Dock (left to right).
    # Note: Finder is always shown and doesn't need to be listed here.
    # Apps managed by Nix (darwin.packages) live in /Applications/Nix Apps/.
    # Apps managed by Homebrew cask live in /Applications/.
    # Apps managed by home-manager live in ~/Applications/Home Manager Apps/.
    persistent-apps = [
      # ── Communication ─────────────────────────────────────────────
      "/System/Applications/Mail.app"
      "/Applications/WhatsApp.app"
      "/System/Applications/Messages.app"
      "/System/Applications/FaceTime.app"
      "/System/Applications/Phone.app"
      "/System/Applications/iPhone Mirroring.app"
      "/Applications/Signal.app"
      "/Applications/Element.app"
      "/Applications/Discord.app"
      # ── Productivity ───────────────────────────────────────────────
      "/System/Applications/Calendar.app"
      "/System/Applications/Reminders.app"
      "/Applications/Obsidian.app"
      "/Applications/Visual Studio Code.app"
      "/Applications/Claude.app"
      # ── Media ─────────────────────────────────────────────
      "/Applications/Spotify.app"
      "/Applications/Firefox.app"
      # ── System ─────────────────────────────────────────────────────
      "/Users/ewan/Applications/Home Manager Apps/Ghostty.app"
    ];
  };

  # ── Finder ───────────────────────────────────────────────────────────────────
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    ShowPathbar = true;
    ShowStatusBar = false;
    _FXShowPosixPathInTitle = true;
    FXEnableExtensionChangeWarning = false;
    QuitMenuItem = true;
    _FXSortFoldersFirst = true;
    FXDefaultSearchScope = "SCcf"; # search current folder by default
  };

  # ── NSGlobalDomain ───────────────────────────────────────────────────────────
  system.defaults.NSGlobalDomain = {
    AppleInterfaceStyle = "Dark";
    AppleShowAllExtensions = true;
    AppleShowScrollBars = "WhenScrolling";
    NSAutomaticCapitalizationEnabled = true;
    NSAutomaticPeriodSubstitutionEnabled = true;
    NSNavPanelExpandedStateForSaveMode = true;
    NSNavPanelExpandedStateForSaveMode2 = true;
    "com.apple.swipescrolldirection" = false; # disable natural scrolling
    "com.apple.sound.beep.feedback" = 1; # beep on volume key press
    InitialKeyRepeat = 15; # 225 ms before key repeat starts
    KeyRepeat = 2; # 30 ms between repeats
  };

  # ── Trackpad ─────────────────────────────────────────────────────────────────
  system.defaults.trackpad = {
    Clicking = false; # tap-to-click off (use physical click)
    TrackpadRightClick = true;
    TrackpadThreeFingerDrag = false;
  };

  # ── Login window ─────────────────────────────────────────────────────────────
  system.defaults.loginwindow = {
    GuestEnabled = false;
    SHOWFULLNAME = false;
  };

  # ── Screen capture ───────────────────────────────────────────────────────────
  system.defaults.screencapture = {
    location = "~/Desktop";
    type = "png";
  };

  # ── Menu bar clock ───────────────────────────────────────────────────────────
  system.defaults.menuExtraClock = {
    IsAnalog = false;
    ShowAMPM = true;
    ShowSeconds = true;
    ShowDate = 0; # 0 = never, 1 = when space allows, 2 = always
    ShowDayOfWeek = false;
  };

  # ── CustomUserPreferences — settings with no native nix-darwin option yet ────
  system.defaults.CustomUserPreferences = {
    # Prevent .DS_Store pollution on network / USB volumes
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
    # Desktop drive icon visibility (no native nix-darwin options for these yet)
    "com.apple.finder" = {
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowMountedServersOnDesktop = true;
      ShowRemovableMediaOnDesktop = false;
    };
    # Each display gets its own Space
    "com.apple.spaces" = {
      "spans-displays" = 0;
    };
    # Opt out of personalised advertising
    "com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
    };
    # Prevent Photos from opening when devices are plugged in
    "com.apple.ImageCapture" = {
      disableHotPlug = true;
    };
    # Accent / highlight colour and mouse speed (no native options yet)
    NSGlobalDomain = {
      AppleAccentColor = 3; # 3=Green (0=Red 1=Orange 2=Yellow 4=Blue 5=Purple 6=Pink -1=Graphite)
      "com.apple.mouse.scaling" = 0.5;
    };
  };
}
