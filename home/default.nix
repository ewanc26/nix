# Home-manager configuration — all hosts.
#
# Access system-level options via `osConfig.myConfig.*`.
# Platform detection: `isDarwin` is passed via extraSpecialArgs in flake.nix.
{
  config,
  pkgs,
  lib,
  osConfig,
  isDarwin,
  ...
}:
let
  cfg = osConfig.myConfig;

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
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
    ./programs/ssh.nix
  ]
  ++ lib.optionals (!isDarwin) [
    ./programs/terminal.nix # Konsole profile — all non-Darwin hosts
  ]
  ++ lib.optionals (cfg.isDesktop && !isDarwin) [
    ./programs/kde.nix # KDE Plasma settings — Linux desktop only
    ./programs/vscode.nix # VSCode — desktop only
  ]
  ++ lib.optionals (cfg.isDesktop) [
    ./programs/starship.nix
  ]
  ++ [
    ./programs/fastfetch.nix
  ];

  home = {
    username = cfg.user.username;
    homeDirectory = if isDarwin then "/Users/${cfg.user.username}" else "/home/${cfg.user.username}";
    stateVersion = cfg.stateVersion;

    packages = [
      myScripts
    ]
    ++ map (font: pkgs.nerd-fonts.${font}) cfg.packages.fonts
    ++ lib.optionals (!isDarwin) (map (pkg: pkgs.${pkg}) cfg.packages.linux);

    # SSH authorised keys — all machines except this one.
    # Filter by hostname so each host does not authorise its own key.
    file.".ssh/authorized_keys".text =
      let
        hostName = osConfig.networking.hostName;
        filteredKeys = lib.attrValues (lib.filterAttrs (name: _: name != hostName) allKeys);
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

  # ── Nextcloud desktop client ─────────────────────────────────────────────
  # Both activation scripts below patch nextcloud.cfg in-place so that
  # credentials/tokens already written by the client are preserved.

  # Enable VFS (virtual files) for all configured sync folders — files appear
  # as lightweight placeholders locally and are only downloaded on access,
  # keeping the primary copy on the server. Linux uses "suffix" mode (.nextcloud
  # placeholder files); this is a no-op if VFS is already on or if the cfg
  # file doesn't exist yet (new installs pick it up after first sync setup).
  home.activation.nextcloudVFS = lib.mkIf (cfg.isDesktop && !isDarwin) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg_file="$HOME/.config/Nextcloud/nextcloud.cfg"
      if [ -f "$cfg_file" ]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/virtualFilesMode=off/virtualFilesMode=suffix/g' "$cfg_file"
      fi
    ''
  );

  # Allow syncing files of any size (client default blocks files over ~500 MB).
  home.activation.nextcloudMaxSize = lib.mkIf cfg.isDesktop (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg_file="$HOME/.config/Nextcloud/nextcloud.cfg"
      if [ -f "$cfg_file" ]; then
        if grep -q "maxSizeEnabled" "$cfg_file"; then
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/^maxSizeEnabled=.*/maxSizeEnabled=false/' "$cfg_file"
        else
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i '/\[General\]/a maxSizeEnabled=false' "$cfg_file"
        fi
      fi
    ''
  );

  fonts.fontconfig.enable = true;

  # ── Linux-only theming ────────────────────────────────────────────────────
  gtk = lib.mkIf (!isDarwin && cfg.isDesktop) {
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

  qt = lib.mkIf (!isDarwin && cfg.isDesktop) {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  catppuccin = lib.mkIf (!isDarwin && cfg.isDesktop) {
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
  # Tell the home-manager sops module to decrypt using the host's SSH ed25519
  # key as an age key — same source as the system-level sops in common.nix.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
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

  ];
}
