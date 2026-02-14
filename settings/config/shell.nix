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
    secrets-setup = "nix run ~/.config/nix-config/tools#secrets-setup";
  };
  
  # macOS-specific aliases
  darwinAliases = {
    # nrs/nrt defined dynamically based on hostname
    cleanup = "sudo nix-collect-garbage -d";
    backup-dde = "nix run ~/.config/nix-config/tools#darwin-export";
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
