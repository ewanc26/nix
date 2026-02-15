{ config, pkgs, lib, osConfig, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  programs.git = {
    enable = true;
    lfs.enable = cfg.git.lfs.enable;

    settings = {
      user = {
        name  = cfg.user.fullName;
        email = cfg.user.email;
      };

      safe.directory = "/etc/nixos";

      core = {
        editor = cfg.git.editor;
        excludesfile = "~/.gitignore_global";
      };

      init.defaultBranch = cfg.git.defaultBranch;

      # SSH commit signing
      gpg.format = cfg.git.signing.format;
      user.signingkey = "${cfg.ssh.keyFile}.pub";
      commit.gpgsign = cfg.git.signing.enabled;
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";

      alias = cfg.git.aliases;
    };
  };
}