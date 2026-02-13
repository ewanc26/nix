{ config, pkgs, lib, hostName ? "default", ... }:

let
  # 1. Detect OS
  isDarwin = pkgs.stdenv.isDarwin;
  
  # 2. User config
  userName = "ewan";  # Same username on all systems

  # 3. Dynamic Command Selection
  rebuildCmd = if isDarwin then "darwin-rebuild" else "nixos-rebuild";
  sudoPrefix = if isDarwin then "" else "sudo ";
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # Common aliases (work on all platforms)
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";

      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
    } 
    # Linux-specific aliases
    // (lib.optionalAttrs (!isDarwin) {
      # Nix rebuild commands
      nrs = "sudo nixos-rebuild switch --flake .#${hostName}";
      nrb = "sudo nixos-rebuild boot --flake .#${hostName}";
      nrt = "sudo nixos-rebuild test --flake .#${hostName}";
      hms = "home-manager switch --flake .#${userName}";
      
      # Combined operations
      update = "sudo nixos-rebuild switch --flake .#${hostName} && home-manager switch --flake .#${userName}";
      cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      
      # GNOME settings export
      backup-gde = "bash '/etc/nixos/settings/gnome-export.sh'";
    })
    # macOS-specific aliases
    // (lib.optionalAttrs isDarwin {
      # Nix rebuild commands
      nrs = "sudo darwin-rebuild switch --flake .#${hostName}";
      nrt = "sudo darwin-rebuild test --flake .#${hostName}";
      hms = "home-manager switch --flake .#${userName}";
      
      # Combined operations
      update = "sudo darwin-rebuild switch --flake .#${hostName} && home-manager switch --flake .#${userName}";
      cleanup = "sudo nix-collect-garbage -d";
      
      # Darwin settings export
      backup-dde = "bash '$HOME/.config/nix-config/settings/darwin-export.sh'";
    });

    # Additional configuration (25.11+ correct)
    initContent = ''
      # Display system info on shell start
      fastfetch

      # Initialize Starship prompt
      eval "$(starship init zsh)"

      setopt PROMPT_SUBST

      # History
      HISTSIZE=10000
      SAVEHIST=10000
      HISTFILE=~/.zsh_history
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_FIND_NO_DUPS
      setopt HIST_SAVE_NO_DUPS

      # Key bindings
      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward

      # Completion styling
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    '';
  };
}