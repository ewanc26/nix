{
  # macOS configuration (nix-darwin)

  # ─── Keyboard ────────────────────────────────────────────────────────────────
  keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = false; # Keep Caps Lock as Caps Lock
  };

  # ─── Startup ─────────────────────────────────────────────────────────────────
  startup = {
    chime = true; # Let it bong
  };

  # ─── Security ────────────────────────────────────────────────────────────────
  security = {
    touchIdForSudo = true; # Allow Touch ID to authenticate sudo
  };

  # ─── Homebrew ────────────────────────────────────────────────────────────────
  homebrew = {
    enable = true;

    # Taps (repositories)
    taps = [
      # Add custom taps here if needed
    ];

    # CLI tools managed by Homebrew (complex media/codec dependencies)
    brews = [
      # Media libraries
      "libmediainfo"
      "media-info"
      "libzen"

      # Video/audio codecs
      "aribb24"
      "dav1d"
      "rav1e"
      "svt-av1"
      "x264"
      "x265"
      "xvid"
      "webp"
      "aom"
      "jpeg-xl"
      "highway"

      # Audio
      "flac"
      "lame"
      "opus"
      "vorbis-tools"
      "libsndfile"
      "libsamplerate"
      "rubberband"
      "speex"
      "theora"
      "mpg123"

      # Image processing
      "little-cms2"
      "leptonica"

      # Network protocols
      "rtmpdump"
      "srt"
      "librist"
      "libmms"

      # Compression
      "lzo"
      "snappy"
      "xxhash"
      "yyjson"

      # Database drivers
      "freetds"
      "unixodbc"

      # Miscellaneous
      "summarize"
      "goat"
      "mas"
    ];

    # GUI applications via Homebrew Cask
    # Note: apps available in nixpkgs are installed via darwin.packages below.
    casks = [
      # Communication
      "element"          # build fails in nixpkgs on darwin (requires Xcode 26 in Nix sandbox)

      # Productivity
      "github"          # GitHub Desktop (not in nixpkgs)
      "claude"

      # Browsers
      "firefox"         # Not available in nixpkgs-darwin

      # Media & Entertainment
      "obs"             # OBS Studio (keep in Homebrew — complex macOS plugin deps)
      "handbrake-app"

      # Gaming
      "steam"
      "epic-games"
      "prismlauncher"    # wayland dep build failure in nixpkgs on darwin (issue #455247)
      "utm"

      # Utilities
      "cloudflare-warp"
      "tailscale-app"   # Renamed from tailscale
      # filezilla — not available on macOS in Homebrew or nixpkgs; use Cyberduck or ForkLift instead
      "parsec"           # Remote desktop (Linux-only in nixpkgs)
      "onyx"
      "mos"             # Mouse/trackpad customization (macOS-specific)

      # Office & Documents
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-teams"
      "microsoft-word"
      "libreoffice"

      # Hardware
      "logitune"        # Logitech webcam
      "logi-options+"   # Logitech devices (replaces deprecated logitech-options)

      # Gaming / social
      "roblox"
      "ea"              # EA app (game launcher)

      # Other
      "netnewswire"     # RSS reader
      "altserver"       # AltStore sideloading server
      # 2fhey          — not in Homebrew, install manually
      # letta-desktop  — not in Homebrew, install manually
      # filezilla      — removed from Homebrew, install manually
    ];

    # Mac App Store apps (by ID)
    masApps = {
      "Amphetamine"    = 937984704;
      # Mini Motorways — Apple Arcade, not available via MAS ID
      "OneDrive"       = 823766827;   # moved from casks
      "OP Auto Clicker" = 6754914118;
      "Steam Link"     = 1246969117;  # was incorrectly labelled "EA app"
      "TestFlight"     = 899247664;
      "The Unarchiver" = 425424353;   # moved from casks
      "WhatsApp"       = 310633997;   # moved from casks
      "Zone Bar"       = 6755328989;
    };
  };

  # ─── Nixpkgs packages (macOS-only) ──────────────────────────────────────────
  # Cross-platform development packages live in settings/config/packages.nix
  # → development. Only add things here that are macOS-specific or provide
  # GNU replacements for the BSD tools macOS ships by default.
  packages = [
    # GNU replacements for BSD tools macOS ships
    "coreutils"        # GNU ls/cp/mv/etc (macOS has BSD variants)
    "parallel"         # GNU parallel
    "stow"             # GNU stow (symlink farm manager)
    "netcat"           # GNU netcat (macOS has BSD nc)

    # Dev libraries needed on PATH for building on macOS
    # (on NixOS these are pulled in automatically as build deps)
    "openssl"
    "readline"
    "ncurses"
    "pcre"
    "pcre2"
    "libffi"

    # ── GUI apps (migrated from Homebrew Cask) ────────────────────────────────
    # These are available in nixpkgs and managed declaratively.
    # mac-app-util (already in the flake) ensures they appear in Spotlight/Launchpad.
    "discord"          # Communication
    "signal-desktop-bin" # Signal — officially the darwin path per nixpkgs 25.11 release notes
    # element-desktop   — build requires Xcode 26 unavailable in Nix sandbox on darwin
    "obsidian"         # Note-taking
    "vscode"           # Editor (note: vscode-fhs fails on darwin, plain vscode is fine)
    "spotify"          # Music
    "transmission_4"   # BitTorrent client
    # filezilla         — Linux-only in nixpkgs, installed via Homebrew cask instead
    # parsec-bin        — Linux-only in nixpkgs, installed via Homebrew cask instead
    # prismlauncher     — wayland dep build failure on darwin (nixpkgs issue #455247)
  ];

}
