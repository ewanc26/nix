# Secrets Management with ragenix

This directory contains encrypted secrets managed with [ragenix](https://github.com/yaxitech/ragenix), a Rust-based implementation of agenix. Secrets are encrypted using [age](https://age-encryption.org/) and decrypted at runtime by your **nix-darwin** or **NixOS** host.

## 🚀 Quick Start (Automated)

The provided bootstrap script manages your **Master Identity** (user key) and **Host Identity** (SSH-derived key) to ensure your `secrets.nix` is always in sync.

```bash
# From the root of your dotfiles:
bash ./secrets/setup.sh

```

**What this script does:**

1. **Master Identity:** Manages `~/.config/age/keys.txt`. (Copy this file to all your machines to maintain one "User" identity).
2. **Host Identity:** Converts your machine's SSH host key to an age key and adds it to the `systems` block.
3. **Additive Updates:** Adds new machines to `secrets.nix` without wiping out existing ones.
4. **Validation:** Verifies Nix syntax and attempts to re-encrypt (rekey) secrets for the new hardware.

---

## 🛠 Manual Operations

### 1. Create or Edit a Secret

`ragenix` requires an explicit editor flag and rules path if run from the repository root.

```bash
# Using VS Code as the editor (requires 'code' in $PATH)
nix run github:yaxitech/ragenix -- --rules secrets/secrets.nix --editor "code --wait" -e secrets/wifi-password.age

# Using Nano
nix run github:yaxitech/ragenix -- --rules secrets/secrets.nix --editor "nano" -e secrets/wifi-password.age

```

### 2. Registering Secrets

Before creating a `.age` file, you **must** define it in `secrets/secrets.nix`:

```nix
in
{
  "wifi-password.age".publicKeys = all; 
  "github-token.age".publicKeys = [ users.ewan systems.MacMini ];
}

```

### 3. Rekeying

If you add a new machine to `secrets.nix`, you must re-encrypt all files so the new machine can read them:

```bash
nix run github:yaxitech/ragenix -- --rules secrets/secrets.nix --rekey

```

---

## ❄️ Use in Flake Configuration

### 1. Configure the Module

Add the `ragenix` input and module to your system configuration:

```nix
# flake.nix
{
  inputs.ragenix.url = "github:yaxitech/ragenix";
  
  outputs = { self, nix-darwin, ragenix, ... }: {
    darwinConfigurations.MacMini = nix-darwin.lib.darwinSystem {
      modules = [
        ragenix.darwinModules.default # or ragenix.nixosModules.default
        {
          age.identityPaths = [ "/Users/ewan/.config/age/keys.txt" ];
          age.secrets.wifi-password.file = ./secrets/wifi-password.age;
        }
      ];
    };
  };
}

```

### 2. Accessing Secrets

Secrets are decrypted to `/run/agenix/<name>` (Linux) or `/Library/Application Support/ragenix/secrets/<name>` (macOS).

```nix
# Access via config
passwordFile = config.age.secrets.wifi-password.path;

```

---

## 📂 Structure

* `secrets.nix`: Public key mapping (Safe to commit).
* `setup.sh`: Automation for key management.
* `*.age`: Encrypted secret data (Safe to commit).
* `~/.config/age/keys.txt`: **Your Private Key (NEVER COMMIT).**

---

## ⚠️ Important Security Rules

1. **The Master Key:** Treat `~/.config/age/keys.txt` like your primary SSH private key. If you lose it, you lose your secrets.
2. **Tailscale Sync:** Since we use a single Master User key, use `scp` or `ssh` over Tailscale to sync `keys.txt` from your main Mac to your Laptop.
3. **Commit often:** It is perfectly safe to commit `.age` files to GitHub; they are useless without your private keys.

---

### Troubleshooting

* **"No rule for file"**: You added a `.age` file but forgot to add it to the list in `secrets.nix`.
* **"Decryption failed"**: You likely added a new system key but didn't run `--rekey` using a machine that already has access.
* **Path errors**: Always ensure you are pointing to `--rules secrets/secrets.nix` if running from the root.
