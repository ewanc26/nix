{
  # Desktop environment configuration (Linux)

  enable = true;

  # Desktop environment
  environment = "plasma6";  # "gnome", "plasma6", "xfce", etc.

  # Display manager
  displayManager = "sddm";  # "gdm", "sddm", "lightdm", etc.

  # GTK/Qt theming
  theme     = "Catppuccin-Mocha-Standard-Green-Dark";
  iconTheme = "Papirus-Dark";

  # Monospace font (used in Konsole, terminal emulators, IDE configs, etc.)
  monoFont        = "FiraCode Nerd Font Mono 11";
  monoFontConsole = "FiraCode Nerd Font Mono 11";  # Konsole uses the same font name as the system

  # KDE Plasma-specific settings
  plasma = {
    # Packages to exclude from the default KDE Plasma install.
    # Must match attribute names under pkgs.kdePackages.
    excludePackages = [
      "oxygen"         # Legacy Oxygen theme – use Breeze/Catppuccin instead
      "elisa"          # KDE music player – use Spotify instead
    ];
  };
}
