{ config, pkgs, ... }:

{
  # System-wide programs with built-in options
  programs = {
    firefox.enable = true;
    git.enable = true;
  };

  # Packages that don't have dedicated options
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    wget
    curl

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
}
