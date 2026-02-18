# Home-manager configuration — all hosts.
#
# Access system-level options via `osConfig.myConfig.*`.
# Platform detection uses `pkgs.stdenv.isDarwin` — no flags passed as args.
{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  cfg = osConfig.myConfig;
  isDarwin = pkgs.stdenv.isDarwin;

  # Custom scripts from home/scripts/ — available on PATH on both platforms.
  myScripts = pkgs.stdenv.mkDerivation {
    name = "my-scripts";
    src = ./scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/bin/
      chmod +x $out/bin/*
    '';
  };

  allKeys = import ../modules/ssh-keys.nix;
in
{
  imports =
    [
      ./programs/git.nix
      ./programs/zsh.nix
      ./programs/ssh.nix
      ./programs/starship.nix
      ./programs/fastfetch.nix
      ./programs/vscode.nix
    ]
    ++ lib.optionals (!isDarwin) [
      ./programs/terminal.nix # Konsole profile — all non-Darwin hosts
    ]
    ++ lib.optionals (cfg.isDesktop && !isDarwin) [
      ./programs/kde.nix # KDE Plasma settings — Linux desktop only
    ];

  home = {
    username = cfg.user.username;
    homeDirectory = if isDarwin then "/Users/${cfg.user.username}" else "/home/${cfg.user.username}";
    stateVersion = cfg.stateVersion;

    packages =
      [ myScripts ]
      ++ map (font: pkgs.nerd-fonts.${font}) cfg.packages.fonts
      ++ lib.optionals (!isDarwin) (
        map (pkg: pkgs.${pkg}) cfg.packages.linux
      );

    # SSH authorised keys — all machines except this one.
    # Filter by hostname so each host does not authorise its own key.
    file.".ssh/authorized_keys".text =
      let
        hostName = osConfig.networking.hostName;
        filteredKeys = lib.attrValues (
          lib.filterAttrs (name: _: name != hostName) allKeys
        );
      in
      builtins.concatStringsSep "\n" filteredKeys;

    file.".ssh/allowed_signers".text =
      let
        entries = lib.mapAttrsToList (_: key: "${cfg.user.email} ${key}") allKeys;
        validEntries = lib.filter (e: !(lib.hasInfix "REPLACE_WITH" e)) (lib.unique entries);
      in
      builtins.concatStringsSep "\n" validEntries + "\n";

    file.".gitignore_global".text = builtins.concatStringsSep "\n" [
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Thumbs.db"
      ".vscode/"
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"
      "*.tmp"
      "*.bak"
      "*.log"
    ];
  };

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  # ── Linux-only theming ────────────────────────────────────────────────────
  gtk = lib.mkIf (!isDarwin) {
    enable = true;
    theme = {
      name = cfg.desktop.theme;
      package = pkgs.catppuccin-gtk.override {
        accents = [ "green" ];
        variant = "mocha";
      };
    };
    iconTheme.name = cfg.desktop.iconTheme;
  };

  qt = lib.mkIf (!isDarwin) {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  catppuccin = lib.mkIf (!isDarwin) {
    enable = true;
    flavor = "mocha";
    accent = "green";
    starship.enable = false;
  };

  # ── macOS: wallpaper via desktoppr ───────────────────────────────────────
  programs.desktoppr = lib.mkIf isDarwin {
    enable = true;
    settings.picture = "${../wallpapers/wallpaper.jpg}";
  };

  # ── Encrypted secrets (sops-nix) ─────────────────────────────────────────
  sops.secrets = lib.mkMerge [
    (lib.mkIf cfg.secrets.docker.enable {
      "docker-config" = {
        sopsFile = ../secrets/docker-config.json;
        path = "${config.home.homeDirectory}/.docker/config.json";
        mode = "0600";
      };
    })

    (lib.mkIf cfg.secrets.claude.enable {
      "claude-config" = {
        sopsFile = ../secrets/claude.json;
        path = "${config.home.homeDirectory}/.claude.json";
        mode = "0600";
      };
    })

    (lib.mkIf cfg.secrets.duckdns.enable {
      "duckdns" = {
        sopsFile = ../secrets/duckdns.tar.gz;
      };
    })
  ];

  # Extract DuckDNS tarball on activation.
  home.activation.setupDuckDNS = lib.mkIf cfg.secrets.duckdns.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "${config.sops.secrets.duckdns.path}" ]; then
        $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.duckdns"
        $DRY_RUN_CMD tar -xzf "${config.sops.secrets.duckdns.path}" \
          -C "${config.home.homeDirectory}"
      fi
    ''
  );
}
