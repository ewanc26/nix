# Secrets Management

Encrypted secrets managed with [ragenix](https://github.com/yaxitech/ragenix) (age encryption). Secrets are decrypted at runtime to `/run/agenix/<name>` and referenced via `config.age.secrets.<name>.path`.

## Quick Start

```bash
bash ./secrets/setup.sh
```

**What the script does:**
1. Manages `~/.config/age/keys.txt` (your master identity — copy this to every machine)
2. Converts the machine's SSH host key to an age key and adds it to the `systems` block in `secrets/secrets.nix`
3. Additively updates `secrets.nix` without removing existing entries
4. Validates Nix syntax and re-encrypts (rekeys) secrets for the new hardware

## Adding a New Secret

### 1. Register it in `settings/config/secrets.nix`

```nix
{
  files = [
    "ssh-passphrase"
    "wifi-home"
    "my-new-secret"   # add here
  ];
}
```

`modules/secrets.nix` automatically generates `age.secrets` entries for every file in this list.

### 2. Encrypt the secret

```nix
# Using ragenix (recommended)
nix run github:yaxitech/ragenix -- \
  --rules secrets/secrets.nix \
  --editor "code --wait" \
  -e secrets/age/my-new-secret.age
```

Or encrypt directly with rage:

```bash
rage -e -r "$(cat ~/.ssh/id_ed25519.pub)" my-secret.txt > secrets/age/my-new-secret.age
```

### 3. Register the public key in `secrets/secrets.nix`

```nix
"age/my-new-secret.age".publicKeys = all;  # or a subset
```

### 4. Rebuild

The secret is now available at `config.age.secrets.my-new-secret.path`.

## Using Secrets in Config

```nix
# Service password file
services.someService.passwordFile = config.age.secrets.my-secret.path;

# Environment variable
systemd.services.myservice.environment.TOKEN_FILE =
  config.age.secrets.api-token.path;

# In a script
script = ''
  TOKEN=$(cat ${config.age.secrets.api-token.path})
'';
```

## Rekeying (after adding a new machine)

```bash
nix run github:yaxitech/ragenix -- --rules secrets/secrets.nix --rekey
```

## File Structure

```
secrets/
├── secrets.nix      # Public key mappings — safe to commit
├── setup.sh         # Key management automation
└── age/
    ├── *.age        # Encrypted secrets — safe to commit
    └── ...

~/.config/age/keys.txt   # ⚠️  Private master key — NEVER commit
```

## Security Rules

1. `~/.config/age/keys.txt` is your master private key — treat it like your SSH private key
2. Sync `keys.txt` to other machines via `scp` over Tailscale (never via git)
3. `.age` files are safe to commit — they are useless without the private key
4. **UI preferences are NOT secrets** — they live in `settings/gnome/` and `settings/darwin/`

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| "No rule for file" | `.age` file not in `secrets.nix` | Add it to `secrets/secrets.nix` |
| "Decryption failed" | New system key added but not rekeyed | Run `--rekey` from a machine that has access |
| Path errors | Running from wrong directory | Pass `--rules secrets/secrets.nix` explicitly |
