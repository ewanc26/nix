# Secrets Management

Encrypted secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix). Secrets
are decrypted at activation time and referenced via `config.sops.secrets.<name>.path`.

Every secret is encrypted to **two kinds of recipient**:

- **Your PGP key** — the personal key that lets you read, edit and re-key any secret from
  any machine holding your private key.
- **Each host's age key** — derived automatically from that machine's SSH ed25519 host key.

## Why hosts still use age

Host decryption happens at activation, as root, with no controlling terminal. A
PGP key cannot be used there: `gpg-agent` has nowhere to prompt for a passphrase, and
avoiding that would mean storing a passphrase-less private key on each machine — strictly
more to manage than the SSH-host-key-derived age key, for no security gain. The host keys
therefore stay on age deliberately.

## How it works

- Each secret file is committed to the repo **already encrypted** — it is useless without
  a matching private key.
- `sops` uses the rules in `.sops.yaml` at the repo root to decide which keys can decrypt
  each file.
- On NixOS hosts, `sops-nix` decrypts at activation using the host's
  `/etc/ssh/ssh_host_ed25519_key` (converted to an age key internally). No key file needs
  to be placed on the system.
- On your workstation, `sops` uses your PGP key via `gpg-agent`.

### Key group structure

In `.sops.yaml`, `pgp:` and `age:` are listed inside a **single** key group. Within one
key group each recipient can decrypt independently, which is what we want.

Splitting them into two key groups would switch sops to Shamir secret sharing and require
*both* a PGP key and a host key before anything decrypts. Don't do that.

## Key inventory

Keys are declared in `.sops.yaml`:

| Name | Type | Location |
| --- | --- | --- |
| `ewan_pgp` | User (personal) | Your PGP private key, in your GnuPG keyring |
| `macmini` | Host (age) | `/etc/ssh/ssh_host_ed25519_key` on macmini |
| `laptop` | Host (age) | `/etc/ssh/ssh_host_ed25519_key` on laptop |
| `server` | Host (age) | `/etc/ssh/ssh_host_ed25519_key` on server |

### The old personal age key is gone

There is no longer a personal age key. The only age identities that exist are the host
keys, each derived from that machine's SSH host key. This matters because `sops
updatekeys` has to **decrypt** a file before it can re-encrypt it to a new recipient set —
so re-keying an existing secret requires a key that can still open it.

## Recovering secrets encrypted to the old key

Losing the personal age key does **not** mean the committed secrets are lost. Every file
is also encrypted to one or more host keys (see the rules in `.sops.yaml`), and those keys
still exist on the machines themselves:

| Secrets | Also readable by |
| --- | --- |
| Server-only rule (`pds.env`, `forgejo.env`, Cloudflare, Nextcloud, …) | `server` |
| `tailscale-auth-key` | `laptop` |
| Everything else (fallback rule) | `macmini`, `laptop`, `server` |

So anything you would otherwise have to re-provision by hand — Cloudflare API tokens,
Resend SMTP keys, the Tailscale auth key, the PDS PLC rotation key — can be recovered from
a host rather than regenerated.

On a host that is a recipient, derive its age identity from its SSH host key:

```bash
# On the server (root, since the host key is root-only)
sudo nix run nixpkgs#ssh-to-age -- -private-key \
  -i /etc/ssh/ssh_host_ed25519_key -o /tmp/host-age.txt

# Read a secret
SOPS_AGE_KEY_FILE=/tmp/host-age.txt \
  nix run nixpkgs#sops -- --decrypt --input-type binary --output-type binary \
  secrets/pds.env

# Or re-key everything the host can open, to the current .sops.yaml recipients
SOPS_AGE_KEY_FILE=/tmp/host-age.txt ./secrets/setup.sh --rekey-only

shred -u /tmp/host-age.txt
```

The PLC rotation key in `pds.env` is worth calling out: it cannot be regenerated without
re-signing the DID document, so recover that one rather than replacing it.

## Migrating to your PGP key

```bash
# 1. Put your fingerprint in .sops.yaml, replacing the placeholder.
gpg --list-secret-keys --with-colons --fingerprint | awk -F: '/^fpr:/{print $10; exit}'
$EDITOR .sops.yaml          # set the &ewan_pgp anchor

# 2. Re-encrypt, using a host age identity to decrypt (see above).
SOPS_AGE_KEY_FILE=/tmp/host-age.txt ./secrets/setup.sh --rekey-only

# 3. Verify each file now lists your PGP key.
./scripts/check-secrets.sh

# 4. Commit.
git add .sops.yaml secrets/ && git commit -m 'chore(secrets): re-key to PGP'
```

`--rekey-only` skips all secret generation and refuses to run while the placeholder
fingerprint is still in place or your secret key is missing from the keyring.

If you would rather start clean, `./secrets/setup.sh --force` regenerates the secrets it
can derive itself (Forgejo, PDS, Cloudflare tunnel, Docker, Claude) and prompts for the
rest. Anything issued by a third party still has to be reissued there.

Then rebuild each host so it picks up the re-encrypted files:

```bash
sudo nixos-rebuild switch --flake ~/.config/nix-config          # laptop / server
sudo darwin-rebuild switch --flake ~/.config/nix-config#macmini # macmini
```

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

`sops` reads `.sops.yaml` automatically and encrypts for the correct recipients based on
the filename.

### 2. Declare it in the NixOS module that uses it

```nix
# e.g. modules/server/services/my-service/my-service.nix
sops.secrets."my-secret.env" = {
  sopsFile = ../../../../secrets/my-secret.env;
  format   = "binary";   # for env files / raw content
  owner    = "my-service";
  mode     = "0400";
};
```

For structured files (YAML/JSON/dotenv), you can also extract individual keys:

```nix
sops.secrets."my-service/api-key" = {
  sopsFile = ../../../../secrets/my-service.yaml;
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

The `path` field places the decrypted file at a specific location rather than
`/run/user/<uid>/secrets/`.

## Adding a new host

When a new machine is provisioned, its SSH host key must be added to `.sops.yaml` so it
can decrypt the secrets it needs.

```bash
# 1. Get the host's age public key from its SSH host key
ssh-keyscan <host-ip> | ssh-to-age

# 2. Add the result to .sops.yaml under `keys:`
#    - &server age1...

# 3. Reference it in the relevant creation_rules

# 4. Re-encrypt every secret the host needs
./secrets/setup.sh --rekey-only
```

## Existing secrets

| File | Purpose | Accessible by |
| --- | --- | --- |
| `secrets/pds.env` | Bluesky PDS runtime secrets | PGP + server |
| `secrets/forgejo.env` | Forgejo `SECRET_KEY` etc. | PGP + server |
| `secrets/cf-tunnel.json` | Cloudflare tunnel credentials | PGP + server |
| `secrets/cloudflare-acme.env` | Cloudflare DNS-01 token (ewancroft.uk) | PGP + server |
| `secrets/cloudflare-acme-croft-click.env` | Cloudflare DNS-01 token (croft.click) | PGP + server |
| `secrets/cloudflare.token` | Cloudflare API token | PGP + server |
| `secrets/forgejo-user-token` | Forgejo user API token | PGP + server |
| `secrets/meilisearch-master-key` | Meilisearch master key | PGP + server |
| `secrets/nextcloud-admin-pass` | Nextcloud initial admin password | PGP + server |
| `secrets/nextcloud-smtp-pass` | Nextcloud SMTP (Resend) API key | PGP + server |
| `secrets/smartd-smtp-pass` | smartd alert SMTP (Resend) API key | PGP + server |
| `secrets/tailscale-auth-key` | Tailscale auth key | PGP + server |
| `secrets/vaultwarden.env` | Vaultwarden admin token + SMTP key | PGP + server |

## Security rules

1. Your PGP private key is what grants access to every secret in this repo. Treat it
   accordingly: passphrase-protected, backed up offline, never committed.
2. To use it on another machine, export and import it rather than copying keyrings:
   `gpg --export-secret-keys --armor <fpr>` → `gpg --import` on the target.
3. Encrypted secret files (in `secrets/`) **are** committed to git — they are useless
   without a matching private key.
4. Host keys are derived from the host's SSH `ed25519` host key and are never stored
   anywhere beyond the key itself. An age identity derived from one (see "Recovering
   secrets") is a full credential for everything that host can read — write it to a
   tmpfs path and `shred -u` it when done.

## Troubleshooting

| Error | Cause | Fix |
| --- | --- | --- |
| `no matching keys` | Secret not encrypted for this key | Add key to `.sops.yaml`, run `sops updatekeys <file>` |
| `key not found` | PGP secret key not in the keyring, or missing host SSH key | `gpg --import` your key, or re-derive the host key |
| `gpg: decryption failed: No secret key` | File was re-keyed to a PGP key you don't hold | Check the `&ewan_pgp` fingerprint in `.sops.yaml` matches `gpg --list-secret-keys` |
| Hangs with no prompt | `gpg-agent` cannot reach a pinentry (e.g. over plain SSH) | `export GPG_TTY=$(tty)`, or run it locally |
| `failed to decrypt` | Wrong key or corrupted file | `./scripts/check-secrets.sh` to see which recipients a file actually has |
| Secret path is empty | sops-nix activation failed | Check `journalctl -b \| grep sops` |
| `attribute '<user>' missing` at eval time | Secret owner uses `DynamicUser` — no static user entry exists | Declare the user/group explicitly (see below) |

### DynamicUser services and sops-nix

Some NixOS services (including `cloudflared`) use systemd's `DynamicUser = true`, which
means they do **not** create a static entry in `config.users.users`. sops-nix tries to
derive `group` from that attribute at evaluation time and fails with
`attribute '<user>' missing`.

Fix: explicitly declare the user and group alongside the secret:

```nix
users.users.cloudflared = {
  isSystemUser = true;
  group = "cloudflared";
};
users.groups.cloudflared = { };

sops.secrets."cf-tunnel.json" = {
  sopsFile = ../../../../secrets/cf-tunnel.json;
  format   = "binary";
  owner    = "cloudflared";
  group    = "cloudflared"; # must be set explicitly — cannot be derived from DynamicUser
  mode     = "0400";
};
```

This pattern is already applied in `modules/server/infra/network/cloudflare-tunnel.nix`.
