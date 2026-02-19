# Central NixOS module options — single source of truth for all configurable
# values shared across hosts, modules, and home-manager.
#
# System modules access these via `config.myConfig.*`.
# Home-manager modules access them via `osConfig.myConfig.*`.
#
# Per-host overrides live in hosts/<name>/default.nix.
{
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  # --------------------------------------------------------------------------
  # Type aliases
  # --------------------------------------------------------------------------
  str = types.str;
  int = types.int;
  bool = types.bool;
  listStr = types.listOf types.str;
  nullStr = types.nullOr types.str;

in
{
  options.myConfig = {

    # ── User ──────────────────────────────────────────────────────────────────
    user = {
      username = mkOption {
        type = str;
        default = "ewan";
      };
      fullName = mkOption {
        type = str;
        default = "Ewan Croft";
      };
      email = mkOption {
        type = str;
        default = "git@ewancroft.uk";
      };
    };

    # ── System ────────────────────────────────────────────────────────────────
    stateVersion = mkOption {
      type = str;
      default = "25.11";
      description = "NixOS / home-manager state version.";
    };

    timeZone = mkOption {
      type = str;
      default = "Europe/London";
    };

    locale = mkOption {
      type = str;
      default = "en_GB.UTF-8";
    };

    # ── Host type ─────────────────────────────────────────────────────────────
    isDesktop = mkOption {
      type = bool;
      default = false;
      description = "Whether this host is an interactive desktop system.";
    };

    # ── Audio ─────────────────────────────────────────────────────────────────
    audio = {
      enable = mkOption {
        type = bool;
        default = true;
      };
      backend = mkOption {
        type = types.enum [
          "pipewire"
          "pulseaudio"
        ];
        default = "pipewire";
      };
    };

    # ── Gaming ────────────────────────────────────────────────────────────────
    gaming = {
      enable = mkOption {
        type = bool;
        default = false;
      };
      steam = {
        enable = mkOption {
          type = bool;
          default = true;
        };
        openFirewall = mkOption {
          type = bool;
          default = false;
        };
      };
    };

    # ── Packages ──────────────────────────────────────────────────────────────
    packages = {
      common = mkOption {
        type = listStr;
        default = [
          "fastfetch"
          "btop"
          "eza"
          "bat"
          "ripgrep"
          "fd"
          "fzf"
          "tree"
          "git"
          "lazygit"
          "unzip"
          "zip"
          "nano"
          "tmux"
          "openssh"
          "wget"
          "curl"
          "rsync"
        ];
      };

      development = mkOption {
        type = listStr;
        default = [
          "nil"
          "nixfmt-rfc-style"
          "git-filter-repo"
          "gh"
          "go"
          "nodejs_22"
          "python313"
          "bun"
          "pnpm"
          "rustup"
          "dotnet-sdk"
          "gopls"
          "golangci-lint"
          "delve"
          "pipx"
          "uv"
          "ruff"
          "pyright"
          "shellcheck"
          "shfmt"
          "cmake"
          "autoconf"
          "libtool"
          "pkgconf"
          "m4"
          "ffmpeg"
          "exiftool"
          "atomicparsley"
          "get_iplayer"
          "tailscale"
          "websocat"
          "nmap"
          "jq"
          "zstd"
          "xz"
          "lz4"
          "brotli"
          "sqlite"
          "tesseract"
          "openjdk21"
          "php"
          "ollama"
        ];
      };

      fonts = mkOption {
        type = listStr;
        default = [
          "fira-code"
          "jetbrains-mono"
          "meslo-lg"
          "roboto-mono"
          "sauce-code-pro"
          "ubuntu-mono"
        ];
      };

      linux = mkOption {
        type = listStr;
        default = [ "vlc" ];
      };

      desktop = mkOption {
        type = listStr;
        default = [
          "papirus-icon-theme"
          "discord"
          "signal-desktop"
          "element-desktop"
          "spotify"
          "obsidian"
          "libreoffice-fresh"
          "gimp"
          "inkscape"
          "parsec-bin"
          "prismlauncher"
        ];
      };

      gaming = mkOption {
        type = listStr;
        default = [
          "steam"
          "lutris"
          "wine"
          "winetricks"
        ];
      };

      server = mkOption {
        type = listStr;
        default = [ ];
        description = "Server-only packages (added on top of common + development).";
      };

      darwin = mkOption {
        type = listStr;
        default = [
          # GNU/POSIX replacements — macOS ships older BSD versions
          "coreutils"
          "parallel"
          "stow"
          "netcat"
          # Build / link libraries expected by many CLI tools
          "openssl"
          "readline"
          "ncurses"
          "pcre"
          "pcre2"
          "libffi"
          # NOTE: GUI apps (discord, signal, obsidian, vscode, spotify,
          # transmission) are intentionally absent here. On a 256 GB Mac
          # they are better installed as Homebrew casks: Homebrew stores
          # only one copy of the .app and Spotlight / Launch Services work
          # natively, whereas Nix would keep every old version in the store.
          # See myConfig.darwin.homebrew.casks below.
        ];
      };
    };

    # ── Desktop theming ───────────────────────────────────────────────────────
    desktop = {
      environment = mkOption {
        type = str;
        default = "plasma6";
        description = "Desktop environment name (e.g. plasma6, gnome).";
      };

      displayManager = mkOption {
        type = str;
        default = "sddm";
        description = "Display manager (e.g. sddm, gdm).";
      };

      uiFont = mkOption {
        type = str;
        default = "Noto Sans";
      };

      uiFontSize = mkOption {
        type = int;
        default = 10;
      };

      monoFontBase = mkOption {
        type = str;
        default = "FiraCode";
        description = "Base monospace font family (no Nerd Font suffix).";
      };

      monoFontFamily = mkOption {
        type = str;
        default = "FiraCode Nerd Font Mono";
        description = "Full Nerd Font monospace family (for terminals and KDE).";
      };

      monoFontSize = mkOption {
        type = int;
        default = 11;
      };

      theme = mkOption {
        type = str;
        default = "Catppuccin-Mocha-Standard-Green-Dark";
        description = "GTK theme name.";
      };

      iconTheme = mkOption {
        type = str;
        default = "Papirus-Dark";
      };

      plasma = {
        colorScheme = mkOption {
          type = str;
          default = "CatppuccinMochaGreen";
        };

        desktopTheme = mkOption {
          type = str;
          default = "breeze-dark";
        };

        excludePackages = mkOption {
          type = listStr;
          default = [
            "oxygen"
            "elisa"
          ];
        };
      };
    };

    # ── SSH ───────────────────────────────────────────────────────────────────
    ssh = {
      keyFile = mkOption {
        type = str;
        default = "~/.ssh/id_ed25519";
      };
    };

    # ── Git ───────────────────────────────────────────────────────────────────
    git = {
      defaultBranch = mkOption {
        type = str;
        default = "main";
      };
      editor = mkOption {
        type = str;
        default = "code --wait";
      };
      lfs.enable = mkOption {
        type = bool;
        default = true;
      };
      signing = {
        enabled = mkOption {
          type = bool;
          default = true;
        };
        format = mkOption {
          type = str;
          default = "ssh";
        };
      };
    };

    # ── Development / VS Code ─────────────────────────────────────────────────
    development.vscode = {
      enable = mkOption {
        type = bool;
        default = true;
      };
      colorTheme = mkOption {
        type = str;
        default = "Catppuccin Mocha";
      };
      iconTheme = mkOption {
        type = str;
        default = "catppuccin-vsc-icons";
      };
      fontSize = mkOption {
        type = int;
        default = 14;
      };
      terminalFontSize = mkOption {
        type = int;
        default = 13;
      };
      lineHeight = mkOption {
        type = int;
        default = 22;
      };
      fontLigatures = mkOption {
        type = bool;
        default = true;
      };
    };

    # ── Secrets ───────────────────────────────────────────────────────────────
    secrets = {
      docker.enable = mkOption {
        type = bool;
        default = false;
      };
      claude.enable = mkOption {
        type = bool;
        default = false;
      };
    };

    # ── Server service toggles ────────────────────────────────────────────────
    services = {
      forgejo.enable = mkOption {
        type = bool;
        default = false;
      };
      pds.enable = mkOption {
        type = bool;
        default = false;
      };
      cloudflare.enable = mkOption {
        type = bool;
        default = false;
      };
    };

    # ── Forgejo ───────────────────────────────────────────────────────────────
    forgejo = {
      hostname = mkOption {
        type = str;
        default = "git.ewancroft.uk";
      };
      port = mkOption {
        type = int;
        default = 3001;
      };
      caddyPort = mkOption {
        type = int;
        default = 3002;
      };
      appName = mkOption {
        type = str;
        default = "Ewan's Git";
      };
      disableRegistration = mkOption {
        type = bool;
        default = true;
      };
    };

    # ── PDS ───────────────────────────────────────────────────────────────────
    pds = {
      hostname = mkOption {
        type = str;
        default = "pds.ewancroft.uk";
      };
      port = mkOption {
        type = int;
        default = 3000;
      };
      caddyPort = mkOption {
        type = int;
        default = 2020;
      };
      adminEmail = mkOption {
        type = str;
        default = "pds@ewancroft.uk";
      };
      serviceHandleDomains = mkOption {
        type = listStr;
        default = [ ".ewancroft.uk" ];
      };
      crawlers = mkOption {
        type = listStr;
        default = [
          "https://bsky.network"
          "https://relay.cerulea.blue"
          "https://relay.fire.hose.cam"
          "https://relay2.fire.hose.cam"
          "https://relay3.fr.hose.cam"
          "https://relay.hayescmd.net"
          "https://relay.xero.systems"
          "https://relay.upcloud.world"
          "https://relay.feeds.blue"
          "https://atproto.africa"
        ];
      };
    };

    # ── Cloudflare ────────────────────────────────────────────────────────────
    cloudflare = {
      tunnelId = mkOption {
        type = str;
        default = "2c3ef2e9-fd2d-4e03-8f3f-6fc87954272f";
        description = "Cloudflare Tunnel UUID from `cloudflared tunnel create`.";
      };
    };

    # ── Server infrastructure ─────────────────────────────────────────────────
    server = {

      timemachine = {
        enable = mkOption {
          type = bool;
          default = false;
        };
        shareName = mkOption {
          type = str;
          default = "TimeMachine";
        };
        path = mkOption {
          type = str;
          default = "/srv/timemachine";
        };
        maxSizeGB = mkOption {
          type = int;
          default = 0;
          description = "Soft cap in GB reported to macOS. 0 = unlimited.";
        };
        validUsers = mkOption {
          type = listStr;
          default = [ ];
        };
      };

      sshd = {
        enable = mkOption {
          type = bool;
          default = true;
        };
        permitRootLogin = mkOption {
          type = str;
          default = "no";
        };
        passwordAuthentication = mkOption {
          type = bool;
          default = false;
        };
        kbdInteractiveAuthentication = mkOption {
          type = bool;
          default = false;
        };
        port = mkOption {
          type = int;
          default = 22;
        };
        maxAuthTries = mkOption {
          type = int;
          default = 3;
        };
        clientAliveInterval = mkOption {
          type = int;
          default = 300;
        };
        clientAliveCountMax = mkOption {
          type = int;
          default = 2;
        };
        x11Forwarding = mkOption {
          type = bool;
          default = false;
        };
      };

      fail2ban = {
        enable = mkOption {
          type = bool;
          default = true;
        };
        maxRetry = mkOption {
          type = int;
          default = 5;
        };
        banTime = mkOption {
          type = int;
          default = 600;
        };
        findTime = mkOption {
          type = int;
          default = 600;
        };
      };

      firewall = {
        enable = mkOption {
          type = bool;
          default = true;
        };
        allowPing = mkOption {
          type = bool;
          default = true;
        };
        allowedTCPPorts = mkOption {
          type = types.listOf int;
          default = [ 22 ];
        };
        allowedUDPPorts = mkOption {
          type = types.listOf int;
          default = [ ];
        };
      };

      servicePolicy = {
        restartSec = mkOption {
          type = int;
          default = 5;
        };
        startLimitIntervalSec = mkOption {
          type = int;
          default = 300;
        };
        startLimitBurst = mkOption {
          type = int;
          default = 5;
        };
      };

      storage.srv = {
        device = mkOption {
          type = str;
          default = "/dev/disk/by-uuid/1811845c-15ab-49c3-8d33-411aad84bce3";
        };
        fsType = mkOption {
          type = str;
          default = "ext4";
        };
        options = mkOption {
          type = listStr;
          default = [
            "defaults"
            "noatime"
          ];
        };
      };

      cockpit = {
        enable = mkOption {
          type = bool;
          default = true;
        };
        port = mkOption {
          type = int;
          default = 9090;
        };
      };
    };

    # ── Darwin ────────────────────────────────────────────────────────────────
    darwin = {

      # ── External storage ──────────────────────────────────────────────────────
      externalDisk.timeMachineVolumeUUID = mkOption {
        type = nullStr;
        default = null;
        description = ''
          Volume UUID of the APFS volume to use for local Time Machine backups.
          Set to null to disable. See docs/time-machine.md for setup instructions.
        '';
      };

      keyboard = {
        enableKeyMapping = mkOption {
          type = bool;
          default = true;
        };
        remapCapsLockToControl = mkOption {
          type = bool;
          default = false;
        };
      };

      startup.chime = mkOption {
        type = bool;
        default = true;
      };

      security.touchIdForSudo = mkOption {
        type = bool;
        default = true;
      };

      homebrew = {
        enable = mkOption {
          type = bool;
          default = true;
        };
        taps = mkOption {
          type = listStr;
          default = [ ];
        };
        brews = mkOption {
          type = listStr;
          default = [
            "libmediainfo"
            "media-info"
            "libzen"
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
            "little-cms2"
            "leptonica"
            "rtmpdump"
            "srt"
            "librist"
            "libmms"
            "lzo"
            "snappy"
            "xxhash"
            "yyjson"
            "freetds"
            "unixodbc"
            "summarize"
            "goat"
            "mas"
          ];
        };
        casks = mkOption {
          type = listStr;
          default = [
            # Communication / social
            "discord"
            "signal"
            "element"
            # Productivity / notes
            "obsidian"
            "netnewswire"
            # Development
            "visual-studio-code"
            "github"
            # Media
            "spotify"
            "obs"
            "handbrake-app"
            "transmission"
            # AI
            "claude"
            # Browsers
            "firefox"
            # Gaming
            "steam"
            "epic-games"
            "prismlauncher"
            "roblox"
            "ea"
            # Virtualisation
            "utm"
            # Networking / remote
            "cloudflare-warp"
            "tailscale-app"
            "parsec"
            # System utilities
            "onyx"
            "mos"
            "altserver"
            # Logitech peripherals
            "logitune"
            "logi-options+"
            # Microsoft Office
            "microsoft-excel"
            "microsoft-powerpoint"
            "microsoft-teams"
            "microsoft-word"
            "libreoffice"
          ];
        };
        masApps = mkOption {
          type = types.attrsOf int;
          default = {
            "Amphetamine" = 937984704;
            "OneDrive" = 823766827;
            "OP Auto Clicker" = 6754914118;
            "Steam Link" = 1246969117;
            "TestFlight" = 899247664;
            "The Unarchiver" = 425424353;
            "WhatsApp" = 310633997;
            "Zone Bar" = 6755328989;
          };
        };
      };
    };

  };
}
