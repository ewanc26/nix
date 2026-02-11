{ config, ... }:

{
  # Import ragenix secrets
  # Uncomment secrets as you create them
  
  age.secrets = {
    # Example: Uncomment and modify as needed
    # example-password = {
    #   file = ../secrets/example-password.age;
    #   owner = "ewan";
    #   group = "users";
    #   mode = "0440";
    # };
    
    # WiFi password example
    # wifi-password = {
    #   file = ../secrets/wifi-password.age;
    #   mode = "0440";
    # };
    
    # SSH private key example
    # ssh-private-key = {
    #   file = ../secrets/ssh-private-key.age;
    #   owner = "ewan";
    #   mode = "0600";
    # };
    
    # GitHub token example
    # github-token = {
    #   file = ../secrets/github-token.age;
    #   owner = "ewan";
    #   mode = "0400";
    # };
  };
  
  # Example usage in configuration:
  # Access decrypted secrets at: /run/agenix/SECRET_NAME
  # Example: config.age.secrets.example-password.path
}
