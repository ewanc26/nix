{ isDarwin }:
{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
  userName = cfg.user.username;
  
  # Tailscale binary path differs by platform
  # macOS: Homebrew Cask provides CLI in PATH after brew shellenv
  # Linux: Nix package provides the binary
  tailscaleBin = if isDarwin 
    then "tailscale"  # Rely on Homebrew PATH
    else "${pkgs.tailscale}/bin/tailscale";
  
  # Define our internal Tailscale hosts
  # These will connect dynamically through Tailscale using ProxyCommand
  internalHosts = [ "laptop" "server" "macmini" ];
  
  # Create SSH host blocks for Tailscale hosts with dynamic routing
  tailscaleHostBlocks = lib.listToAttrs (map (hostName: {
    name = hostName;
    value = {
      user = userName;
      proxyCommand = "${tailscaleBin} nc %h %p";
      extraOptions = {
        # Connection multiplexing over Tailscale
        ControlMaster = "auto";
        ControlPath = "~/.ssh/sockets/tailscale-%r@%h-%p";
        ControlPersist = "600";
      };
    };
  }) internalHosts);
  
  # Global SSH options
  globalExtraOptions = {
    # Reuse connections for speed
    ControlMaster = "auto";
    ControlPath = "~/.ssh/sockets/%r@%h-%p";
    ControlPersist = "600";
    
    # Automatically add keys to agent
    AddKeysToAgent = "yes";
  };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    # Tailscale host configurations with dynamic ProxyCommand routing
    # macOS-only: preserve exact casing for Apple's SSH Keychain extension
    extraConfig = lib.optionalString isDarwin ''UseKeychain yes'';
    
    matchBlocks = tailscaleHostBlocks // {
      # Global SSH configuration for all other hosts (git forges, etc.)
      "*" = {
        extraOptions = globalExtraOptions;
      };
    };
  };
  
  # Linux: Enable SSH agent service via systemd user service
  # On macOS, the system handles this automatically
  services.ssh-agent = lib.mkIf (!isDarwin) {
    enable = true;
  };
  
  # Ensure the socket directory exists
  home.file.".ssh/sockets/.keep".text = "";
}
