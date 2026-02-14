{ pkgs, lib, isDarwin, hostName, extraSpecialArgs ? {}, ... }:
{ config, ... }:

let
  # prefer explicit override, otherwise pick sensible default per platform
  homeDir = extraSpecialArgs.homeDirectory or (if isDarwin then "/Users/ewan" else "/home/ewan");
in
{
  imports = [
    ./programs/git.nix
    (import ./programs/zsh.nix { inherit hostName isDarwin; })
    ./programs/starship.nix
    ./programs/fastfetch.nix
    ./programs/vscode.nix
  ] ++ lib.optionals (!isDarwin) [
    ./programs/gnome.nix
  ];

  home = {
    username = "ewan";
    homeDirectory = homeDir;
    stateVersion = "25.11";

    packages = with pkgs; [
      # Fonts
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.roboto-mono
      nerd-fonts.sauce-code-pro
      nerd-fonts.ubuntu-mono

      # Common cross-platform user tools
      fastfetch
      htop
      tree
      ripgrep
      fd
      unzip
      zip
    ] ++ lib.optionals (!isDarwin) [
      vlc
      dconf2nix
    ];

    file.".ssh/authorized_keys" = {
      text =
        let
          allKeys = import ../modules/ssh-keys.nix;
          filteredKeys = lib.attrValues (lib.filterAttrs (name: _: name != hostName) allKeys);
        in
          builtins.concatStringsSep "\n" filteredKeys;
      onChange = "chmod 600 ${homeDir}/.ssh/authorized_keys";
    };

    file.".gitignore_global".text = ''
      # OS generated files
      .DS_Store
      .DS_Store?
      ._*
      .Spotlight-V100
      .Trashes
      ehthumbs.db
      Thumbs.db

      # Editor files
      .vscode/
      .idea/
      *.swp
      *.swo
      *~

      # Temporary files
      *.tmp
      *.bak
      *.log
    '';
  };

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  gtk = lib.mkIf (!isDarwin) {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  qt = lib.mkIf (!isDarwin) {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };
}