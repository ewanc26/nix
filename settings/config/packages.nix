{
  # Package configuration

  allowUnfree = true;

  # ── Common CLI utilities (every system: laptop, macmini, server) ─────────────
  common = [
    "fastfetch"
    "htop"
    "tree"
    "ripgrep"
    "fd"
    "unzip"
    "zip"
    "vim"
    "wget"
    "curl"
    "tmux"
    "rsync"
  ];

  # ── Development packages (laptop + macmini – NOT server) ─────────────────────
  # Cross-platform: installed via modules/packages.nix on NixOS and
  # modules/darwin/packages.nix on macOS. Keep macOS-only things in
  # settings/config/darwin.nix → packages.
  development = [
    # Nix tooling
    "nil"               # Nix language server (jnoortheen.nix-ide)
    "nixfmt-rfc-style"  # Nix formatter

    # Version control
    "git"
    "git-filter-repo"
    "gh"

    # Languages & runtimes
    "go"
    "nodejs_22"
    "python313"
    "python311"
    "bun"               # Fast TS/JS runtime & bundler (TypeScript repos)
    "pnpm"              # SvelteKit standard package manager
    "rustup"            # Rust toolchain manager
    "dotnet-sdk"        # C# / VB.NET

    # Go tooling
    "gopls"             # Go language server (golang.go extension)
    "golangci-lint"     # Go linter
    "delve"             # Go debugger

    # Python tooling
    "pipx"
    "uv"
    "ruff"              # Fast Python linter + formatter
    "pyright"           # Python type checker / language server

    # Build tools
    "cmake"
    "autoconf"
    "libtool"
    "pkgconf"
    "m4"

    # Media processing
    "ffmpeg"
    "exiftool"
    "atomicparsley"
    "get_iplayer"

    # Network / infra
    "tailscale"
    "websocat"
    "nmap"

    # Text processing
    "jq"

    # Compression
    "zstd"
    "xz"
    "lz4"
    "brotli"

    # Database
    "sqlite"

    # Image processing / OCR
    "tesseract"

    # Runtimes kept for project compatibility
    "openjdk21"
    "php"
    "ollama"
    "pyenv"
  ];

  # ── Nerd Fonts to install ─────────────────────────────────────────────────────
  fonts = [
    "fira-code"
    "jetbrains-mono"
    "meslo-lg"
    "roboto-mono"
    "sauce-code-pro"
    "ubuntu-mono"
  ];

  # ── Linux-only packages ───────────────────────────────────────────────────────
  linux = [
    "vlc"
    "dconf2nix"
  ];

  # ── Desktop/GUI packages (NixOS laptop) ──────────────────────────────────────
  desktop = [
    "discord"
    "signal-desktop"
    "spotify"
    "gimp"
    "inkscape"
    "libreoffice-fresh"
    "prismlauncher"
    "gnome-extension-manager"
  ];

  # ── Gaming packages ───────────────────────────────────────────────────────────
  gaming = [
    "steam"
    "lutris"
    "wine"
    "winetricks"
  ];

  # ── Server-only packages ──────────────────────────────────────────────────────
  server = [
    # git + rsync come from common; only add server-specific extras here
  ];
}
