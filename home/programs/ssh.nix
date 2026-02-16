{ isDarwin, isDesktop ? true }:
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
    matchBlocks = tailscaleHostBlocks // {
      # Global SSH configuration for all other hosts (git forges, etc.)
      "*" = {
        extraOptions = globalExtraOptions;
      };
    };
  };
  
  # Linux desktop: enable SSH agent and load keys into it at login.
  # On macOS the system keychain handles this automatically.
  # The server doesn't need this — we SSH into it, not out from it.
  services.ssh-agent = lib.mkIf (!isDarwin && isDesktop) {
    enable = true;
  };

  # ksshaskpass pops a KWallet GUI prompt on first login after a reboot;
  # subsequent logins retrieve the passphrase from KWallet silently.
  # SSH_AUTH_SOCK must be set explicitly — systemd user services don't
  # inherit the shell environment, so reference the socket path directly.
  systemd.user.services.ssh-load-keys = lib.mkIf (!isDarwin && isDesktop) {
    Unit = {
      Description = "Load SSH keys into agent via KWallet";
      After  = [ "ssh-agent.service" "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type      = "oneshot";
      ExecStart = "${pkgs.openssh}/bin/ssh-add";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent"
        "SSH_ASKPASS=${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass"
        "SSH_ASKPASS_REQUIRE=prefer"
      ];
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # macOS: Load SSH keys from Keychain into the agent at login.
  # Replaces the old `UseKeychain yes` ssh_config option (removed in Tahoe).
  # Equivalent to running `ssh-add --apple-load-keychain` manually after each reboot.
  launchd.agents.ssh-load-keychain = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "/usr/bin/ssh-add" "--apple-load-keychain" ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/ssh-add-keychain.log";
      StandardErrorPath = "/tmp/ssh-add-keychain.log";
    };
  };
  
  # Ensure the socket directory exists
  home.file.".ssh/sockets/.keep".text = "";
}
