{ config, pkgs, lib, osConfig, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user = {
        name  = "Ewan Croft";
        email = "git@ewancroft.uk";
      };

      safe.directory = "/etc/nixos";

      core = {
        editor = "code --wait";
        excludesfile = "~/.gitignore_global";
      };

      init.defaultBranch = "main";

      # SSH commit signing
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
      commit.gpgsign = true;

      alias = {
        la  = "log --all --graph --pretty=format:'%C(auto)%h%d %s %C(bold black)(%ar by <%aN>)%Creset'";
        law = "log --all --graph --pretty=format:'%C(auto)%h%d %w(100,0,8)%s %C(bold black)(%ar by <%aN>)%Creset'";
        lad = "log --all --graph --pretty=format:'%Cgreen%ad%Creset %C(auto)%h%d %s %C(bold black)<%aN>%Creset' --date=format-local:'%Y-%m-%d %H:%M (%a)'";
      };
    };
  };
}