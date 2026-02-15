{
  # ============================================================================
  # CENTRAL CONFIGURATION - SINGLE SOURCE OF TRUTH
  # ============================================================================
  # All configurable values for the entire system are organized here.
  # Each category has its own file in settings/config/ for better organization.
  #
  # To customize your setup, edit the individual files:
  # - user.nix        : User account settings
  # - system.nix      : System-level configuration
  # - nix.nix         : Nix package manager settings
  # - packages.nix    : Package lists for different use cases
  # - git.nix         : Git configuration and aliases
  # - shell.nix       : Shell aliases and history settings
  # - desktop.nix     : Desktop environment settings (Linux)
  # - ssh.nix         : SSH configuration
  # - audio.nix       : Audio backend configuration
  # - gaming.nix      : Gaming-related settings
  # - server.nix      : Server-specific configuration
  # - darwin.nix      : macOS-specific settings
  # - secrets.nix     : Secrets management configuration
  # - development.nix : Development tools and languages
  # - maintenance.nix : Backup and auto-update settings
  # - paths.nix       : Important path locations
  # - pds.nix         : Bluesky Personal Data Server settings
  
  user = import ./user.nix;
  system = import ./system.nix;
  nix = import ./nix.nix;
  packages = import ./packages.nix;
  git = import ./git.nix;
  shell = import ./shell.nix;
  desktop = import ./desktop.nix;
  ssh = import ./ssh.nix;
  audio = import ./audio.nix;
  gaming = import ./gaming.nix;
  server = import ./server.nix;
  darwin = import ./darwin.nix;
  secrets = import ./secrets.nix;
  development = import ./development.nix;
  maintenance = import ./maintenance.nix;
  paths = import ./paths.nix;
  pds = import ./pds.nix;
}
