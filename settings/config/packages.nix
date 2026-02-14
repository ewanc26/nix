{
  # Package configuration

  allowUnfree = true;

  # Common packages for all systems (Linux and macOS)
  common = [
    "fastfetch"
    "htop"
    "tree"
    "ripgrep"
    "fd"
    "unzip"
    "zip"
    "vim"
    "wget"
    "curl"
  ];

  # Nerd Fonts to install
  fonts = [
    "fira-code"
    "jetbrains-mono"
    "meslo-lg"
    "roboto-mono"
    "sauce-code-pro"
    "ubuntu-mono"
  ];

  # Linux-only packages
  linux = [
    "vlc"
    "dconf2nix"
  ];

  # Desktop/GUI packages (NixOS laptop)
  desktop = [
    "discord"
    "signal-desktop"
    "spotify"
    "gimp"
    "inkscape"
    "libreoffice-fresh"
    "prismlauncher"
    "gnome-extension-manager"
  ];

  # Gaming packages
  gaming = [
    "steam"
    "lutris"
    "wine"
    "winetricks"
  ];

  # Server packages
  server = [
    "git"
    "tmux"
    "rsync"
  ];
}
