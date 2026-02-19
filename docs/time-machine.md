# Time Machine Setup

Backups go to a dedicated APFS volume on the external CT2000X9SSD9 (USB, `disk4`/`disk5`).

## Why this isn't automated

`tmutil setdestination` requires root **and** Full Disk Access (TCC). macOS does not allow
FDA to be granted to scripts or launchd daemons without MDM — so it fundamentally cannot
be run from a `nrs` activation script. The destination only needs to be set **once manually**;
it then persists across reboots and `nrs` runs indefinitely.

## First-time setup

### 1. Create the Time Machine APFS volume (if not already done)

```bash
sudo diskutil apfs addVolume disk5 APFS "Time Machine"
```

> `disk5` is the APFS container on `disk4s2`. Run `diskutil list` to confirm the right
> identifier before running this.

### 2. Get the volume UUID

```bash
diskutil info "/Volumes/Time Machine" | grep "Volume UUID"
```

### 3. Set the UUID in the config

In `hosts/macmini/default.nix`:

```nix
myConfig.darwin.externalDisk.timeMachineVolumeUUID = "<uuid from step 2>";
```

This is used only for documentation/reference — `nrs` no longer runs any TM automation.

### 4. Register the destination (once, manually)

```bash
sudo tmutil setdestination "/Volumes/Time Machine"
```

This requires your terminal to have Full Disk Access granted in
**System Settings → Privacy & Security → Full Disk Access**.

### 5. Verify

```bash
tmutil destinationinfo
```

You should see the volume listed. Time Machine will now back up to it automatically.

## Server Time Machine (not configured)

A Samba/netatalk-based network Time Machine destination on the server is not currently set up.
If desired in future, the relevant option is `myConfig.server.timemachine` — see
`modules/options.nix` for the available sub-options.
