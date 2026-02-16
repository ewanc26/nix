{ isDarwin }:
{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    # Global SSH configuration for all hosts
    matchBlocks."*" = {
      extraOptions = {
        # Reuse connections for speed
        ControlMaster = "auto";
        ControlPath = "~/.ssh/sockets/%r@%h-%p";
        ControlPersist = "600";
        
        # Automatically add keys to agent
        AddKeysToAgent = "yes";
      } // lib.optionalAttrs isDarwin {
        # macOS: Use Keychain for SSH keys
        UseKeychain = "yes";
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
