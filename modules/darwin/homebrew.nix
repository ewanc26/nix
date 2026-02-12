{ config, pkgs, ... }:

{
  # Homebrew configuration
  homebrew = {
    enable = true;
    
    # Automatically update Homebrew and upgrade packages
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Cleanup old versions
      cleanup = "zap";
    };
    
    # Taps (repositories)
    taps = [
      "homebrew/cask"
      "homebrew/core"
    ];
    
    # Formulae (CLI tools better managed by Homebrew)
    brews = [
      # Media libraries that are complex in Nix
      "libmediainfo"
      "media-info"
      "libzen"
      
      # Video/Audio codecs and libraries
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
      
      # Misc tools that work better via brew
      "summarize"
      "goat"
    ];
    
    # Casks (GUI applications)
    casks = [
      # Development
      "orbstack"          # Docker alternative for macOS
      
      # Media
      "vlc"
      "imgbrd-grabber"
      
      # Utilities  
      "jordanbaird-ice"   # Menu bar management
      "altserver"         # iOS app sideloading
    ];
    
    # Mac App Store apps (if you want to manage them)
    # masApps = {
    #   "App Name" = 12345678;  # App Store ID
    # };
  };
}
