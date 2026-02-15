{
  # Package configuration

  allowUnfree = true;

  # ── Common CLI utilities (every system: laptop, macmini, server) ─────────────
  common = [
    # System info & monitoring
    "fastfetch"
    "btop"         # Modern htop alternative
    
    # Modern CLI tools
    "eza"          # Modern ls
    "bat"          # Modern cat with syntax highlighting
    "ripgrep"      # Fast grep (rg)
    "fd"           # Fast find
    "fzf"          # Fuzzy finder
    "tree"
    
    # Version control
    "git"
    "lazygit"      # Git TUI
    
    # Archives
    "unzip"
    "zip"
    
    # Editors & multiplexers
    "vim"
    "tmux"
    
    # Network tools
    "wget"
    "curl"
    
    # File sync
    "rsync"
  ];

  # ── Development packages (laptop + macmini – NOT server) ─────────────────────
  # Cross-platform: installed via modules/packages.nix on NixOS and
  # modules/darwin/packages.nix on macOS. Keep macOS-only things in
  # settings/config/darwin.nix → packages.
  development = [
    # Nix tooling
    "nil"              # Nix language server (jnoortheen.nix-ide)
    "nixfmt-rfc-style" # Nix formatter

    # Version control (git is in common)
    "git-filter-repo"
    "gh"               # GitHub CLI

    # Languages & runtimes
    "go"
    "nodejs_22"
    "python313"        # Primary Python version
    "bun"              # Fast TS/JS runtime & bundler
    "pnpm"             # Fast package manager (SvelteKit)
    "rustup"           # Rust toolchain manager
    "dotnet-sdk"       # .NET SDK

    # Go tooling
    "gopls" # Go language server (golang.go extension)
    "golangci-lint" # Go linter
    "delve" # Go debugger

    # Python tooling
    "pipx"
    "uv"
    "ruff" # Fast Python linter + formatter
    "pyright" # Python type checker / language server

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

    # Additional runtimes
    "openjdk21"       # Java LTS
    "php"             # PHP runtime
    "ollama"          # Local LLM runtime
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
    # dconf2nix was only useful for exporting GNOME dconf settings;
    # KDE settings are managed directly by plasma-manager.
  ];

  # ── Desktop/GUI packages (NixOS laptop) ──────────────────────────────────────
  desktop = [
    # Theming
    "papirus-icon-theme"       # Clean minimal icon theme
    
    # Communication
    "discord"
    "signal-desktop"
    
    # Media
    "spotify"
    
    # Productivity
    "obsidian"                 # Note-taking (Markdown)
    "libreoffice-fresh"
    
    # Creative
    "gimp"                     # Image editing
    "inkscape"                 # Vector graphics
    
    # Gaming/Remote
    "parsec-bin"               # Remote gaming/desktop
    "prismlauncher"            # Minecraft launcher
    
    # System tools (KDE System Settings is built-in – no extra package needed)
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
