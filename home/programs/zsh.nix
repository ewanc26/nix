{ hostName, isDarwin }:
{
  config,
  pkgs,
  lib,
  cfgLib,
  ...
}:

let
  cfg = cfgLib.cfg;
  userName = config.home.username;

in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = lib.filterAttrs (n: v: v != null) (
      # Common aliases
      cfg.shell.aliases

      # Git shortcuts
      // cfg.shell.gitAliases

      # Dynamic rebuild aliases (hostname-based)
      // {
        nrs =
          if isDarwin then
            "sudo darwin-rebuild switch --flake .#${hostName}"
          else
            "sudo nixos-rebuild switch --flake .#${hostName}";
        nrb =
          if isDarwin then
            null # Not applicable on Darwin
          else
            "sudo nixos-rebuild boot --flake .#${hostName}";
        nrt =
          if isDarwin then
            "sudo darwin-rebuild test --flake .#${hostName}"
          else
            "sudo nixos-rebuild test --flake .#${hostName}";
        hms = "home-manager switch --flake .#${userName}";
        update =
          if isDarwin then
            "sudo darwin-rebuild switch --flake .#${hostName} && home-manager switch --flake .#${userName}"
          else
            "sudo nixos-rebuild switch --flake .#${hostName} && home-manager switch --flake .#${userName}";
      }

      # Linux-specific
      // (lib.optionalAttrs (!isDarwin) cfg.shell.linuxAliases)

      # macOS-specific
      // (lib.optionalAttrs isDarwin cfg.shell.darwinAliases)
    );

    initContent = ''
      # Display system info on new shell
      fastfetch
      
      # Initialize Starship prompt
      eval "$(starship init zsh)"

      # Prompt settings
      setopt PROMPT_SUBST

      # History settings
      HISTSIZE=${toString cfg.shell.history.size}
      SAVEHIST=${toString cfg.shell.history.saveSize}
      HISTFILE=${cfg.shell.history.file}
      ${lib.optionalString cfg.shell.history.ignoreDups "setopt HIST_IGNORE_ALL_DUPS"}
      ${lib.optionalString cfg.shell.history.ignoreDups "setopt HIST_FIND_NO_DUPS"}
      ${lib.optionalString cfg.shell.history.ignoreDups "setopt HIST_SAVE_NO_DUPS"}
      setopt SHARE_HISTORY           # Share history between sessions
      setopt HIST_EXPIRE_DUPS_FIRST  # Expire duplicates first
      setopt HIST_REDUCE_BLANKS      # Remove superfluous blanks

      # Key bindings
      bindkey '^[[A' history-beginning-search-backward  # Up arrow
      bindkey '^[[B' history-beginning-search-forward   # Down arrow
      bindkey '^[[H' beginning-of-line                  # Home key
      bindkey '^[[F' end-of-line                        # End key
      bindkey '^[[3~' delete-char                       # Delete key

      # Completion settings
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # Case insensitive
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"  # Colored completion
      zstyle ':completion:*' group-name '''                       # Group completions
      
      # Better directory navigation
      setopt AUTO_CD              # cd by typing directory name
      setopt AUTO_PUSHD           # Push directories onto stack
      setopt PUSHD_IGNORE_DUPS    # Don't push duplicates
      setopt PUSHD_MINUS          # Swap meaning of +/-
    '';
  };
}
