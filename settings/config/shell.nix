{
  # Shell configuration
  
  # Common aliases
  aliases = {
    ll = "ls -lah";
    la = "ls -A";
    l = "ls -CF";
    ".." = "cd ..";
    "..." = "cd ../..";
  };
  
  # Git aliases
  gitAliases = {
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
  };
  
  # Linux-specific aliases
  linuxAliases = {
    # nrs/nrb/nrt defined dynamically based on hostname
    cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
    backup-gde = "nix run ~/.config/nix-config/tools#gnome-export";
    backup-gde-bash = "bash '/etc/nixos/settings/gnome-export.sh'";  # Legacy bash version
    secrets-setup = "nix run ~/.config/nix-config/tools#secrets-setup";
  };
  
  # macOS-specific aliases
  darwinAliases = {
    # nrs/nrt defined dynamically based on hostname
    cleanup = "sudo nix-collect-garbage -d";
    backup-dde = "nix run ~/.config/nix-config/tools#darwin-export";
    backup-dde-bash = "bash '$HOME/.config/nix-config/settings/darwin-export.sh'";  # Legacy bash version
    secrets-setup = "nix run ~/.config/nix-config/tools#secrets-setup";
  };
  
  # History configuration
  history = {
    size = 10000;
    saveSize = 10000;
    file = "~/.zsh_history";
    ignoreDups = true;
  };
}
