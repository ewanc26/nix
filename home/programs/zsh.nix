# Zsh configuration.
# Platform detection via pkgs.stdenv.isDarwin — no args passed from outside.
{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  cfg = osConfig.myConfig;
  isDarwin = pkgs.stdenv.isDarwin;
  hostName = config.home.username; # use as fallback; actual hostname from networking
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = lib.filterAttrs (n: v: v != null) (
      # ── Modern CLI replacements ──────────────────────────────────────────────
      {
        ls = "eza --icons";
        ll = "eza -l --icons --git";
        la = "eza -la --icons --git";
        lt = "eza --tree --level=2 --icons";
        cat = "bat";

        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";

        rm = "rm -i";
        cp = "cp -i";
        mv = "mv -i";

        h = "history";
        c = "clear";
        e = "$EDITOR";

        du1 = "du -h -d 1";
        df = "df -h";

        lg = "lazygit";

        # ── Git shortcuts ──────────────────────────────────────────────────────
        gs = "git status";
        gss = "git status -s";
        gl = "git log --oneline --graph --decorate";
        ga = "git add";
        gaa = "git add -A";
        gc = "git commit";
        gcm = "git commit -m";
        gca = "git commit --amend";
        gp = "git push";
        gpf = "git push --force-with-lease";
        gpl = "git pull";
        gpr = "git pull --rebase";
        gb = "git branch";
        gco = "git checkout";
        gcb = "git checkout -b";
        gd = "git diff";
        gds = "git diff --staged";

        # ── Nix tool aliases ──────────────────────────────────────────────────
        flake-bump = "nix run ~/.config/nix-config/tools#flake-bump";
        gen-diff = "nix run ~/.config/nix-config/tools#gen-diff";
        health-check = "nix run ~/.config/nix-config/tools#health-check";
        update-all = "~/.config/nix-config/home/scripts/update-all";
        update-everything = "~/.config/nix-config/home/scripts/update-everything";

        # ── Platform-specific rebuild aliases ─────────────────────────────────
        nrs =
          if isDarwin then
            "sudo darwin-rebuild switch --flake ~/.config/nix-config#macmini"
          else
            "sudo nixos-rebuild switch --flake ~/.config/nix-config";
        nrb = if isDarwin then null else "sudo nixos-rebuild boot --flake ~/.config/nix-config";
        nrt =
          if isDarwin then
            "sudo darwin-rebuild test --flake ~/.config/nix-config#macmini"
          else
            "sudo nixos-rebuild test --flake ~/.config/nix-config";
        hms = "home-manager switch --flake ~/.config/nix-config";

        # ── Platform-specific extras ──────────────────────────────────────────
        cleanup =
          if isDarwin then
            "sudo nix-collect-garbage -d"
          else
            "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      }
    );

    initContent = ''
      # Display system info on new shell
      fastfetch

      # Initialize SSH agent (Linux only)
      ${lib.optionalString (!isDarwin) ''
        if [ -z "$SSH_AUTH_SOCK" ]; then
          export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
        fi
      ''}

      # Initialize Starship prompt
      eval "$(starship init zsh)"

      # Initialize fzf
      eval "$(fzf --zsh)"

      setopt PROMPT_SUBST

      HISTSIZE=10000
      SAVEHIST=10000
      HISTFILE=~/.zsh_history
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_FIND_NO_DUPS
      setopt HIST_SAVE_NO_DUPS
      setopt SHARE_HISTORY
      setopt HIST_EXPIRE_DUPS_FIRST
      setopt HIST_REDUCE_BLANKS

      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
      bindkey '^[[3~' delete-char

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' group-name '''

      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_MINUS
    '';

    profileExtra =
      ''
        [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
        export PATH="$PATH:$HOME/.local/bin"
      ''
      + lib.optionalString isDarwin ''
        [ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"
        [ -x "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
        [ -f "$HOME/.orbstack/shell/init.zsh" ] && source "$HOME/.orbstack/shell/init.zsh"
      '';
  };
}
