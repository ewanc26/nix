{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Shell aliases
    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";

      # NixOS specific
      nrs = "sudo nixos-rebuild switch --flake .#laptop";
      nrb = "sudo nixos-rebuild boot --flake .#laptop";
      nrt = "sudo nixos-rebuild test --flake .#laptop";
      hms = "home-manager switch --flake .#ewan";

      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";

      # System
      update = "sudo nixos-rebuild switch --flake .#laptop && home-manager switch --flake .#ewan";
      cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      backup-gde = "bash '/etc/nixos/settings/gnome-export.sh'";
    };

    # Additional configuration (25.11+ correct)
    initContent = ''
      # Custom prompt components
      setopt PROMPT_SUBST

      # History configuration
      HISTSIZE=10000
      SAVEHIST=10000
      HISTFILE=~/.zsh_history
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_FIND_NO_DUPS
      setopt HIST_SAVE_NO_DUPS

      # Key bindings
      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward

      # Enable better tab completion
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    '';
  };
}
