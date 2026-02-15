{ pkgs, lib, isDarwin, hostName, extraSpecialArgs ? {}, ... }:
{ config, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
  userConfig = cfg.user;
  # prefer explicit override, otherwise pick sensible default per platform
  homeDir = extraSpecialArgs.homeDirectory or (if isDarwin then "/Users/${userConfig.username}" else "/home/${userConfig.username}");
in
{
  imports = [
    ./programs/git.nix
    (import ./programs/zsh.nix { inherit hostName isDarwin; })
    (import ./programs/ssh.nix { inherit isDarwin; })
    ./programs/starship.nix
    ./programs/fastfetch.nix
    ./programs/vscode.nix
  ] ++ lib.optionals (!isDarwin) [
    ./programs/kde.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = homeDir;
    stateVersion = cfg.system.stateVersion;

    packages = with pkgs;
      # Nerd Fonts (home-manager is the canonical place for fonts)
      (map (font: nerd-fonts.${font}) cfg.packages.fonts)
      ++
      # Linux-only packages (not installed as system packages anywhere)
      (lib.optionals (!isDarwin) (map (pkg: pkgs.${pkg}) cfg.packages.linux));

    file.".ssh/authorized_keys" = {
      text =
        let
          allKeys = import ../modules/ssh-keys.nix;
          filteredKeys = lib.attrValues (lib.filterAttrs (name: _: name != hostName) allKeys);
        in
          builtins.concatStringsSep "\n" filteredKeys;
    };

    file.".ssh/allowed_signers".text = let
      allKeys = import ../modules/ssh-keys.nix;
      # Generate allowed_signers entries for all keys
      entries = lib.mapAttrsToList (name: key: "${cfg.user.email} ${key}") allKeys;
      # Remove duplicates and filter out placeholder keys
      validEntries = lib.filter (entry: !(lib.hasInfix "REPLACE_WITH" entry)) (lib.unique entries);
    in
      builtins.concatStringsSep "\n" validEntries + "\n";

    file.".gitignore_global".text = builtins.concatStringsSep "\n" cfg.git.globalIgnore;
  };

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  gtk = lib.mkIf (!isDarwin) {
    enable = true;
    theme = {
      name = cfg.desktop.theme;
      package = pkgs.catppuccin-gtk.override {
        accents = [ "green" ];
        variant  = "mocha";
      };
    };
    iconTheme = {
      # package is managed by the catppuccin module (catppuccin-papirus-folders)
      name = cfg.desktop.iconTheme;
    };
  };

  qt = lib.mkIf (!isDarwin) {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  # ─── Catppuccin global theming ───────────────────────────────────────────────
  # Enables Catppuccin Mocha Green across all supported programs automatically.
  # Per-program overrides can disable catppuccin where we have a custom theme.
  catppuccin = lib.mkIf (!isDarwin) {
    enable = true;
    flavor = "mocha";
    accent = "green";

    # Starship uses a custom forest_dark green palette — keep it as-is.
    starship.enable = false;
  };

  # ─── Wallpaper ───────────────────────────────────────────────────────────────
  # macOS: desktoppr sets the wallpaper declaratively via an activation script.
  # KDE Plasma: set via programs.plasma.workspace.wallpaper in home/programs/kde.nix.
  # Both reference the same wallpapers/wallpaper.jpg from the repo root.
  programs.desktoppr = lib.mkIf isDarwin {
    enable = true;
    settings = {
      picture = "${../wallpapers/wallpaper.jpg}";
    };
  };
}