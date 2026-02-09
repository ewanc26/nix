{ config, pkgs, ... }:

{
  # System-wide packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    vim
    wget
    curl
    htop

    # System information
    fastfetch
    
    # Browsers
    firefox
    
    # Development tools
    vscode
    
    # Communication
    discord
    signal-desktop

    # Media
    spotify
    
    # Gaming
    prismlauncher
    
    # Additional utilities
    unzip
    zip
    tree
    ripgrep
    fd
  ];

  # VSCode with extensions
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };
}
