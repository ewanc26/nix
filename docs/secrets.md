# Secrets Management

Encrypted secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) using [age](https://age-encryption.org/) as the encryption backend. Secrets are decrypted at activation time and referenced via `config.sops.secrets.<name>.path` (system-level) or `config.sops.secrets.<name>.path` inside home-manager.

## How it works

- Each secret file is committed to the repo **already encrypted** — it is useless without the private key.
- `sops` uses the rules in `.sops.yaml` at the repo root to know which age keys can decrypt each file.
- On NixOS hosts, `sops-nix` decrypts secrets at activation using the host's `/etc/ssh/ssh_host_ed25519_key` (automatically converted to an age key). No separate key file is needed on the system itself.
- On macOS, your personal age key (`~/.config/age/keys.txt`) is used.

## Key inventory

Keys are declared in `.sops.yaml`:

| Name | Type | Location |
|---|---|---|
| `ewan` | User (personal) | `~/.config/age/keys.txt` |
| `macmini` | Host | `/etc/ssh/ssh_host_ed25519_key` on macmini |
| `laptop` | Host | `/etc/ssh/ssh_host_ed25519_key` on laptop |
| `server` | Host | `/etc/ssh/ssh_host_ed25519_key` on server *(add after first boot)* |

## Quick reference

```bash
# Edit an existing secret (opens $EDITOR with decrypted content)
sops secrets/pds.env

# Encrypt a new file in-place
sops --encrypt secrets/new-secret.env > secrets/new-secret.env

# Re-encrypt all secrets after adding a new key to .sops.yaml
sops updatekeys secrets/pds.env
```

## Adding a new secret

### 1. Create and encrypt the file

```bash
# Create plaintext in /tmp, never in the repo
cat > /tmp/my-secret.env << 'EOF'
MY_KEY=some-value
EOF

# Encrypt it into the secrets directory
sops --encrypt /tmp/my-secret.env > secrets/my-secret.env
rm /tmp/my-secret.env
```

`sops` reads `.sops.yaml` automatically and encrypts for the correct recipients based on the filename.

### 2. Declare it in the NixOS module that uses it

```nix
# e.g. modules/my-service.nix
sops.secrets."my-secret.env" = {
  sopsFile = ../secrets/my-secret.env;
  format   = "binary";   # for env files / raw content
  owner    = "my-service";
  mode     = "0400";
};
```

For structured files (YAML/JSON/dotenv), you can also extract individual keys:

```nix
sops.secrets."my-service/api-key" = {
  sopsFile = ../secrets/my-service.yaml;
  # sops-nix extracts the "my-service/api-key" key automatically
};
```

### 3. Reference the decrypted path

```nix
# In a systemd service
systemd.services.my-service.serviceConfig.EnvironmentFile =
  config.sops.secrets."my-secret.env".path;

# In a script
script = ''
  TOKEN=$(cat ${config.sops.secrets."my-service/api-key".path})
'';
```

### 4. Home-manager secrets

Home-manager secrets use the same `sops-nix` module (via `sops-nix.homeManagerModules.sops`):

```nix
# home/default.nix
sops.secrets."claude-config" = {
  sopsFile = ../secrets/claude.json;
  path     = "${config.home.homeDirectory}/.claude.json";
  mode     = "0600";
};
```

The `path` field places the decrypted file at a specific location rather than `/run/user/<uid>/secrets/`.

## Adding a new host

When a new machine is provisioned, its SSH host key must be added to `.sops.yaml` so it can decrypt the secrets it needs.

```bash
# 1. Get the host's age public key from its SSH host key
ssh-keyscan <host-ip> | ssh-to-age

# 2. Add the result to .sops.yaml under `keys:`
#    - &server age1...

# 3. Reference it in the relevant creation_rules

# 4. Re-encrypt every secret the host needs
sops updatekeys secrets/pds.env
sops updatekeys secrets/cf-tunnel.json
# ... etc
```

## Existing secrets

| File | Purpose | Accessible by |
|---|---|---|
| `secrets/wifi-home` | Home WiFi passphrase | all hosts |
| `secrets/ssh-passphrase` | SSH private key passphrase | all hosts |
| `secrets/docker-config.json` | Docker Hub credentials | all hosts |
| `secrets/claude.json` | Claude API / config | all hosts |
| `secrets/duckdns.tar.gz` | DuckDNS config bundle | all hosts |
| `secrets/pds.env` | Bluesky PDS runtime secrets | ewan + server |
| `secrets/matrix.env` | Matrix Synapse secrets | ewan + server |
| `secrets/forgejo.env` | Forgejo `SECRET_KEY` etc. | ewan + server |
| `secrets/cloudflare.token` | Cloudflare API token | ewan + server |
| `secrets/cf-tunnel.json` | Cloudflare tunnel credentials | ewan + server |

## Security rules

1. `~/.config/age/keys.txt` is your personal private key — treat it like an SSH private key. Never commit it.
2. Sync it to other machines via `scp` over Tailscale: `scp ~/.config/age/keys.txt ewan@laptop:~/.config/age/keys.txt`
3. Encrypted secret files (in `secrets/`) **are** committed to git — they are useless without a matching private key.
4. Host keys are derived from the host's SSH `ed25519` host key and are never stored anywhere beyond the key itself.

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `no matching keys` | Secret not encrypted for this key | Add key to `.sops.yaml`, run `sops updatekeys <file>` |
| `key not found` | Missing `~/.config/age/keys.txt` or host SSH key | Restore key or re-derive host key |
| `failed to decrypt` | Wrong key or corrupted file | Verify key with `age-keygen --to-public-key` |
| Secret path is empty | sops-nix activation failed | Check `journalctl -b | grep sops` |
