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
    cleanup      = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
    flake-bump   = "nix run ~/.config/nix-config/tools#flake-bump";
    gen-diff     = "nix run ~/.config/nix-config/tools#gen-diff";
    health-check = "nix run ~/.config/nix-config/tools#health-check";
    # Removed: backup-gde (gnome-export retired — dconf now fully declarative)
    # Removed: secrets-setup (was a stub; health-check covers the age key check)
  };
  
  # macOS-specific aliases
  darwinAliases = {
    # nrs/nrt defined dynamically based on hostname
    cleanup      = "sudo nix-collect-garbage -d";
    flake-bump   = "nix run ~/.config/nix-config/tools#flake-bump";
    gen-diff     = "nix run ~/.config/nix-config/tools#gen-diff";
    health-check = "nix run ~/.config/nix-config/tools#health-check";
    # Removed: backup-dde (darwin-export retired — macOS settings now fully declarative)
    # Removed: secrets-setup (was a stub; health-check covers the age key check)
  };
  
  # History configuration
  history = {
    size = 10000;
    saveSize = 10000;
    file = "~/.zsh_history";
    ignoreDups = true;
  };
}
