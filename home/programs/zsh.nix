{ hostName, isDarwin }:
{ config, pkgs, lib, ... }:

let

  # Username (can also be made dynamic later if you want)
  userName = config.home.username;

in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases =
      {
        # Common aliases
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

      # Linux-specific
      // (lib.optionalAttrs (!isDarwin) {
        nrs = "sudo nixos-rebuild switch --flake .#${hostName}";
        nrb = "sudo nixos-rebuild boot --flake .#${hostName}";
        nrt = "sudo nixos-rebuild test --flake .#${hostName}";
        hms = "home-manager switch --flake .#${userName}";

        update = "sudo nixos-rebuild switch --flake .#${hostName} && home-manager switch --flake .#${userName}";
        cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";

        backup-gde = "bash '/etc/nixos/settings/gnome-export.sh'";
      })

      # macOS-specific
      // (lib.optionalAttrs isDarwin {
        nrs = "sudo darwin-rebuild switch --flake .#${hostName}";
        nrt = "sudo darwin-rebuild test --flake .#${hostName}";
        hms = "home-manager switch --flake .#${userName}";

        update = "sudo darwin-rebuild switch --flake .#${hostName} && home-manager switch --flake .#${userName}";
        cleanup = "sudo nix-collect-garbage -d";

        backup-dde = "bash '$HOME/.config/nix-config/settings/darwin-export.sh'";
      });

    initContent = ''
      fastfetch
      eval "$(starship init zsh)"

      ${lib.optionalString (!isDarwin) ''
      # SSH agent persistence (Linux only)
      SSH_ENV="$HOME/.ssh/agent-env"

      function start_agent {
        echo "Starting new SSH agent..."
        ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
        chmod 600 "${SSH_ENV}"
        . "${SSH_ENV}" > /dev/null
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
      }

      # Check if agent is running
      if [ -f "${SSH_ENV}" ]; then
        . "${SSH_ENV}" > /dev/null
        ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
          start_agent;
        }
      else
        start_agent;
      fi
      ''}

      setopt PROMPT_SUBST

      HISTSIZE=10000
      SAVEHIST=10000
      HISTFILE=~/.zsh_history
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_FIND_NO_DUPS
      setopt HIST_SAVE_NO_DUPS

      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    '';
  };
}