{ config, pkgs, lib, ... }:

let
  sshSignKey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
  haveKey = builtins.pathExists sshSignKey;
in
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user = {
        name = "Ewan Croft";
        email = "git@ewancroft.uk";
      };

      safe.directory = "/etc/nixos";

      core = {
        editor = "code --wait";
        excludesfile = "~/.gitignore_global";
      };

      init.defaultBranch = "main";

      alias = {
        la = "log --all --graph --pretty=format:'%C(auto)%h%d %s %C(bold black)(%ar by <%aN>)%Creset'";
        law = "log --all --graph --pretty=format:'%C(auto)%h%d %w(100,0,8)%s %C(bold black)(%ar by <%aN>)%Creset'";
        lad = "log --all --graph --pretty=format:'%Cgreen%ad%Creset %C(auto)%h%d %s %C(bold black)<%aN>%Creset' --date=format-local:'%Y-%m-%d %H:%M (%a)'";
      };
    };

    # only add signing config if key exists
    extraConfig = lib.mkIf haveKey {
      user.signingkey = sshSignKey;
      commit.gpgsign = true;
      tag.gpgsign = true;
      gpg.format = "ssh";
    };
  };
}