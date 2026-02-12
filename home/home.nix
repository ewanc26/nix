{ config, pkgs, lib, isDarwin, ... }:

{
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
    ./programs/starship.nix
    ./programs/fastfetch.nix
    ./programs/vscode.nix
  ] ++ lib.optionals (!isDarwin) [
    # Linux-only imports
    ./programs/gnome.nix
  ];

  # Home Manager settings
  home = {
    username = "ewan";
    homeDirectory = if isDarwin then "/Users/ewan" else "/home/ewan";
    stateVersion = "25.11";

    # Additional user packages
    packages = with pkgs; [
      # Nerd Fonts (available on all platforms)
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.roboto-mono
      nerd-fonts.sauce-code-pro
      nerd-fonts.ubuntu-mono
    ] ++ lib.optionals (!isDarwin) [
      # Linux-only packages
      vlc
      dconf2nix # For exporting GNOME settings to Nix
    ]; 

    # Global gitignore file
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

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Font configuration
  fonts.fontconfig.enable = true;

  # Linux-specific theming (GTK/Qt)
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
