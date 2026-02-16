# Server Host

> **⚠️ Note**: This is a planned configuration that has not yet been deployed to hardware. The configuration is ready; follow the runbook below.

Hardened NixOS server running a Bluesky ATProto PDS, exposed via a Cloudflare tunnel (no open inbound ports except SSH).

## Architecture

```
Internet → Cloudflare edge (TLS)
               ↓ encrypted tunnel (outbound from server)
           cloudflared daemon
               ↓ HTTP
           Caddy (127.0.0.1:2020)
               ↓ age-assurance static responses (UK OSA)
               ↓ reverse proxy
           bluesky-pds (127.0.0.1:3000)
```

No ports 80/443 need to be open in the firewall. SSH is the only public port.

---

## Pre-Deploy Checklist (do these NOW, before the server exists)

These steps interact only with Cloudflare and your local machine — the server
doesn't need to exist yet.

### 1. Generate PDS secrets

If you haven't already done this (check whether `secrets/age/pds.env.age` is
populated with real secrets — not a placeholder):

```bash
# Generate each secret separately — do NOT reuse values
PDS_JWT_SECRET=$(openssl rand --hex 16)
PDS_ADMIN_PASSWORD=$(openssl rand --hex 16)
PDS_PLC_ROTATION_KEY=$(openssl ecparam --name secp256k1 --genkey --noout \
  --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32)

# Edit the secret file (ragenix opens $EDITOR):
nix run github:yaxitech/ragenix -- \
  --rules secrets/secrets.nix \
  --editor "code --wait" \
  -e secrets/age/pds.env.age
```

The file should contain (one per line):

```
PDS_JWT_SECRET=<value>
PDS_ADMIN_PASSWORD=<value>
PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=<value>
PDS_EMAIL_SMTP_URL=smtps://resend:<api-key>@smtp.resend.com:465/
PDS_EMAIL_FROM_ADDRESS=pds@ewancroft.uk
```

### 2. Create the Cloudflare tunnel

Run this on your **macmini or laptop** (not the server — it doesn't exist yet):

```bash
# Authenticate with your Cloudflare account (opens browser)
cloudflared tunnel login

# Create the tunnel — note the UUID printed in the output
cloudflared tunnel create pds
# → Created tunnel pds with id XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

### 3. Update the tunnel UUID in settings

Edit `settings/config/pds.nix` and replace the placeholder UUID:

```nix
cloudflare = {
  tunnelId = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";  # ← paste real UUID here
};
```

### 4. Encrypt the tunnel credentials

The JSON credentials file is at `~/.cloudflared/<UUID>.json` after step 2:

```bash
cp ~/.cloudflared/<UUID>.json /tmp/cf-tunnel-pds.json

nix run github:yaxitech/ragenix -- \
  --rules secrets/secrets.nix \
  --editor "code --wait" \
  -e secrets/age/cf-tunnel-pds.json.age

# Paste the JSON file contents into the editor, save and close.
# Delete the plaintext copy:
rm /tmp/cf-tunnel-pds.json
```

### 5. Add the DNS CNAME in Cloudflare

In the Cloudflare dashboard (or via `cloudflared tunnel route dns`):

```
pds.ewancroft.uk       CNAME   <UUID>.cfargotunnel.com   (proxied ✓)
*.ewancroft.uk         CNAME   <UUID>.cfargotunnel.com   (proxied ✓)
```

The `*.ewancroft.uk` wildcard lets users choose `@user.ewancroft.uk` handles.

---

## Deploy Day

### 1. Boot the NixOS installer on the server

Partition and mount disks, then generate the hardware config:

```bash
sudo nixos-generate-config --show-hardware-config
```

Copy the output into `hosts/server/minimal-hardware.nix` (replacing the
placeholder content), commit, and push.

### 2. Get the server age key

While still on the installer (or after first boot):

```bash
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```

Paste the result into `secrets/secrets.nix`:

```nix
systems = {
  # ...
  server = "age1...";  # ← paste here
};
```

Also change `pdsKeys` from `[ users.ewan ]` to `[ users.ewan systems.server ]`.

### 3. Rekey secrets for the server

From your macmini or laptop (you need your private age key):

```bash
cd ~/.config/nix-config
nix run github:yaxitech/ragenix -- --rules secrets/secrets.nix --rekey
git add secrets/age/ secrets/secrets.nix
git commit -m "secrets: add server key and rekey PDS secrets"
git push
```

### 4. Install NixOS

```bash
# On the server installer, clone the repo and install:
nix-shell -p git
git clone https://github.com/ewanc26/nix /mnt/etc/nixos
nixos-install --flake /mnt/etc/nixos#server
reboot
```

### 5. Verify on the server

```bash
# Check all services are up
systemctl status bluesky-pds
systemctl status cloudflared
systemctl status caddy

# Check the PDS is reachable via the tunnel
curl https://pds.ewancroft.uk/xrpc/_health

# Check UK OSA age-assurance endpoints work
curl https://pds.ewancroft.uk/xrpc/app.bsky.ageassurance.getConfig
```

### 6. Create your account

```bash
# Install atproto-goat (already in systemPackages on the server)
# Create an invite code first, then create the account
atproto-goat --pds-host https://pds.ewancroft.uk account create
```

---

## Key settings

All non-secret PDS settings live in `settings/config/pds.nix`:

| Setting | Value |
|---|---|
| Hostname | `pds.ewancroft.uk` |
| Handle domains | `.ewancroft.uk` |
| PDS port | `3000` (internal only) |
| Caddy port | `2020` (internal only) |
| Tunnel ID | set in `settings/config/pds.nix` |

---

## Security

| Hardening | Status |
|---|---|
| Root login disabled | ✅ |
| Password auth disabled | ✅ |
| Fail2ban active | ✅ |
| SSH key-only | ✅ |
| Firewall: SSH only | ✅ |
| No public HTTP/HTTPS ports | ✅ (Cloudflare tunnel) |
| Secrets age-encrypted | ✅ |
| PDS secrets server-only | ✅ (after rekeying) |

---

## Ongoing maintenance

```bash
# Manual rebuild
sudo nixos-rebuild switch --flake /home/ewan/.config/nix-config#server

# PDS logs
journalctl -u bluesky-pds -f

# Tunnel status
journalctl -u cloudflared -f

# Check banned IPs
sudo fail2ban-client status sshd

# Disk health
sudo smartctl -a /dev/sda
```

## Resources

- [isabelroses PDS guide](https://isabelroses.com/blog/nix-pds-guide/) — basis for this config
- [Cloudflare tunnel docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [ATProto PDS environment variables](https://github.com/bluesky-social/atproto/blob/main/packages/pds/src/config/env.ts)
- [UK OSA age-assurance gist](https://gist.github.com/mary-ext/6e27b24a83838202908808ad528b3318)
