{ config, lib, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
}
