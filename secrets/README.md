# Secrets Management with ragenix

This directory contains encrypted secrets managed with [ragenix](https://github.com/yaxitech/ragenix). Secrets are encrypted using [age](https://age-encryption.org/) and decrypted at runtime by your NixOS host.

---

## 🚀 Quick Start (Automated)

Instead of manually managing public keys, use the provided bootstrap script. It handles age key generation, SSH host key derivation, and `secrets.nix` updates.

```bash
# Run the bootstrap script
sudo bash /etc/nixos/secrets/setup.sh

```

**What this script does:**

1. Generates `~/.config/age/keys.txt` if missing.
2. Converts `/etc/ssh/ssh_host_ed25519_key.pub` to an age key.
3. Automatically populates or updates `secrets/secrets.nix` with the correct keys and Nix syntax.
4. Rekeys existing secrets if new keys were added.

---

## 🛠 Manual Operations

### 1. Create or Edit a Secret

```bash
# Edit a secret (opens in $EDITOR)
nix run github:yaxitech/ragenix -- -e secrets/my-secret.age

```

### 2. Update `secrets.nix`

If you add a new secret file, you must register it in `secrets/secrets.nix`:

```nix
let
  users = {
    ewan = "age1..."; 
  };
  systems = {
    laptop = "age1...";
  };
  all = (builtins.attrValues users) ++ (builtins.attrValues systems);
in
{
  "my-secret.age".publicKeys = all;
  "wifi-password.age".publicKeys = [ users.ewan systems.laptop ];
}

```

### 3. Rekeying

After changing `secrets.nix` (e.g., adding a new laptop), you must re-encrypt the secrets so the new key can open them:

```bash
nix run github:yaxitech/ragenix -- -r

```

---

## ❄️ Use in NixOS Configuration

### 1. Define the Secret

Map the encrypted file to a path on the system:

```nix
# modules/secrets.nix
{ config, ... }:
{
  age.secrets.example-password = {
    file = ../secrets/example-password.age;
    owner = "ewan";
    group = "users";
    mode = "0440";
  };
}

```

### 2. Consume the Secret

Access the plaintext path via `config.age.secrets.<name>.path`:

```nix
services.myservice = {
  enable = true;
  passwordFile = config.age.secrets.example-password.path;
};

```

*Secrets are decrypted to `/run/agenix/<name>` at boot.*

---

## 📂 Common File Structure

```text
/etc/nixos/
├── secrets/
│   ├── secrets.nix      # Public key mapping (safe to commit)
│   ├── setup.sh         # The automation script
│   ├── README.md        # This file
│   └── *.age            # Encrypted secrets (safe to commit)
├── configuration.nix
└── flake.nix

```

---

## ⚠️ Important Security Rules

1. **Never commit plaintext.** Only commit `.age` files.
2. **Backup your key.** If you lose `~/.config/age/keys.txt`, you lose access to all secrets.
3. **Host Keys.** The host key (derived from SSH) allows the *machine* to decrypt secrets without you being logged in.

---

### Troubleshooting

* **"Undefined variable age1..."**: This means a key in `secrets.nix` is missing double quotes. Run `setup.sh` to fix the syntax automatically.
* **"No identity found"**: Ensure `~/.config/age/keys.txt` exists and has permissions `600`.
