{ config, pkgs, ... }:

{
  # System-wide programs with built-in options
  programs = {
    # Firefox with proper NixOS options
    firefox.enable = true;
    
    # Git configuration
    git.enable = true;
  };

  # Packages that don't have dedicated options
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    wget
    curl
    htop
    unzip
    zip
    tree
    ripgrep
    fd
    
    # System information
    fastfetch
    
    # Development tools
    vscode
    
    # Communication
    discord
    signal-desktop

    # Media
    spotify
    
    # Gaming
    prismlauncher
    
    # GNOME utilities
    gnome-extension-manager
  ];

  # VSCode configuration (separate from systemPackages for clarity)
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };
}
