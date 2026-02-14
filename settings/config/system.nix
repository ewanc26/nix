{
  # System configuration
  stateVersion = "25.11";
  timeZone = "Europe/London";
  locale = "en_GB.UTF-8";
  
  # Boot configuration
  boot = {
    loader = "systemd-boot";  # "systemd-boot" or "grub"
    enableConsole = true;
  };
  
  # Kernel configuration
  kernel = {
    useLatest = true;  # Use latest kernel instead of LTS
  };
  
  # Network configuration
  network = {
    enableNetworkManager = true;
    hostName = null;  # Set per-host in host config
  };
}
