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
    backup-gde = "bash '/etc/nixos/settings/gnome-export.sh'";
  };
  
  # macOS-specific aliases
  darwinAliases = {
    # nrs/nrt defined dynamically based on hostname
    cleanup = "sudo nix-collect-garbage -d";
    backup-dde = "bash '$HOME/.config/nix-config/settings/darwin-export.sh'";
  };
  
  # History configuration
  history = {
    size = 10000;
    saveSize = 10000;
    file = "~/.zsh_history";
    ignoreDups = true;
  };
}
