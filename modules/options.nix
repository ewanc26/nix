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
  listInt = types.listOf types.int;
  nullStr = types.nullOr types.str;
  attrsInt = types.attrsOf types.int;

in
{
  options.myConfig = {

    # ── User ──────────────────────────────────────────────────────────────────
    user = {
      username = mkOption {
        type = str;
        default = "ewan";
      };
      githubUsername = mkOption {
        type = str;
        default = "ewanc26";
        description = "GitHub username for cloning repos into ~/Developer/Git.";
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
          "yarn"
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
          "taplo"
          "markdownlint-cli"
          "prettier"
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
          "nextcloud-client"
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
          "bitwarden-desktop"
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
        default = "adw-gtk3-dark";
        description = "GTK theme name.";
      };

      iconTheme = mkOption {
        type = str;
        default = "Papirus-Dark";
      };

      plasma = {
        colorScheme = mkOption {
          type = str;
          default = "BreezeDark";
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
        default = "Default Dark Modern";
      };
      iconTheme = mkOption {
        type = str;
        default = "vs-seti";
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
      pdsGatekeeper.enable = mkOption {
        type = bool;
        default = false;
        description = "Enable PDS Gatekeeper (2FA proxy for the ATProto PDS). Requires services.pds.enable = true.";
      };
      nextcloud.enable = mkOption {
        type = bool;
        default = false;
      };
      immich.enable = mkOption {
        type = bool;
        default = false;
      };
      jellyfin.enable = mkOption {
        type = bool;
        default = false;
      };
      cloudflare.enable = mkOption {
        type = bool;
        default = false;
      };
      vaultwarden.enable = mkOption {
        type = bool;
        default = false;
      };
      gotosocial.enable = mkOption {
        type = bool;
        default = false;
        description = "Enable GoToSocial ActivityPub server.";
      };
      timemachine = {
        enable = mkOption {
          type = bool;
          default = false;
          description = "Enable Time Machine backup target via Samba vfs_fruit (SMB, Tailscale only).";
        };
      };
    };

    # ── Nextcloud ─────────────────────────────────────────────────────────────
    nextcloud = {
      hostname = mkOption {
        type = str;
        default = "cloud.ewancroft.uk";
      };
      port = mkOption {
        type = int;
        default = 8085;
        description = "Internal nginx port — not exposed, Caddy proxies to this.";
      };
      caddyPort = mkOption {
        type = int;
        default = 3003;
        description = "Caddy virtual host port — used by the Cloudflare tunnel.";
      };
      adminUser = mkOption {
        type = str;
        default = "ewan";
      };
      dataDir = mkOption {
        type = str;
        default = "/srv/nextcloud";
        description = "Root directory for all Nextcloud state (config, apps, data).";
      };
      defaultPhoneRegion = mkOption {
        type = str;
        default = "GB";
      };
      maxUploadSize = mkOption {
        type = str;
        default = "50G";
      };
      smtp = {
        fromAddress = mkOption {
          type = str;
          default = "nextcloud@server.ewancroft.uk";
        };
        fromDomain = mkOption {
          type = str;
          default = "server.ewancroft.uk";
        };
      };
    };

    # ── Immich ────────────────────────────────────────────────────────────────
    immich = {
      hostname = mkOption {
        type = str;
        default = "immich.ewancroft.uk";
        description = "Hostname used by Caddy for Immich — should resolve to the server's Tailscale IP via a Cloudflare A record.";
      };
      port = mkOption {
        type = int;
        default = 2283;
        description = "Internal Immich server port — not exposed, Caddy proxies to this.";
      };
      caddyPort = mkOption {
        type = int;
        default = 3004;
        description = "Caddy virtual host port — accessible only via Tailnet (not in allowedTCPPorts).";
      };
      mediaDir = mkOption {
        type = str;
        default = "/srv/immich";
        description = "Primary media directory for Immich uploads and assets.";
      };
    };

    # ── Jellyfin ──────────────────────────────────────────────────────────────
    jellyfin = {
      hostname = mkOption {
        type = str;
        default = "jellyfin.ewancroft.uk";
        description = "Hostname used by Caddy for Jellyfin — should resolve to the server's Tailscale IP via a Cloudflare A record.";
      };
      port = mkOption {
        type = int;
        default = 8096;
        description = "Internal Jellyfin HTTP port — not exposed, Caddy proxies to this.";
      };
      caddyPort = mkOption {
        type = int;
        default = 3005;
        description = "Caddy virtual host port — accessible only via Tailnet (not in allowedTCPPorts).";
      };
      dataDir = mkOption {
        type = str;
        default = "/var/lib/jellyfin";
        description = "Jellyfin config/metadata/plugin directory — managed by the NixOS jellyfin service.";
      };
      mediaDir = mkOption {
        type = str;
        default = "/srv/nextcloud/data/ewan/files/Media";
        description = ''
          Root directory created for Jellyfin media libraries. Defaults to inside
                    the Nextcloud user files tree so media uploaded via Nextcloud clients is
                    immediately available to Jellyfin. Add libraries (movies, TV, music etc.)
                    as subdirectories of this path from the Jellyfin web UI after first-run.
                    Override this if nextcloud.dataDir or nextcloud.adminUser differ from defaults.'';
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
      userApiTokenFile = mkOption {
        type = nullStr;
        default = "/run/secrets/forgejo-user-token";
        description = "Path to a file containing a Forgejo user API token. Used to list private repos for ~/Developer/Local. Defaults to the system sops-decrypted path from modules/common.nix.";
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
        default = 2099;
      };
      adminEmail = mkOption {
        type = str;
        default = "contact@ewancroft.uk";
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
          "https://northamerica.firehose.network"
          "https://europe.firehose.network"
          "https://asia.firehose.network"
        ];
      };
    };

    # ── Vaultwarden ──────────────────────────────────────────────────────────
    vaultwarden = {
      hostname = mkOption {
        type = str;
        default = "vault.ewancroft.uk";
        description = "Hostname for Vaultwarden (tailnet only).";
      };
      port = mkOption {
        type = int;
        default = 8222;
        description = "Port Vaultwarden's Rocket HTTP server listens on (localhost).";
      };
      smtpFrom = mkOption {
        type = str;
        default = "vaultwarden@server.ewancroft.uk";
        description = "From address used for Vaultwarden email notifications.";
      };
      smtpFromName = mkOption {
        type = str;
        default = "Vaultwarden";
        description = "Display name used in Vaultwarden notification emails.";
      };
    };

    # ── Time Machine ───────────────────────────────────────────────────────────
    timemachine = {
      path = mkOption {
        type = str;
        default = "/srv/timemachine";
        description = "Directory served as the Netatalk AFP Time Machine volume.";
      };
      volSizeLimitMiB = mkOption {
        type = int;
        default = 512000;
        description = "Maximum backup sparsebundle size in MiB (512000 ≈ 500 GB).";
      };
    };

    # ── GoToSocial ─────────────────────────────────────────────────────────────
    gotosocial = {
      hostname = mkOption {
        type = str;
        default = "ap.ewancroft.uk";
        description = "Public hostname for GoToSocial (the \"host\" config key).";
      };
      accountDomain = mkOption {
        type = str;
        default = "ewancroft.uk";
        description = "Domain for user handles — accounts appear as @user@accountDomain.";
      };
      port = mkOption {
        type = int;
        default = 8080;
        description = "Internal GoToSocial HTTP port.";
      };
      caddyPort = mkOption {
        type = int;
        default = 3006;
        description = "Caddy virtual host port — used by the Cloudflare tunnel.";
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
          type = listInt;
          default = [ 22 ];
        };
        allowedUDPPorts = mkOption {
          type = listInt;
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

      grafana = {
        hostname = mkOption {
          type = str;
          default = "grafana.ewancroft.uk";
          description = "Hostname for the Grafana dashboard (tailnet only).";
        };
        port = mkOption {
          type = int;
          default = 3100;
          description = "Local port Grafana listens on.";
        };
        nextcloudMetrics = mkOption {
          type = bool;
          default = false;
          description = "Enable Nextcloud exporter. Requires the Monitoring app and secrets/nextcloud-metrics-token.";
        };
      };

      acmeCertDir = mkOption {
        type = str;
        default = "/var/lib/acme/ewancroft.uk";
        description = "Directory containing the ACME wildcard cert for *.ewancroft.uk, used by Caddy tailnet vhosts.";
      };

      tailscaleIP = mkOption {
        type = str;
        default = "";
        description = ''
          Server's Tailscale IPv4 address (output of `tailscale ip -4`).
                    Used by split-dns.nix (CoreDNS bind address) and Caddy tailnet vhosts.
                    Set this in hosts/server/default.nix after running `tailscale ip -4`.
        '';
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
            # MediaInfo — standalone GUI/CLI media analyser
            "libmediainfo"
            "media-info"
            "libzen"
            # MAS helper — required for masApps below
            "mas"
            # SDL2 — required by Mesen (NES/SNES emulator) and other SDL apps
            "sdl2"
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
            "prismlauncher"
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
            "nextcloud-vfs"
            "bitwarden"
          ];
        };
        masApps = mkOption {
          type = attrsInt;
          default = {
            "Amphetamine" = 937984704;
            "OneDrive" = 823766827;
            # Steam Link removed — requires Rosetta 2, incompatible with Apple Silicon
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
