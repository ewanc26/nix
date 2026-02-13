{ config, pkgs, ... }:

{
  # System-wide packages converted from brew formulae
  environment.systemPackages = with pkgs; [
    # === Core Utilities ===
    coreutils
    curl
    wget
    parallel
    rsync
    stow
    netcat
    nmap

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

    # === Network Tools ===
    tailscale
    websocat
    sshfs                 # Mount remote filesystems over SSH (requires macFUSE)

    # === Text Processing ===
    jq

    # === Build Tools ===
    cmake
    autoconf
    libtool
    pkgconf
    m4

    # === Compression ===
    zstd
    xz
    lz4
    brotli

    # === Database Tools ===
    sqlite

    # === Image Processing ===
    tesseract             # OCR

    # === Java ===
    openjdk21

    # === PHP ===
    php

    # === Libraries ===
    openssl
    readline
    ncurses
    pcre
    pcre2
    libffi
  ];

  # Enable programs with dedicated options
  programs = {
    # zsh.enable is already set in darwin/common.nix
    bash.enable = true;
  };
}
