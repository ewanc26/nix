{ config, pkgs, ... }:

{
  # System-wide packages converted from brew formulae
  environment.systemPackages = with pkgs; [
    # === Core Utilities ===
    coreutils
    curl
    wget
    tree
    htop
    parallel
    rsync
    stow
    netcat
    nmap
    
    # === Shell & Terminal ===
    zsh
    bash
    
    # === Development Tools ===
    git
    git-filter-repo
    gh                    # GitHub CLI
    
    # === Programming Languages & Runtimes ===
    go
    nodejs_22
    nodePackages.pnpm
    nodePackages.yarn
    python313
    python311
    ruby
    deno
    ollama
    
    # === Python Tools ===
    pipx
    pyenv
    uv                    # Modern Python package installer
    
    # === Media Tools ===
    ffmpeg
    exiftool
    atomicparsley
    get_iplayer
    
    # === System Information ===
    fastfetch
    neofetch
    
    # === Network Tools ===
    tailscale
    websocat
    
    # === Text Processing ===
    jq
    
    # === Build Tools ===
    cmake
    autoconf
    libtool
    pkgconf
    m4
    
    # === Compression ===
    unzip
    zip
    zstd
    xz
    lz4
    brotli
    
    # === Database Tools ===
    sqlite
    
    # === Image Processing ===
    tesseract             # OCR
    
    # === Searching ===
    ripgrep
    fd
    
    # === Obsidian CLI ===
    # Note: obsidian-cli might need to be installed via npm or built separately
    
    # === Java ===
    openjdk21
    
    # === PHP ===
    php
    
    # === Libraries (often auto-installed as dependencies, but can be explicit) ===
    openssl
    readline
    ncurses
    pcre
    pcre2
    libffi
    
    # === Monitoring & Analysis ===
    # Note: screenresolution not available in nixpkgs
    # Use system_profiler or defaults write for screen resolution changes
  ];

  # Enable programs with dedicated options
  programs = {
    zsh.enable = true;
    bash.enable = true;
  };
}
