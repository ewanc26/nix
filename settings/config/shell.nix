{
  # Shell configuration
  
  # Common aliases
  aliases = {
    # Modern CLI replacements
    ls = "eza --icons";
    ll = "eza -l --icons --git";
    la = "eza -la --icons --git";
    lt = "eza --tree --level=2 --icons";
    cat = "bat";
    
    # Navigation
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    
    # Safety nets
    rm = "rm -i";
    cp = "cp -i";
    mv = "mv -i";
    
    # Shortcuts
    h = "history";
    c = "clear";
    e = "$EDITOR";
    
    # Disk usage
    du1 = "du -h -d 1";
    df = "df -h";
    
    # Git shortcuts (use lazygit for TUI)
    lg = "lazygit";
  };
  
  # Git aliases
  gitAliases = {
    # Status and info
    gs = "git status";
    gss = "git status -s";  # Short status
    gl = "git log --oneline --graph --decorate";
    
    # Adding and committing
    ga = "git add";
    gaa = "git add -A";  # Add all
    gc = "git commit";
    gcm = "git commit -m";  # Commit with message
    gca = "git commit --amend";
    
    # Pushing and pulling
    gp = "git push";
    gpf = "git push --force-with-lease";  # Safer force push
    gpl = "git pull";
    gpr = "git pull --rebase";  # Pull with rebase
    
    # Branching
    gb = "git branch";
    gco = "git checkout";
    gcb = "git checkout -b";  # Create and checkout branch
    
    # Diffs
    gd = "git diff";
    gds = "git diff --staged";
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
