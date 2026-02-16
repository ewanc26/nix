{ pkgs, lib, isDarwin, isDesktop, hostName, extraSpecialArgs ? {}, ... }:
{ config, cfgLib, ... }:

let
  cfg        = cfgLib.cfg;
  userConfig = cfg.user;
  homeDir    = extraSpecialArgs.homeDirectory or (
    if isDarwin then "/Users/${userConfig.username}"
    else             "/home/${userConfig.username}"
  );

  # Custom scripts from home/scripts/ — available on PATH on both platforms.
  myScripts = pkgs.stdenv.mkDerivation {
    name = "my-scripts";
    src  = ./scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/bin/
      chmod +x $out/bin/*
    '';
  };
in
{
  imports = [
    ./programs/git.nix
    ./programs/yarn.nix
    (import ./programs/zsh.nix { inherit hostName isDarwin; })
    (import ./programs/ssh.nix { inherit isDarwin; })
    ./programs/starship.nix
    ./programs/fastfetch.nix
    ./programs/vscode.nix
  ] ++ lib.optionals (!isDarwin) [
    ./programs/terminal.nix   # Konsole profile — all non-Darwin hosts
  ] ++ lib.optionals isDesktop [
    ./programs/kde.nix        # KDE Plasma settings — desktop only
  ];

  home = {
    username      = userConfig.username;
    homeDirectory = homeDir;
    stateVersion  = cfg.system.stateVersion;

    packages =
      # Custom scripts from home/scripts/
      [ myScripts ]
      # Nerd Fonts (home-manager is the canonical place for fonts)
      ++ map (font: pkgs.nerd-fonts.${font}) cfg.packages.fonts
      # Linux-only packages
      ++ lib.optionals (!isDarwin) (map (pkg: pkgs.${pkg}) cfg.packages.linux);

    # SSH authorised keys — all machines except this one (so each host can SSH
    # to the others without a password prompt).
    file.".ssh/authorized_keys" = {
      text =
        let
          allKeys      = import ../modules/ssh-keys.nix;
          filteredKeys = lib.attrValues (lib.filterAttrs (name: _: name != hostName) allKeys);
        in
          builtins.concatStringsSep "\n" filteredKeys;
    };

    file.".ssh/allowed_signers".text =
      let
        allKeys     = import ../modules/ssh-keys.nix;
        entries     = lib.mapAttrsToList (_: key: "${cfg.user.email} ${key}") allKeys;
        validEntries = lib.filter (e: !(lib.hasInfix "REPLACE_WITH" e)) (lib.unique entries);
      in
        builtins.concatStringsSep "\n" validEntries + "\n";

    file.".gitignore_global".text = builtins.concatStringsSep "\n" cfg.git.globalIgnore;
  };

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  # ─── Linux-only theming ───────────────────────────────────────────────────────

  gtk = lib.mkIf (!isDarwin) {
    enable = true;
    theme = {
      name    = cfg.desktop.theme;
      package = pkgs.catppuccin-gtk.override {
        accents = [ "green" ];
        variant = "mocha";
      };
    };
    iconTheme.name = cfg.desktop.iconTheme;
  };

  qt = lib.mkIf (!isDarwin) {
    enable              = true;
    platformTheme.name  = "kvantum";
    style.name          = "kvantum";
  };

  # Catppuccin module (shared modules in flake.nix) — Linux only.
  # Starship keeps its own custom forest_dark theme; disable the override.
  catppuccin = lib.mkIf (!isDarwin) {
    enable         = true;
    flavor         = "mocha";
    accent         = "green";
    starship.enable = false;
  };

  # ─── macOS-only: wallpaper via desktoppr ──────────────────────────────────────
  # KDE wallpaper is set in home/programs/kde.nix via plasma-manager.
  programs.desktoppr = lib.mkIf isDarwin {
    enable   = true;
    settings.picture = "${../wallpapers/wallpaper.jpg}";
  };

  # ─── Encrypted secrets ────────────────────────────────────────────────────────
  # Each block is only active when the corresponding flag is set in
  # settings/config/secrets.nix AND the .age file exists in secrets/age/.
  # Flip enable = false → true only after running the migration script.

  age.secrets = lib.mkMerge [

    (lib.mkIf cfg.secrets.docker.enable {
      "docker-config" = {
        file  = ../secrets/age/docker-config.json.age;
        path  = "${config.home.homeDirectory}/.docker/config.json";
        mode  = "0600";
      };
    })

    (lib.mkIf cfg.secrets.claude.enable {
      "claude-config" = {
        file  = ../secrets/age/claude.json.age;
        path  = "${config.home.homeDirectory}/.claude.json";
        mode  = "0600";
      };
    })

    (lib.mkIf cfg.secrets.duckdns.enable {
      "duckdns" = {
        file = ../secrets/age/duckdns.tar.gz.age;
      };
    })

  ];

  # Extract DuckDNS tarball on activation.
  # Only runs when duckdns secret is enabled (server/Linux only by default).
  home.activation.setupDuckDNS = lib.mkIf cfg.secrets.duckdns.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "${config.age.secrets.duckdns.path}" ]; then
        $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.duckdns"
        $DRY_RUN_CMD tar -xzf "${config.age.secrets.duckdns.path}" \
          -C "${config.home.homeDirectory}"
      fi
    ''
  );
}
