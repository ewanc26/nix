{ config, ... }:
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
let
  cfg = config.myConfig;
  # home-manager stages GUI apps here; path must track myConfig.user.username.
  hmApps = "/Users/${cfg.user.username}/Applications/Home Manager Apps";
in
{
  # ── Dock ─────────────────────────────────────────────────────────────────────
  system.defaults.dock = {
    autohide = false;
    tilesize = 40;
    orientation = "bottom";
    show-recents = false;
    minimize-to-application = true;
    show-process-indicators = true;
    magnification = true;
    largesize = 82;
    # Hot corners
    # 1=None  2=MissionControl  3=AppWindows  4=Desktop  5=ScreenSaver  13=LockScreen
    wvous-bl-corner = 5; # bottom-left  → Screen Saver
    wvous-br-corner = 4; # bottom-right → Desktop
    wvous-tl-corner = 1; # top-left     → None
    wvous-tr-corner = 13; # top-right    → Lock Screen

    # Persistent applications in the Dock (left to right).
    # Note: Finder is always shown and doesn't need to be listed here.
    # Apps managed by Nix (darwin.packages) live in /Applications/Nix Apps/.
    # Apps managed by Homebrew cask live in /Applications/.
    # Apps managed by home-manager live in ~/Applications/Home Manager Apps/.
    persistent-apps = [
      # ── Communication ─────────────────────────────────────────────
      { folder = "/System/Applications/Mail.app"; }
      { folder = "/System/Applications/Messages.app"; }
      { folder = "/Applications/WhatsApp.app"; }
      { folder = "/Applications/Signal.app"; }
      { folder = "/System/Applications/FaceTime.app"; }
      { folder = "/System/Applications/Phone.app"; }
      # ── Productivity ───────────────────────────────────────────────
      { folder = "/System/Applications/Calendar.app"; }
      { folder = "/System/Applications/Podcasts.app"; }
      { folder = "/System/Applications/Music.app"; }
      { folder = "/System/Applications/Contacts.app"; }
      { folder = "/System/Applications/Reminders.app"; }
      { folder = "/System/Applications/Notes.app"; }
      { folder = "/Applications/Discord.app"; }
      { folder = "/System/Applications/Safari.app"; }
      # ── Gaming / emulation ────────────────────────────────────────
      { folder = "/Applications/Prism Launcher.app"; }
      { folder = "/Applications/Steam.app"; }
      # ── Development ───────────────────────────────────────────────
      { folder = "${hmApps}/Ghostty.app"; }
      { folder = "/Applications/Xcode.app"; }
      { folder = "/Applications/Android Studio.app"; }
      { folder = "/Applications/VSCodium.app"; }
      { folder = "/System/Applications/iPhone Mirroring.app"; }
    ];
  };

  # ── Finder ───────────────────────────────────────────────────────────────────
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    ShowPathbar = true;
    ShowStatusBar = true;
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
    ShowDayOfWeek = true;
  };

  # ── CustomUserPreferences — settings with no native nix-darwin option yet ────
  system.defaults.CustomUserPreferences = {
    # Login window fast user switching menu
    "com.apple.loginwindow" = {
      MiniBuddyLaunch = 1;
    };
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
    # Screen capture defaults (no native options yet)
    "com.apple.screencapture" = {
      style = "selection";
      video = false;
    };
    # Accent / highlight colour and mouse speed (no native options yet)
    NSGlobalDomain = {
      AppleAccentColor = 3; # 3=Green (0=Red 1=Orange 2=Yellow 4=Blue 5=Purple 6=Pink -1=Graphite)
      "com.apple.mouse.scaling" = 0.5;
      "com.apple.mouse.doubleClickThreshold" = "1.1";
      "com.apple.trackpad.forceClick" = 1;
      "com.apple.springing.delay" = "0.5";
      "com.apple.springing.enabled" = 1;
    };
    # Magic Mouse / multitouch mouse settings (no native nix-darwin options yet)
    "com.apple.AppleMultitouchMouse" = {
      MouseButtonMode = "OneButton";
      MouseTwoFingerDoubleTapGesture = 3; # 3=Smart Zoom
      MouseTwoFingerHorizSwipeGesture = 2; # 2=Swipe
      MouseVerticalScroll = 1;
      MouseHorizontalScroll = 1;
      MouseMomentumScroll = 1;
      MouseOneFingerDoubleTapGesture = 0;
    };
  };
}
