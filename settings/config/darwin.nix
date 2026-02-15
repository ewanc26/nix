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
    casks = [
      "logitune"
      "logitech-options"
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-teams"
      "microsoft-word"
      "netnewswire"
      "prismlauncher"
    ];

    # Mac App Store apps (by ID)
    masApps = {
      "Amphetamine" = 937984704;
      "EA app" = 1246969117;
      "OP Auto Clicker" = 6754914118;
      "Zone Bar" = 6755328989;
    };
  };

  # ─── Nixpkgs packages (macOS-only) ──────────────────────────────────────────
  # Cross-platform development packages live in settings/config/packages.nix
  # → development. Only add things here that are macOS-specific or provide
  # GNU replacements for the BSD tools macOS ships by default.
  packages = [
    # GNU replacements for BSD tools macOS ships
    "coreutils" # GNU ls/cp/mv/etc (macOS has BSD variants)
    "parallel" # GNU parallel
    "stow" # GNU stow (symlink farm manager)
    "netcat" # GNU netcat (macOS has BSD nc)

    # Dev libraries needed on PATH for building on macOS
    # (on NixOS these are pulled in automatically as build deps)
    "openssl"
    "readline"
    "ncurses"
    "pcre"
    "pcre2"
    "libffi"
  ];

}
