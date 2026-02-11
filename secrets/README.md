# Secrets Management with ragenix

This directory contains encrypted secrets managed with [ragenix](https://github.com/yaxitech/ragenix), which uses [age](https://age-encryption.org/) encryption.

---

## Quick Start

### 1. Generate Your Age Key

Ragenix does **not** generate keys itself. Use `age-keygen`.

```bash
# Generate a new age key
mkdir -p ~/.config/age

# If age-keygen is installed
age-keygen -o ~/.config/age/keys.txt

# Or via nix (no install required)
nix shell nixpkgs#age -c age-keygen -o ~/.config/age/keys.txt

chmod 600 ~/.config/age/keys.txt

# View your public key
grep "# public key:" ~/.config/age/keys.txt
```

Back this file up somewhere safe. Lose it and you lose your secrets. No recovery button.

---

### 2. Get Your Host's SSH Key as Age Key

Convert your system’s SSH host key to an age public key:

```bash
# Option 1: If ssh-to-age is installed
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age

# Option 2: Using nix
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# Option 3: From remote host
ssh-keyscan YOUR_HOSTNAME | ssh-to-age
```

---

### 3. Update secrets.nix

Edit `secrets/secrets.nix` and replace placeholder keys:

```nix
let
  user1 = "age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";  # your age key
  laptop = "age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"; # host key
  
  users = [ user1 ];
  systems = [ laptop ];
  all = users ++ systems;
in
{
  "example-password.age".publicKeys = all;
}
```

---

### 4. Create and Edit Secrets

```bash
# Create or edit a secret
nix run github:yaxitech/ragenix -- -e secrets/example-password.age

# If installed in your environment
ragenix -e secrets/example-password.age
```

Flow:

1. Decrypts using your private key
2. Opens in `$EDITOR`
3. Re-encrypts on save + exit

---

### 5. Use Secrets in NixOS Configuration

```nix
# modules/secrets.nix
{ config, ... }:
{
  age.secrets = {
    example-password = {
      file = ../secrets/example-password.age;
      owner = "ewan";
      group = "users";
      mode = "0440";
    };
  };
}
```

Import it:

```nix
{
  imports = [
    ./modules/secrets.nix
  ];
}
```

Use it:

```nix
services.myservice = {
  enable = true;
  passwordFile = config.age.secrets.example-password.path;
};
```

Secrets appear at runtime under:

```
/run/agenix/<name>
```

---

## Common Use Cases

### WiFi Password

```nix
"wifi-password.age".publicKeys = all;

age.secrets.wifi-password.file = ../secrets/wifi-password.age;

networking.wireless.networks."MyNetwork".pskFile =
  config.age.secrets.wifi-password.path;
```

---

### SSH Private Key

```nix
age.secrets.ssh-private-key = {
  file = ../secrets/ssh-private-key.age;
  owner = "ewan";
  mode = "0600";
};

programs.ssh.extraConfig = ''
  Host github.com
    IdentityFile ${config.age.secrets.ssh-private-key.path}
'';
```

---

### Environment Variables

Secret file contents:

```
API_KEY=secret123
DB_PASSWORD=secret456
```

Config:

```nix
age.secrets.env-vars.file = ../secrets/env-vars.age;

systemd.services.myservice.serviceConfig.EnvironmentFile =
  config.age.secrets.env-vars.path;
```

---

## Rekeying Secrets

After changing keys in `secrets.nix`:

```bash
# Rekey all
nix run github:yaxitech/ragenix -- -r

# Rekey one
nix run github:yaxitech/ragenix -- -r secrets/example-password.age
```

---

## Tips

* Only commit `.age` files — never plaintext
* Back up `~/.config/age/keys.txt`
* Don’t share private keys across machines
* Rekey periodically
* `secrets.nix` is safe to commit — public keys only

---

## Troubleshooting

### “No identity found”

Ragenix looks for identities in:

* `~/.config/age/keys.txt`
* `~/.ssh/id_ed25519`
* `~/.ssh/id_rsa`

---

### Permission denied (key file)

```bash
chmod 600 ~/.config/age/keys.txt
```

---

### Secret not decrypting on boot

Your host age key is missing from the secret’s `publicKeys` list. Add it and rekey.

---

## File Structure

```
secrets/
├── secrets.nix
├── example-password.age
├── wifi-password.age
└── README.md
```
