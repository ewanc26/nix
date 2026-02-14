{
  # macOS configuration (nix-darwin)

  # ─── Keyboard ────────────────────────────────────────────────────────────────
  keyboard = {
    enableKeyMapping        = true;
    remapCapsLockToControl  = false;  # Keep Caps Lock as Caps Lock
  };

  # ─── Startup ─────────────────────────────────────────────────────────────────
  startup = {
    chime = false;  # Silence the boot chime
  };

  # ─── Security ────────────────────────────────────────────────────────────────
  security = {
    touchIdForSudo = true;  # Allow Touch ID to authenticate sudo
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
    ];

    # GUI applications via Homebrew Cask
    casks = [
      "orbstack"          # Docker alternative for macOS
      "vlc"
      "imgbrd-grabber"
      "jordanbaird-ice"   # Menu bar management
      "altserver"         # iOS app sideloading
    ];

    # Mac App Store apps (by ID)
    masApps = {
      # "App Name" = 123456789;
    };
  };

  # ─── Nixpkgs packages ────────────────────────────────────────────────────────
  # All packages installed via nixpkgs on macOS.
  # Must be top-level nixpkgs attribute names.
  packages = [
    # Core utilities
    "coreutils"
    "curl"
    "wget"
    "parallel"
    "rsync"
    "stow"
    "netcat"
    "nmap"

    # Development tools
    "git"
    "git-filter-repo"
    "gh"

    # Programming languages & runtimes
    "go"
    "nodejs_22"
    "python313"
    "python311"
    "ruby"
    "deno"
    "ollama"

    # Python tooling
    "pipx"
    "pyenv"
    "uv"

    # Media tools
    "ffmpeg"
    "exiftool"
    "atomicparsley"
    "get_iplayer"

    # Network tools
    "tailscale"
    "websocat"
    "sshfs"

    # Text processing
    "jq"

    # Build tools
    "cmake"
    "autoconf"
    "libtool"
    "pkgconf"
    "m4"

    # Compression
    "zstd"
    "xz"
    "lz4"
    "brotli"

    # Database tools
    "sqlite"

    # Image processing
    "tesseract"

    # Java
    "openjdk21"

    # PHP
    "php"

    # Libraries
    "openssl"
    "readline"
    "ncurses"
    "pcre"
    "pcre2"
    "libffi"
  ];

  # ─── System preferences ──────────────────────────────────────────────────────
  # These document intent; the canonical values live in settings/darwin/domains/.
  system = {
    defaults = {
      dock = {
        autohide    = true;
        orientation = "bottom";
        tilesize    = 48;
      };

      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar            = true;
        ShowStatusBar          = true;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat       = 15;
        KeyRepeat              = 2;
      };
    };
  };
}
