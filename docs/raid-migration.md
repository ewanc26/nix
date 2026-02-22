# Migrating /srv to RAID

This guide covers moving the server's `/srv` data disk from a single drive to a
software RAID array when new hardware arrives. No data should be lost if the
steps are followed in order.

---

## Choosing a RAID Level

| Level | Drives needed | Usable space | Fault tolerance | Use case |
|---|---|---|---|---|
| **RAID 1** | 2 | 50% | 1 drive failure | Best for a 2-drive home server — simple, safe |
| **RAID 5** | 3+ | n−1 drives | 1 drive failure | Good space efficiency at 3+ drives |
| **RAID 6** | 4+ | n−2 drives | 2 drive failures | Only worth it at 4+ drives |
| **RAID 10** | 4 | 50% | 1 per mirrored pair | Fast + redundant, needs 4 drives |

**Recommendation for home use: RAID 1 with 2 drives.** It's the most
straightforward to set up and recover from, and NixOS supports it natively
via `mdadm`. If you end up with 3+ drives, RAID 5 is a reasonable step up.

---

## Overview of Changes

1. Back up all `/srv` data off-server
2. Wipe and assemble the new RAID array with `mdadm`
3. Update `modules/server/storage.nix` and `modules/options.nix` to point at
   the new RAID device
4. Restore data and rebuild

---

## Step 1 — Back Up /srv

Do this **before touching any disks**.

```bash
# On the server — snapshot /srv to an external drive or remote destination
# (adjust destination as needed)

# Option A: rsync to external USB drive mounted at /mnt/backup
sudo rsync -aHAXv /srv/ /mnt/backup/srv-snapshot/

# Option B: rsync over SSH to your macmini
rsync -aHAXz -e ssh ewan@server:/srv/ ~/srv-backup/

# Verify the backup looks complete
ls -la /mnt/backup/srv-snapshot/
du -sh /mnt/backup/srv-snapshot/
```

Don't proceed until you're confident the backup is good.

---

## Step 2 — Identify the New Drives

Boot with the new drives attached and identify their device paths:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE
```

You're looking for the two (or more) new blank drives. Note their paths —
e.g. `/dev/sdb` and `/dev/sdc`. Double-check by size and model; **do not
mistake the OS drive or your current `/srv` drive for a blank one**.

```bash
# Confirm a drive is blank / has no important filesystem
sudo wipefs /dev/sdb
sudo wipefs /dev/sdc
```

---

## Step 3 — Assemble the RAID Array

### RAID 1 (2 drives — recommended)

```bash
# Create the array — this is destructive on /dev/sdb and /dev/sdc
sudo mdadm --create /dev/md0 \
  --level=1 \
  --raid-devices=2 \
  /dev/sdb /dev/sdc

# Monitor initial sync progress (takes minutes to hours depending on drive size)
watch cat /proc/mdstat
```

### RAID 5 (3+ drives)

```bash
sudo mdadm --create /dev/md0 \
  --level=5 \
  --raid-devices=3 \
  /dev/sdb /dev/sdc /dev/sdd

watch cat /proc/mdstat
```

> You can use the array before the initial sync finishes — it just runs slower.

### Format and label the array

```bash
sudo mkfs.ext4 -L srv /dev/md0
```

> The `storage.nix` auto-format service checks for `TYPE=` from `blkid` and
> skips formatting if the filesystem is already present, so it is safe to
> format manually here. The service will see it's already formatted and do nothing.

### Get the RAID device UUID

```bash
sudo blkid /dev/md0
# → /dev/md0: LABEL="srv" UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" TYPE="ext4"

# Also note the mdadm array UUID for the config:
sudo mdadm --detail /dev/md0 | grep "UUID"
```

---

## Step 4 — Update the NixOS Config

### 4a. Add the RAID device path to `options.nix`

In `modules/options.nix`, update the storage device default to point at the
RAID device instead of the raw disk UUID:

```nix
# modules/options.nix
server.storage.srv = {
  device = mkOption {
    type = str;
    # Was: "/dev/disk/by-uuid/<old-single-drive-uuid>"
    default = "/dev/disk/by-label/srv";   # ← RAID array is labelled "srv"
    description = "Block device for /srv (RAID md0 or raw disk).";
  };
  # fsType and options stay the same
};
```

Using `by-label` rather than `by-uuid` is fine here because the label `srv`
is set on the RAID array itself, not an individual drive. Alternatively, use
`/dev/disk/by-uuid/<md0-uuid>` if you prefer UUID-stable references.

### 4b. Enable mdadm in `modules/server/storage.nix`

Add mdadm configuration so NixOS assembles the array at boot:

```nix
# modules/server/storage.nix
{ config, pkgs, ... }:
let
  srv = config.myConfig.server.storage.srv;
  device = srv.device;
in
{
  # ── mdadm — assemble RAID at boot ──────────────────────────────────────────
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR root
    '';
  };

  # ── 1. Auto-format (unchanged — skips if already formatted) ────────────────
  systemd.services."srv-autoformat" = {
    # ... (no changes needed here)
  };

  # ── 2. /srv mount (unchanged) ──────────────────────────────────────────────
  fileSystems."/srv" = {
    # ... (no changes needed here)
  };

  # ── 3. Subdirectory creation (unchanged) ────────────────────────────────────
  systemd.tmpfiles.rules = [
    # ... (no changes needed here)
  ];
}
```

The only real addition is the `boot.swraid` block. Everything else in the
module stays the same because it already references `device` from the option.

### 4c. (Optional) Add mdadm monitoring

For email alerts on drive failure, add to `modules/server/storage.nix`:

```nix
# Requires postfix or another MTA to be configured separately
environment.etc."mdadm.conf".text = ''
  MAILADDR root
  ARRAY /dev/md0 UUID=<array-uuid-from-step-3>
'';

systemd.services.mdmonitor = {
  wantedBy = [ "multi-user.target" ];
};
```

---

## Step 5 — Restore Data

Mount the new array, then rsync the backup back onto it:

```bash
# Test-mount the new array
sudo mkdir -p /mnt/newraid
sudo mount /dev/md0 /mnt/newraid

# Restore from your backup (adjust source path)
sudo rsync -aHAXv /mnt/backup/srv-snapshot/ /mnt/newraid/

# Check ownership is preserved correctly
ls -la /mnt/newraid/forgejo
ls -la /mnt/newraid/postgresql

sudo umount /mnt/newraid
```

---

## Step 6 — Apply the Config and Reboot

```bash
cd /home/ewan/.config/nix-config

# Rebuild and switch (this writes the new fstab entry and mdadm config)
sudo nixos-rebuild switch --flake .#server

# Reboot so the array is assembled cleanly from the start
sudo reboot
```

After reboot, verify:

```bash
# Array is up and healthy
cat /proc/mdstat
sudo mdadm --detail /dev/md0

# /srv is mounted correctly
mount | grep /srv
df -h /srv

# Services came back up
systemctl status forgejo nextcloud bluesky-pds

# Data looks right
ls -la /srv/
```

---

## Ongoing Maintenance

### Check array health

```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md0
```

### Trigger a manual scrub (checks for silent corruption)

```bash
echo check | sudo tee /sys/block/md0/md/sync_action
watch cat /proc/mdstat
```

It's worth adding a weekly scrub as a systemd timer — NixOS has
`boot.swraid`-compatible options for this, or you can write a simple oneshot
timer in `modules/server/maintenance.nix`.

### Replacing a failed drive

```bash
# Mark the failed drive as faulty and remove it
sudo mdadm /dev/md0 --fail /dev/sdb
sudo mdadm /dev/md0 --remove /dev/sdb

# Physically replace the drive, then add the new one
sudo mdadm /dev/md0 --add /dev/sdb

# Watch the rebuild
watch cat /proc/mdstat
```

---

## Updating This Config for a Fresh Deploy

If you ever rebuild the server from scratch on RAID hardware (rather than
migrating from a single disk), the process is simpler:

1. Assemble and format the RAID array before running `nixos-install`
2. Set `myConfig.server.storage.srv.device` in `hosts/server/default.nix` to
   the correct device path
3. Ensure `boot.swraid.enable = true` is in `storage.nix`
4. The auto-format service will see the existing ext4 and skip formatting
5. Proceed with the normal deploy runbook in `hosts-server.md`

---

## Resources

- [NixOS `boot.swraid` options](https://search.nixos.org/options?query=boot.swraid)
- [Arch Wiki — mdadm](https://wiki.archlinux.org/title/RAID) — comprehensive mdadm reference
- [mdadm man page](https://man.archlinux.org/man/mdadm.8)
