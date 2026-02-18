# Git configuration.
{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  cfg = osConfig.myConfig;
in
{
  programs.git = {
    enable = true;
    lfs.enable = cfg.git.lfs.enable;

    settings = {
      user = {
        name = cfg.user.fullName;
        email = cfg.user.email;
      };

      safe.directory = lib.mkIf (!pkgs.stdenv.isDarwin) "/etc/nixos";

      core = {
        editor = cfg.git.editor;
        excludesfile = "~/.gitignore_global";
      };

      init.defaultBranch = cfg.git.defaultBranch;

      gpg.format = cfg.git.signing.format;
      user.signingkey = "${cfg.ssh.keyFile}.pub";
      commit.gpgsign = cfg.git.signing.enabled;
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";

      alias = {
        la = "log --all --graph --pretty=format:'%C(auto)%h%d %s %C(bold black)(%ar by <%aN>)%Creset'";
        law = "log --all --graph --pretty=format:'%C(auto)%h%d %w(100,0,8)%s %C(bold black)(%ar by <%aN>)%Creset'";
        lad = "log --all --graph --pretty=format:'%Cgreen%ad%Creset %C(auto)%h%d %s %C(bold black)<%aN>%Creset' --date=format-local:'%Y-%m-%d %H:%M (%a)'";
      };
    };
  };
}
