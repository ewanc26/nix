{ hostName, isDarwin }:
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = import ../../settings/config.nix;
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
      fastfetch
      eval "$(starship init zsh)"

      setopt PROMPT_SUBST

      HISTSIZE=${toString cfg.shell.history.size}
      SAVEHIST=${toString cfg.shell.history.saveSize}
      HISTFILE=${cfg.shell.history.file}
      ${lib.optionalString cfg.shell.history.ignoreDups "setopt HIST_IGNORE_ALL_DUPS"}
      ${lib.optionalString cfg.shell.history.ignoreDups "setopt HIST_FIND_NO_DUPS"}
      ${lib.optionalString cfg.shell.history.ignoreDups "setopt HIST_SAVE_NO_DUPS"}

      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    '';
  };
}
