{
  # SSH configuration
  
  keyFile = "~/.ssh/id_ed25519";
  enable = true;
  
  # SSH agent configuration
  agent = {
    enable = true;  # Enable SSH agent on Linux
    persistFile = "$HOME/.ssh/agent-env";
  };
}
