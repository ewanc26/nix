{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Ewan Croft";
    userEmail = "git@ewancroft.uk";
    
    extraConfig = {
      init.defaultBranch = "main";
      core = {
        editor = "code --wait";
        excludesfile = "~/.gitignore_global";
      };
      
      # GPG signing with SSH
      commit.gpgsign = true;
      tag.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
      
      # LFS support
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
      
      # Useful aliases
      alias = {
        la = "log --all --graph --pretty=format:'%C(auto)%h%d %s %C(bold black)(%ar by <%aN>)%Creset'";
        law = "log --all --graph --pretty=format:'%C(auto)%h%d %w(100,0,8)%s %C(bold black)(%ar by <%aN>)%Creset'";
        lad = "log --all --graph --pretty=format:'%Cgreen%ad%Creset %C(auto)%h%d %s %C(bold black)<%aN>%Creset' --date=format-local:'%Y-%m-%d %H:%M (%a)'";
      };
    };
    
    # Git LFS
    lfs.enable = true;
  };
}
