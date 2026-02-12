# Server Host Configuration

A minimal NixOS server configuration with security hardening and automatic updates.

## Features

### ✅ Included
- **SSH Server** - Secure remote access with key-based authentication only
- **Fail2ban** - Automatic SSH brute-force protection
- **Firewall** - Enabled by default (SSH only)
- **Auto-updates** - Daily system updates with flake lock commits
- **Auto-backup** - Git commits every 6 hours with network-aware push
- **Monitoring Tools** - htop, btop, network tools, disk utilities
- **SMART Monitoring** - Disk health monitoring
- **SSD Optimization** - Weekly TRIM operations
- **Automatic Cleanup** - Garbage collection and log rotation
- **Zsh Shell** - With shared dotfiles from home-manager

### ❌ Not Included
- No desktop environment or GUI
- No gaming packages
- No multimedia applications

## Installation

### 1. On Your Server

Boot the NixOS installer and set up your disk partitions.

### 2. Generate Hardware Configuration

```bash
# Mount your partitions first, then:
sudo nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix
```

Copy this file to your local machine at:
```
hosts/server/hardware-configuration.nix
```

### 3. Configure SSH Keys

Edit `hosts/server/default.nix` and add your SSH public keys:

```nix
users.users.ewan = {
  # ... other config ...
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@host"
  ];
};
```

### 4. Customize Settings

**Firewall Ports** (if running web server, etc.):
```nix
networking.firewall.allowedTCPPorts = [ 22 80 443 ];
```

**Enable Optional Services** - See `modules/server-services.nix` for:
- Docker/Podman
- Nginx web server
- PostgreSQL database
- And more (just uncomment)

### 5. Install from USB/ISO

If installing from scratch:

```bash
# On the installer, clone the config
cd /mnt/etc/nixos
sudo git clone https://github.com/yourusername/nix-config .

# Install
sudo nixos-install --flake .#server

# Reboot
reboot
```

### 6. Or Switch from Existing NixOS

If converting an existing system:

```bash
# Clone config to expected location
cd /tmp
git clone https://github.com/yourusername/nix-config
cd nix-config

# Copy your hardware config
sudo nixos-generate-config --show-hardware-config > hosts/server/hardware-configuration.nix

# Build and switch
sudo nixos-rebuild switch --flake .#server

# Move config to permanent location
sudo cp -r . /home/ewan/.config/nix-config
cd /home/ewan/.config/nix-config

# Rebuild from new location
sudo nixos-rebuild switch --flake .#server
```

## Post-Installation

### 1. Verify SSH Access

From your local machine:
```bash
ssh ewan@your-server-ip
```

### 2. Check Services

```bash
# Check SSH is running
systemctl status sshd

# Check fail2ban is active
systemctl status fail2ban

# Check automatic backups
systemctl --user status nix-config-backup.timer

# Check firewall
sudo iptables -L -n
```

### 3. Update System

The system auto-updates daily, but you can manually update:

```bash
sudo nixos-rebuild switch --flake /home/ewan/.config/nix-config#server
```

## Security Notes

### SSH Hardening
- ✅ Root login disabled
- ✅ Password authentication disabled (keys only)
- ✅ Fail2ban monitoring SSH attempts
- ✅ Limited to specific users
- ✅ Connection timeouts configured

### Firewall
- ✅ Enabled by default
- ✅ Only SSH (port 22) open by default
- ✅ Add more ports as needed in config

### Automatic Updates
- ✅ System updates daily
- ✅ Security patches applied automatically
- ✅ Optional: Enable automatic reboots in `modules/server-services.nix`

### Monitoring
- ✅ SMART disk monitoring
- ✅ System logs (journald)
- ✅ Log rotation configured

## Maintenance

### Check Disk Health
```bash
sudo smartctl -a /dev/sda
```

### View Logs
```bash
journalctl -xe
journalctl -u sshd
journalctl -u fail2ban
```

### Check Failed Login Attempts
```bash
sudo fail2ban-client status sshd
```

### Manual Backup
```bash
cd /home/ewan/.config/nix-config
./scripts/auto-backup.sh
```

### Clean Old Generations
```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Delete old generations (automatic weekly, but can do manually)
sudo nix-collect-garbage --delete-older-than 30d
```

## Customization

### Add More Services

Edit `modules/server-services.nix` and uncomment services you need:
- Docker / Podman for containers
- Nginx for web serving
- PostgreSQL for databases

### Change Timezone

Edit `hosts/server/default.nix`:
```nix
time.timeZone = "America/New_York"; # or your timezone
```

### Add More Users

Edit `hosts/server/default.nix`:
```nix
users.users.newuser = {
  isNormalUser = true;
  extraGroups = [ "wheel" ]; # for sudo
  openssh.authorizedKeys.keys = [ "ssh-..." ];
};
```

### Change Hostname

Edit `hosts/server/default.nix`:
```nix
networking.hostName = "my-server";
```

## Backup System

Same as laptop/desktop hosts:
- Auto-commits every 6 hours
- Network-aware (commits locally if offline)
- Git hooks validate and auto-push
- See [BACKUP_SETUP.md](../../BACKUP_SETUP.md) for details

## Common Tasks

### Add a Web Server

1. Edit `modules/server-services.nix` - uncomment nginx section
2. Edit `hosts/server/default.nix` - add ports 80, 443 to firewall
3. Rebuild: `sudo nixos-rebuild switch --flake .#server`

### Add Docker

1. Edit `modules/server-services.nix` - uncomment docker section
2. Rebuild: `sudo nixos-rebuild switch --flake .#server`
3. Add user to docker group if needed

### Change SSH Port

1. Edit `modules/server-services.nix`:
   ```nix
   services.openssh.ports = [ 2222 ]; # or your port
   ```
2. Edit `hosts/server/default.nix`:
   ```nix
   networking.firewall.allowedTCPPorts = [ 2222 ]; # match SSH port
   ```
3. Rebuild

## Troubleshooting

### Can't SSH In

- Check firewall: `sudo iptables -L`
- Check SSH service: `systemctl status sshd`
- Check SSH config: `sudo sshd -T`
- Check fail2ban: `sudo fail2ban-client status sshd`

### System Not Updating

- Check timer: `systemctl status nixos-upgrade.timer`
- Check logs: `journalctl -u nixos-upgrade.service`
- Trigger manually: `sudo systemctl start nixos-upgrade.service`

### Backups Not Working

- Check timer: `systemctl --user status nix-config-backup.timer`
- Check logs: `journalctl --user -u nix-config-backup.service`
- Run manually: `./scripts/auto-backup.sh`

## Architecture

```
hosts/server/
├── default.nix              # Main server configuration
└── hardware-configuration.nix  # Generated hardware config

modules/
├── server-packages.nix      # Server-specific packages
├── server-services.nix      # Server services (SSH, fail2ban, etc.)
└── git-backup.nix           # Automatic backup service

home/ (shared with all hosts)
├── home.nix                 # Home manager config
└── programs/
    ├── git.nix
    ├── zsh.nix              # Zsh configuration
    ├── starship.nix
    └── ...
```

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Security Wiki](https://nixos.wiki/wiki/Security)
- [SSH Hardening Guide](https://nixos.wiki/wiki/SSH_public_key_authentication)
