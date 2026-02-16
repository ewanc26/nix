# Tailscale SSH Configuration

This configuration enables dynamic SSH connections between your hosts (laptop, server, macmini) over Tailscale's encrypted mesh network.

## How It Works

### Dynamic Routing via ProxyCommand
Instead of hardcoding Tailscale IP addresses, the SSH configuration uses `ProxyCommand` with `tailscale nc` (netcat). This means:

1. When you run `ssh laptop`, SSH doesn't connect directly
2. Instead, it invokes `tailscale nc laptop 22`
3. Tailscale dynamically routes the connection through its mesh network
4. The connection automatically follows the host even if its Tailscale IP changes

### Benefits
- **Dynamic**: No hardcoded IP addresses - works even if Tailscale IPs change
- **Automatic**: Tailscale handles routing, NAT traversal, and encryption
- **Fast**: Direct peer-to-peer when possible, relayed when necessary
- **Secure**: All traffic encrypted through Tailscale's WireGuard-based mesh

## Configuration Files

- `home/programs/ssh.nix` - Defines SSH hosts and ProxyCommand routing
- `hosts/laptop/default.nix` - Laptop firewall trusts tailscale0
- `modules/server/firewall.nix` - Server firewall trusts tailscale0
- `settings/config/darwin.nix` - macOS Tailscale via Homebrew

## Initial Setup

### 1. Ensure Tailscale is Running
On each host:
```bash
# Check status
tailscale status

# If not running, start it
sudo tailscale up

# Optional: Set a hostname (if different from system hostname)
sudo tailscale set --hostname=your-hostname
```

### 2. Enable MagicDNS (if not already enabled)
MagicDNS allows you to use short hostnames like `laptop` instead of IPs:
```bash
# This is usually enabled by default
# Check at: https://login.tailscale.com/admin/dns
```

### 3. Rebuild Configuration
On each host, rebuild to apply the changes:

**Laptop/Server (NixOS)**:
```bash
cd ~/.config/nix-config
sudo nixos-rebuild switch --flake .#laptop  # or .#server
```

**MacMini (macOS)**:
```bash
cd ~/.config/nix-config
sudo darwin-rebuild switch --flake .#macmini
```

### 4. Verify Setup
Run the verification script:
```bash
verify-tailscale-ssh
```

## Usage

### Simple SSH
Just use the hostname:
```bash
ssh laptop
ssh server
ssh macmini
```

### With rsync
```bash
rsync -av ~/Documents/ server:~/backup/
```

### With scp
```bash
scp file.txt laptop:~/
```

### With git
If you have git repos on your hosts:
```bash
git clone server:~/projects/myrepo.git
```

## Troubleshooting

### "tailscale: command not found"
- **Linux**: Ensure you rebuilt with the updated configuration
- **macOS**: Ensure Homebrew is in PATH: `eval "$(/opt/homebrew/bin/brew shellenv)"`

### "Connection refused" or "Connection timed out"
1. Verify Tailscale is running: `tailscale status`
2. Check the target host is online in Tailscale
3. Verify firewall allows tailscale0: `sudo firewall-cmd --list-all` (if using firewalld)
4. Test Tailscale connectivity: `tailscale ping laptop`

### "Host key verification failed"
This is normal on first connection. Accept the host key:
```bash
ssh laptop  # Type "yes" when prompted
```

### SSH hangs or is slow
1. Check Tailscale connection quality: `tailscale status`
2. Force direct connection: `sudo tailscale up --accept-routes=false`
3. Check if relay is being used: Look for "relay" in `tailscale status`

## Security Notes

- **Firewall**: The firewall trusts the tailscale0 interface completely
- **Authentication**: Still requires SSH key authentication (keys in authorized_keys)
- **Encryption**: Tailscale provides additional encryption layer beyond SSH
- **Access Control**: Managed through Tailscale ACLs at login.tailscale.com

## Adding New Hosts

To add a new host to the Tailscale SSH mesh:

1. Edit `home/programs/ssh.nix`
2. Add the hostname to the `internalHosts` list:
   ```nix
   internalHosts = [ "laptop" "server" "macmini" "newhost" ];
   ```
3. Rebuild configuration on all hosts
4. Ensure the new host has appropriate SSH keys in authorized_keys
