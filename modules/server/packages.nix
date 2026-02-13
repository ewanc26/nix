{ config, pkgs, ... }:

{
  # Essential server packages
  environment.systemPackages = with pkgs; [
    # System monitoring and management
    btop
    iotop
    iftop

    # Network tools
    wget
    curl
    bind        # dig, nslookup
    inetutils   # telnet, etc
    traceroute
    mtr
    nmap

    # File management
    rsync
    p7zip

    # Text editors
    vim
    nano

    # System tools
    lsof
    pciutils
    usbutils
    file
    which

    # Process management
    tmux
    screen

    # Security tools
    gnupg
    openssl

    # Disk utilities
    parted
    gptfdisk
    smartmontools

    # Archive tools
    gnutar
    gzip
    bzip2
    xz
  ];

  # Enable command-not-found
  programs.command-not-found.enable = true;

  # Bash completion
  programs.bash.completion.enable = true;
}
