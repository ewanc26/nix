# Server Host

> **⚠️ Note**: This is a planned configuration that has not yet been deployed to hardware. The configuration is maintained and ready for deployment when needed.

Minimal NixOS server configuration with security hardening and automatic maintenance.

## Features

**Included:**
- SSH server — key-based authentication only, hardened settings
- Fail2ban — automatic brute-force protection
- Firewall — SSH-only by default
- Auto-upgrades — daily, via `settings/config/maintenance.nix`
- Monitoring tools — btop, iotop, iftop, smartmontools, network tools
- SMART disk monitoring
- Weekly SSD TRIM
- Log rotation and garbage collection
- Zsh shell via shared Home Manager config

**Not included:**
- No desktop environment or GUI
- No gaming or multimedia packages

## Installation

### 1. Generate hardware config

Boot the NixOS installer, partition disks, mount them, then:

```bash
sudo nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix
```

Copy the output to `hosts/server/hardware-configuration.nix`.

### 2. Configure SSH keys

SSH public keys are managed in `modules/ssh-keys.nix`. Add the server's key there.

### 3. Customise settings

All server-specific values live in `settings/config/server.nix`:
- `sshd.port` — SSH port (default: 22)
- `firewall.allowedTCPPorts` — open ports
- `fail2ban.banTime` / `fail2ban.maxRetry` — intrusion thresholds

### 4. Install from USB/ISO

```bash
# On the installer
cd /mnt/etc/nixos
curl -L https://github.com/ewanc26/nix/archive/refs/heads/main.tar.gz | sudo tar -xz --strip-components=1
sudo nixos-install --flake .#server
reboot
```

### 5. Or switch from existing NixOS

```bash
cd /tmp
curl -L https://github.com/ewanc26/nix/archive/refs/heads/main.tar.gz | tar -xz
mv nix-config-main nix-config && cd nix-config
sudo nixos-generate-config --show-hardware-config > hosts/server/hardware-configuration.nix
sudo nixos-rebuild switch --flake .#server
sudo cp -r . /home/ewan/.config/nix-config
```

## Post-Installation

### Verify SSH

```bash
ssh ewan@your-server-ip
```

### Check services

```bash
systemctl status sshd
systemctl status fail2ban
sudo iptables -L -n
```

### Manual update

```bash
sudo nixos-rebuild switch --flake /home/ewan/.config/nix-config#server
```

## Security

| Hardening | Status |
|---|---|
| Root login disabled | ✅ |
| Password auth disabled | ✅ |
| Fail2ban active | ✅ |
| AllowUsers restricted | ✅ |
| Connection timeouts | ✅ |
| Firewall enabled | ✅ |

To open additional ports, edit `settings/config/server.nix` → `firewall.allowedTCPPorts`.

## Maintenance

```bash
# Disk health
sudo smartctl -a /dev/sda

# View logs
journalctl -xe
journalctl -u sshd
journalctl -u fail2ban

# Check banned IPs
sudo fail2ban-client status sshd

# Garbage collection (auto-runs weekly)
sudo nix-collect-garbage --delete-older-than 30d
```

## Common Customisations

### Add a web server
1. Add `80` and `443` to `settings/config/server.nix` → `firewall.allowedTCPPorts`
2. Add nginx config to `hosts/server/default.nix`
3. Rebuild

### Change SSH port
Edit `settings/config/server.nix` → `sshd.port` (firewall updates automatically from the same value).

### Add a user
Edit `hosts/server/default.nix` and add an entry to `users.users`.

## Troubleshooting

**Can't SSH in:**
```bash
sudo iptables -L
systemctl status sshd
sudo sshd -T
sudo fail2ban-client status sshd
```

**System not upgrading:**
```bash
systemctl status nixos-upgrade.timer
journalctl -u nixos-upgrade.service
sudo systemctl start nixos-upgrade.service
```

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Security Wiki](https://nixos.wiki/wiki/Security)
- [SSH hardening](https://nixos.wiki/wiki/SSH_public_key_authentication)
