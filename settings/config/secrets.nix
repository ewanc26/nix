{
  # Secrets configuration
  enable = true;
  masterKeyPath = "~/.config/age/keys.txt";
  
  # List of secrets (filenames without .age extension)
  files = [
    "ssh-passphrase"
    "wifi-home"
  ];
}
