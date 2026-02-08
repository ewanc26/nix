{ config, pkgs, ... }:

{
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
    ./programs/starship.nix
    ./programs/fastfetch.nix
    ./programs/vscode.nix
    ./programs/gnome.nix
  ];

  # Home Manager settings
  home = {
    username = "ewan";
    homeDirectory = "/home/ewan";
    stateVersion = "25.11";

    # Additional user packages
    packages = with pkgs; [
      vlc
      
      # Nerd Fonts
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "Meslo" "SourceCodePro" "UbuntuMono" ]; })
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

  # GTK theme configuration
  gtk = {
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

  # Qt theme configuration
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };
}
