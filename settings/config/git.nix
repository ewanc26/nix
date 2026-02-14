{
  # Git configuration
  
  enable = true;
  defaultBranch = "main";
  editor = "code --wait";
  
  # Git LFS
  lfs = {
    enable = true;
  };
  
  # Commit signing
  signing = {
    enabled = true;
    format = "ssh";  # "ssh" or "gpg"
  };
  
  # Git aliases
  aliases = {
    la = "log --all --graph --pretty=format:'%C(auto)%h%d %s %C(bold black)(%ar by <%aN>)%Creset'";
    law = "log --all --graph --pretty=format:'%C(auto)%h%d %w(100,0,8)%s %C(bold black)(%ar by <%aN>)%Creset'";
    lad = "log --all --graph --pretty=format:'%Cgreen%ad%Creset %C(auto)%h%d %s %C(bold black)<%aN>%Creset' --date=format-local:'%Y-%m-%d %H:%M (%a)'";
  };
  
  # Global gitignore patterns
  globalIgnore = [
    # OS generated
    ".DS_Store"
    ".DS_Store?"
    "._*"
    ".Spotlight-V100"
    ".Trashes"
    "ehthumbs.db"
    "Thumbs.db"
    
    # Editors
    ".vscode/"
    ".idea/"
    "*.swp"
    "*.swo"
    "*~"
    
    # Temporary
    "*.tmp"
    "*.bak"
    "*.log"
  ];
}
