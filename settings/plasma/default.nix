##############################################################################
#  Declarative KDE Plasma 6 settings — macOS-inspired layout.
#
#  Philosophy:
#  ✓ Only include values that express a deliberate preference
#  ✗ No window positions, sidebar widths, last-opened panels, or scroll state
#  ✗ No machine-specific paths or device UUIDs
#  ✗ No internal migration flags or analytics timestamps
#
#  All font families, sizes, color schemes, and icon themes come from
#  myConfig.desktop — never hardcoded here.
#  Wallpaper is applied by a systemd user service in home/programs/kde.nix.
#  The Konsole profile lives in home/programs/terminal.nix.
##############################################################################
{
  osConfig,
  ...
}:
let
  d = osConfig.myConfig.desktop;
in
{
  programs.plasma = {

    # ── Input – keyboard ──────────────────────────────────────────────────────
    input.keyboard = {
      numlockOnStartup = "off";
      repeatDelay = 225;
      repeatRate = 33;
    };

    # ── KWin (window manager) ─────────────────────────────────────────────────
    kwin = {

      virtualDesktops = {
        names = [
          "Main"
          "Work"
          "Media"
          "Social"
        ];
        rows = 1;
      };

      borderlessMaximizedWindows = true;

      nightLight = {
        enable = true;
        mode = "constant";
        temperature = {
          day = 6500;
          night = 4000;
        };
      };

      titlebarButtons.left = [
        "close"
        "minimize"
        "maximize"
      ];
      titlebarButtons.right = [ ];

      effects = {
        blur = {
          enable = true;
          strength = 7;
          noiseStrength = 0;
        };

        minimization = {
          animation = "magiclamp";
          duration = 400;
        };

        windowOpenClose.animation = "glide";

        desktopSwitching = {
          animation = "slide";
          navigationWrapping = false;
        };

        translucency.enable = true;
        shakeCursor.enable = false;
        dimInactive.enable = false;
      };

    };

    configFile."kwinrc" = {
      Compositing.AnimationSpeed = 2;

      ElectricBorders = {
        BottomLeft = "Overview";
        BottomRight = "ShowDesktop";
        TopLeft = "None";
        TopRight = "LockScreen";
      };
    };

    # ── Workspace ─────────────────────────────────────────────────────────────
    workspace = {
      colorScheme = d.plasma.colorScheme;
      theme = d.plasma.desktopTheme;
      iconTheme = d.iconTheme;

      windowDecorations = {
        library = "org.kde.breeze";
        theme = "Breeze";
      };

      splashScreen.theme = "None";
      clickItemTo = "select";
      enableMiddleClickPaste = false;
      tooltipDelay = 500;
      widgetStyle = "breeze";
    };

    # ── Fonts ─────────────────────────────────────────────────────────────────
    fonts = {
      general = {
        family = d.uiFont;
        pointSize = d.uiFontSize;
      };
      fixedWidth = {
        family = d.monoFontFamily;
        pointSize = d.monoFontSize;
      };
      small = {
        family = d.uiFont;
        pointSize = d.uiFontSize - 2;
      };
      toolbar = {
        family = d.uiFont;
        pointSize = d.uiFontSize;
      };
      menu = {
        family = d.uiFont;
        pointSize = d.uiFontSize;
      };
      windowTitle = {
        family = d.uiFont;
        pointSize = d.uiFontSize;
        weight = "medium";
      };
    };

    # ── Windows ───────────────────────────────────────────────────────────────
    windows.allowWindowsToRememberPositions = true;

    # ── KRunner ───────────────────────────────────────────────────────────────
    krunner = {
      position = "center";
      activateWhenTypingOnDesktop = false;
      shortcuts = {
        launch = [
          "Meta+Space"
          "Alt+F2"
        ];
        runCommandOnClipboard = [
          "Meta+Shift+Space"
          "Alt+Shift+F2"
        ];
      };
    };

    # ── Keyboard shortcuts ────────────────────────────────────────────────────
    shortcuts = {
      kwin = {
        "Switch to Desktop 1" = [ "Meta+1" ];
        "Switch to Desktop 2" = [ "Meta+2" ];
        "Switch to Desktop 3" = [ "Meta+3" ];
        "Switch to Desktop 4" = [ "Meta+4" ];
        "Switch One Desktop to the Left" = [ "Meta+Left" ];
        "Switch One Desktop to the Right" = [ "Meta+Right" ];
        "Window to Desktop 1" = [ "Meta+Shift+1" ];
        "Window to Desktop 2" = [ "Meta+Shift+2" ];
        "Window to Desktop 3" = [ "Meta+Shift+3" ];
        "Window to Desktop 4" = [ "Meta+Shift+4" ];
        "Window Close" = [ "Meta+Q" ];
        "Window Minimize" = [ "Meta+H" ];
        "Toggle Window Maximized" = [ "Meta+Ctrl+F" ];
        "Overview" = [ "Meta+W" ];
        "Expose" = [ "Meta+D" ];
        "Show Desktop" = [ "Meta+Shift+D" ];
      };
    };

    spectacle.shortcuts = {
      captureEntireDesktop = [ "Meta+Shift+3" ];
      captureRectangularRegion = [ "Meta+Shift+4" ];
      launch = [ "Meta+Shift+5" ];
      captureActiveWindow = [ "Meta+Shift+Alt+4" ];
    };

    configFile."spectaclerc" = {
      General.launchAction = "DoNotTakeScreenshot";
      ImageSave.defaultFolder = "%DESKTOP%";
      ImageSave.saveImageFormat = "PNG";
    };

    # ── Screen locker ─────────────────────────────────────────────────────────
    kscreenlocker = {
      autoLock = true;
      timeout = 5;
      lockOnResume = true;
      passwordRequired = true;
      passwordRequiredDelay = 0;
    };

    configFile."plasmanotifyrc".Notifications.PopupPosition = "TopRight";

    # ── Default terminal ──────────────────────────────────────────────────────
    configFile."kdeglobals".General = {
      TerminalApplication = "ghostty";
      TerminalService = "com.mitchellh.ghostty.desktop";
    };

    # ── Dolphin ───────────────────────────────────────────────────────────────
    configFile."dolphinrc" = {
      General = {
        ShowHiddenFiles = true;
        SortFoldersFirst = true;
        ShowStatusBar = false;
        BreadcrumbNavigation = true;
      };
      DetailsMode."ExpandableFolders" = false;
      "KFileDialog Settings"."Show Full Path" = true;
    };

    # ── Panels ────────────────────────────────────────────────────────────────
    panels = [

      # Top menu bar
      {
        location = "top";
        floating = false;
        height = 28;

        widgets = [
          {
            name = "org.kde.plasma.kickoff";
            config.General = {
              icon = "start-here-kde-symbolic";
              showButtonOk = "false";
            };
          }
          "org.kde.plasma.appmenu"
          "org.kde.plasma.panelspacer"
          {
            name = "org.kde.plasma.systemtray";
            config.General.shownItems = 3;
          }
          {
            name = "org.kde.plasma.digitalclock";
            config.Appearance = {
              use24hFormat = "0";
              showSeconds = "true";
              showDate = "false";
              showDayOfWeek = "false";
              displayTimezoneAsCode = "false";
            };
          }
        ];
      }

      # Bottom floating dock
      {
        location = "bottom";
        floating = true;
        height = 56;
        alignment = "center";
        lengthMode = "fit";
        hiding = "none";

        widgets = [
          {
            name = "org.kde.plasma.icontasks";
            config.General = {
              showOnlyCurrentDesktop = "false";
              showOnlyCurrentScreen = "false";
              launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:signal-desktop.desktop"
                "applications:obsidian.desktop"
                "applications:spotify.desktop"
                "applications:steam.desktop"
                "applications:discord.desktop"
                "applications:firefox.desktop"
                "applications:code.desktop"
                "applications:com.mitchellh.ghostty.desktop"
              ];
            };
          }
        ];
      }

    ];

  };
}
