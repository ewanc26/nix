{ config, pkgs, lib, ... }:

let
  # 1. Detect OS
  isDarwin = pkgs.stdenv.isDarwin;
  
  # 2. Identify Hostname & User
  # Falls back to "default" if not set in the config
  hostName = config.networking.hostName or "default";
  userName = if isDarwin then config.users.users.${builtins.getEnv "USER"}.name else config.services.getty.autologinUser or "user";

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
      # Navigation & General
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";

      # Dynamic Nix Commands
      nrs = "${sudoPrefix}${rebuildCmd} switch --flake .#${hostName}";
      nrb = if isDarwin then "echo 'Boot not supported on Darwin'" else "sudo nixos-rebuild boot --flake .#${hostName}";
      nrt = "${sudoPrefix}${rebuildCmd} test --flake .#${hostName}";
      hms = "home-manager switch --flake .#${userName}";

      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";

      # Unified Update & Cleanup
      update = "nrs && hms";
      cleanup = if isDarwin 
        then "nix-collect-garbage -d" 
        else "sudo nix-collect-garbage -d && nix-collect-garbage -d";
    } 
    # Linux-specific aliases
    // (lib.optionalAttrs (!isDarwin) {
      backup-gde = "bash '/etc/nixos/settings/gnome-export.sh'";
    })
    # macOS-specific aliases
    // (lib.optionalAttrs (isDarwin) {
      backup-dde = "bash '$HOME/.config/nix-config/settings/darwin-export.sh'";
    });

    # Additional configuration (25.11+ correct)
    initContent = ''
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