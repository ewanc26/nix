{ pkgs, lib, isDarwin, extraSpecialArgs ? {}, ... }:
{ config, ... }:

let
  # prefer explicit override, otherwise pick sensible default per platform
  homeDir = extraSpecialArgs.homeDirectory or (if isDarwin then "/Users/ewan" else "/home/ewan");
in
{
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
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
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.roboto-mono
      nerd-fonts.sauce-code-pro
      nerd-fonts.ubuntu-mono
    ] ++ lib.optionals (!isDarwin) [
      vlc
      dconf2nix
    ];

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