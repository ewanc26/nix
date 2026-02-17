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
#  settings/config/desktop.nix — never hardcoded here.
#  Wallpaper lives in ../../wallpapers/wallpaper.jpg.
#  The Konsole profile lives in home/programs/terminal.nix.
#
#  macOS-like layout:
#  ┌─────────────────────────────────────────────────────────────────┐
#  │  [NixLogo]  [File  Edit  View  …]          [Tray extras]  [🕐]  │  ← 28px menu bar
#  ├─────────────────────────────────────────────────────────────────┤
#  │                      desktop / windows                           │
#  │  ╔═══════════════════════════════════════════════════════════╗   │
#  │  ║  🐬   📡   📝   🎵   🎮   💬   🦊   💻              ║   │  ← floating dock
#  │  ╚═══════════════════════════════════════════════════════════╝   │
#  └─────────────────────────────────────────────────────────────────┘
#
#  After editing: nixos-rebuild switch  (or  home-manager switch)
##############################################################################
{ lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
  d   = cfg.desktop;          # shorthand
in
{
  programs.plasma = {

    # ── Input – keyboard ───────────────────────────────────────────────────────
    # mac: InitialKeyRepeat = 15 (15 × 15 ms = 225 ms before first repeat)
    #      KeyRepeat        = 2  (2  × 15 ms = 30 ms → ~33 repeats / second)
    input.keyboard = {
      numlockOnStartup = "off";
      repeatDelay      = 225;
      repeatRate       = 33;
    };

    # ── KWin (window manager) ──────────────────────────────────────────────────
    kwin = {

      # Four named virtual desktops in one row — analogous to macOS Spaces.
      # mac: "com.apple.spaces"."spans-displays" = 0 (per-display Spaces)
      virtualDesktops = {
        names = [ "Main" "Work" "Media" "Social" ];
        rows  = 1;
      };

      # Borderless maximised windows — mirrors macOS hiding the titlebar in
      # full-screen mode.
      borderlessMaximizedWindows = true;

      # Night light — constant warm tone at all times.
      # To switch to automatic sunset/sunrise for Birmingham UK, set:
      #   mode                  = "location";
      #   location.latitude     = "52.48";
      #   location.longitude    = "-1.89";
      nightLight = {
        enable = true;
        mode   = "constant";   # valid: "constant" | "location" | "times"
        temperature = {
          day   = 6500;        # neutral daylight white
          night = 4000;        # warm amber (macOS default ≈ 3700 K)
        };
      };

      # Titlebar buttons on the LEFT — mac: close → minimise → maximise
      titlebarButtons.left  = [ "close" "minimize" "maximize" ];
      titlebarButtons.right = [];

      # KWin visual effects ────────────────────────────────────────────────────
      effects = {

        # Frosted-glass background behind panels and menus.
        # Mirrors NSVisualEffectView — the ubiquitous blur layer in macOS UI.
        blur = {
          enable        = true;
          strength      = 7;    # 1–15; 7 ≈ macOS vibrancy intensity
          noiseStrength = 0;    # no grain — macOS blur is clean
        };

        # Magic Lamp minimise — window squishes into the dock icon.
        # mac: dock.minimize-to-application = true
        minimization = {
          animation = "magiclamp";
          duration  = 400;      # ms; macOS default ≈ 300–400 ms
        };

        # Glide for window open / close — closest to macOS scale + fade.
        windowOpenClose.animation = "glide";

        # Slide between virtual desktops (macOS Spaces slide animation).
        desktopSwitching = {
          animation          = "slide";
          navigationWrapping = false;   # macOS does not wrap around Spaces
        };

        # Glass feel while moving / resizing windows.
        translucency.enable = true;

        # macOS does not shake the cursor to locate it.
        shakeCursor.enable = false;

        # macOS never dims inactive windows.
        dimInactive.enable = false;

      };

    };  # end kwin

    # ── KWin raw configFile (no first-class plasma-manager option yet) ─────────
    configFile."kwinrc" = {

      # Animation speed: 2 = Fast (KDE default 3 = Normal).
      Compositing.AnimationSpeed = 2;

      # Hot corners — mirrors macOS dock.wvous-* settings exactly:
      #   BL → Mission Control  (wvous-bl-corner = 2)
      #   BR → Show Desktop     (wvous-br-corner = 4)
      #   TL → None             (wvous-tl-corner = 1)
      #   TR → Lock Screen      (wvous-tr-corner = 5 ≈ Screen Saver)
      ElectricBorders = {
        BottomLeft  = "Overview";
        BottomRight = "ShowDesktop";
        TopLeft     = "None";
        TopRight    = "LockScreen";
      };

    };

    # ── Workspace ─────────────────────────────────────────────────────────────
    workspace = {

      # Wallpaper — direct path to wallpaper.jpg.
      wallpaper = ../../wallpapers/wallpaper.jpg;

      # Color scheme — from settings/config/desktop.nix.
      # Explicit here so it always wins, even if the catppuccin module changes
      # its lib.mkDefault later.
      colorScheme = d.plasma.colorScheme;   # "CatppuccinMochaGreen"

      # Plasma desktop style — from settings/config/desktop.nix.
      theme = d.plasma.desktopTheme;        # "breeze-dark"

      # Icon theme — from settings/config/desktop.nix.
      # Uses the proper API (runs plasma-changeicons on login) instead of the
      # raw configFile."kdeglobals".Icons.Theme approach.
      iconTheme = d.iconTheme;             # "Papirus-Dark"

      # Window decorations — Breeze (left-side buttons configured in kwin above).
      windowDecorations = {
        library = "org.kde.breeze";
        theme   = "Breeze";
      };

      # No splash screen — macOS shows nothing on login.
      splashScreen.theme = "None";

      # Single-click selects, double-click opens — standard macOS Finder behaviour.
      clickItemTo = "select";

      # Disable middle-click paste — macOS has no X11 primary selection.
      enableMiddleClickPaste = false;

      # Tooltip delay — 500 ms ≈ macOS hover timing (KDE default 700 ms).
      tooltipDelay = 500;

      # Breeze widget style — cleanest, most macOS-like Qt widget rendering.
      widgetStyle = "breeze";

      # Cursor theme — uncomment to use a macOS-inspired cursor.
      # Requires pkgs.capitaine-cursors (or pkgs.apple-cursor) in home.packages.
      # cursor = {
      #   theme          = "capitaine-cursors";
      #   size           = 24;
      #   cursorFeedback = "Bouncing";   # macOS: app icon bounces in dock on launch
      # };

    };

    # ── Fonts — all roles, all from settings/config/desktop.nix ───────────────
    # d.uiFont / d.uiFontSize / d.monoFontFamily / d.monoFontSize are the
    # single source of truth; change them once, everything updates.
    fonts = {
      general = {
        family    = d.uiFont;         # "Noto Sans"
        pointSize = d.uiFontSize;     # 10
      };
      fixedWidth = {
        family    = d.monoFontFamily; # "FiraCode Nerd Font Mono"
        pointSize = d.monoFontSize;   # 11
      };
      small = {
        family    = d.uiFont;
        pointSize = d.uiFontSize - 2; # 8 — status bars, breadcrumbs, subtitles
      };
      toolbar = {
        family    = d.uiFont;
        pointSize = d.uiFontSize;
      };
      menu = {
        family    = d.uiFont;
        pointSize = d.uiFontSize;
      };
      windowTitle = {
        family    = d.uiFont;
        pointSize = d.uiFontSize;
        weight    = "medium";  # macOS window titles are slightly heavier than body
      };
    };

    # ── Windows ───────────────────────────────────────────────────────────────
    # Allow apps to remember their own window positions.
    # mac: WindowServer stores geometry per app.
    windows.allowWindowsToRememberPositions = true;

    # ── KRunner — Spotlight equivalent (Meta+Space) ───────────────────────────
    krunner = {
      position                    = "center";  # macOS Spotlight is a centred overlay
      activateWhenTypingOnDesktop = false;      # Spotlight requires explicit shortcut
      shortcuts = {
        launch                = [ "Meta+Space" "Alt+F2" ];
        runCommandOnClipboard = [ "Meta+Shift+Space" "Alt+Shift+F2" ];
      };
    };

    # ── Keyboard shortcuts ─────────────────────────────────────────────────────
    shortcuts = {
      kwin = {
        # Virtual desktop / Spaces navigation
        # mac: Ctrl+1–4 and Ctrl+← / → switch Spaces
        "Switch to Desktop 1"             = [ "Meta+1" ];
        "Switch to Desktop 2"             = [ "Meta+2" ];
        "Switch to Desktop 3"             = [ "Meta+3" ];
        "Switch to Desktop 4"             = [ "Meta+4" ];
        "Switch One Desktop to the Left"  = [ "Meta+Left" ];
        "Switch One Desktop to the Right" = [ "Meta+Right" ];

        # Move window to a named Space
        "Window to Desktop 1" = [ "Meta+Shift+1" ];
        "Window to Desktop 2" = [ "Meta+Shift+2" ];
        "Window to Desktop 3" = [ "Meta+Shift+3" ];
        "Window to Desktop 4" = [ "Meta+Shift+4" ];

        # Window management — macOS Cmd+* equivalents
        "Window Close"            = [ "Meta+Q" ];       # Cmd+Q  (quit)
        "Window Minimize"         = [ "Meta+H" ];       # Cmd+H  (hide / minimise)
        "Toggle Window Maximized" = [ "Meta+Ctrl+F" ];  # Ctrl+Cmd+F (full-screen toggle)

        # Mission Control equivalents
        "Overview"     = [ "Meta+W" ];        # all desktops + all windows
        "Expose"       = [ "Meta+D" ];        # windows on current desktop only
        "Show Desktop" = [ "Meta+Shift+D" ];  # reveal desktop (≡ Fn+F11 on mac)
      };
    };

    # ── Spectacle — macOS screenshot shortcut mapping ─────────────────────────
    # mac: Cmd+Shift+3 = full screen → Meta+Shift+3
    #      Cmd+Shift+4 = region      → Meta+Shift+4
    #      Cmd+Shift+5 = UI          → Meta+Shift+5
    spectacle.shortcuts = {
      captureEntireDesktop     = [ "Meta+Shift+3" ];
      captureRectangularRegion = [ "Meta+Shift+4" ];
      launch                   = [ "Meta+Shift+5" ];
      captureActiveWindow      = [ "Meta+Shift+Alt+4" ];
    };

    # Spectacle save location and format
    # mac: system.defaults.screencapture.location = "~/Desktop", type = "png"
    configFile."spectaclerc" = {
      General.launchAction      = "DoNotTakeScreenshot";
      ImageSave.defaultFolder   = "%DESKTOP%";
      ImageSave.saveImageFormat = "PNG";
    };

    # ── Screen locker ──────────────────────────────────────────────────────────
    # mac: "Require password … after sleep or screen saver begins" (immediately)
    #      + 5-minute idle auto-lock.
    kscreenlocker = {
      autoLock              = true;
      timeout               = 5;     # lock after 5 min idle
      lockOnResume          = true;  # lock on wake from sleep
      passwordRequired      = true;
      passwordRequiredDelay = 0;     # no grace period
    };

    # ── Notifications — top-right (macOS notification banner position) ─────────
    configFile."plasmanotifyrc".Notifications.PopupPosition = "TopRight";

    # ── Dolphin — mirrors macOS Finder preferences ────────────────────────────
    # mac: finder.AppleShowAllExtensions  = true
    #      finder._FXSortFoldersFirst     = true
    #      finder.ShowPathbar             = true
    #      finder.ShowStatusBar           = false
    #      finder._FXShowPosixPathInTitle = true
    #      finder.FXDefaultSearchScope    = "SCcf"
    configFile."dolphinrc" = {
      General = {
        ShowHiddenFiles      = true;
        SortFoldersFirst     = true;
        ShowStatusBar        = false;
        BreadcrumbNavigation = true;
      };
      DetailsMode."ExpandableFolders"         = false;
      "KFileDialog Settings"."Show Full Path" = true;
    };

    # ── Panels ─────────────────────────────────────────────────────────────────

    panels = [

      # ── Top menu bar ──────────────────────────────────────────────────────────
      # Full-width, always visible, 28 px tall.
      # Left:  [Launcher]  [Global App Menu — File  Edit  View  …]
      # Right: [System Tray]  [Clock 12h + seconds]
      {
        location = "top";
        floating = false;
        height   = 28;

        widgets = [

          # Application launcher — the "Apple menu" / NixOS logo equivalent.
          {
            name = "org.kde.plasma.kickoff";
            config.General = {
              icon         = "start-here-kde-symbolic";
              showButtonOk = "false";
            };
          }

          # Global app menu — active window's menu bar appears inline here,
          # just as on macOS every app's menu bar lives at the top.
          "org.kde.plasma.appmenu"

          # Flexible spacer — pushes tray + clock to the far right.
          "org.kde.plasma.panelspacer"

          # System tray — equivalent to macOS menu-bar extras.
          {
            name = "org.kde.plasma.systemtray";
            config.General.shownItems = 3;
          }

          # Digital clock — mirrors macOS menuExtraClock:
          #   ShowAMPM = true, ShowSeconds = true
          #   ShowDate = 0 (never), ShowDayOfWeek = false
          {
            name = "org.kde.plasma.digitalclock";
            config.Appearance = {
              use24hFormat          = "0";     # 12-hour with AM/PM
              showSeconds           = "true";
              showDate              = "false";
              showDayOfWeek         = "false";
              displayTimezoneAsCode = "false";
            };
          }

        ];
      }

      # ── Bottom floating dock ──────────────────────────────────────────────────
      # Centred, floating, always visible.
      # mac: dock.autohide = false  dock.tilesize = 46  dock.orientation = "bottom"
      # Height 56 px ≈ icon size 46 + padding.
      {
        location   = "bottom";
        floating   = true;
        height     = 56;
        alignment  = "center";
        lengthMode = "fit";    # shrinks to fit its launchers
        hiding     = "none";   # always visible

        widgets = [
          {
            name = "org.kde.plasma.icontasks";
            config.General = {
              showOnlyCurrentDesktop = "false";
              showOnlyCurrentScreen  = "false";
              launchers = [
                "applications:org.kde.dolphin.desktop"    # Dolphin  ≡  Finder
                "applications:signal-desktop.desktop"
                "applications:obsidian.desktop"
                "applications:spotify.desktop"
                "applications:steam.desktop"
                "applications:discord.desktop"
                "applications:firefox.desktop"
                "applications:code.desktop"
                "applications:org.kde.konsole.desktop"
              ];
            };
          }
        ];
      }

    ];  # end panels

  };  # end programs.plasma
}
