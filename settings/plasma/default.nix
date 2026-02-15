##############################################################################
#  Declarative KDE Plasma 6 settings via plasma-manager.
#
#  Philosophy:
#  ✓ Only include values that express a deliberate preference
#  ✗ No window positions, sidebar widths, last-opened panels, or scroll state
#  ✗ No machine-specific paths or device UUIDs
#  ✗ No internal migration flags or analytics timestamps
#  ✗ No duplicates of keys already set by home/programs/kde.nix
#    (wallpaper, fonts, icon theme — those come from settings/config/desktop.nix)
#
#  Settings are mirrored from settings/darwin/default.nix wherever possible,
#  so behaviour matches the macmini as closely as KDE allows.
#
#  macOS-like layout:
#  ┌─────────────────────────────────────────────────────┐
#  │  [NixLogo] [App Menu — File Edit View …]   [Tray][🕐] │  ← top menu bar
#  ├─────────────────────────────────────────────────────┤
#  │               desktop / windows                      │
#  │  ╔══════════════════════════════════════════════╗    │
#  │  ║  🐬  📡  📝  🎵  🎮  💬  🦊  💻       ║    │  ← always-visible dock
#  │  ╚══════════════════════════════════════════════╝    │
#  └─────────────────────────────────────────────────────┘
#
#  After editing, run `nixos-rebuild switch` to apply.
##############################################################################
{ lib, ... }:

{
  programs.plasma = {

    # ── Input – keyboard ───────────────────────────────────────────────────────
    # Mac: InitialKeyRepeat = 15 (15 × 15ms = 225ms delay before repeat)
    #      KeyRepeat        = 2  (2  × 15ms = 30ms interval → ~33 repeats/s)
    input.keyboard = {
      numlockOnStartup = "off";
      repeatDelay      = 225;
      repeatRate       = 33;
    };

    # ── KWin (window manager) ──────────────────────────────────────────────────
    kwin = {

      # Four virtual desktops in a single row (macOS Spaces)
      virtualDesktops = {
        number = 4;
        rows   = 1;
      };

      # Night light
      nightLight = {
        enable = true;
        mode   = "constantColor";
        temperature = {
          day   = 6500;
          night = 4000;
        };
      };

      effects = {
        translucency.enable = true;   # glass feel while moving/resizing
        shakeCursor.enable  = false;  # macOS doesn't shake cursor to locate it
      };
    };

    # ── Window decoration ──────────────────────────────────────────────────────
    workspace.windowDecorations = {
      theme   = "Breeze";
      library = "org.kde.breeze";
    };

    # Titlebar buttons on the LEFT, mac-style: close → minimise → maximise
    kwin.titlebarButtons.left  = [ "close" "minimize" "maximize" ];
    kwin.titlebarButtons.right = [ ];

    # ── Workspace ──────────────────────────────────────────────────────────────
    # Wallpaper and icon theme are set in home/programs/kde.nix.
    workspace.clickItemTo = "select";  # single-click selects, double-click opens

    # ── Keyboard shortcuts ─────────────────────────────────────────────────────
    shortcuts = {
      kwin = {
        # Virtual desktop switching
        "Switch to Desktop 1" = [ "Meta+1" ];
        "Switch to Desktop 2" = [ "Meta+2" ];
        "Switch to Desktop 3" = [ "Meta+3" ];
        "Switch to Desktop 4" = [ "Meta+4" ];
        "Switch One Desktop to the Left"  = [ "Meta+Left"  ];
        "Switch One Desktop to the Right" = [ "Meta+Right" ];
        # Send window to desktop
        "Window to Desktop 1" = [ "Meta+Shift+1" ];
        "Window to Desktop 2" = [ "Meta+Shift+2" ];
        "Window to Desktop 3" = [ "Meta+Shift+3" ];
        "Window to Desktop 4" = [ "Meta+Shift+4" ];
        # Window management
        "Window Close"               = [ "Meta+Q" ];       # macOS Cmd+Q
        "Window Minimize"            = [ "Meta+H" ];       # macOS Cmd+H (hide)
        "Toggle Window Maximized"    = [ "Meta+Ctrl+F" ];  # macOS Ctrl+Cmd+F
        # Mission Control equivalents
        # mac: wvous-bl-corner = 2 (Mission Control) → Meta+W as keyboard shortcut
        "Overview"     = [ "Meta+W" ];   # all desktops + windows
        "Expose"       = [ "Meta+D" ];   # present windows on current desktop
        "Show Desktop" = [ "Meta+Shift+D" ];
      };
    };

    # ── Panels ────────────────────────────────────────────────────────────────

    panels = [

      # ── Top menu bar ─────────────────────────────────────────────────────────
      # Full-width, always visible, 28 px — hosts the global app menu.
      # Mirrors the macOS menu bar: launcher on left, app menus inline,
      # tray + clock on right.
      {
        location = "top";
        floating = false;
        height   = 28;

        widgets = [

          # Application launcher (Apple menu equivalent)
          {
            name = "org.kde.plasma.kickoff";
            config.General = {
              icon         = "start-here-kde-symbolic";
              showButtonOk = "false";
            };
          }

          # Global app menu — active window's menus appear here
          "org.kde.plasma.appmenu"

          # Flexible spacer
          "org.kde.plasma.panelspacer"

          # System tray
          {
            name = "org.kde.plasma.systemtray";
            config.General.shownItems = 3;
          }

          # Clock — mirroring mac menuExtraClock:
          #   ShowAMPM = true  (12-hour)
          #   ShowSeconds = true
          #   ShowDate = 0  (never)
          #   ShowDayOfWeek = false
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

      # ── Bottom dock ───────────────────────────────────────────────────────────
      # Floating, centred, always visible (mac dock.autohide = false).
      # Icon-only task manager — no labels — mirrors the macOS dock.
      # Height 56 ≈ tilesize 46 + padding (mac dock.tilesize = 46).
      {
        location   = "bottom";
        floating   = true;
        height     = 56;
        alignment  = "center";
        lengthMode = "fit";
        hiding     = "none";   # mac: dock.autohide = false

        widgets = [
          {
            name = "org.kde.plasma.icontasks";
            config.General = {
              showOnlyCurrentDesktop = "false";
              showOnlyCurrentScreen  = "false";
              launchers = [
                "applications:org.kde.dolphin.desktop"    # Files (Finder)
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

    ];

    # ── KWin config via configFile ────────────────────────────────────────────
    configFile."kwinrc" = {

      # Blur behind panels and menus (frosted-glass macOS look)
      Plugins.blurEnabled = true;
      "Effect-blur" = {
        BlurStrength  = 7;
        NoiseStrength = 0;
      };

      # Magic Lamp minimise animation — mirrors mac dock.minimize-to-application = true.
      # The window squishes into the dock icon rather than zooming to the centre.
      Plugins.magiclampEnabled = true;
      Plugins.squashEnabled    = false;

      # Faster animations — snappier than KDE default (3)
      Compositing.AnimationSpeed = 2;

      # Hot corners — mirroring mac dock wvous-* settings:
      #   BL → Mission Control (Overview in KDE = 9)
      #   BR → Desktop         (ShowDesktop     = 4)
      #   TL → None            (None            = 0)
      #   TR → Screen Saver    (LockScreen      = 5, closest KDE equivalent)
      ElectricBorders = {
        BottomLeft  = "Overview";     # mac: wvous-bl-corner = 2 (Mission Control)
        BottomRight = "ShowDesktop";  # mac: wvous-br-corner = 4 (Desktop)
        TopLeft     = "None";         # mac: wvous-tl-corner = 1 (None)
        TopRight    = "LockScreen";   # mac: wvous-tr-corner = 5 (Screen Saver)
      };
    };

    # ── KRunner = Spotlight (Meta+Space) ─────────────────────────────────────
    configFile."kglobalshortcutsrc".krunner = {
      _launch      = "Meta+Space,Alt+F2,Run Command";
      RunClipboard = "Meta+Shift+Space,Alt+Shift+F2,Run Command on clipboard contents";
    };

    # ── Notifications — top-right (macOS position) ────────────────────────────
    configFile."plasmanotifyrc".Notifications.PopupPosition = "TopRight";

    # ── Splash screen — none (macOS has none) ────────────────────────────────
    configFile."ksplashrc".KSplash = {
      Engine = "none";
      Theme  = "None";
    };

    # ── Dolphin (file manager) ────────────────────────────────────────────────
    # mirrors: finder.AppleShowAllExtensions = true
    #          finder._FXSortFoldersFirst = true
    #          finder.ShowPathbar = true
    #          finder.FXDefaultSearchScope = "SCcf" (search current folder)
    configFile."dolphinrc".General = {
      ShowHiddenFiles  = true;
      SortFoldersFirst = true;   # mac: finder._FXSortFoldersFirst = true
    };
    configFile."dolphinrc".DetailsMode.ExpandableFolders = false;

    # ── Spectacle (screenshot) ────────────────────────────────────────────────
    # mac: screencapture.location = "~/Desktop"  screencapture.type = "png"
    configFile."spectaclerc" = {
      General.launchAction    = "DoNotTakeScreenshot";
      ImageSave.defaultFolder = "%DESKTOP%";
      ImageSave.saveImageFormat = "PNG";
    };

  };
}
