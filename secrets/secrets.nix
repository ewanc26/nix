# secrets.nix - Define your age keys and secrets here
# This file tells ragenix which public keys can decrypt which secrets

let
  # User keys - Add your age public key(s) here
  # Generate with: nix run github:yaxitech/ragenix -- --generate-age-key
  user1 = "age1... your-age-public-key-here";
  
  # System keys - Your host's SSH public key
  # Get with: ssh-keyscan localhost | ssh-to-age
  # Or from: /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
  laptop = "age1... your-host-ssh-age-key-here";
  
  # Define groups of keys that can access secrets
  users = [ user1 ];
  systems = [ laptop ];
  all = users ++ systems;
in
{
  # Example secrets - Add your own here
  # Each secret file will be encrypted with the listed public keys
  
  "example-password.age".publicKeys = all;
  "wifi-password.age".publicKeys = all;
  "github-token.age".publicKeys = all;
  "ssh-private-key.age".publicKeys = all;
  
  # You can also restrict secrets to specific users or systems
  # "admin-only.age".publicKeys = [ user1 ];
  # "laptop-only.age".publicKeys = [ laptop ];
}
