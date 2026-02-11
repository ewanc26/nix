# Secrets Management with ragenix

This directory contains encrypted secrets managed with [ragenix](https://github.com/yaxitech/ragenix), which uses [age](https://age-encryption.org/) encryption.

## Quick Start

### 1. Generate Your Age Key

First, generate an age key pair for encrypting/decrypting secrets:

```bash
# Generate a new age key
mkdir -p ~/.config/age
nix run github:yaxitech/ragenix -- --generate-age-key > ~/.config/age/keys.txt
chmod 600 ~/.config/age/keys.txt

# View your public key
cat ~/.config/age/keys.txt | grep "# public key:"
```

### 2. Get Your Host's SSH Key as Age Key

Convert your system's SSH host key to an age public key:

```bash
# Option 1: If you have ssh-to-age installed
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age

# Option 2: Using nix-shell
nix-shell -p ssh-to-age --run "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"

# Option 3: From remote host
ssh-keyscan YOUR_HOSTNAME | ssh-to-age
```

### 3. Update secrets.nix

Edit `secrets/secrets.nix` and replace the placeholder keys with your actual keys:

```nix
let
  user1 = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p";  # Your age key
  laptop = "age1...";  # Your host's SSH key as age key
  
  users = [ user1 ];
  systems = [ laptop ];
  all = users ++ systems;
in
{
  "example-password.age".publicKeys = all;
  # Add more secrets here...
}
```

### 4. Create and Edit Secrets

Use the `ragenix` command to create and edit encrypted secrets:

```bash
# Create/edit a secret
nix run github:yaxitech/ragenix -- -e secrets/example-password.age

# Or if you have it in your environment
ragenix -e secrets/example-password.age
```

This will:
1. Decrypt the secret (if it exists) using your private key
2. Open it in your $EDITOR
3. Re-encrypt it when you save and close the editor

### 5. Use Secrets in NixOS Configuration

Create a module to use your secrets:

```nix
# modules/secrets.nix
{ config, ... }:
{
  age.secrets = {
    example-password = {
      file = ../secrets/example-password.age;
      # Optional: specify owner, group, and mode
      owner = "ewan";
      group = "users";
      mode = "0440";
    };
  };
}
```

Then import it in your configuration:

```nix
# configuration.nix
{
  imports = [
    ./modules/secrets.nix
  ];
}
```

Access the secret path in your configuration:

```nix
{
  # The decrypted secret will be available at:
  # /run/agenix/example-password
  
  # Example: Use in a service
  services.myservice = {
    enable = true;
    passwordFile = config.age.secrets.example-password.path;
  };
}
```

## Common Use Cases

### WiFi Password

```nix
# secrets.nix
"wifi-password.age".publicKeys = all;

# modules/secrets.nix
age.secrets.wifi-password.file = ../secrets/wifi-password.age;

# Use in networking configuration
networking.wireless.networks = {
  "MyNetwork" = {
    pskFile = config.age.secrets.wifi-password.path;
  };
};
```

### SSH Private Key

```nix
# secrets.nix
"ssh-private-key.age".publicKeys = all;

# modules/secrets.nix
age.secrets.ssh-private-key = {
  file = ../secrets/ssh-private-key.age;
  owner = "ewan";
  mode = "0600";
};

# Use with SSH
programs.ssh.extraConfig = ''
  Host github.com
    IdentityFile ${config.age.secrets.ssh-private-key.path}
'';
```

### Environment Variables

```nix
# Create a secret file with KEY=value pairs
# secrets/env-vars.age contains:
# API_KEY=secret123
# DB_PASSWORD=hunter2

age.secrets.env-vars.file = ../secrets/env-vars.age;

# Source in a systemd service
systemd.services.myservice = {
  serviceConfig.EnvironmentFile = config.age.secrets.env-vars.path;
};
```

## Tips

1. **Never commit unencrypted secrets** - Only commit `.age` files
2. **Keep your age key safe** - Back up `~/.config/age/keys.txt`
3. **Use different keys for different systems** - Don't share private keys between machines
4. **Rotate secrets regularly** - Use `ragenix -r` to rekey secrets
5. **Add secrets.nix to git** - It only contains public keys

## Rekeying Secrets

If you need to change which keys can decrypt secrets:

```bash
# Edit secrets.nix to update public keys
# Then rekey all secrets
nix run github:yaxitech/ragenix -- -r

# Or rekey a specific secret
nix run github:yaxitech/ragenix -- -r secrets/example-password.age
```

## Troubleshooting

### "No identity found"

Make sure your age key is in one of these locations:
- `~/.config/age/keys.txt`
- `~/.ssh/id_ed25519` (will be automatically converted)
- `~/.ssh/id_rsa` (will be automatically converted)

### "Permission denied"

Check that your age key file has correct permissions:
```bash
chmod 600 ~/.config/age/keys.txt
```

### Secret not decrypting on boot

Ensure your host's SSH key is included in the secret's `publicKeys` list in `secrets.nix`.

## File Structure

```
secrets/
├── secrets.nix           # Defines public keys and secret mappings
├── example-password.age  # Encrypted secret file
├── wifi-password.age     # Another encrypted secret
└── README.md            # This file
```

## Resources

- [ragenix GitHub](https://github.com/yaxitech/ragenix)
- [age encryption](https://age-encryption.org/)
- [NixOS age module](https://github.com/ryantm/agenix)
