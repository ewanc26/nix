# Time Machine Setup

Backups go to a dedicated APFS volume on the external CT2000X9SSD9 (USB, `disk4`/`disk5`).
The `nrs` activation script handles registration and mounting automatically on every rebuild —
this doc covers the one-time volume creation only.

## First-time setup

### 1. Create the Time Machine APFS volume

```bash
sudo diskutil apfs addVolume disk5 APFS "Time Machine"
```

> `disk5` is the APFS container that lives on `disk4s2`. Run `diskutil list` to confirm
> it's still the right identifier before running this.

### 2. Get the volume UUID

```bash
diskutil info "/Volumes/Time Machine" | grep "Volume UUID"
```

### 3. Set the UUID in the config

In `hosts/macmini/default.nix`:

```nix
myConfig.darwin.externalDisk.timeMachineVolumeUUID = "<uuid from step 2>";
```

### 4. Rebuild

```bash
nrs
```

The activation script will mount the volume if needed and register it as a Time Machine
destination. Backups run on a weekly interval (configured via `tmutil setbackupinterval`).

## How it works

`modules/darwin/system.nix` runs a `system.activationScripts.timeMachineDestination` on
every `nrs`. It:

1. Looks up the volume by UUID via `diskutil info`
2. Mounts it if it exists but isn't mounted
3. Registers it with `tmutil setdestination -a` if not already registered
4. Skips silently if the disk isn't plugged in

Setting `myConfig.darwin.externalDisk.timeMachineVolumeUUID = null` disables the script
entirely.

## Server Time Machine (not configured)

A Samba/netatalk-based network Time Machine destination on the server is not currently set up.
If desired in future, the relevant option is `myConfig.server.timemachine` — see
`modules/options.nix` for the available sub-options.
