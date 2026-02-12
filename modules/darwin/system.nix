{ config, pkgs, ... }:

{
  # Import Darwin defaults (encrypted settings)
  imports = [
    ../../settings/darwin
  ];

  # macOS system settings
  system = {
    defaults = {
      # Dock settings
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.2;
        orientation = "bottom";
        show-recents = false;
        tilesize = 48;
        # Remove all default apps from dock
        persistent-apps = [];
      };

      # Finder settings
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        CreateDesktop = true;
        FXDefaultSearchScope = "SCcf";  # Search current folder
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";  # List view
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };

      # Trackpad settings
      trackpad = {
        Clicking = true;  # Tap to click
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
      };

      # NSGlobalDomain (system-wide) settings
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";  # Dark mode
        AppleKeyboardUIMode = 3;  # Full keyboard access
        ApplePressAndHoldEnabled = false;  # Disable press-and-hold for keys
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.sound.beep.volume" = 0.0;
      };

      # Custom user preferences
      CustomUserPreferences = {
        # Disable screenshot shadows
        "com.apple.screencapture" = {
          "disable-shadow" = true;
        };
        
        # Show hidden files in Finder
        "com.apple.finder" = {
          "AppleShowAllFiles" = true;
        };
      };

      # Menu bar
      menuExtraClock = {
        Show24Hour = true;
        ShowDate = 1;  # Always show date
      };

      # Screen saver
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 5;
      };

      # Login window
      loginwindow = {
        GuestEnabled = false;
        DisableConsoleAccess = true;
      };

      # Spaces
      spaces = {
        spans-displays = false;  # Displays have separate Spaces
      };

      # Universal Access
      universalaccess = {
        closeViewScrollWheelToggle = true;
        closeViewZoomFollowsFocus = true;
      };
    };

    # Keyboard settings
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;  # Remap Caps Lock to Control
    };

    # Startup chime
    startup.chime = false;
  };

  # Additional system configuration
  system.activationScripts.postUserActivation.text = ''
    # Restart affected apps after configuration changes
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  # Security settings
  security.pam.enableSudoTouchIdAuth = true;  # Enable Touch ID for sudo
}
